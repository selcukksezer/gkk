-- ============================================================
-- CONSOLIDATED FACILITIES SYSTEM
-- ============================================================
-- Complete facilities system with all tables and RPC functions
-- Last updated: 2026-02-08
-- 
-- This single file contains:
-- 1. Users table extensions (global suspicion tracking)
-- 2. Facilities table schema
-- 3. Supporting tables (recipes, queue, prison records)
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

-- RPC 1: unlock_facility (consolidated)
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
    
    -- Default cost (client can override via config)
    v_cost := 5000;
    
    -- Check Balance
    IF (SELECT gold FROM public.users WHERE id = v_user_id) < v_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient gold');
    END IF;
    
    -- Deduct Gold
    UPDATE public.users SET gold = gold - v_cost WHERE id = v_user_id;
    
    -- UPSERT: Insert new facility or reactivate existing one
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
    
    -- Verify facility ownership
    SELECT * INTO v_facility
    FROM public.facilities
    WHERE id = p_facility_id AND user_id = v_user_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Facility not found or not owned');
    END IF;
    
    -- Check energy
    SELECT energy INTO v_current_energy FROM public.users WHERE id = v_user_id;
    IF v_current_energy < v_energy_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient energy');
    END IF;
    
    -- Deduct energy
    UPDATE public.users
    SET energy = energy - v_energy_cost
    WHERE id = v_user_id;
    
    -- Start production
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
    
    -- Update facility suspicion (max 100)
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

