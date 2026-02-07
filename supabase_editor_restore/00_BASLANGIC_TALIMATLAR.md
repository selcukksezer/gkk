# 🎯 SUPABASE SQL EDİTÖR - VERİTABANI KURTARMA TALİMATLARI

## 📋 Genel Bakış

Bu klasörde, Supabase SQL Editor'de sırayla çalıştırmanız gereken **5 dosya** bulunmaktadır.
Her dosya, ilgili SQL migration'ları içerir ve doğru sırada çalıştırıldığında veritabanınızı tamamen geri yükler.

---

## 🚀 HIZLI BAŞLANGIÇ

### Adım 1: Supabase SQL Editor'ü Açın
```
https://app.supabase.com/project/znvsyzstmxhqvdkkmgdt/sql
```

### Adım 2: Dosyaları Sırayla Çalıştırın

Aşağıdaki dosyaları **tam olarak bu sırayla** çalıştırın:

1. ✅ **01_TEMEL_ALTYAPI.sql** (41KB)
2. ✅ **02_DUZELTMELER.sql** (19KB)
3. ✅ **03_ANA_SISTEMLER.sql** (24KB)
4. ✅ **04_RPC_FONKSIYONLAR.sql** (35KB)
5. ✅ **05_VERI_VE_ICERIK.sql** (43KB)

---

## 📝 DETAYLI TALİMATLAR

### DOSYA 1: 01_TEMEL_ALTYAPI.sql

**İçerik:**
- Envanter tablosu oluşturma
- Items tablosu ve normalizasyon
- Ekipman sistemi
- Slot pozisyon RPC'leri
- Hastane fonksiyonları

**Nasıl Çalıştırılır:**
1. `01_TEMEL_ALTYAPI.sql` dosyasını bir text editörde açın
2. Tüm içeriği kopyalayın (Ctrl+A, Ctrl+C)
3. Supabase SQL Editor'e yapıştırın
4. **RUN** butonuna basın
5. İşlem tamamlanana kadar bekleyin (~30 saniye)

**Beklenen Sonuç:**
```
✅ items tablosu oluşturuldu
✅ inventory tablosu oluşturuldu
✅ Temel RPC fonksiyonları eklendi
```

---

### DOSYA 2: 02_DUZELTMELER.sql

**İçerik:**
- Master düzeltme scripti
- Slot pozisyon düzeltmeleri
- Ekipman duplikasyon temizleme
- Envanter bütünlük kontrolleri

**Nasıl Çalıştırılır:**
1. `02_DUZELTMELER.sql` dosyasını açın
2. Tüm içeriği kopyalayın
3. Supabase SQL Editor'e yapıştırın
4. **RUN** butonuna basın
5. İşlem tamamlanana kadar bekleyin (~15 saniye)

**Beklenen Sonuç:**
```
✅ Slot pozisyonları düzeltildi
✅ Duplike ekipmanlar temizlendi
✅ Veri bütünlüğü sağlandı
```

**⚠️ Önemli:** Bu dosya bazı uyarılar verebilir ama normal. Devam edin.

---

### DOSYA 3: 03_ANA_SISTEMLER.sql

**İçerik:**
- Tesis (Facilities) sistemi
- Hapishane (Prison) sistemi
- Pazar (Market) sistemi

**Nasıl Çalıştırılır:**
1. `03_ANA_SISTEMLER.sql` dosyasını açın
2. Tüm içeriği kopyalayın
3. Supabase SQL Editor'e yapıştırın
4. **RUN** butonuna basın
5. İşlem tamamlanana kadar bekleyin (~20 saniye)

**Beklenen Sonuç:**
```
✅ facilities tablosu oluşturuldu
✅ prison tablosu oluşturuldu
✅ market_listings tablosu oluşturuldu
✅ İlgili RPC fonksiyonları eklendi
```

---

### DOSYA 4: 04_RPC_FONKSIYONLAR.sql

**İçerik:**
- Kaynak toplama RPC'leri
- Oyuncu tesisleri RPC'leri
- Tesis tarifleri RPC'leri
- Tesis yükseltme RPC'leri
- Satın alma RPC'leri
- Tesis kaynak toplama RPC'leri

**Nasıl Çalıştırılır:**
1. `04_RPC_FONKSIYONLAR.sql` dosyasını açın
2. Tüm içeriği kopyalayın
3. Supabase SQL Editor'e yapıştırın
4. **RUN** butonuna basın
5. İşlem tamamlanana kadar bekleyin (~25 saniye)

**Beklenen Sonuç:**
```
✅ collect_resources() fonksiyonu eklendi
✅ get_player_facilities() fonksiyonu eklendi
✅ get_facility_recipes() fonksiyonu eklendi
✅ upgrade_facility() fonksiyonu eklendi
✅ purchase_listing() fonksiyonu eklendi
```

---

### DOSYA 5: 05_VERI_VE_ICERIK.sql

