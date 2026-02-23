-- ============================================================
-- QUEST SYSTEM — gkk-web uyumlu
-- Kaynak: scenes/ui/screens/QuestScreen.gd (280 satır)
-- RPCs: get_available_quests, get_active_quests, start_quest, complete_quest
-- ============================================================

-- ============================================================
-- 1. QUEST DEFINITIONS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.quest_definitions (
    id              TEXT    PRIMARY KEY,
    title           TEXT    NOT NULL,
    description     TEXT,
    difficulty      TEXT    NOT NULL DEFAULT 'easy', -- easy, normal, hard, elite, dungeon
    type            TEXT    NOT NULL DEFAULT 'combat', -- combat, gather, craft, explore, social
    category        TEXT    NOT NULL DEFAULT 'main',  -- main, side, daily, weekly
    required_level  INT     NOT NULL DEFAULT 1,
    energy_cost     INT     NOT NULL DEFAULT 0,
    gold_reward     INT     NOT NULL DEFAULT 100,
    xp_reward       INT     NOT NULL DEFAULT 100,
    gem_reward      INT     NOT NULL DEFAULT 0,
    item_rewards    JSONB   NOT NULL DEFAULT '[]',
    goal_type       TEXT    NOT NULL DEFAULT 'count', -- count, kill, collect, craft
    goal_target     TEXT,   -- what to complete (e.g. 'goblin', 'iron_ore')
    goal_count      INT     NOT NULL DEFAULT 1,
    duration_hours  INT     NOT NULL DEFAULT 24,  -- time limit
    is_repeatable   BOOLEAN NOT NULL DEFAULT FALSE,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_quest_definitions_difficulty ON public.quest_definitions(difficulty);
CREATE INDEX IF NOT EXISTS idx_quest_definitions_required_level ON public.quest_definitions(required_level);
CREATE INDEX IF NOT EXISTS idx_quest_definitions_category ON public.quest_definitions(category);

-- ============================================================
-- 2. PLAYER QUESTS TABLE (active/completed)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.player_quests (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    quest_id        TEXT        NOT NULL REFERENCES public.quest_definitions(id),
    status          TEXT        NOT NULL DEFAULT 'active', -- active, completed, failed, claimed
    progress        INT         NOT NULL DEFAULT 0,
    goal            INT         NOT NULL DEFAULT 1,
    started_at      TIMESTAMPTZ DEFAULT NOW(),
    completed_at    TIMESTAMPTZ,
    expires_at      TIMESTAMPTZ,
    UNIQUE(user_id, quest_id)
);

CREATE INDEX IF NOT EXISTS idx_player_quests_user_id ON public.player_quests(user_id);
CREATE INDEX IF NOT EXISTS idx_player_quests_status ON public.player_quests(status);
CREATE INDEX IF NOT EXISTS idx_player_quests_user_status ON public.player_quests(user_id, status);

-- ============================================================
-- 3. SEED QUEST DATA (matching Godot QuestManager content)
-- ============================================================
INSERT INTO public.quest_definitions (id, title, description, difficulty, type, category, required_level, energy_cost, gold_reward, xp_reward, gem_reward, goal_type, goal_target, goal_count, duration_hours, is_repeatable)
VALUES
  -- Ana Görevler (Main Quests)
  ('quest_first_steps',         'İlk Adımlar',          'Oyunu keşfet ve ilk zindanına gir.',                      'easy',   'explore', 'main', 1,  0, 200,  150,  5,  'enter_dungeon',  'any',           1,  72, FALSE),
  ('quest_goblin_slayer',       'Goblin Avcısı',         'Goblin Mağarasını 3 kez temizle.',                        'easy',   'combat',  'main', 5,  0, 500,  400,  0,  'dungeon_clear',  'dungeon_goblin_cave', 3, 168, FALSE),
  ('quest_master_crafter',      'Usta Zanaatçı',         '5 farklı tarifi üret.',                                   'normal', 'craft',   'main', 10, 0, 1000, 800,  10, 'craft_count',    'any',           5,  168, FALSE),
  ('quest_pvp_champion',        'PvP Şampiyonu',         '10 PvP savaşı kazan.',                                    'hard',   'combat',  'main', 15, 0, 2000, 1500, 20, 'pvp_win',        'any',           10, 336, FALSE),
  ('quest_guild_member',        'Lonca Üyesi',           'Bir loncaya katıl.',                                      'easy',   'social',  'main', 5,  0, 300,  200,  5,  'join_guild',     'any',           1,  72,  FALSE),
  ('quest_shadow_lord',         'Gölge Lordu',           'Gölge Kalesi zindanını tamamla.',                         'elite',  'combat',  'main', 40, 0, 10000,5000, 50, 'dungeon_clear',  'dungeon_shadow_citadel', 1, 720, FALSE),

  -- Günlük Görevler (Daily Quests)
  ('quest_daily_dungeon',       'Günlük Zindan',         'Bugün en az 1 zindana gir.',                              'easy',   'combat',  'daily', 1, 0, 300,  200,  2,  'enter_dungeon',  'any',           1,  24, TRUE),
  ('quest_daily_pvp',           'Günlük Dövüş',          'Bugün 3 PvP savaşı yap.',                                 'easy',   'combat',  'daily', 5, 0, 400,  300,  3,  'pvp_battle',     'any',           3,  24, TRUE),
  ('quest_daily_craft',         'Günlük Üretim',         'Bugün 2 eşya üret.',                                      'easy',   'craft',   'daily', 3, 0, 250,  200,  2,  'craft_count',    'any',           2,  24, TRUE),
  ('quest_daily_facility',      'Günlük Tesis',          'Bugün bir tesisten kaynak topla.',                        'easy',   'gather',  'daily', 3, 0, 200,  150,  1,  'collect_resources','any',         1,  24, TRUE),

  -- Haftalık Görevler (Weekly Quests)
  ('quest_weekly_dungeons',     'Haftalık Macera',       'Bu hafta 10 zindan tamamla.',                             'normal', 'combat',  'weekly',5, 0, 2000, 1500, 10, 'dungeon_clear',  'any',           10, 168, TRUE),
  ('quest_weekly_pvp',          'Haftalık Arena',        'Bu hafta 20 PvP savaşı kazan.',                           'hard',   'combat',  'weekly',10, 0, 5000, 3000, 20, 'pvp_win',        'any',           20, 168, TRUE),
  ('quest_weekly_crafting',     'Haftalık Zanaat',       'Bu hafta 10 eşya üret.',                                  'normal', 'craft',   'weekly',5,  0, 3000, 2000, 15, 'craft_count',    'any',           10, 168, TRUE),

  -- Yan Görevler (Side Quests)
  ('quest_market_trader',       'Pazar Tüccarı',         'Pazarda 5 eşya sat.',                                     'easy',   'social',  'side', 5, 0, 800, 600, 5,  'sell_items',     'any',           5,  336, FALSE),
  ('quest_bank_investor',       'Banka Yatırımcısı',     'Bankaya 5 eşya yatır.',                                   'easy',   'social',  'side', 5, 0, 500, 400, 3,  'deposit_items',  'any',           5,  336, FALSE),
  ('quest_dragon_hunter',       'Ejderha Avcısı',        'Ejderha Yuvasını 3 kez tamamla.',                         'elite',  'combat',  'side', 25, 0, 8000,4000, 30, 'dungeon_clear',  'dungeon_dragon_lair', 3, 720, FALSE),
  ('quest_reputation_seeker',   'İtibar Kazananı',       'İtibarını 100 artır.',                                    'normal', 'social',  'side', 10, 0, 1000, 800, 5, 'reputation_gain','any',           100, 336, FALSE)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 4. RPC: get_available_quests
-- Godot: QuestManager.get_available_quests()
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_available_quests()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id UUID;
    v_level   INT;
    v_result  JSONB;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT COALESCE(level, 1) INTO v_level FROM public.users WHERE auth_id = v_user_id;

    SELECT jsonb_agg(
        jsonb_build_object(
            'id',             q.id,
            'title',          q.title,
            'description',    q.description,
            'difficulty',     q.difficulty,
            'type',           q.type,
            'category',       q.category,
            'required_level', q.required_level,
            'energy_cost',    q.energy_cost,
            'gold_reward',    q.gold_reward,
            'xp_reward',      q.xp_reward,
            'gem_reward',     q.gem_reward,
            'item_rewards',   q.item_rewards,
            'goal_type',      q.goal_type,
            'goal_target',    q.goal_target,
            'goal_count',     q.goal_count,
            'is_repeatable',  q.is_repeatable,
            'status',         'available',
            'progress',       0,
            'goal',           q.goal_count
        )
        ORDER BY q.required_level, q.difficulty
    )
    INTO v_result
    FROM public.quest_definitions q
    WHERE q.is_active = TRUE
      AND q.required_level <= v_level
      -- Not already active or completed (non-repeatable)
      AND NOT EXISTS (
          SELECT 1 FROM public.player_quests pq
          WHERE pq.user_id = v_user_id
            AND pq.quest_id = q.id
            AND pq.status IN ('active', 'completed', 'claimed')
            AND (q.is_repeatable = FALSE OR pq.status = 'active')
      );

    RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

-- ============================================================
-- 5. RPC: get_active_quests
-- Godot: QuestManager.get_active_quests() — used on HomeScreen too
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_active_quests()
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
            'id',             pq.id,
            'quest_id',       pq.quest_id,
            'title',          qd.title,
            'description',    qd.description,
            'difficulty',     qd.difficulty,
            'type',           qd.type,
            'category',       qd.category,
            'gold_reward',    qd.gold_reward,
            'xp_reward',      qd.xp_reward,
            'gem_reward',     qd.gem_reward,
            'item_rewards',   qd.item_rewards,
            'status',         pq.status,
            'progress',       pq.progress,
            'goal',           pq.goal,
            'started_at',     pq.started_at,
            'expires_at',     pq.expires_at
        )
        ORDER BY pq.started_at DESC
    )
    INTO v_result
    FROM public.player_quests pq
    JOIN public.quest_definitions qd ON qd.id = pq.quest_id
    WHERE pq.user_id = v_user_id
      AND pq.status = 'active';

    RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

