# Gölge Ekonomi — Monetizasyon Sistemi Detaylı Belge

> Kaynak: plan-golgeEkonomi-part-04.prompt.md (Faza 13)
> Oyun: Gölge Krallık: Kadim Mühür'ün Çöküşü
> Amaç: Gem ekonomisi, fiyatlandırma, battle pass, pay-to-win koruması

---

## 1. MONETİZASYON GENEL BAKIŞ

### 1.1 Tasarım İlkeleri
- **PAY-TO-WIN YOK:** Güç satılamaz, sadece konfor
- **Fair-to-play:** Ücretsiz oyuncular rekabetçi olabilir
- **Value proposition:** Harcanan para karşılığını verir
- **Sürdürülebilir:** Uzun vadeli gelir modeli
- **Etik:** Manipülasyon/bağımlılık yok

### 1.2 Monetizasyon Katmanları
```
Tier 1: Ücretsiz (F2P) - %85 oyuncu
Tier 2: Düşük harcama ($1-10) - %10 oyuncu
Tier 3: Orta harcama ($10-50) - %4 oyuncu
Tier 4: Yüksek harcama ($50+) - %1 oyuncu (whale)
```

---

## 2. GEM EKONOMİSİ

### 2.1 Ücretsiz Gem Kazanımı

**Günlük Kaynaklar:**
```
Günlük giriş: 10💎
Günlük görevler (3 adet): 30💎 (toplam)
Reklam izleme (max 3): 15💎 (5💎 × 3)
─────────────────────────
Günlük toplam: 55💎
```

**Haftalık Kaynaklar:**
```
Haftalık görevler: 100💎
Lonca görevi: 50💎
─────────────────────────
Haftalık toplam: 150💎
```

**Aylık Kaynaklar:**
```
Seviye atlama (ort. 10/ay): 200💎
Başarımlar: 100💎
Event katılımı: 200💎
Sezon sıralaması: 500-2000💎
─────────────────────────
Aylık toplam: ~2000-2500💎 (aktif oyuncu)
```

**Yıllık tahmin:**
```
Düzenli oyuncu: ~24,000-30,000💎/yıl
Hardcore oyuncu: ~40,000-50,000💎/yıl
```

### 2.2 Gem Satın Alma Paketleri

**Fiyatlandırma stratejisi:**
```typescript
interface GemPackage {
  id: string;
  gems: number;
  bonus: number;  // %
  price_usd: number;
  best_value?: boolean;
  first_time_bonus?: number;
}

const GEM_PACKAGES: GemPackage[] = [
  {
    id: "starter",
    gems: 100,
    bonus: 0,
    price_usd: 0.99,
    first_time_bonus: 50  // İlk alımda +50 gem
  },
  {
    id: "small",
    gems: 500,
    bonus: 20,  // +100 gem
    price_usd: 4.99
  },
  {
    id: "medium",
    gems: 1200,
    bonus: 40,  // +480 gem
    price_usd: 9.99,
    best_value: true
  },
  {
    id: "large",
    gems: 2500,
    bonus: 60,  // +1500 gem
    price_usd: 19.99
  },
  {
    id: "mega",
    gems: 8000,
    bonus: 80,  // +6400 gem
    price_usd: 49.99
  }
];
```

**Özel teklifler:**
```
• İlk alım: 2x gem bonus (bir kez)
• Haftalık teklif: %30 ekstra (sınırlı süre)
• Sezon başlangıcı: Özel paket (800💎 → $4.99)
• Doğum günü: Kişiye özel %50 indirim
```

### 2.3 Gem Harcama Yerleri

**A. Hastane Erken Çıkış (En popüler)**
```
Maliyet: remaining_minutes × 3

Örnek:
2 saat hastane = 120 dk × 3 = 360💎
4 saat = 240 dk × 3 = 720💎
8 saat = 480 dk × 3 = 1440💎
```

**Günlük limit:** 3 kez (abuse önleme)

**B. Kozmetikler (PAY-TO-WIN DEĞİL)**
```
Profil çerçevesi: 100-500💎
İsim rengi: 200💎
Chat efektleri: 150💎
Silah skini: 300-1000💎
Zırh skini: 300-1000💎
Pet (kozmetik): 500-2000💎
Emote: 100-300💎
Banner: 200-800💎
```

**C. Konfor & Slot Genişletme**
```
Envanter slot (+20): 500💎
Bina slot (+1): 800💎
Market emir slot (+5): 300💎
Production queue slot (+1): 400💎
Hızlı üretim (+50% hız, 7 gün): 600💎
```

**D. Premium Analiz (7 gün: 150💎)**
```
• Market trend grafiği
• Fiyat tahmin aracı
• Kişisel ekonomi raporu
• Lonca istatistikleri
• PvP rakip analizi
```

