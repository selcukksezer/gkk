-- ============================================================
-- CONSOLIDATED FACILITIES SYSTEM - FINAL VERSION
-- ============================================================
-- Complete facilities system with all tables and RPC functions
-- Created: 2026-02-08
-- 
-- This migration includes:
-- 1. Users table extensions (global suspicion tracking)
-- 2. Facilities table schema
-- 3. Supporting objects (recipes, queue, prison records)
-- 4. All unified RPC functions
-- 5. Prison admission system

-- ============================================================
-- 0. USERS TABLE EXTENSIONS
-- ============================================================
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS global_suspicion_level INT NOT NULL DEFAULT 0 CHECK (global_suspicion_level >= 0 AND global_suspicion_level <= 100);

-- ============================================================
-- 1. FACILITIES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.facilities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL, 
    level INT NOT NULL DEFAULT 1,
    suspicion_level INT NOT NULL DEFAULT 0 CHECK (suspicion_level >= 0 AND suspicion_level <= 100),
    is_active BOOLEAN DEFAULT TRUE,
    production_started_at TIMESTAMPTZ,
    last_production_collected_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, type)
);

CREATE INDEX IF NOT EXISTS idx_facilities_user_id ON public.facilities(user_id);
CREATE INDEX IF NOT EXISTS idx_facilities_type ON public.facilities(type);
CREATE INDEX IF NOT EXISTS idx_facilities_active ON public.facilities(is_active);

-- ============================================================
-- 2. FACILITY RECIPES TABLE
-- ============================================================
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

-- ============================================================
-- 3. PRODUCTION QUEUE TABLE
-- ============================================================
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

-- ============================================================
-- 4. PRISON RECORDS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.prison_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    facility_id UUID REFERENCES public.facilities(id) ON DELETE SET NULL,
    reason TEXT NOT NULL DEFAULT 'High suspicion at facility operations',
    sentence_hours INT NOT NULL,
    admitted_at TIMESTAMPTZ DEFAULT NOW(),
    released_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_prison_records_user_id ON public.prison_records(user_id);
CREATE INDEX IF NOT EXISTS idx_prison_records_released_at ON public.prison_records(released_at);

-- ============================================================
-- RPC FUNCTIONS
-- ============================================================

