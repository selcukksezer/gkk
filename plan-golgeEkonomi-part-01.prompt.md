# Gölge Krallık: Kadim Mühür'ün Çöküşü — Ekonomi Planı (Ana Belge)

> Oyun Türü: Ortaçağ Tema MMORPG (Mobil - Godot 4.x)
> Backend: Supabase + Edge Functions
> Tasarım Hedefi: Server-authoritative, anti-cheat, dengeli ekonomi, sürdürülebilir monetizasyon (pay-to-win YOK)

---

## 🎯 GENEL TASARIM İLKELERİ

### Temel Konsept
Ortaçağ döneminde geçen karanlık bir krallıkta oyuncular maceralar yaparak, kaynak toplayarak, üretim yaparak ve savaşarak güçlenirler. Enerji sistemi oyun tempolarını düzenler; ancak iksirlerle enerji yönetimi risk-ödül dengesi sunar.

### Ekonomik Prensipler
1. **Enflasyon kontrolü:** para ve item kaynaklarından fazla "yakma mekaniği" (sink)
2. **Server-authoritative:** kritik işlemler (enerji tüketimi, RNG, PvP sonuçları) sadece server'da
3. **Şeffaf risk/ödül:** oyuncular seçimlerinin sonucunu anlamalı
4. **Anti-abuse dayanıklılığı:** her mekanik suistimale karşı koruma içerir
5. **Pay-to-win YOK:** sadece zaman/konfor satılır; güç satılmaz

---

## ⚡ FAZA 0: ENERJİ & İKSİR SİSTEMİ (Hafta 1-2)

### 0.1 Enerji Mekanizması
**Temel Kurallar:**
- Maksimum enerji: 100 (base)
- Doğal yenilenme: 1 enerji / 5 dakika (20/saat, 480/gün)
- Her aktivite enerji tüketir:
  - Görev (quest): 5-20 enerji
  - PvP saldırı: 10-15 enerji
  - Kaynak toplama: 5-10 enerji
  - Zindan (dungeon): 15-30 enerji

### 0.2 İksir Sistemi
**İksir Tipleri:**
- Minör İyileştirme İksiri: +20 enerji
- Büyük İyileştirme İksiri: +50 enerji
- Yüce İyileştirme İksiri: +100 enerji (max doldurur)
- Antidot: bağımlılık tedavisi

**Edinme Yolları:**
- Görev ödülleri
- Market (oyuncular arası)
- Simya/üretim
- Nadir loot

### 0.3 Bağımlılık Mekanizması
**Tolerans Sistemi:**
- Her oyuncunun `potion_tolerance` değeri (0-100)
- İksir kullanımı toleransı artırır:
  - Minör: +2
  - Büyük: +5
  - Yüce: +10

**Bağımlılık Eşikleri:**
| Tolerans | Etki | Durum |
|----------|------|-------|
| 0-30 | Normal | Sağlıklı |
| 31-60 | İksir etkisi %80'e düşer | Hafif tolerans |
| 61-85 | İksir etkisi %50'ye düşer | Bağımlı |
| 86-99 | İksir etkisi %20'ye düşer | Ağır bağımlı |
| 100 | İksir işe yaramaz + risk | Kritik |

**Aşırı Dozaj (Overdose):**
- Tolerans 80+ iken iksir içme → `overdose_risk` hesaplanır
- Risk formülü: `P(overdose) = 0.05 × (tolerance - 80)`
- Overdose sonucu → HASTANELİK (2-12 saat)

**Tolerans Azalması:**
- Doğal azalma: -1 / 6 saat (iksir kullanılmazsa)
- Antidot kullanımı: -30 (anında)
- Hekim tedavisi: -50 (ücretli + zaman)

### 0.4 Hastanelik Olma (Hospital System)
**Hastaneye Düşme Sebepleri:**
1. İksir overdose
2. PvP'de ağır yaralanma (HP %0'a düşme)
3. Zindan başarısızlığı (kritik hasar)

**Hastanede Geçen Süre:**
- Sebebe göre değişir (2-12 saat)
- Süre boyunca oyuncu aktivite yapamaz
- Chat/market görüntüleme yapabilir

**Hastaneden Çıkış:**
- Süre bekle (ücretsiz)
- Gem harca (dakika × 3)
- Hekim çağır (ücretli, %30-70 başarı, başarısızlıkta +%50 süre)

---

## 📊 FAZA 1: PAZAR & FİYAT ALGORİTMASI (Hafta 3-6)

### 1.1 Market Yapısı
- **Emir defteri (Order Book)** modeli
- Bölge bazlı market (şehir/kasaba)
- Item kategorileri:
  - Silahlar (kılıç, mızrak, yay)
  - Zırhlar
  - İksirler
  - Malzemeler
  - Taşınabilir eşyalar
  - Üretim kaynakları

