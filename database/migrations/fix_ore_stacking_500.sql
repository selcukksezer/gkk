-- Fix facility item stacking + correct production_building_type mapping
-- Ensures facility collection stacks correctly and does NOT touch non-facility items.

-- 1) Add missing facility items (only if missing)
INSERT INTO public.items (
    id, name, description, icon, type, rarity, equip_slot,
    weapon_type, armor_type, material_type, potion_type,
    attack, defense, health, power, energy_restore, heal_amount,
    base_price, vendor_sell_price, can_enhance, max_enhancement,
    is_tradeable, is_stackable, max_stack,
    required_level, required_class, tolerance_increase, overdose_risk, production_building_type
) VALUES
    ('vegetables', 'Sebzeler', 'Taze sebzeler.', 'res://assets/icons/materials/vegetables.png',
        'MATERIAL', 'COMMON', NULL,
        NULL, NULL, NULL, NULL,
        0, 0, 0, 0, 0, 0,
        10, 5, false, 0,
        true, true, 500,
        1, NULL, 0, 0, 'farming'),
    ('wool', 'Yün', 'Hayvan yünü.', 'res://assets/icons/materials/wool.png',
        'MATERIAL', 'COMMON', NULL,
        NULL, NULL, NULL, NULL,
        0, 0, 0, 0, 0, 0,
        12, 6, false, 0,
        true, true, 500,
        1, NULL, 0, 0, 'ranch'),
    ('shadow_crystal', 'Gölge Kristali', 'Gölge esansı kristali.', 'res://assets/icons/materials/shadow_crystal.png',
        'MATERIAL', 'UNCOMMON', NULL,
        NULL, NULL, NULL, NULL,
        0, 0, 0, 0, 0, 0,
        60, 30, false, 0,
        true, true, 500,
        1, NULL, 0, 0, 'shadow_pit'),
    ('time_crystal', 'Zaman Kristali', 'Zaman gücü kristali.', 'res://assets/icons/materials/time_crystal.png',
        'MATERIAL', 'RARE', NULL,
        NULL, NULL, NULL, NULL,
        0, 0, 0, 0, 0, 0,
        200, 100, false, 0,
        true, true, 500,
        1, NULL, 0, 0, 'time_well')
ON CONFLICT (id) DO UPDATE SET
    production_building_type = EXCLUDED.production_building_type,
    is_stackable = true,
    max_stack = 500;

-- 2) Facility whitelist + rarity alignment (matches FacilityManager.FACILITY_RESOURCES_FULL)
WITH facility_items(facility_type, item_id, rarity) AS (
    VALUES
    ('mining','iron_ore','COMMON'),
    ('mining','copper_ore','COMMON'),
    ('mining','silver_ore','UNCOMMON'),
    ('mining','gold_ore','RARE'),
    ('mining','mithril_ore','LEGENDARY'),

    ('quarry','granite','COMMON'),
    ('quarry','marble','COMMON'),
    ('quarry','crystal_shard','UNCOMMON'),
    ('quarry','obsidian','RARE'),
    ('quarry','moonstone','LEGENDARY'),

    ('lumber_mill','oak_wood','COMMON'),
    ('lumber_mill','pine_wood','COMMON'),
    ('lumber_mill','bamboo','UNCOMMON'),
    ('lumber_mill','elder_wood','RARE'),
    ('lumber_mill','world_tree_sap','LEGENDARY'),

    ('clay_pit','ceramic_clay','COMMON'),
    ('clay_pit','brick_clay','COMMON'),
    ('clay_pit','enchanted_clay','UNCOMMON'),
    ('clay_pit','dragon_clay','RARE'),

    ('sand_quarry','glass_sand','COMMON'),
    ('sand_quarry','crystal_sand','COMMON'),
    ('sand_quarry','star_dust','UNCOMMON'),
    ('sand_quarry','void_sand','RARE'),

    ('farming','wheat','COMMON'),
    ('farming','vegetables','COMMON'),
    ('farming','cotton','UNCOMMON'),
    ('farming','magical_grain','RARE'),
    ('farming','golden_wheat','LEGENDARY'),

    ('herb_garden','healing_herb','COMMON'),
    ('herb_garden','poison_herb','COMMON'),
    ('herb_garden','rare_flower','UNCOMMON'),
    ('herb_garden','dragon_root','RARE'),
    ('herb_garden','phoenix_petal','LEGENDARY'),

    ('ranch','leather','COMMON'),
    ('ranch','bone','COMMON'),
    ('ranch','wool','UNCOMMON'),
    ('ranch','monster_hide','RARE'),
    ('ranch','dragon_scale','LEGENDARY'),

    ('apiary','honey','COMMON'),
    ('apiary','beeswax','COMMON'),
    ('apiary','bee_venom','UNCOMMON'),
    ('apiary','royal_jelly','RARE'),
    ('apiary','celestial_honey','LEGENDARY'),

    ('mushroom_farm','healing_mushroom','COMMON'),
    ('mushroom_farm','poison_mushroom','COMMON'),
    ('mushroom_farm','glowing_mushroom','UNCOMMON'),
    ('mushroom_farm','ghost_mushroom','RARE'),
    ('mushroom_farm','immortality_shroom','LEGENDARY'),

    ('rune_mine','raw_rune','COMMON'),
    ('rune_mine','magic_crystal','COMMON'),
    ('rune_mine','energy_shard','UNCOMMON'),
    ('rune_mine','power_rune','RARE'),
    ('rune_mine','ancient_rune','LEGENDARY'),

    ('holy_spring','holy_water','COMMON'),
    ('holy_spring','mana_crystal','COMMON'),
    ('holy_spring','purification_water','UNCOMMON'),
    ('holy_spring','blessed_essence','RARE'),
    ('holy_spring','divine_tear','LEGENDARY'),

    ('shadow_pit','dark_essence','COMMON'),
    ('shadow_pit','shadow_crystal','COMMON'),
    ('shadow_pit','curse_dust','UNCOMMON'),
    ('shadow_pit','void_fragment','RARE'),
    ('shadow_pit','abyss_core','LEGENDARY'),

    ('elemental_forge','fire_essence','COMMON'),
    ('elemental_forge','ice_crystal','COMMON'),
    ('elemental_forge','lightning_core','UNCOMMON'),
    ('elemental_forge','storm_shard','RARE'),
    ('elemental_forge','primordial_flame','LEGENDARY'),

    ('time_well','time_crystal','COMMON'),
    ('time_well','aging_dust','COMMON'),
    ('time_well','eternity_essence','UNCOMMON'),
    ('time_well','temporal_shard','RARE'),
    ('time_well','infinity_stone','LEGENDARY')
)
UPDATE public.items i
SET production_building_type = f.facility_type,
    rarity = f.rarity