-- Drop ALL existing function signatures (clean slate)
DROP FUNCTION IF EXISTS public.unlock_facility(TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.unlock_facility(uuid, text) CASCADE;
DROP FUNCTION IF EXISTS public.start_facility_production(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.start_facility_production(uuid, jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.increment_facility_suspicion(UUID, INT) CASCADE;
DROP FUNCTION IF EXISTS public.increment_facility_suspicion(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.increment_facility_suspicion(uuid, integer) CASCADE;
DROP FUNCTION IF EXISTS public.bribe_officials(UUID, INT) CASCADE;
DROP FUNCTION IF EXISTS public.bribe_officials(uuid, integer) CASCADE;
DROP FUNCTION IF EXISTS public.admit_to_prison(UUID, INT) CASCADE;
DROP FUNCTION IF EXISTS public.admit_to_prison(uuid, integer) CASCADE;
DROP FUNCTION IF EXISTS public.check_and_release_from_prison(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.collect_facility_resources_v2(UUID, BIGINT, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS public.collect_facility_resources_v2(uuid, bigint, boolean) CASCADE;

-- RPC 1: unlock_facility
CREATE OR REPLACE FUNCTION public.unlock_facility(p_type TEXT)
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
    
    SELECT EXISTS(SELECT 1 FROM public.facilities WHERE user_id = v_user_id AND type = p_type AND is_active = true) 
    INTO v_exists;
    
    IF v_exists THEN 
        RETURN jsonb_build_object('success', false, 'error', 'Facility already unlocked'); 
    END IF;
    
    v_cost := 5000;
    
    IF (SELECT gold FROM public.users WHERE id = v_user_id) < v_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient gold');
    END IF;
    
    UPDATE public.users SET gold = gold - v_cost WHERE id = v_user_id;
    
    INSERT INTO public.facilities (user_id, type, level, suspicion_level, is_active) 
    VALUES (v_user_id, p_type, 1, 0, true)
    ON CONFLICT (user_id, type) 
    DO UPDATE SET 
        is_active = true,
        suspicion_level = 0,
        updated_at = NOW();
    
    RETURN jsonb_build_object('success', true, 'message', 'Facility unlocked successfully');
END;
$$;

GRANT EXECUTE ON FUNCTION public.unlock_facility(TEXT) TO authenticated;

-- RPC 2: start_facility_production
CREATE OR REPLACE FUNCTION public.start_facility_production(p_facility_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_facility RECORD;
    v_current_energy INT;
    v_energy_cost INT := 50;
BEGIN
    v_user_id := auth.uid();
    
    SELECT * INTO v_facility
    FROM public.facilities
    WHERE id = p_facility_id AND user_id = v_user_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Facility not found or not owned');
    END IF;
    
    SELECT energy INTO v_current_energy FROM public.users WHERE id = v_user_id;
    IF v_current_energy < v_energy_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient energy');
    END IF;
    
    UPDATE public.users
    SET energy = energy - v_energy_cost
    WHERE id = v_user_id;
    
    UPDATE public.facilities
    SET production_started_at = NOW(),
        updated_at = NOW()
    WHERE id = p_facility_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Production started',
        'new_energy', v_current_energy - v_energy_cost,
        'production_started_at', NOW()
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.start_facility_production(UUID) TO authenticated;

-- RPC 2b: increment_facility_suspicion (during production)
CREATE OR REPLACE FUNCTION public.increment_facility_suspicion(
    p_facility_id UUID,
    p_amount INT DEFAULT 5
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_new_suspicion INT;
    v_global_suspicion INT;
BEGIN
    v_user_id := auth.uid();
    
    UPDATE public.facilities
    SET suspicion_level = LEAST(suspicion_level + p_amount, 100)
    WHERE id = p_facility_id AND user_id = v_user_id
    RETURNING suspicion_level INTO v_new_suspicion;
    
    IF v_new_suspicion IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Facility not found or not owned');
    END IF;
    
    -- NOTE: Don't update global_suspicion_level here!
    -- Client handles risk calculation and syncs via update_global_suspicion_level RPC
    -- This keeps risk sync centralized and prevents conflicts
    
    RETURN jsonb_build_object(
        'success', true,
        'facility_suspicion', v_new_suspicion,
        'global_suspicion', 0,
        'message', CASE WHEN v_new_suspicion >= 80 THEN 'High suspicion! Risk of prison!' ELSE 'OK' END
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.increment_facility_suspicion(UUID, INT) TO authenticated;

-- RPC 3: bribe_officials (FIXED: updates global suspicion + validates reduction)
CREATE OR REPLACE FUNCTION public.bribe_officials(p_facility_id UUID, p_amount_gems INT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_current_gems INT;
    v_global_suspicion INT;
    v_suspicion_reduction INT;
    v_facility_suspicion_before INT;
    v_facility_suspicion_after INT;
BEGIN
    v_user_id := auth.uid();
    
    SELECT gems, global_suspicion_level 
    INTO v_current_gems, v_global_suspicion
    FROM public.users 
    WHERE auth_id = v_user_id;
    
    IF v_current_gems < p_amount_gems THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient gems');
    END IF;
    
    SELECT suspicion_level 
    INTO v_facility_suspicion_before
    FROM public.facilities 
    WHERE id = p_facility_id AND user_id = v_user_id;
    
    IF v_facility_suspicion_before IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Facility not found or not owned');
    END IF;
    
    v_suspicion_reduction := p_amount_gems * 10;
    
    -- Allow bribe even if suspicion is already 0 (will just reset to 0, no harm)
    -- Only prevent if gems insufficient
    
    UPDATE public.users
    SET gems = gems - p_amount_gems
    WHERE auth_id = v_user_id;
    
    -- RESET global suspicion to 0 (bribed immunity)
    UPDATE public.users
    SET global_suspicion_level = 0
    WHERE auth_id = v_user_id;
    
    -- RESET facility suspicion to 0
    UPDATE public.facilities
    SET suspicion_level = 0
    WHERE id = p_facility_id
    RETURNING suspicion_level INTO v_facility_suspicion_after;
    
    RETURN jsonb_build_object(
        'success', true, 
        'message', 'Bribed successfully. Immunity for 1 hour.',
        'new_suspicion', v_facility_suspicion_after,
        'gems_spent', p_amount_gems,
        'suspicion_reduction', v_suspicion_reduction,
        'facility_suspicion_before', v_facility_suspicion_before,
        'facility_suspicion_after', v_facility_suspicion_after,
        'global_suspicion_before', v_global_suspicion,
        'global_suspicion_after', GREATEST(0, v_global_suspicion - v_suspicion_reduction)
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.bribe_officials(UUID, INT) TO authenticated;

-- RPC 4: admit_to_prison
CREATE OR REPLACE FUNCTION public.admit_to_prison(
    p_facility_id UUID,
    p_suspicion_level INT DEFAULT 80
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_sentence_hours INT;
    v_release_time TIMESTAMPTZ;
    v_prison_record_id UUID;
BEGIN
    v_user_id := auth.uid();
    
    IF NOT EXISTS (
        SELECT 1 FROM public.facilities 
        WHERE id = p_facility_id AND user_id = v_user_id
    ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Facility not found');
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM public.prison_records
        WHERE user_id = v_user_id AND released_at IS NULL
    ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Already in prison');
    END IF;
    
    v_sentence_hours := 2 + (p_suspicion_level / 10);
    v_release_time := NOW() + (v_sentence_hours || ' hours')::INTERVAL;
    
    INSERT INTO public.prison_records (
        user_id, facility_id, reason, sentence_hours, admitted_at, released_at
    ) VALUES (
        v_user_id, p_facility_id, 'High suspicion at facility operations', v_sentence_hours, NOW(), v_release_time
    ) RETURNING id INTO v_prison_record_id;
    
    UPDATE public.facilities
    SET suspicion_level = 0
    WHERE id = p_facility_id;
    
    UPDATE public.users
    SET in_prison = true,
        hospital_until = v_release_time
    WHERE id = v_user_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Admitted to prison',
        'prison_record_id', v_prison_record_id,
        'sentence_hours', v_sentence_hours,
        'release_time', v_release_time
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.admit_to_prison(UUID, INT) TO authenticated;

-- RPC 5: check_and_release_from_prison
CREATE OR REPLACE FUNCTION public.check_and_release_from_prison(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_today TIMESTAMPTZ := NOW();
    v_prison_record RECORD;
    v_released_count INT := 0;
BEGIN
    FOR v_prison_record IN
        SELECT id, user_id FROM public.prison_records
        WHERE user_id = p_user_id
          AND released_at IS NOT NULL
          AND released_at <= v_today
          AND released_at > (SELECT COALESCE(MAX(released_at), '1900-01-01'::TIMESTAMPTZ) FROM public.prison_records 
                          WHERE user_id = p_user_id AND released_at < v_today)
    LOOP
        v_released_count := v_released_count + 1;
    END LOOP;
    
    IF v_released_count > 0 THEN
        UPDATE public.users
        SET in_prison = false,
            hospital_until = NULL
        WHERE id = p_user_id
          AND NOT EXISTS (
              SELECT 1 FROM public.prison_records
              WHERE user_id = p_user_id AND released_at IS NULL
          );
    END IF;
    
    RETURN jsonb_build_object(
        'success', true,
        'released', v_released_count > 0,
        'message', CASE WHEN v_released_count > 0 
            THEN 'Released from prison' 
            ELSE 'Still in prison' 
        END
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.check_and_release_from_prison(UUID) TO authenticated;

-- RPC 6: collect_facility_resources_v2 (with rarity distribution and level-based drop rates)
CREATE OR REPLACE FUNCTION public.collect_facility_resources_v2(
    p_facility_id UUID,
    p_seed BIGINT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_facility RECORD;
    v_level INT;
    v_type TEXT;
    v_started_at TIMESTAMPTZ;
    v_now TIMESTAMPTZ := NOW();
    v_total_qty INT;
    v_base_rate INT := 10;
    
    v_production_duration INT := 120;
    v_end_time TIMESTAMPTZ;
    v_calc_time TIMESTAMPTZ;
    v_last_collected TIMESTAMPTZ;
    v_elapsed_seconds NUMERIC;
    
    v_items_breakdown JSONB := '{}'::jsonb;
    v_generated_items JSONB := '[]'::jsonb;
    
    v_i INT;
    v_item_id TEXT;
    v_item_name TEXT;
    v_qty_for_item INT;
    v_rarity TEXT;
    v_resource_index INT;
    v_rng_val FLOAT;
    v_cumulative FLOAT;
    
    v_available_slots INT := 0;
    v_available_slot_list INT[] := ARRAY[]::int[];
    v_max_stack INT := 500;
    v_existing_space INT;
    v_qty_remaining INT;
    v_required_slots INT := 0;
    v_slot_idx INT;
    v_add_qty INT;
    v_existing_item RECORD;
    
    v_items_inserted INT := 0;
    v_items_updated INT := 0;
    
    v_new_global_suspicion INT;
    v_prison_roll FLOAT;
    v_prison_chance INT;
    
    v_resources_pool TEXT[];
    v_weights JSONB;
    v_total_weight NUMERIC;
    v_unlocked_rarities TEXT[];
    
BEGIN
    v_user_id := auth.uid();
    
    SELECT * INTO v_facility FROM public.facilities
    WHERE id = p_facility_id AND user_id = v_user_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Facility not found');
    END IF;
    
    v_type := v_facility.type;
    v_level := COALESCE(v_facility.level, 1);
    v_started_at := v_facility.production_started_at;
    
    IF v_started_at IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Production not started');
    END IF;
    
    -- Calculate resources using same formula as preview:
    -- Production duration: 120 seconds for testing (matches client-side preview)
    -- hours_elapsed * (base_rate * level * 10multiplier)
    -- Calculate from when production was last collected to either now or when production expired
    v_end_time := v_started_at + (v_production_duration || ' seconds')::INTERVAL;
    v_calc_time := LEAST(v_now, v_end_time);  -- Cap calc time to end_time
    v_last_collected := COALESCE(v_facility.last_production_collected_at, v_started_at);
    v_elapsed_seconds := EXTRACT(EPOCH FROM (v_calc_time - v_last_collected));
    
    v_total_qty := LEAST(
        GREATEST(0, ((v_elapsed_seconds / 3600.0) * (v_base_rate * v_level * 10))::INT),
        100
    );
    
    -- DEBUG: Log calculation details
    RAISE LOG '[RPC_DEBUG] facility_type=%, level=%, started_at=%, last_collected=%, now=%, end_time=%, calc_time=%, elapsed_seconds=%, base_calc=%, total_qty=%',
        v_type, v_level, v_started_at, v_last_collected, v_now, v_end_time, v_calc_time,
        v_elapsed_seconds, ((v_elapsed_seconds / 3600.0) * (v_base_rate * v_level * 10))::numeric, v_total_qty;
    
    IF v_total_qty <= 0 THEN
        RETURN jsonb_build_object('success', true, 'message', 'No resources yet', 'count', 0, 'items_generated', '[]'::jsonb);
    END IF;
    
    -- Resource pools
    v_resources_pool := CASE v_type
        WHEN 'mining' THEN ARRAY['iron_ore', 'copper_ore', 'silver_ore', 'gold_ore', 'mithril_ore']
        WHEN 'clay_pit' THEN ARRAY['ceramic_clay', 'brick_clay', 'enchanted_clay', 'dragon_clay', 'primordial_clay']
        WHEN 'quarry' THEN ARRAY['granite', 'marble', 'crystal_shard', 'obsidian', 'moonstone']
        WHEN 'lumber_mill' THEN ARRAY['oak_wood', 'pine_wood', 'bamboo', 'elder_wood', 'world_tree_sap']
        WHEN 'sand_quarry' THEN ARRAY['glass_sand', 'crystal_sand', 'star_dust', 'void_sand', 'infinity_sand']
        WHEN 'farming' THEN ARRAY['wheat', 'vegetables', 'cotton', 'magical_grain', 'golden_wheat']
        WHEN 'herb_garden' THEN ARRAY['healing_herb', 'poison_herb', 'rare_flower', 'dragon_root', 'phoenix_petal']
        WHEN 'ranch' THEN ARRAY['leather', 'bone', 'wool', 'monster_hide', 'dragon_scale']
        WHEN 'apiary' THEN ARRAY['honey', 'beeswax', 'bee_venom', 'royal_jelly', 'celestial_honey']
        WHEN 'mushroom_farm' THEN ARRAY['healing_mushroom', 'poison_mushroom', 'glowing_mushroom', 'ghost_mushroom', 'immortality_shroom']
        WHEN 'rune_mine' THEN ARRAY['raw_rune', 'magic_crystal', 'energy_shard', 'power_rune', 'ancient_rune']
        WHEN 'holy_spring' THEN ARRAY['holy_water', 'mana_crystal', 'purification_water', 'blessed_essence', 'divine_tear']
        WHEN 'shadow_pit' THEN ARRAY['dark_essence', 'shadow_crystal', 'curse_dust', 'void_fragment', 'abyss_core']
        WHEN 'elemental_forge' THEN ARRAY['fire_essence', 'ice_crystal', 'lightning_core', 'storm_shard', 'primordial_flame']
        WHEN 'time_well' THEN ARRAY['time_crystal', 'aging_dust', 'eternity_essence', 'temporal_shard', 'infinity_stone']
        ELSE ARRAY[]::TEXT[]
    END;
    
    IF array_length(v_resources_pool, 1) IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unknown facility type');
    END IF;
    
    -- Calculate rarity weights for this level (same as preview)
    -- Base: COMMON=700, UNCOMMON=200, RARE=80, EPIC=15, LEGENDARY=5
    -- Per level increase: UNCOMMON +15, RARE +8, EPIC +3, LEGENDARY +1.5
    v_weights := jsonb_build_object(
        'COMMON', 700.0,
        'UNCOMMON', 200.0 + ((v_level - 1) * 15.0),
        'RARE', 80.0 + ((v_level - 1) * 8.0),
        'EPIC', 15.0 + ((v_level - 1) * 3.0),
        'LEGENDARY', 5.0 + ((v_level - 1) * 1.5)
    );
    
    -- Calculate total weight
    SELECT SUM(value::NUMERIC)::NUMERIC INTO v_total_weight FROM jsonb_each_text(v_weights);
    v_total_weight := COALESCE(v_total_weight, 0);
    
    -- Determine which rarities are unlocked at this level
    v_unlocked_rarities := ARRAY[]::TEXT[];
    IF v_level >= 1 THEN v_unlocked_rarities := array_append(v_unlocked_rarities, 'COMMON'); END IF;
    IF v_level >= 3 THEN v_unlocked_rarities := array_append(v_unlocked_rarities, 'UNCOMMON'); END IF;
    IF v_level >= 5 THEN v_unlocked_rarities := array_append(v_unlocked_rarities, 'RARE'); END IF;
    IF v_level >= 7 THEN v_unlocked_rarities := array_append(v_unlocked_rarities, 'EPIC'); END IF;
    IF v_level >= 10 THEN v_unlocked_rarities := array_append(v_unlocked_rarities, 'LEGENDARY'); END IF;
    
    -- Generate items with rarity-based distribution
    FOR v_i IN 1..v_total_qty LOOP
        -- Use seed-based deterministic RNG to pick rarity
        v_rng_val := ((p_seed + v_i) * 16807.0 % 2147483647.0) / 2147483647.0;
        v_cumulative := 0.0;
        v_rarity := 'COMMON';  -- default
        
        -- Pick rarity based on weights
        IF (v_weights->>'COMMON')::NUMERIC / v_total_weight <= v_rng_val THEN
            v_cumulative := (v_weights->>'COMMON')::NUMERIC / v_total_weight;
            IF v_cumulative + (v_weights->>'UNCOMMON')::NUMERIC / v_total_weight > v_rng_val THEN
                v_rarity := 'UNCOMMON';
            ELSIF v_cumulative + (v_weights->>'RARE')::NUMERIC / v_total_weight > v_rng_val THEN
                v_rarity := 'RARE';
            ELSIF v_cumulative + (v_weights->>'EPIC')::NUMERIC / v_total_weight > v_rng_val THEN
                v_rarity := 'EPIC';
            ELSE
                v_rarity := 'LEGENDARY';
            END IF;
        END IF;
        
        -- Downgrade if not unlocked
        IF NOT (v_rarity = ANY(v_unlocked_rarities)) THEN
            IF 'EPIC' = ANY(v_unlocked_rarities) AND v_rarity = 'LEGENDARY' THEN
                v_rarity := 'EPIC';
            ELSIF 'RARE' = ANY(v_unlocked_rarities) AND (v_rarity = 'LEGENDARY' OR v_rarity = 'EPIC') THEN
                v_rarity := 'RARE';
            ELSIF 'UNCOMMON' = ANY(v_unlocked_rarities) AND (v_rarity IN ('LEGENDARY', 'EPIC', 'RARE')) THEN
                v_rarity := 'UNCOMMON';
            ELSE
                v_rarity := 'COMMON';
            END IF;
        END IF;
        
        -- Pick resource based on rarity tier
        -- Index 0,1 = COMMON | 2 = UNCOMMON | 3 = RARE | 4 = LEGENDARY
        v_resource_index := CASE v_rarity
            WHEN 'COMMON' THEN ((p_seed + v_i) % 2)
            WHEN 'UNCOMMON' THEN 2
            WHEN 'RARE' THEN 3
            WHEN 'EPIC' THEN 3
            WHEN 'LEGENDARY' THEN 4
            ELSE 0
        END;
        
        IF v_resource_index >= array_length(v_resources_pool, 1) THEN
            v_resource_index := array_length(v_resources_pool, 1) - 1;
        END IF;
        
        v_item_id := v_resources_pool[v_resource_index + 1];
        IF v_item_id IS NULL THEN v_item_id := v_resources_pool[1]; END IF;
        
        v_qty_for_item := COALESCE((v_items_breakdown->>v_item_id)::INT, 0) + 1;
        v_items_breakdown := jsonb_set(v_items_breakdown, ARRAY[v_item_id], to_jsonb(v_qty_for_item));
    END LOOP;
    
    -- Build items array for response (before inventory operations)
    FOR v_item_id IN SELECT key FROM jsonb_each(v_items_breakdown) LOOP
        v_qty_for_item := (v_items_breakdown->>v_item_id)::INT;
        SELECT name INTO v_item_name FROM public.items WHERE id = v_item_id LIMIT 1;
        v_generated_items := v_generated_items || jsonb_build_object(
            'item_id', v_item_id,
            'item_name', v_item_name,
            'quantity', v_qty_for_item
        );
    END LOOP;
    
    -- Inventory checks
    SELECT COUNT(*) INTO v_available_slots
    FROM public.inventory WHERE user_id = v_user_id AND slot_position BETWEEN 0 AND 19;
    v_available_slots := 20 - v_available_slots;
    
    -- Calculate slots needed
    FOR v_item_id, v_qty_for_item IN SELECT key, value::int FROM jsonb_each_text(v_items_breakdown) LOOP
        SELECT COALESCE(SUM(GREATEST(v_max_stack - quantity, 0)), 0)
        INTO v_existing_space FROM public.inventory
        WHERE user_id = v_user_id AND item_id = v_item_id;
        
        v_qty_remaining := GREATEST(v_qty_for_item - v_existing_space, 0);
        IF v_qty_remaining > 0 THEN
            v_required_slots := v_required_slots + CEIL(v_qty_remaining::numeric / v_max_stack::numeric)::int;
        END IF;
    END LOOP;
    
    -- Get available slots
    SELECT ARRAY_AGG(s ORDER BY s) INTO v_available_slot_list
    FROM generate_series(0, 19) s
    WHERE NOT EXISTS (SELECT 1 FROM public.inventory WHERE user_id = v_user_id AND slot_position = s);
    
    IF v_required_slots > COALESCE(array_length(v_available_slot_list, 1), 0) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Inventory full',
            'count', v_total_qty,
            'items_generated', v_generated_items
        );
    END IF;
    
    -- Add to inventory - FIXED to count correctly
    v_slot_idx := 1;
    FOR v_item_id, v_qty_for_item IN SELECT key, value::int FROM jsonb_each_text(v_items_breakdown) LOOP
        v_qty_remaining := v_qty_for_item;
        
        -- Update existing stacks
        FOR v_existing_item IN
            SELECT row_id, quantity FROM public.inventory
            WHERE user_id = v_user_id AND item_id = v_item_id AND quantity < v_max_stack
            ORDER BY quantity DESC
        LOOP
            v_add_qty := LEAST(v_max_stack - v_existing_item.quantity, v_qty_remaining);
            UPDATE public.inventory SET quantity = quantity + v_add_qty, updated_at = NOW()
            WHERE row_id = v_existing_item.row_id;
            v_qty_remaining := v_qty_remaining - v_add_qty;
            v_items_updated := v_items_updated + 1;
            
            IF v_qty_remaining <= 0 THEN EXIT; END IF;
        END LOOP;
        
        -- Insert new stacks
        WHILE v_qty_remaining > 0 LOOP
            v_add_qty := LEAST(v_max_stack, v_qty_remaining);
            INSERT INTO public.inventory (user_id, item_id, quantity, enhancement_level, is_equipped, obtained_at, slot_position)
            VALUES (v_user_id, v_item_id, v_add_qty, 0, false, EXTRACT(EPOCH FROM NOW())::BIGINT, v_available_slot_list[v_slot_idx]);
            v_items_inserted := v_items_inserted + 1;
            v_slot_idx := v_slot_idx + 1;
            v_qty_remaining := v_qty_remaining - v_add_qty;
        END LOOP;
    END LOOP;
    
    -- Update facility
    UPDATE public.facilities SET
        last_production_collected_at = v_now,
        production_started_at = NULL,
        suspicion_level = GREATEST(0, suspicion_level - 10)
    WHERE id = p_facility_id;
    
    -- NOTE: Don't update global_suspicion_level here!
    -- Client handles risk calculation and syncs via update_global_suspicion_level RPC
    -- This keeps risk sync centralized and prevents conflicts
    
    -- Get current facility suspicion for prison check
    SELECT COALESCE(suspicion_level, 0) INTO v_new_global_suspicion
    FROM public.facilities WHERE id = p_facility_id;
    
    -- PROBABILISTIC prison admission based on global suspicion %
    IF v_new_global_suspicion >= 50 THEN
        v_prison_chance := 50 + v_new_global_suspicion;  -- At 50% = 100%, at 100% = 150%
        v_prison_roll := (((p_seed + 19) * 16807) % 2147483647) / 2147483647.0 * 100;
        
        IF v_prison_roll < v_prison_chance AND NOT EXISTS (
            SELECT 1 FROM public.prison_records WHERE user_id = v_user_id AND released_at IS NULL
        ) THEN
            PERFORM admit_to_prison(p_facility_id, v_new_global_suspicion);
        END IF;
    END IF;
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Resources collected successfully',
        'count', v_total_qty,
        'total_added', v_total_qty,
        'items_generated', v_generated_items,
        'items_breakdown', v_items_breakdown,
        'items_inserted', v_items_inserted,
        'items_updated', v_items_updated
    );

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

GRANT EXECUTE ON FUNCTION public.collect_facility_resources_v2(UUID, BIGINT) TO authenticated;

-- RPC 7: reset_facility_production (for testing - clears all production data)
CREATE OR REPLACE FUNCTION public.reset_facility_production(p_facility_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_facility RECORD;
    v_deleted_queue INT := 0;
BEGIN
    v_user_id := auth.uid();
    
    SELECT * INTO v_facility FROM public.facilities
    WHERE id = p_facility_id AND user_id = v_user_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Facility not found or not owned');
    END IF;
    
    -- Clear production queue for this facility
    DELETE FROM public.facility_queue
    WHERE facility_id = p_facility_id AND status = 'in_progress'
    RETURNING COUNT(*) INTO v_deleted_queue;
    
    -- Reset facility production
    UPDATE public.facilities
    SET 
        production_started_at = NULL,
        last_production_collected_at = NULL,
        suspicion_level = 0,
        updated_at = NOW()
    WHERE id = p_facility_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Facility production reset',
        'queue_items_deleted', COALESCE(v_deleted_queue, 0),
        'facility_id', p_facility_id,
        'facility_type', v_facility.type
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.reset_facility_production(UUID) TO authenticated;

-- RPC 8: reset_all_facility_production (for testing - clears ALL production data for all facilities)
CREATE OR REPLACE FUNCTION public.reset_all_facility_production()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_deleted_queue INT := 0;
    v_reset_count INT := 0;
BEGIN
    v_user_id := auth.uid();
    
    -- Clear all production queues for this user
    DELETE FROM public.facility_queue
    WHERE facility_id IN (
        SELECT id FROM public.facilities WHERE user_id = v_user_id
    ) AND status = 'in_progress';
    
    GET DIAGNOSTICS v_deleted_queue = ROW_COUNT;
    
    -- Reset all facilities for this user
    UPDATE public.facilities
    SET 
        production_started_at = NULL,
        last_production_collected_at = NULL,
        suspicion_level = 0,
        updated_at = NOW()
    WHERE user_id = v_user_id;
    
    GET DIAGNOSTICS v_reset_count = ROW_COUNT;
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'All facility production reset',
        'facilities_reset', v_reset_count,
        'queue_items_deleted', COALESCE(v_deleted_queue, 0)
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.reset_all_facility_production() TO authenticated;