-- RPC 3: collect_facility_resources_v2 (advanced with deterministic RNG)
CREATE OR REPLACE FUNCTION public.collect_facility_resources_v2(
    p_facility_id UUID,
    p_seed BIGINT,
    p_debug BOOLEAN DEFAULT false
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
    v_last_collected TIMESTAMPTZ;
    v_now TIMESTAMPTZ := NOW();
    
    v_production_duration_seconds NUMERIC := 120;
    v_calc_end TIMESTAMPTZ;
    v_hours_elapsed FLOAT;
    v_production_rate INT;
    v_total_qty INT;
    v_offline_cap INT := 720;
    v_base_rate INT := 10;
    
    v_w_common FLOAT := 700.0;
    v_w_uncommon FLOAT := 200.0;
    v_w_rare FLOAT := 80.0;
    v_w_epic FLOAT := 15.0;
    v_w_legendary FLOAT := 5.0;
    v_total_weight FLOAT;
    
    v_resources_pool TEXT[] := '{}';
    v_generated_items JSONB := '[]'::jsonb;
    v_items_breakdown JSONB := '{}'::jsonb;
    
    v_roll FLOAT;
    v_rarity TEXT;
    v_item_id TEXT;
    v_item_name TEXT;
    v_rarity_idx INT;
    v_random_val FLOAT;
    v_qty_for_item INT;
    
    v_required_slots INT := 0;
    v_available_slots INT := 0;
    v_available_slot_list INT[] := ARRAY[]::int[];
    v_max_stack INT := 500;
    v_existing_space INT := 0;
    v_qty_remaining INT := 0;
    v_add_qty INT := 0;
    v_slot_idx INT := 1;
    v_existing_item RECORD;
    
    v_items_inserted INT := 0;
    v_items_updated INT := 0;
    
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT * INTO v_facility
    FROM public.facilities
    WHERE id = p_facility_id AND user_id = v_user_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Facility not found or not owned');
    END IF;

    v_type := v_facility.type;
    v_level := COALESCE(v_facility.level, 1);
    v_started_at := v_facility.production_started_at;
    v_last_collected := COALESCE(v_facility.last_production_collected_at, v_started_at);

    IF v_started_at IS NULL THEN
         RETURN jsonb_build_object('success', false, 'error', 'Production not started');
    END IF;
    
    IF v_last_collected IS NULL THEN
        v_last_collected := v_started_at;
    END IF;
    IF v_last_collected < v_started_at THEN
        v_last_collected := v_started_at;
    END IF;
    
    v_calc_end := LEAST(v_now, v_started_at + (v_production_duration_seconds || ' seconds')::interval);
    IF v_last_collected >= v_calc_end THEN
        RETURN jsonb_build_object(
            'success', true,
            'message', 'No resources accumulated yet',
            'count', 0,
            'items_generated', '[]'::jsonb,
            'items_breakdown', '{}'::jsonb
        );
    END IF;
    
    v_hours_elapsed := EXTRACT(EPOCH FROM (v_calc_end - v_last_collected)) / 3600.0;
    v_production_rate := v_base_rate * v_level * 10;
    v_total_qty := GREATEST(0, (v_hours_elapsed * v_production_rate)::INT);
    
    IF v_total_qty <= 0 THEN
        RETURN jsonb_build_object('success', true, 'message', 'No resources accumulated yet', 'count', 0);
    END IF;
    
    v_total_qty := LEAST(v_total_qty, v_offline_cap);
    
    -- Resource pools for all 15 facility types
    v_resources_pool := CASE v_type
        WHEN 'mining' THEN ARRAY['iron_ore', 'copper_ore', 'silver_ore', 'gold_ore', 'mithril_ore']
        WHEN 'quarry' THEN ARRAY['granite', 'marble', 'crystal_shard', 'obsidian', 'moonstone']
        WHEN 'lumber_mill' THEN ARRAY['oak_wood', 'pine_wood', 'bamboo', 'elder_wood', 'world_tree_sap']
        WHEN 'clay_pit' THEN ARRAY['ceramic_clay', 'brick_clay', 'enchanted_clay', 'dragon_clay', 'primordial_clay']
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
        RETURN jsonb_build_object('success', false, 'error', 'Unknown facility type: ' || v_type);
    END IF;
    
    -- Adjust weights by level
    IF v_level > 1 THEN
        v_w_uncommon := v_w_uncommon + ((v_level - 1) * 15.0);
        v_w_rare := v_w_rare + ((v_level - 1) * 8.0);
        v_w_epic := v_w_epic + ((v_level - 1) * 3.0);
        v_w_legendary := v_w_legendary + ((v_level - 1) * 1.5);
    END IF;
    
    v_total_weight := v_w_common + v_w_uncommon + v_w_rare + v_w_epic + v_w_legendary;

    -- Generate items with deterministic RNG
    FOR i IN 1..v_total_qty LOOP
        v_random_val := ((p_seed + i * 17) * 16807) % 2147483647;
        v_random_val := v_random_val / 2147483647.0;
        
        v_roll := v_random_val * v_total_weight;
        IF v_roll < v_w_common THEN 
            v_rarity := 'common'; v_rarity_idx := 0;
        ELSIF v_roll < (v_w_common + v_w_uncommon) THEN 
            v_rarity := 'uncommon'; v_rarity_idx := 1;
        ELSIF v_roll < (v_w_common + v_w_uncommon + v_w_rare) THEN 
            v_rarity := 'rare'; v_rarity_idx := 2;
        ELSIF v_roll < (v_w_common + v_w_uncommon + v_w_rare + v_w_epic) THEN 
            v_rarity := 'epic'; v_rarity_idx := 3;
        ELSE 
            v_rarity := 'legendary'; v_rarity_idx := 4;
        END IF;
        
        v_rarity_idx := CASE v_rarity_idx
            WHEN 0 THEN (((p_seed + i * 13) * 16807) % 2147483647) % 2
            WHEN 1 THEN 2
            WHEN 2 THEN 3
            WHEN 3 THEN 4
            ELSE 4
        END;
        
        v_item_id := v_resources_pool[v_rarity_idx + 1];
        
        IF v_item_id IS NOT NULL THEN
            SELECT name INTO v_item_name FROM public.items WHERE id = v_item_id LIMIT 1;
            v_qty_for_item := COALESCE((v_items_breakdown->>v_item_id)::INT, 0) + 1;
            v_items_breakdown := jsonb_set(v_items_breakdown, ARRAY[v_item_id], to_jsonb(v_qty_for_item));
        END IF;
    END LOOP;
    
    -- Convert to array
    FOR v_item_id IN SELECT key FROM jsonb_each(v_items_breakdown) LOOP
        v_qty_for_item := (v_items_breakdown->>v_item_id)::INT;
        SELECT name INTO v_item_name FROM public.items WHERE id = v_item_id LIMIT 1;
        v_generated_items := v_generated_items || jsonb_build_object(
            'item_id', v_item_id,
            'item_name', v_item_name,
            'quantity', v_qty_for_item,
            'rarity', 'mixed'
        );
    END LOOP;

    -- Inventory capacity check
    SELECT COUNT(*) INTO v_available_slots
    FROM public.inventory
    WHERE user_id = v_user_id
      AND slot_position BETWEEN 0 AND 19;
    v_available_slots := 20 - v_available_slots;
    IF v_available_slots < 0 THEN
        v_available_slots := 0;
    END IF;

    -- Calculate required slots
    FOR v_item_id, v_qty_for_item IN
        SELECT key, value::int FROM jsonb_each_text(v_items_breakdown)
    LOOP
        SELECT COALESCE(SUM(GREATEST(v_max_stack - quantity, 0)), 0)
        INTO v_existing_space
        FROM public.inventory
        WHERE user_id = v_user_id AND item_id = v_item_id;

        v_qty_remaining := GREATEST(v_qty_for_item - v_existing_space, 0);
        IF v_qty_remaining > 0 THEN
            v_required_slots := v_required_slots + CEIL(v_qty_remaining::numeric / v_max_stack::numeric)::int;
        END IF;
    END LOOP;

    -- Build available slot list
    SELECT ARRAY_AGG(slot_num ORDER BY slot_num)
    INTO v_available_slot_list
    FROM generate_series(0, 19) slot_num
    WHERE NOT EXISTS (
        SELECT 1 FROM public.inventory
        WHERE user_id = v_user_id AND slot_position = slot_num
    );

    v_available_slots := COALESCE(array_length(v_available_slot_list, 1), 0);

    IF v_required_slots > v_available_slots THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Inventory is full',
            'required_slots', v_required_slots,
            'available_slots', v_available_slots,
            'count', v_total_qty,
            'items_generated', v_generated_items
        );
    END IF;

    -- Add items to inventory
    FOR v_item_id, v_qty_for_item IN
        SELECT key, value::int FROM jsonb_each_text(v_items_breakdown)
    LOOP
        v_qty_remaining := v_qty_for_item;

        -- Fill existing stacks
        FOR v_existing_item IN
            SELECT row_id, quantity, slot_position
            FROM public.inventory
            WHERE user_id = v_user_id AND item_id = v_item_id
            ORDER BY quantity ASC
        LOOP
            v_add_qty := LEAST(v_max_stack - v_existing_item.quantity, v_qty_remaining);
            IF v_add_qty > 0 THEN
                UPDATE public.inventory
                SET quantity = quantity + v_add_qty, updated_at = NOW()
                WHERE row_id = v_existing_item.row_id;
                v_qty_remaining := v_qty_remaining - v_add_qty;
                v_items_updated := v_items_updated + 1;
            END IF;
            IF v_qty_remaining <= 0 THEN
                EXIT;
            END IF;
        END LOOP;

        -- Insert new stacks
        WHILE v_qty_remaining > 0 LOOP
            v_add_qty := LEAST(v_max_stack, v_qty_remaining);
            INSERT INTO public.inventory (
                user_id, item_id, quantity, enhancement_level, is_equipped, obtained_at, slot_position
            ) VALUES (
                v_user_id, v_item_id, v_add_qty, 0, false, EXTRACT(EPOCH FROM NOW())::BIGINT,
                v_available_slot_list[v_slot_idx]
            );
            v_items_inserted := v_items_inserted + 1;
            v_slot_idx := v_slot_idx + 1;
            v_qty_remaining := v_qty_remaining - v_add_qty;
        END LOOP;
    END LOOP;

    -- Update facility
    UPDATE public.facilities
    SET last_production_collected_at = v_now,
        production_started_at = CASE 
            WHEN EXTRACT(EPOCH FROM (v_now - v_started_at)) >= v_production_duration_seconds THEN NULL
            ELSE production_started_at 
        END,
        suspicion_level = GREATEST(0, suspicion_level - GREATEST(5, (suspicion_level * 0.15)::INT))
    WHERE id = p_facility_id;
    
    -- NOTE: Don't update global_suspicion_level here!
    -- Client handles risk calculation and syncs via update_global_suspicion_level RPC
    -- This keeps risk sync centralized and prevents conflicts
    
    -- Check for prison admission (80%+ suspicion = 50% base chance, increases with suspicion)
    IF v_facility_suspicion_before >= 80 THEN
        PERFORM admit_to_prison(p_facility_id, v_facility_suspicion_before)
        WHERE NOT EXISTS (
            SELECT 1 FROM public.prison_records
            WHERE user_id = v_user_id AND released_at IS NULL
        );
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'message', 'Resources collected',
        'count', v_total_qty,
        'items_generated', v_generated_items,
        'items_breakdown', v_items_breakdown,
        'items_inserted', v_items_inserted,
        'items_updated', v_items_updated,
        'seed_used', p_seed
    );

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '[collect_v2] ERROR: %', SQLERRM;
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

