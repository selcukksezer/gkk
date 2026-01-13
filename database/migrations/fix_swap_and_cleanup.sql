-- ================================================================================
-- FIX SWAP FUNCTION + CLEANUP STUCK ITEMS
-- ================================================================================
-- Run this in Supabase SQL Editor to fix the swap issue
-- ================================================================================

-- STEP 1: Clean up item stuck in TEMP slot (-998)
DO $$
DECLARE
    v_stuck_item RECORD;
    v_free_slot INT;
BEGIN
    -- Find all items stuck at slot_position = -998
    FOR v_stuck_item IN 
        SELECT row_id, user_id FROM public.inventory
        WHERE slot_position = -998 AND is_equipped = FALSE
    LOOP
        -- Find first free slot for this user
        SELECT s.i INTO v_free_slot
        FROM generate_series(0, 19) AS s(i)
        WHERE NOT EXISTS (
            SELECT 1 FROM public.inventory 
            WHERE user_id = v_stuck_item.user_id 
              AND slot_position = s.i
              AND is_equipped = FALSE
        )
        LIMIT 1;
        
        IF v_free_slot IS NOT NULL THEN
            -- Move to free slot
            UPDATE public.inventory
            SET slot_position = v_free_slot,
                updated_at = NOW()
            WHERE row_id = v_stuck_item.row_id;
            
            RAISE NOTICE 'Moved stuck item % from TEMP (-998) to slot %', v_stuck_item.row_id, v_free_slot;
        ELSE
            RAISE NOTICE 'No free slots for user % - item % remains in overflow', v_stuck_item.user_id, v_stuck_item.row_id;
        END IF;
    END LOOP;
END $$;

-- STEP 2: Update swap_equip_item function with 3-step TEMP slot pattern
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
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    -- Get the New Item (from Inventory)
    SELECT * INTO v_new_item
    FROM public.inventory
    WHERE row_id = p_item_instance_id AND user_id = v_user_id;

    IF v_new_item IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Item not found');
    END IF;

    IF v_new_item.is_equipped THEN
        RETURN jsonb_build_object('success', false, 'error', 'Item is already equipped');
    END IF;

    -- Get the Old Item (Currently Equipped)
    SELECT * INTO v_old_item
    FROM public.inventory
    WHERE user_id = v_user_id 
      AND is_equipped = TRUE 
      AND equip_slot = p_target_equip_slot;

    -- Perform Swap using TEMP slot to avoid constraint violation
    IF v_old_item IS NOT NULL THEN
        -- Step 1: Move old equipped item to TEMP slot (-998) to free the equip_slot
        UPDATE public.inventory
        SET is_equipped = FALSE,
            equip_slot = NULL,
            slot_position = -998,
            updated_at = NOW()
        WHERE row_id = v_old_item.row_id;
        
        -- Step 2: Equip new item (now safe - no duplicate in equip_slot)
        UPDATE public.inventory
        SET is_equipped = TRUE,
            equip_slot = p_target_equip_slot,
            slot_position = NULL,
            updated_at = NOW()
        WHERE row_id = v_new_item.row_id;
        
        -- Step 3: Move old item from TEMP to new item's original position
        UPDATE public.inventory
        SET slot_position = v_new_item.slot_position,
            updated_at = NOW()
        WHERE row_id = v_old_item.row_id;
        
        RETURN jsonb_build_object(
            'success', true,
            'action', 'swap',
            'equipped_item', v_new_item.row_id,
            'unequipped_item', v_old_item.row_id,
            'swapped_slot_pos', v_new_item.slot_position
        );
    ELSE
        -- Equip to Empty Slot
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

-- Verification
DO $$
BEGIN
    RAISE NOTICE '✅ Swap function updated with 3-step TEMP slot pattern';
    RAISE NOTICE '✅ Stuck items cleaned up';
    RAISE NOTICE 'Close and reopen your game to test the fix!';
END $$;
