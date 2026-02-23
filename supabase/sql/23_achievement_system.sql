-- ============================================================
-- ACHIEVEMENT SYSTEM — gkk-web uyumlu
-- Kaynak: scenes/ui/screens/AchievementScreen.gd
-- RPCs: get_achievements, claim_achievement, get_achievement_stats
-- ============================================================

-- ============================================================
-- 1. ACHIEVEMENT DEFINITIONS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.achievement_definitions (
    id              TEXT    PRIMARY KEY,
    title           TEXT    NOT NULL,
    description     TEXT,
    category        TEXT    NOT NULL DEFAULT 'general', -- combat, craft, social, exploration, pvp, dungeon, economy
    icon            TEXT    DEFAULT '🏅',
    rarity          TEXT    NOT NULL DEFAULT 'common',  -- common, uncommon, rare, epic, legendary
    goal_type       TEXT    NOT NULL DEFAULT 'count',
    goal_target     TEXT,
    goal_count      INT     NOT NULL DEFAULT 1,
    reward_type     TEXT    NOT NULL DEFAULT 'title',   -- title, gems, gold, item
    reward_amount   INT     NOT NULL DEFAULT 0,
    reward_title    TEXT,
    reward_item_id  TEXT,
    is_hidden       BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order      INT     NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 2. PLAYER ACHIEVEMENTS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.player_achievements (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    achievement_id  TEXT        NOT NULL REFERENCES public.achievement_definitions(id),
    progress        INT         NOT NULL DEFAULT 0,
    is_completed    BOOLEAN     NOT NULL DEFAULT FALSE,
    is_claimed      BOOLEAN     NOT NULL DEFAULT FALSE,
    completed_at    TIMESTAMPTZ,
    claimed_at      TIMESTAMPTZ,
    UNIQUE(user_id, achievement_id)
);

CREATE INDEX IF NOT EXISTS idx_player_achievements_user_id ON public.player_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_player_achievements_completed ON public.player_achievements(user_id, is_completed);

-- ============================================================
-- 3. SEED ACHIEVEMENT DATA (Godot AchievementManager content)
-- ============================================================
INSERT INTO public.achievement_definitions (id, title, description, category, icon, rarity, goal_type, goal_count, reward_type, reward_amount, reward_title, sort_order)
VALUES
  -- COMBAT
  ('ach_first_dungeon',    'İlk Zindan',       'İlk zindanına gir.',             'dungeon', '🏰', 'common',    'enter_dungeon',  1,  'gems',  5,  NULL, 10),
  ('ach_dungeon_10',       'Zindan Kaşifi',    '10 zindan tamamla.',             'dungeon', '🗺️', 'uncommon',  'dungeon_clear',  10, 'gems',  20, 'Zindan Kaşifi', 20),
  ('ach_dungeon_50',       'Zindan Üstadı',    '50 zindan tamamla.',             'dungeon', '⚔️', 'rare',      'dungeon_clear',  50, 'gems',  50, 'Zindan Üstadı', 30),
  ('ach_dungeon_100',      'Zindan Lordu',     '100 zindan tamamla.',            'dungeon', '🔱', 'epic',      'dungeon_clear',  100,'gems', 100, 'Zindan Lordu', 40),
  ('ach_dragon_slayer',    'Ejderha Avcısı',   'Ejderha Yuvasını tamamla.',      'dungeon', '🐉', 'legendary', 'dungeon_clear',  1,  'gems',  200,'Ejderha Katili', 50),

  -- PvP
  ('ach_first_pvp',        'Savaşçı',          'İlk PvP savaşını yap.',          'pvp',     '⚔️', 'common',    'pvp_battle',     1,  'gems',  5,  NULL, 10),
  ('ach_pvp_10',           'Arena Savaşçısı',  '10 PvP savaşı yap.',            'pvp',     '🏟️', 'uncommon',  'pvp_battle',     10, 'gems',  15, NULL, 20),
  ('ach_pvp_win_10',       'Arena Şampiyonu',  '10 PvP galibiyeti kazan.',      'pvp',     '🏆', 'rare',      'pvp_win',        10, 'gems',  30, 'Arena Şampiyonu', 30),
  ('ach_pvp_win_50',       'Arena Efsanesi',   '50 PvP galibiyeti kazan.',      'pvp',     '👑', 'epic',      'pvp_win',        50, 'gems',  80, 'Arena Efsanesi', 40),
  ('ach_pvp_win_rate',     'Bozulmaz',         'PvP kazanma oranı %80+.',       'pvp',     '⚡', 'legendary', 'pvp_win_rate',   80, 'gems',  150,'Yenilmez', 50),

  -- CRAFTING
  ('ach_first_craft',      'Zanaatçı',         'İlk eşyayı üret.',              'craft',   '🔨', 'common',    'craft_count',    1,  'gems',  5,  NULL, 10),
  ('ach_craft_10',         'Usta Zanaatçı',    '10 eşya üret.',                 'craft',   '⚒️', 'uncommon',  'craft_count',    10, 'gems',  20, 'Usta Zanaatçı', 20),
  ('ach_craft_50',         'Demirci Üstadı',   '50 eşya üret.',                 'craft',   '🏭', 'rare',      'craft_count',    50, 'gems',  50, 'Demirci Üstadı', 30),
  ('ach_craft_legendary',  'Efsane Ustası',    'Efsanevi nadirlikteki eşya üret.','craft', '✨', 'legendary', 'craft_legendary',1,  'gems',  200,'Efsane Ustası', 40),

  -- SOCIAL/GUILD
  ('ach_join_guild',       'Lonca Üyesi',      'Bir loncaya katıl.',             'social',  '🏰', 'common',    'join_guild',     1,  'gems',  10, 'Lonca Üyesi', 10),
  ('ach_guild_officer',    'Lonca Subayı',     'Bir loncada subay ol.',          'social',  '⭐', 'uncommon',  'guild_officer',  1,  'gems',  25, 'Lonca Subayı', 20),
  ('ach_guild_leader',     'Lonca Lideri',     'Bir loncayı yönet.',            'social',  '👑', 'rare',      'guild_leader',   1,  'gems',  50, 'Lonca Lideri', 30),
  ('ach_trade_10',         'Tüccar',           '10 ticaret yap.',               'social',  '💱', 'uncommon',  'trade_count',    10, 'gems',  20, 'Tüccar', 40),

  -- ECONOMY
  ('ach_gold_1k',          'Para Sahibi',      '1000 altın biriktir.',           'economy', '🪙', 'common',    'gold_total',     1000, 'gems', 5, NULL, 10),
  ('ach_gold_10k',         'Zengin',           '10000 altın biriktir.',          'economy', '💰', 'uncommon',  'gold_total',     10000,'gems', 15, 'Zengin', 20),
  ('ach_gold_100k',        'Midas Dokunuşu',   '100000 altın biriktir.',         'economy', '🏦', 'rare',      'gold_total',     100000,'gems',50,'Altın El', 30),

  -- EXPLORATION
  ('ach_level_10',         'Tecrübeli',        'Seviye 10 ulaş.',               'exploration','📊','common',   'level_reach',    10,  'gems', 10, NULL, 10),
  ('ach_level_25',         'Güçlü Kahraman',   'Seviye 25 ulaş.',               'exploration','⚡','uncommon', 'level_reach',    25,  'gems', 30, NULL, 20),
  ('ach_level_50',         'Efsane Kahraman',  'Seviye 50 ulaş.',               'exploration','🌟','epic',     'level_reach',    50,  'gems', 80, 'Efsane', 30),
  ('ach_level_99',         'İlah',             'Azami seviyeye ulaş.',           'exploration','🔱','legendary','level_reach',    99,  'gems',500, 'İlah', 40),

  -- FACILITY/PRODUCTION
  ('ach_unlock_facility',  'Girişimci',        'İlk tesisini aç.',              'economy', '🏭', 'common',    'unlock_facility',1,  'gems', 10, NULL, 10),
  ('ach_facility_5',       'Endüstriyel',      '5 tesis aç.',                   'economy', '⚙️', 'uncommon',  'unlock_facility',5,  'gems', 30, 'Sanayici', 20),
  ('ach_collect_100',      'Toplayıcı',        '100 kaynak topla.',             'economy', '📦', 'uncommon',  'collect_resources',100,'gems',20, NULL, 30)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 4. RPC: get_achievements
-- Godot: AchievementScreen — http_get("/v1/achievements")
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_achievements(p_category TEXT DEFAULT 'all')
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

    -- Ensure all achievement rows exist for this user
    INSERT INTO public.player_achievements (user_id, achievement_id, progress)
    SELECT v_user_id, ad.id, 0
    FROM public.achievement_definitions ad
    WHERE NOT EXISTS (
        SELECT 1 FROM public.player_achievements pa
        WHERE pa.user_id = v_user_id AND pa.achievement_id = ad.id
    )
    AND (ad.is_hidden = FALSE);

    SELECT jsonb_agg(
        jsonb_build_object(
            'id',            ad.id,
            'title',         ad.title,
            'description',   ad.description,
            'category',      ad.category,
            'icon',          ad.icon,
            'rarity',        ad.rarity,
            'goal_count',    ad.goal_count,
            'reward_type',   ad.reward_type,
            'reward_amount', ad.reward_amount,
            'reward_title',  ad.reward_title,
            'progress',      COALESCE(pa.progress, 0),
            'is_completed',  COALESCE(pa.is_completed, FALSE),
            'is_claimed',    COALESCE(pa.is_claimed, FALSE),
            'completed_at',  pa.completed_at,
            'pct',           LEAST(100, ROUND(COALESCE(pa.progress, 0)::NUMERIC / ad.goal_count * 100))
        )
        ORDER BY ad.sort_order, ad.rarity
    )
    INTO v_result
    FROM public.achievement_definitions ad
    LEFT JOIN public.player_achievements pa ON pa.achievement_id = ad.id AND pa.user_id = v_user_id
    WHERE ad.is_hidden = FALSE
      AND (p_category = 'all' OR ad.category = p_category);

    RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

-- ============================================================
-- 5. RPC: claim_achievement
-- Godot: AchievementScreen — http_post("/v1/achievements/claim")
-- ============================================================
CREATE OR REPLACE FUNCTION public.claim_achievement(p_achievement_id TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id UUID;
    v_pa      RECORD;
    v_ad      RECORD;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT * INTO v_pa FROM public.player_achievements WHERE user_id = v_user_id AND achievement_id = p_achievement_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Başarım bulunamadı');
    END IF;

    IF v_pa.is_claimed THEN
        RETURN jsonb_build_object('success', false, 'error', 'Ödül zaten alındı');
    END IF;

    IF NOT v_pa.is_completed THEN
        RETURN jsonb_build_object('success', false, 'error', 'Başarım henüz tamamlanmadı');
    END IF;

    SELECT * INTO v_ad FROM public.achievement_definitions WHERE id = p_achievement_id;

    -- Apply reward
    CASE v_ad.reward_type
        WHEN 'gems' THEN
            UPDATE public.users SET gems = gems + v_ad.reward_amount, updated_at = NOW() WHERE auth_id = v_user_id;
        WHEN 'gold' THEN
            UPDATE public.users SET gold = gold + v_ad.reward_amount, updated_at = NOW() WHERE auth_id = v_user_id;
        ELSE NULL;
    END CASE;

    UPDATE public.player_achievements SET is_claimed = TRUE, claimed_at = NOW() WHERE user_id = v_user_id AND achievement_id = p_achievement_id;

    RETURN jsonb_build_object(
        'success',       TRUE,
        'reward_type',   v_ad.reward_type,
        'reward_amount', v_ad.reward_amount,
        'reward_title',  v_ad.reward_title
    );
END;
$$;

-- ============================================================
-- 6. RPC: get_achievement_stats
-- Godot: AchievementScreen — summary stats
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_achievement_stats()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id   UUID;
    v_total     INT;
    v_completed INT;
    v_claimed   INT;
    v_points    INT;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT COUNT(*) INTO v_total FROM public.achievement_definitions WHERE is_hidden = FALSE;

    SELECT COUNT(*) INTO v_completed
    FROM public.player_achievements WHERE user_id = v_user_id AND is_completed = TRUE;

    SELECT COUNT(*) INTO v_claimed
    FROM public.player_achievements WHERE user_id = v_user_id AND is_claimed = TRUE;

    SELECT COALESCE(SUM(CASE ad.rarity WHEN 'legendary' THEN 50 WHEN 'epic' THEN 20 WHEN 'rare' THEN 10 WHEN 'uncommon' THEN 5 ELSE 1 END), 0) INTO v_points
    FROM public.player_achievements pa
    JOIN public.achievement_definitions ad ON ad.id = pa.achievement_id
    WHERE pa.user_id = v_user_id AND pa.is_completed = TRUE;

    RETURN jsonb_build_object(
        'total',         v_total,
        'completed',     v_completed,
        'claimed',       v_claimed,
        'pending_claim', v_completed - v_claimed,
        'completion_pct',CASE WHEN v_total > 0 THEN ROUND(v_completed::NUMERIC / v_total * 100) ELSE 0 END,
        'points',        v_points
    );
END;
$$;

-- ============================================================
-- 7. Internal: update_achievement_progress (called by other RPCs)
-- ============================================================
CREATE OR REPLACE FUNCTION public.update_achievement_progress(
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
    -- Upsert progress
    INSERT INTO public.player_achievements (user_id, achievement_id, progress)
    SELECT p_user_id, ad.id, LEAST(ad.goal_count, p_amount)
    FROM public.achievement_definitions ad
    WHERE ad.goal_type = p_goal_type
    ON CONFLICT (user_id, achievement_id) DO UPDATE
        SET progress = LEAST(
            achievement_definitions.goal_count,
            public.player_achievements.progress + p_amount
        ),
        is_completed = CASE
            WHEN LEAST(achievement_definitions.goal_count, public.player_achievements.progress + p_amount) >= achievement_definitions.goal_count
            THEN TRUE ELSE public.player_achievements.is_completed END,
        completed_at = CASE
            WHEN public.player_achievements.is_completed = FALSE
              AND LEAST(achievement_definitions.goal_count, public.player_achievements.progress + p_amount) >= achievement_definitions.goal_count
            THEN NOW() ELSE public.player_achievements.completed_at END
    FROM public.achievement_definitions;
END;
$$;

NOTIFY pgrst, 'reload schema';