GRANT EXECUTE ON FUNCTION public.collect_facility_resources_v2(UUID, BIGINT, BOOLEAN) TO authenticated;

-- RPC 4: bribe_officials (FIXED: updates global suspicion + validates reduction)
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
    
    -- Get current gems and global suspicion
    SELECT gems, global_suspicion_level 
    INTO v_current_gems, v_global_suspicion
    FROM public.users 
    WHERE id = v_user_id;
    
    IF v_current_gems < p_amount_gems THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient gems');
    END IF;
    
    -- Get facility suspicion before
    SELECT suspicion_level 
    INTO v_facility_suspicion_before
    FROM public.facilities 
    WHERE id = p_facility_id AND user_id = v_user_id;
    
    IF v_facility_suspicion_before IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Facility not found or not owned');
    END IF;
    
    -- Calculate reduction: 1 gem = 10 suspicion reduction
    v_suspicion_reduction := p_amount_gems * 10;
    
    -- If nothing to reduce, return error
    IF v_global_suspicion <= 0 AND v_facility_suspicion_before <= 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'No suspicion to reduce');
    END IF;
    
    -- Deduct Gems
    UPDATE public.users
    SET gems = gems - p_amount_gems
    WHERE id = v_user_id;
    
    -- Reduce global suspicion
    UPDATE public.users
    SET global_suspicion_level = GREATEST(0, global_suspicion_level - v_suspicion_reduction)
    WHERE id = v_user_id;
    
    -- Reduce facility suspicion
    UPDATE public.facilities
    SET suspicion_level = GREATEST(0, suspicion_level - v_suspicion_reduction)
    WHERE id = p_facility_id
    RETURNING suspicion_level INTO v_facility_suspicion_after;
    
    RETURN jsonb_build_object(
        'success', true, 
        'message', 'Bribed successfully. Immunity for 1 hour.',
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

-- RPC 5: admit_to_prison (prison system trigger)
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
    
    -- Verify facility exists
    IF NOT EXISTS (
        SELECT 1 FROM public.facilities 
        WHERE id = p_facility_id AND user_id = v_user_id
    ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Facility not found');
    END IF;
    
    -- Check if already in prison
    IF EXISTS (
        SELECT 1 FROM public.prison_records
        WHERE user_id = v_user_id AND released_at IS NULL
    ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Already in prison');
    END IF;
    
    -- Calculate sentence: 2 hours base + 1 hour per 10% suspicion (80% = 10 hours)
    v_sentence_hours := 2 + (p_suspicion_level / 10);
    v_release_time := NOW() + (v_sentence_hours || ' hours')::INTERVAL;
    
    -- Insert prison record (provide non-null reason)
    INSERT INTO public.prison_records (
        user_id, facility_id, reason, sentence_hours, admitted_at, released_at
    ) VALUES (
        v_user_id, p_facility_id, 'High suspicion at facility operations', v_sentence_hours, NOW(), v_release_time
    ) RETURNING id INTO v_prison_record_id;
    
    -- Reset facility suspicion
    UPDATE public.facilities
    SET suspicion_level = 0
    WHERE id = p_facility_id;
    
    -- Update user prison status
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

-- RPC 6: check_and_release_from_prison (background: check if player should be released)
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
    -- Find expired prison records
    FOR v_prison_record IN
        SELECT id, user_id FROM public.prison_records
        WHERE user_id = p_user_id
          AND released_at IS NOT NULL
          AND released_at <= v_today
          AND released_at > (SELECT MAX(released_at) FROM public.prison_records 
                          WHERE user_id = p_user_id AND released_at < v_today)
    LOOP
        v_released_count := v_released_count + 1;
    END LOOP;
    
    -- If released, update user status
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
