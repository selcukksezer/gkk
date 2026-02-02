-- ============================================
-- RPC: Collect Facility Resources (Server-Side Calculation)
-- ============================================

CREATE OR REPLACE FUNCTION public.collect_facility_resources(
    p_facility_id UUID,
    p_resources JSONB DEFAULT '[]'::jsonb -- Kept for signature compatibility, ignored
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_facility RECORD;
    v_resources_generated JSONB := '[]'::jsonb;
    v_item RECORD;
    v_existing_item RECORD;
    v_items_inserted INT := 0;
    v_items_updated INT := 0;
    v_items_skipped INT := 0;
    v_to_add JSONB := '{}'::jsonb;
    v_required_slots INT := 0;
    v_available_slots INT := 0;
        v_available_slot_list INT[] := ARRAY[]::int[];
        v_slot_idx INT := 1;
    v_qty_to_add INT := 0;
    v_qty_remaining INT := 0;
    v_max_stack INT := 999;
    v_is_stackable BOOLEAN := true;
    v_existing_space INT := 0;
    v_item_id TEXT;
    v_add_qty INT := 0;
    
    -- Time Logic
    v_now TIMESTAMP WITH TIME ZONE := NOW();
    v_last_collected TIMESTAMP WITH TIME ZONE;
    v_started_at TIMESTAMP WITH TIME ZONE;
    v_hours_elapsed FLOAT;
    v_production_rate INT;
    v_total_qty INT;
    v_offline_cap INT := 720;
    v_production_duration_seconds NUMERIC := 120;  -- 2 minutes for testing (originally 3600 = 1 hour)
    v_calc_end TIMESTAMP WITH TIME ZONE;
    v_elapsed_since_start NUMERIC;
    
    -- Drop Rate Variables
    v_level INT;
    v_base_rate INT := 10;
    v_roll FLOAT;
    v_rarity TEXT;
    
    -- Weights (Base Level 1 - Matched with FacilityManager.gd)
    v_w_common FLOAT := 700.0;
    v_w_uncommon FLOAT := 200.0;
    v_w_rare FLOAT := 80.0;
    v_w_epic FLOAT := 15.0;
    v_w_legendary FLOAT := 5.0;
    v_total_weight FLOAT;
    
BEGIN
    -- Get authenticated user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    -- CHECK IF PLAYER IS IN PRISON
    IF EXISTS (
        SELECT 1 FROM public.prison_records 
        WHERE user_id = v_user_id AND released_at IS NULL
    ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Player is imprisoned and cannot collect resources');
    END IF;

    -- Verify facility ownership
    SELECT * INTO v_facility
    FROM public.facilities
    WHERE id = p_facility_id AND user_id = v_user_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Facility not found or not owned');
    END IF;

    v_level := COALESCE(v_facility.level, 1);
    v_started_at := v_facility.production_started_at;
    v_last_collected := COALESCE(v_facility.last_production_collected_at, v_started_at);

    -- Production Validation
    IF v_started_at IS NULL THEN
         RETURN jsonb_build_object('success', false, 'error', 'Production not started');
    END IF;
    
    -- CRITICAL: If last_collected is same as started, use started time (first collection from production start)
    -- Otherwise use the actual last collection time
    IF v_last_collected IS NULL THEN
        v_last_collected := v_started_at;
    END IF;
    IF v_last_collected < v_started_at THEN
        v_last_collected := v_started_at;
    END IF;
    
    -- Cap calculation to production duration window
    v_calc_end := LEAST(v_now, v_started_at + (v_production_duration_seconds || ' seconds')::interval);
    IF v_last_collected >= v_calc_end THEN
        RETURN jsonb_build_object(
            'success', true,
            'message', 'No resources accumulated yet',
            'count', 0,
            'items_inserted', 0,
            'items_updated', 0,
            'items_skipped', 0,
            'debug_started_at', v_started_at,
            'debug_last_collected', v_last_collected,
            'debug_calc_end', v_calc_end
        );
    END IF;
    
    -- Calculate hours elapsed since last collection
    v_hours_elapsed := EXTRACT(EPOCH FROM (v_calc_end - v_last_collected)) / 3600.0;
    
    RAISE NOTICE '[collect_facility_resources] DEBUG: started_at=%, last_collected=%, calc_end=%, hours_elapsed=%, now=%', v_started_at, v_last_collected, v_calc_end, v_hours_elapsed, v_now;
    
    -- Resources accumulate continuously: (hours_elapsed * base_rate * level * 10x multiplier)
    v_production_rate := v_base_rate * v_level * 10;  -- 10x for testing
    v_total_qty := GREATEST(0, (v_hours_elapsed * v_production_rate)::INT);
    
    RAISE NOTICE '[collect_facility_resources] CALC: hours_elapsed=%, rate=%, total_qty=%', v_hours_elapsed, v_production_rate, v_total_qty;
    
    -- If no time has passed, no resources
    IF v_total_qty <= 0 THEN
        RETURN jsonb_build_object('success', true, 'message', 'No resources accumulated yet', 'count', 0);
    END IF;
    
    -- Cap by offline production cap
    v_total_qty := LEAST(v_total_qty, v_offline_cap);
    
    -- Adjust Weights Scaling by Level (Sync with FacilityManager.gd)
    IF v_level > 1 THEN
        v_w_uncommon := v_w_uncommon + ((v_level - 1) * 15.0);
        v_w_rare := v_w_rare + ((v_level - 1) * 8.0);
        v_w_epic := v_w_epic + ((v_level - 1) * 3.0);
        v_w_legendary := v_w_legendary + ((v_level - 1) * 1.5);
    END IF;
    
    v_total_weight := v_w_common + v_w_uncommon + v_w_rare + v_w_epic + v_w_legendary;

    RAISE NOTICE '[collect_facility_resources] Start: user_id=%, facility_type=%, level=%, total_qty=%', v_user_id, v_facility.type, v_level, v_total_qty;
    
    -- Generate Items loop
    FOR i IN 1..v_total_qty LOOP
        v_roll := random() * v_total_weight;
        
        IF v_roll < v_w_common THEN v_rarity := 'common';
        ELSIF v_roll < (v_w_common + v_w_uncommon) THEN v_rarity := 'uncommon';
        ELSIF v_roll < (v_w_common + v_w_uncommon + v_w_rare) THEN v_rarity := 'rare';
        ELSIF v_roll < (v_w_common + v_w_uncommon + v_w_rare + v_w_epic) THEN v_rarity := 'epic';
        ELSE v_rarity := 'legendary';
        END IF;
        
                -- Select Item based on Facility Type & Rarity (case-insensitive)
                SELECT * INTO v_item
                FROM public.items
                WHERE production_building_type = v_facility.type
                    AND lower(rarity) = v_rarity
                ORDER BY random()
                LIMIT 1;
        
                -- Fallback if not found
                IF NOT FOUND THEN
                        RAISE NOTICE '[collect_facility_resources] No item found for type=% rarity=%, trying common', v_facility.type, v_rarity;
                        SELECT * INTO v_item
                        FROM public.items
                        WHERE production_building_type = v_facility.type
                            AND lower(rarity) = 'common'
                        ORDER BY random()
                        LIMIT 1;
                END IF;

                -- Final fallback: any item for this facility type
                IF NOT FOUND THEN
                    RAISE NOTICE '[collect_facility_resources] No rarity match, picking any item for type=%', v_facility.type;
                    SELECT * INTO v_item
                    FROM public.items
                    WHERE production_building_type = v_facility.type
                    ORDER BY random()
                    LIMIT 1;
                END IF;

                -- Last resort: pick any item at all (prevents zero inserts if type mapping is missing)
                IF NOT FOUND THEN
                    RAISE NOTICE '[collect_facility_resources] No item found for type=%, picking any item globally', v_facility.type;
                    SELECT * INTO v_item
                    FROM public.items
                    ORDER BY random()
                    LIMIT 1;
                END IF;
        
        IF FOUND THEN
            RAISE NOTICE '[collect_facility_resources] Item found: id=%, name=%, stackable=%, rarity=%', v_item.id, v_item.name, v_item.is_stackable, v_item.rarity;
            v_to_add := jsonb_set(
                v_to_add,
                ARRAY[v_item.id::text],
                to_jsonb(COALESCE((v_to_add->>v_item.id::text)::int, 0) + 1),
                true
            );
        ELSE
            v_items_skipped := v_items_skipped + 1;
            RAISE NOTICE '[collect_facility_resources] WARNING: No item found even in fallback for type=%', v_facility.type;
        END IF;
    END LOOP;
    
    RAISE NOTICE '[collect_facility_resources] Loop complete: processed % items', v_total_qty;

    -- ===== Inventory capacity check (20 slots) =====
    -- Count only valid slot positions (0-19)
    SELECT COUNT(*) INTO v_available_slots
    FROM public.inventory
    WHERE user_id = v_user_id
      AND slot_position BETWEEN 0 AND 19;
    v_available_slots := 20 - v_available_slots;
    IF v_available_slots < 0 THEN
        v_available_slots := 0;
    END IF;

    -- Calculate required slots based on stacking rules
    FOR v_item_id, v_qty_to_add IN
        SELECT key, value::int FROM jsonb_each_text(v_to_add)
    LOOP
        -- FACILITY ITEMS: All facility-produced items MUST stack with max=500
        -- Do NOT read from database - use fixed values
        v_is_stackable := true;
        v_max_stack := 500;

        IF v_is_stackable THEN
            SELECT COALESCE(SUM(GREATEST(v_max_stack - quantity, 0)), 0)
            INTO v_existing_space
            FROM public.inventory
            WHERE user_id = v_user_id AND item_id = v_item_id;

            v_qty_remaining := GREATEST(v_qty_to_add - v_existing_space, 0);
            IF v_qty_remaining > 0 THEN
                v_required_slots := v_required_slots + CEIL(v_qty_remaining::numeric / v_max_stack::numeric)::int;
            END IF;
        ELSE
            v_required_slots := v_required_slots + v_qty_to_add;
        END IF;
    END LOOP;

    -- Build available slot list (0-19)
    SELECT ARRAY_AGG(slot_num ORDER BY slot_num)
    INTO v_available_slot_list
    FROM generate_series(0, 19) slot_num
    WHERE NOT EXISTS (
        SELECT 1 FROM public.inventory
        WHERE user_id = v_user_id AND slot_position = slot_num
    );

    -- Recalculate available slots based on actual free positions
    v_available_slots := COALESCE(array_length(v_available_slot_list, 1), 0);

    IF v_required_slots > v_available_slots THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Inventory is full',
            'required_slots', v_required_slots,
            'available_slots', v_available_slots,
            'count', v_total_qty,
            'items_inserted', 0,
            'items_updated', 0,
            'items_skipped', v_items_skipped,
            'debug_started_at', v_started_at,
            'debug_last_collected', v_last_collected,
            'debug_calc_end', v_calc_end,
            'debug_hours_elapsed', v_hours_elapsed,
            'debug_rate', v_production_rate
        );
    END IF;

    -- ===== Apply additions =====
    FOR v_item_id, v_qty_to_add IN
        SELECT key, value::int FROM jsonb_each_text(v_to_add)
    LOOP

        -- FACILITY ITEMS: Force max_stack=500 for all facility-produced items
        v_is_stackable := true;
        v_max_stack := 500;

        RAISE NOTICE '[collect_facility_resources] Item %: stackable=%, max_stack=%', v_item_id, v_is_stackable, v_max_stack;

        IF v_is_stackable THEN
            v_qty_remaining := v_qty_to_add;

            -- Fill existing stacks first
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

            -- Insert new stacks if needed
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
        ELSE
            -- Non-stackable: each needs its own slot
            FOR i IN 1..v_qty_to_add LOOP
                INSERT INTO public.inventory (
                    user_id, item_id, quantity, enhancement_level, is_equipped, obtained_at, slot_position
                ) VALUES (
                    v_user_id, v_item_id, 1, 0, false, EXTRACT(EPOCH FROM NOW())::BIGINT,
                    v_available_slot_list[v_slot_idx]
                );
                v_items_inserted := v_items_inserted + 1;
                v_slot_idx := v_slot_idx + 1;
            END LOOP;
        END IF;
    END LOOP;

    -- Update Facility
    -- Update last_production_collected_at to NOW
    -- Reset production_started_at ONLY if 120 seconds have passed (status=expired)
    -- Otherwise keep production_started_at so production continues from where it left off
    
    BEGIN
        v_elapsed_since_start := EXTRACT(EPOCH FROM (v_now - v_started_at));
        RAISE NOTICE '[collect_facility_resources] Updating facility: elapsed_since_start=%, duration=%', v_elapsed_since_start, v_production_duration_seconds;
        
        IF v_elapsed_since_start >= v_production_duration_seconds THEN
            -- Production expired (120 seconds passed), reset for next cycle
            RAISE NOTICE '[collect_facility_resources] Production expired, resetting production_started_at';
            UPDATE public.facilities
            SET last_production_collected_at = v_now,
                production_started_at = NULL,
                suspicion = GREATEST(0, suspicion - GREATEST(5, (suspicion * 0.15)::INT))
            WHERE id = p_facility_id;
        ELSE
            -- Production still active (under 120 seconds), keep production_started_at
            RAISE NOTICE '[collect_facility_resources] Production still active, keeping production_started_at';
            UPDATE public.facilities
            SET last_production_collected_at = v_now,
                suspicion = GREATEST(0, suspicion - GREATEST(5, (suspicion * 0.15)::INT))
            WHERE id = p_facility_id;
        END IF;
    END;

    RAISE NOTICE '[collect_facility_resources] SUCCESS: collected %, inserted=%, updated=%', v_total_qty, v_items_inserted, v_items_updated;

    RETURN jsonb_build_object(
        'success', true,
        'message', 'Resources collected',
        'count', v_total_qty,
        'items_inserted', v_items_inserted,
        'items_updated', v_items_updated,
        'items_skipped', v_items_skipped,
        'debug_started_at', v_started_at,
        'debug_last_collected', v_last_collected,
        'debug_calc_end', v_calc_end,
        'debug_hours_elapsed', v_hours_elapsed,
        'debug_rate', v_production_rate,
        'new_suspicion', GREATEST(0, v_facility.suspicion - GREATEST(5, (v_facility.suspicion * 0.15)::INT))
    );

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '[collect_facility_resources] ERROR: %', SQLERRM;
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;