**E. Battle Pass (Sezon geçişi: 800💎)**
```
• 50 seviye ödül
• Gem geri kazanım (~1500💎 değerinde ödül)
• Özel kozmetikler
• XP boost
• Rün ve iksir bonusları
```

---

## 3. PAY-TO-WIN KORUMALARI

### 3.1 ASLA Satılmayacaklar

**❌ YASAK:**
```
• Silah/Zırh (güç)
• Altın (direkt)
• İksir (direkt)
• Rün taşları (direkt)
• Başarı şansı artırma
• XP boost (sezon geçişi hariç)
• Enerji satın alma (sadece iksirle, oyunda kazanılır)
• Seviye atlama
• Lonca puan
• PvP kazanma garantisi
```

**✅ İZİNLİ:**
```
• Zaman tasarrufu (hastane, üretim hızlandırma)
• Kozmetik (görsel)
• Konfor (slot, analiz)
• Bilgi (market araçları)
• Battle pass (karma ödül)
```

### 3.2 Soft-Paywall Stratejisi

**Ücretsiz oyuncu deneyimi:**
```
• Tüm içeriğe erişim ✓
• Rekabetçi olabilir ✓
• Lonca üyesi olabilir ✓
• Market kullanabilir ✓
• PvP yapabilir ✓

Fark:
• Hastanede daha uzun bekler
• Daha az slot
• Market analizi yok
• Kozmetik daha az
```

**Premium oyuncu deneyimi:**
```
• Her şey aynı + konfor
• Hızlı hastane çıkış
• Daha fazla slot
• Market araçları
• Özel kozmetikler
```

### 3.3 Competitive Balance

**F2P vs P2W denge:**
```typescript
function calculatePowerAdvantage(
  f2p_player: Player,
  whale_player: Player
): number {
  // Güç itemlerden gelir (alınamaz)
  const f2p_power = calculateCombatPower(f2p_player);
  const whale_power = calculateCombatPower(whale_player);
  
  // Maksimum fark: %5 (slot avantajından)
  const power_diff = (whale_power - f2p_power) / f2p_power;
  
  return power_diff; // Target: <0.05 (<%5)
}
```

**Telemetry:**
- F2P win rate vs whale: Target %45-55
- Alert eğer <%40 veya >%60

---

## 4. BATTLE PASS SİSTEMİ

### 4.1 İki Track Yapısı

**Free Track:**
```
Level 1: 1000 altın
Level 3: Minör iksir x5
Level 5: 100💎
Level 10: Kozmetik (basit)
Level 15: Rün (Basit) x2
Level 20: 200💎
Level 25: Nadir sandık
Level 30: 300💎
Level 40: Epic sandık
Level 50: Unvan "Sezon Veteranı" + 500💎
```

**Premium Track (800💎):**
```
Tüm free track + aşağıdakiler:

Level 1: +5000 altın
Level 3: Büyük iksir x5
Level 5: +200💎 (toplam 300💎)
Level 7: Özel emote
Level 10: Animasyonlu kozmetik
Level 12: +10% XP boost (30 gün)
Level 15: Rün (Gelişmiş) x3
Level 18: Pet (özel)
Level 20: +500💎 (toplam 700💎)
Level 25: Silah skini (legendary)
Level 30: +500💎 (toplam 800💎)
Level 35: Koruma rünü x1
Level 40: Zırh skini (legendary)
Level 45: +700💎 (toplam 1500💎)
Level 50: Efsanevi sandık + Özel unvan + Banner
```

**ROI (Return on Investment):**
```
Maliyet: 800💎
Geri kazanım: 1500💎 (gem) + ~5000💎 değerinde item
Net: +700💎 + items
```

### 4.2 XP Kazanımı

**Daily quests:**
```
Quest 1: 100 BP XP
Quest 2: 100 BP XP
Quest 3: 100 BP XP
─────────────────
Günlük: 300 BP XP
```

**Weekly quests:**
```
Week quest 1: 500 BP XP
Week quest 2: 500 BP XP
─────────────────
Haftalık: 1000 BP XP
```

**Gameplay:**
```
Görev tamamlama: 50 BP XP
Zindan clear: 100 BP XP
PvP zafer: 50 BP XP
Lonca görevi: 200 BP XP
```

**Toplam hesap (60 günlük sezon):**
```
Daily quests: 300 × 60 = 18,000 BP XP
Weekly quests: 1000 × 8 = 8,000 BP XP
Gameplay (ort.): 500 × 60 = 30,000 BP XP
─────────────────────────────────
Toplam: ~56,000 BP XP

Level 50 requirement: 50,000 BP XP
Sonuç: Aktif oyuncu rahatça bitirir
```

