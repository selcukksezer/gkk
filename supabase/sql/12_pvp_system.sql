-- ============================================================
-- PvP SYSTEM — gkk-web uyumlu
-- Kaynak: scenes/ui/screens/PvPScreen.gd (230 satır)
-- RPCs: get_pvp_targets, attack_player, get_pvp_attack_history,
--        get_pvp_defense_history, search_pvp_player
-- ============================================================

-- ============================================================
-- 1. PvP BATTLE LOG TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.pvp_battles (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    attacker_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    defender_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    attacker_name   TEXT        NOT NULL,
    defender_name   TEXT        NOT NULL,
    attacker_power  INT         NOT NULL DEFAULT 0,
    defender_power  INT         NOT NULL DEFAULT 0,
    result          TEXT        NOT NULL, -- 'win' or 'loss' (attacker perspective)
    gold_stolen     INT         NOT NULL DEFAULT 0,
    attacker_gold_change INT    NOT NULL DEFAULT 0,
    defender_gold_change INT    NOT NULL DEFAULT 0,
    attacker_rating_change INT  NOT NULL DEFAULT 0,
    defender_rating_change INT  NOT NULL DEFAULT 0,
    battle_log      JSONB       NOT NULL DEFAULT '[]',
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pvp_battles_attacker_id ON public.pvp_battles(attacker_id);
CREATE INDEX IF NOT EXISTS idx_pvp_battles_defender_id ON public.pvp_battles(defender_id);
CREATE INDEX IF NOT EXISTS idx_pvp_battles_created_at ON public.pvp_battles(created_at DESC);

-- ============================================================
-- 2. RPC: get_pvp_targets
-- Godot: PvPManager.get_attack_targets() — players near our level
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_pvp_targets(p_limit INT DEFAULT 10)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id UUID;
    v_user    RECORD;
    v_result  JSONB;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT level, pvp_rating INTO v_user FROM public.users WHERE auth_id = v_user_id;

    SELECT jsonb_agg(
        jsonb_build_object(
            'player_id',      u.auth_id,
            'username',       u.username,
            'display_name',   u.display_name,
            'level',          u.level,
            'rating',         u.pvp_rating,
            'estimated_gold', LEAST(u.gold * 0.1, 5000)::INT,
            'power',          COALESCE(u.power, u.attack + u.defense),
            'guild_name',     NULL
        )
        ORDER BY random()
    )
    INTO v_result
    FROM public.users u
    WHERE u.auth_id <> v_user_id
      AND u.auth_id IS NOT NULL
      AND u.level BETWEEN GREATEST(1, v_user.level - 5) AND v_user.level + 5
      AND (u.in_prison = FALSE OR u.prison_until <= NOW())
      AND (u.in_hospital = FALSE OR u.hospital_until <= NOW())
    LIMIT p_limit;

    RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

-- ============================================================
-- 3. RPC: search_pvp_player
-- Godot: PvPScreen._on_search_button_pressed
-- ============================================================
CREATE OR REPLACE FUNCTION public.search_pvp_player(p_search TEXT)
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
            'player_id',      u.auth_id,
            'username',       u.username,
            'display_name',   u.display_name,
            'level',          u.level,
            'rating',         u.pvp_rating,
            'estimated_gold', LEAST(u.gold * 0.1, 5000)::INT,
            'power',          COALESCE(u.power, u.attack + u.defense)
        )
    )
    INTO v_result
    FROM public.users u
    WHERE u.auth_id <> v_user_id
      AND (
          u.username ILIKE '%' || p_search || '%'
          OR u.display_name ILIKE '%' || p_search || '%'
      )
    LIMIT 10;

    RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

