CREATE OR REPLACE FUNCTION cancel_sell_order(
    p_order_id UUID,
    p_is_stackable BOOLEAN DEFAULT FALSE -- Kept for compatibility, but we will double check DB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_order_record RECORD;
    v_slot INT;
    v_item_data JSONB;
    v_enhancement_level INT;
    v_quantity INT;
    v_remaining_qty INT;
    v_dest_qty INT;
    v_space INT;
    v_transfer_qty INT;
    v_db_is_stackable BOOLEAN;
    v_db_max_stack INT;
    v_final_is_stackable BOOLEAN;
BEGIN
    v_user_id := auth.uid();
    
    -- 1. Find Order
    SELECT * INTO v_order_record
    FROM public.market_orders
    WHERE id = p_order_id AND seller_id = v_user_id;
    
    IF v_order_record IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Order not found');
    END IF;
    
    v_quantity := v_order_record.quantity;
    v_item_data := v_order_record.item_data;
    v_enhancement_level := COALESCE((v_item_data->>'enhancement_level')::int, 0);

    -- 2. Determine Stackability from DB (Source of Truth)
    SELECT is_stackable, max_stack 
    INTO v_db_is_stackable, v_db_max_stack
    FROM public.items 
    WHERE id = v_order_record.item_id;
    
    -- Fallback/Safety: If DB is null, trust parameter. If DB exists, use DB or Parameter (whichever is true)
    -- Actually, if DB says TRUE, we should definitely treat it as true.
    v_final_is_stackable := COALESCE(v_db_is_stackable, p_is_stackable);
    
    -- 3. Check Inventory Space & Restore
    
    IF v_final_is_stackable THEN
        -- Stackable Logic
        v_remaining_qty := v_quantity;
        
        WHILE v_remaining_qty > 0 LOOP
            v_slot := NULL;
            v_dest_qty := 0;
            
            -- Try to find existing partial stack
            SELECT slot_position, quantity INTO v_slot, v_dest_qty
            FROM public.inventory
            WHERE user_id = v_user_id 
              AND item_id = v_order_record.item_id
              AND enhancement_level = v_enhancement_level
              -- Ensure we don't overflow max_stack (default 50)
              AND quantity < COALESCE(v_db_max_stack, 50)
            ORDER BY quantity DESC 
            LIMIT 1;
            
            IF v_slot IS NOT NULL THEN
                -- Fill Existing Stack
                v_space := COALESCE(v_db_max_stack, 50) - v_dest_qty;
                v_transfer_qty := LEAST(v_remaining_qty, v_space);
                
                UPDATE public.inventory 
                SET quantity = quantity + v_transfer_qty
                WHERE user_id = v_user_id AND slot_position = v_slot;
                
                v_remaining_qty := v_remaining_qty - v_transfer_qty;
            ELSE
                -- New Slot
                SELECT MIN(slot_num) INTO v_slot
                FROM generate_series(0, 19) slot_num
                WHERE NOT EXISTS (SELECT 1 FROM public.inventory WHERE user_id = v_user_id AND slot_position = slot_num);
                
                IF v_slot IS NULL THEN
                    RAISE EXCEPTION 'Inventory full';
                END IF;
                
                -- Create new stack (capped at max_stack)
                v_transfer_qty := LEAST(v_remaining_qty, COALESCE(v_db_max_stack, 50));
                
                INSERT INTO public.inventory (
                    user_id, item_id, quantity, slot_position, 
                    enhancement_level, obtained_at, is_equipped, row_id
                ) VALUES (
                    v_user_id, 
                    v_order_record.item_id, 
                    v_transfer_qty, 
                    v_slot, 
                    v_enhancement_level,
                    (v_item_data->>'obtained_at')::bigint,
                    FALSE,
                    gen_random_uuid()
                );
                
                v_remaining_qty := v_remaining_qty - v_transfer_qty;
            END IF;
        END LOOP;
        
    ELSE
        -- Non-Stackable Logic
        -- Usually listings are single items for equip, but if multiple, separate them
        FOR i IN 1..v_quantity LOOP
             v_slot := NULL;
             SELECT MIN(slot_num) INTO v_slot
             FROM generate_series(0, 19) slot_num
             WHERE NOT EXISTS (SELECT 1 FROM public.inventory WHERE user_id = v_user_id AND slot_position = slot_num);
             
             IF v_slot IS NULL THEN
                 RAISE EXCEPTION 'Inventory full';
             END IF;
             
             INSERT INTO public.inventory (
                user_id, item_id, quantity, slot_position, 
                enhancement_level, obtained_at, is_equipped, row_id
             ) VALUES (
                v_user_id, 
                v_order_record.item_id, 
                1, 
                v_slot, 
                v_enhancement_level,
                (v_item_data->>'obtained_at')::bigint,
                FALSE,
                gen_random_uuid()
             );
        END LOOP;
    END IF;

    -- 4. Delete Order
    DELETE FROM public.market_orders WHERE id = p_order_id;
    
    RETURN jsonb_build_object('success', true);

EXCEPTION 
    WHEN OTHERS THEN
         IF SQLERRM = 'Inventory full' THEN
             RETURN jsonb_build_object('success', false, 'error', 'Inventory full');
         END IF;
         RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;
