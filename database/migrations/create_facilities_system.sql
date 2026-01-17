-- Facilities System Migration (Knight Online + The Crims Hybrid)
-- v6: FIX - Drop existing function to allow parameter rename (p_amount -> p_amount_gems)

-- 1. Facilities Table
CREATE TABLE IF NOT EXISTS public.facilities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL, 
    level INT NOT NULL DEFAULT 1,
    suspicion INT NOT NULL DEFAULT 0 CHECK (suspicion >= 0 AND suspicion <= 100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, type)
);

-- 2. Recipes Table
CREATE TABLE IF NOT EXISTS public.facility_recipes (
    id TEXT PRIMARY KEY,
    facility_type TEXT NOT NULL,
    output_item_id TEXT NOT NULL, 
    output_quantity INT NOT NULL DEFAULT 1,
    input_materials JSONB DEFAULT '{}'::jsonb, 
    gold_cost INT DEFAULT 0,
    duration_seconds INT NOT NULL,
    required_level INT DEFAULT 1,
    success_rate INT DEFAULT 100, 
    base_suspicion_increase INT DEFAULT 0
);

-- 3. Production Queue
CREATE TABLE IF NOT EXISTS public.facility_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    facility_id UUID NOT NULL REFERENCES public.facilities(id) ON DELETE CASCADE,
    recipe_id TEXT NOT NULL REFERENCES public.facility_recipes(id),
    quantity INT NOT NULL DEFAULT 1,
    started_at BIGINT NOT NULL, 
    completed_at BIGINT NOT NULL, 
    status TEXT DEFAULT 'in_progress',
    is_raided BOOLEAN DEFAULT FALSE,
    is_burned BOOLEAN DEFAULT FALSE
);

-- 4. Initial Data
DELETE FROM public.facility_recipes; 
INSERT INTO public.facility_recipes 
(id, facility_type, output_item_id, output_quantity, input_materials, gold_cost, duration_seconds, required_level, success_rate, base_suspicion_increase)
VALUES
('recipe_gather_iron', 'mine', 'material_iron_ore', 10, '{}'::jsonb, 50, 3600, 1, 100, 5),
('recipe_gather_crystal', 'mine', 'material_crystal', 5, '{}'::jsonb, 200, 7200, 2, 90, 20),
('recipe_grow_wheat', 'farm', 'material_wheat', 20, '{"material_seed_wheat": 5}'::jsonb, 20, 1800, 1, 100, 0), 
('recipe_grow_poison_shroom', 'farm', 'material_poison_shroom', 10, '{}'::jsonb, 150, 3600, 1, 80, 30),
('recipe_chop_oak', 'lumber_mill', 'material_oak_log', 20, '{}'::jsonb, 30, 2700, 1, 100, 2);


