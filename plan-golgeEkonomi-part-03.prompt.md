### ⚔️ FAZA 6: GÖREV & ZİNDAN SİSTEMİ (Hafta 29-36)

**1. Görev Tipleri**
| Tip | Enerji | Kazanç | Risk | Süre |
|-----|--------|--------|------|------|
| Kolay Görev | 5-10 | 100-500 altın | ⭐ | 1-3 dk |
| Orta Görev | 10-15 | 500-2K | ⭐⭐ | 3-7 dk |
| Zor Görev | 15-20 | 2K-10K | ⭐⭐⭐ | 7-15 dk |
| Zindan (Solo) | 20-30 | 10K-100K | ⭐⭐⭐⭐ | 10-30 dk |
| Zindan (Grup) | 25-40 | 50K-500K | ⭐⭐⭐⭐⭐ | 20-60 dk |

**2. Başarı Formülü**
```
Başarı = %50 (baz) + Silah (+5-25%) + Zırh (+5-20%)
         + Beceri (+5-20%) + Seviye (+1-15%)
         + Lonca bonusu (+0-15%)
         - Zorluk (-10-40%)
```

**3. Başarısızlık Sonuçları**
- Enerji kaybı (zaten harcandı)
- Olası item durability loss (%20-40)
- Kritik başarısızlık → HASTANELİK (zindan için)
  - Zindan başarısızlığı: %15 hastanelik riski
  - Hastane süresi: 2-6 saat

**4. Görev Ödülleri**
- Altın (garantili)
- XP (garantili)
- Loot (şansa bağlı):
  - Temel: %60
  - Uncommon: %25
  - Nadir: %10
  - Epic: %4
  - Legendary: %0.9
  - Mythic: %0.1

---

### ⚔️ FAZA 7: PvP & SALDIRI SİSTEMİ (Hafta 37-44)

**1. Saldırı Mekanizması**
**Enerji Maliyeti:**
- Normal saldırı: 15 enerji
- Misilleme: 0 enerji (24 saat içinde)

**Saldırı Kısıtları:**
- Aynı oyuncuya 24 saat içinde max 3 saldırı
- Her saldırıda diminishing returns:
  - 1. saldırı: %100 ödül
  - 2. saldırı: %50 ödül
  - 3. saldırı: %25 ödül
- Saldırı cooldown: 30 dakika

**2. Güç Hesaplama**
```
Savaş Gücü = (
  Base Stats (level × 10) +
  Weapon Power (0-500) +
  Armor Defense (0-300) +
  Skill Bonuses (0-200) +
  Enchantments (0-150)
) × Random(0.85, 1.15)
```

**3. Savaş Sonucu Olasılıkları**
```
power_ratio = attacker_power / defender_power
base_win_chance = 0.5 + 0.3 × log(power_ratio)
win_chance = clamp(base_win_chance, 0.15, 0.85)
```

**4. Sonuç Tablosu**
| Sonuç | Olasılık | Saldırgan | Savunan |
|-------|----------|-----------|----------|
| Kritik Zafer | %10 (win içinde) | +150% ödül + ün | HASTANELİK (4-8 saat) |
| Zafer | win_chance | +100% ödül | -Altın -XP |
| Beraberlik | %5 | - | - |
| Yenilgi | 1-win_chance | -XP | +XP |
| Kritik Yenilgi | %10 (loss içinde) | HASTANELİK (2-4 saat) | +100% ödül + ün |

**Ödül Hesaplama:**
```
base_reward = defender_level × 100 + defender_gold × 0.05
capped_reward = min(base_reward, defender_gold × 0.20)
```

