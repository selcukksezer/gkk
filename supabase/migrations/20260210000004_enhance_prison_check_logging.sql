-- Migration: Enhance prison check logic and logging
-- Updates collect_facility_resources_v2 to:
-- 1. Always perform prison check (not just when suspicion >= 50)
-- 2. Use formula: prison_chance = 20 + global_suspicion
-- 3. Log detailed roll and decision info

-- Drop the old function first
DROP FUNCTION IF EXISTS public.collect_facility_resources_v2(UUID, BIGINT, INT) CASCADE;

-- Update the collect_facility_resources_v2 function
CREATE OR REPLACE FUNCTION public.collect_facility_resources_v2(
    p_facility_id UUID,
    p_seed BIGINT,
    p_total_count INT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_facility RECORD;
    v_type TEXT;
    v_level INT;
    v_started_at TIMESTAMPTZ;
    v_end_time TIMESTAMPTZ;
    v_now TIMESTAMPTZ := NOW();
    v_calc_time TIMESTAMPTZ;
    v_last_collected TIMESTAMPTZ;
    v_elapsed_seconds FLOAT;
    v_production_duration INT;
    v_base_rate FLOAT;
    v_total_qty INT;
    v_available_slots INT;
    v_available_slot_list INT[];
    v_max_stack INT := 99;
    v_i INT;
    v_rng_val FLOAT;
    v_cumulative FLOAT;
    v_rarity TEXT;
    v_resource_index INT;
    v_item_id TEXT;
    v_qty_for_item INT;
    v_generated_items JSONB := '[]'::jsonb;
    v_items_breakdown JSONB := '{}'::jsonb;
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
    v_item_name TEXT;
    v_existing_space INT;
    v_qty_remaining INT;
    
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
    v_production_duration := CASE v_type
        WHEN 'mining' THEN 300
        WHEN 'quarry' THEN 300
        WHEN 'lumber_mill' THEN 300
        WHEN 'clay_pit' THEN 300
        WHEN 'sand_quarry' THEN 300
        WHEN 'farming' THEN 300
        WHEN 'herb_garden' THEN 300
        WHEN 'ranch' THEN 300
        WHEN 'apiary' THEN 300
        WHEN 'mushroom_farm' THEN 300
        WHEN 'rune_mine' THEN 300
        WHEN 'holy_spring' THEN 300
        WHEN 'shadow_pit' THEN 300
        WHEN 'elemental_forge' THEN 300
        WHEN 'time_well' THEN 300
        ELSE 300
    END;
    
    v_base_rate := CASE v_type
        WHEN 'mining' THEN 10.0
        WHEN 'quarry' THEN 8.0
        WHEN 'lumber_mill' THEN 9.0
        WHEN 'clay_pit' THEN 7.0
        WHEN 'sand_quarry' THEN 6.0
        WHEN 'farming' THEN 11.0
        WHEN 'herb_garden' THEN 10.0
        WHEN 'ranch' THEN 9.0
        WHEN 'apiary' THEN 8.0
        WHEN 'mushroom_farm' THEN 7.0
        WHEN 'rune_mine' THEN 5.0
        WHEN 'holy_spring' THEN 4.0
        WHEN 'shadow_pit' THEN 4.0
        WHEN 'elemental_forge' THEN 3.0
        WHEN 'time_well' THEN 2.0
        ELSE 10.0
    END;
    
    v_end_time := v_started_at + (v_production_duration || ' seconds')::INTERVAL;
    v_calc_time := LEAST(v_now, v_end_time);
    v_last_collected := COALESCE(v_facility.last_production_collected_at, v_started_at);
    v_elapsed_seconds := EXTRACT(EPOCH FROM (v_calc_time - v_last_collected));
    
    v_server_calc_qty := LEAST(
        GREATEST(0, ((v_elapsed_seconds / 3600.0) * (v_base_rate * v_level * 10))::INT),
        100
    );
    
    IF p_total_count IS NOT NULL AND p_total_count >= 0 AND p_total_count <= v_server_calc_qty + 2 THEN
        v_total_qty := p_total_count;
    ELSE
        v_total_qty := v_server_calc_qty;
    END IF;
    
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
    
    -- Rarity weights
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
    
    -- Generate items with LCG RNG
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
    
    FOR v_item_id IN SELECT key FROM jsonb_each(v_items_breakdown) LOOP
        v_qty_for_item := (v_items_breakdown->>v_item_id)::INT;
        SELECT name INTO v_item_name FROM public.items WHERE id = v_item_id LIMIT 1;
        v_generated_items := v_generated_items || jsonb_build_object(
            'item_id', v_item_id,
            'item_name', v_item_name,
            'quantity', v_qty_for_item
        );
    END LOOP;
    
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
    
    UPDATE public.facilities SET
        last_production_collected_at = v_now,
        production_started_at = NULL,
        suspicion_level = GREATEST(0, suspicion_level - 10)
    WHERE id = p_facility_id;
    
    -- Prison check uses GLOBAL suspicion level (accounting for baseline risk)
    SELECT COALESCE(global_suspicion_level, 0) INTO v_new_global_suspicion
    FROM public.users WHERE auth_id = v_user_id;
    
    -- Calculate prison chance: base 20% + 1% per suspicion point
    v_prison_chance := 20 + v_new_global_suspicion;
    v_prison_roll := (((p_seed + 19) * 16807) % 2147483647) / 2147483647.0 * 100;
    
    RAISE LOG '[collect_facility_resources_v2] PRISON CHECK: global_suspicion=%, prison_chance=%, roll=%, within_chance=%',
        v_new_global_suspicion, v_prison_chance, ROUND(v_prison_roll::NUMERIC, 2), (v_prison_roll < v_prison_chance);
    
    IF v_prison_roll < v_prison_chance AND NOT EXISTS (
        SELECT 1 FROM public.prison_records WHERE user_id = v_user_id AND released_at IS NULL
    ) THEN
        RAISE LOG '[collect_facility_resources_v2] PRISON ADMIT: Sent to prison (roll % < chance %)', 
            ROUND(v_prison_roll::NUMERIC, 2), v_prison_chance;
        PERFORM admit_to_prison(p_facility_id, v_new_global_suspicion);
    ELSIF v_prison_roll >= v_prison_chance THEN
        RAISE LOG '[collect_facility_resources_v2] PRISON AVOIDED: Escaped this time (roll % >= chance %)', 
            ROUND(v_prison_roll::NUMERIC, 2), v_prison_chance;
    ELSE
        RAISE LOG '[collect_facility_resources_v2] PRISON SKIP: Already imprisoned';
    END IF;
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Resources collected successfully',
        'count', v_total_qty,
        'total_added', v_total_qty,
        'items_generated', v_generated_items,
        'prison_check', jsonb_build_object(
            'global_suspicion', v_new_global_suspicion,
            'prison_chance', v_prison_chance,
            'prison_roll', ROUND(v_prison_roll::NUMERIC, 2),
            'admission_occurred', (v_prison_roll < v_prison_chance AND NOT EXISTS (
                SELECT 1 FROM public.prison_records WHERE user_id = v_user_id AND released_at IS NULL
            ))
        )
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.collect_facility_resources_v2(UUID, BIGINT, INT) TO authenticated;
