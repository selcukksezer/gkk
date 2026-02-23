-- ============================================================
-- EVENTS SYSTEM — gkk-web uyumlu
-- Kaynak: scenes/ui/screens/EventScreen.gd
-- RPCs: get_events, participate_event, claim_event_reward
-- ============================================================

-- ============================================================
-- 1. EVENTS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.game_events (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id        TEXT        UNIQUE NOT NULL,
    title           TEXT        NOT NULL,
    description     TEXT,
    type            TEXT        NOT NULL DEFAULT 'combat', -- combat, crafting, pvp, social, special
    status          TEXT        NOT NULL DEFAULT 'active', -- upcoming, active, past
    reward_type     TEXT        NOT NULL DEFAULT 'gold',   -- gold, gems, items, xp
    reward_amount   INT         NOT NULL DEFAULT 0,
    reward_items    JSONB       NOT NULL DEFAULT '[]',
    goal_type       TEXT        NOT NULL DEFAULT 'count',
    goal_target     TEXT,
    goal_count      INT         NOT NULL DEFAULT 1,
    max_participants INT,
    participant_count INT       NOT NULL DEFAULT 0,
    min_level       INT         NOT NULL DEFAULT 1,
    energy_cost     INT         NOT NULL DEFAULT 0,
    starts_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ends_at         TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '7 days'),
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_game_events_status ON public.game_events(status);
CREATE INDEX IF NOT EXISTS idx_game_events_ends_at ON public.game_events(ends_at);

-- ============================================================
-- 2. PLAYER EVENT PARTICIPATION TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.player_events (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    event_id        TEXT        NOT NULL REFERENCES public.game_events(event_id),
    progress        INT         NOT NULL DEFAULT 0,
    goal            INT         NOT NULL DEFAULT 1,
    status          TEXT        NOT NULL DEFAULT 'active', -- active, completed, claimed
    joined_at       TIMESTAMPTZ DEFAULT NOW(),
    completed_at    TIMESTAMPTZ,
    claimed_at      TIMESTAMPTZ,
    UNIQUE(user_id, event_id)
);

CREATE INDEX IF NOT EXISTS idx_player_events_user_id ON public.player_events(user_id);
CREATE INDEX IF NOT EXISTS idx_player_events_event_id ON public.player_events(event_id);

-- ============================================================
-- 3. SEED EVENT DATA
-- ============================================================
INSERT INTO public.game_events (event_id, title, description, type, status, reward_type, reward_amount, goal_type, goal_count, min_level, starts_at, ends_at)
VALUES
  ('event_weekly_dungeon_blitz', 'Zindan Saldırısı', 'Bu hafta 5 zindan tamamla ve özel ödül kazan!',
   'combat', 'active', 'gems', 30, 'dungeon_clear', 5, 1, NOW(), NOW() + INTERVAL '7 days'),
  ('event_pvp_tournament',       'PvP Turnuvası',    'En fazla galibiyet al ve şampiyonluk kupunu kaz!',
   'pvp', 'active', 'gold', 5000, 'pvp_win', 10, 5, NOW(), NOW() + INTERVAL '3 days'),
  ('event_crafting_frenzy',      'Üretim Çılgınlığı','10 eşya üret ve nadir ödüller kazan.',
   'crafting', 'active', 'gems', 20, 'craft_count', 10, 3, NOW(), NOW() + INTERVAL '5 days'),
  ('event_season_finale',        'Sezon Finali',     'Sezon sonunda en iyi oyuncular özel unvanlar alacak!',
   'special', 'upcoming', 'items', 0, 'pvp_win', 50, 10, NOW() + INTERVAL '14 days', NOW() + INTERVAL '21 days'),
  ('event_guild_war_weekend',    'Lonca Savaş Haftası','Loncanızla savaş ve bölge fethede!',
   'pvp', 'upcoming', 'gold', 20000, 'guild_war', 1, 15, NOW() + INTERVAL '3 days', NOW() + INTERVAL '7 days'),
  ('event_past_spring_festival', 'Bahar Festivali',  'Geçen ayın bahar festivali etkinliği.',
   'social', 'past', 'gems', 50, 'craft_count', 5, 1, NOW() - INTERVAL '30 days', NOW() - INTERVAL '23 days')
ON CONFLICT (event_id) DO NOTHING;

-- ============================================================
-- 4. RPC: get_events
-- Godot: EventScreen — http_get("/v1/events/active")
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_events(p_filter TEXT DEFAULT 'active')
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

    -- Auto-update event status
    UPDATE public.game_events SET status = 'active' WHERE status = 'upcoming' AND starts_at <= NOW() AND ends_at > NOW();
    UPDATE public.game_events SET status = 'past'   WHERE status = 'active'   AND ends_at <= NOW();

    SELECT jsonb_agg(
        jsonb_build_object(
            'id',                ge.id,
            'event_id',          ge.event_id,
            'title',             ge.title,
            'description',       ge.description,
            'type',              ge.type,
            'status',            ge.status,
            'reward_type',       ge.reward_type,
            'reward_amount',     ge.reward_amount,
            'reward_items',      ge.reward_items,
            'goal_type',         ge.goal_type,
            'goal_count',        ge.goal_count,
            'participant_count', ge.participant_count,
            'min_level',         ge.min_level,
            'energy_cost',       ge.energy_cost,
            'starts_at',         ge.starts_at,
            'ends_at',           ge.ends_at,
            'seconds_until_end', GREATEST(0, EXTRACT(EPOCH FROM (ge.ends_at - NOW()))::INT),
            'my_progress',       COALESCE(pe.progress, 0),
            'my_status',         COALESCE(pe.status, 'not_joined'),
            'is_joined',         (pe.id IS NOT NULL)
        )
        ORDER BY ge.ends_at ASC
    )
    INTO v_result
    FROM public.game_events ge
    LEFT JOIN public.player_events pe ON pe.event_id = ge.event_id AND pe.user_id = v_user_id
    WHERE (p_filter = 'all' OR ge.status = p_filter);

    RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

