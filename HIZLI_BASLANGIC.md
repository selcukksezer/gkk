# 🔄 Hızlı Başlangıç - Veritabanı Kurtarma
# Quick Start - Database Restoration

## ⚡ En Hızlı Yöntem / Fastest Method

### Linux/Mac:
```bash
export DB_PASSWORD="your-database-password"
bash restore_database.sh
# Seçenek 1'i seçin (Otomatik kurulum)
```

### Windows PowerShell:
```powershell
.\restore_database.ps1
# Seçenek 1'i seçin (Otomatik kurulum)
```

## 📋 Alternatif: Supabase Dashboard (Manuel)

1. Giriş yapın: https://app.supabase.com/project/znvsyzstmxhqvdkkmgdt/sql

2. Dosyaları bu sırayla çalıştırın:

```
✅ supabase/sql/01_create_inventory_table.sql
✅ supabase/sql/02_normalize_and_rpc.sql
✅ supabase/sql/03_equipment_system.sql
✅ supabase/sql/04_slot_position_rpcs.sql
✅ supabase/sql/hospital_functions.sql
✅ database/migrations/00_MASTER_FIX_ALL.sql
✅ database/migrations/20260130201441_facilities_system.sql
✅ database/migrations/create_prison_system.sql
✅ database/migrations/create_market_system.sql
```

## 📊 Kurulum Sonrası Kontrol

```sql
-- Tabloları kontrol et
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Veri sayılarını kontrol et
SELECT 
    'items' as table_name, COUNT(*) as count FROM public.items
UNION ALL
SELECT 'inventory', COUNT(*) FROM public.inventory
UNION ALL
SELECT 'facilities', COUNT(*) FROM public.facilities;
```

## 🆘 Sorun Giderme

### Hata: psql bulunamadı
**Çözüm:** PostgreSQL Client yükleyin
- Mac: `brew install postgresql`
- Ubuntu: `sudo apt-get install postgresql-client`
- Windows: https://www.postgresql.org/download/windows/

### Hata: Bağlantı başarısız
**Çözüm:** 
1. Şifrenizi kontrol edin
2. Supabase Dashboard'da "Database Settings" bölümünden bağlantı bilgilerini doğrulayın
3. IP beyaz listesini kontrol edin (Supabase → Settings → Database → Connection Pooling)

### Hata: Table already exists
**Normal:** Bu hata göz ardı edilebilir. Script mevcut tabloları korur.

## 📚 Detaylı Bilgi

Tüm detaylar için: [VERITABANI_KURULUM_KILAVUZU.md](VERITABANI_KURULUM_KILAVUZU.md)

## 🔐 Güvenlik Notları

- ⚠️ Şifreleri hiçbir zaman Git'e commit etmeyin
- ⚠️ `.env` dosyalarını `.gitignore`'a ekleyin
- ⚠️ Production veritabanında test yapmadan önce yedek alın

## ✅ Başarı Kriterleri

Kurulum başarılı sayılır eğer:
- [x] Tüm tablolar oluşturuldu (items, inventory, facilities, vb.)
- [x] RPC fonksiyonları çalışıyor
- [x] Oyun bağlanabiliyor ve veri okuyabiliyor
- [x] Envanter sistemi çalışıyor
- [x] Tesis sistemi çalışıyor

---

**Son Güncelleme:** 2026-02-07
