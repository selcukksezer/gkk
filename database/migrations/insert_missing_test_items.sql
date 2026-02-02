-- Insert missing items for test recipes
INSERT INTO public.items (id, name, type, description, rarity, icon)
VALUES 
('material_herb', 'Şifalı Ot', 'material', 'İlaç yapımında kullanılır.', 'common', 'res://assets/icons/herb.png'),
('test_sword', 'Test Kılıcı', 'weapon', 'Test amaçlı üretim kılıcı.', 'common', 'res://assets/icons/sword_basic.png'),
('test_armor', 'Test Zırhı', 'armor', 'Test amaçlı üretim zırhı.', 'common', 'res://assets/icons/armor_basic.png'),
('potion_health_small', 'Küçük Can İksiri', 'consumable', 'Az miktarda can yeniler.', 'common', 'res://assets/icons/potion_red.png'),
('rune_weak', 'Zayıf Rün', 'material', 'Basit büyü işleri için.', 'common', 'res://assets/icons/rune.png'),
('scroll_identify', 'Tanımlama Parşömeni', 'consumable', 'Eşyaları tanımlar.', 'common', 'res://assets/icons/scroll.png'),
('gem_fragment', 'Cevher Parçası', 'material', 'İşlenmemiş cevher parçası.', 'common', 'res://assets/icons/gem.png'),
('enhance_stone', 'Yükseltme Taşı', 'material', 'Eşya yükseltmek için kullanılır.', 'uncommon', 'res://assets/icons/stone.png'),
('potion_health_large', 'Büyük Can İksiri', 'consumable', 'Büyük miktarda can yeniler.', 'uncommon', 'res://assets/icons/potion_red_big.png'),
('plate_armor', 'Plaka Zırh', 'armor', 'Ağır zırh.', 'rare', 'res://assets/icons/armor_plate.png')
ON CONFLICT (id) DO NOTHING;
