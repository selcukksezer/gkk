# 📊 Veritabanı Kurtarma Akış Şeması
# Database Restoration Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                 VERİTABANI KAYBOLDU!                        │
│              DATABASE LOST - ALL DATA GONE                  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              ÇÖZÜM SEÇENEKLERİ / SOLUTIONS                  │
├─────────────────────────────────────────────────────────────┤
│  1. Otomatik Script (Önerilen)                              │
│  2. Supabase Dashboard (Manuel)                             │
│  3. Supabase CLI (Gelişmiş)                                 │
│  4. psql Komut Satırı (Profesyonel)                         │
└─────────────────────────────────────────────────────────────┘
      │              │              │              │
      ▼              ▼              ▼              ▼
┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│ SEÇENEK 1│  │ SEÇENEK 2│  │ SEÇENEK 3│  │ SEÇENEK 4│
└──────────┘  └──────────┘  └──────────┘  └──────────┘


═════════════════════════════════════════════════════════════
SEÇENEK 1: OTOMATİK SCRIPT (EN KOLAY) 🚀
═════════════════════════════════════════════════════════════

┌─────────────────────────────────────┐
│  Linux/Mac                          │
│  ────────────────                   │
│  $ export DB_PASSWORD="şifre"       │
│  $ bash restore_database.sh         │
│  Seçim: 1                           │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  Windows PowerShell                 │
│  ────────────────                   │
│  PS> .\restore_database.ps1         │
│  Seçim: 1                           │
└─────────────────────────────────────┘
                │
                ▼
        ┌───────────────┐
        │ Bağlantı Test │
        └───────────────┘
                │
                ▼
    ┌───────────────────────┐
    │ FAZ 1: Temel Altyapı  │ ◀── 5 dosya
    └───────────────────────┘
                │
                ▼
    ┌───────────────────────┐
    │ FAZ 2: Düzeltmeler    │ ◀── 1 dosya (00_MASTER_FIX_ALL)
    └───────────────────────┘
                │
                ▼
    ┌───────────────────────┐
    │ FAZ 3: Ana Sistemler  │ ◀── 3 dosya (facilities, prison, market)
    └───────────────────────┘
                │
                ▼
    ┌───────────────────────┐
    │ FAZ 4: RPC Fonk.      │ ◀── 6 dosya
    └───────────────────────┘
                │
                ▼
    ┌───────────────────────┐
    │ FAZ 5: Veri Ekleme    │ ◀── 6 dosya
    └───────────────────────┘
                │
                ▼
        ┌───────────────┐
        │  DOĞRULAMA    │
        └───────────────┘
                │
                ▼
        ┌───────────────┐
        │   BAŞARILI!   │
        └───────────────┘


═════════════════════════════════════════════════════════════
SEÇENEK 2: SUPABASE DASHBOARD (MANUEL KONTROL) 🖱️
═════════════════════════════════════════════════════════════

Browser'da Aç
    │
    ▼
https://app.supabase.com/project/znvsyzstmxhqvdkkmgdt/sql
    │
    ▼
SQL Editor Aç
    │
    ▼
┌────────────────────────────────────┐
│ Her dosyayı tek tek kopyala-yapıştır:
│
│ 1. supabase/sql/01_create_inventory_table.sql
│    ↓ Yapıştır → RUN
│
│ 2. supabase/sql/02_normalize_and_rpc.sql
│    ↓ Yapıştır → RUN
│
│ 3. supabase/sql/03_equipment_system.sql
│    ↓ Yapıştır → RUN
│
│ ... (toplam 21 dosya)
│
└────────────────────────────────────┘
    │
    ▼
✅ Tamamlandı


═════════════════════════════════════════════════════════════
SEÇENEK 3: SUPABASE CLI (PROFESYONEL) 💻
═════════════════════════════════════════════════════════════

┌────────────────────────────────┐
│ npm install -g supabase        │
└────────────────────────────────┘
                │
                ▼
┌────────────────────────────────┐
│ supabase link --project-ref    │
│   znvsyzstmxhqvdkkmgdt          │
└────────────────────────────────┘
                │
                ▼
┌────────────────────────────────┐
│ supabase db push               │
└────────────────────────────────┘
                │
                ▼
        ✅ Tamamlandı


═════════════════════════════════════════════════════════════
SEÇENEK 4: PSQL KOMUT SATIRI (GELİŞMİŞ) ⌨️
═════════════════════════════════════════════════════════════

┌────────────────────────────────────────────────────┐
│ DB_URL="postgresql://postgres:ŞİFRE@               │
│   db.znvsyzstmxhqvdkkmgdt.supabase.co:5432/postgres"│
└────────────────────────────────────────────────────┘
                        │
                        ▼
┌────────────────────────────────────────────────────┐
│ psql $DB_URL -f supabase/sql/01_*.sql              │
│ psql $DB_URL -f supabase/sql/02_*.sql              │
│ ...                                                 │
└────────────────────────────────────────────────────┘
                        │
                        ▼
                ✅ Tamamlandı


═════════════════════════════════════════════════════════════
KURULUM SONRASI DOĞRULAMA ✅
═════════════════════════════════════════════════════════════

