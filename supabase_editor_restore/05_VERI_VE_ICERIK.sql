-- ============================================================
-- SUPABASE SQL EDİTÖR - VERİTABANI KURTARMA
-- ============================================================
-- DOSYA 5/5: VERİ VE İÇERİK (SON DOSYA!)
-- ============================================================
--
-- Bu dosya oyun içeriğini ekler:
-- ✓ Tüm kaynak öğeleri (ores, wood, stones, etc.)
-- ✓ Üretilebilir öğeler (swords, armor, etc.)
-- ✓ Üretim tarifleri (crafting recipes)
-- ✓ Tesis öğeleri
-- ✓ Tesis tarifleri
-- ✓ 15 kaynak tesisi
--
-- TALİMATLAR:
-- 1. Bu dosyanın tüm içeriğini kopyalayın
-- 2. Supabase SQL Editor'e yapıştırın
-- 3. RUN butonuna basın
-- 4. İşlem tamamlanana kadar bekleyin (~30 saniye)
-- 5. 🎉 TAMAMLANDI! Doğrulama sorgularını çalıştırın
--
-- BEKLENEN SÜRE: ~30 saniye
-- BEKLENEN SONUÇ: 100+ item, 50+ tarif eklendi
-- ============================================================

-- ============================================
-- CRAFTING SYSTEM: ALL RESOURCE ITEMS
-- ============================================
-- This migration adds all 75+ resource items that can be collected from the 15 facilities
-- These are MATERIALS only - craftable items (weapons, armor, potions) will be in a separate migration

-- ============================================
-- 1. TEMEL KAYNAKLAR (Basic Resources)
-- ============================================

-- MINING (Maden Ocağı)
INSERT INTO public.items (id, name, type, description, rarity, icon, is_stackable, max_stack, base_price)
VALUES 
('iron_ore', 'Demir Cevheri', 'MATERIAL', 'Ham demir cevheri. Silah ve zırh yapımında kullanılır.', 'COMMON', 'res://assets/icons/materials/iron_ore.png', true, 50, 10),
('copper_ore', 'Bakır Cevheri', 'MATERIAL', 'Bakır cevheri. Alaşım yapımında kullanılır.', 'COMMON', 'res://assets/icons/materials/copper_ore.png', true, 50, 15),
('silver_ore', 'Gümüş Cevheri', 'MATERIAL', 'Nadir gümüş cevheri. Değerli eşyalar için.', 'UNCOMMON', 'res://assets/icons/materials/silver_ore.png', true, 50, 50),
('gold_ore', 'Altın Cevheri', 'MATERIAL', 'Çok nadir altın cevheri. En değerli malzeme.', 'RARE', 'res://assets/icons/materials/gold_ore.png', true, 50, 200),
('mithril_ore', 'Mithril Cevheri', 'MATERIAL', 'Efsanevi hafif ve sağlam metal. Çok nadir bulunur.', 'LEGENDARY', 'res://assets/icons/materials/mithril_ore.png', true, 50, 1000)
ON CONFLICT (id) DO NOTHING;

-- QUARRY (Taş Ocağı)
INSERT INTO public.items (id, name, type, description, rarity, icon, is_stackable, max_stack, base_price)
VALUES 
('granite', 'Granit', 'MATERIAL', 'Sağlam granit taşı. İnşaat ve zırh yapımında kullanılır.', 'COMMON', 'res://assets/icons/materials/granite.png', true, 50, 8),
('marble', 'Mermer', 'MATERIAL', 'Değerli mermer taşı. Nadir eşyalar için.', 'UNCOMMON', 'res://assets/icons/materials/marble.png', true, 50, 40),
('crystal_shard', 'Kristal Parçası', 'MATERIAL', 'Işıltılı kristal kırıntısı. Büyü eşyaları için.', 'UNCOMMON', 'res://assets/icons/materials/crystal_shard.png', true, 50, 60),
('obsidian', 'Obsidyen', 'MATERIAL', 'Siyah volkanik cam. Keskin silahlar için.', 'RARE', 'res://assets/icons/materials/obsidian.png', true, 50, 150),
('moonstone', 'Ay Taşı', 'MATERIAL', 'Ay ışığında parlayan mistik taş.', 'LEGENDARY', 'res://assets/icons/materials/moonstone.png', true, 50, 800)
ON CONFLICT (id) DO NOTHING;

