-- Force repack all unequipped items into sequential slots 0, 1, 2...
DO $$
DECLARE
    v_user_id UUID;
    v_item RECORD;
    v_counter INT := 0;
BEGIN
    -- For each user
    FOR v_user_id IN (SELECT DISTINCT user_id FROM public.inventory) LOOP
        v_counter := 0;
        
        -- Loop through all UNEQUIPPED items for this user, ordered by obtained_at
        FOR v_item IN (
            SELECT row_id 
            FROM public.inventory 
            WHERE user_id = v_user_id 
              AND is_equipped = FALSE
            ORDER BY obtained_at ASC, row_id ASC
        ) LOOP
            -- Assign new sequential slot
            UPDATE public.inventory
            SET slot_position = v_counter
            WHERE row_id = v_item.row_id;
            
            v_counter := v_counter + 1;
        END LOOP;
        
        RAISE NOTICE 'User %: Repacked % items into slots 0-%', v_user_id, v_counter, v_counter - 1;
    END LOOP;
END $$;