-- 5. RPC: Unlock Facility
CREATE OR REPLACE FUNCTION unlock_facility(p_type TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_cost INT;
    v_exists BOOLEAN;
BEGIN
    v_user_id := auth.uid();
    
    SELECT EXISTS(SELECT 1 FROM public.facilities WHERE user_id = v_user_id AND type = p_type) INTO v_exists;
    IF v_exists THEN RETURN jsonb_build_object('success', false, 'error', 'Facility already unlocked'); END IF;
    
    v_cost := CASE 
        WHEN p_type = 'mine' THEN 1000
        WHEN p_type = 'farm' THEN 500
        WHEN p_type = 'lumber_mill' THEN 800
        ELSE 1000
    END;
    
    -- CHECK game.users
    IF (SELECT gold FROM game.users WHERE id = v_user_id) < v_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient gold');
    END IF;
    
    -- UPDATE game.users
    UPDATE game.users SET gold = gold - v_cost WHERE id = v_user_id;
    INSERT INTO public.facilities (user_id, type, level, suspicion) VALUES (v_user_id, p_type, 1, 0);
    
    RETURN jsonb_build_object('success', true);
END;
$$;

-- 6. RPC: Start Production
CREATE OR REPLACE FUNCTION start_facility_production(
    p_facility_id UUID,
    p_recipe_id TEXT,
    p_quantity INT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_facility RECORD;
    v_recipe RECORD;
    v_total_gold INT;
    v_now BIGINT;
    v_duration INT;
    v_suspicion_inc INT;
    v_mat_id TEXT;
    v_mat_req_single INT;
    v_mat_total_needed INT;
    v_user_has INT;
    v_deduct INT;
    v_inv_row RECORD;
BEGIN
    v_user_id := auth.uid();
    v_now := EXTRACT(EPOCH FROM NOW())::BIGINT;
    
    SELECT * INTO v_facility FROM public.facilities WHERE id = p_facility_id AND user_id = v_user_id;
    IF v_facility IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Facility not found'); END IF;
    SELECT * INTO v_recipe FROM public.facility_recipes WHERE id = p_recipe_id;
    IF v_recipe IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Recipe not found'); END IF;
    IF v_facility.level < v_recipe.required_level THEN RETURN jsonb_build_object('success', false, 'error', 'Facility level too low'); END IF;
    
    v_total_gold := v_recipe.gold_cost * p_quantity;
    
    -- CHECK game.users
    IF (SELECT gold FROM game.users WHERE id = v_user_id) < v_total_gold THEN
         RETURN jsonb_build_object('success', false, 'error', 'Insufficient gold');
    END IF;
    
    -- Check Materials
    FOR v_mat_id, v_mat_req_single IN SELECT * FROM jsonb_each_text(v_recipe.input_materials)
    LOOP
        v_mat_total_needed := v_mat_req_single::INT * p_quantity;
        SELECT COALESCE(SUM(quantity), 0) INTO v_user_has FROM public.inventory WHERE user_id = v_user_id AND item_id = v_mat_id;
        IF v_user_has < v_mat_total_needed THEN RAISE EXCEPTION 'Insufficient material: %', v_mat_id; END IF;
    END LOOP;
    
    -- UPDATE game.users
    UPDATE game.users SET gold = gold - v_total_gold WHERE id = v_user_id;
    
    -- Deduct Materials
    FOR v_mat_id, v_mat_req_single IN SELECT * FROM jsonb_each_text(v_recipe.input_materials)
    LOOP
        v_mat_total_needed := v_mat_req_single::INT * p_quantity;
        WHILE v_mat_total_needed > 0 LOOP
            SELECT row_id, quantity INTO v_inv_row FROM public.inventory WHERE user_id = v_user_id AND item_id = v_mat_id ORDER BY quantity ASC LIMIT 1;
            v_deduct := LEAST(v_inv_row.quantity, v_mat_total_needed);
            UPDATE public.inventory SET quantity = quantity - v_deduct WHERE row_id = v_inv_row.row_id;
            DELETE FROM public.inventory WHERE row_id = v_inv_row.row_id AND quantity <= 0;
            v_mat_total_needed := v_mat_total_needed - v_deduct;
        END LOOP;
    END LOOP;

    v_suspicion_inc := v_recipe.base_suspicion_increase * p_quantity;
    UPDATE public.facilities SET suspicion = LEAST(100, suspicion + v_suspicion_inc) WHERE id = p_facility_id;
    
    v_duration := (v_recipe.duration_seconds * p_quantity);
    INSERT INTO public.facility_queue (facility_id, recipe_id, quantity, started_at, completed_at)
    VALUES (p_facility_id, p_recipe_id, p_quantity, v_now, v_now + v_duration);
    
    RETURN jsonb_build_object('success', true);
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;


-- 8. RPC: Bribe (Uses GEMS, game.users)
-- Drop first to allow parameter rename
DROP FUNCTION IF EXISTS bribe_officials(uuid, int);

CREATE OR REPLACE FUNCTION bribe_officials(p_facility_id UUID, p_amount_gems INT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_reduction INT;
BEGIN
    v_user_id := auth.uid();
    
    -- CHECK game.users for GEMS
    IF (SELECT gems FROM game.users WHERE id = v_user_id) < p_amount_gems THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient gems');
    END IF;
    
    v_reduction := p_amount_gems * 10;
    
    -- UPDATE game.users
    UPDATE game.users SET gems = gems - p_amount_gems WHERE id = v_user_id;
    UPDATE public.facilities SET suspicion = GREATEST(0, suspicion - v_reduction) WHERE id = p_facility_id;
    
    RETURN jsonb_build_object('success', true, 'new_suspicion', (SELECT suspicion FROM public.facilities WHERE id = p_facility_id));
END;
$$;