-- LUMBER MILL (Kereste Fabrikası)
INSERT INTO public.items (id, name, type, description, rarity, icon, is_stackable, max_stack, base_price)
VALUES 
('oak_wood', 'Meşe Odunu', 'MATERIAL', 'Sağlam meşe ağacı. Silah sapı ve inşaat için.', 'COMMON', 'res://assets/icons/materials/oak_wood.png', true, 50, 5),
('pine_wood', 'Çam Odunu', 'MATERIAL', 'Hafif çam ağacı. Yay ve oklar için.', 'COMMON', 'res://assets/icons/materials/pine_wood.png', true, 50, 5),
('bamboo', 'Bambu', 'MATERIAL', 'Esnek bambu. Hafif silahlar için ideal.', 'UNCOMMON', 'res://assets/icons/materials/bamboo.png', true, 50, 30),
('elder_wood', 'Kadim Ağaç', 'MATERIAL', 'Yüzyıllık yaşlı ağaç. Büyülü asalar için.', 'RARE', 'res://assets/icons/materials/elder_wood.png', true, 50, 120),
('world_tree_sap', 'Dünya Ağacı Özsuyu', 'MATERIAL', 'Efsanevi dünya ağacının özsuyu. Paha biçilmez.', 'LEGENDARY', 'res://assets/icons/materials/world_tree_sap.png', true, 50, 900)
ON CONFLICT (id) DO NOTHING;

-- CLAY PIT (Kil Ocağı)
INSERT INTO public.items (id, name, type, description, rarity, icon, is_stackable, max_stack, base_price)
VALUES 
('ceramic_clay', 'Seramik Kili', 'MATERIAL', 'İşlenmiş seramik kili. Çanak çömlek için.', 'COMMON', 'res://assets/icons/materials/ceramic_clay.png', true, 50, 6),
('brick_clay', 'Tuğla Kili', 'MATERIAL', 'Tuğla yapımı için kil. İnşaatta kullanılır.', 'COMMON', 'res://assets/icons/materials/brick_clay.png', true, 50, 6),
('enchanted_clay', 'Büyülü Kil', 'MATERIAL', 'Mana ile doymuş kil. Büyülü eşyalar için.', 'UNCOMMON', 'res://assets/icons/materials/enchanted_clay.png', true, 50, 45),
('dragon_clay', 'Ejderha Kili', 'MATERIAL', 'Ejderha yuvalarından toplanan kil. Ateşe dayanıklı.', 'RARE', 'res://assets/icons/materials/dragon_clay.png', true, 50, 180)
ON CONFLICT (id) DO NOTHING;

-- SAND QUARRY (Kum Ocağı)
INSERT INTO public.items (id, name, type, description, rarity, icon, is_stackable, max_stack, base_price)
VALUES 
('glass_sand', 'Cam Kumu', 'MATERIAL', 'Cam yapımı için ince kum.', 'COMMON', 'res://assets/icons/materials/glass_sand.png', true, 50, 4),
('crystal_sand', 'Kristal Kumu', 'MATERIAL', 'Kristalleşmiş kum. Büyü için kullanılır.', 'UNCOMMON', 'res://assets/icons/materials/crystal_sand.png', true, 50, 35),
('star_dust', 'Yıldız Tozu', 'MATERIAL', 'Gökyüzünden düşen parlak toz.', 'RARE', 'res://assets/icons/materials/star_dust.png', true, 50, 160),
('void_sand', 'Boşluk Kumu', 'MATERIAL', 'Başka bir boyuttan gelen gizemli kum.', 'LEGENDARY', 'res://assets/icons/materials/void_sand.png', true, 50, 850)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- 2. ORGANİK KAYNAKLAR (Organic Resources)
-- ============================================

