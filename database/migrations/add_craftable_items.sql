-- ============================================
-- CRAFTING SYSTEM: CRAFTING RECIPES (Part 1)
-- ============================================
-- This migration adds crafting recipes for weapons, armor, potions, runes, and scrolls
-- All recipes are used in the CRAFTING/SIMYA screen, NOT in facilities

-- 0. ENSURE COLUMNS EXIST (Runes)
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS rune_enhancement_type text;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS rune_success_bonus double precision DEFAULT 0.0;
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS rune_destruction_reduction double precision DEFAULT 0.0;

-- First, let's add the craftable items themselves
-- ============================================
-- CRAFTABLE ITEMS: WEAPONS
-- ============================================

-- COMMON Weapons (Level 1-5)
INSERT INTO public.items (id, name, type, description, rarity, icon, equip_slot, weapon_type, attack, defense, health, power, can_enhance, max_enhancement, required_level, base_price, is_stackable, is_tradeable, max_stack)
VALUES 
('weapon_sword_basic', 'Basit Kılıç', 'WEAPON', 'Demir ve meşe ağacından yapılmış sade bir kılıç.', 'COMMON', 'res://assets/icons/weapons/sword_basic.png', 'WEAPON', 'SWORD', 15, 0, 0, 0, true, 10, 1, 100, false, true, 1),
('weapon_spear_basic', 'Basit Mızrak', 'WEAPON', 'Uzun menzilli basit mızrak.', 'COMMON', 'res://assets/icons/weapons/spear_basic.png', 'WEAPON', 'SPEAR', 12, 5, 0, 0, true, 10, 1, 90, false, true, 1),
('weapon_bow_basic', 'Basit Yay', 'WEAPON', 'Meşe ağacından yapılmış sağlam yay.', 'COMMON', 'res://assets/icons/weapons/bow_basic.png', 'WEAPON', 'BOW', 18, 0, 0, 0, true, 10, 1, 110, false, true, 1),
('weapon_axe_basic', 'Basit Balta', 'WEAPON', 'Ağır ve güçlü demir balta.', 'COMMON', 'res://assets/icons/weapons/axe_basic.png', 'WEAPON', 'AXE', 20, -5, 0, 0, true, 10, 1, 95, false, true, 1),
('weapon_dagger_basic', 'Basit Hançer', 'WEAPON', 'Küçük ve hızlı hançer.', 'COMMON', 'res://assets/icons/weapons/dagger_basic.png', 'WEAPON', 'DAGGER', 10, 0, 0, 10, true, 10, 1, 80, false, true, 1)
ON CONFLICT (id) DO NOTHING;

-- UNCOMMON Weapons (Level 6-10)
INSERT INTO public.items (id, name, type, description, rarity, icon, equip_slot, weapon_type, attack, defense, health, power, can_enhance, max_enhancement, required_level, base_price, is_stackable, is_tradeable, max_stack)
VALUES 
('weapon_sword_steel', 'Çelik Kılıç', 'WEAPON', 'Kaliteli çelikten dövülmüş keskin kılıç.', 'UNCOMMON', 'res://assets/icons/weapons/sword_steel.png', 'WEAPON', 'SWORD', 30, 0, 0, 5, true, 10, 6, 500, false, true, 1),
('weapon_spear_dragon', 'Ejderha Mızrağı', 'WEAPON', 'Ejderha kökü saplı mistik mızrak.', 'UNCOMMON', 'res://assets/icons/weapons/spear_dragon.png', 'WEAPON', 'SPEAR', 40, 15, 0, 10, true, 10, 8, 800, false, true, 1),
('weapon_staff_magic', 'Büyülü Asa', 'WEAPON', 'Mana kristali ile süslenmiş kadim ağaç asası.', 'UNCOMMON', 'res://assets/icons/weapons/staff_magic.png', 'WEAPON', 'STAFF', 10, 0, 20, 50, true, 10, 7, 750, false, true, 1)
ON CONFLICT (id) DO NOTHING;

