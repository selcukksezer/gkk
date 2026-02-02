-- ============================================
-- CRAFTING SYSTEM: CRAFTING RECIPES
-- ============================================
-- This defines HOW to craft each item - the material requirements, time, and success rate
-- All recipes are for the CRAFTING/SIMYA screen

-- ============================================
-- WEAPON RECIPES
-- ============================================

-- COMMON Weapons
INSERT INTO public.facility_recipes (id, facility_type, output_item_id, output_quantity, input_materials, gold_cost, duration_seconds, required_level, success_rate, base_suspicion_increase)
VALUES 
('recipe_sword_basic', 'crafting', 'weapon_sword_basic', 1, 
 '{"iron_ore": 10, "oak_wood": 5, "leather": 2}'::jsonb, 
 50, 1800, 1, 100, 0),

('recipe_spear_basic', 'crafting', 'weapon_spear_basic', 1,
 '{"iron_ore": 8, "pine_wood": 10, "leather": 1}'::jsonb,
 40, 1500, 1, 100, 0),

('recipe_bow_basic', 'crafting', 'weapon_bow_basic', 1,
 '{"oak_wood": 15, "cotton": 5, "bone": 3}'::jsonb,
 45, 2100, 1, 100, 0),

('recipe_axe_basic', 'crafting', 'weapon_axe_basic', 1,
 '{"iron_ore": 12, "oak_wood": 8, "granite": 3}'::jsonb,
 50, 1800, 1, 100, 0),

('recipe_dagger_basic', 'crafting', 'weapon_dagger_basic', 1,
 '{"iron_ore": 5, "leather": 3, "bone": 2}'::jsonb,
 35, 1200, 1, 100, 0)

ON CONFLICT (id) DO NOTHING;

-- UNCOMMON Weapons
INSERT INTO public.facility_recipes (id, facility_type, output_item_id, output_quantity, input_materials, gold_cost, duration_seconds, required_level, success_rate, base_suspicion_increase)
VALUES 
('recipe_sword_steel', 'crafting', 'weapon_sword_steel', 1,
 '{"iron_ore": 20, "copper_ore": 10, "leather": 5, "crystal_shard": 2}'::jsonb,
 200, 3600, 6, 100, 0),

('recipe_spear_dragon', 'crafting', 'weapon_spear_dragon', 1,
 '{"iron_ore": 15, "dragon_root": 5, "elder_wood": 10, "monster_hide": 3}'::jsonb,
 350, 5400, 8, 90, 0),

('recipe_staff_magic', 'crafting', 'weapon_staff_magic', 1,
 '{"elder_wood": 20, "magic_crystal": 10, "mana_crystal": 5, "rare_flower": 3}'::jsonb,
 320, 7200, 7, 90, 0)

ON CONFLICT (id) DO NOTHING;

-- RARE+ Weapons
INSERT INTO public.facility_recipes (id, facility_type, output_item_id, output_quantity, input_materials, gold_cost, duration_seconds, required_level, success_rate, base_suspicion_increase)
VALUES 
('recipe_sword_mithril', 'crafting', 'weapon_sword_mithril', 1,
 '{"mithril_ore": 15, "silver_ore": 20, "moonstone": 5, "dragon_scale": 3, "ancient_rune": 1}'::jsonb,
 2000, 10800, 11, 75, 0),

('recipe_axe_divine', 'crafting', 'weapon_axe_divine', 1,
 '{"mithril_ore": 20, "holy_water": 30, "divine_tear": 5, "obsidian": 10, "blessed_essence": 8}'::jsonb,
 5000, 14400, 15, 60, 0)

ON CONFLICT (id) DO NOTHING;

-- ============================================
-- ARMOR RECIPES
-- ============================================

