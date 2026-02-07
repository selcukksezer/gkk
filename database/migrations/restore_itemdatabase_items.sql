-- ============================================
-- RESTORE ALL ITEMS FROM ItemDatabase.gd
-- ============================================
-- This script adds ALL 39 items from core/data/ItemDatabase.gd to the database
-- These item IDs MUST match exactly between the game code and database
-- Run this after database restoration to ensure all game items are available

-- ============================================
-- PART 1: WEAPONS (6 items)
-- ============================================

INSERT INTO public.items (
    id, name, type, description, rarity, icon, 
    equip_slot, weapon_type, attack, defense, health, power,
    can_enhance, max_enhancement, required_level, base_price, vendor_sell_price,
    is_stackable, is_tradeable, max_stack
)
VALUES 
-- Basic weapons
('weapon_sword_basic', 'Demir Kılıç', 'WEAPON', 'Basit bir demir kılıç. Yeni başlayanlar için ideal.', 'COMMON', 'res://assets/sprites/items/sword_basic.png', 'WEAPON', 'SWORD', 15, 5, 0, 0, true, 10, 1, 100, 50, false, true, 1),
('weapon_bow_elven', 'Elf Yayı', 'WEAPON', 'Elf ustalarının yaptığı hafif ve güçlü yay.', 'RARE', 'res://assets/sprites/items/bow.png', 'WEAPON', 'BOW', 35, 0, 0, 10, true, 10, 15, 2500, 1250, false, true, 1),
('weapon_custom_longsword', 'Eşsiz Uzun Kılıç', 'WEAPON', 'Kullanıcının eklediği kılıç.', 'EPIC', 'res://assets/sprites/items/sword_custom.png', 'WEAPON', 'SWORD', 60, 0, 0, 0, true, 15, 10, 1200, 600, false, true, 1),
('weapon_iron_sword', 'Demir Kılıç', 'WEAPON', 'Temel demir kılıç. İyi bir başlangıç silahı.', 'COMMON', 'res://assets/sprites/items/iron_sword.png', 'WEAPON', 'SWORD', 12, 0, 0, 0, true, 10, 1, 100, 50, false, true, 1),
('weapon_steel_sword', 'Çelik Kılıç', 'WEAPON', 'Çelikten yapılmış güçlü kılıç. Daha yüksek saldırı gücü.', 'RARE', 'res://assets/sprites/items/steel_sword.png', 'WEAPON', 'SWORD', 25, 0, 0, 0, true, 10, 1, 400, 200, false, true, 1),
('weapon_legendary_sword', 'Efsanevi Kılıç', 'WEAPON', 'Eski zamanlardan kalma efsanevi kılıç. Muazzam gücü vardır.', 'LEGENDARY', 'res://assets/sprites/items/legendary_sword.png', 'WEAPON', 'SWORD', 50, 0, 0, 0, true, 10, 1, 2000, 1000, false, true, 1)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    type = EXCLUDED.type,
    description = EXCLUDED.description,
    rarity = EXCLUDED.rarity,
    icon = EXCLUDED.icon,
    equip_slot = EXCLUDED.equip_slot,
    weapon_type = EXCLUDED.weapon_type,
    attack = EXCLUDED.attack,
    defense = EXCLUDED.defense,
    health = EXCLUDED.health,
    power = EXCLUDED.power,
    can_enhance = EXCLUDED.can_enhance,
    max_enhancement = EXCLUDED.max_enhancement,
    required_level = EXCLUDED.required_level,
    base_price = EXCLUDED.base_price,
    vendor_sell_price = EXCLUDED.vendor_sell_price,
    is_stackable = EXCLUDED.is_stackable,
    is_tradeable = EXCLUDED.is_tradeable,
    max_stack = EXCLUDED.max_stack;

-- ============================================
-- PART 2: ARMOR (5 items)
-- ============================================

