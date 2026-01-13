-- Function to repair inventory slot collisions
-- Finds items that share the same slot_position and moves them to empty slots

CREATE OR REPLACE FUNCTION public.repair_inventory_slots(p_user_id UUID DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
    v_target_user_id UUID;
    v_item RECORD;
    v_conflicts RECORD;
    v_free_slot INT;
    v_repaired_count INT := 0;
    v_users_to_process UUID[];
    v_current_user UUID;
BEGIN
    -- Determine users to process (either specific one or all)
    IF p_user_id IS NOT NULL THEN
        v_users_to_process := ARRAY[p_user_id];
    ELSE
        SELECT ARRAY_AGG(id) INTO v_users_to_process FROM auth.users;
    END IF;

    FOREACH v_current_user IN ARRAY v_users_to_process
    LOOP
        -- Find collisions: Slots appearing more than once for this user (unequipped items only)
        FOR v_conflicts IN 
            SELECT slot_position, COUNT(*) as cnt
            FROM public.inventory
            WHERE user_id = v_current_user 
              AND is_equipped = FALSE 
              AND slot_position IS NOT NULL
            GROUP BY slot_position
            HAVING COUNT(*) > 1
        LOOP
            -- For each collision group, leave ONE item there, move the rest
            -- We order by updated_at desc to keep the most recent one in place (arbitrary choice)
            FOR v_item IN 
                SELECT row_id 
                FROM public.inventory 
                WHERE user_id = v_current_user 
                  AND slot_position = v_conflicts.slot_position
                  AND is_equipped = FALSE
                ORDER BY updated_at DESC
                OFFSET 1 -- Skip the first one (keep it)
            LOOP
                -- Find a new home for this displaced item
                v_free_slot := public._find_first_empty_slot(v_current_user);
                
                IF v_free_slot IS NOT NULL THEN
                    UPDATE public.inventory
                    SET slot_position = v_free_slot, updated_at = NOW()
                    WHERE row_id = v_item.row_id;
                    
                    v_repaired_count := v_repaired_count + 1;
                ELSE
                    -- Overflow! No safe slot. Set to special "overflow" index or NULL
                    -- Setting to -1 or NULL makes it invisible but safe from constraint error
                    UPDATE public.inventory
                    SET slot_position = NULL, updated_at = NOW()
                    WHERE row_id = v_item.row_id;
                END IF;
            END LOOP;
        END LOOP;
    END LOOP;

    RETURN jsonb_build_object(
        'success', true,
        'repaired_items', v_repaired_count
    );
END;
$$;
