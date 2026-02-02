# Gölge Ekonomi — Plan Detaylandırma (Part 01B)

> Kaynak: plan-golgeEkonomi-part-01.prompt.md
> Oyun: Gölge Krallık: Kadim Mühür'ün Çöküşü
> Hedef: Market algoritması detayı + enerji-iksir ekonomisi entegrasyonu

---

## MARKET ALGORİTMASI DETAYI

### 1.1 Market Tasarım: Emir Defteri
**Emir Defteri (Order Book)** modeli:
- Her item için bölge bazlı order book
- Tek para birimi: `altın`
- Emir türleri: `limit buy`, `limit sell`, `market buy`, `market sell`

### 1.2 Bölgesel Market (Ortaçağ Şehirleri)
Oyun dünyasında birden fazla şehir/kasaba:
- Ana şehir (capital): yüksek hacim, düşük komisyon
- Sınır kasabaları: düşük hacim, yüksek komisyon
- Liman şehri: özel itemler

Her bölgenin özellikleri:
- `security_level`: güvenlik (PvP riski)
- `merchant_tax`: tüccar vergisi (%)
- `distance_from_capital`: arbitraj maliyeti

**Arbitraj:**
- Oyuncu itemleri ucuz bölgeden alıp pahalı bölgede satabilir
- Taşıma sırasında:
  - Haydut/PvP riski
  - Taşıma ücreti (sepet büyüklüğüne göre)
  - Enerji maliyeti (5-10 enerji/bölge değişimi)

### 1.3 Fiyat Gösterimi: "Last Price" + "VWAP" + "Band"
UI'da 3 sinyal:
- **Last price:** son gerçekleşen işlem
- **VWAP(1h):** son 1 saat hacim ağırlıklı
- **Band:** güncel fiyat bandı (anti-spike)

### 1.4 Fiyat Güncelleme Modeli

#### 1.4.1 Ana formül (log ratio)
$$ P_t = P_{t-1} \times e^{k \times \ln(\frac{Q_d}{Q_s})} $$
- $k$: 0.05–0.15 (item kategori hassasiyeti)
- $Q_d, Q_s$: son N dakika demand/supply

**İksir için k değeri:**
- Normal itemler: k=0.08
- İksirler: k=0.12 (daha reaktif)
- Antidot: k=0.15 (en reaktif)

#### 1.4.2 Yumuşatma (EMA)
$$ EMA_t = \alpha \cdot Price_t + (1-\alpha) \cdot EMA_{t-1} $$
- $\alpha = \frac{2}{n+1}$
- n=20 → alpha ~0.095

### 1.5 Market Matching (Eşleştirme) Kuralları
- Buy order en yüksek fiyattan sıralı
- Sell order en düşük fiyattan sıralı
- Eşleşme fiyatı: **maker price** (emri önce koyanın fiyatı)

### 1.6 Komisyon/Vergi (Para Yakma Mekaniği)
Market para yakar:
- **Tüccar komisyonu:** %2–5 (bölgeye göre)
- **Krallık vergisi:** %1–3
- **Lonca bonusu:** komisyon indirimi (maks %20 cap)

> İksir ekonomisinde asıl para yakma: simya maliyeti + hastane masrafları

### 1.7 Market Abuse Edge-Case'leri
- **0.01 fiyatla test order spam:**
  - min price floor + min qty
- **1 adetlik binlerce emir:**
  - order fee (sabit) + rate limit
- **Anlık iptal-spam:**
  - iptal cooldown + ücret

---

## ANTİ-MANİPÜLASYON VE ANTİ-ABUSE

### 2.1 Hedeflenen Saldırı Türleri
- **Spoofing:** büyük emir koyup iptal ederek algı yaratma
- **Wash trading:** kendi hesapları arasında işlem
- **Pump & dump:** fiyatı şişirip boşaltma
- **Cornering:** stok toplayıp arzı kısmak
- **Botting:** 7/24 emir yönetimi
- **İksir hoarding:** iksir stoklayıp fiyat patlatma

### 2.2 Savunma Katmanları

#### Katman A: Rate limiting (token bucket)
- `/market/order`: 30/dk
- `/market/cancel`: 60/dk
- `/trade/accept`: 10/dk
- Aynı item için 10/dk'dan fazla order → artan order fee

#### Katman B: Emir maliyeti (Order Fee)
- Her emir: sabit ücret
- İptal: küçük ücret veya cooldown

#### Katman C: Dinamik fiyat bandı
- Referans: `VWAP(24h)`
- Band: ±%10 (base) + volatiliteye göre genişler
- İksirler için: ±%15 (daha geniş, enerji talebi değişken)
- Band dışı emirler **engellenir**