-- COMMON Armor
INSERT INTO public.facility_recipes (id, facility_type, output_item_id, output_quantity, input_materials, gold_cost, duration_seconds, required_level, success_rate, base_suspicion_increase)
VALUES 
('recipe_armor_leather', 'crafting', 'armor_leather_chest', 1,
 '{"leather": 20, "cotton": 10, "bone": 5}'::jsonb,
 60, 2400, 1, 100, 0),

('recipe_armor_chain', 'crafting', 'armor_chain_chest', 1,
 '{"iron_ore": 25, "leather": 10, "cotton": 5}'::jsonb,
 100, 3600, 3, 100, 0)

ON CONFLICT (id) DO NOTHING;

-- UNCOMMON Armor
INSERT INTO public.facility_recipes (id, facility_type, output_item_id, output_quantity, input_materials, gold_cost, duration_seconds, required_level, success_rate, base_suspicion_increase)
VALUES 
('recipe_armor_plate_steel', 'crafting', 'armor_plate_steel', 1,
 '{"iron_ore": 40, "copper_ore": 20, "leather": 15, "crystal_shard": 5}'::jsonb,
 400, 5400, 6, 100, 0),

('recipe_armor_cloth_magical', 'crafting', 'armor_cloth_magical', 1,
 '{"cotton": 30, "magical_grain": 10, "mana_crystal": 8, "rare_flower": 5}'::jsonb,
 380, 7200, 8, 90, 0)

ON CONFLICT (id) DO NOTHING;

-- ============================================
-- POTION RECIPES (Energy)
-- ============================================

INSERT INTO public.facility_recipes (id, facility_type, output_item_id, output_quantity, input_materials, gold_cost, duration_seconds, required_level, success_rate, base_suspicion_increase)
VALUES 
('recipe_potion_energy_small', 'crafting', 'potion_energy_small', 1,
 '{"healing_herb": 5, "honey": 3, "holy_water": 2}'::jsonb,
 25, 900, 1, 100, 0),

('recipe_potion_energy_large', 'crafting', 'potion_energy_large', 1,
 '{"healing_herb": 15, "royal_jelly": 5, "mana_crystal": 3, "rare_flower": 2}'::jsonb,
 150, 1800, 8, 95, 0),

('recipe_potion_energy_master', 'crafting', 'potion_energy_master', 1,
 '{"phoenix_petal": 3, "celestial_honey": 5, "mana_crystal": 10, "divine_tear": 2, "immortality_shroom": 1}'::jsonb,
 800, 3600, 15, 80, 0)

ON CONFLICT (id) DO NOTHING;

-- ============================================
-- POTION RECIPES (Health)
-- ============================================

INSERT INTO public.facility_recipes (id, facility_type, output_item_id, output_quantity, input_materials, gold_cost, duration_seconds, required_level, success_rate, base_suspicion_increase)
VALUES 
('recipe_potion_health_small', 'crafting', 'potion_health_small', 1,
 '{"healing_mushroom": 10, "honey": 5, "wheat": 8}'::jsonb,
 20, 1200, 1, 100, 0),

('recipe_potion_health_large', 'crafting', 'potion_health_large', 1,
 '{"healing_mushroom": 20, "royal_jelly": 8, "golden_wheat": 5, "holy_water": 10}'::jsonb,
 120, 2700, 10, 95, 0)

ON CONFLICT (id) DO NOTHING;

-- ============================================
-- POTION RECIPES (Buffs & Antidote)
-- ============================================

INSERT INTO public.facility_recipes (id, facility_type, output_item_id, output_quantity, input_materials, gold_cost, duration_seconds, required_level, success_rate, base_suspicion_increase)
VALUES 
('recipe_potion_buff_power', 'crafting', 'potion_buff_power', 1,
 '{"dragon_root": 5, "fire_essence": 10, "lightning_core": 3, "poison_herb": 8}'::jsonb,
 200, 2400, 9, 90, 0),

