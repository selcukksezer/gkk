-- Clean up duplicate equipment slots and enforce uniqueness
-- This ensures a user can only have ONE item with is_equipped=TRUE for each equip_slot type.

CREATE OR REPLACE FUNCTION public.repair_equipment_slots()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id UUID;
    v_row_id UUID;
    v_target_slot INT;
    v_item RECORD;
BEGIN
    -- Get current user (this function is usually called with user context, or we iterate all users if superuser)
    -- Assuming called by user via RPC or Supabase console with auth.uid()
    v_user_id := auth.uid();
    
    -- If running as admin/migration without specific user context, this logic might need adjustment.
    -- But based on user error, they have a UID.
    
    -- Iterate over duplicate items (keeping the most recent one valid, moving others)
    FOR v_item IN 
        SELECT row_id, user_id
        FROM (
            SELECT row_id, user_id,
                   ROW_NUMBER() OVER (
                       PARTITION BY user_id, equip_slot 
                       ORDER BY updated_at DESC
                   ) as rn
            FROM public.inventory
            WHERE is_equipped = TRUE AND equip_slot IS NOT NULL
        ) dupes
        WHERE rn > 1
    LOOP
        -- Find a free slot for this item
        -- Simple linear search from 0 to 999
        SELECT s.i INTO v_target_slot
        FROM generate_series(0, 999) AS s(i)
        WHERE NOT EXISTS (
            SELECT 1 FROM public.inventory 
            WHERE user_id = v_item.user_id 
              AND slot_position = s.i
        )
        LIMIT 1;
        
        -- Update the item
        UPDATE public.inventory
        SET is_equipped = FALSE,
            equip_slot = NULL,
            slot_position = v_target_slot,
            updated_at = NOW()
        WHERE row_id = v_item.row_id;
        
    END LOOP;

END;
$$;

-- Run repairs immediately
SELECT public.repair_equipment_slots();

-- 2. Add Unique Index to prevent future collisions
DROP INDEX IF EXISTS idx_inventory_user_equip_slot_unique;

CREATE UNIQUE INDEX idx_inventory_user_equip_slot_unique 
ON public.inventory (user_id, equip_slot) 
WHERE is_equipped = TRUE;