-- ============================================================
-- 4. RPC: attack_player
-- Godot: PvPManager.initiate_attack → server-side resolution
-- Matches gkk-web: api.rpc("attack_player", { p_target_id })
-- ============================================================
CREATE OR REPLACE FUNCTION public.attack_player(p_target_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id          UUID;
    v_attacker         RECORD;
    v_defender         RECORD;
    v_pvp_energy_cost  INT := 10;
    v_attacker_power   INT;
    v_defender_power   INT;
    v_rng              NUMERIC;
    v_win_chance       NUMERIC;
    v_attacker_wins    BOOLEAN;
    v_gold_stolen      INT;
    v_attacker_gold    BIGINT;
    v_defender_gold    BIGINT;
    v_rating_change    INT;
    v_battle_log       JSONB;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    -- Cannot attack self
    IF v_user_id = p_target_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'Kendinize saldıramazsınız');
    END IF;

    -- Load attacker
    SELECT * INTO v_attacker FROM public.users WHERE auth_id = v_user_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Oyuncu bulunamadı');
    END IF;

    -- Status checks
    IF v_attacker.in_hospital = TRUE AND v_attacker.hospital_until > NOW() THEN
        RETURN jsonb_build_object('success', false, 'error', 'Hastanedeyken saldıramazsınız');
    END IF;
    IF v_attacker.in_prison = TRUE AND v_attacker.prison_until > NOW() THEN
        RETURN jsonb_build_object('success', false, 'error', 'Cezaevindeyken saldıramazsınız');
    END IF;
    IF v_attacker.energy < v_pvp_energy_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Yetersiz enerji');
    END IF;

    -- Load defender
    SELECT * INTO v_defender FROM public.users WHERE auth_id = p_target_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Hedef bulunamadı');
    END IF;

    -- Deduct energy from attacker
    UPDATE public.users SET energy = energy - v_pvp_energy_cost, updated_at = NOW() WHERE auth_id = v_user_id;

    -- Power calculation (Godot: attack + equipment bonus)
    v_attacker_power := GREATEST(1, COALESCE(v_attacker.power, 0) + v_attacker.attack * 2 + v_attacker.defense);
    v_defender_power := GREATEST(1, COALESCE(v_defender.power, 0) + v_defender.attack * 2 + v_defender.defense);

    -- Win probability (Godot: power-based + 0.1 level bonus per level above)
    v_win_chance := GREATEST(0.1, LEAST(0.9,
        0.5
        + (v_attacker_power - v_defender_power)::NUMERIC / (v_attacker_power + v_defender_power + 1) * 0.4
        + (v_attacker.level - v_defender.level) * 0.01
    ));

    v_rng := random();
    v_attacker_wins := v_rng < v_win_chance;

    -- Gold steal: 5-15% of defender gold, max 2000
    IF v_attacker_wins THEN
        v_gold_stolen := LEAST(2000, GREATEST(0, floor(v_defender.gold * (0.05 + random() * 0.10))::INT));
        v_rating_change := 10 + floor(random() * 5)::INT;
    ELSE
        v_gold_stolen := 0;
        v_rating_change := -(5 + floor(random() * 5)::INT);
    END IF;

    -- Apply gold changes
    SELECT gold INTO v_attacker_gold FROM public.users WHERE auth_id = v_user_id;
    SELECT gold INTO v_defender_gold FROM public.users WHERE auth_id = p_target_id;

    UPDATE public.users
    SET gold       = GREATEST(0, gold + v_gold_stolen),
        pvp_wins   = pvp_wins + CASE WHEN v_attacker_wins THEN 1 ELSE 0 END,
        pvp_losses = pvp_losses + CASE WHEN v_attacker_wins THEN 0 ELSE 1 END,
        pvp_rating = GREATEST(0, pvp_rating + v_rating_change),
        updated_at = NOW()
    WHERE auth_id = v_user_id;

    UPDATE public.users
    SET gold       = GREATEST(0, gold - v_gold_stolen),
        pvp_wins   = pvp_wins + CASE WHEN v_attacker_wins THEN 0 ELSE 1 END,
        pvp_losses = pvp_losses + CASE WHEN v_attacker_wins THEN 1 ELSE 0 END,
        pvp_rating = GREATEST(0, pvp_rating - v_rating_change),
        updated_at = NOW()
    WHERE auth_id = p_target_id;

    -- Build battle log
    v_battle_log := jsonb_build_array(
        jsonb_build_object('round', 1, 'attacker_action', 'saldırı', 'damage', floor(v_attacker_power * (0.8 + random() * 0.4))::INT),
        jsonb_build_object('round', 2, 'defender_action', 'karşılık', 'damage', floor(v_defender_power * (0.8 + random() * 0.4))::INT),
        jsonb_build_object('round', 3, 'result', CASE WHEN v_attacker_wins THEN 'Saldırgan galip' ELSE 'Savunmacı galip' END)
    );

    -- Record battle in log
    INSERT INTO public.pvp_battles (
        attacker_id, defender_id, attacker_name, defender_name,
        attacker_power, defender_power, result,
        gold_stolen, attacker_gold_change, defender_gold_change,
        attacker_rating_change, defender_rating_change, battle_log
    ) VALUES (
        v_user_id, p_target_id, v_attacker.username, v_defender.username,
        v_attacker_power, v_defender_power,
        CASE WHEN v_attacker_wins THEN 'win' ELSE 'loss' END,
        v_gold_stolen, v_gold_stolen, -v_gold_stolen,
        v_rating_change, -v_rating_change, v_battle_log
    );

    RETURN jsonb_build_object(
        'success',         TRUE,
        'result',          CASE WHEN v_attacker_wins THEN 'win' ELSE 'loss' END,
        'won',             v_attacker_wins,
        'gold_stolen',     v_gold_stolen,
        'gold_change',     v_gold_stolen,
        'rating_change',   v_rating_change,
        'opponent_name',   v_defender.username,
        'battle_log',      v_battle_log
    );
