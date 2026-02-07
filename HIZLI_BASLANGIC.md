# Veritabanı Geri Yükleme - Hızlı Başlangıç

## Ne Yapılması Gerekiyor?

Veritabanınız silindi ve 5 temel SQL dosyasını çalıştırdınız. Şimdi oyundaki tüm eşyaları ve üretim sistemlerini geri yüklemek için aşağıdaki adımları takip edin.

## Tek Komut ile Geri Yükleme (ÖNERİLEN)

```bash
psql -U postgres -d veritabani_adi -f database/migrations/00_COMPLETE_RESTORE.sql
```

**veya Supabase kullanıyorsanız:**

```bash
supabase db push --include-all
```

Bu tek komut:
- ✅ Items tablosunu hazırlar (44 kolon)
- ✅ 39 eşyayı ekler (silah, zırh, iksir, malzeme vs.)
- ✅ 60+ üretim tarifini ekler (maden, çiftlik, simyahane vs.)
- ✅ Tüm indexleri oluşturur
- ✅ Sonuçları doğrular

## Ne Eklendi?

### 📦 39 Eşya Eklendi

#### ⚔️ Silahlar (6 adet)
- Demir Kılıç, Elf Yayı, Eşsiz Uzun Kılıç
- Çelik Kılıç, Efsanevi Kılıç

#### 🛡️ Zırhlar (5 adet)  
- Deri Göğüslük, Plaka Göğüslük, Eşsiz Zırh
- Deri Zırh, Zincir Zırh, Plaka Zırh

#### 🧪 İksirler (5 adet)
- Minör Enerji İksiri, Antidot, Sağlık İksiri
- Mana İksiri, Dayanıklılık İksiri

#### ⛏️ Malzemeler (21 adet)
- **Madenler:** Demir, Bakır, Altın, Gümüş, Kristal, Elmas
- **Ahşap:** Kereste, Sert Kereste, Bambu
- **Deri:** Deri, Kaliteli Deri, Yün
- **Bitkiler:** Tıbbi Ot, Nadir Ot, Ejderha Kanı

#### 📜 Yükseltme Malzemeleri (11 adet)
- **Kağıtlar:** Düşük/Orta/Yüksek Sınıf Yükseltme Kağıdı
- **Rünler:** Küçük/Büyük Saldırı/Savunma Rünü, Efsanevi Rüne
- **Mücevherler:** Yakut, Safir, Zümrüt

#### 👑 Diğer (2 adet)
- Altın Taç (kozmetik), Demir Kılıç Tarifi

### 🏭 10 Tesis Türü Yapılandırıldı

1. **Maden Ocağı** - Demir, bakır, altın, gümüş, kristal, elmas üretir
2. **Kereste Fabrikası** - Kereste, bambu, sert kereste üretir
3. **Çiftlik** - Deri, yün, kaliteli deri üretir
4. **Ot Bahçesi** - Tıbbi ot, nadir ot, ejderha kanı üretir
5. **Simyahane** - Tüm iksirler üretilir
6. **Demirci** - Silahlar yapılır
7. **Zırhcı** - Zırhlar yapılır
8. **Rün Ustası** - Rünler yapılır
9. **Mücevher Kesici** - Değerli taşlar işlenir
10. **Parşömen Kütüphanesi** - Yükseltme kağıtları hazırlanır

## Doğrulama

Geri yükleme bittikten sonra kontrol edin:

```sql
-- Toplam eşya sayısı
SELECT COUNT(*) FROM public.items;
-- Sonuç: 39 veya daha fazla olmalı

-- Eşya türleri
SELECT type, COUNT(*) 
FROM public.items 
GROUP BY type;
-- WEAPON, ARMOR, POTION, MATERIAL, RUNE, SCROLL, COSMETIC, RECIPE görmelisiniz

-- Toplam tarif sayısı  
SELECT COUNT(*) FROM public.facility_recipes;
-- Sonuç: 60 veya daha fazla olmalı

-- Tesis türleri
SELECT facility_type, COUNT(*) 
FROM public.facility_recipes 
GROUP BY facility_type;
-- mine, farm, sawmill, herb_garden vb. görmelisiniz
```

## Sorun Giderme

### ❌ "relation 'items' does not exist" hatası
**Çözüm:** Önce 5 temel SQL dosyasını çalıştırmış olmalısınız:
```bash
psql -U postgres -d db_adi -f supabase/sql/01_create_inventory_table.sql
psql -U postgres -d db_adi -f supabase/sql/02_normalize_and_rpc.sql
psql -U postgres -d db_adi -f supabase/sql/03_equipment_system.sql
psql -U postgres -d db_adi -f supabase/sql/04_slot_position_rpcs.sql
psql -U postgres -d db_adi -f supabase/sql/hospital_functions.sql
```

### ❌ Oyunda eşyalar görünmüyor
**Çözüm:**
1. Veritabanı bağlantısını kontrol edin
2. Item ID'lerinin doğru olduğunu kontrol edin
3. Oyunu yeniden başlatın

### ❌ Üretim çalışmıyor
**Çözüm:**
1. `facility_recipes` tablosunun olduğunu kontrol edin
2. `output_item_id` değerlerinin `items` tablosunda olduğunu kontrol edin

## Detaylı Bilgi

Daha fazla bilgi için bakın:
- **Kullanıcı Kılavuzu:** `DATABASE_RESTORATION_GUIDE.md`
- **Teknik Detaylar:** `RESTORATION_TECHNICAL_SUMMARY.md`

## Adım Adım Yöntem

Tek komut yerine adım adım ilerlemek isterseniz:

```bash
# Adım 1: Tablo yapısını hazırla
psql -U postgres -d db_adi -f database/migrations/ensure_items_table_columns.sql

# Adım 2: Eşyaları ekle
psql -U postgres -d db_adi -f database/migrations/restore_itemdatabase_items.sql

# Adım 3: Tarifleri ekle
psql -U postgres -d db_adi -f database/migrations/restore_facility_recipes.sql
```

## Güvenlik

✅ **Veri kaybı riski yok** - Scriptler sadece ekler/günceller, silmez  
✅ **Güvenli çalıştırma** - Birden fazla kez çalıştırılabilir  
✅ **Mevcut veriler korunur** - ON CONFLICT kullanır  
✅ **Downtime gerekmez** - Canlı veritabanında çalışabilir

## Özet

1. `00_COMPLETE_RESTORE.sql` dosyasını çalıştırın
2. Doğrulama sorgularını kontrol edin
3. Oyunu başlatın ve test edin
4. Tüm sistemler çalışır durumda olacak!

---
**Not:** Bu geri yükleme, oyun kodundaki (`ItemDatabase.gd`) tüm eşyaları veritabanıyla senkronize eder. ID'ler tam olarak eşleşir, hiçbir uyumsuzluk olmaz.
