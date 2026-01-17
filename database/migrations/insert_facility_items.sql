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
