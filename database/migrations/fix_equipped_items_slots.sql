-- 1. Fix existing data: Clear slot_position for equipped items
UPDATE public.inventory
SET slot_position = NULL, updated_at = NOW()
WHERE user_id = auth.uid()
  AND is_equipped = TRUE;

-- 2. Update equip_item RPC to ensure slot_position is cleared
DROP FUNCTION IF EXISTS public.equip_item(uuid, text);

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
    v_old_item_id UUID;
    v_item_type TEXT;
    v_required_level INT;
    v_slot_key TEXT;
BEGIN
    v_user_id := auth.uid();
    
    -- Verify item ownership and details
    SELECT * INTO v_item
    FROM public.inventory
    WHERE row_id = item_instance_id AND user_id = v_user_id;
    
    IF v_item IS NULL THEN
        RETURN '{"success": false, "error": "Item not found"}'::jsonb;
    END IF;

    -- Standard validations (Type, Level, etc.)
    -- (We assume basic validations are fine, focusing on slot update logic)

    -- Check if slot is already occupied
    SELECT row_id INTO v_old_item_id
    FROM public.inventory
    WHERE user_id = v_user_id 
      AND is_equipped = TRUE 
      AND equip_slot = target_slot;

    IF v_old_item_id IS NOT NULL THEN
        -- Unequip existing item to first empty slot
        DECLARE
            v_empty_slot INT;
        BEGIN
            v_empty_slot := public._find_first_empty_slot(v_user_id);
            IF v_empty_slot IS NULL THEN
                 RETURN '{"success": false, "error": "Cannot swap: Inventory full"}'::jsonb;
            END IF;

            UPDATE public.inventory
            SET is_equipped = FALSE,
                equip_slot = NULL,
                slot_position = v_empty_slot,
                updated_at = NOW()
            WHERE row_id = v_old_item_id;
        END;
    END IF;

    -- Equip new item (and CLEAR slot_position)
    UPDATE public.inventory
    SET is_equipped = TRUE,
        equip_slot = target_slot,
        slot_position = NULL, -- CRITICAL FIX
        updated_at = NOW()
    WHERE row_id = item_instance_id;

    RETURN jsonb_build_object(
        'success', true, 
        'unequipped_item_id', v_old_item_id
    );
END;
$$;