#### Katman D: Circuit breaker
- 24h VWAP'a göre:
  - L1: %30 hareket → 30 dk trade durdur
  - L2: %50 hareket → 2 saat trade durdur
- İksir için özel kurallar:
  - Antidot: L1 %40, L2 %70 (daha esnek)

#### Katman E: Yeni hesap koruması
- İlk 7 gün:
  - Günlük işlem limiti: 50
  - Max emir değeri: 10K altın
  - İksir alımı: günlük 50 adet

### 2.3 Manipülasyon Tespit Sinyalleri
Her sinyal risk score besler:
- **Cancel ratio:** iptal / oluşturulan order
- **Order burst:** dakikada X üstü
- **Self-trade proximity:** aynı iki oyuncu tekrar eden işlem
- **IP/device overlap**
- **Price impact:** oyuncunun işlemi bandı zorladı mı?

### 2.4 Wash Trading Önleme
- Aynı IP'deki hesaplar arası eşleşme engellenir
- Aynı cihaz ID → risk score
- DM trade (pazarlıklı):
  - Sadece aynı bölgede
  - Vergi %10 (market %5'e kıyasla yüksek)
  - Günlük limit

### 2.5 Bot/Macro Tespit
MVP:
- Rate limiting
- Minimum action interval (500ms)
- Captcha (şüpheli durumda)

Gelişmiş:
- Davranış analizi:
  - Pixel-perfect tıklama
  - Milisaniye precision
  - İnsan olmayan pattern

### 2.6 Pump & Dump Önleme
- Tek oyuncu günlük hacmin %25'ini geçerse:
  - Trade slowdown
  - Risk flag
- Alım sonrası hızlı satış:
  - Holding cooldown (1-6 saat)

### 2.7 İksir Hoarding Önleme
**Özel kurallar:**
- Tek oyuncu envanter iksir limiti: 500 adet (stack total)
- Market'te açık iksir satış emri: max 100 adet
- Tek oyuncu toplam iksir supply'ın %5'ini geçerse alarm
- Banka deposu iksir limiti: 200 adet

### 2.8 Uygulanabilir Parametre Seti
Server config:
```
market.k_normal = 0.08
market.k_potion = 0.12
market.k_antidote = 0.15
market.ema_n = 20
market.band_base = 0.10
market.band_potion = 0.15
market.circuit_l1 = 0.30
market.circuit_l2 = 0.50
market.potion_circuit_l1 = 0.40
market.potion_circuit_l2 = 0.70
limits.order_per_min = 30
limits.cancel_per_min = 60
limits.potion_inventory_max = 500
limits.potion_market_order_max = 100
```

---

## ENERJİ & İKSİR EKONOMİSİ ENTEGRASYONU

### 3.1 İksir Talep Dinamikleri
İksir talebi şu faktörlerden etkilenir:
- **Enerji tüketim hızı:** aktif oyuncu sayısı
- **PvP aktivitesi:** savaşlar enerji tüketir
- **Görev yoğunluğu:** event/quest dönemleri
- **Bağımlılık oranı:** tolerans yüksek oyuncular daha çok alır

### 3.2 İksir Supply Kontrol Mekanizmaları
Server-side kontrol:
- **Drop rate ayarlama:** zindan/görev iksir düşme oranı
- **Simya üretim süreleri:** üretim hızını yavaşlatma
- **Recipe drop rate:** yüksek tier iksir tariflerini nadir yapma
- **NPC vendor fiyatı:** acil durum floor price

### 3.3 İksir Fiyat Senaryoları

#### Senaryo 1: Düşük aktivite
- Enerji tüketimi az
- İksir talebi düşük
- Fiyat düşer
- Server drop rate artırabilir (stokları eritme)

#### Senaryo 2: Event/PvP günü
- Enerji tüketimi yüksek
- İksir talebi patlama
- Fiyat yükselir (%40-70)
- Circuit breaker devreye girer
- Server müdahale: NPC vendor satış açabilir

#### Senaryo 3: Hoarding manipulation
- Tek grup toplam supply'ı topluyor
- Fiyat suni olarak yükseliyor
- Tespit: hoarding alarm
- Server müdahale: 
  - NPC vendor satış
  - Özel simya event (üretim bonusu)
  - Suspect hesapları flag

### 3.4 Antidot Ekonomisi
Antidot özel item:
- Sadece high-level simya ile üretilir
- Recipe nadir
- Üretim maliyeti yüksek
- Market fiyatı volatil

**Server garantisi:**
- NPC vendor her zaman satıyor (yüksek fiyattan)
- Floor price: 10K altın
- Availability guarantee: kritik bağımlılık durumunda

### 3.5 Bağımlılık ve Market İlişkisi
Oyuncu bağımlılık durumuna göre:
- **Tolerans 0-30:** normal alım
- **Tolerans 31-60:** alım miktarı artar
- **Tolerans 61+:** desperasyon, yüksek fiyat kabul eder

**Market manipülasyonu riski:**
- Bağımlı oyuncular price insensitive
- Manipülatörler bunu kullanabilir
- Koruma: daily purchase limit (200 adet)

---

## VERİ YAPILARI

### potion_tolerance
```sql
CREATE TABLE player_potion_tolerance (
  player_id UUID PRIMARY KEY,
  tolerance INTEGER NOT NULL DEFAULT 0,
  last_consumption TIMESTAMP,
  daily_consumption_count INTEGER DEFAULT 0,
  overdose_count INTEGER DEFAULT 0,
  last_overdose TIMESTAMP
);
```

### potion_market_analytics
```sql
CREATE TABLE potion_market_analytics (
  timestamp TIMESTAMP NOT NULL,
  region_id INTEGER NOT NULL,
  potion_type TEXT NOT NULL,
  total_supply INTEGER NOT NULL,
  daily_demand INTEGER NOT NULL,
  avg_price DECIMAL NOT NULL,
  price_volatility DECIMAL NOT NULL,
  hoarding_risk_score INTEGER DEFAULT 0,
  PRIMARY KEY (timestamp, region_id, potion_type)
);
```

### market_manipulation_alerts
```sql
CREATE TABLE market_manipulation_alerts (
  id UUID PRIMARY KEY,
  timestamp TIMESTAMP NOT NULL,
  player_id UUID NOT NULL,
  alert_type TEXT NOT NULL, -- 'wash_trade', 'spoofing', 'hoarding', 'pump_dump'
  risk_score INTEGER NOT NULL,
  evidence JSONB,
  status TEXT NOT NULL, -- 'open', 'reviewed', 'actioned'
  admin_notes TEXT
);
```

---

## TELEMETRİ & ANALYTICS

### İksir Ekonomi Dashboard
**Real-time metrikler:**
- İksir fiyat grafiği (24h)
- Supply/demand dengesi
- Bağımlılık dağılımı (histogram)
- Hoarding risk skorları
- Circuit breaker aktivasyonları

**Alarm eşikleri:**
- İksir fiyatı 2x artış < 6 saat
- Total supply < daily demand × 2
- Hoarding risk > 80
- Overdose rate > %5 (günlük aktif oyuncu)

### Manipülasyon Tespiti
**Günlük rapor:**
- Wash trade tespit: sayı
- Spoofing tespit: sayı
- Hoarding tespit: oyuncu listesi
- Bot davranışı: risk skorları

---

## OPERASYON PLAYBOOK

### Durum 1: İksir Fiyat Patlaması
**Belirti:**
- Fiyat 24h içinde %70+ arttı
- Circuit breaker tetiklendi

**Aksiyon:**
1. Hoarding tespiti yap
2. Suspect hesapları incele
3. NPC vendor satış aç (floor price)
4. Event duyurusu: "Simya üretim bonusu" (+%50 üretim hızı, 48 saat)

### Durum 2: Bağımlılık Oranı Yüksek
**Belirti:**
- Oyuncuların %30+ tolerans 60+
- Overdose oranı %8+

**Aksiyon:**
1. Hekim NPC'yi indirimli yap (tedavi maliyeti -%30)
2. Antidot drop rate artır
3. Quest ekle: "Bağımlılıkla mücadele" (ödül: antidot)
4. Awareness mesajı: "İksir bağımlılığı riskli!"

### Durum 3: Market Manipülasyonu Tespiti
**Belirti:**
- Wash trade alert > 10/gün
- Aynı grup hesaplar arası yüksek hacim

**Aksiyon:**
1. Suspect hesapları trade ban (geçici)
2. Ledger inceleme
3. Market integrity announcement
4. Anti-manipulation sistemlerini güncelle

---

## DEFINITION OF DONE

- [ ] Order book + fiyat algoritması çalışıyor
- [ ] İksir özel kuralları (band/circuit breaker) aktif
- [ ] Rate limiting + order fee aktif
- [ ] Anti-manipulation sinyalleri kaydediliyor
- [ ] İksir hoarding tespiti çalışıyor
- [ ] Bağımlılık ve market entegrasyonu doğru
- [ ] NPC vendor floor price mekanizması hazır
- [ ] Telemetri dashboard operasyonel
- [ ] Operasyon playbook dokümante edilmiş

---

**Son Güncelleme:** 2 Ocak 2026  
**Versiyon:** 2.0 (Ortaçağ + Enerji + İksir Ekonomisi)
