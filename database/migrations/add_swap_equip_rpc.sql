-- RPC: Swap Equip Item
-- Atomically swaps an item from inventory with an item currently equipped in a specific slot.
-- This prevents "Inventory Full" errors effectively because the unequipped item takes the exact place of the equipped item.

CREATE OR REPLACE FUNCTION public.swap_equip_item(
    p_item_instance_id UUID,
    p_target_equip_slot TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_new_item RECORD;
    v_old_item RECORD;
BEGIN
    -- Get authenticated user
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RETURN '{"success": false, "error": "Not authenticated"}'::jsonb;
    END IF;

    -- 1. Get the New Item (Inventory Item)
    SELECT * INTO v_new_item
    FROM public.inventory
    WHERE row_id = p_item_instance_id AND user_id = v_user_id;

    IF v_new_item IS NULL THEN
        RETURN '{"success": false, "error": "Item not found"}'::jsonb;
    END IF;

    IF v_new_item.is_equipped THEN
        RETURN '{"success": false, "error": "Item is already equipped"}'::jsonb;
    END IF;

    -- 2. Get the Old Item (Currently Equipped in the target slot)
    SELECT * INTO v_old_item
    FROM public.inventory
    WHERE user_id = v_user_id 
      AND is_equipped = TRUE 
      AND equip_slot = p_target_equip_slot;

    -- 3. Perform Swap
    IF v_old_item IS NOT NULL THEN
        -- Case: Swap
        -- Move Old Item to New Item's grid position
        UPDATE public.inventory
        SET is_equipped = FALSE,
            equip_slot = NULL,
            slot_position = v_new_item.slot_position,
            updated_at = NOW()
        WHERE row_id = v_old_item.row_id;
        
        -- Move New Item to Equipment Slot
        UPDATE public.inventory
        SET is_equipped = TRUE,
            equip_slot = p_target_equip_slot,
            slot_position = NULL, -- Clear grid position
            updated_at = NOW()
        WHERE row_id = v_new_item.row_id;
        
        RETURN jsonb_build_object(
            'success', true,
            'action', 'swap',
            'equipped_item', v_new_item.row_id,
            'unequipped_item', v_old_item.row_id,
            'swapped_slot_pos', v_new_item.slot_position
        );
    ELSE
        -- Case: Equip to Empty Slot (Fallback)
        -- Just equip the new item
        UPDATE public.inventory
        SET is_equipped = TRUE,
            equip_slot = p_target_equip_slot,
            slot_position = NULL,
            updated_at = NOW()
        WHERE row_id = v_new_item.row_id;
        
        RETURN jsonb_build_object(
            'success', true,
            'action', 'equip',
            'equipped_item', v_new_item.row_id
        );
    END IF;

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;
