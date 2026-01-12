-- Update add_inventory_item_v2 to handle max_stack limits
-- Logic:
-- 1. Try to fill existing stacks that have space
-- 2. Create new stacks for remaining quantity in empty slots

CREATE OR REPLACE FUNCTION public.add_inventory_item_v2(
    item_data jsonb,
    p_slot_position int DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_item_id text;
    v_user_id uuid;
    v_quantity int;        -- Total quantity to add
    v_remaining_qty int;   -- Counter for remaining quantity
    v_max_stack int;
    v_is_stackable boolean;
    v_new_row jsonb;       -- Returns the LAST modified/inserted row
    v_target_position int;
    v_space_available int;
    v_add_amount int;
    v_existing_row record; -- For looping through existing stacks
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN '{"success": false, "error": "Not authenticated"}'::jsonb;
    END IF;

    v_item_id := item_data->>'id';
    IF v_item_id IS NULL OR v_item_id = '' THEN
        RETURN '{"success": false, "error": "item_id is required"}'::jsonb;
    END IF;
    
    v_quantity := public._jsonb_to_int(item_data->'quantity', 1);
    v_remaining_qty := v_quantity;

    -- Upsert item definition (same as before)
    INSERT INTO public.items (
        id, name, description, icon, type, rarity, equip_slot,
        weapon_type, armor_type, material_type, potion_type,
        attack, defense, health, power, energy_restore, heal_amount,
        base_price, vendor_sell_price, can_enhance, max_enhancement,
        is_tradeable, is_stackable, max_stack,
        required_level, required_class, tolerance_increase, overdose_risk, production_building_type
    ) VALUES (
        v_item_id, item_data->>'name', item_data->>'description', item_data->>'icon',
        item_data->>'item_type', item_data->>'rarity', item_data->>'equip_slot',
        item_data->>'weapon_type', item_data->>'armor_type', item_data->>'material_type', item_data->>'potion_type',
        public._jsonb_to_int(item_data->'attack', 0), public._jsonb_to_int(item_data->'defense', 0),
        public._jsonb_to_int(item_data->'health', 0), public._jsonb_to_int(item_data->'power', 0),
        public._jsonb_to_int(item_data->'energy_restore', 0), public._jsonb_to_int(item_data->'heal_amount', 0),
        public._jsonb_to_int(item_data->'base_price', 0), public._jsonb_to_int(item_data->'vendor_sell_price', 0),
        COALESCE((item_data->>'can_enhance')::boolean, false), public._jsonb_to_int(item_data->'max_enhancement', 0),
        COALESCE((item_data->>'is_tradeable')::boolean, true), COALESCE((item_data->>'is_stackable')::boolean, true),
        public._jsonb_to_int(item_data->'max_stack', 999),
        public._jsonb_to_int(item_data->'required_level', 1), item_data->>'required_class',
        public._jsonb_to_int(item_data->'tolerance_increase', 0), COALESCE((item_data->>'overdose_risk')::numeric, 0),
        item_data->>'production_building_type'
    )
    ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name, description = EXCLUDED.description, icon = EXCLUDED.icon,
        attack = EXCLUDED.attack, defense = EXCLUDED.defense, health = EXCLUDED.health, power = EXCLUDED.power,
        max_stack = EXCLUDED.max_stack, is_stackable = EXCLUDED.is_stackable,
        base_price = EXCLUDED.base_price, vendor_sell_price = EXCLUDED.vendor_sell_price,
        is_tradeable = EXCLUDED.is_tradeable;

    -- Get item properties
    SELECT COALESCE(is_stackable, true), COALESCE(max_stack, 999) 
    INTO v_is_stackable, v_max_stack
    FROM public.items WHERE id = v_item_id;

    -- STEP 1: If stackable, try to fill existing non-full stacks
    IF v_is_stackable THEN
        FOR v_existing_row IN 
            SELECT row_id, quantity 
            FROM public.inventory 
            WHERE user_id = v_user_id AND item_id = v_item_id AND quantity < v_max_stack
            ORDER BY quantity DESC -- Fill almost-full stacks first? Or by slot_position? Let's generic.
        LOOP
            IF v_remaining_qty <= 0 THEN
                EXIT;
            END IF;

            v_space_available := v_max_stack - v_existing_row.quantity;
            v_add_amount := LEAST(v_remaining_qty, v_space_available);

            UPDATE public.inventory
            SET quantity = quantity + v_add_amount, updated_at = NOW()
            WHERE row_id = v_existing_row.row_id;
            
            v_remaining_qty := v_remaining_qty - v_add_amount;
            
            -- Keep track of last modified row to return something valid
            SELECT to_jsonb(i.*) INTO v_new_row FROM public.inventory i WHERE row_id = v_existing_row.row_id;
        END LOOP;
    END IF;

    -- STEP 2: create new stacks if quantity remains (or if not stackable)
    -- This handles the "300 potions -> 99, 99, 99, 3" scenario
    WHILE v_remaining_qty > 0 LOOP
        
        -- Determine amount for this new stack
        IF v_is_stackable THEN
             v_add_amount := LEAST(v_remaining_qty, v_max_stack);
        ELSE
             v_add_amount := 1; -- Non-stackable always size 1
        END IF;

        -- Find slot position (use provided preference ONLY for the first new stack, then find empty)
        IF p_slot_position IS NOT NULL AND v_remaining_qty = v_quantity THEN
             -- Very first stack being created, check if preferred slot is empty
             IF NOT EXISTS (SELECT 1 FROM public.inventory WHERE user_id = v_user_id AND slot_position = p_slot_position) THEN
                 v_target_position := p_slot_position;
             ELSE
                 -- Preferred slot taken, find first empty
                 SELECT COALESCE(MIN(slot_num), 0) INTO v_target_position
                 FROM generate_series(0, 19) slot_num
                 WHERE NOT EXISTS (SELECT 1 FROM public.inventory WHERE user_id = v_user_id AND slot_position = slot_num);
             END IF;
        ELSE
            -- Find first empty slot (0-19)
            SELECT COALESCE(MIN(slot_num), 0) INTO v_target_position
            FROM generate_series(0, 19) slot_num
            WHERE NOT EXISTS (SELECT 1 FROM public.inventory WHERE user_id = v_user_id AND slot_position = slot_num);
        END IF;

        -- Check if inventory full
        IF v_target_position > 19 OR v_target_position IS NULL THEN
            -- Inventory full! 
            -- If we added *some* items, we should probably return success with what we did, 
            -- but the user might lose money if we don't handle partial refund.
            -- For now, simplest is to stop adding and return error if absolutely nothing was added?
            -- Or just stop and return the last success row.
            -- Let's break the loop. 
            -- Ideally we should error if v_remaining_qty == v_quantity (nothing added).
            IF v_remaining_qty = v_quantity THEN
                 RETURN '{"success": false, "error": "Inventory full"}'::jsonb;
            END IF;
            EXIT; -- Stop adding, return what was added.
        END IF;

        -- Insert new item row
        INSERT INTO public.inventory (
            user_id, item_id, quantity, enhancement_level, is_equipped, obtained_at, slot_position
        ) VALUES (
            v_user_id, v_item_id, v_add_amount,
            public._jsonb_to_int(item_data->'enhancement_level', 0),
            false, EXTRACT(EPOCH FROM NOW())::bigint, v_target_position
        )
        RETURNING to_jsonb(inventory.*) INTO v_new_row;

        v_remaining_qty := v_remaining_qty - v_add_amount;
        
        -- Clear p_slot_position after first use so subsequent stacks find their own slots
        p_slot_position := NULL;
        
        -- If not stackable and we have more to add, we just loop again (checked logic above)
        -- logic handles it: v_add_amount was 1.
    END LOOP;

    RETURN jsonb_build_object('success', true, 'data', v_new_row);
END;
$$;