---

## 5. ÖZEL TEKLİFLER VE KAMPANYALAR

### 5.1 Starter Pack (İlk Alım)

**$4.99 (sadece bir kez):**
```
• 1000💎 (normal: 500💎)
• +5 Epic silah
• 10x Büyük İksir
• 7 gün XP boost (+30%)
• Özel "Başlangıç" unvanı
```

**Conversion rate hedef:** >20%

### 5.2 Haftalık Teklif

**Rotating offer (her pazartesi yenilenir):**
```
Hafta 1: Gem paketi %30 bonus
Hafta 2: Kozmetik paketi (3 skin) - $9.99
Hafta 3: Hızlandırma paketi (7 gün boost) - $4.99
Hafta 4: Battle pass %20 indirim
```

### 5.3 Seasonal Offers

**Sezon başlangıcı:**
```
"Taze Başlangıç Paketi" - $9.99
• 2000💎
• 10x Gelişmiş Rün
• 30x Büyük İksir
• 14 gün premium analiz
```

**Sezon sonu:**
```
"Son Hamle Paketi" - $19.99
• 5000💎
• 3x Koruma Rünü
• 50x Yüce İksir
• Özel banner
```

### 5.4 Event-Based Offers

**Lonca savaşı:**
```
"Savaş Hazırlık Paketi" - $14.99
• 3000💎
• 20x Büyük İksir
• 5x Usta Rün
• 3x Hastane çıkış (ücretsiz)
```

---

## 6. FİYATLANDIRMA STRATEJİSİ

### 6.1 Psikolojik Fiyatlandırma

**$0.99 noktaları:**
```
$0.99 (starter)
$4.99 (sweet spot)
$9.99 (best value perception)
$19.99 (whale bait)
$49.99 (mega whale)
```

**Anchor pricing:**
```
$49.99 paket göster (pahalı)
↓
$9.99 paketi "best value" etiketle
↓
Conversion artar ($9.99 makul görünür)
```

### 6.2 Bölgesel Fiyatlandırma

**Purchasing Power Parity (PPP):**
```typescript
const REGIONAL_MULTIPLIERS = {
  "US": 1.0,
  "TR": 0.3,  // Türkiye ekonomisi göz önünde
  "BR": 0.4,
  "IN": 0.25,
  "EU": 1.1,
  "JP": 1.2
};

function getLocalizedPrice(base_price_usd: number, region: string): number {
  const multiplier = REGIONAL_MULTIPLIERS[region] || 1.0;
  return base_price_usd * multiplier;
}
```

**Örnek (100💎 paketi):**
```
US: $0.99
TR: ₺9.99 (≈$0.30 PPP adjusted)
BR: R$1.99
IN: ₹25
EU: €0.99
JP: ¥150
```

### 6.3 Dynamic Pricing (Optional)

**Personalized offers:**
```typescript
function generatePersonalizedOffer(player: Player): Offer {
  // Son alım zamanı
  const days_since_purchase = daysSince(player.last_purchase);
  
  // Engagement level
  const engagement = player.daily_playtime_avg;
  
  // Gem dengesi
  const gem_balance = player.gems;
  
  if (days_since_purchase > 30 && engagement > 60) {
    // "Geri dön" teklifi
    return {
      discount: 0.30,
      message: "Seni özledik! %30 indirim"
    };
  }
  
  if (gem_balance < 100 && engagement > 90) {
    // Aktif ama gem yok
    return {
      discount: 0.20,
      message: "Sana özel teklif!"
    };
  }
  
  return null; // Standart fiyat
}
```

---

## 7. CONVERSION FUNNEL OPTİMİZASYONU

### 7.1 Satın Alma Akışı

**Friction points minimize:**
```
1. Gem ihtiyacı fark edilir (hastane, slot)
   ↓
2. "Gem Al" butonu (prominent)
   ↓
3. Paket seçimi (best value vurgusu)
   ↓
4. Ödeme yöntemi (1-click eğer kayıtlı)
   ↓
5. Onay (kolay, hızlı)
   ↓
6. Gem hesaba yüklenir (anında)
   ↓
7. "Teşekkürler" mesajı + bonus
```

**Conversion rate hedefler:**
```
Gem store görüntüleme → Paket seçimi: >40%
Paket seçimi → Ödeme başlatma: >60%
Ödeme başlatma → Başarılı ödeme: >90%

Toplam conversion: ~22%
```

### 7.2 Urgency Tactics

**Limited-time offers:**
```
• Countdown timer (48 saat)
• "Son 10 paket!" gösterimi
• Flash sale (2 saat)
```

**FOMO (Fear of Missing Out):**
```
• "Diğer oyuncular aldı!" (sosyal kanıt)
• "Bir daha gelmeyecek!" (nadir)
• Sezon özel itemler
```

