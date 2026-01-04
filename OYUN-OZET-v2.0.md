# GÖLGE KRALLIK: KADİM MÜHÜR'ÜN ÇÖKÜŞÜ
## Oyun Tasarımı Özet Döküman (v2.0 - 2 Ocak 2026)

---

## 🎮 OYUN HAKKINDA

**Tür:** Ortaçağ Tema MMORPG (Mobil)  
**Platform:** iOS/Android (Godot 4.x)  
**Backend:** Supabase + Edge Functions  
**Tema:** Karanlık ortaçağ krallığı, kadim mühürün çöküşü, kaos ve macera

---

## ⚡ ANA MEKANİKLER

### 1. ENERJİ SİSTEMİ
**Oyun temposu enerji ile kontrol edilir:**
- Maksimum enerji: 100
- Yenilenme: 1/5 dakika (288/gün)
- Her aktivite enerji tüketir:
  - Görevler: 5-20 enerji
  - PvP: 15 enerji
  - Zindan: 20-40 enerji

### 2. İKSİR & BAĞIMLILIK
**Enerji yönetimi için riskli seçim:**
- İksirler enerji doldurur ama bağımlılık yaratır
- Tolerans arttıkça iksir etkisi azalır
- Yüksek toleransta overdose riski
- Overdose → hastanelik (2-12 saat)

**Tolerans seviyeleri:**
- 0-30: Sağlıklı (%100 etki)
- 31-60: Hafif tolerans (%80 etki)
- 61-80: Bağımlı (%50 etki, %5+ overdose riski)
- 81+: Ağır bağımlı (%20 etki, %20+ overdose riski)

### 3. GÖREV & ZİNDAN
**PvE içerik:**
- 4 zorluk seviyesi (kolay → zindan)
- Enerji tüketimi + ödül dengesi
- Başarısızlık riski (özellikle zindan)
- Kritik başarısızlık → hastanelik

### 4. PvP (OYUNCU VS OYUNCU)
**Saldırı mekanizması:**
- Enerji maliyeti: 15
- Güç bazlı kazanma olasılığı
- 5 sonuç tipi: kritik zafer/zafer/beraberlik/yenilgi/kritik yenilgi
- Kritik sonuçlar → hastanelik (2-8 saat)
- Misilleme hakkı (24 saat, bedava)

**Ün sistemi:**
- Saldırgan → ün kaybı
- Düşük ün → "Haydut" (herkese açık hedef)
- Yüksek ün → "Kahraman" (bonuslar)

### 5. HASTANELİK
**3 sebep:**
- İksir overdose
- PvP kritik yenilgi
- Zindan kritik başarısızlık

**Çıkış yolları:**
- Bekle (ücretsiz)
- Gem harca (dakika × 3)
- Hekim çağır (%30-70 başarı, ücretli)
- Lonca yardımı (-%20 süre, ücretsiz)

### 6. MARKET & EKONOMİ
**Oyuncu odaklı ekonomi:**
- Emir defteri (order book) modeli
- Bölgesel pazarlar (arbitraj)
- Arz-talep dinamik fiyat
- Anti-manipülasyon sistemleri
- İksir özel ekonomi (volatilite kontrolü)

### 7. GELİŞTİRME & BASMA
**KO tarzı ekipman sistemi:**
- +0 → +10 seviye
- Başarı şansı azalır, risk artar
- Yok olma riski (+8 ve üstü)
- Rün taşları (scroll yerine)

### 8. LONCA (GUILD)
**Sosyal sistem:**
- Roller: Lord → Çırak
- Lonca deposu
- Grup görevleri
- Lonca savaşları (haftalık)
- Lonca hastane yardımı

### 9. SEZON & SIRALAMA
**60-90 günlük döngü:**
- Sıfırlanan: altın, ekipman, seviye, bina
- Kalıcı: gem, kozmetik, unvan
- Sıralama kategorileri: servet, PvP, görev, ekonomi, lonca
- Sezon sonu ödülleri

### 10. MONETİZASYON
**PAY-TO-WIN YOK:**
- ✅ Gem ile: hastane çıkış, kozmetik, slot, analiz
- ❌ Gem ile: güç, altın, iksir, başarı şansı

**Gem kaynakları:**
- Ücretsiz: günlük giriş, başarım, seviye (200/hafta)
- Satın alma: $0.99 - $49.99

---

## 📊 SİSTEM AKIŞI

### Oyuncu Döngüsü
```
1. Enerji dolu → Aktivite yap (görev/PvP/zindan)
2. Enerji azalır → İksir mi? Bekle mi?
3. İksir kullan → Tolerans artar → Risk artar
4. Aktivite tekrar → Ödül kazan / Risk al
5. Başarısız → Hastane → Çıkış seçimi → Döngü devam
```

### Ekonomi Döngüsü
```
1. Görev/PvP → Altın kazan
2. Market → Item al/sat
3. Geliştirme → Altın yak (enflasyon kontrolü)
4. Üretim → Kaynak üret → Market'e sat
5. İksir ekonomisi → Supply/demand → Fiyat dinamiği
```

---

## 🔐 GÜVENLİK & ANTİ-CHEAT

**Her şey server-authoritative:**
- Enerji hesaplama
- İksir etkisi ve tolerans
- Overdose RNG
- PvP sonuçları
- Görev başarı/başarısızlık
- Market işlemleri

