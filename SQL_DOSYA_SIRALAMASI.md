# SQL Dosya Sıralaması ve Açıklamaları
# SQL File Ordering and Descriptions

## 📊 Kurulum Sırası Tablosu

| Sıra | Dosya | Açıklama | Zorunlu |
|------|-------|----------|---------|
| 1 | `supabase/sql/01_create_inventory_table.sql` | Envanter tablosu ve temel yapı | ✅ Evet |
| 2 | `supabase/sql/02_normalize_and_rpc.sql` | Tablolar ve RPC fonksiyonları | ✅ Evet |
| 3 | `supabase/sql/03_equipment_system.sql` | Ekipman sistemi | ✅ Evet |
| 4 | `supabase/sql/04_slot_position_rpcs.sql` | Slot pozisyon yönetimi | ✅ Evet |
| 5 | `supabase/sql/hospital_functions.sql` | Hastane fonksiyonları | ✅ Evet |
| 6 | `database/migrations/00_MASTER_FIX_ALL.sql` | Ana düzeltme scripti | ✅ Evet |
| 7 | `database/migrations/20260130201441_facilities_system.sql` | Tesis sistemi (güncel) | ✅ Evet |
| 8 | `database/migrations/create_prison_system.sql` | Hapishane sistemi | ✅ Evet |
| 9 | `database/migrations/create_market_system.sql` | Pazar sistemi | ✅ Evet |
| 10 | `database/migrations/create_collect_rpc_v2.sql` | Kaynak toplama RPC v2 | 🟡 Önerilen |
| 11 | `database/migrations/create_get_player_facilities_rpc.sql` | Oyuncu tesisleri RPC | 🟡 Önerilen |
| 12 | `database/migrations/create_get_facility_recipes_rpc.sql` | Tesis tarifleri RPC | 🟡 Önerilen |
| 13 | `database/migrations/create_upgrade_facility_rpc.sql` | Tesis yükseltme RPC | 🟡 Önerilen |
| 14 | `database/migrations/create_purchase_listing_rpc.sql` | Satın alma RPC | 🟡 Önerilen |
| 15 | `database/migrations/add_collect_facility_resources_rpc.sql` | Tesis kaynak toplama | 🟡 Önerilen |
| 16 | `database/migrations/add_all_resource_items.sql` | Tüm kaynak öğeleri | 🟡 Önerilen |
| 17 | `database/migrations/add_craftable_items.sql` | Üretilebilir öğeler | 🟡 Önerilen |
| 18 | `database/migrations/add_crafting_recipes.sql` | Üretim tarifleri | 🟡 Önerilen |
| 19 | `database/migrations/insert_facility_items.sql` | Tesis öğeleri | 🟡 Önerilen |
| 20 | `database/migrations/seed_facility_recipes_complete.sql` | Tam tesis tarifleri | 🟡 Önerilen |
| 21 | `database/migrations/add_15_resource_facilities.sql` | 15 kaynak tesisi | 🟡 Önerilen |

## 📁 Kategori Bazında Gruplandırma

### 🏗️ Temel Altyapı (1-6)
Bu dosyalar veritabanının temel iskeletini oluşturur. **Mutlaka çalıştırılmalıdır.**

- Tablolar: items, inventory, equipment
- Temel RPC fonksiyonları
- Düzeltmeler ve optimizasyonlar

### 🎮 Oyun Sistemleri (7-9)
Oyunun ana sistemleri. **Oyunun çalışması için gerekli.**

- Tesis sistemi (facilities)
- Hapishane sistemi (prison)
- Pazar sistemi (market)

### ⚙️ İleri RPC Fonksiyonları (10-15)
Gelişmiş oyun mekaniği fonksiyonları. **Önerilir ama opsiyonel.**

- Kaynak toplama
- Tesis yönetimi
- Satın alma işlemleri

### 📦 Veri ve İçerik (16-21)
Oyun içeriği ve başlangıç verileri. **Oynanabilir bir oyun için gerekli.**

- Öğe tanımları
- Üretim tarifleri
- Tesis tanımları

## 🔍 Dosya Detayları

### Kritik Dosyalar

#### `00_MASTER_FIX_ALL.sql`
**Ne yapar:**
- Slot pozisyonlarını düzeltir
- Ekipman duplikasyonlarını temizler
- Envanter bütünlüğünü sağlar

