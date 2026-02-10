# ✅ SUPABASE SQL EDİTÖR - HIZLI KONTROL LİSTESİ

## 🎯 5 ADIMDA VERİTABANI KURTARMA

### URL
```
https://app.supabase.com/project/znvsyzstmxhqvdkkmgdt/sql
```

---

## 📋 ÇALIŞTIRMA SIRASI

### ☐ ADIM 1: Temel Altyapı
**Dosya:** `01_TEMEL_ALTYAPI.sql` (41KB)

**İçerik:**
- ✓ Envanter tablosu
- ✓ Items tablosu
- ✓ Ekipman sistemi
- ✓ Slot RPC'leri
- ✓ Hastane fonksiyonları

**Aksiyon:**
1. Dosyayı aç
2. Ctrl+A (Tümünü seç)
3. Ctrl+C (Kopyala)
4. SQL Editor'e yapıştır
5. RUN'a bas
6. Bekle (~30 saniye)

**Sonuç:** ☐ Başarılı ☐ Hatalı

---

### ☐ ADIM 2: Düzeltmeler
**Dosya:** `02_DUZELTMELER.sql` (19KB)

**İçerik:**
- ✓ Master fix scripti
- ✓ Slot düzeltmeleri
- ✓ Duplikasyon temizleme

**Aksiyon:**
1. Dosyayı aç
2. Ctrl+A, Ctrl+C
3. SQL Editor'e yapıştır
4. RUN'a bas
5. Bekle (~15 saniye)

**Sonuç:** ☐ Başarılı ☐ Hatalı

⚠️ Uyarılar normaldir, devam et!

---

### ☐ ADIM 3: Ana Sistemler
**Dosya:** `03_ANA_SISTEMLER.sql` (24KB)

**İçerik:**
- ✓ Tesis sistemi
- ✓ Hapishane sistemi
- ✓ Pazar sistemi

**Aksiyon:**
1. Dosyayı aç
2. Ctrl+A, Ctrl+C
3. SQL Editor'e yapıştır
4. RUN'a bas
5. Bekle (~20 saniye)

**Sonuç:** ☐ Başarılı ☐ Hatalı

---

### ☐ ADIM 4: RPC Fonksiyonlar
**Dosya:** `04_RPC_FONKSIYONLAR.sql` (35KB)

**İçerik:**
- ✓ Kaynak toplama
- ✓ Tesis yönetimi
- ✓ Satın alma
- ✓ Yükseltme

**Aksiyon:**
1. Dosyayı aç
2. Ctrl+A, Ctrl+C
3. SQL Editor'e yapıştır
4. RUN'a bas
5. Bekle (~25 saniye)

**Sonuç:** ☐ Başarılı ☐ Hatalı

---

### ☐ ADIM 5: Veri ve İçerik
**Dosya:** `05_VERI_VE_ICERIK.sql` (43KB)

**İçerik:**
- ✓ Kaynak öğeleri
- ✓ Üretilebilir öğeler
- ✓ Üretim tarifleri
- ✓ Tesis öğeleri
- ✓ 15 kaynak tesisi

**Aksiyon:**
1. Dosyayı aç
2. Ctrl+A, Ctrl+C
3. SQL Editor'e yapıştır
4. RUN'a bas
5. Bekle (~30 saniye)

**Sonuç:** ☐ Başarılı ☐ Hatalı

---

## ✅ DOĞRULAMA

### Kontrol 1: Tablo Sayısı
```sql
SELECT COUNT(*) 
FROM information_schema.tables 
WHERE table_schema = 'public';
```
**Beklenen:** 15+ tablo  
**Gerçek:** _____ tablo  
**Durum:** ☐ OK ☐ Sorunlu

---

### Kontrol 2: Item Sayısı
```sql
SELECT COUNT(*) FROM public.items;
```
**Beklenen:** 100+ item  
**Gerçek:** _____ item  
**Durum:** ☐ OK ☐ Sorunlu

---

### Kontrol 3: RPC Sayısı
```sql
SELECT COUNT(*) 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_type = 'FUNCTION';
```
**Beklenen:** 30+ fonksiyon  
**Gerçek:** _____ fonksiyon  
**Durum:** ☐ OK ☐ Sorunlu

---

## 🎯 FİNAL KONTROL

- [ ] Tüm 5 dosya çalıştırıldı
- [ ] Hiç kritik hata olmadı
- [ ] Tablo sayısı 15+
- [ ] Item sayısı 100+
- [ ] RPC sayısı 30+
- [ ] Oyun bağlanabiliyor

---

## ⏱️ TOPLAM SÜRE

- Dosya 1: ~30 saniye
- Dosya 2: ~15 saniye
- Dosya 3: ~20 saniye
- Dosya 4: ~25 saniye
- Dosya 5: ~30 saniye
- **TOPLAM: ~2 dakika**

---

## 📝 NOTLAR

Sorunlar:
_____________________________________________
_____________________________________________
_____________________________________________

Başarılar:
_____________________________________________
_____________________________________________
_____________________________________________

---

## 🎉 TAMAMLANDI!

**Tarih:** _______________  
**Saat:** _______________  
**Durum:** ☐ Başarılı ☐ Kısmi ☐ Başarısız

**Sonraki Adım:** Oyunu test et!

---

**Not:** Bu kontrol listesini yazdırıp yanınızda tutabilirsiniz.
