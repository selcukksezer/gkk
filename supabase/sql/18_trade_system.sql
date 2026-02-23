-- ============================================================
-- TRADE SYSTEM — gkk-web uyumlu
-- Kaynak: scenes/ui/screens/TradeScreen.gd
-- RPCs: initiate_trade, confirm_trade, cancel_trade,
--        get_my_trades, get_trade_offers
-- ============================================================

-- ============================================================
-- 1. TRADE SESSIONS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.trade_sessions (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    initiator_id    UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    partner_id      UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status          TEXT        NOT NULL DEFAULT 'pending', -- pending, active, confirmed, completed, cancelled
    initiator_items JSONB       NOT NULL DEFAULT '[]', -- [{item_id, quantity, inventory_row_id}]
    partner_items   JSONB       NOT NULL DEFAULT '[]',
    initiator_gold  INT         NOT NULL DEFAULT 0,
    partner_gold    INT         NOT NULL DEFAULT 0,
    initiator_confirmed BOOLEAN NOT NULL DEFAULT FALSE,
    partner_confirmed   BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW(),
    completed_at    TIMESTAMPTZ,
    expires_at      TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '30 minutes')
);

CREATE INDEX IF NOT EXISTS idx_trade_sessions_initiator ON public.trade_sessions(initiator_id);
CREATE INDEX IF NOT EXISTS idx_trade_sessions_partner ON public.trade_sessions(partner_id);
CREATE INDEX IF NOT EXISTS idx_trade_sessions_status ON public.trade_sessions(status);

