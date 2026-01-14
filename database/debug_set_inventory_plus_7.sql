-- Tüm envanterdeki eşyaların seviyesini +7 yapmak için:

-- 1. Yöntem: Sadece belirli bir karakterin eşyalarını güncelle (ÖNERİLEN)
-- 'KARAKTER_ID_BURAYA' kısmını kendi character_id'niz ile değiştirin.
-- UPDATE character_items 
-- SET enhancement_level = 7 
-- WHERE character_id = 'KARAKTER_ID_BURAYA';

-- 2. Yöntem: Veritabanındaki HERKESİN ve HER EŞYANIN seviyesini +7 yap (Sadece geliştirme ortamı için)
UPDATE character_items
SET enhancement_level = 7;

-- 3. Yöntem: Sadece belirli tipteki eşyaları (Silah, Zırh vb.) güncellemek isterseniz (item_templates ile join):
-- UPDATE character_items
-- SET enhancement_level = 7
-- FROM item_templates
-- WHERE character_items.item_id = item_templates.id
-- AND item_templates.item_type IN ('WEAPON', 'ARMOR', 'ACCESSORY');
