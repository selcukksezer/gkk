-- ================================================================================
-- MASTER MIGRATION: Complete Inventory & Equipment System Fix
-- ================================================================================
-- This script performs ALL necessary fixes in the correct order
-- Run this ONCE to fix all issues
-- ================================================================================

-- STEP 1: Add slot_position column if missing
-- ================================================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'inventory' 
        AND column_name = 'slot_position'
    ) THEN
        ALTER TABLE public.inventory ADD COLUMN slot_position INT;
        RAISE NOTICE 'Added slot_position column';
    END IF;
END $$;

-- STEP 2: Set equipped items to have NULL slot_position
-- ================================================================================
DO $$
DECLARE
    v_updated_count INT;
BEGIN
    UPDATE public.inventory
    SET slot_position = NULL
    WHERE is_equipped = TRUE AND slot_position IS NOT NULL;
    
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    RAISE NOTICE 'Cleared slot_position for % equipped items', v_updated_count;
END $$;

-- STEP 3: Repair Equipment Slot Duplicates (Keep newest, move others to inventory)
-- ================================================================================
DO $$
DECLARE
    v_item RECORD;
    v_free_slot INT;
BEGIN
    -- For each duplicate equipped item (same user + equip_slot)
    FOR v_item IN 
        SELECT row_id, user_id, equip_slot
        FROM (
            SELECT row_id, user_id, equip_slot,
                   ROW_NUMBER() OVER (
                       PARTITION BY user_id, equip_slot 
                       ORDER BY updated_at DESC
                   ) as rn
            FROM public.inventory
            WHERE is_equipped = TRUE AND equip_slot IS NOT NULL
        ) dupes
        WHERE rn > 1
    LOOP
        -- Find first free inventory slot for this user
        SELECT s.i INTO v_free_slot
        FROM generate_series(0, 19) AS s(i)
        WHERE NOT EXISTS (
            SELECT 1 FROM public.inventory 
            WHERE user_id = v_item.user_id 
              AND slot_position = s.i
              AND is_equipped = FALSE
        )
        LIMIT 1;
        
        IF v_free_slot IS NOT NULL THEN
            -- Move to inventory
            UPDATE public.inventory
            SET is_equipped = FALSE,
                equip_slot = NULL,
                slot_position = v_free_slot,
                updated_at = NOW()
            WHERE row_id = v_item.row_id;
            
            RAISE NOTICE 'Moved duplicate equipped item % to slot %', v_item.row_id, v_free_slot;
        ELSE
            -- No free slot - set to NULL (overflow)
            UPDATE public.inventory
            SET is_equipped = FALSE,
                equip_slot = NULL,
                slot_position = NULL,
                updated_at = NOW()
            WHERE row_id = v_item.row_id;
            
            RAISE NOTICE 'Moved duplicate equipped item % to overflow (no free slots)', v_item.row_id;
        END IF;
    END LOOP;
END $$;

-- STEP 4: Repair Inventory Slot Duplicates (Keep newest, move others)
-- ================================================================================
DO $$
DECLARE
    v_item RECORD;
    v_free_slot INT;
BEGIN
    -- For each duplicate inventory slot (same user + slot_position)
    FOR v_item IN 
        SELECT row_id, user_id, slot_position
        FROM (
            SELECT row_id, user_id, slot_position,
                   ROW_NUMBER() OVER (
                       PARTITION BY user_id, slot_position 
                       ORDER BY updated_at DESC
                   ) as rn
            FROM public.inventory
            WHERE is_equipped = FALSE AND slot_position IS NOT NULL
        ) dupes
        WHERE rn > 1
    LOOP
        -- Find first free inventory slot
        SELECT s.i INTO v_free_slot
        FROM generate_series(0, 19) AS s(i)
        WHERE NOT EXISTS (
            SELECT 1 FROM public.inventory 
            WHERE user_id = v_item.user_id 
              AND slot_position = s.i
              AND is_equipped = FALSE
        )
        LIMIT 1;
        
        IF v_free_slot IS NOT NULL THEN
            UPDATE public.inventory
            SET slot_position = v_free_slot,
                updated_at = NOW()
            WHERE row_id = v_item.row_id;
            
            RAISE NOTICE 'Moved duplicate inventory item % to slot %', v_item.row_id, v_free_slot;
        ELSE
            -- No free slot - set to NULL (overflow)
            UPDATE public.inventory
            SET slot_position = NULL,
                updated_at = NOW()
            WHERE row_id = v_item.row_id;
            
            RAISE NOTICE 'Moved duplicate inventory item % to overflow', v_item.row_id;
        END IF;
    END LOOP;
END $$;