INSERT INTO public.items (
    id, name, type, description, rarity, icon,
    equip_slot, armor_type, defense, health, attack,
    can_enhance, max_enhancement, required_level, base_price, vendor_sell_price,
    is_stackable, is_tradeable, max_stack
)
VALUES 
('armor_custom_plate', 'Eşsiz Zırh', 'ARMOR', 'Kullanıcının eklediği plaka zırh.', 'EPIC', 'res://assets/sprites/items/armor_custom.png', 'CHEST', 'PLATE', 80, 120, 0, true, 15, 12, 1500, 750, false, true, 1),
('armor_chest_leather', 'Deri Göğüslük', 'ARMOR', 'Esnek deri zırh. Hareket özgürlüğü sağlar.', 'COMMON', 'res://assets/sprites/items/chest_leather.png', 'CHEST', 'LEATHER', 12, 20, 0, true, 10, 1, 80, 40, false, true, 1),
('armor_chest_plate', 'Plaka Göğüslük', 'ARMOR', 'Ağır plaka zırh. Maksimum koruma sağlar.', 'UNCOMMON', 'res://assets/sprites/items/chest_plate.png', 'CHEST', 'PLATE', 25, 40, 0, true, 10, 8, 500, 250, false, true, 1),
('armor_leather_armor', 'Deri Zırh', 'ARMOR', 'Hafif deri zırh. İyi hareket kabiliyeti sağlar.', 'COMMON', 'res://assets/sprites/items/leather_armor.png', 'CHEST', 'LEATHER', 15, 0, 0, true, 10, 1, 150, 75, false, true, 1),
('armor_chain_mail', 'Zincir Zırh', 'ARMOR', 'Zincir halkalarından yapılmış zırh. Orta derecede koruma sağlar.', 'UNCOMMON', 'res://assets/sprites/items/chain_mail.png', 'CHEST', 'CHAIN', 25, 20, 0, true, 10, 1, 400, 200, false, true, 1),
('armor_plate_armor', 'Plaka Zırh', 'ARMOR', 'Ağır plaka zırh. Maksimum koruma sağlar ama hareket yavaşlatır.', 'RARE', 'res://assets/sprites/items/plate_armor.png', 'CHEST', 'PLATE', 40, 50, 0, true, 10, 1, 1000, 500, false, true, 1)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    type = EXCLUDED.type,
    description = EXCLUDED.description,
    rarity = EXCLUDED.rarity,
    icon = EXCLUDED.icon,
    equip_slot = EXCLUDED.equip_slot,
    armor_type = EXCLUDED.armor_type,
    defense = EXCLUDED.defense,
    health = EXCLUDED.health,
    attack = EXCLUDED.attack,
    can_enhance = EXCLUDED.can_enhance,
    max_enhancement = EXCLUDED.max_enhancement,
    required_level = EXCLUDED.required_level,
    base_price = EXCLUDED.base_price,
    vendor_sell_price = EXCLUDED.vendor_sell_price,
    is_stackable = EXCLUDED.is_stackable,
    is_tradeable = EXCLUDED.is_tradeable,
    max_stack = EXCLUDED.max_stack;

-- ============================================
-- PART 3: POTIONS (5 items)
-- ============================================

INSERT INTO public.items (
    id, name, type, description, rarity, icon, potion_type,
    base_price, vendor_sell_price, is_stackable, max_stack,
    tolerance_increase, energy_restore, health_restore, mana_restore, buff_duration
)
VALUES 
('potion_energy_minor', 'Minör Enerji İksiri', 'POTION', '+20 enerji geri yükler. Hafif bağımlılık yapar.', 'COMMON', 'res://assets/sprites/items/potion_energy.png', 'ENERGY', 25, 10, true, 50, 1, 20, 0, 0, 0),
('potion_antidote', 'Antidot', 'POTION', 'Bağımlılığı azaltır ve toleransı sıfırlar.', 'UNCOMMON', 'res://assets/sprites/items/potion_antidote.png', 'ANTIDOTE', 100, 50, true, 50, -5, 0, 0, 0, 0),
('potion_health', 'Sağlık İksiri', 'POTION', 'Can sağlığını geri yükler. 50 HP''yi tamamen iyileştirir.', 'COMMON', 'res://assets/sprites/items/potion_health.png', 'HEALING', 50, 25, true, 50, 0, 0, 50, 0, 0),
('potion_mana', 'Mana İksiri', 'POTION', 'Mana reservini geri yükler. Büyüler açmada yardımcı.', 'UNCOMMON', 'res://assets/sprites/items/potion_mana.png', 'HEALING', 75, 37, true, 50, 0, 0, 0, 50, 0),
('potion_stamina', 'Dayanıklılık İksiri', 'POTION', 'Çabukluk ve dayanıklılık arttırır. 1 saat etkili.', 'UNCOMMON', 'res://assets/sprites/items/potion_stamina.png', 'BUFF', 100, 50, true, 30, 0, 0, 0, 0, 3600)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    type = EXCLUDED.type,
    description = EXCLUDED.description,
    rarity = EXCLUDED.rarity,
    icon = EXCLUDED.icon,
    potion_type = EXCLUDED.potion_type,
    base_price = EXCLUDED.base_price,
    vendor_sell_price = EXCLUDED.vendor_sell_price,
    is_stackable = EXCLUDED.is_stackable,
    max_stack = EXCLUDED.max_stack,
    tolerance_increase = EXCLUDED.tolerance_increase,
    energy_restore = EXCLUDED.energy_restore,
    health_restore = EXCLUDED.health_restore,
    mana_restore = EXCLUDED.mana_restore,
    buff_duration = EXCLUDED.buff_duration;