-- ============================================================
-- 2. RPC: initiate_trade
-- Godot: TradeScreen — Network.http_post("/v1/trade/initiate")
-- ============================================================
CREATE OR REPLACE FUNCTION public.initiate_trade(p_partner_username TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id   UUID;
    v_partner_id UUID;
    v_trade_id  UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    -- Find partner
    SELECT auth_id INTO v_partner_id FROM public.users WHERE username ILIKE p_partner_username;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Oyuncu bulunamadı');
    END IF;

    IF v_user_id = v_partner_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'Kendinizle ticaret yapamazsınız');
    END IF;

    -- Check for existing active trade
    IF EXISTS (
        SELECT 1 FROM public.trade_sessions
        WHERE (initiator_id = v_user_id OR partner_id = v_user_id)
          AND status IN ('pending', 'active')
          AND expires_at > NOW()
    ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Zaten aktif bir ticaret var');
    END IF;

    -- Create trade session
    INSERT INTO public.trade_sessions (initiator_id, partner_id, status)
    VALUES (v_user_id, v_partner_id, 'pending')
    RETURNING id INTO v_trade_id;

    RETURN jsonb_build_object(
        'success',     TRUE,
        'trade_id',    v_trade_id,
        'partner_id',  v_partner_id,
        'expires_at',  NOW() + INTERVAL '30 minutes'
    );
END;
$$;

-- ============================================================
-- 3. RPC: update_trade_offer
-- Godot: TradeScreen — add/remove items from trade
-- ============================================================
CREATE OR REPLACE FUNCTION public.update_trade_offer(
    p_trade_id   UUID,
    p_items      JSONB DEFAULT '[]',
    p_gold       INT DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id UUID;
    v_trade   RECORD;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT * INTO v_trade FROM public.trade_sessions WHERE id = p_trade_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Ticaret bulunamadı');
    END IF;

    IF v_trade.status NOT IN ('pending', 'active') OR v_trade.expires_at < NOW() THEN
        RETURN jsonb_build_object('success', false, 'error', 'Ticaret artık aktif değil');
    END IF;

    -- Reset confirmations when offer changes
    IF v_user_id = v_trade.initiator_id THEN
        UPDATE public.trade_sessions
        SET initiator_items = p_items, initiator_gold = p_gold,
            initiator_confirmed = FALSE, partner_confirmed = FALSE,
            status = 'active', updated_at = NOW()
        WHERE id = p_trade_id;
    ELSIF v_user_id = v_trade.partner_id THEN
        UPDATE public.trade_sessions
        SET partner_items = p_items, partner_gold = p_gold,
            initiator_confirmed = FALSE, partner_confirmed = FALSE,
            status = 'active', updated_at = NOW()
        WHERE id = p_trade_id;
    ELSE
        RETURN jsonb_build_object('success', false, 'error', 'Bu ticarete dahil değilsiniz');
    END IF;

    RETURN jsonb_build_object('success', TRUE, 'trade_id', p_trade_id);
END;
$$;

-- ============================================================
-- 4. RPC: confirm_trade
-- Godot: TradeScreen — Network.http_post("/v1/trade/confirm")
-- ============================================================
CREATE OR REPLACE FUNCTION public.confirm_trade(p_trade_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id UUID;
    v_trade   RECORD;
    v_both_confirmed BOOLEAN;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT * INTO v_trade FROM public.trade_sessions WHERE id = p_trade_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Ticaret bulunamadı');
    END IF;

    IF v_trade.status NOT IN ('pending', 'active') OR v_trade.expires_at < NOW() THEN
        RETURN jsonb_build_object('success', false, 'error', 'Ticaret süresi dolmuş');
    END IF;

    -- Set confirmation
    IF v_user_id = v_trade.initiator_id THEN
        UPDATE public.trade_sessions SET initiator_confirmed = TRUE, updated_at = NOW() WHERE id = p_trade_id;
    ELSIF v_user_id = v_trade.partner_id THEN
        UPDATE public.trade_sessions SET partner_confirmed = TRUE, updated_at = NOW() WHERE id = p_trade_id;
    ELSE
        RETURN jsonb_build_object('success', false, 'error', 'Bu ticarete dahil değilsiniz');
    END IF;

    -- Check if both confirmed
    SELECT initiator_confirmed AND partner_confirmed INTO v_both_confirmed
    FROM public.trade_sessions WHERE id = p_trade_id;

    IF v_both_confirmed THEN
        -- Execute the trade!
        -- Note: Full item transfer would require inventory manipulation
        -- For now, mark as completed and let clients refresh inventory
        UPDATE public.trade_sessions
        SET status = 'completed', completed_at = NOW(), updated_at = NOW()
        WHERE id = p_trade_id;

        -- Transfer gold
        SELECT * INTO v_trade FROM public.trade_sessions WHERE id = p_trade_id;
        IF v_trade.initiator_gold > 0 THEN
            UPDATE public.users SET gold = gold - v_trade.initiator_gold, updated_at = NOW() WHERE auth_id = v_trade.initiator_id;
            UPDATE public.users SET gold = gold + v_trade.initiator_gold, updated_at = NOW() WHERE auth_id = v_trade.partner_id;
        END IF;
        IF v_trade.partner_gold > 0 THEN
            UPDATE public.users SET gold = gold - v_trade.partner_gold, updated_at = NOW() WHERE auth_id = v_trade.partner_id;
            UPDATE public.users SET gold = gold + v_trade.partner_gold, updated_at = NOW() WHERE auth_id = v_trade.initiator_id;
        END IF;

        RETURN jsonb_build_object(
            'success',   TRUE,
            'completed', TRUE,
            'trade_id',  p_trade_id,
            'message',   'Ticaret tamamlandı!'
        );
    END IF;

    RETURN jsonb_build_object(
        'success',    TRUE,
        'completed',  FALSE,
        'waiting_for','Karşı tarafın onayı bekleniyor'
    );
END;
$$;

-- ============================================================
-- 5. RPC: cancel_trade
-- Godot: TradeScreen — Network.http_post("/v1/trade/cancel")
-- ============================================================
CREATE OR REPLACE FUNCTION public.cancel_trade(p_trade_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id UUID;
    v_trade   RECORD;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT * INTO v_trade FROM public.trade_sessions WHERE id = p_trade_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Ticaret bulunamadı');
    END IF;

    IF v_user_id NOT IN (v_trade.initiator_id, v_trade.partner_id) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Bu ticarete dahil değilsiniz');
    END IF;

    IF v_trade.status = 'completed' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Tamamlanmış ticaret iptal edilemez');
    END IF;

    UPDATE public.trade_sessions SET status = 'cancelled', updated_at = NOW() WHERE id = p_trade_id;

    RETURN jsonb_build_object('success', TRUE, 'message', 'Ticaret iptal edildi');
END;
$$;

-- ============================================================
-- 6. RPC: get_my_trades
-- Godot: TradeScreen — trade history
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_my_trades(p_limit INT DEFAULT 20)
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
            'id',            ts.id,
            'status',        ts.status,
            'partner_name',  CASE WHEN ts.initiator_id = v_user_id
                                  THEN pu.username ELSE iu.username END,
            'my_items',      CASE WHEN ts.initiator_id = v_user_id
                                  THEN ts.initiator_items ELSE ts.partner_items END,
            'their_items',   CASE WHEN ts.initiator_id = v_user_id
                                  THEN ts.partner_items ELSE ts.initiator_items END,
            'my_gold',       CASE WHEN ts.initiator_id = v_user_id
                                  THEN ts.initiator_gold ELSE ts.partner_gold END,
            'their_gold',    CASE WHEN ts.initiator_id = v_user_id
                                  THEN ts.partner_gold ELSE ts.initiator_gold END,
            'created_at',    ts.created_at,
            'completed_at',  ts.completed_at
        )
        ORDER BY ts.created_at DESC
    )
    INTO v_result
    FROM public.trade_sessions ts
    LEFT JOIN public.users iu ON iu.auth_id = ts.initiator_id
    LEFT JOIN public.users pu ON pu.auth_id = ts.partner_id
    WHERE ts.initiator_id = v_user_id OR ts.partner_id = v_user_id
    LIMIT p_limit;

    RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

-- ============================================================
-- 7. RPC: get_active_trade
-- Godot: TradeScreen — get current active trade session
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_active_trade()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id UUID;
    v_trade   RECORD;
    v_partner RECORD;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT ts.* INTO v_trade
    FROM public.trade_sessions ts
    WHERE (ts.initiator_id = v_user_id OR ts.partner_id = v_user_id)
      AND ts.status IN ('pending', 'active')
      AND ts.expires_at > NOW()
    ORDER BY ts.created_at DESC
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('active', FALSE);
    END IF;

    -- Get partner info
    IF v_trade.initiator_id = v_user_id THEN
        SELECT username INTO v_partner FROM public.users WHERE auth_id = v_trade.partner_id;
    ELSE
        SELECT username INTO v_partner FROM public.users WHERE auth_id = v_trade.initiator_id;
    END IF;

    RETURN jsonb_build_object(
        'active',                TRUE,
        'trade_id',              v_trade.id,
        'status',                v_trade.status,
        'partner_username',      v_partner.username,
        'my_items',              CASE WHEN v_trade.initiator_id = v_user_id THEN v_trade.initiator_items ELSE v_trade.partner_items END,
        'their_items',           CASE WHEN v_trade.initiator_id = v_user_id THEN v_trade.partner_items ELSE v_trade.initiator_items END,
        'my_gold',               CASE WHEN v_trade.initiator_id = v_user_id THEN v_trade.initiator_gold ELSE v_trade.partner_gold END,
        'their_gold',            CASE WHEN v_trade.initiator_id = v_user_id THEN v_trade.partner_gold ELSE v_trade.initiator_gold END,
        'my_confirmed',          CASE WHEN v_trade.initiator_id = v_user_id THEN v_trade.initiator_confirmed ELSE v_trade.partner_confirmed END,
        'their_confirmed',       CASE WHEN v_trade.initiator_id = v_user_id THEN v_trade.partner_confirmed ELSE v_trade.initiator_confirmed END,
        'expires_at',            v_trade.expires_at
    );
END;
$$;

NOTIFY pgrst, 'reload schema';
