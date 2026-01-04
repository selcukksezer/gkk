# Gölge Ekonomi — Plan Detaylandırma (Part 01A)

> Kaynak: plan-golgeEkonomi-part-01.prompt.md
> Oyun: Gölge Krallık: Kadim Mühür'ün Çöküşü
> Tema: Ortaçağ MMORPG
> Hedef: Market algoritması + anti-manipülasyon + iksir ekonomisi için kurallar, parametreler, veri yapıları.

---

## PAZAR & FİYAT ALGORİTMASI

### 1.1 Market Tasarım Kararı: Emir Defteri
**Emir Defteri (Order Book)** modeli seçilir:
- **Artıları:** oyuncu stratejisi (undercut, spread), gerçek ekonomi hissi
- **Eksileri:** manipülasyon yüzeyi geniş

Minimum MVP:
- Her item için bölge bazlı order book
- Tek para birimi: `altın`
- Emir türleri: `limit buy`, `limit sell`, `market buy/sell`

### 1.2 Bölgesel Market (Ortaçağ Şehirleri)
Her bölge (şehir/kasaba) kendi pazarına sahip:
- `region_id` zorunlu
- Her bölgenin:
  - Tüccar komisyonu (değişken)
  - Güvenlik seviyesi
  - Ulaşım mesafesi (arbitraj için)

**Arbitraj:**
- Şehirler arası fiyat farkı her zaman var
- Oyuncu taşıma yapar; taşıma sırasında:
  - Haydut riski
  - Taşıma ücreti
  - Enerji maliyeti

### 1.3 İtem Kategorileri
Market kategorileri:
- **Silahlar:** kılıç, mızrak, yay, balta
- **Zırhlar:** plate, chain, leather
- **İksirler:** iyileştirme, enerji, buff, antidot
- **Malzemeler:** demir cevheri, kereste, deri
- **Rün taşları:** büyüleme için
- **Tarifler (recipe):** üretim için
- **Kozmetik:** (bind on pickup, sadece showcase)

### 1.4 Fiyat Gösterimi
UI'da oyunculara gösterilen 3 sinyal:
- **Last price:** son işlem fiyatı
- **VWAP(1h):** son 1 saat hacim ağırlıklı ortalama
- **Band:** güncel fiyat bandı (circuit breaker)

### 1.5 Fiyat Güncelleme Modeli

#### 1.5.1 Ana formül (log ratio)
$$ P_t = P_{t-1} \times e^{k \times \ln(\frac{Q_d}{Q_s})} $$
- $k$: 0.05–0.15 (item tipine göre)
- $Q_d, Q_s$: son N dakika demand/supply

#### 1.5.2 Yumuşatma (EMA)
$$ EMA_t = \alpha \cdot Price_t + (1-\alpha) \cdot EMA_{t-1} $$
- $\alpha = \frac{2}{n+1}$
- n=20 → alpha ~0.095

### 1.6 Market Matching (Eşleştirme)
- Buy emirler en yüksek fiyattan sıralı
- Sell emirler en düşük fiyattan sıralı
- Eşleşme fiyatı: **maker price** (emri önce koyanın fiyatı)

### 1.7 Komisyon/Vergi (Para Yakma)
Ekonomi dengelemek için market para yakar:
- **Tüccar komisyonu:** %2–5 (bölgeye göre)
- **Krallık vergisi:** %1–3
- **Lonca bonusu:** komisyon indirimi (maks %20)

> İksir ekonomisinde asıl para yakma simya/üretim ve hastane masrafları olacak.

### 1.8 Market Abuse Edge-Case'leri
- **0.01 fiyatla spam:**
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

### 2.2 Savunma Katmanları

#### Katman A: Rate limiting (token bucket)
- `/market/order`: 30/dk
- `/market/cancel`: 60/dk
- `/trade/accept`: 10/dk
- Aynı item için 10/dk'dan fazla order → artan order fee

#### Katman B: Emir maliyeti (Order Fee)
- Her emir koyma: sabit ücret (küçük ama caydırıcı)
- İptal: küçük ücret veya cooldown

#### Katman C: Dinamik fiyat bandı
- Referans: `VWAP(24h)`
- Band: ±%10 (base) + volatiliteye göre genişler
- Band dışı emirler engellenir

#### Katman D: Circuit breaker
- 24h VWAP'a göre:
  - L1: %30 hareket → 30 dk trade durdurma
  - L2: %50 hareket → 2 saat trade durdurma

#### Katman E: Yeni hesap koruması
- İlk 7 gün:
  - Günlük işlem limiti: 50
  - Max emir değeri: 10K altın
  - Withdraw kısıtı

### 2.3 Manipülasyon Tespit Sinyalleri
Her sinyal risk score besler:
- **Cancel ratio:** iptal / oluşturulan order
- **Order burst:** dakikada X üstü
- **Self-trade proximity:** aynı iki oyuncu tekrar eden işlem
- **IP/device overlap**
- **Price impact:** oyuncunun işlemi bandı zorladı mı?

### 2.4 Wash Trading Önleme
- Aynı IP'deki hesaplar arası eşleşme engellenir (soft)
- Aynı cihaz ID → risk score
- DM trade (pazarlıklı):
  - Sadece aynı bölgede
  - Vergi daha yüksek (%10)
  - Spam limit