**Anti-abuse:**
- Rate limiting (API endpoint bazlı)
- Günlük limitler (iksir, gem kullanımı)
- Anomali tespiti (telemetri)
- Audit logging (her kritik işlem)
- Security events (inceleme için)

---

## 🎯 HEDEF METRIKLER

### Retention
- D1: >40%
- D7: >20%
- D30: >10%

### Ekonomi Sağlığı
- Altın sink/source dengesi: ±%10
- İksir tüketimi/üretimi: ±%15
- Market volatilite: <%50
- Hoarding riski: <5 oyuncu

### Oyuncu Sağlığı
- Ortalama enerji: 40-60
- Bağımlılık (tolerans >60): <%40
- Overdose oranı: <%5/gün
- Hastanelik oranı: <%10/gün
- PvP aktivite: %30-50

### Monetizasyon
- ARPDAU: >$0.15
- Gem conversion: >5%
- Crash-free rate: >99%

---

## 📅 GELİŞTİRME ROADMAP

### Milestone 1 (0-8 hafta): Temel Sistemler
- Enerji + iksir + bağımlılık
- Görev sistemi (temel)
- Market (MVP)
- Temel PvP

### Milestone 2 (9-16 hafta): Ekonomi Derinliği
- Geliştirme/basma
- Üretim (5 bina)
- İksir ekonomisi entegrasyonu
- Hastane sistemi

### Milestone 3 (17-24 hafta): Sosyal & Rekabet
- Lonca sistemi
- Lonca savaşları
- PvP ranking
- Ün sistemi

### Milestone 4 (25-32 hafta): Polish & Sezon
- Sezon sistemi
- Sıralama
- Battle pass
- Event sistemi

### Milestone 5 (33+ hafta): Lansman
- Güvenlik sertleştirme
- Analytics dashboard
- Alpha → Beta → Soft launch → Global

---

## 📖 DETAYLI DÖKÜMANLAR

### Ana Planlar
- [**Ana Plan**](plan-golgeEkonomi-part-01.prompt.md) - Genel bakış
- [**Server/Client**](plan-golgeEkonomi-part-02.prompt.md) - Mimari
- [**Görev/PvP**](plan-golgeEkonomi-part-03.prompt.md) - Gameplay
- [**Sosyal/Sezon**](plan-golgeEkonomi-part-04.prompt.md) - Sosyal sistemler

### Detaylı Belgeler
- [**Market Detay**](plan-golgeEkonomi-part-01a-detailed.prompt.md) - Pazar algoritması
- [**Market Anti-Manip**](plan-golgeEkonomi-part-01b-detailed.prompt.md) - Güvenlik
- [**Görev Detay**](plan-golgeEkonomi-part-03a-detailed.prompt.md) - Quest sistemi
- [**Enerji & İksir**](plan-golgeEkonomi-ENERGY-POTION-detailed.prompt.md) - Bağımlılık sistemi
- [**PvP Detay**](plan-golgeEkonomi-PVP-detailed.prompt.md) - Savaş mekanizması

---

## 🎮 OYUN FARKI (USP)

1. **Risk/Ödül İksir Mekanizması:** Hızlanmak için iksir kullan, ama bağımlı olma riski
2. **Server-Authoritative Ekonomi:** Adil, manipülasyon yok
3. **PvP + PvE Dengesi:** Her iki oyun tarzı da destekleniyor
4. **Ortaçağ Karanlık Tema:** Ciddi, yetişkin odaklı hikaye
5. **Pay-to-win YOK:** Sadece zaman/konfor satılır
6. **Sezon Sistemi:** Düzenli sıfırlama, sürekli yenilik

---

## ⚠️ ÖNEMLİ NOTLAR

### Bağımlılık Mekaniği Hassasiyeti
- Gerçek hayat bağımlılık ciddi konu
- UI'da "oyun mekaniği" olarak açıkça belirtilmeli
- Age rating: 12+ (PEGI/ESRB)
- Disclaimer: "Bu bir oyun mekaniğidir, gerçek hayat tavsiyesi değildir"

### Server Kapasite
- İlk 6 ay Supabase yeterli
- 100K+ DAU için custom backend gerekli
- Redis caching kritik (enerji/tolerance)

### Godot Limitasyonları
- Built-in multiplayer yetersiz (100+ concurrent)
- REST + WebSocket hibrit zorunlu
- Real-time PvP için optimizasyon

---

## 🚀 LANSMAN PLANI

1. **Alpha** (50-100 oyuncu, 4 hafta)
2. **Closed Beta** (500-1000 oyuncu, 4 hafta)
3. **Open Beta** (5000+ oyuncu, 4 hafta)
4. **Soft Launch** (3 ülke, 2 hafta)
5. **Global Launch** (dünya çapında)

---

**Proje Başlangıç:** 2 Ocak 2026  
**Tahmini Lansman:** Eylül 2026  
**Versiyon:** 2.0 (Ortaçağ + Enerji + PvP güncellemesi)

**Ekip İhtiyacı:**
- 1x Backend Developer (Supabase/PostgreSQL)
- 1x Frontend Developer (Godot 4.x)
- 1x Game Designer / Balance
- 1x UI/UX Designer
- 1x Artist (2D sprite/UI)
- 0.5x DevOps (part-time)

**Bütçe Tahmini:**
- Development: $50K-80K (6-8 ay)
- Marketing: $20K-50K (soft launch + global)
- Server: $500/ay (başlangıç)
