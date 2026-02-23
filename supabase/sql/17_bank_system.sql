-- ============================================================
-- BANK SYSTEM — gkk-web uyumlu
-- Kaynak: scenes/ui/screens/BankScreen.gd
-- RPCs: get_bank_items, expand_bank, deposit_item, withdraw_item
-- ============================================================

-- ============================================================
-- 1. BANK STORAGE TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.bank_storage (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    item_id         TEXT        NOT NULL,
    item_name       TEXT,
    item_type       TEXT,
    item_rarity     TEXT        DEFAULT 'common',
    quantity        INT         NOT NULL DEFAULT 1,
    slot_position   INT,
    deposited_at    TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bank_storage_user_id ON public.bank_storage(user_id);
CREATE INDEX IF NOT EXISTS idx_bank_storage_item_type ON public.bank_storage(item_type);

-- ============================================================
-- 2. BANK CAPACITY TABLE (per user)
-- ============================================================
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS bank_capacity INT NOT NULL DEFAULT 50;

-- ============================================================
-- 3. RPC: get_bank_items
-- Godot: BankScreen — Network.http_get("/v1/bank/items")
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_bank_items(p_filter TEXT DEFAULT 'all')
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id     UUID;
    v_capacity    INT;
    v_used        INT;
    v_result      JSONB;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT COALESCE(bank_capacity, 50) INTO v_capacity FROM public.users WHERE auth_id = v_user_id;
    SELECT COUNT(*) INTO v_used FROM public.bank_storage WHERE user_id = v_user_id;

    SELECT jsonb_agg(
        jsonb_build_object(
            'id',           bs.id,
            'item_id',      bs.item_id,
            'item_name',    COALESCE(bs.item_name, bs.item_id),
            'item_type',    COALESCE(bs.item_type, 'unknown'),
            'item_rarity',  COALESCE(bs.item_rarity, 'common'),
            'quantity',     bs.quantity,
            'slot_position',bs.slot_position,
            'deposited_at', bs.deposited_at
        )
        ORDER BY bs.slot_position NULLS LAST, bs.deposited_at
    )
    INTO v_result
    FROM public.bank_storage bs
    WHERE bs.user_id = v_user_id
      AND (p_filter = 'all'
           OR (p_filter = 'weapon' AND bs.item_type = 'weapon')
           OR (p_filter = 'armor' AND bs.item_type = 'armor')
           OR (p_filter = 'potion' AND bs.item_type = 'potion')
           OR (p_filter = 'material' AND bs.item_type IN ('material', 'resource')));

    RETURN jsonb_build_object(
        'items',    COALESCE(v_result, '[]'::jsonb),
        'used',     v_used,
        'capacity', v_capacity,
        'max_capacity', 200
    );
END;
$$;

-- ============================================================
-- 4. RPC: expand_bank
-- Godot: BankScreen — Network.http_post("/v1/bank/expand")
-- ============================================================
CREATE OR REPLACE FUNCTION public.expand_bank()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id    UUID;
    v_user       RECORD;
    v_expand_by  INT := 25;
    v_gem_cost   INT := 50;
    v_max_cap    INT := 200;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT gems, COALESCE(bank_capacity, 50) AS bank_capacity INTO v_user FROM public.users WHERE auth_id = v_user_id;

    IF v_user.bank_capacity >= v_max_cap THEN
        RETURN jsonb_build_object('success', false, 'error', 'Banka maksimum kapasitede');
    END IF;

    IF v_user.gems < v_gem_cost THEN
        RETURN jsonb_build_object('success', false, 'error', format('Yetersiz elmas. Gerekli: %s', v_gem_cost));
    END IF;

    UPDATE public.users
    SET gems = gems - v_gem_cost,
        bank_capacity = LEAST(v_max_cap, COALESCE(bank_capacity, 50) + v_expand_by),
        updated_at = NOW()
    WHERE auth_id = v_user_id;

    RETURN jsonb_build_object(
        'success',      TRUE,
        'gem_cost',     v_gem_cost,
        'new_capacity', LEAST(v_max_cap, v_user.bank_capacity + v_expand_by),
        'expand_by',    v_expand_by
    );
END;
$$;

-- ============================================================
-- 5. RPC: deposit_item_to_bank
-- Godot: BankScreen — deposit from inventory to bank
-- ============================================================
CREATE OR REPLACE FUNCTION public.deposit_item_to_bank(
    p_inventory_row_id UUID,
    p_quantity         INT DEFAULT 1
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id     UUID;
    v_inv_item    RECORD;
    v_capacity    INT;
    v_used        INT;
    v_item_def    RECORD;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    -- Load inventory item
    SELECT * INTO v_inv_item FROM public.inventory WHERE row_id = p_inventory_row_id AND user_id = v_user_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Envanter öğesi bulunamadı');
    END IF;

    IF v_inv_item.is_equipped THEN
        RETURN jsonb_build_object('success', false, 'error', 'Kuşanılmış eşya bankaya yatırılamaz');
    END IF;

    -- Bank capacity check
    SELECT COALESCE(bank_capacity, 50) INTO v_capacity FROM public.users WHERE auth_id = v_user_id;
    SELECT COUNT(*) INTO v_used FROM public.bank_storage WHERE user_id = v_user_id;

    IF v_used >= v_capacity THEN
        RETURN jsonb_build_object('success', false, 'error', 'Banka dolu. Genişletmek için elmas kullanın');
    END IF;

    -- Get item info from items table (if exists)
    SELECT name, type, rarity INTO v_item_def FROM public.items WHERE id = v_inv_item.item_id LIMIT 1;

    -- Move to bank
    IF v_inv_item.quantity <= p_quantity THEN
        -- Move entire stack
        DELETE FROM public.inventory WHERE row_id = p_inventory_row_id;
    ELSE
        -- Reduce quantity in inventory
        UPDATE public.inventory SET quantity = quantity - p_quantity, updated_at = NOW() WHERE row_id = p_inventory_row_id;
    END IF;

    -- Add to bank (merge if same item exists)
    UPDATE public.bank_storage
    SET quantity = quantity + LEAST(p_quantity, v_inv_item.quantity), updated_at = NOW()
    WHERE user_id = v_user_id AND item_id = v_inv_item.item_id
      AND ctid IN (SELECT ctid FROM public.bank_storage WHERE user_id = v_user_id AND item_id = v_inv_item.item_id LIMIT 1);

    IF NOT FOUND THEN
        INSERT INTO public.bank_storage (user_id, item_id, item_name, item_type, item_rarity, quantity)
        VALUES (v_user_id, v_inv_item.item_id, v_item_def.name, v_item_def.type, v_item_def.rarity,
                LEAST(p_quantity, v_inv_item.quantity));
    END IF;

    RETURN jsonb_build_object(
        'success',   TRUE,
        'item_id',   v_inv_item.item_id,
        'quantity',  LEAST(p_quantity, v_inv_item.quantity)
    );
END;
$$;

-- ============================================================
-- 6. RPC: withdraw_item_from_bank
-- Godot: BankScreen — withdraw from bank to inventory
-- ============================================================
CREATE OR REPLACE FUNCTION public.withdraw_item_from_bank(
    p_bank_id  UUID,
    p_quantity INT DEFAULT 1
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id    UUID;
    v_bank_item  RECORD;
    v_inv_count  INT;
    v_slot       INT;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT * INTO v_bank_item FROM public.bank_storage WHERE id = p_bank_id AND user_id = v_user_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Banka öğesi bulunamadı');
    END IF;

    IF v_bank_item.quantity < p_quantity THEN
        RETURN jsonb_build_object('success', false, 'error', 'Yetersiz miktar');
    END IF;

    -- Inventory space check
    SELECT COUNT(*) INTO v_inv_count FROM public.inventory WHERE user_id = v_user_id AND is_equipped = FALSE;
    IF v_inv_count >= 20 THEN
        RETURN jsonb_build_object('success', false, 'error', 'Envanter dolu');
    END IF;

    -- Find empty slot
    SELECT s.i INTO v_slot
    FROM generate_series(0, 19) AS s(i)
    WHERE NOT EXISTS (
        SELECT 1 FROM public.inventory WHERE user_id = v_user_id AND slot_position = s.i AND is_equipped = FALSE
    )
    LIMIT 1;

    -- Move from bank to inventory
    IF v_bank_item.quantity <= p_quantity THEN
        DELETE FROM public.bank_storage WHERE id = p_bank_id;
    ELSE
        UPDATE public.bank_storage SET quantity = quantity - p_quantity, updated_at = NOW() WHERE id = p_bank_id;
    END IF;

    -- Add to inventory
    INSERT INTO public.inventory (user_id, item_id, quantity, is_equipped, slot_position, updated_at)
    VALUES (v_user_id, v_bank_item.item_id, LEAST(p_quantity, v_bank_item.quantity), FALSE, v_slot, NOW())
    ON CONFLICT DO NOTHING;

    RETURN jsonb_build_object(
        'success',  TRUE,
        'item_id',  v_bank_item.item_id,
        'quantity', LEAST(p_quantity, v_bank_item.quantity)
    );
END;
$$;

NOTIFY pgrst, 'reload schema';