**Çalıştırılmadan önce gerekli:**
- 01-05 numaralı dosyalar

**Hata durumunda:**
- Normal, uyarılar göz ardı edilebilir
- Mevcut veriler korunur

#### `20260130201441_facilities_system.sql`
**Ne yapar:**
- Tesislerin tüm tabloları
- Tesis RPC fonksiyonları
- Tesis izinleri (RLS)

**Alternatif:**
- `create_facilities_system.sql` (eski versiyon)

**Not:** İkisinden birini seçin, ikisini birden çalıştırmayın.

### Opsiyonel Dosyalar

Bu dosyalar belirli sorunları çözer veya optimizasyonlar sağlar:

```
database/migrations/
├── fix_equipment_stacking.sql      # Ekipman stack sorunları
├── fix_shop_stacking.sql           # Mağaza stack sorunları
├── optimize_facilities_indexes.sql # Performans optimizasyonu
├── wipe_duplicates.sql             # Duplike kayıtları temizle
└── repair_inventory_slots.sql      # Slot tamiri
```

**Ne zaman çalıştırılır:**
- Sadece ilgili sorun yaşanırsa
- Kurulum sonrası optimizasyon için

## 🔄 Güncelleme ve Sürüm Takibi

### Dosya İsimlendirme Kuralları

1. **Numaralı dosyalar:** Sıralı çalıştırılır
   - `01_create_inventory_table.sql`
   - `02_normalize_and_rpc.sql`

2. **Tarih prefix'li:** Timestamp sırasıyla
   - `20260130201441_facilities_system.sql`

3. **İsimlendirilmiş:** İşlev bazlı
   - `create_market_system.sql`
   - `fix_equipment_stacking.sql`

### Çakışan Dosyalar

| Grup | Eski | Yeni | Hangisi? |
|------|------|------|----------|
| Tesisler | `create_facilities_system.sql` | `20260130201441_facilities_system.sql` | Yeni |
| Toplama | `create_collect_rpc.sql` | `create_collect_rpc_v2.sql` | v2 |

## 📝 Test ve Doğrulama

### Her Aşama Sonrası

```sql
-- Tablo kontrolü
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE '%facility%';

-- RPC kontrolü
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%facility%';
```

### Tam Kurulum Sonrası

```sql
-- Tüm tabloları listele
\dt public.*

-- Tüm fonksiyonları listele
\df public.*

-- Kayıt sayıları
SELECT 
    'items' as tbl, COUNT(*) FROM public.items
UNION ALL
SELECT 'inventory', COUNT(*) FROM public.inventory
UNION ALL
SELECT 'facilities', COUNT(*) FROM public.facilities
UNION ALL
SELECT 'crafting_recipes', COUNT(*) FROM public.crafting_recipes;
```

## ⚠️ Bilinen Sorunlar ve Çözümleri

### Sorun 1: "relation already exists"
**Neden:** Tablo zaten var
**Çözüm:** Normal, devam et. Script `IF NOT EXISTS` kullanır.

### Sorun 2: "column does not exist"
**Neden:** Önceki migration atlandı
**Çözüm:** Önceki dosyayı çalıştır

### Sorun 3: "function does not exist"
**Neden:** Bağımlı RPC eksik
**Çözüm:** İlgili `create_*_rpc.sql` dosyasını çalıştır

### Sorun 4: Foreign key violation
**Neden:** İlişkili tablo henüz yok
**Çözüm:** Sıralamaya uy, önce ana tabloları oluştur

## 🎯 Minimal Kurulum (Hızlı Test İçin)

Sadece oyunu test etmek için minimum dosyalar:

```bash
1. supabase/sql/01_create_inventory_table.sql
2. supabase/sql/02_normalize_and_rpc.sql
3. supabase/sql/03_equipment_system.sql
4. database/migrations/00_MASTER_FIX_ALL.sql
5. database/migrations/add_all_resource_items.sql
```

Bu 5 dosya ile temel bir oyun ortamı elde edilir.

## 📞 Yardım ve Destek

Sorun yaşarsanız:
1. Hangi dosyayı çalıştırdığınızı not edin
2. Tam hata mesajını kaydedin
3. `VERITABANI_KURULUM_KILAVUZU.md` dosyasına bakın
4. Sorun giderme bölümünü inceleyin

---

**Hazırlayan:** Database Restoration System
**Tarih:** 2026-02-07
**Versiyon:** 1.0
