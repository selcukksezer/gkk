-- Add slot_position support to existing RPC functions
-- Run this after add_slot_position.sql migration

-- 1. Update get_inventory() to include slot_position and order by it
CREATE OR REPLACE FUNCTION public.get_inventory()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id uuid;
    v_inventory jsonb;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN '{"success": false, "error": "Not authenticated"}'::jsonb;
    END IF;

    -- Fetch inventory with slot_position, ordered by position
    SELECT jsonb_agg(
        jsonb_build_object(
            'row_id', inv.row_id,
            'id', inv.item_id,
            'item_id', inv.item_id,
            'quantity', inv.quantity,
            'enhancement_level', COALESCE(inv.enhancement_level, 0),
            'is_equipped', COALESCE(inv.is_equipped, false),
            'equip_slot', inv.equip_slot,
            'obtained_at', inv.obtained_at,
            'is_favorite', COALESCE(inv.is_favorite, false),
            'slot_position', inv.slot_position,  -- NEW
            -- Item definition data
            'name', it.name,
            'description', it.description,
            'icon', it.icon,
            'item_type', it.type,
            'rarity', it.rarity,
            'weapon_type', it.weapon_type,
            'armor_type', it.armor_type,
            'material_type', it.material_type,
            'potion_type', it.potion_type,
            'attack', it.attack,
            'defense', it.defense,
            'health', it.health,
            'power', it.power,
            'energy_restore', it.energy_restore,
            'heal_amount', it.heal_amount,
            'base_price', it.base_price,
            'vendor_sell_price', it.vendor_sell_price,
            'can_enhance', it.can_enhance,
            'max_enhancement', it.max_enhancement,
            'is_tradeable', it.is_tradeable,
            'is_stackable', it.is_stackable,
            'max_stack', it.max_stack,
            'required_level', COALESCE(it.required_level, 1),
            'required_class', it.required_class,
            'tolerance_increase', COALESCE(it.tolerance_increase, 0),
            'overdose_risk', COALESCE(it.overdose_risk, 0),
            'production_building_type', it.production_building_type
        )
        ORDER BY COALESCE(inv.slot_position, 999), inv.obtained_at  -- Sort by position, unassigned last
    )
    INTO v_inventory
    FROM public.inventory inv
    LEFT JOIN public.items it ON inv.item_id = it.id
    WHERE inv.user_id = v_user_id;

    IF v_inventory IS NULL THEN
        v_inventory := '[]'::jsonb;
    END IF;

    RETURN jsonb_build_object('success', true, 'items', v_inventory);
END;
$$;

-- 2. Create RPC to update item positions (for drag-and-drop slot swapping)
CREATE OR REPLACE FUNCTION public.update_item_positions(p_updates jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id uuid;
    v_update jsonb;
    v_row_id uuid;
    v_new_position int;
    v_count int := 0;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    -- p_updates is array like: [{"row_id": "uuid", "slot_position": 5}, ...]
    FOR v_update IN SELECT * FROM jsonb_array_elements(p_updates)
    LOOP
        v_row_id := (v_update->>'row_id')::uuid;
        v_new_position := (v_update->>'slot_position')::int;
        
        -- Validate position (0-19)
        IF v_new_position < 0 OR v_new_position > 19 THEN
            RETURN jsonb_build_object(
                'success', false, 
                'error', format('Invalid slot_position: %s (must be 0-19)', v_new_position)
            );
        END IF;
        
        -- Update position
        UPDATE public.inventory
        SET slot_position = v_new_position,
            updated_at = NOW()
        WHERE row_id = v_row_id
          AND user_id = v_user_id;
        
        v_count := v_count + 1;
    END LOOP;

    RETURN jsonb_build_object(
        'success', true, 
        'updated_count', v_count
    );
END;
$$;

-- 3. Update add_inventory_item to support slot_position
-- Add slot_position parameter (optional - finds first empty slot if null)
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
    v_new_row jsonb;
    v_is_stackable boolean;
    v_target_position int;
    v_existing_row record;
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
        attack = EXCLUDED.attack, defense = EXCLUDED.defense, health = EXCLUDED.health, power = EXCLUDED.power;

    -- Check if stackable
    SELECT COALESCE(is_stackable, true) INTO v_is_stackable
    FROM public.items WHERE id = v_item_id;

    -- Check for existing item
    SELECT * INTO v_existing_row FROM public.inventory 
    WHERE user_id = v_user_id AND item_id = v_item_id
    LIMIT 1;

    -- If stackable and exists
    IF v_is_stackable AND v_existing_row IS NOT NULL THEN
        -- Check if it has a valid slot
        IF v_existing_row.slot_position IS NULL OR v_existing_row.slot_position < 0 THEN
             -- FIND A SLOT because the existing one is broken/hidden
            SELECT MIN(slot_num) INTO v_target_position
            FROM generate_series(0, 19) slot_num
            WHERE NOT EXISTS (
                SELECT 1 FROM public.inventory 
                WHERE user_id = v_user_id AND slot_position = slot_num
            );
            
            -- If full, we still have to handle it. 
            -- But upgrading an existing NULL item is better than nothing.
            -- If v_target_position is NULL (full), we leave it as NULL (or maybe 0?)
            -- Let's stick to NULL if full, but ideally we assign a slot.
            
            UPDATE public.inventory
            SET quantity = quantity + v_quantity, 
                slot_position = COALESCE(v_target_position, slot_position), -- Update slot if we found one
                updated_at = NOW()
            WHERE row_id = v_existing_row.row_id
            RETURNING to_jsonb(inventory.*) INTO v_new_row;
            
        ELSE
            -- Normal update
            UPDATE public.inventory
            SET quantity = quantity + v_quantity, updated_at = NOW()
            WHERE row_id = v_existing_row.row_id
            RETURNING to_jsonb(inventory.*) INTO v_new_row;
        END IF;

    ELSE
        -- Find slot position (use provided or find first empty)
        IF p_slot_position IS NOT NULL THEN
            v_target_position := p_slot_position;
        ELSE
            -- Find first empty slot (0-19)
            SELECT MIN(slot_num) INTO v_target_position
            FROM generate_series(0, 19) slot_num
            WHERE NOT EXISTS (
                SELECT 1 FROM public.inventory 
                WHERE user_id = v_user_id AND slot_position = slot_num
            );
        END IF;
        
        -- If inventory is full (v_target_position IS NULL)
        IF v_target_position IS NULL THEN
             RETURN '{"success": false, "error": "Inventory is full"}'::jsonb;
        END IF;

        -- Insert new item
        INSERT INTO public.inventory (
            user_id, item_id, quantity, enhancement_level, is_equipped, obtained_at, slot_position
        ) VALUES (
            v_user_id, v_item_id, v_quantity,
            public._jsonb_to_int(item_data->'enhancement_level', 0),
            false, EXTRACT(EPOCH FROM NOW())::bigint, v_target_position
        )
        RETURNING to_jsonb(inventory.*) INTO v_new_row;
    END IF;

    RETURN jsonb_build_object('success', true, 'data', v_new_row);
END;
$$;
