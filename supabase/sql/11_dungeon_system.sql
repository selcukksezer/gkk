-- ============================================================
-- DUNGEON SYSTEM — gkk-web uyumlu
-- Kaynak: scenes/ui/screens/DungeonScreen.gd + DungeonBattleScreen.gd
-- RPCs: get_dungeons, enter_dungeon
-- ============================================================

-- ============================================================
-- 1. DUNGEON DEFINITIONS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.dungeons (
    id            UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
    dungeon_id    TEXT    UNIQUE NOT NULL,
    name          TEXT    NOT NULL,
    description   TEXT,
    difficulty    TEXT    NOT NULL DEFAULT 'easy', -- easy, medium, hard, dungeon
    required_level INT   NOT NULL DEFAULT 1,
    min_level     INT    NOT NULL DEFAULT 1,
    max_players   INT    NOT NULL DEFAULT 1,
    energy_cost   INT    NOT NULL DEFAULT 5,
    min_gold      INT    NOT NULL DEFAULT 10,
    max_gold      INT    NOT NULL DEFAULT 100,
    xp_reward     INT    NOT NULL DEFAULT 50,
    base_gold_reward INT NOT NULL DEFAULT 50,
    base_xp_reward   INT NOT NULL DEFAULT 50,
    success_rate  NUMERIC(4,3) NOT NULL DEFAULT 0.80,
    is_group      BOOLEAN NOT NULL DEFAULT FALSE,
    loot_table    JSONB   NOT NULL DEFAULT '[]',
    boss_name     TEXT,
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    season_modifier NUMERIC(4,3) NOT NULL DEFAULT 1.0,
    created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_dungeons_difficulty ON public.dungeons(difficulty);
CREATE INDEX IF NOT EXISTS idx_dungeons_required_level ON public.dungeons(required_level);
CREATE INDEX IF NOT EXISTS idx_dungeons_is_active ON public.dungeons(is_active);

-- ============================================================
-- 2. DUNGEON RUNS TABLE (battle log)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.dungeon_runs (
    id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    dungeon_id    TEXT        NOT NULL,
    dungeon_name  TEXT        NOT NULL,
    success       BOOLEAN     NOT NULL,
    gold_earned   INT         NOT NULL DEFAULT 0,
    xp_earned     INT         NOT NULL DEFAULT 0,
    items_earned  JSONB       NOT NULL DEFAULT '[]',
    energy_spent  INT         NOT NULL DEFAULT 0,
    sent_to_hospital BOOLEAN  NOT NULL DEFAULT FALSE,
    hospital_duration_minutes INT,
    created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_dungeon_runs_user_id ON public.dungeon_runs(user_id);
CREATE INDEX IF NOT EXISTS idx_dungeon_runs_created_at ON public.dungeon_runs(created_at DESC);

-- ============================================================
-- 3. SEED DUNGEON DATA (matching Godot/gkk-web mock data)
-- ============================================================
INSERT INTO public.dungeons (dungeon_id, name, description, difficulty, required_level, min_level, max_players, energy_cost, min_gold, max_gold, xp_reward, base_gold_reward, base_xp_reward, success_rate, is_group, loot_table, boss_name)
VALUES
  ('dungeon_tutorial_grotto',    'Başlangıç Mağarası',     'Yeni kahramanlar için basit düşmanlar ve küçük ödüller.',      'easy',   1,  1,  1,  5,  10,   50,   100,  30,   100, 0.900, FALSE, '["iron_ore","herb","leather"]',          NULL),
  ('dungeon_goblin_cave',        'Goblin Mağarası',         'Goblin saldırılarını durdur ve mağarayı temizle.',              'easy',   5,  5,  1, 10, 50,  200,   200,  100,  200, 0.800, FALSE, '["goblin_dagger","herbs","copper_ore"]',  'Goblin Şefi'),
  ('dungeon_haunted_mill',       'Perili Değirmen',         'Perili Değirmen''deki hayaletleri kov.',                        'medium', 8,  8,  1, 15, 100, 500,  300,  250,  300, 0.700, FALSE, '["ghost_essence","silver_ore","scroll_ice"]', 'Değirmenci Hayaleti'),
  ('dungeon_dark_forest',        'Karanlık Orman Zindanı',  'Karanlık Orman''ın derinliklerini keşfet ve boss''u yen.',       'dungeon',10, 10, 1, 25, 500, 2000,  500, 1000,  500, 0.450, FALSE, '["iron_ingot","rare_gem","scroll_fire"]', 'Orman Koruyucusu'),
  ('dungeon_cursed_tomb',        'Lanetli Mezar',           'Lanetli Mezar''ın sırlarını keşfet.',                           'dungeon',15, 15, 1, 30, 1000,5000,  750, 2500,  750, 0.400, FALSE, '["cursed_blade","dark_essence","bone_armor"]', 'Mezar Koruyucusu'),
  ('dungeon_dragon_lair',        'Ejderha Yuvası',          'Ejderha Yuvası''na gir ve hazinesini al.',                      'dungeon',25, 25, 1, 40, 3000,10000, 1000,5000, 1000, 0.350, FALSE, '["dragon_scale","legendary_sword","fire_gem"]', 'Kadim Ejderha'),
  ('dungeon_shadow_citadel',     'Gölge Kalesi',            'En güçlü düşmanların beklediği son zindan.',                    'dungeon',40, 40, 1, 60, 8000,30000, 2000,15000,2000, 0.300, FALSE, '["shadow_crystal","void_blade","arcane_robe"]', 'Gölge Lordu'),
  ('dungeon_group_crystal_cavern','Kristal Mağarası (Grup)','Kristal Mağarası''nda grup halinde hazine avla.',               'dungeon',12, 12, 4, 35, 1500,6000,  750, 3000,  750, 0.600, TRUE,  '["crystal_shard","mithril_ore","enchanted_ring"]', 'Kristal Golem'),
  ('dungeon_group_fortress',     'Kale Kuşatması (Grup)',   'Büyük kaleyi fethederek efsanevi hazineyi ele geçirin.',        'dungeon',20, 20, 4, 50, 5000,20000, 1500,10000,1500, 0.550, TRUE,  '["fortress_key","royal_armor","siege_bow"]', 'Kale Komutanı')
ON CONFLICT (dungeon_id) DO NOTHING;

-- ============================================================
-- 4. RPC: get_dungeons
-- Godot: DungeonManager → get_dungeons()
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_dungeons()
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
            'id',              d.id,
            'dungeon_id',      d.dungeon_id,
            'name',            d.name,
            'description',     d.description,
            'difficulty',      d.difficulty,
            'required_level',  d.required_level,
            'min_level',       d.min_level,
            'max_players',     d.max_players,
            'energy_cost',     d.energy_cost,
            'min_gold',        d.min_gold,
            'max_gold',        d.max_gold,
            'xp_reward',       d.xp_reward,
            'base_gold_reward',d.base_gold_reward,
            'base_xp_reward',  d.base_xp_reward,
            'success_rate',    d.success_rate,
            'is_group',        d.is_group,
            'loot_table',      d.loot_table,
            'boss_name',       d.boss_name,
            'season_modifier', d.season_modifier
        )
        ORDER BY d.required_level, d.is_group
    )
    INTO v_result
    FROM public.dungeons d
    WHERE d.is_active = TRUE;

    RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