-- ============================================================
-- 5. RPC: participate_event
-- Godot: EventScreen — http_post("/v1/events/participate")
-- ============================================================
CREATE OR REPLACE FUNCTION public.participate_event(p_event_id TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id UUID;
    v_user    RECORD;
    v_event   RECORD;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT * INTO v_event FROM public.game_events WHERE event_id = p_event_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Etkinlik bulunamadı');
    END IF;

    IF v_event.status <> 'active' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Etkinlik aktif değil');
    END IF;

    IF v_event.ends_at <= NOW() THEN
        RETURN jsonb_build_object('success', false, 'error', 'Etkinlik süresi dolmuş');
    END IF;

    SELECT * INTO v_user FROM public.users WHERE auth_id = v_user_id;
    IF v_user.level < v_event.min_level THEN
        RETURN jsonb_build_object('success', false, 'error', format('Seviye %s gerekli', v_event.min_level));
    END IF;

    IF v_event.energy_cost > 0 AND v_user.energy < v_event.energy_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Yetersiz enerji');
    END IF;

    -- Join event
    INSERT INTO public.player_events (user_id, event_id, progress, goal, status)
    VALUES (v_user_id, p_event_id, 0, v_event.goal_count, 'active')
    ON CONFLICT (user_id, event_id) DO NOTHING;

    -- Deduct energy if needed
    IF v_event.energy_cost > 0 THEN
        UPDATE public.users SET energy = energy - v_event.energy_cost, updated_at = NOW() WHERE auth_id = v_user_id;
    END IF;

    -- Update participant count
    UPDATE public.game_events SET participant_count = participant_count + 1 WHERE event_id = p_event_id;

    RETURN jsonb_build_object('success', TRUE, 'event_id', p_event_id);
END;
$$;

-- ============================================================
-- 6. RPC: claim_event_reward
-- Godot: EventScreen — http_post("/v1/events/claim_reward")
-- ============================================================
CREATE OR REPLACE FUNCTION public.claim_event_reward(p_event_id TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id  UUID;
    v_pe       RECORD;
    v_event    RECORD;
    v_new_xp   BIGINT;
    v_level    INT;
    v_xp_threshold BIGINT;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT * INTO v_pe FROM public.player_events WHERE user_id = v_user_id AND event_id = p_event_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Etkinliğe katılmadınız');
    END IF;

    IF v_pe.status = 'claimed' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Ödül zaten alındı');
    END IF;

    IF v_pe.status <> 'completed' AND v_pe.progress < v_pe.goal THEN
        RETURN jsonb_build_object(
            'success',  FALSE,
            'error',    'Etkinlik henüz tamamlanmadı',
            'progress', v_pe.progress,
            'goal',     v_pe.goal
        );
    END IF;

    SELECT * INTO v_event FROM public.game_events WHERE event_id = p_event_id;

    -- Apply rewards
    CASE v_event.reward_type
        WHEN 'gold' THEN
            UPDATE public.users SET gold = gold + v_event.reward_amount, updated_at = NOW() WHERE auth_id = v_user_id;
        WHEN 'gems' THEN
            UPDATE public.users SET gems = gems + v_event.reward_amount, updated_at = NOW() WHERE auth_id = v_user_id;
        WHEN 'xp' THEN
            SELECT xp, level INTO v_new_xp, v_level FROM public.users WHERE auth_id = v_user_id;
            v_new_xp := COALESCE(v_new_xp, 0) + v_event.reward_amount;
            v_xp_threshold := floor(1000 * pow(v_level::NUMERIC, 1.5))::BIGINT;
            WHILE v_new_xp >= v_xp_threshold LOOP
                v_new_xp := v_new_xp - v_xp_threshold;
                v_level  := v_level + 1;
                v_xp_threshold := floor(1000 * pow(v_level::NUMERIC, 1.5))::BIGINT;
            END LOOP;
            UPDATE public.users SET xp = v_new_xp, level = v_level, updated_at = NOW() WHERE auth_id = v_user_id;
        ELSE NULL;
    END CASE;

    -- Mark as claimed
    UPDATE public.player_events SET status = 'claimed', claimed_at = NOW() WHERE user_id = v_user_id AND event_id = p_event_id;

    RETURN jsonb_build_object(
        'success',       TRUE,
        'reward_type',   v_event.reward_type,
        'reward_amount', v_event.reward_amount,
        'reward_items',  v_event.reward_items
    );
END;
$$;

-- ============================================================
-- 7. RPC: update_event_progress (internal — called by dungeon/pvp/craft RPCs)
-- ============================================================
CREATE OR REPLACE FUNCTION public.update_event_progress(
    p_user_id  UUID,
    p_goal_type TEXT,
    p_amount    INT DEFAULT 1
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
BEGIN
    UPDATE public.player_events pe
    SET progress = LEAST(pe.goal, pe.progress + p_amount),
        status   = CASE WHEN LEAST(pe.goal, pe.progress + p_amount) >= pe.goal
                        THEN 'completed' ELSE 'active' END,
        completed_at = CASE WHEN LEAST(pe.goal, pe.progress + p_amount) >= pe.goal
                            THEN NOW() ELSE NULL END
    FROM public.game_events ge
    WHERE pe.event_id = ge.event_id
      AND pe.user_id = p_user_id
      AND pe.status = 'active'
      AND ge.status = 'active'
      AND ge.ends_at > NOW()
      AND ge.goal_type = p_goal_type;
END;
$$;

NOTIFY pgrst, 'reload schema';