-- ============================================
-- PART 4: MATERIALS - ORE (6 items)
-- ============================================

INSERT INTO public.items (
    id, name, type, description, rarity, icon, material_type,
    base_price, vendor_sell_price, is_stackable, max_stack,
    production_building_type, production_rate_per_hour, production_required_level
)
VALUES 
('material_iron_ore', 'Demir Cevheri', 'MATERIAL', 'Demir üretimi için kullanılır.', 'COMMON', 'res://assets/sprites/items/ore_iron.png', 'ORE', 5, 2, true, 500, 'mine', 10, 1),
('material_copper_ore', 'Bakır Cevheri', 'MATERIAL', 'Bakır ve tunç eşyalar üretmek için kullanılır.', 'COMMON', 'res://assets/sprites/items/ore_copper.png', 'ORE', 8, 3, true, 500, 'mine', 10, 1),
('material_gold_ore', 'Altın Cevheri', 'MATERIAL', 'Altın ve değerli eşyalar üretmek için kullanılır.', 'UNCOMMON', 'res://assets/sprites/items/ore_gold.png', 'ORE', 20, 10, true, 500, 'mine', 10, 5),
('material_silver_ore', 'Gümüş Cevheri', 'MATERIAL', 'Gümüş ve aksesuarlar üretmek için kullanılır.', 'UNCOMMON', 'res://assets/sprites/items/ore_silver.png', 'ORE', 15, 7, true, 500, 'mine', 10, 3),
('material_crystal', 'Kristal', 'MATERIAL', 'Büyü ve rün yapımında kullanılan değerli taş.', 'RARE', 'res://assets/sprites/items/crystal.png', 'CRYSTAL', 50, 25, true, 500, 'mine', 10, 7),
('material_diamond', 'Elmas', 'MATERIAL', 'En değerli efsanevi eşyalar yapılırken gerekli olan taş.', 'LEGENDARY', 'res://assets/sprites/items/diamond.png', 'GEM', 500, 250, true, 500, 'mine', 10, 10)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    type = EXCLUDED.type,
    description = EXCLUDED.description,
    rarity = EXCLUDED.rarity,
    icon = EXCLUDED.icon,
    material_type = EXCLUDED.material_type,
    base_price = EXCLUDED.base_price,
    vendor_sell_price = EXCLUDED.vendor_sell_price,
    is_stackable = EXCLUDED.is_stackable,
    max_stack = EXCLUDED.max_stack,
    production_building_type = EXCLUDED.production_building_type,
    production_rate_per_hour = EXCLUDED.production_rate_per_hour,
    production_required_level = EXCLUDED.production_required_level;

-- ============================================
-- PART 5: MATERIALS - WOOD (3 items)
-- ============================================