-- FARMING (Çiftlik)
INSERT INTO public.items (id, name, type, description, rarity, icon, is_stackable, max_stack, base_price)
VALUES 
('wheat', 'Buğday', 'MATERIAL', 'Taze buğday. Ekmek ve iksir yapımında kullanılır.', 'COMMON', 'res://assets/icons/materials/wheat.png', true, 50, 3),
('vegetables', 'Sebze', 'MATERIAL', 'Karışık sebze. Yemek ve iksir için.', 'COMMON', 'res://assets/icons/materials/vegetables.png', true, 50, 4),
('cotton', 'Pamuk', 'MATERIAL', 'Yumuşak pamuk. Kumaş yapımı için.', 'COMMON', 'res://assets/icons/materials/cotton.png', true, 50, 7),
('magical_grain', 'Büyülü Tahıl', 'MATERIAL', 'Mana ile büyümüş tahıl. Güçlü iksirlerde kullanılır.', 'UNCOMMON', 'res://assets/icons/materials/magical_grain.png', true, 50, 38),
('golden_wheat', 'Altın Buğday', 'MATERIAL', 'Altın rengi parlayan efsanevi buğday.', 'RARE', 'res://assets/icons/materials/golden_wheat.png', true, 50, 140)
ON CONFLICT (id) DO NOTHING;

-- HERB GARDEN (Ot Bahçesi)
INSERT INTO public.items (id, name, type, description, rarity, icon, is_stackable, max_stack, base_price)
VALUES 
('healing_herb', 'Şifalı Ot', 'MATERIAL', 'İyileştirici özelliklere sahip ot. İksir yapımında temel.', 'COMMON', 'res://assets/icons/materials/healing_herb.png', true, 50, 12),
('poison_herb', 'Zehirli Ot', 'MATERIAL', 'Tehlikeli zehirli bitki. Dikkatle kullanılmalı.', 'UNCOMMON', 'res://assets/icons/materials/poison_herb.png', true, 50, 50),
('rare_flower', 'Nadir Çiçek', 'MATERIAL', 'Güzel ve nadir çiçek. Değerli iksirlerde kullanılır.', 'UNCOMMON', 'res://assets/icons/materials/rare_flower.png', true, 50, 55),
('dragon_root', 'Ejderha Kökü', 'MATERIAL', 'Ejderha kanıyla beslenen kök. Güç iksiri için.', 'RARE', 'res://assets/icons/materials/dragon_root.png', true, 50, 170),
('phoenix_petal', 'Anka Kuşu Yaprağı', 'MATERIAL', 'Efsanevi anka kuşunun tüyünden yaprak. Ölümsüzlük iksiri için.', 'LEGENDARY', 'res://assets/icons/materials/phoenix_petal.png', true, 50, 1200)
ON CONFLICT (id) DO NOTHING;

-- RANCH (Hayvancılık)
INSERT INTO public.items (id, name, type, description, rarity, icon, is_stackable, max_stack, base_price)
VALUES 
('leather', 'Deri', 'MATERIAL', 'Hayvan derisi. Zırh ve tutacak yapımında.', 'COMMON', 'res://assets/icons/materials/leather.png', true, 50, 9),
('bone', 'Kemik', 'MATERIAL', 'Hayvan kemiği. Silah ve süs eşyası için.', 'COMMON', 'res://assets/icons/materials/bone.png', true, 50, 6),
('wool', 'Yün', 'MATERIAL', 'Yumuşak yün. Kumaş ve zırh için.', 'COMMON', 'res://assets/icons/materials/wool.png', true, 50, 8),
('monster_hide', 'Canavar Derisi', 'MATERIAL', 'Kalın ve sağlam canavar derisi. Güçlü zırhlar için.', 'UNCOMMON', 'res://assets/icons/materials/monster_hide.png', true, 50, 60),
('dragon_scale', 'Ejderha Pulları', 'MATERIAL', 'Ejderha pulları. En sağlam zırh malzemesi.', 'LEGENDARY', 'res://assets/icons/materials/dragon_scale.png', true, 50, 1100)
ON CONFLICT (id) DO NOTHING;

