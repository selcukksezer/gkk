-- Helper function to find first empty slot
CREATE OR REPLACE FUNCTION public._find_first_empty_slot(p_user_id uuid)
RETURNS int
LANGUAGE plpgsql
AS $$
DECLARE
    v_slot int;
BEGIN
    SELECT MIN(slot_num) INTO v_slot
    FROM generate_series(0, 19) slot_num
    WHERE NOT EXISTS (
        SELECT 1 FROM public.inventory 
        WHERE user_id = p_user_id AND slot_position = slot_num
    );
    RETURN v_slot;
END;
$$;

-- Enhanced Unequip Item RPC
DROP FUNCTION IF EXISTS public.unequip_item(UUID);
DROP FUNCTION IF EXISTS public.unequip_item(UUID, INT);

CREATE OR REPLACE FUNCTION public.unequip_item(
    item_instance_id UUID,
    target_slot_position INT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_updated_count INT;
    v_occupying_item_id UUID;
    v_free_slot INT;
BEGIN
    -- Get authenticated user
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RETURN '{"success": false, "error": "Not authenticated"}'::jsonb;
    END IF;

    -- If target slot is provided, validate it
    IF target_slot_position IS NOT NULL THEN
        IF target_slot_position < 0 OR target_slot_position > 19 THEN
             RETURN '{"success": false, "error": "Invalid target slot position"}'::jsonb;
        END IF;

        -- Check if target slot is occupied by ANOTHER item (not the one we are unequipping, obviously)
        SELECT row_id INTO v_occupying_item_id
        FROM public.inventory
        WHERE user_id = v_user_id 
          AND slot_position = target_slot_position
          AND row_id != item_instance_id
        LIMIT 1;

        -- If occupied, move the occupant to a free slot
        IF v_occupying_item_id IS NOT NULL THEN
            v_free_slot := public._find_first_empty_slot(v_user_id);
            
            IF v_free_slot IS NULL THEN
                 RETURN '{"success": false, "error": "Inventory full, cannot displace item"}'::jsonb;
            END IF;

            UPDATE public.inventory
            SET slot_position = v_free_slot, updated_at = NOW()
            WHERE row_id = v_occupying_item_id;
        END IF;
    ELSE
        -- No target slot provided, find one
        target_slot_position := public._find_first_empty_slot(v_user_id);
        
        IF target_slot_position IS NULL THEN
             RETURN '{"success": false, "error": "Inventory full"}'::jsonb;
        END IF;
    END IF;
    
    -- Unequip item and set to target slot
    UPDATE public.inventory
    SET is_equipped = FALSE, 
        equip_slot = NULL, 
        slot_position = target_slot_position,
        updated_at = NOW()
    WHERE row_id = item_instance_id 
      AND user_id = v_user_id
      AND is_equipped = TRUE;
    
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    
    IF v_updated_count = 0 THEN
        RETURN '{"success": false, "error": "Item not found, not owned, or not equipped"}'::jsonb;
    END IF;
    
    RETURN jsonb_build_object(
        'success', true,
        'item_id', item_instance_id,
        'new_slot_position', target_slot_position
    );
END;
$$;
