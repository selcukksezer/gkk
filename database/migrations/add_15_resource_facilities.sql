-- Add 15 New Resource Facilities
-- This migration adds the new resource extraction facilities to the database
-- Old production facilities (blacksmith, armorer, etc.) will be removed in a later migration

-- Insert new facility types into facility_recipes table
-- These are placeholder entries - actual resource collection will be handled differently
INSERT INTO public.facility_recipes 
(id, facility_type, output_item_id, output_quantity, input_materials, gold_cost, duration_seconds, required_level, success_rate, base_suspicion_increase)
VALUES
-- TEMEL KAYNAKLAR (Basic Resources)
('resource_iron_ore', 'mining', 'iron_ore', 10, '{}'::jsonb, 0, 3600, 1, 100, 0),
('resource_granite', 'quarry', 'granite', 8, '{}'::jsonb, 0, 3600, 2, 100, 0),
('resource_oak_wood', 'lumber_mill', 'oak_wood', 12, '{}'::jsonb, 0, 3600, 3, 100, 0),
('resource_ceramic_clay', 'clay_pit', 'ceramic_clay', 15, '{}'::jsonb, 0, 3600, 4, 100, 0),
('resource_glass_sand', 'sand_quarry', 'glass_sand', 20, '{}'::jsonb, 0, 3600, 5, 100, 0),

-- ORGANİK KAYNAKLAR (Organic Resources)
('resource_wheat', 'farming', 'wheat', 18, '{}'::jsonb, 0, 3600, 6, 100, 0),
('resource_healing_herb', 'herb_garden', 'healing_herb', 10, '{}'::jsonb, 0, 3600, 7, 100, 0),
('resource_leather', 'ranch', 'leather', 12, '{}'::jsonb, 0, 3600, 8, 100, 0),
('resource_honey', 'apiary', 'honey', 8, '{}'::jsonb, 0, 3600, 9, 100, 0),
('resource_healing_mushroom', 'mushroom_farm', 'healing_mushroom', 10, '{}'::jsonb, 0, 3600, 10, 100, 0),

-- MİSTİK KAYNAKLAR (Mystical Resources)
('resource_raw_rune', 'rune_mine', 'raw_rune', 5, '{}'::jsonb, 0, 3600, 11, 100, 0),
('resource_holy_water', 'holy_spring', 'holy_water', 6, '{}'::jsonb, 0, 3600, 12, 100, 0),
('resource_dark_essence', 'shadow_pit', 'dark_essence', 4, '{}'::jsonb, 0, 3600, 13, 100, 0),
('resource_fire_essence', 'elemental_forge', 'fire_essence', 5, '{}'::jsonb, 0, 3600, 14, 100, 0),
('resource_time_crystal', 'time_well', 'time_crystal', 3, '{}'::jsonb, 0, 3600, 15, 100, 0)

ON CONFLICT (id) DO NOTHING;

-- Note: This is a temporary solution
-- In the future, we should create a separate 'resources' table
-- and remove the dependency on facility_recipes for resource extraction