-- ============================================================
-- 6. RPC: get_completed_quests
-- Godot: QuestManager.get_completed_quests()
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_completed_quests()
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
            'id',             pq.id,
            'quest_id',       pq.quest_id,
            'title',          qd.title,
            'description',    qd.description,
            'difficulty',     qd.difficulty,
            'gold_reward',    qd.gold_reward,
            'xp_reward',      qd.xp_reward,
            'status',         pq.status,
            'progress',       pq.progress,
            'goal',           pq.goal,
            'completed_at',   pq.completed_at
        )
        ORDER BY pq.completed_at DESC
    )
    INTO v_result
    FROM public.player_quests pq
    JOIN public.quest_definitions qd ON qd.id = pq.quest_id
    WHERE pq.user_id = v_user_id
      AND pq.status IN ('completed', 'claimed');

    RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

-- ============================================================
-- 7. RPC: start_quest
-- Godot: QuestManager.start_quest(quest_id)
-- ============================================================
CREATE OR REPLACE FUNCTION public.start_quest(p_quest_id TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id    UUID;
    v_level      INT;
    v_quest      RECORD;
    v_expires_at TIMESTAMPTZ;
    v_new_pq_id  UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT COALESCE(level, 1), energy INTO v_level FROM public.users WHERE auth_id = v_user_id;

    -- Load quest definition
    SELECT * INTO v_quest FROM public.quest_definitions WHERE id = p_quest_id AND is_active = TRUE;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Görev bulunamadı');
    END IF;

    -- Level check
    IF v_level < v_quest.required_level THEN
        RETURN jsonb_build_object('success', false, 'error', format('Seviye %s gerekli', v_quest.required_level));
    END IF;

    -- Check if already active
    IF EXISTS (
        SELECT 1 FROM public.player_quests
        WHERE user_id = v_user_id AND quest_id = p_quest_id AND status = 'active'
    ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Görev zaten aktif');
    END IF;

    -- For non-repeatable quests, check if already completed
    IF v_quest.is_repeatable = FALSE AND EXISTS (
        SELECT 1 FROM public.player_quests
        WHERE user_id = v_user_id AND quest_id = p_quest_id AND status IN ('completed', 'claimed')
    ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Bu görev zaten tamamlandı');
    END IF;

    -- Calculate expiry
    v_expires_at := NOW() + (v_quest.duration_hours || ' hours')::INTERVAL;

    -- Insert player quest
    INSERT INTO public.player_quests (user_id, quest_id, status, progress, goal, expires_at)
    VALUES (v_user_id, p_quest_id, 'active', 0, v_quest.goal_count, v_expires_at)
    ON CONFLICT (user_id, quest_id) DO UPDATE
        SET status = 'active', progress = 0, started_at = NOW(), expires_at = v_expires_at
    RETURNING id INTO v_new_pq_id;

    RETURN jsonb_build_object(
        'success',    TRUE,
        'quest_id',   p_quest_id,
        'id',         v_new_pq_id,
        'expires_at', v_expires_at
    );
END;
$$;

-- ============================================================
-- 8. RPC: update_quest_progress (internal helper, called by other RPCs)
-- ============================================================
CREATE OR REPLACE FUNCTION public.update_quest_progress(
    p_user_id   UUID,
    p_goal_type TEXT,
    p_target    TEXT DEFAULT 'any',
    p_amount    INT  DEFAULT 1
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_pq   RECORD;
    v_quest RECORD;
BEGIN
    FOR v_pq IN
        SELECT pq.id, pq.progress, pq.goal, pq.quest_id
        FROM public.player_quests pq
        JOIN public.quest_definitions qd ON qd.id = pq.quest_id
        WHERE pq.user_id = p_user_id
          AND pq.status = 'active'
          AND qd.goal_type = p_goal_type
          AND (qd.goal_target = 'any' OR qd.goal_target = p_target)
          AND (pq.expires_at IS NULL OR pq.expires_at > NOW())
    LOOP
        UPDATE public.player_quests
        SET progress = LEAST(v_pq.goal, progress + p_amount),
            status   = CASE WHEN LEAST(v_pq.goal, v_pq.progress + p_amount) >= v_pq.goal
                            THEN 'completed' ELSE 'active' END,
            completed_at = CASE WHEN LEAST(v_pq.goal, v_pq.progress + p_amount) >= v_pq.goal
                            THEN NOW() ELSE NULL END
        WHERE id = v_pq.id;
    END LOOP;
END;
$$;

-- ============================================================
-- 9. RPC: claim_quest_reward
-- Godot: QuestManager — claim completed quest reward
-- ============================================================
CREATE OR REPLACE FUNCTION public.claim_quest_reward(p_player_quest_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id UUID;
    v_pq      RECORD;
    v_quest   RECORD;
    v_new_xp  BIGINT;
    v_level   INT;
    v_xp_threshold BIGINT;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    -- Load player quest
    SELECT * INTO v_pq FROM public.player_quests WHERE id = p_player_quest_id AND user_id = v_user_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Görev bulunamadı');
    END IF;

    IF v_pq.status <> 'completed' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Görev henüz tamamlanmadı');
    END IF;

    -- Load quest definition for rewards
    SELECT * INTO v_quest FROM public.quest_definitions WHERE id = v_pq.quest_id;

    -- Apply rewards
    SELECT xp, level INTO v_new_xp, v_level FROM public.users WHERE auth_id = v_user_id;
    v_new_xp := COALESCE(v_new_xp, 0) + v_quest.xp_reward;
    v_xp_threshold := floor(1000 * pow(v_level::NUMERIC, 1.5))::BIGINT;

    WHILE v_new_xp >= v_xp_threshold LOOP
        v_new_xp   := v_new_xp - v_xp_threshold;
        v_level    := v_level + 1;
        v_xp_threshold := floor(1000 * pow(v_level::NUMERIC, 1.5))::BIGINT;
    END LOOP;

    UPDATE public.users
    SET gold  = gold + v_quest.gold_reward,
        gems  = gems + v_quest.gem_reward,
        xp    = v_new_xp,
        level = v_level,
        updated_at = NOW()
    WHERE auth_id = v_user_id;

    -- Mark as claimed
    UPDATE public.player_quests SET status = 'claimed' WHERE id = p_player_quest_id;

    RETURN jsonb_build_object(
        'success',      TRUE,
        'gold_reward',  v_quest.gold_reward,
        'xp_reward',    v_quest.xp_reward,
        'gem_reward',   v_quest.gem_reward,
        'item_rewards', v_quest.item_rewards
    );
END;
$$;

NOTIFY pgrst, 'reload schema';
