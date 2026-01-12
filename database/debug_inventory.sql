-- Check inventory summary
SELECT name, COUNT(*) as count, 
       SUM(CASE WHEN is_equipped THEN 1 ELSE 0 END) as equipped_count,
       SUM(CASE WHEN is_equipped = FALSE THEN 1 ELSE 0 END) as bag_count
FROM public.inventory
WHERE user_id = auth.uid()
GROUP BY name;

-- Check exact slot usage
SELECT slot_position, name, is_equipped, row_id
FROM public.inventory
WHERE user_id = auth.uid()
ORDER BY slot_position ASC NULLS LAST;
