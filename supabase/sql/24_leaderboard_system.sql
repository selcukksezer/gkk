-- ============================================================
-- LEADERBOARD SYSTEM — gkk-web uyumlu
-- Kaynak: scenes/ui/screens/LeaderboardScreen.gd
-- RPCs: get_leaderboard, get_player_rank, get_season_leaderboard
-- ============================================================

-- ============================================================
-- 1. RPC: get_leaderboard
-- Godot: LeaderboardManager.fetch_leaderboard()
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_leaderboard(
    p_type   TEXT DEFAULT 'level',  -- level, pvp_rating, gold, guild_power
    p_limit  INT  DEFAULT 100
)
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

    CASE p_type
        WHEN 'level' THEN
            SELECT jsonb_agg(
                jsonb_build_object(
                    'rank',         ROW_NUMBER() OVER (ORDER BY u.level DESC, u.xp DESC),
                    'user_id',      u.auth_id,
                    'username',     u.username,
                    'display_name', u.display_name,
                    'level',        u.level,
                    'xp',           u.xp,
                    'guild_name',   NULL,
                    'is_me',        (u.auth_id = v_user_id)
                )
            )
            INTO v_result
            FROM (
                SELECT * FROM public.users
                ORDER BY level DESC, xp DESC
                LIMIT p_limit
            ) u;

        WHEN 'pvp_rating' THEN
            SELECT jsonb_agg(
                jsonb_build_object(
                    'rank',         ROW_NUMBER() OVER (ORDER BY u.pvp_rating DESC),
                    'user_id',      u.auth_id,
                    'username',     u.username,
                    'display_name', u.display_name,
                    'level',        u.level,
                    'pvp_rating',   u.pvp_rating,
                    'pvp_wins',     u.pvp_wins,
                    'pvp_losses',   u.pvp_losses,
                    'is_me',        (u.auth_id = v_user_id)
                )
            )
            INTO v_result
            FROM (
                SELECT * FROM public.users
                ORDER BY pvp_rating DESC
                LIMIT p_limit
            ) u;

        WHEN 'gold' THEN
            SELECT jsonb_agg(
                jsonb_build_object(
                    'rank',         ROW_NUMBER() OVER (ORDER BY u.gold DESC),
                    'user_id',      u.auth_id,
                    'username',     u.username,
                    'display_name', u.display_name,
                    'level',        u.level,
                    'gold',         u.gold,
                    'is_me',        (u.auth_id = v_user_id)
                )
            )
            INTO v_result
            FROM (
                SELECT * FROM public.users
                ORDER BY gold DESC
                LIMIT p_limit
            ) u;

        WHEN 'guild_power' THEN
            SELECT jsonb_agg(
                jsonb_build_object(
                    'rank',          ROW_NUMBER() OVER (ORDER BY g.total_power DESC),
                    'guild_id',      g.id,
                    'guild_name',    g.name,
                    'guild_tag',     g.tag,
                    'level',         g.level,
                    'total_power',   g.total_power,
                    'member_count',  g.member_count,
                    'is_my_guild',   EXISTS(SELECT 1 FROM public.users WHERE auth_id = v_user_id AND guild_id = g.id)
                )
            )
            INTO v_result
            FROM (
                SELECT * FROM public.guilds
                ORDER BY total_power DESC
                LIMIT p_limit
            ) g;

        ELSE
            RETURN jsonb_build_object('success', false, 'error', 'Geçersiz sıralama türü');
    END CASE;

    RETURN jsonb_build_object(
        'type',    p_type,
        'entries', COALESCE(v_result, '[]'::jsonb)
    );
END;
$$;

-- ============================================================
-- 2. RPC: get_player_rank
-- Godot: LeaderboardScreen — show player's own rank
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_player_rank(p_type TEXT DEFAULT 'level')
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id UUID;
    v_rank    BIGINT;
    v_user    RECORD;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT * INTO v_user FROM public.users WHERE auth_id = v_user_id;

    CASE p_type
        WHEN 'level' THEN
            SELECT COUNT(*) + 1 INTO v_rank FROM public.users WHERE level > v_user.level OR (level = v_user.level AND xp > v_user.xp);
        WHEN 'pvp_rating' THEN
            SELECT COUNT(*) + 1 INTO v_rank FROM public.users WHERE pvp_rating > v_user.pvp_rating;
        WHEN 'gold' THEN
            SELECT COUNT(*) + 1 INTO v_rank FROM public.users WHERE gold > v_user.gold;
        ELSE
            v_rank := 0;
    END CASE;

    RETURN jsonb_build_object(
        'rank',       v_rank,
        'type',       p_type,
        'value',      CASE p_type
                         WHEN 'level'      THEN v_user.level
                         WHEN 'pvp_rating' THEN v_user.pvp_rating
                         WHEN 'gold'       THEN v_user.gold
                         ELSE 0 END,
        'username',   v_user.username
    );
END;
$$;

-- ============================================================
-- 3. RPC: get_nearby_players (show players near current rank)
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_nearby_players(
    p_type  TEXT DEFAULT 'level',
    p_range INT  DEFAULT 5
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id UUID;
    v_rank    BIGINT;
    v_result  JSONB;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    -- Get own rank first
    SELECT (get_player_rank(p_type))->>'rank' INTO v_rank;

    -- Return players at rank ± range
    CASE p_type
        WHEN 'level' THEN
            SELECT jsonb_agg(
                jsonb_build_object(
                    'rank',     sub.rn,
                    'username', sub.username,
                    'level',    sub.level,
                    'is_me',    (sub.auth_id = v_user_id)
                )
            )
            INTO v_result
            FROM (
                SELECT auth_id, username, level, xp,
                       ROW_NUMBER() OVER (ORDER BY level DESC, xp DESC) AS rn
                FROM public.users
            ) sub
            WHERE sub.rn BETWEEN GREATEST(1, v_rank - p_range) AND v_rank + p_range;

        WHEN 'pvp_rating' THEN
            SELECT jsonb_agg(
                jsonb_build_object(
                    'rank',       sub.rn,
                    'username',   sub.username,
                    'pvp_rating', sub.pvp_rating,
                    'is_me',      (sub.auth_id = v_user_id)
                )
            )
            INTO v_result
            FROM (
                SELECT auth_id, username, pvp_rating,
                       ROW_NUMBER() OVER (ORDER BY pvp_rating DESC) AS rn
                FROM public.users
            ) sub
            WHERE sub.rn BETWEEN GREATEST(1, v_rank - p_range) AND v_rank + p_range;

        ELSE v_result := '[]'::jsonb;
    END CASE;

    RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

NOTIFY pgrst, 'reload schema';