INSERT INTO public.items (
    id, name, type, description, rarity, icon, material_type,
    base_price, vendor_sell_price, is_stackable, max_stack,
    production_building_type, production_rate_per_hour, production_required_level
)
VALUES 
('material_wood', 'Kereste', 'MATERIAL', 'İnşaat ve üretim için kullanılır.', 'COMMON', 'res://assets/sprites/items/wood.png', 'WOOD', 3, 1, true, 500, 'sawmill', 15, 1),
('material_hardwood', 'Sert Kereste', 'MATERIAL', 'Dayanıklı kaliteli kereste. Güçlü eşyalar yapmak için gerekli.', 'UNCOMMON', 'res://assets/sprites/items/hardwood.png', 'WOOD', 10, 5, true, 500, 'sawmill', 15, 4),
('material_bamboo', 'Bambu', 'MATERIAL', 'Hafif ve esnek. Yaylar ve çubuklardan yapılır.', 'COMMON', 'res://assets/sprites/items/bamboo.png', 'WOOD', 5, 2, true, 500, 'sawmill', 15, 3)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    type = EXCLUDED.type,
    description = EXCLUDED.description,
    rarity = EXCLUDED.rarity,
    icon = EXCLUDED.icon,
    material_type = EXCLUDED.material_type,
    base_price = EXCLUDED.base_price,
    vendor_sell_price = EXCLUDED.vendor_sell_price,
    is_stackable = EXCLUDED.is_stackable,
    max_stack = EXCLUDED.max_stack,
    production_building_type = EXCLUDED.production_building_type,
    production_rate_per_hour = EXCLUDED.production_rate_per_hour,
    production_required_level = EXCLUDED.production_required_level;

-- ============================================
-- PART 6: MATERIALS - LEATHER (3 items)
-- ============================================

INSERT INTO public.items (
    id, name, type, description, rarity, icon, material_type,
    base_price, vendor_sell_price, is_stackable, max_stack,
    production_building_type, production_required_level
)
VALUES 
('material_leather', 'Deri', 'MATERIAL', 'Hayvan derisi. Zırh ve aksesuarlar yapımında kullanılır.', 'COMMON', 'res://assets/sprites/items/leather.png', 'LEATHER', 8, 4, true, 500, 'farm', 1),
('material_quality_leather', 'Kaliteli Deri', 'MATERIAL', 'Işlenmiş yüksek kaliteli deri. Ince zırh yapımında kullanılır.', 'RARE', 'res://assets/sprites/items/quality_leather.png', 'LEATHER', 40, 20, true, 500, 'farm', 5),
('material_wool', 'Yün', 'MATERIAL', 'Koyundan alınan yün. Kumaş eşyalar yapımında kullanılır.', 'COMMON', 'res://assets/sprites/items/wool.png', 'LEATHER', 6, 3, true, 500, 'farm', 2)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    type = EXCLUDED.type,
    description = EXCLUDED.description,
    rarity = EXCLUDED.rarity,
    icon = EXCLUDED.icon,
    material_type = EXCLUDED.material_type,
    base_price = EXCLUDED.base_price,
    vendor_sell_price = EXCLUDED.vendor_sell_price,
    is_stackable = EXCLUDED.is_stackable,
    max_stack = EXCLUDED.max_stack,
    production_building_type = EXCLUDED.production_building_type,
    production_required_level = EXCLUDED.production_required_level;

-- ============================================
-- PART 7: MATERIALS - HERBS (3 items)
-- ============================================

INSERT INTO public.items (
    id, name, type, description, rarity, icon, material_type,
    base_price, vendor_sell_price, is_stackable, max_stack,
    production_building_type, production_required_level
)
VALUES 
('material_herb', 'Tıbbi Ot', 'MATERIAL', 'İksir yapımında temel malzeme. Şifa ve buff potionları için gerekli.', 'COMMON', 'res://assets/sprites/items/herb.png', 'HERB', 5, 2, true, 500, 'herb_garden', 1),
('material_rare_herb', 'Nadir Ot', 'MATERIAL', 'Nadir ve kuvvetli bitki. Güçlü potion yapımında gereklidir.', 'EPIC', 'res://assets/sprites/items/rare_herb.png', 'HERB', 100, 50, true, 500, 'herb_garden', 5),
('material_dragon_blood', 'Ejderha Kanı', 'MATERIAL', 'Efsanevi gücü olan sıvı. En güçlü potion ve runeler için gereklidir.', 'LEGENDARY', 'res://assets/sprites/items/dragon_blood.png', 'HERB', 300, 150, true, 500, 'herb_garden', 10)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    type = EXCLUDED.type,
    description = EXCLUDED.description,
    rarity = EXCLUDED.rarity,
    icon = EXCLUDED.icon,
    material_type = EXCLUDED.material_type,
    base_price = EXCLUDED.base_price,
    vendor_sell_price = EXCLUDED.vendor_sell_price,
    is_stackable = EXCLUDED.is_stackable,
    max_stack = EXCLUDED.max_stack,
    production_building_type = EXCLUDED.production_building_type,
    production_required_level = EXCLUDED.production_required_level;

