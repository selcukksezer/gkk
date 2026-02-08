-- Migration: Accept p_total_count from client to guarantee shown == collected
-- The client pre-calculates total_count using the same formula. By accepting it
-- as a parameter, server uses client's count (after validation) so the number
-- of items shown in the UI always matches what gets added to inventory.

-- RPC: Update global suspicion level from client calculation
-- Allows client to sync calculated risk based on active facilities to database
CREATE OR REPLACE FUNCTION public.update_global_suspicion_level(
    p_global_suspicion INT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    
    UPDATE public.users
    SET global_suspicion_level = GREATEST(0, LEAST(100, p_global_suspicion))
    WHERE id = v_user_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Global suspicion level updated',
        'new_level', GREATEST(0, LEAST(100, p_global_suspicion))
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_global_suspicion_level(INT) TO authenticated;

-- Drop old signatures first
DROP FUNCTION IF EXISTS public.collect_facility_resources_v2(UUID, BIGINT) CASCADE;
DROP FUNCTION IF EXISTS public.collect_facility_resources_v2(UUID, BIGINT, INT) CASCADE;

CREATE OR REPLACE FUNCTION public.collect_facility_resources_v2(
    p_facility_id UUID,
    p_seed BIGINT,
    p_total_count INT DEFAULT NULL
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
    
    v_server_calc_qty INT;
    
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
    
    -- Server-side calculation for validation
    v_end_time := v_started_at + (v_production_duration || ' seconds')::INTERVAL;
    v_calc_time := LEAST(v_now, v_end_time);
    v_last_collected := COALESCE(v_facility.last_production_collected_at, v_started_at);
    v_elapsed_seconds := EXTRACT(EPOCH FROM (v_calc_time - v_last_collected));
    
    v_server_calc_qty := LEAST(
        GREATEST(0, ((v_elapsed_seconds / 3600.0) * (v_base_rate * v_level * 10))::INT),
        100
    );
    
    -- Use client's p_total_count if provided and reasonable (within ±2 of server calc)
    -- This eliminates timing/float-precision mismatches between client and server
    IF p_total_count IS NOT NULL AND p_total_count >= 0 AND p_total_count <= v_server_calc_qty + 2 THEN
        v_total_qty := p_total_count;
    ELSE
        v_total_qty := v_server_calc_qty;
    END IF;
    
    RAISE LOG '[RPC_DEBUG] facility=%, level=%, server_calc=%, client_count=%, using=%',
        v_type, v_level, v_server_calc_qty, COALESCE(p_total_count, -1), v_total_qty;
    
    IF v_total_qty <= 0 THEN
        RETURN jsonb_build_object('success', true, 'message', 'No resources yet', 'count', 0, 'items_generated', '[]'::jsonb);
    END IF;
    
    -- Resource pools (same as client FACILITY_RESOURCES_FULL)
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
    
    -- Rarity weights (same formula as client get_rarity_chances_at_level)
    v_weights := jsonb_build_object(
        'COMMON', 700.0,
        'UNCOMMON', 200.0 + ((v_level - 1) * 15.0),
        'RARE', 80.0 + ((v_level - 1) * 8.0),
        'EPIC', 15.0 + ((v_level - 1) * 3.0),
        'LEGENDARY', 5.0 + ((v_level - 1) * 1.5)
    );
    
    SELECT SUM(value::NUMERIC)::NUMERIC INTO v_total_weight FROM jsonb_each_text(v_weights);
    v_total_weight := COALESCE(v_total_weight, 0);
    
    -- Unlocked rarities
    v_unlocked_rarities := ARRAY[]::TEXT[];
    IF v_level >= 1 THEN v_unlocked_rarities := array_append(v_unlocked_rarities, 'COMMON'); END IF;
    IF v_level >= 3 THEN v_unlocked_rarities := array_append(v_unlocked_rarities, 'UNCOMMON'); END IF;
    IF v_level >= 5 THEN v_unlocked_rarities := array_append(v_unlocked_rarities, 'RARE'); END IF;
    IF v_level >= 7 THEN v_unlocked_rarities := array_append(v_unlocked_rarities, 'EPIC'); END IF;
    IF v_level >= 10 THEN v_unlocked_rarities := array_append(v_unlocked_rarities, 'LEGENDARY'); END IF;
    
    -- Generate items with LCG RNG (same algorithm as client)
    FOR v_i IN 1..v_total_qty LOOP
        v_rng_val := ((p_seed + v_i) * 16807.0 % 2147483647.0) / 2147483647.0;
        v_cumulative := 0.0;
        v_rarity := 'COMMON';
        
        IF (v_weights->>'COMMON')::NUMERIC / v_total_weight <= v_rng_val THEN
            v_cumulative := (v_weights->>'COMMON')::NUMERIC / v_total_weight;
            IF v_cumulative + (v_weights->>'UNCOMMON')::NUMERIC / v_total_weight > v_rng_val THEN
                v_rarity := 'UNCOMMON';
            ELSIF v_cumulative + (v_weights->>'UNCOMMON')::NUMERIC / v_total_weight + (v_weights->>'RARE')::NUMERIC / v_total_weight > v_rng_val THEN
                v_rarity := 'RARE';
            ELSIF v_cumulative + (v_weights->>'UNCOMMON')::NUMERIC / v_total_weight + (v_weights->>'RARE')::NUMERIC / v_total_weight + (v_weights->>'EPIC')::NUMERIC / v_total_weight > v_rng_val THEN
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
        
        -- Pick resource index (same as client)
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
    
    -- Build items array for response
    FOR v_item_id IN SELECT key FROM jsonb_each(v_items_breakdown) LOOP
        v_qty_for_item := (v_items_breakdown->>v_item_id)::INT;
        SELECT name INTO v_item_name FROM public.items WHERE id = v_item_id LIMIT 1;
        v_generated_items := v_generated_items || jsonb_build_object(
            'item_id', v_item_id,
            'item_name', v_item_name,
            'quantity', v_qty_for_item
        );
    END LOOP;
    
    -- Inventory space check
    SELECT COUNT(*) INTO v_available_slots
    FROM public.inventory WHERE user_id = v_user_id AND slot_position BETWEEN 0 AND 19;
    v_available_slots := 20 - v_available_slots;
    
    FOR v_item_id, v_qty_for_item IN SELECT key, value::int FROM jsonb_each_text(v_items_breakdown) LOOP
        SELECT COALESCE(SUM(GREATEST(v_max_stack - quantity, 0)), 0)
        INTO v_existing_space FROM public.inventory
        WHERE user_id = v_user_id AND item_id = v_item_id;
        
        v_qty_remaining := GREATEST(v_qty_for_item - v_existing_space, 0);
        IF v_qty_remaining > 0 THEN
            v_required_slots := v_required_slots + CEIL(v_qty_remaining::numeric / v_max_stack::numeric)::int;
        END IF;
    END LOOP;
    
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
    
    -- Add to inventory
    v_slot_idx := 1;
    FOR v_item_id, v_qty_for_item IN SELECT key, value::int FROM jsonb_each_text(v_items_breakdown) LOOP
        v_qty_remaining := v_qty_for_item;
        
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
        
        WHILE v_qty_remaining > 0 LOOP
            v_add_qty := LEAST(v_max_stack, v_qty_remaining);
            INSERT INTO public.inventory (user_id, item_id, quantity, enhancement_level, is_equipped, obtained_at, slot_position)
            VALUES (v_user_id, v_item_id, v_add_qty, 0, false, EXTRACT(EPOCH FROM NOW())::BIGINT, v_available_slot_list[v_slot_idx]);
            v_items_inserted := v_items_inserted + 1;
            v_slot_idx := v_slot_idx + 1;
            v_qty_remaining := v_qty_remaining - v_add_qty;
        END LOOP;
    END LOOP;
    
    -- Update facility: clear production
    UPDATE public.facilities SET
        last_production_collected_at = v_now,
        production_started_at = NULL,
        suspicion_level = GREATEST(0, suspicion_level - 10)
    WHERE id = p_facility_id;
    
    -- NOTE: Don't update global_suspicion_level here!
    -- Client handles risk calculation and syncs via update_global_suspicion_level RPC
    -- This keeps risk sync centralized and prevents conflicts
    
    -- Prison check uses GLOBAL suspicion level (accounting for baseline risk)
    -- Get user's current global suspicion level (which already has baseline subtracted)
    SELECT COALESCE(global_suspicion_level, 0) INTO v_new_global_suspicion
    FROM public.users WHERE auth_id = v_user_id;
    
    -- Calculate prison chance based on global suspicion
    -- Formula: base_chance (20%) + suspicion_multiplier (1% per suspicion point)
    v_prison_chance := 20 + v_new_global_suspicion;
    v_prison_roll := (((p_seed + 19) * 16807) % 2147483647) / 2147483647.0 * 100;
    
    RAISE LOG '[collect_facility_resources_v2] PRISON CHECK: global_suspicion=%, chance=%, roll=%, within_chance=%',
        v_new_global_suspicion, v_prison_chance, ROUND(v_prison_roll::NUMERIC, 2), (v_prison_roll < v_prison_chance);
    
    -- Admit to prison if roll succeeds and not already in prison
    IF v_prison_roll < v_prison_chance AND NOT EXISTS (
        SELECT 1 FROM public.prison_records WHERE user_id = v_user_id AND released_at IS NULL
    ) THEN
        RAISE LOG '[collect_facility_resources_v2] PRISON ADMIT: User sent to prison (roll % < chance %)',
            ROUND(v_prison_roll::NUMERIC, 2), v_prison_chance;
        PERFORM admit_to_prison(p_facility_id, v_new_global_suspicion);
    ELSIF v_prison_roll >= v_prison_chance THEN
        RAISE LOG '[collect_facility_resources_v2] PRISON AVOIDED: User avoided prison this time';
    ELSE
        RAISE LOG '[collect_facility_resources_v2] PRISON SKIP: User already in prison';
    END IF;
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Resources collected successfully',
        'count', v_total_qty,
        'total_added', v_total_qty,
        'items_generated', v_generated_items,
        'items_breakdown', v_items_breakdown,
        'items_inserted', v_items_inserted,
        'items_updated', v_items_updated,
        'seed_used', p_seed
    );

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- Grant to both old and new signatures
GRANT EXECUTE ON FUNCTION public.collect_facility_resources_v2(UUID, BIGINT, INT) TO authenticated;
