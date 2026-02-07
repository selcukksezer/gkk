# 🔄 Veritabanı Kurtarma ve Kurulum Kılavuzu

## 📋 Genel Bakış

Bu kılavuz, veritabanınızdaki tüm verilerin silinmesi durumunda, parça parça SQL dosyalarından veritabanını sıfırdan yeniden oluşturmanız için hazırlanmıştır.

## ⚠️ Önemli Notlar

- **Backend:** Supabase PostgreSQL
- **Proje ID:** znvsyzstmxhqvdkkmgdt
- **SQL Dosya Sayısı:** 59+ dosya
- **Şemalar:** public, auth

## 🗂️ SQL Dosya Organizasyonu

Projede SQL dosyaları 3 ana kategoride bulunur:

### 1. Temel Şema Dosyaları (Öncelik: Yüksek)
Bu dosyalar veritabanı tablolarını ve temel yapıyı oluşturur:

```
supabase/sql/
├── 01_create_inventory_table.sql    # İlk adım: Envanter tablosu
├── 02_normalize_and_rpc.sql         # İkinci adım: Tabloların normalizasyonu
├── 03_equipment_system.sql          # Üçüncü adım: Ekipman sistemi
├── 04_slot_position_rpcs.sql        # Dördüncü adım: Slot pozisyon fonksiyonları
└── hospital_functions.sql           # Hastane fonksiyonları
```

### 2. Migrasyon Dosyaları (Öncelik: Orta)
Bu dosyalar ek özellikler ve düzeltmeler içerir:

```
database/migrations/
├── 00_MASTER_FIX_ALL.sql           # Ana düzeltme dosyası (önemli!)
├── create_facilities_system.sql     # Tesis sistemi
├── create_prison_system.sql         # Hapishane sistemi
├── create_market_system.sql         # Pazar sistemi
└── [diğer migrasyon dosyaları]
```

### 3. Veri ve Düzeltme Dosyaları (Öncelik: Düşük)
İşlevsellik ve veri ekleme dosyaları:

```
database/migrations/
├── add_all_resource_items.sql      # Kaynak öğeleri ekle
├── add_craftable_items.sql         # Üretilebilir öğeler
├── add_crafting_recipes.sql        # Üretim tarifleri
├── insert_facility_items.sql       # Tesis öğeleri
└── seed_facility_recipes_complete.sql # Tesis tarifleri
```

## 🚀 Kurulum Yöntemleri

### Yöntem 1: Otomatik Kurulum Scripti (Önerilen)

Projede hazırlanmış otomatik kurulum scriptini kullanın:

```bash
# Linux/Mac için
bash restore_database.sh

# Windows PowerShell için
.\restore_database.ps1
```

### Yöntem 2: Supabase Dashboard (Manuel)

1. **Supabase Dashboard'a gidin:**
   ```
   https://app.supabase.com/project/znvsyzstmxhqvdkkmgdt/sql
   ```

2. **SQL Editor'ü açın** (sol menüden "SQL Editor")

3. **Dosyaları sırayla çalıştırın:**

   **Adım 1: Temel Şema**
   ```sql
   -- supabase/sql/01_create_inventory_table.sql içeriğini kopyala
   -- SQL Editor'e yapıştır ve "Run" butonuna tıkla
   ```

   **Adım 2: Normalizasyon**
   ```sql
   -- supabase/sql/02_normalize_and_rpc.sql içeriğini kopyala
   -- SQL Editor'e yapıştır ve "Run" butonuna tıkla
   ```

   **Adım 3: Ekipman Sistemi**
   ```sql
   -- supabase/sql/03_equipment_system.sql içeriğini kopyala
   -- SQL Editor'e yapıştır ve "Run" butonuna tıkla
   ```

   **Adım 4: Slot Pozisyon**
   ```sql
   -- supabase/sql/04_slot_position_rpcs.sql içeriğini kopyala
   -- SQL Editor'e yapıştır ve "Run" butonuna tıkla
   ```

   **Adım 5: Hastane Fonksiyonları**
   ```sql
   -- supabase/sql/hospital_functions.sql içeriğini kopyala
   -- SQL Editor'e yapıştır ve "Run" butonuna tıkla
   ```

4. **Migrasyonları çalıştırın:**

   **Ana Düzeltme (Önemli!):**
   ```sql
   -- database/migrations/00_MASTER_FIX_ALL.sql içeriğini çalıştır
   ```

   **Tesis Sistemi:**
   ```sql
   -- database/migrations/create_facilities_system.sql veya
   -- database/migrations/20260130201441_facilities_system.sql (hangisi daha güncel)
   ```

   **Diğer Sistemler:**
   ```sql
   -- database/migrations/create_prison_system.sql
   -- database/migrations/create_market_system.sql
   ```

5. **Veri ekleyin:**
   ```sql
   -- database/migrations/add_all_resource_items.sql
   -- database/migrations/add_craftable_items.sql
   -- database/migrations/add_crafting_recipes.sql
   -- database/migrations/insert_facility_items.sql
   -- database/migrations/seed_facility_recipes_complete.sql
   ```

### Yöntem 3: Supabase CLI (Gelişmiş)

