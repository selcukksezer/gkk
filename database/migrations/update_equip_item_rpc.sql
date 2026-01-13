-- RPC: Equip Item (Update)
-- Ensures that when an item is equipped, its slot_position is explicitly set to NULL.

CREATE OR REPLACE FUNCTION public.equip_item(
    item_instance_id UUID,
    target_slot TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_item RECORD;
BEGIN
    -- Get authenticated user
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RETURN '{"success": false, "error": "Not authenticated"}'::jsonb;
    END IF;

    -- Get the Item
    SELECT * INTO v_item
    FROM public.inventory
    WHERE row_id = item_instance_id AND user_id = v_user_id;

    IF v_item IS NULL THEN
        RETURN '{"success": false, "error": "Item not found"}'::jsonb;
    END IF;

    -- Update the item
    UPDATE public.inventory
    SET is_equipped = TRUE,
        equip_slot = target_slot,
        slot_position = NULL, -- CRITICAL: Remove from grid
        updated_at = NOW()
    WHERE row_id = item_instance_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'action', 'equip',
        'item_id', item_instance_id,
        'slot', target_slot
    );

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;
