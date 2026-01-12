-- Clean up slot_position for equipped items
-- Equipped items should NOT have a slot_position (0-19) as they are in equipment slots.
-- Having a value there can cause "Inventory Full" errors in Shop calculations.

UPDATE public.inventory
SET slot_position = NULL
WHERE is_equipped = true;

-- Also checking for any items with invalid negative slot positions that aren't equipped (just in case)
-- (We leave them as is for now, or could set to NULL allowing auto-assign later)
-- BUT, let's just focus on the equipped ones which are the likely culprit.

SELECT count(*) as fixed_items FROM public.inventory WHERE is_equipped = true AND slot_position IS NOT NULL;
