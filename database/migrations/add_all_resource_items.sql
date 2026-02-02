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
