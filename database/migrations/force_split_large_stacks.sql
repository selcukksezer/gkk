-- Force split stacks > 50 into multiple stacks
-- This function iterates through all inventory items that exceed the stack limit
-- and splits them into new rows until they are <= 50.

DO $$
DECLARE
    v_rec RECORD;
    v_qty INT;
    v_split_qty INT;
    v_new_slot INT;
    v_user_id UUID;
BEGIN
    -- Loop through all items with quantity > 50
    FOR v_rec IN 
        SELECT * FROM public.inventory 
        WHERE quantity > 50 AND is_equipped = false
        ORDER BY obtained_at DESC
    LOOP
        v_qty := v_rec.quantity;
        v_user_id := v_rec.user_id;
        
        -- While we have more than 50
        WHILE v_qty > 50 LOOP
            -- We will keep 50 in the current row at the end
            -- So we peel off 50 chunks into NEW rows
            v_split_qty := 50; 
            
            -- Find a free slot (0-19)
            SELECT slot_num INTO v_new_slot
            FROM generate_series(0, 19) slot_num
            WHERE NOT EXISTS (
                SELECT 1 FROM public.inventory 
                WHERE user_id = v_user_id AND slot_position = slot_num
            )
            LIMIT 1;
            
            IF v_new_slot IS NULL THEN
                -- No empty slots! Stop splitting this item to prevent data loss.
                -- Use RAISE NOTICE to log it but don't fail transaction.
                RAISE NOTICE 'User % has no empty slots to split item %', v_user_id, v_rec.item_id;
                EXIT; -- Exit the WHILE loop, proceed to next item
            END IF;
            
            -- Insert new stack of 50
            INSERT INTO public.inventory (
                user_id, item_id, quantity, enhancement_level, is_equipped, 
                obtained_at, slot_position, is_favorite
            ) VALUES (
                v_user_id, v_rec.item_id, v_split_qty, v_rec.enhancement_level, false,
                EXTRACT(EPOCH FROM NOW())::bigint, v_new_slot, v_rec.is_favorite
            );
            
            -- Decrease remaining quantity locally
            v_qty := v_qty - v_split_qty;
            
            -- Decrease amount in the ORIGINAL row (to reflect what's left so far)
            UPDATE public.inventory 
            SET quantity = v_qty 
            WHERE row_id = v_rec.row_id;
            
        END LOOP;
        
    END LOOP;
END $$;
