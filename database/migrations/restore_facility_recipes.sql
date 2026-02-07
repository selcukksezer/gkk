-- ============================================
-- RESTORE FACILITY RECIPES BASED ON ITEMDATABASE.GD
-- ============================================
-- This script adds facility recipes that match the items in ItemDatabase.gd
-- These recipes enable production of materials from facilities

-- Ensure facility_recipes table exists with required columns
CREATE TABLE IF NOT EXISTS public.facility_recipes (
    id text PRIMARY KEY,
    facility_type text NOT NULL,
    output_item_id text NOT NULL,
    output_quantity int NOT NULL DEFAULT 1,
    input_materials jsonb DEFAULT '{}'::jsonb,
    gold_cost int DEFAULT 0,
    duration_seconds int NOT NULL,
    required_level int DEFAULT 1,
    success_rate int DEFAULT 100,
    base_suspicion_increase int DEFAULT 0,
    created_at timestamp DEFAULT NOW(),
    updated_at timestamp DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_facility_recipes_type ON public.facility_recipes(facility_type);
CREATE INDEX IF NOT EXISTS idx_facility_recipes_output ON public.facility_recipes(output_item_id);
CREATE INDEX IF NOT EXISTS idx_facility_recipes_level ON public.facility_recipes(required_level);

-- ============================================
-- MINING FACILITY RECIPES
-- ============================================
-- Produces: iron_ore, copper_ore, gold_ore, silver_ore, crystal, diamond

INSERT INTO public.facility_recipes 
(id, facility_type, output_item_id, output_quantity, input_materials, gold_cost, duration_seconds, required_level, success_rate, base_suspicion_increase)
VALUES
('recipe_mine_iron_ore', 'mine', 'material_iron_ore', 10, '{}'::jsonb, 50, 3600, 1, 100, 5),
('recipe_mine_copper_ore', 'mine', 'material_copper_ore', 10, '{}'::jsonb, 60, 3600, 1, 100, 5),
('recipe_mine_silver_ore', 'mine', 'material_silver_ore', 8, '{}'::jsonb, 120, 7200, 3, 95, 10),
('recipe_mine_gold_ore', 'mine', 'material_gold_ore', 6, '{}'::jsonb, 200, 10800, 5, 90, 15),
('recipe_mine_crystal', 'mine', 'material_crystal', 4, '{}'::jsonb, 350, 14400, 7, 85, 20),
('recipe_mine_diamond', 'mine', 'material_diamond', 2, '{}'::jsonb, 1500, 28800, 10, 70, 30)
ON CONFLICT (id) DO UPDATE SET
    facility_type = EXCLUDED.facility_type,
    output_item_id = EXCLUDED.output_item_id,
    output_quantity = EXCLUDED.output_quantity,
    input_materials = EXCLUDED.input_materials,
    gold_cost = EXCLUDED.gold_cost,
    duration_seconds = EXCLUDED.duration_seconds,
    required_level = EXCLUDED.required_level,
    success_rate = EXCLUDED.success_rate,
    base_suspicion_increase = EXCLUDED.base_suspicion_increase,
    updated_at = NOW();

-- Alternative facility name variants
INSERT INTO public.facility_recipes 
(id, facility_type, output_item_id, output_quantity, input_materials, gold_cost, duration_seconds, required_level, success_rate, base_suspicion_increase)
VALUES
('recipe_mining_iron_ore', 'mining', 'material_iron_ore', 10, '{}'::jsonb, 50, 3600, 1, 100, 5),
('recipe_mining_copper_ore', 'mining', 'material_copper_ore', 10, '{}'::jsonb, 60, 3600, 1, 100, 5),
('recipe_mining_silver_ore', 'mining', 'material_silver_ore', 8, '{}'::jsonb, 120, 7200, 3, 95, 10),
('recipe_mining_gold_ore', 'mining', 'material_gold_ore', 6, '{}'::jsonb, 200, 10800, 5, 90, 15),
('recipe_mining_crystal', 'mining', 'material_crystal', 4, '{}'::jsonb, 350, 14400, 7, 85, 20),
('recipe_mining_diamond', 'mining', 'material_diamond', 2, '{}'::jsonb, 1500, 28800, 10, 70, 30)
ON CONFLICT (id) DO UPDATE SET
    facility_type = EXCLUDED.facility_type,
    output_item_id = EXCLUDED.output_item_id,
    output_quantity = EXCLUDED.output_quantity,
    input_materials = EXCLUDED.input_materials,
    gold_cost = EXCLUDED.gold_cost,
    duration_seconds = EXCLUDED.duration_seconds,
    required_level = EXCLUDED.required_level,
    success_rate = EXCLUDED.success_rate,
    base_suspicion_increase = EXCLUDED.base_suspicion_increase,
    updated_at = NOW();

-- ============================================
-- SAWMILL/LUMBER MILL FACILITY RECIPES
-- ============================================
-- Produces: wood, hardwood, bamboo

INSERT INTO public.facility_recipes 
(id, facility_type, output_item_id, output_quantity, input_materials, gold_cost, duration_seconds, required_level, success_rate, base_suspicion_increase)
VALUES
('recipe_sawmill_wood', 'sawmill', 'material_wood', 15, '{}'::jsonb, 30, 2400, 1, 100, 2),
('recipe_sawmill_bamboo', 'sawmill', 'material_bamboo', 12, '{}'::jsonb, 50, 4800, 3, 95, 5),
('recipe_sawmill_hardwood', 'sawmill', 'material_hardwood', 10, '{}'::jsonb, 100, 7200, 4, 90, 8)
ON CONFLICT (id) DO UPDATE SET
    facility_type = EXCLUDED.facility_type,
    output_item_id = EXCLUDED.output_item_id,
    output_quantity = EXCLUDED.output_quantity,
    input_materials = EXCLUDED.input_materials,
    gold_cost = EXCLUDED.gold_cost,
    duration_seconds = EXCLUDED.duration_seconds,
    required_level = EXCLUDED.required_level,
    success_rate = EXCLUDED.success_rate,
    base_suspicion_increase = EXCLUDED.base_suspicion_increase,
    updated_at = NOW();

-- Alternative: lumber_mill
INSERT INTO public.facility_recipes 
(id, facility_type, output_item_id, output_quantity, input_materials, gold_cost, duration_seconds, required_level, success_rate, base_suspicion_increase)
VALUES
('recipe_lumber_mill_wood', 'lumber_mill', 'material_wood', 15, '{}'::jsonb, 30, 2400, 1, 100, 2),
('recipe_lumber_mill_bamboo', 'lumber_mill', 'material_bamboo', 12, '{}'::jsonb, 50, 4800, 3, 95, 5),
('recipe_lumber_mill_hardwood', 'lumber_mill', 'material_hardwood', 10, '{}'::jsonb, 100, 7200, 4, 90, 8)
ON CONFLICT (id) DO UPDATE SET
    facility_type = EXCLUDED.facility_type,
    output_item_id = EXCLUDED.output_item_id,
    output_quantity = EXCLUDED.output_quantity,
    input_materials = EXCLUDED.input_materials,
    gold_cost = EXCLUDED.gold_cost,
    duration_seconds = EXCLUDED.duration_seconds,
    required_level = EXCLUDED.required_level,
    success_rate = EXCLUDED.success_rate,
    base_suspicion_increase = EXCLUDED.base_suspicion_increase,
    updated_at = NOW();

-- ============================================
-- FARM FACILITY RECIPES
-- ============================================
-- Produces: leather, quality_leather, wool

INSERT INTO public.facility_recipes 
(id, facility_type, output_item_id, output_quantity, input_materials, gold_cost, duration_seconds, required_level, success_rate, base_suspicion_increase)
VALUES
('recipe_farm_leather', 'farm', 'material_leather', 12, '{}'::jsonb, 70, 3600, 1, 100, 3),
('recipe_farm_wool', 'farm', 'material_wool', 15, '{}'::jsonb, 50, 3000, 2, 100, 2),
('recipe_farm_quality_leather', 'farm', 'material_quality_leather', 6, '{}'::jsonb, 250, 10800, 5, 85, 12)
ON CONFLICT (id) DO UPDATE SET
    facility_type = EXCLUDED.facility_type,
    output_item_id = EXCLUDED.output_item_id,
    output_quantity = EXCLUDED.output_quantity,
    input_materials = EXCLUDED.input_materials,
    gold_cost = EXCLUDED.gold_cost,
    duration_seconds = EXCLUDED.duration_seconds,
    required_level = EXCLUDED.required_level,
    success_rate = EXCLUDED.success_rate,
    base_suspicion_increase = EXCLUDED.base_suspicion_increase,
    updated_at = NOW();

-- Alternative: farming
INSERT INTO public.facility_recipes 
(id, facility_type, output_item_id, output_quantity, input_materials, gold_cost, duration_seconds, required_level, success_rate, base_suspicion_increase)
VALUES
('recipe_farming_leather', 'farming', 'material_leather', 12, '{}'::jsonb, 70, 3600, 1, 100, 3),
('recipe_farming_wool', 'farming', 'material_wool', 15, '{}'::jsonb, 50, 3000, 2, 100, 2),
('recipe_farming_quality_leather', 'farming', 'material_quality_leather', 6, '{}'::jsonb, 250, 10800, 5, 85, 12)
ON CONFLICT (id) DO UPDATE SET
    facility_type = EXCLUDED.facility_type,
    output_item_id = EXCLUDED.output_item_id,
    output_quantity = EXCLUDED.output_quantity,
    input_materials = EXCLUDED.input_materials,
    gold_cost = EXCLUDED.gold_cost,
    duration_seconds = EXCLUDED.duration_seconds,
    required_level = EXCLUDED.required_level,
    success_rate = EXCLUDED.success_rate,
    base_suspicion_increase = EXCLUDED.base_suspicion_increase,
    updated_at = NOW();

-- ============================================
-- HERB GARDEN FACILITY RECIPES
-- ============================================
-- Produces: herb, rare_herb, dragon_blood

INSERT INTO public.facility_recipes 
(id, facility_type, output_item_id, output_quantity, input_materials, gold_cost, duration_seconds, required_level, success_rate, base_suspicion_increase)
VALUES
('recipe_herb_garden_herb', 'herb_garden', 'material_herb', 20, '{}'::jsonb, 40, 2400, 1, 100, 5),
('recipe_herb_garden_rare_herb', 'herb_garden', 'material_rare_herb', 8, '{}'::jsonb, 500, 14400, 5, 80, 25),
('recipe_herb_garden_dragon_blood', 'herb_garden', 'material_dragon_blood', 2, '{}'::jsonb, 2000, 43200, 10, 60, 50)
ON CONFLICT (id) DO UPDATE SET
    facility_type = EXCLUDED.facility_type,
    output_item_id = EXCLUDED.output_item_id,
    output_quantity = EXCLUDED.output_quantity,
    input_materials = EXCLUDED.input_materials,
    gold_cost = EXCLUDED.gold_cost,
    duration_seconds = EXCLUDED.duration_seconds,
    required_level = EXCLUDED.required_level,
    success_rate = EXCLUDED.success_rate,
    base_suspicion_increase = EXCLUDED.base_suspicion_increase,
    updated_at = NOW();

-- ============================================
-- ALCHEMY LAB FACILITY RECIPES
-- ============================================
-- Produces: potions

INSERT INTO public.facility_recipes 
(id, facility_type, output_item_id, output_quantity, input_materials, gold_cost, duration_seconds, required_level, success_rate, base_suspicion_increase)
VALUES
('recipe_alchemy_energy_minor', 'alchemy_lab', 'potion_energy_minor', 5, '{"material_herb": 5}'::jsonb, 100, 1800, 1, 90, 15),
('recipe_alchemy_antidote', 'alchemy_lab', 'potion_antidote', 3, '{"material_herb": 10, "material_crystal": 1}'::jsonb, 300, 3600, 2, 85, 20),
('recipe_alchemy_health', 'alchemy_lab', 'potion_health', 5, '{"material_herb": 8, "material_crystal": 1}'::jsonb, 200, 2400, 1, 90, 18),
('recipe_alchemy_mana', 'alchemy_lab', 'potion_mana', 3, '{"material_rare_herb": 5, "material_crystal": 2}'::jsonb, 400, 4800, 3, 85, 25),
('recipe_alchemy_stamina', 'alchemy_lab', 'potion_stamina', 2, '{"material_rare_herb": 8, "material_crystal": 3}'::jsonb, 600, 7200, 4, 80, 30)
ON CONFLICT (id) DO UPDATE SET
    facility_type = EXCLUDED.facility_type,
    output_item_id = EXCLUDED.output_item_id,
    output_quantity = EXCLUDED.output_quantity,
    input_materials = EXCLUDED.input_materials,
    gold_cost = EXCLUDED.gold_cost,
    duration_seconds = EXCLUDED.duration_seconds,
    required_level = EXCLUDED.required_level,
    success_rate = EXCLUDED.success_rate,
    base_suspicion_increase = EXCLUDED.base_suspicion_increase,
    updated_at = NOW();

-- ============================================
-- BLACKSMITH FACILITY RECIPES
-- ============================================
-- Produces: weapons

INSERT INTO public.facility_recipes 
(id, facility_type, output_item_id, output_quantity, input_materials, gold_cost, duration_seconds, required_level, success_rate, base_suspicion_increase)
VALUES
('recipe_blacksmith_iron_sword', 'blacksmith', 'weapon_iron_sword', 1, '{"material_iron_ore": 20, "material_wood": 5}'::jsonb, 500, 7200, 1, 85, 25),
('recipe_blacksmith_steel_sword', 'blacksmith', 'weapon_steel_sword', 1, '{"material_iron_ore": 40, "material_wood": 10, "material_crystal": 2}'::jsonb, 2000, 14400, 3, 75, 40),
('recipe_blacksmith_legendary_sword', 'blacksmith', 'weapon_legendary_sword', 1, '{"material_gold_ore": 30, "material_diamond": 5, "material_dragon_blood": 2}'::jsonb, 10000, 43200, 8, 60, 70)
ON CONFLICT (id) DO UPDATE SET
    facility_type = EXCLUDED.facility_type,
    output_item_id = EXCLUDED.output_item_id,
    output_quantity = EXCLUDED.output_quantity,
    input_materials = EXCLUDED.input_materials,
    gold_cost = EXCLUDED.gold_cost,
    duration_seconds = EXCLUDED.duration_seconds,
    required_level = EXCLUDED.required_level,
    success_rate = EXCLUDED.success_rate,
    base_suspicion_increase = EXCLUDED.base_suspicion_increase,
    updated_at = NOW();

-- ============================================
-- ARMORER FACILITY RECIPES
-- ============================================
-- Produces: armor

INSERT INTO public.facility_recipes 
(id, facility_type, output_item_id, output_quantity, input_materials, gold_cost, duration_seconds, required_level, success_rate, base_suspicion_increase)
VALUES
('recipe_armorer_leather_armor', 'armorer', 'armor_leather_armor', 1, '{"material_leather": 20, "material_wood": 5}'::jsonb, 700, 7200, 1, 85, 25),
('recipe_armorer_chain_mail', 'armorer', 'armor_chain_mail', 1, '{"material_iron_ore": 30, "material_leather": 10}'::jsonb, 2000, 14400, 3, 75, 40),
('recipe_armorer_plate_armor', 'armorer', 'armor_plate_armor', 1, '{"material_iron_ore": 50, "material_gold_ore": 10, "material_crystal": 3}'::jsonb, 5000, 21600, 5, 70, 50)
ON CONFLICT (id) DO UPDATE SET
    facility_type = EXCLUDED.facility_type,
    output_item_id = EXCLUDED.output_item_id,
    output_quantity = EXCLUDED.output_quantity,
    input_materials = EXCLUDED.input_materials,
    gold_cost = EXCLUDED.gold_cost,
    duration_seconds = EXCLUDED.duration_seconds,
    required_level = EXCLUDED.required_level,
    success_rate = EXCLUDED.success_rate,
    base_suspicion_increase = EXCLUDED.base_suspicion_increase,
    updated_at = NOW();

-- ============================================
-- RUNESMITH FACILITY RECIPES
-- ============================================
-- Produces: runes

INSERT INTO public.facility_recipes 
(id, facility_type, output_item_id, output_quantity, input_materials, gold_cost, duration_seconds, required_level, success_rate, base_suspicion_increase)
VALUES
('recipe_runesmith_attack_minor', 'runesmith', 'rune_attack_minor', 1, '{"material_crystal": 5, "material_iron_ore": 10}'::jsonb, 1000, 7200, 3, 80, 35),
('recipe_runesmith_defense_minor', 'runesmith', 'rune_defense_minor', 1, '{"material_crystal": 5, "material_iron_ore": 10}'::jsonb, 1000, 7200, 3, 80, 35),
('recipe_runesmith_attack_major', 'runesmith', 'rune_attack_major', 1, '{"material_crystal": 15, "material_gold_ore": 10, "material_rare_herb": 5}'::jsonb, 4000, 14400, 5, 70, 50),
('recipe_runesmith_defense_major', 'runesmith', 'rune_defense_major', 1, '{"material_crystal": 15, "material_gold_ore": 10, "material_rare_herb": 5}'::jsonb, 4000, 14400, 5, 70, 50),
('recipe_runesmith_legendary', 'runesmith', 'rune_legendary', 1, '{"material_diamond": 10, "material_dragon_blood": 5, "material_crystal": 30}'::jsonb, 25000, 43200, 10, 50, 80)
ON CONFLICT (id) DO UPDATE SET
    facility_type = EXCLUDED.facility_type,
    output_item_id = EXCLUDED.output_item_id,
    output_quantity = EXCLUDED.output_quantity,
    input_materials = EXCLUDED.input_materials,
    gold_cost = EXCLUDED.gold_cost,
    duration_seconds = EXCLUDED.duration_seconds,
    required_level = EXCLUDED.required_level,
    success_rate = EXCLUDED.success_rate,
    base_suspicion_increase = EXCLUDED.base_suspicion_increase,
    updated_at = NOW();

-- ============================================
-- GEM CUTTER FACILITY RECIPES
-- ============================================
-- Produces: gems

INSERT INTO public.facility_recipes 
(id, facility_type, output_item_id, output_quantity, input_materials, gold_cost, duration_seconds, required_level, success_rate, base_suspicion_increase)
VALUES
('recipe_gem_cutter_ruby', 'gem_cutter', 'gem_ruby', 1, '{"material_crystal": 10, "material_gold_ore": 5}'::jsonb, 1500, 10800, 4, 75, 40),
('recipe_gem_cutter_sapphire', 'gem_cutter', 'gem_sapphire', 1, '{"material_crystal": 15, "material_silver_ore": 10}'::jsonb, 3000, 14400, 6, 70, 50),
('recipe_gem_cutter_emerald', 'gem_cutter', 'gem_emerald', 1, '{"material_diamond": 5, "material_rare_herb": 10, "material_crystal": 20}'::jsonb, 7500, 21600, 8, 60, 65)
ON CONFLICT (id) DO UPDATE SET
    facility_type = EXCLUDED.facility_type,
    output_item_id = EXCLUDED.output_item_id,
    output_quantity = EXCLUDED.output_quantity,
    input_materials = EXCLUDED.input_materials,
    gold_cost = EXCLUDED.gold_cost,
    duration_seconds = EXCLUDED.duration_seconds,
    required_level = EXCLUDED.required_level,
    success_rate = EXCLUDED.success_rate,
    base_suspicion_increase = EXCLUDED.base_suspicion_increase,
    updated_at = NOW();

-- ============================================
-- SCROLL LIBRARY FACILITY RECIPES
-- ============================================
-- Produces: upgrade scrolls

INSERT INTO public.facility_recipes 
(id, facility_type, output_item_id, output_quantity, input_materials, gold_cost, duration_seconds, required_level, success_rate, base_suspicion_increase)
VALUES
('recipe_scroll_library_low', 'scroll_library', 'scroll_upgrade_low', 3, '{"material_wood": 20, "material_herb": 10}'::jsonb, 2500, 7200, 2, 85, 20),
('recipe_scroll_library_middle', 'scroll_library', 'scroll_upgrade_middle', 2, '{"material_hardwood": 15, "material_rare_herb": 8, "material_crystal": 5}'::jsonb, 12500, 14400, 5, 75, 35),
('recipe_scroll_library_high', 'scroll_library', 'scroll_upgrade_high', 1, '{"material_hardwood": 30, "material_dragon_blood": 3, "material_diamond": 2}'::jsonb, 50000, 28800, 8, 60, 55)
ON CONFLICT (id) DO UPDATE SET
    facility_type = EXCLUDED.facility_type,
    output_item_id = EXCLUDED.output_item_id,
    output_quantity = EXCLUDED.output_quantity,
    input_materials = EXCLUDED.input_materials,
    gold_cost = EXCLUDED.gold_cost,
    duration_seconds = EXCLUDED.duration_seconds,
    required_level = EXCLUDED.required_level,
    success_rate = EXCLUDED.success_rate,
    base_suspicion_increase = EXCLUDED.base_suspicion_increase,
    updated_at = NOW();

-- ============================================
-- VERIFICATION
-- ============================================
-- Check that all recipes were added

SELECT 
    'Total facility recipes' as description,
    COUNT(*) as count
FROM public.facility_recipes

UNION ALL

SELECT 
    'Facility types covered' as description,
    COUNT(DISTINCT facility_type) as count
FROM public.facility_recipes;

-- Show recipes by facility type
SELECT 
    facility_type,
    COUNT(*) as recipe_count,
    STRING_AGG(output_item_id, ', ') as produces
FROM public.facility_recipes
GROUP BY facility_type
ORDER BY facility_type;