-- RARE+ Weapons (Level 11+)
INSERT INTO public.items (id, name, type, description, rarity, icon, equip_slot, weapon_type, attack, defense, health, power, can_enhance, max_enhancement, required_level, base_price, is_stackable, is_tradeable, max_stack)
VALUES 
('weapon_sword_mithril', 'Mithril Kılıç', 'WEAPON', 'Efsanevi mithril metalinden işlenmiş kılıç.', 'RARE', 'res://assets/icons/weapons/sword_mithril.png', 'WEAPON', 'SWORD', 80, 0, 50, 30, true, 10, 11, 5000, false, true, 1),
('weapon_axe_divine', 'İlahi Balta', 'WEAPON', 'Tanrıların kutsadığı kutsal balta.', 'EPIC', 'res://assets/icons/weapons/axe_divine.png', 'WEAPON', 'AXE', 120, 40, 60, 60, true, 10, 15, 15000, false, true, 1)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- CRAFTABLE ITEMS: ARMOR
-- ============================================

-- COMMON Armor
INSERT INTO public.items (id, name, type, description, rarity, icon, equip_slot, armor_type, attack, defense, health, power, can_enhance, max_enhancement, required_level, base_price, is_stackable, is_tradeable, max_stack)
VALUES 
('armor_leather_chest', 'Deri Zırh', 'ARMOR', 'Yumuşak ve esnek deri zırh.', 'COMMON', 'res://assets/icons/armor/leather_chest.png', 'CHEST', 'LEATHER', 0, 20, 10, 0, true, 10, 1, 120, false, true, 1),
('armor_chain_chest', 'Zincir Zırh', 'ARMOR', 'Demir zincirlerden örülmüş koruyucu zırh.', 'COMMON', 'res://assets/icons/armor/chain_chest.png', 'CHEST', 'CHAIN', 0, 35, 15, 0, true, 10, 3, 200, false, true, 1)
ON CONFLICT (id) DO NOTHING;

-- UNCOMMON Armor
INSERT INTO public.items (id, name, type, description, rarity, icon, equip_slot, armor_type, attack, defense, health, power, can_enhance, max_enhancement, required_level, base_price, is_stackable, is_tradeable, max_stack)
VALUES 
('armor_plate_steel', 'Çelik Plaka Zırh', 'ARMOR', 'Kalın çelik levhalardan yapılmış ağır zırh.', 'UNCOMMON', 'res://assets/icons/armor/plate_steel.png', 'CHEST', 'PLATE', 0, 60, 30, 10, true, 10, 6, 1000, false, true, 1),
('armor_cloth_magical', 'Büyülü Kaftan', 'ARMOR', 'Mana ile dokunan mistik kumaş zırh.', 'UNCOMMON', 'res://assets/icons/armor/cloth_magical.png', 'CHEST', 'CLOTH', 0, 25, 40, 80, true, 10, 8, 900, false, true, 1)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- CRAFTABLE ITEMS: POTIONS
-- ============================================

-- Energy Potions
INSERT INTO public.items (id, name, type, description, rarity, icon, potion_type, energy_restore, tolerance_increase, overdose_risk, can_enhance, base_price, is_stackable, is_tradeable, max_stack)
VALUES 
('potion_energy_small', 'Basit Enerji İksiri', 'POTION', 'Enerji yenileyen basit iksir.', 'COMMON', 'res://assets/icons/potions/energy_small.png', 'ENERGY', 50, 5, 0.0, false, 50, true, false, 50),
('potion_energy_large', 'Güçlü Enerji İksiri', 'POTION', 'Yüksek enerji veren güçlü iksir.', 'UNCOMMON', 'res://assets/icons/potions/energy_large.png', 'ENERGY', 150, 15, 0.1, false, 300, true, false, 50),
('potion_energy_master', 'Usta Enerji İksiri', 'POTION', 'Efsanevi enerji iksiri. Bağımlılık riski yüksek!', 'RARE', 'res://assets/icons/potions/energy_master.png', 'ENERGY', 300, 25, 0.2, false, 1500, true, false, 50)
ON CONFLICT (id) DO NOTHING;

-- Health Potions
INSERT INTO public.items (id, name, type, description, rarity, icon, potion_type, heal_amount, can_enhance, base_price, is_stackable, is_tradeable, max_stack)
VALUES 
('potion_health_small', 'Basit Can İksiri', 'POTION', 'Can yenileyen basit iksir.', 'COMMON', 'res://assets/icons/potions/health_small.png', 'HEALING', 100, false, 40, true, false, 50),
('potion_health_large', 'Büyük Can İksiri', 'POTION', 'Güçlü iyileştirme iksiri.', 'UNCOMMON', 'res://assets/icons/potions/health_large.png', 'HEALING', 500, false, 250, true, false, 50)
ON CONFLICT (id) DO NOTHING;