END;
$$;

-- ============================================================
-- 5. RPC: get_pvp_attack_history
-- Godot: PvPManager.get_attack_history()
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_pvp_attack_history(p_limit INT DEFAULT 20)
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
            'id',             b.id,
            'opponent_name',  b.defender_name,
            'opponent_id',    b.defender_id,
            'result',         b.result,
            'gold_change',    b.attacker_gold_change,
            'rating_change',  b.attacker_rating_change,
            'timestamp',      b.created_at
        )
        ORDER BY b.created_at DESC
    )
    INTO v_result
    FROM public.pvp_battles b
    WHERE b.attacker_id = v_user_id
    LIMIT p_limit;

    RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

-- ============================================================
-- 6. RPC: get_pvp_defense_history
-- Godot: PvPManager.get_defense_history()
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_pvp_defense_history(p_limit INT DEFAULT 20)
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
            'id',             b.id,
            'opponent_name',  b.attacker_name,
            'opponent_id',    b.attacker_id,
            -- Defense perspective: if attacker won = 'loss' for defender
            'result',         CASE WHEN b.result = 'win' THEN 'loss' ELSE 'win' END,
            'gold_change',    b.defender_gold_change,
            'rating_change',  b.defender_rating_change,
            'timestamp',      b.created_at
        )
        ORDER BY b.created_at DESC
    )
    INTO v_result
    FROM public.pvp_battles b
    WHERE b.defender_id = v_user_id
    LIMIT p_limit;

    RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

-- ============================================================
-- 7. RPC: get_pvp_stats
-- Godot: PvPManager.get_player_stats()
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_pvp_stats()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id UUID;
    v_user    RECORD;
    v_rank    INT;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT pvp_wins, pvp_losses, pvp_rating, username INTO v_user FROM public.users WHERE auth_id = v_user_id;

    -- Calculate rank (position by rating)
    SELECT COUNT(*) + 1 INTO v_rank FROM public.users WHERE pvp_rating > v_user.pvp_rating;

    RETURN jsonb_build_object(
        'wins',    COALESCE(v_user.pvp_wins, 0),
        'losses',  COALESCE(v_user.pvp_losses, 0),
        'rating',  COALESCE(v_user.pvp_rating, 1000),
        'rank',    v_rank,
        'win_rate', CASE WHEN COALESCE(v_user.pvp_wins,0) + COALESCE(v_user.pvp_losses,0) > 0
                    THEN ROUND(v_user.pvp_wins::NUMERIC / (v_user.pvp_wins + v_user.pvp_losses) * 100, 1)
                    ELSE 0 END
    );
END;
$$;

NOTIFY pgrst, 'reload schema';