### 1.2 Fiyat Hesaplama
- Arz-talep dengesi
- VWAP (hacim ağırlıklı ortalama)
- Dinamik band sistemi (volatilite kontrolü)
- Circuit breaker (ani fiyat patlamalarını engeller)

### 1.3 Anti-Manipülasyon
- Rate limiting
- Wash trading tespiti
- Spoofing önleme
- Bot/macro tespiti

**Detaylı bilgi:** [plan-golgeEkonomi-part-01a-detailed.prompt.md](plan-golgeEkonomi-part-01a-detailed.prompt.md)

---

## 🏰 FAZA 2: GÖREV & ZİNDAN SİSTEMİ (Hafta 7-12)

### 2.1 Görev (Quest) Sistemi
**Görev Tipleri:**
- Ana hikaye: krallığın sırrını çöz
- Yan görevler: kasaba sakinlerine yardım
- Günlük görevler: tekrarlayan aktiviteler
- Lonca görevleri: grup aktiviteleri

**Enerji Maliyeti & Ödüller:**
| Görev Tipi | Enerji | Altın | XP | Loot |
|------------|--------|-------|-----|------|
| Kolay | 5-10 | 100-500 | 50-200 | ⭐ |
| Orta | 10-15 | 500-2K | 200-800 | ⭐⭐ |
| Zor | 15-20 | 2K-10K | 800-3K | ⭐⭐⭐ |
| Zindan | 20-30 | 10K-100K | 3K-15K | ⭐⭐⭐⭐ |

### 2.2 Zindan (Dungeon) Sistemi
- Solo/grup zindanları
- Canavar sürüleri + boss
- Loot tabloları (rarity sistemi)
- Başarısızlıkta enerji kaybı + olası hastanelik

---

## ⚔️ FAZA 3: PvP & SALDIRI SİSTEMİ (Hafta 13-18)

### 3.1 Oyuncu vs Oyuncu Savaş
**Saldırı Mekanizması:**
- Oyuncular birbirlerine saldırı düzenleyebilir
- Enerji maliyeti: 10-15
- Saldırı mesafesi sınırı: aynı bölge/harita

**Güç Hesaplama:**
```
Savaş Gücü = Base Stats + Ekipman Gücü + Beceri Bonusları
```

**Sonuç Olasılığı:**
- Güç farkına göre kazanma olasılığı
- RNG faktörü (%20-80 arası kesin sonuç yok)

**Saldırı Sonuçları:**
| Sonuç | Saldırgan | Savunan |
|-------|----------|----------|
| Kritik Zafer | Altın + XP + ün | -Altın -XP, HASTANELİK |
| Zafer | Altın + XP | -Altın |
| Beraberlik | - | - |
| Yenilgi | -XP | +XP |
| Kritik Yenilgi | HASTANELİK | Altın + XP + ün |

### 3.2 Koruma Mekanizmaları
- Güvenli bölgeler (şehir merkezleri)
- Yeni oyuncu koruması (ilk 7 gün)
- Saldırı cooldown: 30 dakika
- Misilleme hakkı: 24 saat içinde tek saldırı (enerji bedava)

### 3.3 Ün (Reputation) Sistemi
- Saldırganlar "kırmızı" oyuncu olur
- Kırmızı oyunculara herkes saldırabilir
- Muhafızlar kırmızı oyuncuları saldırabilir
- Ün kazanma: görevler/yardım yaparak

---

## 🔨 FAZA 4: GELİŞTİRME & BASMA SİSTEMİ (Hafta 19-26)

### 4.1 Ekipman Geliştirme
**Seviye Sistemi (+0 to +10):**
| Seviye | Başarı | Kayıp | Yok Olma | Maliyet |
|--------|--------|-------|----------|---------|
| +0→+3 | %100 | - | - | 1K-5K altın |
| +4→+6 | %70-50 | - | - | 15K-75K |
| +7 | %35 | %65 | - | 150K |
| +8 | %20 | %40 | %40 | 500K |
| +9 | %10 | %30 | %60 | 2M |
| +10 | %3 | - | %97 | 10M |

### 4.2 Büyüleme (Enchanting)
- Rün taşları ile özel bonuslar
- Ateş hasarı +%
- Savunma +%
- Kritik şans +%

### 4.3 Simya (Alchemy) & Zanaatkarlık
- İksir üretimi
- Malzeme işleme
- Silah/zırh yapımı

---

## 🏭 FAZA 5: ÜRETİM & BİNA SİSTEMİ (Hafta 27-34)

### 5.1 Bina Tipleri
**Kaynak Üretimi:**
- Maden
- Kereste deposu
- Çiftlik
- Simya laboratuvarı

**İşleme:**
- Demirci
- Deri işleme
- Terzi

