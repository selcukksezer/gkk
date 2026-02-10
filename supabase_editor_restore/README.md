# 📁 SUPABASE SQL EDITOR - VERİTABANI KURTARMA DOSYALARI

## 🎯 Bu Klasörün Amacı

Bu klasör, Supabase SQL Editor'de **sırayla çalıştırmanız** için hazırlanmış 5 SQL dosyası içerir.
Her dosya, veritabanınızı geri yüklemek için gereken tüm SQL komutlarını içerir.

---

## 📂 Klasör İçeriği

### 📖 Dökümanlar
1. **README.md** (bu dosya) - Genel bilgi
2. **00_BASLANGIC_TALIMATLAR.md** - Detaylı talimatlar
3. **KONTROL_LISTESI.md** - Yazdırılabilir kontrol listesi

### 💾 SQL Dosyaları (Sırayla Çalıştırın!)
1. **01_TEMEL_ALTYAPI.sql** (42KB) - Temel tablolar ve RPC'ler
2. **02_DUZELTMELER.sql** (36KB) - Düzeltme scriptleri
3. **03_ANA_SISTEMLER.sql** (24KB) - Tesis, hapishane, pazar
4. **04_RPC_FONKSIYONLAR.sql** (35KB) - İleri RPC fonksiyonları
5. **05_VERI_VE_ICERIK.sql** (43KB) - Oyun içeriği

**TOPLAM:** 180KB SQL kodu

---

## 🚀 HIZLI BAŞLANGIÇ

### 3 Basit Adım:

#### 1️⃣ SQL Editor'ü Aç
```
https://app.supabase.com/project/znvsyzstmxhqvdkkmgdt/sql
```

#### 2️⃣ Dosyaları Sırayla Çalıştır
Her dosya için:
- Dosyayı bir text editörde aç
- Tüm içeriği kopyala (Ctrl+A, Ctrl+C)
- SQL Editor'e yapıştır (Ctrl+V)
- **RUN** butonuna bas
- Bitene kadar bekle
- Sonraki dosyaya geç

#### 3️⃣ Doğrula
Son dosyadan sonra şu sorguyu çalıştır:
```sql
SELECT COUNT(*) FROM public.items;
-- 100+ item varsa başarılı!
```

---

## 📋 DOSYA DETAYLARI

### Dosya 1: 01_TEMEL_ALTYAPI.sql
**Boyut:** 42KB  
**Süre:** ~30 saniye  
**İçerik:**
- Envanter ve items tabloları
- Temel RPC fonksiyonları
- Ekipman sistemi

### Dosya 2: 02_DUZELTMELER.sql
**Boyut:** 36KB  
**Süre:** ~15 saniye  
**İçerik:**
- Master düzeltme scripti
- Veri bütünlük kontrolleri

### Dosya 3: 03_ANA_SISTEMLER.sql
**Boyut:** 24KB  
**Süre:** ~20 saniye  
**İçerik:**
- Tesis sistemi
- Hapishane sistemi
- Pazar sistemi

### Dosya 4: 04_RPC_FONKSIYONLAR.sql
**Boyut:** 35KB  
**Süre:** ~25 saniye  
**İçerik:**
- Kaynak toplama
- Tesis yönetimi
- Satın alma fonksiyonları

### Dosya 5: 05_VERI_VE_ICERIK.sql
**Boyut:** 43KB  
**Süre:** ~30 saniye  
**İçerik:**
- 100+ oyun öğesi
- 50+ üretim tarifi
- 15 kaynak tesisi

---

## ⏱️ TOPLAM KURULUM SÜRESİ

**~2 Dakika** (tüm dosyalar için)

- Dosya 1: 30s
- Dosya 2: 15s
- Dosya 3: 20s
- Dosya 4: 25s
- Dosya 5: 30s

---

## ✅ BAŞARI KRİTERLERİ

Kurulum başarılı sayılır eğer:

- [x] Tüm 5 dosya hatasız çalıştı
- [x] 15+ tablo oluşturuldu
- [x] 100+ item eklendi
- [x] 30+ RPC fonksiyonu var
- [x] Oyun bağlanabiliyor

---

## 🎯 SIRA NEDEN ÖNEMLİ?

SQL dosyaları bağımlılık sırasına göre düzenlenmiştir:

```
01_TEMEL_ALTYAPI
    ↓ (tablolar oluşturuldu)
02_DUZELTMELER
    ↓ (veri bütünlüğü sağlandı)
03_ANA_SISTEMLER
    ↓ (sistemler kuruldu)
04_RPC_FONKSIYONLAR
    ↓ (fonksiyonlar eklendi)
05_VERI_VE_ICERIK
    ↓ (içerik eklendi)
✅ TAMAM!
```

**Sırayı atlamayın!** Her dosya bir öncekine bağlıdır.

---

## ⚠️ ÖNEMLİ NOTLAR

1. **İnternet Bağlantısı:** Stabil olmalı
2. **Tarayıcı:** Chrome veya Firefox önerilir
3. **Zaman Aşımı:** Her dosya için yeterli zaman verin
4. **Uyarılar:** Bazı uyarılar normal, hata değil
5. **Yedek:** Mümkünse önce yedek alın

---

## 🆘 SORUN GİDERME

### "table already exists" Hatası
✅ **Normal!** Devam edin, script bunu handle eder.

### "timeout" Hatası
⏱️ **Çözüm:** Dosyayı ikiye bölün ve ayrı ayrı çalıştırın.

### "permission denied" Hatası
🔐 **Çözüm:** Doğru Supabase kullanıcısı ile giriş yapın.

### Diğer Hatalar
📖 **Çözüm:** `00_BASLANGIC_TALIMATLAR.md` dosyasına bakın.

---

## 📞 YARDIM

**Detaylı Talimatlar:** `00_BASLANGIC_TALIMATLAR.md`  
**Kontrol Listesi:** `KONTROL_LISTESI.md`  
**Ana Kılavuz:** `../VERITABANI_KURULUM_KILAVUZU.md`

---

## 📊 YAPILAN İŞ

Bu klasördeki dosyalar şu şekilde hazırlandı:

1. ✅ 59+ SQL dosyası tarandı
2. ✅ Bağımlılıklar analiz edildi
3. ✅ 5 ana dosyaya birleştirildi
4. ✅ Sıralama optimize edildi
5. ✅ Her dosyaya header eklendi
6. ✅ Türkçe talimatlar yazıldı
7. ✅ Kontrol listeleri oluşturuldu

---

## 🎉 HAZIR!

Bu klasördeki dosyalar **tam olarak çalıştırılmaya hazır**.

**İlk adım:** `00_BASLANGIC_TALIMATLAR.md` dosyasını okuyun!

**Sonra:** SQL dosyalarını sırayla çalıştırın!

**Başarılar!** 🚀

---

**Oluşturulma Tarihi:** 7 Şubat 2026  
**Proje:** Gölge Krallık (GKK)  
**Versiyon:** 1.0  
**Hazırlayan:** GitHub Copilot Agent