-- Buff Potions
INSERT INTO public.items (id, name, type, description, rarity, icon, potion_type, can_enhance, base_price, is_stackable, is_tradeable, max_stack)
VALUES 
('potion_buff_power', 'Güç İksiri', 'POTION', '30 dakika boyunca +50% güç verir.', 'UNCOMMON', 'res://assets/icons/potions/buff_power.png', 'BUFF', false, 400, true, false, 50),
('potion_buff_defense', 'Zırh İksiri', 'POTION', '30 dakika boyunca +50% savunma verir.', 'UNCOMMON', 'res://assets/icons/potions/buff_defense.png', 'BUFF', false, 400, true, false, 50),
('potion_antidote', 'Arınma İksiri', 'POTION', 'Bağımlılığı azaltır. -50 Tolerance.', 'RARE', 'res://assets/icons/potions/antidote.png', 'ANTIDOTE', false, 2000, true, false, 50)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- CRAFTABLE ITEMS: RUNES & SCROLLS
-- ============================================

-- Runes
INSERT INTO public.items (id, name, type, description, rarity, icon, rune_enhancement_type, rune_success_bonus, rune_destruction_reduction, can_enhance, base_price, is_stackable, is_tradeable, max_stack)
VALUES 
('rune_attack_1', 'Saldırı Rünü I', 'RUNE', 'Saldırı itemlerinin geliştirme başarısını artırır.', 'COMMON', 'res://assets/icons/runes/attack_1.png', 'attack', 10.0, 0.0, false, 200, true, true, 50),
('rune_defense_1', 'Savunma Rünü I', 'RUNE', 'Savunma itemlerinin geliştirme başarısını artırır.', 'COMMON', 'res://assets/icons/runes/defense_1.png', 'defense', 10.0, 0.0, false, 200, true, true, 50),
('rune_power_ancient', 'Kadim Güç Rünü', 'RUNE', 'Yüksek başarı oranı ve düşük yok olma riski.', 'RARE', 'res://assets/icons/runes/power_ancient.png', 'power', 25.0, 10.0, false, 3000, true, true, 50)
ON CONFLICT (id) DO NOTHING;

-- Scrolls (aligned with BlacksmithScreen.gd rarity-based system)
INSERT INTO public.items (id, name, type, description, rarity, icon, can_enhance, base_price, is_stackable, is_tradeable, max_stack)
VALUES 
('scroll_upgrade_low', 'Basit Geliştirme Parşömeni', 'SCROLL', 'COMMON ve UNCOMMON rarity itemleri yükseltir.', 'COMMON', 'res://assets/icons/scrolls/upgrade_low.png', false, 150, true, true, 50),
('scroll_upgrade_middle', 'Orta Geliştirme Parşömeni', 'SCROLL', 'RARE ve EPIC rarity itemleri yükseltir.', 'UNCOMMON', 'res://assets/icons/scrolls/upgrade_middle.png', false, 500, true, true, 50),
('scroll_upgrade_high', 'Gelişmiş Geliştirme Parşömeni', 'SCROLL', 'LEGENDARY ve MYTHIC rarity itemleri yükseltir.', 'RARE', 'res://assets/icons/scrolls/upgrade_high.png', false, 2000, true, true, 50)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- CRAFTABLE ITEMS: ACCESSORIES
-- ============================================

INSERT INTO public.items (id, name, type, description, rarity, icon, equip_slot, attack, defense, health, power, can_enhance, max_enhancement, required_level, base_price, is_stackable, is_tradeable, max_stack)
VALUES 
('accessory_ring_power', 'Güç Yüzüğü', 'ACCESSORY', 'Altın ve mana kristalinden yapılmış güç veren yüzük.', 'UNCOMMON', 'res://assets/icons/accessories/ring_power.png', 'ACCESSORY', 0, 0, 0, 30, true, 10, 6, 600, false, true, 1),
('accessory_necklace_dragon', 'Ejderha Kolyesi', 'ACCESSORY', 'Ejderha pullarıyla süslenmiş efsanevi kolye.', 'RARE', 'res://assets/icons/accessories/necklace_dragon.png', 'ACCESSORY', 50, 50, 0, 100, true, 10, 12, 8000, false, true, 1)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
DO $$
BEGIN
    RAISE NOTICE 'Craftable items migration completed successfully!';
    RAISE NOTICE 'Items added: Weapons (10), Armor (4), Potions (9), Runes (3), Scrolls (3), Accessories (2)';
    RAISE NOTICE 'Total craftable items: 31';
END $$;