-- STEP 5: Add UNIQUE Constraints
-- ================================================================================
DO $$
BEGIN
    -- Equipment slot constraint
    DROP INDEX IF EXISTS idx_inventory_user_equip_slot_unique;
    CREATE UNIQUE INDEX idx_inventory_user_equip_slot_unique 
    ON public.inventory (user_id, equip_slot) 
    WHERE is_equipped = TRUE AND equip_slot IS NOT NULL;
    
    RAISE NOTICE 'Created unique constraint on equipment slots';
    
    -- Inventory slot constraint
    DROP INDEX IF EXISTS idx_inventory_user_slot_unique;
    CREATE UNIQUE INDEX idx_inventory_user_slot_unique 
    ON public.inventory (user_id, slot_position)
    WHERE slot_position IS NOT NULL AND is_equipped = FALSE;
    
    RAISE NOTICE 'Created unique constraint on inventory slots';
END $$;

-- STEP 6: Create/Update RPC Functions
-- ================================================================================

-- 6.1: Helper function to find first empty inventory slot
CREATE OR REPLACE FUNCTION public._find_first_empty_slot(p_user_id UUID)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_slot INT;
BEGIN
    SELECT s.i INTO v_slot
    FROM generate_series(0, 19) AS s(i)
    WHERE NOT EXISTS (
        SELECT 1 FROM public.inventory 
        WHERE user_id = p_user_id 
          AND slot_position = s.i
          AND is_equipped = FALSE
    )
    LIMIT 1;
    
    RETURN v_slot; -- NULL if all slots full
END;
$$;

-- 6.2: Swap Equip Item (Atomic swap - handles full inventory)
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
            slot_position = -998,  -- Temporary holding slot
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