-- ============================================
-- PART 8: UPGRADE SCROLLS (3 items)
-- ============================================

INSERT INTO public.items (
    id, name, type, description, rarity, icon,
    base_price, vendor_sell_price, is_stackable, max_stack
)
VALUES 
('scroll_upgrade_low', 'Düşük Sınıf Yükseltme Kağıdı', 'SCROLL', 'Common ve Uncommon eşyaları yükseltmek için kullanılır.', 'UNCOMMON', 'res://assets/sprites/items/lowclassscroll.png', 500, 250, true, 50),
('scroll_upgrade_middle', 'Orta Sınıf Yükseltme Kağıdı', 'SCROLL', 'Rare ve Epic eşyaları yükseltmek için kullanılır.', 'RARE', 'res://assets/sprites/items/middleclassscroll.png', 2500, 1250, true, 50),
('scroll_upgrade_high', 'Yüksek Sınıf Yükseltme Kağıdı', 'SCROLL', 'Legendary ve Mythic eşyaları yükseltmek için kullanılır.', 'EPIC', 'res://assets/sprites/items/highclassscroll.png', 10000, 5000, true, 30)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    type = EXCLUDED.type,
    description = EXCLUDED.description,
    rarity = EXCLUDED.rarity,
    icon = EXCLUDED.icon,
    base_price = EXCLUDED.base_price,
    vendor_sell_price = EXCLUDED.vendor_sell_price,
    is_stackable = EXCLUDED.is_stackable,
    max_stack = EXCLUDED.max_stack;

-- ============================================
-- PART 9: RUNES (5 items)
-- ============================================

INSERT INTO public.items (
    id, name, type, description, rarity, icon,
    base_price, vendor_sell_price, is_stackable,
    rune_enhancement_type, rune_success_bonus, rune_destruction_reduction
)
VALUES 
('rune_attack_minor', 'Küçük Saldırı Rünü', 'RUNE', 'Geliştirme başarı oranını %5 artırır.', 'UNCOMMON', 'res://assets/sprites/items/rune_attack_minor.png', 200, 100, false, 'attack', 5.0, 2.0),
('rune_defense_minor', 'Küçük Savunma Rünü', 'RUNE', 'Zırh geliştirme başarı oranını %5 artırır.', 'UNCOMMON', 'res://assets/sprites/items/rune_defense_minor.png', 200, 100, false, 'defense', 5.0, 3.0),
('rune_attack_major', 'Büyük Saldırı Rünü', 'RUNE', 'Geliştirme başarı oranını %10 artırır.', 'RARE', 'res://assets/sprites/items/rune_attack_major.png', 800, 400, false, 'attack', 10.0, 5.0),
('rune_defense_major', 'Büyük Savunma Rünü', 'RUNE', 'Zırh geliştirme başarı oranını %10 artırır.', 'RARE', 'res://assets/sprites/items/rune_defense_major.png', 800, 400, false, 'defense', 10.0, 7.0),
('rune_legendary', 'Efsanevi Rüne', 'RUNE', 'Tüm geliştirme işlemlerine %15 başarı ve %5 hasar azaltma bonus verir.', 'LEGENDARY', 'res://assets/sprites/items/rune_legendary.png', 5000, 2500, false, 'all', 15.0, 10.0)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    type = EXCLUDED.type,
    description = EXCLUDED.description,
    rarity = EXCLUDED.rarity,
    icon = EXCLUDED.icon,
    base_price = EXCLUDED.base_price,
    vendor_sell_price = EXCLUDED.vendor_sell_price,
    is_stackable = EXCLUDED.is_stackable,
    rune_enhancement_type = EXCLUDED.rune_enhancement_type,
    rune_success_bonus = EXCLUDED.rune_success_bonus,
    rune_destruction_reduction = EXCLUDED.rune_destruction_reduction;

-- ============================================
-- PART 10: GEMS (3 items)
-- ============================================

