-- Comprehensive facility recipes seed for all facility types
-- This ensures recipes exist for all facility types in the game

INSERT INTO public.facility_recipes 
(id, facility_type, output_item_id, output_quantity, input_materials, gold_cost, duration_seconds, required_level, success_rate, base_suspicion_increase)
VALUES
-- Existing recipes (already in database, but ensuring they're there)
('recipe_gather_iron', 'mine', 'material_iron_ore', 10, '{}'::jsonb, 50, 3600, 1, 100, 5),
('recipe_gather_crystal', 'mine', 'material_crystal', 5, '{}'::jsonb, 200, 7200, 2, 90, 20),
('recipe_grow_wheat', 'farm', 'material_wheat', 20, '{"material_seed_wheat": 5}'::jsonb, 20, 1800, 1, 100, 0),
('recipe_grow_poison_shroom', 'farm', 'material_poison_shroom', 10, '{}'::jsonb, 150, 3600, 1, 80, 30),
('recipe_chop_oak', 'lumber_mill', 'material_oak_log', 20, '{}'::jsonb, 30, 2700, 1, 100, 2),

-- Mining facility (plural variant)
('recipe_mine_iron', 'mining', 'material_iron_ore', 15, '{}'::jsonb, 75, 3600, 2, 95, 8),
('recipe_mine_crystal', 'mining', 'material_crystal', 8, '{}'::jsonb, 250, 7200, 3, 85, 25),

-- Farming facility (plural variant)
('recipe_farm_wheat', 'farming', 'material_wheat', 25, '{"material_seed_wheat": 5}'::jsonb, 25, 1800, 1, 100, 2),
('recipe_farm_poison', 'farming', 'material_poison_shroom', 12, '{}'::jsonb, 180, 3600, 2, 80, 35),

-- Woodworking
('recipe_craft_wood', 'woodworking', 'material_oak_log', 30, '{}'::jsonb, 40, 2700, 1, 100, 3),
('recipe_craft_board', 'woodworking', 'material_wood_board', 15, '{"material_oak_log": 20}'::jsonb, 100, 5400, 2, 90, 5),

-- Alchemy Lab / Master Alchemist
('recipe_potion_health', 'alchemy_lab', 'potion_health_minor', 5, '{"material_herb": 10, "material_crystal": 2}'::jsonb, 150, 1800, 1, 85, 40),
('recipe_potion_mana', 'master_alchemist', 'potion_mana_minor', 5, '{"material_herb": 15, "material_crystal": 3}'::jsonb, 200, 2400, 2, 80, 45),

-- Blacksmith / Armorer / Master Armorer
('recipe_forge_iron_sword', 'blacksmith', 'weapon_iron_sword', 1, '{"material_iron_ore": 20, "material_coal": 5}'::jsonb, 300, 7200, 3, 75, 50),
('recipe_forge_armor', 'armorer', 'armor_iron_plate', 1, '{"material_iron_ore": 30, "material_leather": 10}'::jsonb, 400, 9000, 4, 70, 55),
('recipe_craft_legendary', 'master_armorer', 'armor_legendary', 1, '{"material_diamond": 5, "material_enchanted": 10}'::jsonb, 1000, 14400, 8, 60, 80),

-- Gem Cutter
('recipe_cut_gem', 'gem_cutter', 'material_cut_gem', 3, '{"material_raw_gem": 5}'::jsonb, 250, 3600, 3, 80, 30),

-- Herb Garden
('recipe_dry_herb', 'herb_garden', 'material_dried_herb', 20, '{"material_herb": 30}'::jsonb, 50, 2400, 1, 100, 5),

-- Market Hub
('recipe_trade_item', 'market_hub', 'material_misc', 1, '{}'::jsonb, 0, 1800, 1, 100, 0),

-- Runesmith / Rune Master
('recipe_craft_rune', 'runesmith', 'rune_basic', 1, '{"material_crystal": 5, "material_essence": 3}'::jsonb, 500, 5400, 5, 75, 60),

-- Scroll Library / Written Knowledge Repository
('recipe_scribe_scroll', 'scroll_library', 'scroll_knowledge', 1, '{"material_paper": 10, "material_ink": 5}'::jsonb, 100, 3600, 2, 85, 10),

-- Enhancement Master
('recipe_enhance_item', 'enhancement_master', 'material_enhancement_stone', 3, '{"material_essence": 5, "material_dust": 20}'::jsonb, 400, 7200, 6, 70, 70)
ON CONFLICT (id) DO NOTHING;

-- Verify recipes were inserted
SELECT COUNT(*) as total_recipes FROM public.facility_recipes;
SELECT facility_type, COUNT(*) as count FROM public.facility_recipes GROUP BY facility_type ORDER BY facility_type;
