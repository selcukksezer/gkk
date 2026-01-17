-- Fix Shop Stacking Logic & Data

-- 1. Redefine add_inventory_item_v2 with robust stacking logic
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
    v_quantity int;        
    v_remaining_qty int;   
    v_max_stack int;
    v_is_stackable boolean;
    v_new_row jsonb;       
    v_target_position int;
    v_space_available int;
    v_add_amount int;
    v_existing_row record; 
    v_item_type text;
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

    -- Extract Key Props for fallback
    v_item_type := item_data->>'item_type';

    -- 2. Smart UPSERT item definition
    -- Ensure we don't accidentally set max_stack to 0 or is_stackable to false for known stackables
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
        GREATEST(public._jsonb_to_int(item_data->'max_stack', 50), 1), -- Force at least 1, default 50
        public._jsonb_to_int(item_data->'required_level', 1), item_data->>'required_class',
        public._jsonb_to_int(item_data->'tolerance_increase', 0), COALESCE((item_data->>'overdose_risk')::numeric, 0),
        item_data->>'production_building_type'
    )
    ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name, description = EXCLUDED.description, icon = EXCLUDED.icon,
        max_stack = GREATEST(EXCLUDED.max_stack, 1), is_stackable = EXCLUDED.is_stackable;

    -- 3. Fetch canonical properties from DB
    SELECT is_stackable, max_stack 
    INTO v_is_stackable, v_max_stack
    FROM public.items WHERE id = v_item_id;
    
    -- Safety override: If DB says false but it's clearly a material/potion, force true
    IF v_item_type IN ('MATERIAL', 'POTION', 'SCROLL', 'CONSUMABLE') THEN
         v_is_stackable := TRUE;
         IF v_max_stack < 2 THEN v_max_stack := 50; END IF;
    END IF;

    -- STEP 1: Fill Existing Stacks
    IF v_is_stackable THEN
        -- Loop through all partial stacks
        FOR v_existing_row IN 
            SELECT row_id, quantity, slot_position
            FROM public.inventory 
            WHERE user_id = v_user_id 
              AND item_id = v_item_id 
              AND quantity < v_max_stack
            ORDER BY quantity DESC 
        LOOP
            IF v_remaining_qty <= 0 THEN EXIT; END IF;

            v_space_available := v_max_stack - v_existing_row.quantity;
            v_add_amount := LEAST(v_remaining_qty, v_space_available);

            UPDATE public.inventory
            SET quantity = quantity + v_add_amount, updated_at = NOW()
            WHERE row_id = v_existing_row.row_id;
            
            v_remaining_qty := v_remaining_qty - v_add_amount;
            
            -- Capture result for simple single-stack case
            SELECT to_jsonb(i.*) INTO v_new_row FROM public.inventory i WHERE row_id = v_existing_row.row_id;
        END LOOP;
    END IF;

    -- STEP 2: Create New Stacks
    WHILE v_remaining_qty > 0 LOOP
        
        IF v_is_stackable THEN
             v_add_amount := LEAST(v_remaining_qty, v_max_stack);
        ELSE
             v_add_amount := 1;
        END IF;

        -- Find Slot
        IF p_slot_position IS NOT NULL AND v_remaining_qty = v_quantity THEN
             IF NOT EXISTS (SELECT 1 FROM public.inventory WHERE user_id = v_user_id AND slot_position = p_slot_position) THEN
                 v_target_position := p_slot_position;
             ELSE
                 SELECT COALESCE(MIN(slot_num), 0) INTO v_target_position
                 FROM generate_series(0, 19) slot_num
                 WHERE NOT EXISTS (SELECT 1 FROM public.inventory WHERE user_id = v_user_id AND slot_position = slot_num);
             END IF;
        ELSE
            SELECT COALESCE(MIN(slot_num), 0) INTO v_target_position
            FROM generate_series(0, 19) slot_num
            WHERE NOT EXISTS (SELECT 1 FROM public.inventory WHERE user_id = v_user_id AND slot_position = slot_num);
        END IF;

        IF v_target_position > 19 OR v_target_position IS NULL THEN
            IF v_remaining_qty = v_quantity THEN
                 RETURN '{"success": false, "error": "Inventory full"}'::jsonb;
            END IF;
            EXIT; 
        END IF;

        INSERT INTO public.inventory (
            user_id, item_id, quantity, enhancement_level, is_equipped, obtained_at, slot_position
        ) VALUES (
            v_user_id, v_item_id, v_add_amount,
            public._jsonb_to_int(item_data->'enhancement_level', 0),
            false, EXTRACT(EPOCH FROM NOW())::bigint, v_target_position
        )
        RETURNING to_jsonb(inventory.*) INTO v_new_row;

        v_remaining_qty := v_remaining_qty - v_add_amount;
        p_slot_position := NULL;
    END LOOP;

    RETURN jsonb_build_object('success', true, 'data', v_new_row);
END;
$$;

-- 2. FORCE DATA CORRECTION
-- Ensure all potentially stackable items are correctly marked
UPDATE public.items
SET is_stackable = TRUE, max_stack = 50
WHERE type IN ('MATERIAL', 'POTION', 'SCROLL', 'CONSUMABLE', 'RUNE')
OR name LIKE '%Potion%' OR name LIKE '%Scroll%';
