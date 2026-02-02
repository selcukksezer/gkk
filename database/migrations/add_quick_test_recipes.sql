-- Add quick test recipes (15 seconds) for debugging purposes
-- Deletes existing 'test_quick_%' recipes to avoid duplicates if re-run

DELETE FROM public.facility_recipes WHERE id LIKE 'test_quick_%';

INSERT INTO public.facility_recipes 
(id, facility_type, output_item_id, output_quantity, input_materials, gold_cost, duration_seconds, required_level, success_rate, base_suspicion_increase)
VALUES
-- Mining
('test_quick_mining', 'mining', 'material_iron_ore', 1, '{}'::jsonb, 0, 15, 1, 100, 1),
-- Woodworking
('test_quick_wood', 'woodworking', 'material_oak_log', 1, '{}'::jsonb, 0, 15, 1, 100, 1),
-- Farming
('test_quick_farm', 'farming', 'material_wheat', 1, '{}'::jsonb, 0, 15, 1, 100, 1),
-- Herb Garden
('test_quick_herb', 'herb_garden', 'material_herb', 1, '{}'::jsonb, 0, 15, 1, 100, 1),
-- Blacksmith
('test_quick_smith', 'blacksmith', 'test_sword', 1, '{"material_iron_ore": 1}'::jsonb, 0, 15, 1, 100, 1),
-- Armorer
('test_quick_armor', 'armorer', 'test_armor', 1, '{"material_iron_ore": 1}'::jsonb, 0, 15, 1, 100, 1),
-- Alchemy
('test_quick_alchemy', 'alchemy_lab', 'potion_health_small', 1, '{"material_herb": 1}'::jsonb, 0, 15, 1, 100, 1),
-- Runesmith
('test_quick_rune', 'runesmith', 'rune_weak', 1, '{}'::jsonb, 0, 15, 1, 100, 1),
-- Scroll Library
('test_quick_scroll', 'scroll_library', 'scroll_identify', 1, '{}'::jsonb, 0, 15, 1, 100, 1),
-- Gem Cutter
('test_quick_gem', 'gem_cutter', 'gem_fragment', 1, '{}'::jsonb, 0, 15, 1, 100, 1),
-- Enhancement
('test_quick_enhance', 'enhancement_master', 'enhance_stone', 1, '{}'::jsonb, 0, 15, 1, 100, 1),
-- Master Alchemist
('test_quick_master_alc', 'master_alchemist', 'potion_health_large', 1, '{}'::jsonb, 0, 15, 1, 100, 1),
-- Master Armorer
('test_quick_master_arm', 'master_armorer', 'plate_armor', 1, '{}'::jsonb, 0, 15, 1, 100, 1);