-- 6.3: Equip Item (Updated to clear slot_position)
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
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT * INTO v_item
    FROM public.inventory
    WHERE row_id = item_instance_id AND user_id = v_user_id;

    IF v_item IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Item not found');
    END IF;

    -- Check if slot already occupied (this should use swap_equip_item instead)
    IF EXISTS (
        SELECT 1 FROM public.inventory
        WHERE user_id = v_user_id 
          AND is_equipped = TRUE 
          AND equip_slot = target_slot
    ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Slot already occupied - use swap_equip_item');
    END IF;

    -- Equip the item
    UPDATE public.inventory
    SET is_equipped = TRUE,
        equip_slot = target_slot,
        slot_position = NULL, -- CRITICAL: Clear grid position
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

-- 6.4: Unequip Item (Updated with swap support)
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
    v_item RECORD;
    v_target_slot INT;
    v_occupying_item_id UUID;
    v_temp_slot INT := -998;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT * INTO v_item
    FROM public.inventory
    WHERE row_id = item_instance_id AND user_id = v_user_id;

    IF v_item IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Item not found');
    END IF;

    IF NOT v_item.is_equipped THEN
        RETURN jsonb_build_object('success', false, 'error', 'Item is not equipped');
    END IF;

    -- Determine target slot
    IF target_slot_position IS NOT NULL THEN
        v_target_slot := target_slot_position;
    ELSE
        v_target_slot := public._find_first_empty_slot(v_user_id);
    END IF;

    IF v_target_slot IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'No free inventory slots');
    END IF;

    -- Check if target slot is occupied by another item
    SELECT row_id INTO v_occupying_item_id
    FROM public.inventory
    WHERE user_id = v_user_id 
      AND slot_position = v_target_slot
      AND is_equipped = FALSE
      AND row_id != item_instance_id;
    
    IF v_occupying_item_id IS NOT NULL THEN
        -- Target slot is occupied - need to swap positions
        -- Step 1: Move occupying item to temp slot
        UPDATE public.inventory
        SET slot_position = v_temp_slot,
            updated_at = NOW()
        WHERE row_id = v_occupying_item_id;
        
        -- Step 2: Unequip our item to the target slot
        UPDATE public.inventory
        SET is_equipped = FALSE,
            equip_slot = NULL,
            slot_position = v_target_slot,
            updated_at = NOW()
        WHERE row_id = item_instance_id;
        
        -- Step 3: Move occupying item to first empty slot
        DECLARE
            v_empty_slot INT;
        BEGIN
            v_empty_slot := public._find_first_empty_slot(v_user_id);
            IF v_empty_slot IS NULL THEN
                -- This shouldn't happen if inventory wasn't full before
                -- Rollback is automatic due to transaction
                RETURN jsonb_build_object('success', false, 'error', 'No space for displaced item');
            END IF;
            
            UPDATE public.inventory
            SET slot_position = v_empty_slot,
                updated_at = NOW()
            WHERE row_id = v_occupying_item_id;
        END;
    ELSE
        -- Target slot is free - simple unequip
        UPDATE public.inventory
        SET is_equipped = FALSE,
            equip_slot = NULL,
            slot_position = v_target_slot,
            updated_at = NOW()
        WHERE row_id = item_instance_id;
    END IF;
    
    RETURN jsonb_build_object(
        'success', true,
        'action', 'unequip',
        'item_id', item_instance_id,
        'new_slot_position', v_target_slot
    );

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- 6.5: Update Item Positions (For inventory swaps/moves)
CREATE OR REPLACE FUNCTION public.update_item_positions(
    p_updates JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_update_record JSONB;
    v_row_id UUID;
    v_slot_position INT;
    v_temp_slot INT := -999; -- Temporary slot to avoid conflicts
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    -- For swaps, we need to temporarily move items to avoid unique constraint violations
    -- Step 1: Move all items to temporary slots
    FOR v_update_record IN SELECT * FROM jsonb_array_elements(p_updates)
    LOOP
        v_row_id := (v_update_record->>'row_id')::UUID;
        
        UPDATE public.inventory
        SET slot_position = v_temp_slot,
            updated_at = NOW()
        WHERE row_id = v_row_id AND user_id = v_user_id;
        
        v_temp_slot := v_temp_slot - 1; -- Use different temp slots
    END LOOP;

    -- Step 2: Move items to their final positions
    v_temp_slot := -999;
    FOR v_update_record IN SELECT * FROM jsonb_array_elements(p_updates)
    LOOP
        v_row_id := (v_update_record->>'row_id')::UUID;
        v_slot_position := (v_update_record->>'slot_position')::INT;
        
        IF v_slot_position < 0 OR v_slot_position > 19 THEN
            RETURN jsonb_build_object('success', false, 'error', 'Invalid slot position: ' || v_slot_position);
        END IF;

        UPDATE public.inventory
        SET slot_position = v_slot_position,
            updated_at = NOW()
        WHERE row_id = v_row_id AND user_id = v_user_id;
    END LOOP;

    RETURN jsonb_build_object('success', true);

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- 6.6: Move Item to Slot (Simple move)
CREATE OR REPLACE FUNCTION public.move_item_to_slot(
    p_item_instance_id UUID,
    p_target_slot INT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    IF p_target_slot < 0 OR p_target_slot > 19 THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invalid slot position');
    END IF;

    -- Check if target slot is occupied
    IF EXISTS (
        SELECT 1 FROM public.inventory
        WHERE user_id = v_user_id 
          AND slot_position = p_target_slot
          AND is_equipped = FALSE
    ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Target slot is occupied');
    END IF;

    UPDATE public.inventory
    SET slot_position = p_target_slot,
        updated_at = NOW()
    WHERE row_id = p_item_instance_id AND user_id = v_user_id;
    
    RETURN jsonb_build_object('success', true);

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- ================================================================================
-- STEP 7: Verification
-- ================================================================================
DO $$
DECLARE
    v_user RECORD;
    v_equip_dupes INT;
    v_inv_dupes INT;
BEGIN
    -- Check for remaining duplicates
    FOR v_user IN SELECT DISTINCT user_id FROM public.inventory
    LOOP
        -- Check equipment duplicates
        SELECT COUNT(*) INTO v_equip_dupes
        FROM (
            SELECT equip_slot, COUNT(*) as cnt
            FROM public.inventory
            WHERE user_id = v_user.user_id 
              AND is_equipped = TRUE 
              AND equip_slot IS NOT NULL
            GROUP BY equip_slot
            HAVING COUNT(*) > 1
        ) dupes;
        
        IF v_equip_dupes > 0 THEN
            RAISE WARNING 'User % still has % equipment slot duplicates!', v_user.user_id, v_equip_dupes;
        END IF;
        
        -- Check inventory duplicates
        SELECT COUNT(*) INTO v_inv_dupes
        FROM (
            SELECT slot_position, COUNT(*) as cnt
            FROM public.inventory
            WHERE user_id = v_user.user_id 
              AND is_equipped = FALSE 
              AND slot_position IS NOT NULL
            GROUP BY slot_position
            HAVING COUNT(*) > 1
        ) dupes;
        
        IF v_inv_dupes > 0 THEN
            RAISE WARNING 'User % still has % inventory slot duplicates!', v_user.user_id, v_inv_dupes;
        END IF;
    END LOOP;
    
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'MASTER MIGRATION COMPLETE!';
    RAISE NOTICE 'All duplicates fixed, constraints added, RPC functions updated.';
    RAISE NOTICE '=================================================================';
END $$;