```bash
# Supabase CLI kurulumu (eğer yoksa)
npm install -g supabase

# Projeye bağlan
supabase link --project-ref znvsyzstmxhqvdkkmgdt

# Tüm migrasyonları çalıştır
supabase db push
```

### Yöntem 4: psql Komut Satırı

```bash
# PostgreSQL bağlantısı
export DB_URL="postgresql://postgres:ŞIFRE@db.znvsyzstmxhqvdkkmgdt.supabase.co:5432/postgres"

# Dosyaları sırayla çalıştır
psql $DB_URL -f supabase/sql/01_create_inventory_table.sql
psql $DB_URL -f supabase/sql/02_normalize_and_rpc.sql
psql $DB_URL -f supabase/sql/03_equipment_system.sql
psql $DB_URL -f supabase/sql/04_slot_position_rpcs.sql
psql $DB_URL -f supabase/sql/hospital_functions.sql
psql $DB_URL -f database/migrations/00_MASTER_FIX_ALL.sql
# ... diğer dosyalar
```

## 📝 Kurulum Sırası (Detaylı)

### Faz 1: Temel Altyapı (Zorunlu)
1. ✅ `supabase/sql/01_create_inventory_table.sql`
2. ✅ `supabase/sql/02_normalize_and_rpc.sql`
3. ✅ `supabase/sql/03_equipment_system.sql`
4. ✅ `supabase/sql/04_slot_position_rpcs.sql`
5. ✅ `supabase/sql/hospital_functions.sql`

### Faz 2: Sistem Düzeltmeleri (Önemli)
6. ✅ `database/migrations/00_MASTER_FIX_ALL.sql` (Ana düzeltme)

### Faz 3: Ana Sistemler (Zorunlu)
7. ✅ `database/migrations/create_facilities_system.sql` VEYA `20260130201441_facilities_system.sql`
8. ✅ `database/migrations/create_prison_system.sql`
9. ✅ `database/migrations/create_market_system.sql`

### Faz 4: RPC Fonksiyonları (İsteğe Bağlı ama Önerilen)
10. ✅ `database/migrations/create_collect_rpc_v2.sql`
11. ✅ `database/migrations/create_get_player_facilities_rpc.sql`
12. ✅ `database/migrations/create_get_facility_recipes_rpc.sql`
13. ✅ `database/migrations/create_upgrade_facility_rpc.sql`
14. ✅ `database/migrations/create_purchase_listing_rpc.sql`
15. ✅ `database/migrations/add_collect_facility_resources_rpc.sql`

### Faz 5: Öğeler ve Veriler (Oyun İçeriği)
16. ✅ `database/migrations/add_all_resource_items.sql`
17. ✅ `database/migrations/add_craftable_items.sql`
18. ✅ `database/migrations/add_crafting_recipes.sql`
19. ✅ `database/migrations/insert_facility_items.sql`
20. ✅ `database/migrations/seed_facility_recipes_complete.sql`
21. ✅ `database/migrations/add_15_resource_facilities.sql`

### Faz 6: İyileştirmeler ve Optimizasyonlar (İsteğe Bağlı)
22. ⚙️ `database/migrations/fix_*` dosyaları (gerekirse)
23. ⚙️ `database/migrations/update_*` dosyaları (gerekirse)
24. ⚙️ `database/migrations/optimize_facilities_indexes.sql`

## ✅ Doğrulama

Kurulumdan sonra veritabanını kontrol edin:

```sql
-- Tabloların varlığını kontrol et
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- RPC fonksiyonlarını kontrol et
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_type = 'FUNCTION'
ORDER BY routine_name;

-- Kayıt sayılarını kontrol et
SELECT 
    'items' as table_name, COUNT(*) as count FROM public.items
UNION ALL
SELECT 'inventory', COUNT(*) FROM public.inventory
UNION ALL
SELECT 'facilities', COUNT(*) FROM public.facilities
UNION ALL
SELECT 'crafting_recipes', COUNT(*) FROM public.crafting_recipes;
```

## 🔧 Sorun Giderme

### Hata: "table already exists"
Bu normal bir durum. Script devam edecek ve mevcut tabloyu koruyacak.

### Hata: "column already exists"
Bu da normal. Script mevcut sütunları korur.

### Hata: "function does not exist"
Önceki bir SQL dosyasını kaçırmış olabilirsiniz. Kurulum sırasını kontrol edin.

### Hata: "permission denied"
Supabase'de veritabanı şifrenizin doğru olduğundan emin olun.

## 📞 Destek

Sorun yaşarsanız:
1. `inspect_schema.sql` dosyasını çalıştırarak mevcut durumu kontrol edin
2. Hata mesajlarını tam olarak kaydedin
3. Hangi SQL dosyasında hata aldığınızı not edin

## 🔐 Güvenlik

- ⚠️ Veritabanı şifrelerini asla Git'e commit etmeyin
- ⚠️ `.env` dosyalarını `.gitignore`'a ekleyin
- ⚠️ Supabase API anahtarlarını güvende tutun

## 📚 İlgili Dosyalar

- `restore_database.sh` - Linux/Mac için otomatik kurulum scripti
- `restore_database.ps1` - Windows için otomatik kurulum scripti
- `DEPLOY_SQL.ps1` - Mevcut deployment scripti
- `run_master_migration.ps1` - Master migration çalıştırıcı