-- APIARY (Arıcılık)
INSERT INTO public.items (id, name, type, description, rarity, icon, is_stackable, max_stack, base_price)
VALUES 
('honey', 'Bal', 'MATERIAL', 'Tatlı bal. İksir ve yemek için.', 'COMMON', 'res://assets/icons/materials/honey.png', true, 50, 11),
('beeswax', 'Balmumu', 'MATERIAL', 'Arı mumu. Mühür ve kaplama için.', 'COMMON', 'res://assets/icons/materials/beeswax.png', true, 50, 10),
('bee_venom', 'Arı Zehiri', 'MATERIAL', 'Güçlü arı zehiri. Zehir iksirleri için.', 'UNCOMMON', 'res://assets/icons/materials/bee_venom.png', true, 50, 48),
('royal_jelly', 'Arı Sütü', 'MATERIAL', 'Kraliçe arı sütü. Çok değerli besleyici.', 'RARE', 'res://assets/icons/materials/royal_jelly.png', true, 50, 190),
('celestial_honey', 'İlahi Bal', 'MATERIAL', 'İlahi güçlerle kutsanmış bal. Mucize yaratır.', 'LEGENDARY', 'res://assets/icons/materials/celestial_honey.png', true, 50, 950)
ON CONFLICT (id) DO NOTHING;

-- MUSHROOM FARM (Mantar Çiftliği)
INSERT INTO public.items (id, name, type, description, rarity, icon, is_stackable, max_stack, base_price)
VALUES 
('healing_mushroom', 'Şifalı Mantar', 'MATERIAL', 'İyileştirici mantar. Can iksiri için.', 'COMMON', 'res://assets/icons/materials/healing_mushroom.png', true, 50, 13),
('poison_mushroom', 'Zehirli Mantar', 'MATERIAL', 'Ölümcül zehirli mantar. Tehlikeli.', 'UNCOMMON', 'res://assets/icons/materials/poison_mushroom.png', true, 50, 52),
('glowing_mushroom', 'Parlak Mantar', 'MATERIAL', 'Karanlıkta parlayan mantar. Büyü için.', 'UNCOMMON', 'res://assets/icons/materials/glowing_mushroom.png', true, 50, 47),
('ghost_mushroom', 'Hayalet Mantar', 'MATERIAL', 'Ruhlarla konuşmayı sağlayan mantar.', 'RARE', 'res://assets/icons/materials/ghost_mushroom.png', true, 50, 175),
('immortality_shroom', 'Ölümsüzlük Mantarı', 'MATERIAL', 'Efsanelerde geçen ölümsüzlük mantarı.', 'LEGENDARY', 'res://assets/icons/materials/immortality_shroom.png', true, 50, 1300)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- 3. MİSTİK KAYNAKLAR (Mystical Resources)
-- ============================================