### 2.5 Bot/Macro Tespit (MVP ve sonrası)
MVP:
- Rate limiting
- Minimum action interval (500ms)
- Captcha (şüpheli durumda)

Sonrası:
- Davranış özellikleri:
  - Pixel-perfect tıklama
  - Milisaniye precision timing
  - İnsan olmayan düzenli pattern

### 2.6 Pump & Dump Önleme
- Tek oyuncu günlük hacmin %25'ini geçerse:
  - Trade slowdown
  - Risk flag
- Alım sonrası hızlı satış:
  - Holding cooldown (1-6 saat)

### 2.7 Uygulanabilir Parametre Seti
Server config'den çekilecek, client hardcode olmayacak:
```
market.k = 0.08
market.ema_n = 20
market.band_base = 0.10
market.circuit_l1 = 0.30
market.circuit_l2 = 0.50
limits.order_per_min = 30
limits.cancel_per_min = 60
limits.min_order_value = 10
```

---

## İKSİR EKONOMİSİ & MARKET ENTEGRASYONU

### 3.1 İksir Fiyat Dinamikleri
İksirler özel kategori:
- **Yüksek volatilite:** enerji sistemi nedeniyle talep değişken
- **Server-kontrollü supply:** simya/drop oranları ayarlanabilir
- **Bağımlılık etkisi:** tolerans yüksek oyuncular daha çok alır

### 3.2 İksir Market Kuralları
- İksir alımında max stack: 100 (anti-hoarding)
- Günlük alım limiti: 200 adet (yeni hesaplar)
- Fiyat bandı daha dar: ±%15 (abuse'e karşı)

### 3.3 Antidot Ekonomisi
- Antidot'lar nadir
- Sadece simya ile üretilir (high-level)
- Market fiyatı yüksek
- Server minimum fiyat floor koyabilir (availability garantisi)

### 3.4 İksir Hoarding Tespiti
Telemetry:
- Tek oyuncu toplam iksir supply'ın %5'ini geçerse alarm
- Simya üretimi vs market satışı oranı izlenir
- Anomali → admin incelemesi

---

## VERİ YAPILARI (Database Schema)

### market_orders
```sql
CREATE TABLE market_orders (
  id UUID PRIMARY KEY,
  player_id UUID NOT NULL,
  region_id INTEGER NOT NULL,
  item_id INTEGER NOT NULL,
  order_type TEXT NOT NULL, -- 'buy' / 'sell'
  price DECIMAL NOT NULL,
  quantity INTEGER NOT NULL,
  filled_quantity INTEGER DEFAULT 0,
  status TEXT NOT NULL, -- 'active' / 'filled' / 'cancelled'
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP,
  idempotency_key UUID UNIQUE
);
```

### market_trades
```sql
CREATE TABLE market_trades (
  id UUID PRIMARY KEY,
  region_id INTEGER NOT NULL,
  item_id INTEGER NOT NULL,
  buyer_id UUID NOT NULL,
  seller_id UUID NOT NULL,
  quantity INTEGER NOT NULL,
  price DECIMAL NOT NULL,
  commission DECIMAL NOT NULL,
  timestamp TIMESTAMP NOT NULL
);
```

### market_ticker
```sql
CREATE TABLE market_ticker (
  region_id INTEGER NOT NULL,
  item_id INTEGER NOT NULL,
  last_price DECIMAL,
  vwap_1h DECIMAL,
  vwap_24h DECIMAL,
  volume_24h INTEGER,
  band_min DECIMAL,
  band_max DECIMAL,
  updated_at TIMESTAMP,
  PRIMARY KEY (region_id, item_id)
);
```

### potion_economy_log
```sql
CREATE TABLE potion_economy_log (
  id UUID PRIMARY KEY,
  timestamp TIMESTAMP NOT NULL,
  total_supply INTEGER NOT NULL,
  daily_production INTEGER NOT NULL,
  daily_consumption INTEGER NOT NULL,
  market_volume_24h INTEGER NOT NULL,
  avg_price DECIMAL NOT NULL,
  hoarding_alerts INTEGER DEFAULT 0
);
```

---

## TELEMETRİ & DASHBOARD

### Ekonomi Sağlık Metrikleri
- **Altın sink/source dengesi:** +/- %10 bant
- **İksir supply/demand:** 24h rolling
- **Market spread:** item başına ortalama
- **Volatilite:** günlük fiyat değişim %'si
- **Manipulation alerts:** günlük sayı

### Alarm Eşikleri
- Altın enflasyonu > %5/gün
- İksir fiyatı 2x artış < 6 saat
- Market wash trade tespit > 10/gün
- Bot davranışı tespit > 50/gün

---

## DEFINITION OF DONE (Faza 1)

- [ ] Order book create/cancel/match çalışıyor
- [ ] Bölgesel market ayrımı aktif
- [ ] Fiyat güncelleme algoritması doğru
- [ ] Circuit breaker aktif
- [ ] Rate limiting aktif
- [ ] Komisyon/vergi kesintisi doğru
- [ ] İksir market kuralları uygulanıyor
- [ ] Telemetri dashboard çalışıyor
- [ ] Anti-manipulation sinyalleri kaydediliyor

---

**Son Güncelleme:** 2 Ocak 2026  
**Versiyon:** 2.0 (Ortaçağ + İksir Ekonomisi)