**İçerik:**
- Tüm kaynak öğeleri (resource items)
- Üretilebilir öğeler (craftable items)
- Üretim tarifleri (crafting recipes)
- Tesis öğeleri
- Tesis tarifleri
- 15 kaynak tesisi

**Nasıl Çalıştırılır:**
1. `05_VERI_VE_ICERIK.sql` dosyasını açın
2. Tüm içeriği kopyalayın
3. Supabase SQL Editor'e yapıştırın
4. **RUN** butonuna basın
5. İşlem tamamlanana kadar bekleyin (~30 saniye)

**Beklenen Sonuç:**
```
✅ 100+ item tanımı eklendi
✅ 50+ üretim tarifi eklendi
✅ 15 kaynak tesisi eklendi
✅ Oyun içeriği hazır
```

---

## ✅ DOĞRULAMA

Tüm dosyaları çalıştırdıktan sonra, aşağıdaki sorguyu SQL Editor'de çalıştırın:

```sql
-- Tabloları kontrol et
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Kayıt sayılarını kontrol et
SELECT 
    'items' as table_name, COUNT(*) as count FROM public.items
UNION ALL
SELECT 'inventory', COUNT(*) FROM public.inventory
UNION ALL
SELECT 'facilities', COUNT(*) FROM public.facilities
UNION ALL
SELECT 'crafting_recipes', COUNT(*) FROM public.crafting_recipes;

-- RPC fonksiyonlarını kontrol et
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_type = 'FUNCTION'
ORDER BY routine_name;
```

**Beklenen Sonuçlar:**
- ✅ 15+ tablo görünmeli
- ✅ items tablosunda 100+ kayıt
- ✅ 30+ RPC fonksiyonu

---

## 🎯 BAŞARI KRİTERLERİ

Kurulum başarılı sayılır eğer:

- [ ] Tüm 5 dosya hatasız çalıştı
- [ ] 15+ tablo oluşturuldu
- [ ] items tablosunda veriler var
- [ ] RPC fonksiyonları çalışıyor
- [ ] Oyun bağlanabiliyor

---

## ⚠️ SORUN GİDERME

### "table already exists" Hatası
**Neden:** Tablo zaten mevcut  
**Çözüm:** Normal, devam edin. Script bunu handle eder.

### "column does not exist" Hatası
**Neden:** Önceki dosya atlandı  
**Çözüm:** Dosyaları sırayla çalıştırdığınızdan emin olun.

### "function does not exist" Hatası
**Neden:** Bağımlı dosya eksik  
**Çözüm:** Önceki dosyaları tekrar çalıştırın.

### "permission denied" Hatası
**Neden:** Yetki sorunu  
**Çözüm:** Supabase'de doğru kullanıcı ile giriş yaptığınızdan emin olun.

### Timeout Hatası
**Neden:** Dosya çok büyük  
**Çözüm:** 
1. Dosyayı iki parçaya bölün
2. İlk yarısını çalıştırın
3. İkinci yarısını çalıştırın

---

## 📊 DOSYA BİLGİLERİ

| Dosya | Boyut | Süre | İçerik |
|-------|-------|------|--------|
| 01_TEMEL_ALTYAPI.sql | 41KB | ~30s | Temel tablolar ve RPC'ler |
| 02_DUZELTMELER.sql | 19KB | ~15s | Düzeltme scriptleri |
| 03_ANA_SISTEMLER.sql | 24KB | ~20s | Tesis, hapishane, pazar |
| 04_RPC_FONKSIYONLAR.sql | 35KB | ~25s | İleri RPC fonksiyonları |
| 05_VERI_VE_ICERIK.sql | 43KB | ~30s | Oyun içeriği |
| **TOPLAM** | **162KB** | **~2dk** | **Tam veritabanı** |

---

## 💡 İPUÇLARI

1. **Her dosyadan sonra kontrol edin:** Hata mesajlarını okuyun
2. **Acele etmeyin:** Her dosyanın tamamlanmasını bekleyin
3. **Yedek alın:** Kurulum öncesi mevcut veriyi yedekleyin
4. **İnternet bağlantısı:** Kararlı bir bağlantı kullanın
5. **Tarayıcı:** Chrome veya Firefox önerilir

---

## 🎉 BAŞARILI KURULUM

Tüm dosyalar başarıyla çalıştıysa:

1. ✅ Veritabanınız tamamen geri yüklendi
2. ✅ Oyununuzu test edebilirsiniz
3. ✅ Tüm sistemler çalışır durumda
4. ✅ Yedek almayı unutmayın!

---

## 📞 DESTEK

Sorun yaşarsanız:
1. Hata mesajını tam olarak kaydedin
2. Hangi dosyada hata aldığınızı not edin
3. `VERITABANI_KURULUM_KILAVUZU.md` dosyasına bakın
4. `SQL_DOSYA_SIRALAMASI.md` dosyasında detaylı bilgi var

---

**Hazırlayan:** GitHub Copilot Agent  
**Tarih:** 7 Şubat 2026  
**Proje:** Gölge Krallık (GKK)  
**Versiyon:** 1.0

**Başarılar!** 🚀