INSERT INTO public.items (
    id, name, type, description, rarity, icon, material_type,
    equip_slot, base_price, vendor_sell_price, is_stackable,
    attack, defense, health
)
VALUES 
('gem_ruby', 'Yakut', 'MATERIAL', 'Kırmızı taş. Saldırı gücü +10 verir.', 'RARE', 'res://assets/sprites/items/gem_ruby.png', 'GEM', 'ACCESSORY', 300, 150, false, 10, 0, 0),
('gem_sapphire', 'Safir', 'MATERIAL', 'Mavi taş. Savunma +15 verir.', 'EPIC', 'res://assets/sprites/items/gem_sapphire.png', 'GEM', 'ACCESSORY', 600, 300, false, 0, 15, 0),
('gem_emerald', 'Zümrüt', 'MATERIAL', 'Yeşil taş. Can sağlığı +50 verir.', 'LEGENDARY', 'res://assets/sprites/items/gem_emerald.png', 'GEM', 'ACCESSORY', 1500, 750, false, 0, 0, 50)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    type = EXCLUDED.type,
    description = EXCLUDED.description,
    rarity = EXCLUDED.rarity,
    icon = EXCLUDED.icon,
    material_type = EXCLUDED.material_type,
    equip_slot = EXCLUDED.equip_slot,
    base_price = EXCLUDED.base_price,
    vendor_sell_price = EXCLUDED.vendor_sell_price,
    is_stackable = EXCLUDED.is_stackable,
    attack = EXCLUDED.attack,
    defense = EXCLUDED.defense,
    health = EXCLUDED.health;

-- ============================================
-- PART 11: COSMETICS (1 item)
-- ============================================

INSERT INTO public.items (
    id, name, type, description, rarity, icon,
    base_price, is_tradeable, cosmetic_effect, cosmetic_bind_on_pickup, cosmetic_showcase_only
)
VALUES 
('cosmetic_crown_gold', 'Altın Taç', 'COSMETIC', 'Altın taç efekti. Sadece gösterim amaçlı.', 'EPIC', 'res://assets/sprites/items/crown_gold.png', 5000, false, 'golden_crown', true, false)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    type = EXCLUDED.type,
    description = EXCLUDED.description,
    rarity = EXCLUDED.rarity,
    icon = EXCLUDED.icon,
    base_price = EXCLUDED.base_price,
    is_tradeable = EXCLUDED.is_tradeable,
    cosmetic_effect = EXCLUDED.cosmetic_effect,
    cosmetic_bind_on_pickup = EXCLUDED.cosmetic_bind_on_pickup,
    cosmetic_showcase_only = EXCLUDED.cosmetic_showcase_only;

-- ============================================
-- PART 12: RECIPES (1 item - template)
-- ============================================

INSERT INTO public.items (
    id, name, type, description, rarity, icon,
    base_price, recipe_result_item_id, recipe_building_type,
    recipe_production_time, recipe_required_level
)
VALUES 
('recipe_sword_basic', 'Demir Kılıç Tarifi', 'RECIPE', 'Demir kılıç üretme tarifi.', 'COMMON', 'res://assets/sprites/items/recipe_sword.png', 50, 'weapon_sword_basic', 'blacksmith', 300, 1)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    type = EXCLUDED.type,
    description = EXCLUDED.description,
    rarity = EXCLUDED.rarity,
    icon = EXCLUDED.icon,
    base_price = EXCLUDED.base_price,
    recipe_result_item_id = EXCLUDED.recipe_result_item_id,
    recipe_building_type = EXCLUDED.recipe_building_type,
    recipe_production_time = EXCLUDED.recipe_production_time,
    recipe_required_level = EXCLUDED.recipe_required_level;

-- ============================================
-- SUMMARY
-- ============================================
-- Total items added/updated: 39
-- 
-- Breakdown:
-- - Weapons: 6 items
-- - Armor: 5 items  
-- - Potions: 5 items
-- - Materials (Ore): 6 items
-- - Materials (Wood): 3 items
-- - Materials (Leather): 3 items
-- - Materials (Herbs): 3 items
-- - Scrolls: 3 items
-- - Runes: 5 items
-- - Gems: 3 items
-- - Cosmetics: 1 item
-- - Recipes: 1 item
-- ============================================