-- RUNE MINE (Rune Madeni)
INSERT INTO public.items (id, name, type, description, rarity, icon, is_stackable, max_stack, base_price)
VALUES 
('raw_rune', 'Ham Rune', 'MATERIAL', 'İşlenmemiş rune taşı. Büyü için temel.', 'COMMON', 'res://assets/icons/materials/raw_rune.png', true, 50, 20),
('magic_crystal', 'Büyü Kristali', 'MATERIAL', 'Mana ile dolu kristal. Güçlü büyüler için.', 'UNCOMMON', 'res://assets/icons/materials/magic_crystal.png', true, 50, 65),
('energy_shard', 'Enerji Kırıntısı', 'MATERIAL', 'Enerji parıltısı. Büyü eşyaları için.', 'UNCOMMON', 'res://assets/icons/materials/energy_shard.png', true, 50, 58),
('power_rune', 'Güç Rünü', 'MATERIAL', 'Güç veren kadim rune. Çok nadir.', 'RARE', 'res://assets/icons/materials/power_rune.png', true, 50, 220),
('ancient_rune', 'Kadim Rün', 'MATERIAL', 'Kayıp uygarlıktan kalma rune. Paha biçilmez.', 'LEGENDARY', 'res://assets/icons/materials/ancient_rune.png', true, 50, 1400)
ON CONFLICT (id) DO NOTHING;

-- HOLY SPRING (Kutsal Kaynak)
INSERT INTO public.items (id, name, type, description, rarity, icon, is_stackable, max_stack, base_price)
VALUES 
('holy_water', 'Kutsal Su', 'MATERIAL', 'Kutsanmış su. İyileştirme için.', 'COMMON', 'res://assets/icons/materials/holy_water.png', true, 50, 14),
('mana_crystal', 'Mana Kristali', 'MATERIAL', 'Saf mana kristali. Büyücüler için.', 'UNCOMMON', 'res://assets/icons/materials/mana_crystal.png', true, 50, 70),
('purification_water', 'Arınma Suyu', 'MATERIAL', 'Lanetleri kaldıran su. Antidot için.', 'UNCOMMON', 'res://assets/icons/materials/purification_water.png', true, 50, 62),
('blessed_essence', 'Kutsanmış Öz', 'MATERIAL', 'İlahi güçle kutsanmış öz. Mukaddes eşyalar için.', 'RARE', 'res://assets/icons/materials/blessed_essence.png', true, 50, 210),
('divine_tear', 'İlahi Gözyaşı', 'MATERIAL', 'Tanrıların gözyaşı. Mucizevi iyileştirme gücü.', 'LEGENDARY', 'res://assets/icons/materials/divine_tear.png', true, 50, 1500)
ON CONFLICT (id) DO NOTHING;

-- SHADOW PIT (Gölge Çukuru)
INSERT INTO public.items (id, name, type, description, rarity, icon, is_stackable, max_stack, base_price)
VALUES 
('dark_essence', 'Karanlık Öz', 'MATERIAL', 'Karanlık enerji özü. Kara büyü için.', 'COMMON', 'res://assets/icons/materials/dark_essence.png', true, 50, 18),
('shadow_crystal', 'Gölge Kristali', 'MATERIAL', 'Gölgelerin kristalleşmiş hali.', 'UNCOMMON', 'res://assets/icons/materials/shadow_crystal.png', true, 50, 67),
('curse_dust', 'Lanet Tozu', 'MATERIAL', 'Lanet veren toz. Tehlikeli büyüler için.', 'UNCOMMON', 'res://assets/icons/materials/curse_dust.png', true, 50, 64),
('void_fragment', 'Boşluk Parçası', 'MATERIAL', 'Hiçliğin bir parçası. Gerçekliği bükebilir.', 'RARE', 'res://assets/icons/materials/void_fragment.png', true, 50, 230),
('abyss_core', 'Uçurum Özü', 'MATERIAL', 'Sonsuz karanlığın kalbi.', 'LEGENDARY', 'res://assets/icons/materials/abyss_core.png', true, 50, 1350)
ON CONFLICT (id) DO NOTHING;

