-- ============================================================
-- PRODUCTION SYSTEM — gkk-web uyumlu
-- Kaynak: scenes/ui/screens/ProductionScreen.gd
-- RPCs: get_active_productions, start_production, speedup_production,
--        cancel_production, get_production_history
-- ============================================================

-- ============================================================
-- 1. PRODUCTION RECIPES TABLE (player-usable production, not facility)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.production_recipes (
    id              TEXT    PRIMARY KEY,
    name            TEXT    NOT NULL,
    description     TEXT,
    output_item_id  TEXT    NOT NULL,
    output_name     TEXT    NOT NULL,
    output_quantity INT     NOT NULL DEFAULT 1,
    input_materials JSONB   NOT NULL DEFAULT '[]', -- [{item_id, item_name, quantity}]
    gold_cost       INT     NOT NULL DEFAULT 0,
    duration_seconds INT    NOT NULL DEFAULT 3600,
    required_level  INT     NOT NULL DEFAULT 1,
    category        TEXT    NOT NULL DEFAULT 'general', -- weapon, armor, potion, material
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 2. PRODUCTION QUEUE TABLE (player productions)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.production_queue (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    recipe_id       TEXT        NOT NULL REFERENCES public.production_recipes(id),
    recipe_name     TEXT        NOT NULL,
    output_item_id  TEXT        NOT NULL,
    output_name     TEXT        NOT NULL,
    output_quantity INT         NOT NULL DEFAULT 1,
    status          TEXT        NOT NULL DEFAULT 'in_progress', -- in_progress, completed, claimed, cancelled
    started_at      TIMESTAMPTZ DEFAULT NOW(),
    completes_at    TIMESTAMPTZ NOT NULL,
    speedup_gems_used INT       NOT NULL DEFAULT 0,
    cancelled_at    TIMESTAMPTZ,
    claimed_at      TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_production_queue_user_id ON public.production_queue(user_id);
CREATE INDEX IF NOT EXISTS idx_production_queue_status ON public.production_queue(status);

-- ============================================================
-- 3. SEED PRODUCTION RECIPES (Godot ProductionScreen content)
-- ============================================================
INSERT INTO public.production_recipes (id, name, description, output_item_id, output_name, output_quantity, input_materials, gold_cost, duration_seconds, required_level, category)
VALUES
  ('prod_iron_ingot',    'Demir Külçe Dökümü',    'Demir cevherini eritip külçe yap.',
   'iron_ingot',    'Demir Külçe',    5,
   '[{"item_id":"iron_ore","item_name":"Demir Cevheri","quantity":10}]',
   50, 1800, 1, 'material'),

  ('prod_leather_strip', 'Deri İşleme',            'Ham deriyi kullanışlı deri şeridine dönüştür.',
   'leather_strip', 'Deri Şerit',     8,
   '[{"item_id":"leather","item_name":"Deri","quantity":5}]',
   30, 900, 1, 'material'),

  ('prod_health_potion', 'Sağlık İksiri Üretimi',  'Temel sağlık iksiri yap.',
   'health_potion', 'Sağlık İksiri',  3,
   '[{"item_id":"herb","item_name":"Ot","quantity":5},{"item_id":"water_vial","item_name":"Su Şişesi","quantity":1}]',
   100, 1200, 1, 'potion'),

  ('prod_steel_ingot',   'Çelik Eritme',           'Demir ve kömürden çelik yap.',
   'steel_ingot',   'Çelik Külçe',    3,
   '[{"item_id":"iron_ingot","item_name":"Demir Külçe","quantity":5},{"item_id":"coal","item_name":"Kömür","quantity":3}]',
   200, 3600, 5, 'material'),

  ('prod_enchant_scroll','Büyü Tomarı Yazımı',     'Arkanik malzemelerden büyü tomarı üret.',
   'scroll_generic','Büyü Tomarı',    1,
   '[{"item_id":"arcane_paper","item_name":"Arkanik Kağıt","quantity":3},{"item_id":"ink","item_name":"Mürekkep","quantity":2}]',
   500, 7200, 10, 'scroll'),

  ('prod_mithril_ingot', 'Mithril Arıtımı',        'Nadir mithril cevherini arıt.',
   'mithril_ingot', 'Mithril Külçe',  2,
   '[{"item_id":"mithril_ore","item_name":"Mithril Cevheri","quantity":8}]',
   1000, 14400, 20, 'material'),

  ('prod_elixir',        'Güç Eliksiri',            'Güçlü eliksir karıştır.',
   'elixir_power',  'Güç Eliksiri',   1,
   '[{"item_id":"rare_herb","item_name":"Nadir Ot","quantity":3},{"item_id":"shadow_essence","item_name":"Gölge Esansı","quantity":1}]',
   800, 10800, 15, 'potion')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 4. RPC: get_active_productions
-- Godot: ProductionScreen — http_get("/v1/production/active")
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_active_productions()
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

    -- Auto-complete finished productions
    UPDATE public.production_queue
    SET status = 'completed'
    WHERE user_id = v_user_id AND status = 'in_progress' AND completes_at <= NOW();

    SELECT jsonb_agg(
        jsonb_build_object(
            'id',              pq.id,
            'recipe_id',       pq.recipe_id,
            'recipe_name',     pq.recipe_name,
            'output_item_id',  pq.output_item_id,
            'output_name',     pq.output_name,
            'output_quantity', pq.output_quantity,
            'status',          pq.status,
            'started_at',      pq.started_at,
            'completes_at',    pq.completes_at,
            'seconds_left',    GREATEST(0, EXTRACT(EPOCH FROM (pq.completes_at - NOW()))::INT),
            'progress_pct',    CASE
                WHEN pq.status = 'completed' THEN 100
                ELSE LEAST(100, ROUND(
                    100.0 * EXTRACT(EPOCH FROM (NOW() - pq.started_at)) /
                    NULLIF(EXTRACT(EPOCH FROM (pq.completes_at - pq.started_at)), 0)
                ))
            END
        )
        ORDER BY pq.started_at ASC
    )
    INTO v_result
    FROM public.production_queue pq
    WHERE pq.user_id = v_user_id
      AND pq.status IN ('in_progress', 'completed');

    RETURN jsonb_build_object(
        'productions', COALESCE(v_result, '[]'::jsonb),
        'recipes',     (SELECT jsonb_agg(jsonb_build_object(
                'id',               pr.id,
                'name',             pr.name,
                'description',      pr.description,
                'output_item_id',   pr.output_item_id,
                'output_name',      pr.output_name,
                'output_quantity',  pr.output_quantity,
                'input_materials',  pr.input_materials,
                'gold_cost',        pr.gold_cost,
                'duration_seconds', pr.duration_seconds,
                'required_level',   pr.required_level,
                'category',         pr.category
            )) FROM public.production_recipes pr WHERE pr.is_active = TRUE ORDER BY pr.required_level)
    );
END;
$$;

-- ============================================================
-- 5. RPC: start_production
-- Godot: ProductionScreen — http_post("/v1/production/start")
-- ============================================================
CREATE OR REPLACE FUNCTION public.start_production(p_recipe_id TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id      UUID;
    v_user         RECORD;
    v_recipe       RECORD;
    v_queue_count  INT;
    v_completes_at TIMESTAMPTZ;
    v_new_id       UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT * INTO v_recipe FROM public.production_recipes WHERE id = p_recipe_id AND is_active = TRUE;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Tarif bulunamadı');
    END IF;

    SELECT * INTO v_user FROM public.users WHERE auth_id = v_user_id;

    IF v_user.level < v_recipe.required_level THEN
        RETURN jsonb_build_object('success', false, 'error', format('Seviye %s gerekli', v_recipe.required_level));
    END IF;

    IF v_user.gold < v_recipe.gold_cost THEN
        RETURN jsonb_build_object('success', false, 'error', format('Yetersiz altın. Gerekli: %s', v_recipe.gold_cost));
    END IF;

    -- Queue limit check (max 3 simultaneous productions)
    SELECT COUNT(*) INTO v_queue_count
    FROM public.production_queue
    WHERE user_id = v_user_id AND status = 'in_progress';

    IF v_queue_count >= 3 THEN
        RETURN jsonb_build_object('success', false, 'error', 'Üretim kuyruğu dolu (maks 3)');
    END IF;

    -- Deduct gold
    IF v_recipe.gold_cost > 0 THEN
        UPDATE public.users SET gold = gold - v_recipe.gold_cost, updated_at = NOW() WHERE auth_id = v_user_id;
    END IF;

    v_completes_at := NOW() + (v_recipe.duration_seconds || ' seconds')::INTERVAL;

    INSERT INTO public.production_queue (user_id, recipe_id, recipe_name, output_item_id, output_name, output_quantity, status, completes_at)
    VALUES (v_user_id, p_recipe_id, v_recipe.name, v_recipe.output_item_id, v_recipe.output_name, v_recipe.output_quantity, 'in_progress', v_completes_at)
    RETURNING id INTO v_new_id;

    RETURN jsonb_build_object(
        'success',       TRUE,
        'production_id', v_new_id,
        'recipe_name',   v_recipe.name,
        'completes_at',  v_completes_at,
        'gold_cost',     v_recipe.gold_cost
    );
END;
$$;

-- ============================================================
-- 6. RPC: speedup_production
-- Godot: ProductionScreen — http_post("/v1/production/speedup")
-- ============================================================
CREATE OR REPLACE FUNCTION public.speedup_production(
    p_production_id UUID,
    p_gems          INT DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id    UUID;
    v_user       RECORD;
    v_prod       RECORD;
    v_seconds_left INT;
    v_gem_cost   INT;
    v_skip_seconds INT;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT * INTO v_prod FROM public.production_queue WHERE id = p_production_id AND user_id = v_user_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Üretim bulunamadı');
    END IF;

    IF v_prod.status <> 'in_progress' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Üretim zaten tamamlandı veya iptal edildi');
    END IF;

    -- Calculate cost: 1 gem per 5 minutes
    v_seconds_left := GREATEST(0, EXTRACT(EPOCH FROM (v_prod.completes_at - NOW()))::INT);
    v_gem_cost := CEIL(v_seconds_left::NUMERIC / 300)::INT;

    -- Skip by gems: each gem = 5 minutes
    IF p_gems <= 0 THEN
        -- Full speedup
        p_gems := v_gem_cost;
    END IF;

    SELECT gems INTO v_user FROM public.users WHERE auth_id = v_user_id;
    IF v_user.gems < p_gems THEN
        RETURN jsonb_build_object('success', false, 'error', format('Yetersiz elmas. Gerekli: %s', p_gems));
    END IF;

    v_skip_seconds := p_gems * 300; -- each gem = 5 minutes

    UPDATE public.users SET gems = gems - p_gems, updated_at = NOW() WHERE auth_id = v_user_id;

    -- Advance completion time
    UPDATE public.production_queue
    SET completes_at     = LEAST(NOW(), completes_at - (v_skip_seconds || ' seconds')::INTERVAL),
        speedup_gems_used = speedup_gems_used + p_gems,
        status           = CASE WHEN completes_at - (v_skip_seconds || ' seconds')::INTERVAL <= NOW()
                                THEN 'completed' ELSE 'in_progress' END
    WHERE id = p_production_id;

    RETURN jsonb_build_object(
        'success',    TRUE,
        'gems_used',  p_gems,
        'skipped_seconds', v_skip_seconds,
        'is_complete', (v_seconds_left <= v_skip_seconds)
    );
END;
$$;

-- ============================================================
-- 7. RPC: cancel_production
-- Godot: ProductionScreen — http_post("/v1/production/cancel")
-- ============================================================
CREATE OR REPLACE FUNCTION public.cancel_production(p_production_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id UUID;
    v_prod    RECORD;
    v_recipe  RECORD;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT * INTO v_prod FROM public.production_queue WHERE id = p_production_id AND user_id = v_user_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Üretim bulunamadı');
    END IF;

    IF v_prod.status NOT IN ('in_progress') THEN
        RETURN jsonb_build_object('success', false, 'error', 'Bu üretim iptal edilemez');
    END IF;

    -- Partial gold refund (50%)
    SELECT * INTO v_recipe FROM public.production_recipes WHERE id = v_prod.recipe_id;
    IF v_recipe.gold_cost > 0 THEN
        UPDATE public.users SET gold = gold + floor(v_recipe.gold_cost * 0.5)::INT, updated_at = NOW() WHERE auth_id = v_user_id;
    END IF;

    UPDATE public.production_queue SET status = 'cancelled', cancelled_at = NOW() WHERE id = p_production_id;

    RETURN jsonb_build_object(
        'success',       TRUE,
        'refunded_gold', floor(v_recipe.gold_cost * 0.5)::INT
    );
END;
$$;

-- ============================================================
-- 8. RPC: claim_production
-- Godot: ProductionScreen — collect completed production
-- ============================================================
CREATE OR REPLACE FUNCTION public.claim_production(p_production_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id UUID;
    v_prod    RECORD;
    v_slot    INT;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT * INTO v_prod FROM public.production_queue WHERE id = p_production_id AND user_id = v_user_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Üretim bulunamadı');
    END IF;

    IF v_prod.status = 'claimed' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Zaten alındı');
    END IF;

    IF v_prod.status = 'in_progress' AND v_prod.completes_at > NOW() THEN
        RETURN jsonb_build_object(
            'success',    FALSE,
            'error',      'Üretim henüz tamamlanmadı',
            'seconds_left', EXTRACT(EPOCH FROM (v_prod.completes_at - NOW()))::INT
        );
    END IF;

    -- Add item to inventory
    SELECT s.i INTO v_slot
    FROM generate_series(0, 19) AS s(i)
    WHERE NOT EXISTS (
        SELECT 1 FROM public.inventory WHERE user_id = v_user_id AND slot_position = s.i AND is_equipped = FALSE
    )
    LIMIT 1;

    IF v_slot IS NOT NULL THEN
        INSERT INTO public.inventory (user_id, item_id, quantity, is_equipped, slot_position, updated_at)
        VALUES (v_user_id, v_prod.output_item_id, v_prod.output_quantity, FALSE, v_slot, NOW())
        ON CONFLICT DO NOTHING;
    END IF;

    UPDATE public.production_queue SET status = 'claimed', claimed_at = NOW() WHERE id = p_production_id;

    RETURN jsonb_build_object(
        'success',  TRUE,
        'item_id',  v_prod.output_item_id,
        'item_name',v_prod.output_name,
        'quantity', v_prod.output_quantity
    );
END;
$$;

-- ============================================================
-- 9. RPC: get_production_history
-- Godot: ProductionScreen — http_get("/v1/production/history")
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_production_history(p_limit INT DEFAULT 20)
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
            'id',              pq.id,
            'recipe_name',     pq.recipe_name,
            'output_name',     pq.output_name,
            'output_quantity', pq.output_quantity,
            'status',          pq.status,
            'started_at',      pq.started_at,
            'completed_at',    pq.completes_at,
            'claimed_at',      pq.claimed_at
        )
        ORDER BY pq.started_at DESC
    )
    INTO v_result
    FROM public.production_queue pq
    WHERE pq.user_id = v_user_id
      AND pq.status IN ('completed', 'claimed', 'cancelled')
    LIMIT p_limit;

    RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

NOTIFY pgrst, 'reload schema';