┌─────────────────────────────────────┐
│ SQL Editor'de Çalıştır:             │
│                                     │
│ SELECT table_name                   │
│ FROM information_schema.tables      │
│ WHERE table_schema = 'public'       │
│ ORDER BY table_name;                │
└─────────────────────────────────────┘
                │
                ▼
        Beklenen Tablolar:
        ├── items
        ├── inventory
        ├── facilities
        ├── crafting_recipes
        ├── market_listings
        ├── prison
        └── ... (daha fazla)
                │
                ▼
┌─────────────────────────────────────┐
│ SELECT routine_name                 │
│ FROM information_schema.routines    │
│ WHERE routine_schema = 'public'     │
│ AND routine_type = 'FUNCTION';      │
└─────────────────────────────────────┘
                │
                ▼
        Beklenen RPC Fonksiyonları:
        ├── add_item
        ├── equip_item
        ├── collect_resources
        ├── upgrade_facility
        └── ... (30+ fonksiyon)
                │
                ▼
        ┌───────────────┐
        │  HER ŞEY OK!  │
        └───────────────┘


═════════════════════════════════════════════════════════════
DOSYA YAPISI VE BAĞIMLILIKLAR 📁
═════════════════════════════════════════════════════════════

KATMAN 1: Temel Tablolar (Bağımlılık yok)
├── 01_create_inventory_table.sql
├── 02_normalize_and_rpc.sql
└── 03_equipment_system.sql
        │
        │ creates: items, inventory tables
        ▼
KATMAN 2: Sistem Fonksiyonları (items, inventory gerekli)
├── 04_slot_position_rpcs.sql
├── hospital_functions.sql
└── 00_MASTER_FIX_ALL.sql
        │
        │ creates: RPC functions
        ▼
KATMAN 3: Oyun Sistemleri (Tablolar ve RPC gerekli)
├── create_facilities_system.sql
├── create_prison_system.sql
└── create_market_system.sql
        │
        │ creates: facilities, prison, market tables
        ▼
KATMAN 4: İleri Fonksiyonlar (Sistem tabloları gerekli)
├── create_collect_rpc_v2.sql
├── create_get_player_facilities_rpc.sql
├── create_upgrade_facility_rpc.sql
└── ... (daha fazla RPC)
        │
        │ creates: Advanced RPC functions
        ▼
KATMAN 5: Veri (Tüm tablolar gerekli)
├── add_all_resource_items.sql
├── add_craftable_items.sql
├── add_crafting_recipes.sql
└── seed_facility_recipes_complete.sql
        │
        │ inserts: Game content
        ▼
    ✅ TAM SİSTEM


═════════════════════════════════════════════════════════════
SORUN GİDERME AKIŞI 🔧
═════════════════════════════════════════════════════════════

Hata Aldınız mı?
        │
        ▼
┌───────────────────────────┐
│ "table already exists"    │  → Normal, devam et
└───────────────────────────┘

┌───────────────────────────┐
│ "column does not exist"   │  → Önceki dosyayı çalıştır
└───────────────────────────┘

┌───────────────────────────┐
│ "function not found"      │  → İlgili RPC dosyasını çalıştır
└───────────────────────────┘

┌───────────────────────────┐
│ "permission denied"       │  → Şifreyi kontrol et
└───────────────────────────┘

┌───────────────────────────┐
│ "connection failed"       │  → Bağlantı bilgilerini kontrol et
└───────────────────────────┘

Hala sorun mu var?
        │
        ▼
VERITABANI_KURULUM_KILAVUZU.md → Sorun Giderme bölümü


═════════════════════════════════════════════════════════════
HIZLI REFERANS 📝
═════════════════════════════════════════════════════════════

Kılavuzlar:
├── HIZLI_BASLANGIC.md          ← Hemen başla
├── VERITABANI_KURULUM_KILAVUZU.md  ← Detaylı bilgi
└── SQL_DOSYA_SIRALAMASI.md      ← Dosya listesi

Scriptler:
├── restore_database.sh          ← Linux/Mac
└── restore_database.ps1         ← Windows

Supabase:
├── Proje ID: znvsyzstmxhqvdkkmgdt
├── Host: db.znvsyzstmxhqvdkkmgdt.supabase.co
└── Dashboard: https://app.supabase.com/project/znvsyzstmxhqvdkkmgdt


═════════════════════════════════════════════════════════════
ZAMAN TABLOSU ⏱️
═════════════════════════════════════════════════════════════

Otomatik Script:       ~5-10 dakika
Supabase Dashboard:    ~20-30 dakika
Supabase CLI:          ~3-5 dakika
psql Komut Satırı:     ~10-15 dakika

* Süreler internet hızına ve veritabanı performansına bağlıdır


═════════════════════════════════════════════════════════════
✅ BAŞARI KRİTERLERİ
═════════════════════════════════════════════════════════════

[✅] Tüm tablolar oluşturuldu (15+)
[✅] RPC fonksiyonları çalışıyor (30+)
[✅] Oyun bağlanabiliyor
[✅] Envanter sistemi çalışıyor
[✅] Tesis sistemi çalışıyor
[✅] Pazar sistemi çalışıyor
[✅] Hata yok

→ Kurulum tamamlandı! Oyunu başlatabilirsiniz.
```

---

**Hazırlayan:** Database Restoration System  
**Tarih:** 2026-02-07  
**Versiyon:** 1.0  
**Dil:** Türkçe & English