('recipe_potion_buff_defense', 'crafting', 'potion_buff_defense', 1,
 '{"granite": 15, "obsidian": 5, "honey": 10, "bone": 20}'::jsonb,
 200, 2400, 9, 90, 0),

('recipe_potion_antidote', 'crafting', 'potion_antidote', 1,
 '{"purification_water": 10, "healing_herb": 15, "blessed_essence": 5, "phoenix_petal": 2}'::jsonb,
 1000, 3600, 12, 100, 0)

ON CONFLICT (id) DO NOTHING;

-- ============================================
-- RUNE RECIPES
-- ============================================

INSERT INTO public.facility_recipes (id, facility_type, output_item_id, output_quantity, input_materials, gold_cost, duration_seconds, required_level, success_rate, base_suspicion_increase)
VALUES 
('recipe_rune_attack_1', 'crafting', 'rune_attack_1', 1,
 '{"raw_rune": 5, "energy_shard": 3, "fire_essence": 5}'::jsonb,
 100, 1800, 5, 100, 0),

('recipe_rune_defense_1', 'crafting', 'rune_defense_1', 1,
 '{"raw_rune": 5, "energy_shard": 3, "granite": 10}'::jsonb,
 100, 1800, 5, 100, 0),

('recipe_rune_power_ancient', 'crafting', 'rune_power_ancient', 1,
 '{"ancient_rune": 3, "magic_crystal": 15, "power_rune": 5, "primordial_flame": 2}'::jsonb,
 1500, 7200, 14, 75, 0)

ON CONFLICT (id) DO NOTHING;

-- ============================================
-- SCROLL RECIPES (aligned with BlacksmithScreen system)
-- ============================================

INSERT INTO public.facility_recipes (id, facility_type, output_item_id, output_quantity, input_materials, gold_cost, duration_seconds, required_level, success_rate, base_suspicion_increase)
VALUES 
('recipe_scroll_upgrade_low', 'crafting', 'scroll_upgrade_low', 1,
 '{"cotton": 20, "vegetables": 10, "magic_crystal": 5}'::jsonb,
 75, 1800, 3, 100, 0),

('recipe_scroll_upgrade_middle', 'crafting', 'scroll_upgrade_middle', 1,
 '{"cotton": 40, "magic_crystal": 15, "mana_crystal": 8, "energy_shard": 10}'::jsonb,
 250, 3600, 8, 95, 0),

('recipe_scroll_upgrade_high', 'crafting', 'scroll_upgrade_high', 1,
 '{"cotton": 80, "magic_crystal": 30, "mana_crystal": 20, "blessed_essence": 10, "ancient_rune": 2}'::jsonb,
 1000, 7200, 14, 85, 0)

ON CONFLICT (id) DO NOTHING;

-- ============================================
-- ACCESSORY RECIPES
-- ============================================

INSERT INTO public.facility_recipes (id, facility_type, output_item_id, output_quantity, input_materials, gold_cost, duration_seconds, required_level, success_rate, base_suspicion_increase)
VALUES 
('recipe_accessory_ring_power', 'crafting', 'accessory_ring_power', 1,
 '{"gold_ore": 10, "magic_crystal": 5, "fire_essence": 8}'::jsonb,
 300, 3600, 6, 95, 0),

('recipe_accessory_necklace_dragon', 'crafting', 'accessory_necklace_dragon', 1,
 '{"dragon_scale": 5, "gold_ore": 15, "moonstone": 3, "dragon_root": 10}'::jsonb,
 3000, 7200, 12, 80, 0)

ON CONFLICT (id) DO NOTHING;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
DO $$
BEGIN
    RAISE NOTICE 'Crafting recipes migration completed successfully!';
    RAISE NOTICE 'Categories: Weapons (9), Armor (4), Potions (9), Runes (3), Scrolls (2), Accessories (2)';
    RAISE NOTICE 'Total recipes: 29';
    RAISE NOTICE 'All recipes use facility_type = crafting for use in Simya screen';
END $$;