**5. Koruma Mekanizmaları**
- **Güvenli bölgeler:** şehir merkezleri (PvP yok)
- **Yeni oyuncu koruması:** ilk 7 gün veya level <10
- **Shield item:** 24 saat PvP immunity (nadir, market'te pahalı)
- **Lonca koruması:** lonca üyeleri saldırı bildirimi alır

**6. Ün (Reputation) Sistemi**
- Saldırı yapınca: -10 ün (aggressive)
- Savunma kazanınca: +5 ün
- Düşük ün (<-100): "Kırmızı oyuncu"
  - Herkese açık hedef
  - Şehir muhafızları saldırabilir
  - Tüccar fiyatları %20 artar
- Yüksek ün (>200): "Kahraman"
  - Tüccar indirimi %10
  - Özel görevler

---

### 🏥 FAZA 8: HASTANELİK SİSTEMİ (Hafta 45-48)

**1. Hastaneye Düşme Sebepleri**
| Sebep | Hastane Süresi | Önlenebilir mi? |
|-------|----------------|-----------------|
| İksir overdose | 2-12 saat | Evet (tolerans yönetimi) |
| PvP kritik yenilgi | 2-4 saat | Evet (güçlen/sakın) |
| PvP kritik zafer karşısında | 4-8 saat | Hayır (savunma) |
| Zindan kritik başarısızlık | 2-6 saat | Evet (donanım/seviye) |

**2. Hastanede Kısıtlar**
- Aktivite yapılamaz (görev/PvP/üretim)
- Sadece izlenebilir:
  - Chat
  - Market (görüntüleme + emir koyma)
  - Lonca mesajları
  - Ekipman planlama

**3. Hastaneden Çıkış Yolları**
**A. Süre bekle (ücretsiz)**
- Doğal iyileşme
- Garantili çıkış

**B. Gem harca**
- Maliyet: `remaining_minutes × 3`
- Anında çıkış
- Limit: günlük 3 kez (abuse önleme)

**C. Hekim çağır**
- Maliyet: 1,000-10,000 altın (süreye göre)
- Başarı şansı: %30-70 (hekim kalitesi)
- Başarı: süre %50-80 azalır
- Başarısızlık: süre %50 artar
- Cooldown: 1 deneme / hastanelik

**D. Lonca yardımı**
- Lonca üyeleri "heal" fonksiyonu kullanabilir
- Günlük limit: 3 heal / lonca
- Her heal: süre -%20
- Maliyetsiz (lonca bonusu)

**4. Hastane Ekonomisi**
- Hekim masrafı → para yakma
- Gem harcama → monetizasyon
- Lonca yardımı → sosyal bağ

---

### 🔨 FAZA 9: GELİŞTİRME (+BASMA) SİSTEMİ (Hafta 49-56)

**1. Geliştirme Oranları (Ortaçağ tarzı)**
| Seviye | Başarı | Düşme | Yok Olma | Maliyet |
|--------|--------|-------|----------|---------|
| +0→+3 | %100 | - | - | 1K-5K |
| +4→+6 | %70-50 | - | - | 15K-75K |
| +7 | %35 | %65 | - | 150K |
| +8 | %20 | %40 | %40 | 500K |
| +9 | %10 | %30 | %60 | 2M |
| +10 | %3 | - | %97 | 10M |

**2. Rün Taşı Sistemi (Scroll yerine)**
- Basit Rün: +%5 başarı (+0→+5)
- Gelişmiş Rün: +%10 başarı (+3→+7)
- Usta Rün: +%15 başarı (+6→+8)
- Efsanevi Rün: +%20 başarı (+8→+10)
- Koruma Rünü:
  - Yok olmayı engeller
  - Düşmeyi engeller

**3. Demirci (Anvil) Ekranı**
- Item slot + 3 rün slot
- Başarı/başarısızlık animasyonları
- Near-miss effect (psikolojik)

**4. Enflasyon Kontrolü**
- Geliştirme maliyeti = para yakar
- Başarısız deneme = para yakar
- Yok olan item = supply azalır

---

### 🏭 FAZA 10: ÜRETİM & BİNA SİSTEMİ (Hafta 57-64)

**1. Bina Kategorileri (15+)**
**Tier 1 Hammadde:**
- Maden (demir cevheri)
- Kereste deposu
- Çiftlik (yiyecek)
- Simya laboratuvarı (iksir üretimi)
- Tekstil (kumaş)

**Tier 2 İşleme:**
- Demirci (metal işleme)
- Deri işleme
- İlaç üretimi (antidot)

**Tier 3 Son Ürün:**
- Silah dökümhanesi
- Zırh atölyesi
- Rün oyma atölyesi

**Destek:**
- Mağaza
- Depo
- Güvenli ev
- Simyacı kulesi (high-level)

**2. Üretim Zinciri**
```
Demir Cevheri → Demirci → Silah Dökümhanesi → Kılıç
  +
Kereste ───────────────┘
  +
Rün Taşı ──────────────┘
```

**3. İksir Üretimi (Özel)**
**Simya Laboratuvarı:**
- Recipe gerekli (nadir drop)
- Malzemeler:
  - Bitki (görevlerden)
  - Mantar (zindanlardan)
  - Kristal (madenden)
- Üretim süresi: 30 dk - 4 saat
- Başarı şansı: %60-95 (kalite)

**İksir Tipi ve Üretim:**
| İksir | Recipe Nadirlık | Üretim Süresi | Başarı |
|-------|-----------------|---------------|--------|
| Minör | Temel | 30 dk | %95 |
| Büyük | Uncommon | 1 saat | %85 |
| Yüce | Nadir | 2 saat | %70 |
| Antidot | Epic | 4 saat | %60 |

**4. Loot/Drop Sistemi**
- Görev tipi → drop tabloları
- Rarity dağılımı (yukarıda)
- Legendary+ drop → sunucu duyurusu

---

### 📊 TELEMETRY & BALANCE

**Görev Metrikleri:**
- Görev başarı oranı (tip bazlı)
- Ortalama görev süresi
- Enerji tüketim hızı
- Hastanelik oranı (zindan)

**PvP Metrikleri:**
- Günlük saldırı sayısı
- Zafer/yenilgi oranı
- Güç dengesizliği (power ratio dağılımı)
- Hastanelik oranı (PvP)
- Misilleme kullanım oranı

**İksir & Üretim:**
- Günlük iksir üretimi
- Günlük iksir tüketimi
- Market fiyat trendi
- Üretim vs drop oranı

**Hastane:**
- Hastane günlük admission
- Ortalama süre
- Erken çıkış metod dağılımı (gem/hekim/lonca/wait)
- Hekim başarı oranı

**Balance Alarmları:**
- Görev başarı < %40 → çok zor
- PvP zafer oranı > %70 → dengesiz matchmaking
- İksir fiyatı 2x artış < 6 saat → supply problemi
- Hastanelik oranı > %10/gün → çok sert
