-- Update max_stack to 50 for ALL stackable items
UPDATE public.items
SET max_stack = 50
WHERE is_stackable = true;

-- Optional: If you want to clamp existing inventory quantities to 50 (not requested but safe)
-- UPDATE public.inventory
-- SET quantity = 50
-- WHERE quantity > 50 AND item_id IN (SELECT id FROM public.items WHERE is_stackable = true);