-- ============================================================
-- 5. RPC: enter_dungeon
-- Godot: DungeonBattleScreen — server-side battle resolution
-- Matches gkk-web: api.rpc("enter_dungeon", { p_dungeon_id })
-- ============================================================
CREATE OR REPLACE FUNCTION public.enter_dungeon(p_dungeon_id TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id        UUID;
    v_user           RECORD;
    v_dungeon        RECORD;
    v_success_rate   NUMERIC;
    v_rng            NUMERIC;
    v_success        BOOLEAN;
    v_gold_earned    INT;
    v_xp_earned      INT;
    v_items_earned   JSONB := '[]';
    v_hospital       BOOLEAN := FALSE;
    v_hosp_duration  INT := 0;
    v_level_bonus    NUMERIC;
    v_new_gold       BIGINT;
    v_new_xp         BIGINT;
    v_new_level      INT;
    v_xp_threshold   BIGINT;
BEGIN
    -- Auth check
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    -- Load dungeon
    SELECT * INTO v_dungeon FROM public.dungeons WHERE dungeon_id = p_dungeon_id AND is_active = TRUE;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Dungeon not found');
    END IF;

    -- Load player
    SELECT * INTO v_user FROM public.users WHERE auth_id = v_user_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Player not found');
    END IF;

    -- Status checks
    IF v_user.in_hospital = TRUE AND v_user.hospital_until > NOW() THEN
        RETURN jsonb_build_object('success', false, 'error', 'Hastanedeyken zindana giremezsiniz');
    END IF;
    IF v_user.in_prison = TRUE AND v_user.prison_until > NOW() THEN
        RETURN jsonb_build_object('success', false, 'error', 'Cezaevindeyken zindana giremezsiniz');
    END IF;

    -- Level check
    IF v_user.level < v_dungeon.required_level THEN
        RETURN jsonb_build_object('success', false, 'error', format('Seviye %s gerekli', v_dungeon.required_level));
    END IF;

    -- Energy check
    IF v_user.energy < v_dungeon.energy_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Yetersiz enerji');
    END IF;

    -- Deduct energy
    UPDATE public.users SET energy = energy - v_dungeon.energy_cost, updated_at = NOW() WHERE auth_id = v_user_id;

    -- Calculate success rate (mirrors Godot DungeonManager.preview_success_rate)
    v_level_bonus := LEAST((v_user.level - v_dungeon.required_level) * 0.02, 0.15);
    v_success_rate := GREATEST(0.05, LEAST(0.95,
        v_dungeon.success_rate
        + v_level_bonus
        - CASE WHEN v_dungeon.difficulty = 'dungeon' THEN 0.1 ELSE 0.0 END
        + CASE WHEN v_user.level < v_dungeon.required_level THEN (v_dungeon.required_level - v_user.level) * (-0.05) ELSE 0 END
    ));

    -- RNG battle resolution
    v_rng := random();
    v_success := v_rng < v_success_rate;

    IF v_success THEN
        -- Calculate rewards (Godot: gold range + xp)
        v_gold_earned := (v_dungeon.min_gold + floor(random() * (v_dungeon.max_gold - v_dungeon.min_gold + 1)))::INT;
        v_xp_earned   := v_dungeon.xp_reward + floor(random() * v_dungeon.xp_reward * 0.2)::INT;

        -- Loot (pick 0-2 items from loot_table)
        IF jsonb_array_length(v_dungeon.loot_table) > 0 THEN
            DECLARE
                v_loot_count INT := floor(random() * 3)::INT;
                v_idx INT;
                v_item TEXT;
            BEGIN
                FOR i IN 1..LEAST(v_loot_count, jsonb_array_length(v_dungeon.loot_table)) LOOP
                    v_idx := floor(random() * jsonb_array_length(v_dungeon.loot_table))::INT;
                    v_item := v_dungeon.loot_table->v_idx #>> '{}';
                    v_items_earned := v_items_earned || jsonb_build_array(v_item);
                END LOOP;
            END;
        END IF;

        -- Apply gold reward
        SELECT gold INTO v_new_gold FROM public.users WHERE auth_id = v_user_id;
        v_new_gold := COALESCE(v_new_gold, 0) + v_gold_earned;

        -- Apply XP & possible level up
        SELECT xp, level INTO v_new_xp, v_new_level FROM public.users WHERE auth_id = v_user_id;
        v_new_xp   := COALESCE(v_new_xp, 0) + v_xp_earned;
        v_xp_threshold := floor(1000 * pow(v_new_level::NUMERIC, 1.5))::BIGINT;

        WHILE v_new_xp >= v_xp_threshold LOOP
            v_new_xp   := v_new_xp - v_xp_threshold;
            v_new_level := v_new_level + 1;
            v_xp_threshold := floor(1000 * pow(v_new_level::NUMERIC, 1.5))::BIGINT;
        END LOOP;

        UPDATE public.users SET gold = v_new_gold, xp = v_new_xp, level = v_new_level, updated_at = NOW() WHERE auth_id = v_user_id;
    ELSE
        v_gold_earned := 0;
        v_xp_earned   := 0;

        -- Hospital chance on failure: 25% → 2-6 hours (Godot: DungeonBattleScreen)
        IF random() < 0.25 THEN
            v_hospital      := TRUE;
            v_hosp_duration := 2 + floor(random() * 5)::INT;  -- 2 to 6 hours
            UPDATE public.users
            SET in_hospital    = TRUE,
                hospital_until = NOW() + (v_hosp_duration || ' hours')::INTERVAL,
                hospital_reason = format('Zindan başarısızlığı: %s', v_dungeon.name),
                updated_at      = NOW()
            WHERE auth_id = v_user_id;
        END IF;
    END IF;

    -- Log run
    INSERT INTO public.dungeon_runs (user_id, dungeon_id, dungeon_name, success, gold_earned, xp_earned, items_earned, energy_spent, sent_to_hospital, hospital_duration_minutes)
    VALUES (v_user_id, p_dungeon_id, v_dungeon.name, v_success, v_gold_earned, v_xp_earned, v_items_earned, v_dungeon.energy_cost, v_hospital, v_hosp_duration * 60);

    RETURN jsonb_build_object(
        'success',           v_success,
        'gold_earned',       v_gold_earned,
        'xp_earned',         v_xp_earned,
        'items',             v_items_earned,
        'hospital',          v_hospital,
        'hospital_duration', v_hosp_duration,
        'dungeon_name',      v_dungeon.name
    );
END;
$$;

-- ============================================================
-- 6. RPC: get_dungeon_history  (recent runs for player)
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_dungeon_history(p_limit INT DEFAULT 20)
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
            'id',              r.id,
            'dungeon_id',      r.dungeon_id,
            'dungeon_name',    r.dungeon_name,
            'success',         r.success,
            'gold_earned',     r.gold_earned,
            'xp_earned',       r.xp_earned,
            'items_earned',    r.items_earned,
            'sent_to_hospital',r.sent_to_hospital,
            'created_at',      r.created_at
        )
        ORDER BY r.created_at DESC
    )
    INTO v_result
    FROM public.dungeon_runs r
    WHERE r.user_id = v_user_id
    LIMIT p_limit;

    RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

-- ============================================================
-- Notify PostgREST schema reload
-- ============================================================
NOTIFY pgrst, 'reload schema';
