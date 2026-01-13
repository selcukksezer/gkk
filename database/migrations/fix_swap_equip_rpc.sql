-- RPC: Swap Equip Item (FIXED)
-- Atomically swaps an item using direct UPDATEs to avoid unique constraint violations.

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
    v_rows_updated INT;
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

    -- 2. CLEAR THE SLOT (Blind Update)
    -- Move any item currently in this slot to the new item's grid position.
    -- This handles specific case matching issues by matching case-insensitively or just relying on "is_equipped=TRUE"
    -- We'll use standard equality for now, assuming the inputs are consistent.
    
    UPDATE public.inventory
    SET is_equipped = FALSE,
        equip_slot = NULL,
        slot_position = v_new_item.slot_position, -- Valid swap pos
        updated_at = NOW()
    WHERE user_id = v_user_id 
      AND is_equipped = TRUE 
      AND equip_slot = p_target_equip_slot;
      
    GET DIAGNOSTICS v_rows_updated = ROW_COUNT;

    -- 3. EQUIP THE NEW ITEM
    UPDATE public.inventory
    SET is_equipped = TRUE,
        equip_slot = p_target_equip_slot,
        slot_position = NULL,
        updated_at = NOW()
    WHERE row_id = v_new_item.row_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'action', CASE WHEN v_rows_updated > 0 THEN 'swap' ELSE 'equip' END,
        'equipped_item', v_new_item.row_id,
        'previous_item_displaced', (v_rows_updated > 0)
    );

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;