**⚠️ Etik sınırlar:**
```
✓ Gerçek limited-time (teknik olarak sınırlı)
✓ Dürüst geri sayım (fake değil)
✗ Manipülatif karanlık desenler
✗ Çocuklara özel taktikler
✗ Bağımlılık tetikleme
```

---

## 8. MONETIZATION METRICS

### 8.1 KPI'lar

**Conversion:**
```
Install → Paying user: >5%
Free user → First purchase: >15%
First purchase → Repeat: >40%
```

**Revenue:**
```
ARPDAU (Average Revenue Per Daily Active User): >$0.15
ARPPU (Average Revenue Per Paying User): >$10
LTV (Lifetime Value): >$50
```

**Retention:**
```
D1 retention (paying users): >70%
D7 retention (paying users): >50%
D30 retention (paying users): >30%
```

### 8.2 Cohort Analysis

**Spending tiers:**
```typescript
interface SpendingTier {
  name: string;
  min_spent: number;
  max_spent: number;
  percentage: number;
  avg_ltv: number;
}

const SPENDING_TIERS: SpendingTier[] = [
  { name: "Non-payer", min_spent: 0, max_spent: 0, percentage: 85, avg_ltv: 0 },
  { name: "Minnow", min_spent: 0.01, max_spent: 10, percentage: 10, avg_ltv: 5 },
  { name: "Dolphin", min_spent: 10.01, max_spent: 50, percentage: 4, avg_ltv: 30 },
  { name: "Whale", min_spent: 50.01, max_spent: Infinity, percentage: 1, avg_ltv: 500 }
];
```

**Whale management:**
```
• VIP support (öncelikli)
• Özel teklifler
• Community spotlight
• Beta test access
```

---

## 9. ETIK MONETIZASYON

### 9.1 Dark Patterns'den Kaçınma

**❌ Yasak dark patterns:**
```
• Fake urgency (sahte geri sayım)
• Hidden costs (gizli ücret)
• Bait and switch (yanıltıcı reklam)
• Roach motel (iptal zorlaştırma)
• Confirmshaming (utandırma)
```

**✅ Etik yaklaşım:**
```
• Şeffaf fiyatlandırma
• Gerçek değer önerisi
• Kolay iptal/iade
• Çocuk koruması
• Bağımlılık farkındalığı
```

### 9.2 Çocuk Koruması

**Yaş kısıtlamaları:**
```
• 13 yaş altı: Hiç satın alma yapamaz
• 13-17 yaş: Ebeveyn onayı gerekir
• 18+ yaş: Tam erişim
```

**Spending limits:**
```
• 13-17 yaş: Max $10/hafta
• İlk 7 gün: Max $5 (yeni hesap)
• Fraud detection aktif
```

### 9.3 Addiction Prevention

**Harcama uyarıları:**
```
• $50 harcamada: "Bu hafta $50 harcadın"
• $100 harcamada: "Bu ay $100 harcadın, dikkatli ol"
• $500 harcamada: "Çok fazla harcıyorsun, destek lazım mı?"
```

**Self-exclusion:**
```
• "Spending pause" (7/30 gün)
• Kendini limitle ($10/gün, $50/hafta)
• Account freeze (geçici)
```

---

## 10. A/B TESTING

### 10.1 Test Senaryoları

**Fiyat testi:**
```
Variant A: Battle pass $7.99
Variant B: Battle pass $9.99 (control)
Variant C: Battle pass $11.99

Metric: Revenue per user
```

**Bundle testi:**
```
Variant A: 3 item bundle $4.99
Variant B: 5 item bundle $6.99
Variant C: 10 item bundle $9.99

Metric: Conversion rate
```

**UI testi:**
```
Variant A: "Best Value!" badge
Variant B: "Most Popular!" badge
Variant C: "Limited Time!" badge

Metric: Click-through rate
```

### 10.2 Statistical Significance

**Sample size:**
```
Minimum: 1000 users/variant
Confidence: 95%
Power: 80%
Duration: 7-14 gün
```

---

## 11. DEFINITION OF DONE

- [ ] Gem ekonomisi çalışıyor (kazanım/harcama)
- [ ] Satın alma akışı test edildi
- [ ] Battle pass sistemi aktif
- [ ] Pay-to-win korumaları doğrulandı
- [ ] Etik kontroller yapıldı
- [ ] A/B test altyapısı hazır
- [ ] Conversion tracking aktif
- [ ] Revenue metrikleri izleniyor

---

Bu döküman, monetizasyon sisteminin tam teknik spesifikasyonunu, etik korumalarını ve production-ready implementasyon detaylarını içerir.
