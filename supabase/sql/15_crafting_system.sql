-- ============================================================
-- CRAFTING SYSTEM — gkk-web uyumlu
-- Kaynak: scenes/ui/screens/CraftingScreen.gd (389 satır)
-- RPCs: get_all_recipes, craft_item, get_crafting_queue, claim_crafted_item
-- ============================================================

-- ============================================================
-- 1. CRAFTING RECIPES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.crafting_recipes (
    id                      TEXT    PRIMARY KEY,
    name                    TEXT    NOT NULL,
    output_item_id          TEXT    NOT NULL,
    output_name             TEXT    NOT NULL,
    output_rarity           TEXT    NOT NULL DEFAULT 'common',
    output_quantity         INT     NOT NULL DEFAULT 1,
    item_type               TEXT    NOT NULL DEFAULT 'weapon', -- weapon/armor/potion/rune/scroll/accessory
    recipe_type             TEXT    NOT NULL DEFAULT 'weapon',
    required_level          INT     NOT NULL DEFAULT 1,
    craft_time_seconds      INT     NOT NULL DEFAULT 60,
    production_time_seconds INT     NOT NULL DEFAULT 60,
    success_rate            NUMERIC(4,3) NOT NULL DEFAULT 0.80,
    ingredients             JSONB   NOT NULL DEFAULT '[]', -- [{item_id, item_name, quantity}]
    gold_cost               INT     NOT NULL DEFAULT 0,
    gem_cost_per_batch      INT     NOT NULL DEFAULT 1,
    max_batch               INT     NOT NULL DEFAULT 5,
    description             TEXT,
    is_active               BOOLEAN NOT NULL DEFAULT TRUE,
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_crafting_recipes_item_type ON public.crafting_recipes(item_type);
CREATE INDEX IF NOT EXISTS idx_crafting_recipes_required_level ON public.crafting_recipes(required_level);

-- ============================================================
-- 2. CRAFTING QUEUE TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.crafting_queue (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    recipe_id       TEXT        NOT NULL REFERENCES public.crafting_recipes(id),
    recipe_name     TEXT        NOT NULL,
    output_item_id  TEXT        NOT NULL,
    output_name     TEXT        NOT NULL,
    output_rarity   TEXT        NOT NULL DEFAULT 'common',
    batch_count     INT         NOT NULL DEFAULT 1,
    status          TEXT        NOT NULL DEFAULT 'crafting', -- crafting, done, claimed
    started_at      TIMESTAMPTZ DEFAULT NOW(),
    completes_at    TIMESTAMPTZ NOT NULL,
    claimed_at      TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_crafting_queue_user_id ON public.crafting_queue(user_id);
CREATE INDEX IF NOT EXISTS idx_crafting_queue_status ON public.crafting_queue(status);
CREATE INDEX IF NOT EXISTS idx_crafting_queue_completes_at ON public.crafting_queue(completes_at);

-- ============================================================
-- 3. SEED CRAFTING RECIPES (Godot CraftingScreen content)
-- ============================================================
INSERT INTO public.crafting_recipes (id, name, output_item_id, output_name, output_rarity, output_quantity, item_type, recipe_type, required_level, craft_time_seconds, production_time_seconds, success_rate, ingredients, gold_cost)
VALUES
  -- WEAPONS
  ('recipe_iron_sword',       'Demir Kılıç',          'iron_sword',       'Demir Kılıç',          'common',    1, 'weapon', 'weapon', 1,  120,  120, 0.85, '[{"item_id":"iron_ore","item_name":"Demir Cevheri","quantity":5},{"item_id":"leather","item_name":"Deri","quantity":2}]', 100),
  ('recipe_steel_blade',      'Çelik Bıçak',           'steel_blade',      'Çelik Bıçak',          'uncommon',  1, 'weapon', 'weapon', 5,  300,  300, 0.80, '[{"item_id":"iron_ingot","item_name":"Demir Külçe","quantity":3},{"item_id":"coal","item_name":"Kömür","quantity":2}]', 300),
  ('recipe_elven_bow',        'Elf Yayı',              'elven_bow',        'Elf Yayı',              'rare',      1, 'weapon', 'weapon', 10, 600,  600, 0.75, '[{"item_id":"oak_wood","item_name":"Meşe Odunu","quantity":8},{"item_id":"silk_thread","item_name":"İpek İp","quantity":3}]', 800),
  ('recipe_shadow_dagger',    'Gölge Hançeri',         'shadow_dagger',    'Gölge Hançeri',         'rare',      1, 'weapon', 'weapon', 15, 900,  900, 0.70, '[{"item_id":"shadow_essence","item_name":"Gölge Esansı","quantity":5},{"item_id":"mithril_ore","item_name":"Mithril Cevheri","quantity":2}]', 1500),
  ('recipe_mithril_axe',      'Mithril Balta',         'mithril_axe',      'Mithril Balta',         'epic',      1, 'weapon', 'weapon', 20, 1800, 1800, 0.65, '[{"item_id":"mithril_ingot","item_name":"Mithril Külçe","quantity":5},{"item_id":"dragon_bone","item_name":"Ejderha Kemiği","quantity":1}]', 3000),
  ('recipe_legendary_sword',  'Efsanevi Kılıç',        'legendary_sword',  'Efsanevi Kılıç',        'legendary', 1, 'weapon', 'weapon', 30, 3600, 3600, 0.55, '[{"item_id":"dragon_scale","item_name":"Ejderha Pulları","quantity":3},{"item_id":"void_crystal","item_name":"Boşluk Kristali","quantity":2}]', 10000),

  -- ARMOR
  ('recipe_leather_armor',    'Deri Zırh',             'leather_armor',    'Deri Zırh',             'common',    1, 'armor', 'armor',  1,  120,  120, 0.85, '[{"item_id":"leather","item_name":"Deri","quantity":8},{"item_id":"iron_ring","item_name":"Demir Halka","quantity":2}]', 150),
  ('recipe_chainmail',        'Zincir Zırh',           'chainmail',        'Zincir Zırh',            'uncommon',  1, 'armor', 'armor',  5,  300,  300, 0.80, '[{"item_id":"iron_ingot","item_name":"Demir Külçe","quantity":10},{"item_id":"leather","item_name":"Deri","quantity":3}]', 500),
  ('recipe_plate_armor',      'Plaka Zırh',            'plate_armor',      'Plaka Zırh',             'rare',      1, 'armor', 'armor',  12, 600,  600, 0.75, '[{"item_id":"steel_ingot","item_name":"Çelik Külçe","quantity":15},{"item_id":"iron_ring","item_name":"Demir Halka","quantity":5}]', 1200),
  ('recipe_shadow_robe',      'Gölge Cübbesi',         'shadow_robe',      'Gölge Cübbesi',          'epic',      1, 'armor', 'armor',  20, 1800, 1800, 0.65, '[{"item_id":"shadow_silk","item_name":"Gölge İpeği","quantity":10},{"item_id":"dark_essence","item_name":"Karanlık Esans","quantity":5}]', 3500),

  -- POTIONS
  ('recipe_health_potion',    'Sağlık İksiri',         'health_potion',    'Sağlık İksiri',          'common',    1, 'potion', 'potion', 1,  30,   30,  0.90, '[{"item_id":"herb","item_name":"Ot","quantity":3},{"item_id":"water_vial","item_name":"Su Şişesi","quantity":1}]', 50),
  ('recipe_energy_potion',    'Enerji İksiri',         'energy_potion',    'Enerji İksiri',          'common',    1, 'potion', 'potion', 3,  60,   60,  0.85, '[{"item_id":"mushroom","item_name":"Mantar","quantity":2},{"item_id":"sugar","item_name":"Şeker","quantity":1}]', 100),
  ('recipe_stamina_potion',   'Dayanıklılık İksiri',   'stamina_potion',   'Dayanıklılık İksiri',    'uncommon',  1, 'potion', 'potion', 8,  120,  120, 0.80, '[{"item_id":"rare_herb","item_name":"Nadir Ot","quantity":3},{"item_id":"honey","item_name":"Bal","quantity":2}]', 300),
  ('recipe_greater_health',   'Büyük Sağlık İksiri',   'greater_health_potion','Büyük Sağlık İksiri','uncommon',  1, 'potion', 'potion', 10, 180,  180, 0.78, '[{"item_id":"golden_herb","item_name":"Altın Ot","quantity":3},{"item_id":"ruby_dust","item_name":"Yakut Tozu","quantity":1}]', 500),
  ('recipe_elixir_power',     'Güç Eliksiri',          'elixir_power',     'Güç Eliksiri',           'rare',      1, 'potion', 'potion', 15, 300,  300, 0.75, '[{"item_id":"dragon_blood","item_name":"Ejderha Kanı","quantity":1},{"item_id":"shadow_essence","item_name":"Gölge Esansı","quantity":2}]', 1000),

  -- RUNES
  ('recipe_fire_rune',        'Ateş Rünü',             'rune_fire',        'Ateş Rünü',             'uncommon',  1, 'rune', 'rune',   5,  240,  240, 0.80, '[{"item_id":"fire_crystal","item_name":"Ateş Kristali","quantity":2},{"item_id":"rune_stone","item_name":"Rün Taşı","quantity":1}]', 400),
  ('recipe_ice_rune',         'Buz Rünü',              'rune_ice',         'Buz Rünü',              'uncommon',  1, 'rune', 'rune',   5,  240,  240, 0.80, '[{"item_id":"ice_crystal","item_name":"Buz Kristali","quantity":2},{"item_id":"rune_stone","item_name":"Rün Taşı","quantity":1}]', 400),
  ('recipe_lightning_rune',   'Şimşek Rünü',           'rune_lightning',   'Şimşek Rünü',           'rare',      1, 'rune', 'rune',   10, 480,  480, 0.75, '[{"item_id":"storm_crystal","item_name":"Fırtına Kristali","quantity":3},{"item_id":"rune_stone","item_name":"Rün Taşı","quantity":2}]', 800),
  ('recipe_shadow_rune',      'Gölge Rünü',            'rune_shadow',      'Gölge Rünü',            'epic',      1, 'rune', 'rune',   20, 900,  900, 0.65, '[{"item_id":"void_crystal","item_name":"Boşluk Kristali","quantity":3},{"item_id":"dark_rune_stone","item_name":"Karanlık Rün Taşı","quantity":2}]', 2000),

  -- SCROLLS
  ('recipe_scroll_teleport',  'Işınlanma Tomarı',      'scroll_teleport',  'Işınlanma Tomarı',      'uncommon',  1, 'scroll','scroll', 5,  180,  180, 0.85, '[{"item_id":"arcane_paper","item_name":"Arkanik Kağıt","quantity":2},{"item_id":"teleport_dust","item_name":"Işınlanma Tozu","quantity":1}]', 300),
  ('recipe_scroll_protection','Koruma Tomarı',          'scroll_protection','Koruma Tomarı',         'uncommon',  1, 'scroll','scroll', 5,  180,  180, 0.85, '[{"item_id":"arcane_paper","item_name":"Arkanik Kağıt","quantity":2},{"item_id":"protection_dust","item_name":"Koruma Tozu","quantity":1}]', 350),
  ('recipe_scroll_haste',     'Hız Tomarı',            'scroll_haste',     'Hız Tomarı',            'rare',      1, 'scroll','scroll', 10, 360,  360, 0.75, '[{"item_id":"arcane_paper","item_name":"Arkanik Kağıt","quantity":3},{"item_id":"speed_crystal","item_name":"Hız Kristali","quantity":2}]', 600),

  -- ACCESSORIES
  ('recipe_iron_ring',        'Demir Yüzük',           'iron_ring',        'Demir Yüzük',           'common',    1, 'accessory','accessory',1, 90, 90, 0.90,'[{"item_id":"iron_ore","item_name":"Demir Cevheri","quantity":3}]', 80),
  ('recipe_silver_necklace',  'Gümüş Kolye',           'silver_necklace',  'Gümüş Kolye',           'uncommon',  1, 'accessory','accessory',8, 240, 240, 0.80,'[{"item_id":"silver_ore","item_name":"Gümüş Cevheri","quantity":5},{"item_id":"gem_dust","item_name":"Mücevher Tozu","quantity":2}]', 600),
  ('recipe_arcane_amulet',    'Arkanik Muska',         'arcane_amulet',    'Arkanik Muska',         'rare',      1, 'accessory','accessory',15,480, 480, 0.72,'[{"item_id":"arcane_crystal","item_name":"Arkanik Kristal","quantity":3},{"item_id":"soul_gem","item_name":"Ruh Mücevheri","quantity":1}]', 2000)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 4. RPC: get_all_recipes
-- Godot: CraftingManager.load_all_recipes()
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_all_recipes()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id UUID;
    v_result  JSONB;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT jsonb_agg(
        jsonb_build_object(
            'id',                      cr.id,
            'recipe_id',               cr.id,
            'name',                    cr.name,
            'output_item_id',          cr.output_item_id,
            'output_name',             cr.output_name,
            'output_rarity',           cr.output_rarity,
            'output_quantity',         cr.output_quantity,
            'item_type',               cr.item_type,
            'recipe_type',             cr.recipe_type,
            'required_level',          cr.required_level,
            'craft_time_seconds',      cr.craft_time_seconds,
            'production_time_seconds', cr.production_time_seconds,
            'success_rate',            cr.success_rate,
            'ingredients',             cr.ingredients,
            'gold_cost',               cr.gold_cost,
            'gem_cost_per_batch',      cr.gem_cost_per_batch,
            'max_batch',               cr.max_batch,
            'description',             cr.description
        )
        ORDER BY cr.item_type, cr.required_level
    )
    INTO v_result
    FROM public.crafting_recipes cr
    WHERE cr.is_active = TRUE;

    RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

-- ============================================================
-- 5. RPC: craft_item
-- Godot: CraftingManager.craft_item(recipe_id, batch_count)
-- Matches gkk-web craftingStore.craftItem(recipeId, batchCount)
-- ============================================================
CREATE OR REPLACE FUNCTION public.craft_item(
    p_recipe_id   TEXT,
    p_batch_count INT DEFAULT 1
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id     UUID;
    v_user        RECORD;
    v_recipe      RECORD;
    v_gem_cost    INT;
    v_total_time  INT;
    v_completes_at TIMESTAMPTZ;
    v_queue_count INT;
    v_new_queue_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    -- Load recipe
    SELECT * INTO v_recipe FROM public.crafting_recipes WHERE id = p_recipe_id AND is_active = TRUE;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Tarif bulunamadı');
    END IF;

    -- Load user
    SELECT * INTO v_user FROM public.users WHERE auth_id = v_user_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Kullanıcı bulunamadı');
    END IF;

    -- Level check
    IF v_user.level < v_recipe.required_level THEN
        RETURN jsonb_build_object('success', false, 'error', format('Seviye %s gerekli', v_recipe.required_level));
    END IF;

    -- Batch count check (Godot: max 5)
    IF p_batch_count < 1 OR p_batch_count > v_recipe.max_batch THEN
        RETURN jsonb_build_object('success', false, 'error', format('Geçersiz miktar (1-%s)', v_recipe.max_batch));
    END IF;

    -- Gem cost (Godot: batch - 1 gems for extra batches)
    v_gem_cost := GREATEST(0, p_batch_count - 1);
    IF v_user.gems < v_gem_cost THEN
        RETURN jsonb_build_object('success', false, 'error', format('Yetersiz elmas. Gerekli: %s', v_gem_cost));
    END IF;

    -- Queue check (max 5 items in crafting queue)
    SELECT COUNT(*) INTO v_queue_count
    FROM public.crafting_queue
    WHERE user_id = v_user_id AND status = 'crafting';

    IF v_queue_count >= 5 THEN
        RETURN jsonb_build_object('success', false, 'error', 'Üretim kuyruğu dolu (maks 5)');
    END IF;

    -- Deduct gems
    IF v_gem_cost > 0 THEN
        UPDATE public.users SET gems = gems - v_gem_cost, updated_at = NOW() WHERE auth_id = v_user_id;
    END IF;

    -- Calculate completion time
    v_total_time   := v_recipe.craft_time_seconds * p_batch_count;
    v_completes_at := NOW() + (v_total_time || ' seconds')::INTERVAL;

    -- Insert into queue
    INSERT INTO public.crafting_queue (user_id, recipe_id, recipe_name, output_item_id, output_name, output_rarity, batch_count, status, completes_at)
    VALUES (v_user_id, p_recipe_id, v_recipe.name, v_recipe.output_item_id, v_recipe.output_name, v_recipe.output_rarity, p_batch_count, 'crafting', v_completes_at)
    RETURNING id INTO v_new_queue_id;

    RETURN jsonb_build_object(
        'success',      TRUE,
        'queue_id',     v_new_queue_id,
        'recipe_name',  v_recipe.name,
        'batch_count',  p_batch_count,
        'gem_cost',     v_gem_cost,
        'completes_at', v_completes_at,
        'total_seconds',v_total_time
    );
END;
$$;

-- ============================================================
-- 6. RPC: get_crafting_queue
-- Godot: CraftingManager — queue with countdown
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_crafting_queue()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id UUID;
    v_result  JSONB;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    -- Auto-complete finished items
    UPDATE public.crafting_queue
    SET status = 'done'
    WHERE user_id = v_user_id AND status = 'crafting' AND completes_at <= NOW();

    SELECT jsonb_agg(
        jsonb_build_object(
            'id',            cq.id,
            'recipe_id',     cq.recipe_id,
            'recipe_name',   cq.recipe_name,
            'output_item_id',cq.output_item_id,
            'output_name',   cq.output_name,
            'output_rarity', cq.output_rarity,
            'batch_count',   cq.batch_count,
            'status',        cq.status,
            'started_at',    cq.started_at,
            'completes_at',  cq.completes_at,
            'seconds_left',  GREATEST(0, EXTRACT(EPOCH FROM (cq.completes_at - NOW()))::INT)
        )
        ORDER BY cq.started_at ASC
    )
    INTO v_result
    FROM public.crafting_queue cq
    WHERE cq.user_id = v_user_id AND cq.status IN ('crafting', 'done');

    RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

-- ============================================================
-- 7. RPC: claim_crafted_item
-- Godot: CraftingManager — claim completed item
-- ============================================================
CREATE OR REPLACE FUNCTION public.claim_crafted_item(p_queue_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id    UUID;
    v_queue_item RECORD;
    v_recipe     RECORD;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT * INTO v_queue_item FROM public.crafting_queue WHERE id = p_queue_id AND user_id = v_user_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Kuyruk öğesi bulunamadı');
    END IF;

    IF v_queue_item.status = 'claimed' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Zaten alındı');
    END IF;

    IF v_queue_item.status = 'crafting' AND v_queue_item.completes_at > NOW() THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Üretim henüz tamamlanmadı',
            'seconds_left', EXTRACT(EPOCH FROM (v_queue_item.completes_at - NOW()))::INT
        );
    END IF;

    -- Add items to inventory (using add_inventory_item_v2 if exists, else direct insert)
    DECLARE
        v_total_qty INT := v_queue_item.batch_count;
        v_item_exists BOOLEAN;
    BEGIN
        -- Check if player already has this item (stackable)
        SELECT EXISTS(
            SELECT 1 FROM public.inventory
            WHERE user_id = v_user_id AND item_id = v_queue_item.output_item_id AND is_equipped = FALSE AND quantity < 50
        ) INTO v_item_exists;

        IF v_item_exists THEN
            UPDATE public.inventory
            SET quantity = LEAST(50, quantity + v_total_qty), updated_at = NOW()
            WHERE user_id = v_user_id AND item_id = v_queue_item.output_item_id AND is_equipped = FALSE AND quantity < 50
              AND ctid IN (SELECT ctid FROM public.inventory WHERE user_id = v_user_id AND item_id = v_queue_item.output_item_id AND is_equipped = FALSE LIMIT 1);
        ELSE
            -- Find first empty slot
            DECLARE
                v_slot INT;
            BEGIN
                SELECT s.i INTO v_slot
                FROM generate_series(0, 19) AS s(i)
                WHERE NOT EXISTS (
                    SELECT 1 FROM public.inventory
                    WHERE user_id = v_user_id AND slot_position = s.i AND is_equipped = FALSE
                )
                LIMIT 1;

                IF v_slot IS NOT NULL THEN
                    INSERT INTO public.inventory (user_id, item_id, quantity, is_equipped, slot_position, updated_at)
                    VALUES (v_user_id, v_queue_item.output_item_id, LEAST(50, v_total_qty), FALSE, v_slot, NOW())
                    ON CONFLICT DO NOTHING;
                END IF;
            END;
        END IF;
    END;

    -- Mark as claimed
    UPDATE public.crafting_queue SET status = 'claimed', claimed_at = NOW() WHERE id = p_queue_id;

    RETURN jsonb_build_object(
        'success',       TRUE,
        'item_id',       v_queue_item.output_item_id,
        'item_name',     v_queue_item.output_name,
        'quantity',      v_queue_item.batch_count,
        'rarity',        v_queue_item.output_rarity
    );
END;
$$;

NOTIFY pgrst, 'reload schema';