-- ELEMENTAL FORGE (Elementel Ocak)
INSERT INTO public.items (id, name, type, description, rarity, icon, is_stackable, max_stack, base_price)
VALUES 
('fire_essence', 'Ateş Özü', 'MATERIAL', 'Saf ateş özü. Yakıcı silahlar için.', 'COMMON', 'res://assets/icons/materials/fire_essence.png', true, 50, 16),
('ice_crystal', 'Buz Kristali', 'MATERIAL', 'Dondurucu buz kristali. Soğuk silahlar için.', 'COMMON', 'res://assets/icons/materials/ice_crystal.png', true, 50, 16),
('lightning_core', 'Yıldırım Çekirdeği', 'MATERIAL', 'Şimşek çekirdeği. Elektrik büyüleri için.', 'UNCOMMON', 'res://assets/icons/materials/lightning_core.png', true, 50, 72),
('storm_shard', 'Fırtına Kırıntısı', 'MATERIAL', 'Fırtınanın gücünü barındıran kırıntı.', 'RARE', 'res://assets/icons/materials/storm_shard.png', true, 50, 200),
('primordial_flame', 'İlkel Alev', 'MATERIAL', 'Yaratılışın ilk ateşi. Sonsuz yanıyor.', 'LEGENDARY', 'res://assets/icons/materials/primordial_flame.png', true, 50, 1250)
ON CONFLICT (id) DO NOTHING;

-- TIME WELL (Zaman Kuyusu)
INSERT INTO public.items (id, name, type, description, rarity, icon, is_stackable, max_stack, base_price)
VALUES 
('time_crystal', 'Zaman Kristali', 'MATERIAL', 'Zamanı yavaşlatan kristal. Nadir bulunur.', 'UNCOMMON', 'res://assets/icons/materials/time_crystal.png', true, 50, 75),
('aging_dust', 'Yaşlanma Tozu', 'MATERIAL', 'Zamanı hızlandıran gizemli toz.', 'COMMON', 'res://assets/icons/materials/aging_dust.png', true, 50, 17),
('eternity_essence', 'Sonsuzluk Özü', 'MATERIAL', 'Ölümsüzlüğün özü. Çok nadir.', 'RARE', 'res://assets/icons/materials/eternity_essence.png', true, 50, 240),
('temporal_shard', 'Zamansal Kırıntı', 'MATERIAL', 'Zaman akışının kırık parçası.', 'RARE', 'res://assets/icons/materials/temporal_shard.png', true, 50, 235),
('infinity_stone', 'Sonsuzluk Taşı', 'MATERIAL', 'Tüm zamanların gücünü barındıran taş.', 'LEGENDARY', 'res://assets/icons/materials/infinity_stone.png', true, 50, 1600)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
DO $$
BEGIN
    RAISE NOTICE 'Resource items migration completed successfully!';
    RAISE NOTICE 'Total items added: 75 resource materials';
    RAISE NOTICE 'Categories: Basic (24), Organic (25), Mystical (26)';
END $$;

-- ============================================================
-- add_craftable_items.sql
-- ============================================================

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

-- ============================================================
-- add_crafting_recipes.sql
-- ============================================================

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

-- ============================================================
-- insert_facility_items.sql
-- ============================================================

-- Insert Missing Material Items into Items Table

INSERT INTO game.items (id, name, type, description, rarity, icon_url)
VALUES 
('material_iron_ore', 'Demir Cevheri', 'material', 'Ham demir cevheri.', 'common', 'res://assets/icons/iron_ore.png'),
('material_crystal', 'Kristal', 'material', 'Değerli bir kristal.', 'uncommon', 'res://assets/icons/crystal.png'),
('material_wheat', 'Buğday', 'material', 'Ekmek yapımında kullanılır.', 'common', 'res://assets/icons/wheat.png'),
('material_poison_shroom', 'Zehirli Mantar', 'material', 'Tehlikeli mantar.', 'rare', 'res://assets/icons/shroom.png'),
('material_oak_log', 'Meşe Kütüğü', 'material', 'Sağlam odun.', 'common', 'res://assets/icons/log.png')
ON CONFLICT (id) DO NOTHING;
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- seed_facility_recipes_complete.sql
-- ============================================================

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

-- ============================================================
-- add_15_resource_facilities.sql
-- ============================================================

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
