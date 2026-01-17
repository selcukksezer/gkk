CREATE OR REPLACE FUNCTION public.purchase_market_listing(p_order_id UUID, p_quantity INT DEFAULT 1, p_is_stackable BOOLEAN DEFAULT FALSE)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order RECORD;
    v_buyer_id UUID;
    v_seller_id UUID;
    v_total_price BIGINT;
    v_buyer_gold BIGINT;
    v_item_data JSONB;
    v_commission_rate NUMERIC := 0.05; -- 5% commission
    v_commission_amount BIGINT;
    v_seller_revenue BIGINT;
    v_seller_gold BIGINT;
    v_remaining_qty INT;
    v_transfer_qty INT;
    v_dest_slot INT;
    v_dest_qty INT;
    v_space INT;
    v_enhancement_level INT;
BEGIN
    -- Get current user (buyer)
    v_buyer_id := auth.uid();
    IF v_buyer_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    -- Get Order
    SELECT * INTO v_order FROM public.market_orders WHERE id = p_order_id AND status = 'active' FOR UPDATE;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Listing not found or no longer active');
    END IF;

    v_seller_id := v_order.seller_id;
    
    -- Prevent self-trading
    IF v_seller_id = v_buyer_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'Cannot buy your own listing');
    END IF;
    
    -- Check Quantity
    IF p_quantity <= 0 THEN
         RETURN jsonb_build_object('success', false, 'error', 'Invalid quantity');
    END IF;
    
    IF v_order.quantity < p_quantity THEN
         RETURN jsonb_build_object('success', false, 'error', 'Not enough quantity available (Stock: ' || v_order.quantity || ')');
    END IF;

    -- Calculate Total Price
    v_total_price := v_order.price * p_quantity;
    
    -- Check Buyer Gold
    SELECT gold INTO v_buyer_gold FROM public.users WHERE auth_id = v_buyer_id OR id = v_buyer_id;
    
    IF v_buyer_gold < v_total_price THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not enough gold');
    END IF;

    -- Transaction
    -- 1. Deduct Gold from Buyer
    UPDATE public.users 
    SET gold = gold - v_total_price 
    WHERE auth_id = v_buyer_id OR id = v_buyer_id
    RETURNING gold INTO v_buyer_gold;
    
    -- 2. Add Gold to Seller (minus commission)
    v_commission_amount := FLOOR(v_total_price * v_commission_rate);
    v_seller_revenue := v_total_price - v_commission_amount;
    
    UPDATE public.users 
    SET gold = gold + v_seller_revenue 
    WHERE auth_id = v_seller_id OR id = v_seller_id
    RETURNING gold INTO v_seller_gold;
    
    -- 3. Transfer Item to Buyer with Stacking Logic
    v_item_data := v_order.item_data;
    v_enhancement_level := COALESCE((v_item_data->>'enhancement_level')::int, 0);
    v_remaining_qty := p_quantity;
    
    -- Handling Logic based on Stackability
    IF p_is_stackable THEN
        -- Legacy Stackable Logic (Potion, etc)
        WHILE v_remaining_qty > 0 LOOP
            v_dest_slot := NULL;
            v_dest_qty := 0;
            
            -- Try to find existing partial stack
            SELECT slot_position, quantity INTO v_dest_slot, v_dest_qty
            FROM public.inventory
            WHERE user_id = v_buyer_id 
              AND item_id = v_order.item_id
              AND enhancement_level = v_enhancement_level
              AND quantity < 50
            ORDER BY quantity DESC 
            LIMIT 1;
            
            IF v_dest_slot IS NOT NULL THEN
                -- Fill Existing Stack
                v_space := 50 - v_dest_qty;
                v_transfer_qty := LEAST(v_remaining_qty, v_space);
                
                UPDATE public.inventory 
                SET quantity = quantity + v_transfer_qty
                WHERE user_id = v_buyer_id AND slot_position = v_dest_slot;
                
                v_remaining_qty := v_remaining_qty - v_transfer_qty;
            ELSE
                -- New Slot
                SELECT MIN(slot_num) INTO v_dest_slot
                FROM generate_series(0, 19) slot_num
                WHERE NOT EXISTS (SELECT 1 FROM public.inventory WHERE user_id = v_buyer_id AND slot_position = slot_num);
                
                IF v_dest_slot IS NULL THEN
                    RAISE EXCEPTION 'Inventory full';
                END IF;
                
                v_transfer_qty := LEAST(v_remaining_qty, 50);
                
                INSERT INTO public.inventory (
                    user_id, item_id, quantity, slot_position, 
                    enhancement_level, is_equipped, obtained_at
                )
                VALUES (
                    v_buyer_id, 
                    v_order.item_id, 
                    v_transfer_qty, 
                    v_dest_slot, 
                    v_enhancement_level,
                    false,
                    EXTRACT(EPOCH FROM NOW())::bigint
                );
                
                v_remaining_qty := v_remaining_qty - v_transfer_qty;
            END IF;
        END LOOP;
        
    ELSE
        -- Non-Stackable Logic (Equipment)
        -- Must find separate slots for EACH item if p_quantity > 1 (unlikely for equip, but safe to handle)
        FOR i IN 1..p_quantity LOOP
             -- Find ONE empty slot
             v_dest_slot := NULL;
             SELECT MIN(slot_num) INTO v_dest_slot
             FROM generate_series(0, 19) slot_num
             WHERE NOT EXISTS (SELECT 1 FROM public.inventory WHERE user_id = v_buyer_id AND slot_position = slot_num);
             
             IF v_dest_slot IS NULL THEN
                 RAISE EXCEPTION 'Inventory full';
             END IF;
             
             INSERT INTO public.inventory (
                user_id, item_id, quantity, slot_position, 
                enhancement_level, is_equipped, obtained_at
            )
            VALUES (
                v_buyer_id, 
                v_order.item_id, 
                1, -- Always 1 for non-stackable
                v_dest_slot, 
                v_enhancement_level,
                false,
                EXTRACT(EPOCH FROM NOW())::bigint
            );
        END LOOP;
    END IF;
    
    -- 4. Update or Delete Order
    IF v_order.quantity = p_quantity THEN
        DELETE FROM public.market_orders WHERE id = p_order_id;
    ELSE
        UPDATE public.market_orders SET quantity = quantity - p_quantity WHERE id = p_order_id;
    END IF;
    
    -- 5. Track History
    INSERT INTO public.market_history (item_id, seller_id, buyer_id, price, quantity, sold_at)
    VALUES (v_order.item_id, v_seller_id, v_buyer_id, v_order.price, p_quantity, NOW());
    
    RETURN jsonb_build_object(
        'success', true, 
        'message', 'Item purchased',
        'new_buyer_gold', v_buyer_gold,
        'new_seller_gold', v_seller_gold
    );

EXCEPTION 
    WHEN OTHERS THEN
         IF SQLERRM = 'Inventory full' THEN
             RETURN jsonb_build_object('success', false, 'error', 'Inventory full');
         END IF;
         RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;
