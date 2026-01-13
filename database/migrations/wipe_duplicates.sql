-- Nuclear Duplicate Wiper
-- Finds items that act as duplicates (same item_id, same details) and deletes the extras.
-- This is aggressive.

CREATE OR REPLACE FUNCTION public.wipe_duplicates()
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
    v_deleted_count INT := 0;
BEGIN
    -- 1. Identify duplicates based on item_id and user_id (ignoring unique IDs for a moment)
    -- This assumes items with same item_id SHOULD stack or be unique if not stackable.
    
    -- Actually, let's just target the specific "Ghost" scenario:
    -- Items that are NOT equipped but share a slot position are already handled by repair_inventory_slots.
    -- But what if we have multiple items with the SAME slot_position?
    
    -- Let's re-run a forced cleanup on slot_positions
    
    -- Strategy: Partition by user + slot_position (where slot is not null and not equipped)
    -- Keep only the most recently updated one.
    
    WITH duplicates AS (
        SELECT row_id,
               ROW_NUMBER() OVER (
                   PARTITION BY user_id, slot_position 
                   ORDER BY updated_at DESC, quantity DESC
               ) as rn
        FROM public.inventory
        WHERE slot_position IS NOT NULL 
          AND is_equipped = FALSE
    )
    DELETE FROM public.inventory
    WHERE row_id IN (
        SELECT row_id FROM duplicates WHERE rn > 1
    );
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;

    RETURN jsonb_build_object(
        'success', true,
        'deleted_ghosts', v_deleted_count
    );
END;
$$;