**Ticaret:**
- Mağaza
- Depo
- Lojistik

### 5.2 Üretim Zincirleri
```
Demir Cevheri → Demirci → Kılıç → Market
     +
Kereste ──────────┘
```

---

## 💬 FAZA 6: CHAT & LONCA SİSTEMİ (Hafta 35-42)

### 6.1 Lonca (Guild) Yapısı
- Kuruluş: 500K altın, Level 20
- Roller: Lord → Komutan → Şövalye → Asker → Çırak
- Bonuslar:
  - %0 üye arası market komisyonu
  - Grup görevlerinde +%15 başarı
  - Lonca deposu

### 6.2 Lonca Savaşları
- Haftalık turnuvalar
- Bölge kontrolü
- Kale kuşatması (gelişmiş PvP)

---

## 📅 FAZA 7: SEZON & SIRALAMA (Hafta 43-48)

### 7.1 Sezon Döngüsü
- 60-90 gün
- Sıfırlanan: altın, ekipman, seviye
- Kalıcı: gem, kozmetik, başarılar

### 7.2 Sıralama Ödülleri
- Top 1: Efsanevi sandık + 5000 gem + özel unvan
- Top 2-10: Nadir sandık + 2000 gem
- Top 11-50: İyi sandık + 1000 gem

---

## 💎 FAZA 8: MONETİZASYON (Hafta 49-52)

### 8.1 Gem Ekonomisi
**Ücretsiz Kazanım:**
- Günlük giriş
- Başarımlar
- Seviye atlama

**Gem Harcama:**
- Hastane çıkış (dakika × 3)
- Kozmetikler
- Ekstra envanter/bina slotu
- Premium analiz (7 gün)

### 8.2 ASLA Satılmayacaklar
❌ Güç (stat, ekipman)
❌ Altın
❌ Başarı şansı
✅ Zaman
✅ Konfor
✅ Kozmetik

---

## 🔒 GÜVENLİK & ANTİ-CHEAT (Sürekli)

### Server-Side Doğrulamalar
- RNG server-side
- Enerji tüketimi server-side
- PvP sonuçları server-side
- Audit logging tüm işlemler

### Rate Limiting
- API endpoint bazlı
- Oyuncu/IP bazlı
- İksir kullanımı
- PvP saldırı

### Anomali Tespiti
- İksir abuse
- Market manipulation
- PvP farming (aynı kişiye tekrar saldırı)
- Bot tespiti

---

## 📊 ANALYTİCS & METRIKLER

### Temel KPI'lar
- D1, D7, D30 retention
- ARPDAU
- Ekonomi sağlığı:
  - Altın sink/source dengesi
  - İksir tüketimi/üretimi
  - PvP aktivite oranı
  - Hastanelik oranları

### Risk Metrikleri
- Overdose oranı
- Bağımlılık dağılımı
- PvP dengesizliği
- Market manipülasyon sinyalleri

---

## 🚀 GELIŞTIRME ROADMAP

### Milestone 1 (0-8 hafta): Temel Sistemler
- Enerji + iksir
- Görev sistemi
- Market
- Temel PvP

### Milestone 2 (9-16 hafta): Ekonomi Derinliği
- Geliştirme/basma
- Üretim
- Loncalar

### Milestone 3 (17-24 hafta): Sosyal & Rekabet
- Lonca savaşları
- Sezon sistemi
- Sıralama

### Milestone 4 (25+ hafta): Polish & Lansman
- Güvenlik sertleştirme
- Analytics
- Soft launch

---

## 📖 DETAYLI DÖKÜMANLAR

- **Pazar/Market:** [part-01a](plan-golgeEkonomi-part-01a-detailed.prompt.md), [part-01b](plan-golgeEkonomi-part-01b-detailed.prompt.md)
- **Server/Client:** [part-02](plan-golgeEkonomi-part-02.prompt.md), [part-02a](plan-golgeEkonomi-part-02a-detailed.prompt.md), [part-02b](plan-golgeEkonomi-part-02b-detailed.prompt.md)
- **Görev/PvP/Hastane:** [part-03](plan-golgeEkonomi-part-03.prompt.md), [part-03a](plan-golgeEkonomi-part-03a-detailed.prompt.md), [part-03b](plan-golgeEkonomi-part-03b-detailed.prompt.md)
- **Sosyal/Sezon/Monetizasyon:** [part-04](plan-golgeEkonomi-part-04.prompt.md), [part-04a](plan-golgeEkonomi-part-04a-detailed.prompt.md), [part-04b](plan-golgeEkonomi-part-04b-detailed.prompt.md)

---

**Son Güncelleme:** 2 Ocak 2026
**Versiyon:** 2.0 (Ortaçağ + Enerji + PvP güncellemesi)