FROM facility_items f
WHERE i.id = f.item_id;

-- 3) Remove facility assignment from items not in whitelist
WITH facility_items(facility_type, item_id) AS (
    VALUES
    ('mining','iron_ore'),('mining','copper_ore'),('mining','silver_ore'),('mining','gold_ore'),('mining','mithril_ore'),
    ('quarry','granite'),('quarry','marble'),('quarry','crystal_shard'),('quarry','obsidian'),('quarry','moonstone'),
    ('lumber_mill','oak_wood'),('lumber_mill','pine_wood'),('lumber_mill','bamboo'),('lumber_mill','elder_wood'),('lumber_mill','world_tree_sap'),
    ('clay_pit','ceramic_clay'),('clay_pit','brick_clay'),('clay_pit','enchanted_clay'),('clay_pit','dragon_clay'),
    ('sand_quarry','glass_sand'),('sand_quarry','crystal_sand'),('sand_quarry','star_dust'),('sand_quarry','void_sand'),
    ('farming','wheat'),('farming','vegetables'),('farming','cotton'),('farming','magical_grain'),('farming','golden_wheat'),
    ('herb_garden','healing_herb'),('herb_garden','poison_herb'),('herb_garden','rare_flower'),('herb_garden','dragon_root'),('herb_garden','phoenix_petal'),
    ('ranch','leather'),('ranch','bone'),('ranch','wool'),('ranch','monster_hide'),('ranch','dragon_scale'),
    ('apiary','honey'),('apiary','beeswax'),('apiary','bee_venom'),('apiary','royal_jelly'),('apiary','celestial_honey'),
    ('mushroom_farm','healing_mushroom'),('mushroom_farm','poison_mushroom'),('mushroom_farm','glowing_mushroom'),('mushroom_farm','ghost_mushroom'),('mushroom_farm','immortality_shroom'),
    ('rune_mine','raw_rune'),('rune_mine','magic_crystal'),('rune_mine','energy_shard'),('rune_mine','power_rune'),('rune_mine','ancient_rune'),
    ('holy_spring','holy_water'),('holy_spring','mana_crystal'),('holy_spring','purification_water'),('holy_spring','blessed_essence'),('holy_spring','divine_tear'),
    ('shadow_pit','dark_essence'),('shadow_pit','shadow_crystal'),('shadow_pit','curse_dust'),('shadow_pit','void_fragment'),('shadow_pit','abyss_core'),
    ('elemental_forge','fire_essence'),('elemental_forge','ice_crystal'),('elemental_forge','lightning_core'),('elemental_forge','storm_shard'),('elemental_forge','primordial_flame'),
    ('time_well','time_crystal'),('time_well','aging_dust'),('time_well','eternity_essence'),('time_well','temporal_shard'),('time_well','infinity_stone')
)
UPDATE public.items
SET production_building_type = NULL
WHERE production_building_type IN (
    'mining','quarry','lumber_mill','clay_pit','sand_quarry',
    'farming','herb_garden','ranch','apiary','mushroom_farm',
    'rune_mine','holy_spring','shadow_pit','elemental_forge','time_well'
)
AND id NOT IN (SELECT item_id FROM facility_items);

-- 4) Stack all facility-produced items to 500
UPDATE public.items
SET is_stackable = true, max_stack = 500
WHERE production_building_type IN (
    'mining','quarry','lumber_mill','clay_pit','sand_quarry',
    'farming','herb_garden','ranch','apiary','mushroom_farm',
    'rune_mine','holy_spring','shadow_pit','elemental_forge','time_well'
);
