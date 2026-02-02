# 🏭 TESISLER SİSTEMİ - ULTRA KAPSAMLI OYUN TASARIMI
> **Proje:** Gölge Krallık: Kadim Mühür'ün Çöküşü  
> **Tarih:** 30 Ocak 2026  
> **Tür:** The Crims + Knight Online Hybrid  
> **Hedef:** MMO-style Passive Income + Crafting System  

---

## 📊 OYUN MEKANICI ÖZET

```
Oyuncu deneyimi:
1. Enerji ile kaynak toplar (MiningScreen) → Hapishaneye giriş riski
2. Hapishane çıkış bedeli öder (PrisonScreen)
3. Tesisler satın alır ve upgrade eder (FacilitiesScreen)
4. Tesisler 24/7 offline üretim yapar
5. Üretilen materyallerle crafting yapar (CraftingScreen)
6. Crafted itemler market'te satılır
7. Güçlü itemler ile PvP/Dungeons yaparak daha çok kaynak toplar
```

---

## 🏢 15 TESİS TİPİ DETAYLARI

### **KATEGORİ 1: RAW KAYNAK ÜRETİMİ (4 tesis)**

#### 1️⃣ **MADEN (Mine) ⛏️**
- **Seviye 1-5:** 100 → 1600 demir/gün
- **Üretim:** Demir Cevheri, Demir Külçe, Kristal, Eter Tozu (nadir)
- **Kullanım:** Tüm metal tabanlı crafting'te
- **Upgrade Maliyeti:** 15K → 1.5M altın
- **Özellik:** Madenci ekle (+2/seviye)
- **Riski:** Hiç yok (kaynağı toplarken değil)

---

#### 2️⃣ **KERESTE DEPOSU (Lumber Mill) 🪵**
- **Seviye 1-5:** 100 → 1600 odun/gün
- **Üretim:** Ham Odun, İşlenmiş Tahta, Kömür
- **Kullanım:** Silah/zırh yapımında ara malzeme
- **Upgrade Maliyeti:** 8K → 800K altın
- **Özellik:** Orman yönetimi (dikmeyen ağaçlar → -%5/hafta üretim)
- **Riski:** Kaynağı toplarken hapishaneye giriş riski

---

#### 3️⃣ **ÇİFTLİK (Farm) 🌾**
- **Seviye 1-5:** 50 → 800 yiyecek/gün
- **Üretim:** Yiyecek, Bitki, Tohum, Su
- **Kullanım:** Simya lab'da buff iksiri yapımında
- **Upgrade Maliyeti:** 5K → 500K altın
- **Özellik:** Mevsimsel bonuslar
  - Bahar: +20% bitki
  - Yaz: +20% yiyecek
  - Sonbahar: +20% tohum
  - Kış: -%10 tüm üretim
- **Riski:** Düşük

---

#### 4️⃣ **HEYKELTTRAŞ (Quarry) 🪨**
- **Seviye 1-5:** 120 → 1200 taş/gün
- **Üretim:** Ham Taş, Cilalı Taş, Mermimer
- **Kullanım:** Bina upgrade'de ve bazı silahlar
- **Upgrade Maliyeti:** 12K → 1.2M altın
- **Özellik:** Ekipman kalite bonusu (silahın dayanıklılığını arttırır)
- **Riski:** Orta

---

### **KATEGORİ 2: CRAFTED ITEMS - İŞLENMİŞ ÜRÜN (6 tesis)**

#### 5️⃣ **DEMIRCI (Blacksmith) ⚒️**
- **Üretim:**
  - **Lv1:** Demir Kılıç, Demir Kalkan (5 item/gün)
  - **Lv2:** + Tunç Kılıç (10 item/gün, %10 Uncommon)
  - **Lv3:** + Çelik Kılıç (20 item/gün, %20 Uncommon)
  - **Lv4:** + Değerli Taş Kılıç (40 item/gün, %30 Uncommon + %5 Nadir)
  - **Lv5:** + Mitril Kılıç (80 item/gün, %40 Uncommon + %10 Nadir)
- **Gerekli Malzeme:** Demir, Odun, Kömür
- **Slot:** 2 → 6 (seviye ile artar)
- **Upgrade Maliyeti:** 10K → 1M altın
- **Rarity System:**
  ```
  COMMON (Beyaz):    70% şans
  UNCOMMON (Yeşil):  20% şans → +5 power bonus
  RARE (Mavi):       8% şans → +10 power bonus
  EPIC (Mor):        1.5% şans → +20 power bonus
  LEGENDARY (Turuncu): 0.5% şans → +30 power bonus
  ```
- **Özellik:** Kritik başarı sistemi
  - %5 ihtimalle Flawless item (tüm statlar +10%)
  - %2 ihtimalle failsafe (item hasar görmez)

---

#### 6️⃣ **ZİRH USTASI (Armorer) 🛡️**
- **Üretim:** Zırh takımları (Plaka, Zincir, Deri)
  - Helm, Chest, Legs, Boots (4 slot)
- **Lv1-5:** 3 → 60 zırh/gün
- **Gerekli Malzeme:** Demir/Taş, Deri, Kumaş
- **Rarity:** Demir ustası ile aynı
- **Özellik:** Zırh setleri (4 parça = 10% defense bonus)

---

#### 7️⃣ **SİMYA LABORATUVARı (Alchemy Lab) ⚗️**
- **Üretim:**
  - **Lv1:** Minör İksir (10/gün)
  - **Lv2:** + Büyük İksir (10 Minör + 5 Büyük)
  - **Lv3:** + Yüce İksir (20 Minör + 10 Büyük)
  - **Lv4:** + Antidot (5 adet)
  - **Lv5:** + Buff İksiri özel (10 adet)
- **Gerekli Malzeme:** Kristal, Bitki, Su
- **Slot:** 2 → 6
- **Upgrade Maliyeti:** 20K → 2M altın
- **Özellik:** Batch crafting
  - 5 aynı iksiri aynı anda yap → 1 adette upgrade (Büyük → Yüce)

---

#### 8️⃣ **RUNE CARVER (Rune Master) ✨**
- **Üretim:** Geliştirme taşları (Rune Stones)
  - Temel Rün (Lv1-3 boost)
  - Gelişmiş Rün (Lv4-7 boost)
  - Usta Rünü (Lv8-10 boost)
  - Efsanevi Rün (Custom boost)
- **Tipler:**
  - 🔴 Kızıl Rün: +Attack %
  - 🔵 Mavi Rün: +Defense %
  - 🟢 Yeşil Rün: +Health %
  - 🟡 Sarı Rün: +Experience % (derslere gelen bonus)
- **Üretim:** Lv1: 0 → Lv5: 10/hafta
- **Upgrade Maliyeti:** 25K → 2.5M altın

---

#### 9️⃣ **KAĞIT YAZARHANESI (Scroll Crafters) 📜**
- **Üretim:** Upgrade Scrolls
  - Safe Enhancement (success %100)
  - Blessed Enhancement (success % artar)
  - Guaranteed Extraction (failed item kurtarma)
- **Lv1-5:** 2 → 20 scroll/gün
- **Gerekli Malzeme:** Kağıt, Mürekkep, Kristal
- **Özellik:** Scroll leveli belirler (Safe +1 scroll Blessed'den daha düşük success)

---

#### 🔟 **DERİ İŞLEME (Leathercraft) 🦌**
- **Üretim:** Deri zırh & aksesuarlar
  - Deri Chest, Deri Legs, Deri Boots
  - Kemerbez, Eldive, Kemer
- **Lv1-5:** 5 → 50/gün
- **Rarity:** Orman için çalışan sistem (Uncommon → Legendary)
- **Özellik:** Şok direnci
  - Deri itemler fire/ice damage -10% resist

---

### **KATEGORİ 3: ADVANCED CRAFTING (3 tesis)**

#### 1️⃣1️⃣ **ENCHANTMENT ACADEMY (Enchanter) 🌠**
- **Fonksiyon:** ItemData içinde mevcut enhancement sistemi için +0 → +10
- **Özellik:**
  - +0-+3: %100 success, cost 1K-10K altın
  - +4-+6: %70-50 success, 15K-75K altın
  - +7: %35 success, 150K altın, safehouse risk
  - +8: %20 success, 500K altın, %40 destruction risk
  - +9: %10 success, 2M altın, %60 destruction risk
  - +10: %3 success, 10M altın, %97 destruction risk
- **Rune bonus:** Her rün +3% success, +2% destruction reduction
- **Lv1-5:** Daha hızlı upgrade (1.1x → 1.5x speed)

---

#### 1️⃣2️⃣ **CİNGEL WORKSHOP (Alchemist Advanced) 🧪**
- **Fonksiyon:** Advanced potion blending
- **Üretim:**
  - İksir kombinleme (2 farklı iksir = 3. yeni iksir)
  - Örnek: Büyük İksir + Rün Taşı = Büyük Güçlendirilmiş İksir
  - Büyük İksir + Antidot = Bağımlılık Kürü
- **Lv1-5:** Karışım hızı 1.1x → 1.5x
- **Özellik:** Keşif sistemi
  - Oyuncu 100 kez deneme yaparsa yeni iksir "unlock" edilir

---

#### 1️⃣3️⃣ **AUCTION HOUSE / MARKET HUB 🏪**
*This is NOT a facility in the traditional sense but acts as a crafting destination*
- **Fonksiyon:** Tüm crafted itemlerin satış noktası
- **Mekanik:**
  - Market tax: 10% (demirci → market: %10 kesinti)
  - Fiyat dinamikleri (arz-talep)
  - Player-to-player trade settlement
- **Ekstra:**
  - Price history grafikleri
  - Trending items
  - Bulk buy/sell options

---

### **KATEGORİ 4: SPECIAL FACILITIES (2 tesis)**

#### 1️⃣4️⃣ **TAVERN (Entertainment Hub) 🍺**
- **Fonksiyon:** Sosyal hub + passive bonuses
- **Özellik:**
  - Lonca üyeleri buluşurlar
  - Buff iksirlerini içerler (süre sınırlı)
  - Quest'ler başlarlar
  - Duyuru panosu
- **Lv1-5:** İksir etkisi 1.1x → 1.5x (duration artar)

---

#### 1️⃣5️⃣ **BANK / VAULT (Storage Hub) 🏦**
- **Fonksiyon:** Storage expansion + security
- **Özellik:**
  - Lv1: 50 slot inventory
  - Lv5: 200 slot inventory
  - Lonca shared storage (loncaya upgrade)
  - Insurance (item kaybı proteksiyonu, premium)
- **Upgrade:** 5K → 500K altın

---

## 💰 EKONOMI DENGESI

### **Kurulum Maliyeti vs Getiri**
```
DEMIRCI:
- Lv1 Satın Alma: 50K altın (first time unlock)
- Lv1 → Lv2 Upgrade: 10K altın + 100 odun + 50 demir
- Lv5 Toplam: 50K + 10K + 50K + 200K + 1M = 1.31M altın
- Günlük Verim Lv5: 80 silah × 500 altın (avg) = 40K altın/gün
- ROI: 1.31M ÷ 40K = 32.75 gün (market temkinli düşünüldüğünde)

SİMYA LAB:
- Lv1 Satın Alma: 30K altın
- Lv5 Toplam: 30K + 20K + 100K + 500K + 2M = 2.65M altın
- Günlük Verim Lv5: 30 Büyük İksir × 1000 altın (avg) = 30K altın/gün
- ROI: 2.65M ÷ 30K = 88 gün (daha uzun ama stratejik)
```

### **Inflation Control Mekanizması**
```
Altın Sink (Harcama):
- Facility upgrade: 50M-300M toplam (endgame)
- Enchantment (+0 → +10): 15M altın/item
- Market tax: Her satışta %10
- Potion crafting: 1K-2K per potion × 1000 potions/ay = 1-2M/ay

Altın Source (Kazanç):
- Crafted item sales: 10K-100K/item
- Quest rewards: 5K-50K
- Dungeon loot: 10K-200K
- Daily logins: 1K/day (utility)
- Facility production: 15K-50K/day (passive)
```

---

## 🎨 UI/UX DETAYLI TASARIMI

### **FacilitiesScreen (Tesisler Hub)**
```
┌─────────────────────────────────────────────────┐
│  🏭 TESİSLER      Toplam Getiri: 240K/gün      │
├─────────────────────────────────────────────────┤
│                                                  │
│  [Maden]     [Kereste]  [Çiftlik]  [Heykeltaş] │
│  ⛏️ Lv 3      🪵 Lv 2    🌾 Lv 1    🪨 Locked  │
│  45K/gün      30K/gün    25K/gün    ?          │
│  ✅ Aktif     ✅ Aktif    ✅ Aktif   🔒        │
│                                                  │
│  [Demirci]   [Zırh U.]   [Simya]    [Rün M.]   │
│  ⚒️ Lv 5     🛡️ Lv 3    ⚗️ Lv 4    ✨ Lv 2   │
│  50K/gün     35K/gün     60K/gün    25K/gün    │
│  ✅ Aktif    ✅ Aktif    ✅ Aktif   ✅ Aktif   │
│                                                  │
│  [Kağıt Y.]  [Deri İşl.] [Enchant] [Cincel]   │
│  📜 Lv 2     🦌 Lv 3     🌠 Lv 4   🧪 Lv 1    │
│  15K/gün     20K/gün     70K/gün    10K/gün    │
│  ✅ Aktif    ✅ Aktif    ✅ Aktif   ✅ Aktif   │
│                                                  │
│  [Taverna] [Vault]                              │
│  🍺 Lv 2   🏦 Lv 3 (50+75 slot = 125 total)    │
│  -         Storage Expanded                     │
│                                                  │
└─────────────────────────────────────────────────┘
```

---

### **FacilityDetailScreen (Detay + Üretim)**
```
┌──────────────────────────────────┐
│ DEMIRCI ⚒️ | YÜKSELT | YÖNETİM  │
├──────────────────────────────────┤
│ Seviye 5 / 5 (Max)               │
│ ████████████████████ 100%        │
│                                   │
│ STATUS PANEL:                     │
│ ├─ Yapı Durumu: ✅ Mükemmel      │
│ ├─ İşçi: 10/10                   │
│ ├─ Şüphe: 15% (Düşük)            │
│ └─ Son Şekillendirme: 2 saat     │
│                                   │
│ ┌─ AKTIF ÜRETİM ─────────────────┐│
│ │ Demir Kılıç (Rare)             ││
│ │ ████░░░░░ 45% | 1sa 20sn kaldı ││
│ │ [TOPLANDI] → Envantere Ekle    ││
│ │                                 ││
│ │ Demir Kılıç (Common)           ││
│ │ ██████░░░░ 60% | 2sa kaldı     ││
│ │ [Toplanmadı]                   ││
│ └─────────────────────────────────┘│
│                                   │
│ ┌─ TARİFLER ──────────────────────┐│
│ │ Demir Kılıç (COMMON)           ││
│ │ Gerekli: 10 Demir, 5 Odun     ││
│ │ Süre: 1 saat | Başarı: %95    ││
│ │ [BAŞLAT]                       ││
│ │                                 ││
│ │ Çelik Kılıç (UNCOMMON)         ││
│ │ Gerekli: 15 Demir, 10 Taş    ││
│ │ Süre: 1.5 saat | Başarı: %85  ││
│ │ [BAŞLAT]                       ││
│ │                                 ││
│ │ Mitril Kılıç (RARE)            ││
│ │ Gerekli: 25 Mitril, 20 Kristal││
│ │ Süre: 2 saat | Başarı: %70    ││
│ │ [BAŞLAT]                       ││
│ └─────────────────────────────────┘│
│                                   │
│ UPGRADE MALIYETI: 1M Altın        │
│ (İşçi + Alet + Ekipman)           │
│ [YÜKSELT] [İPTAL]                 │
└──────────────────────────────────┘
```

---

### **CraftingScreen (Crafting Hub)**
```
┌────────────────────────────────────────┐
│ ⚒️ CRAFTING | FİLTRE | SIRA           │
├────────────────────────────────────────┤
│ Demirci | Zırh U. | Simya | Enchant   │
├────────────────────────────────────────┤
│                                        │
│ TARIF SEÇIMI:                          │
│ ┌──────────────────────────────────┐  │
│ │ 🎯 Demir Kılıç (COMMON)          │  │
│ │    Başarı: %95 | Süre: 1sa      │  │
│ │    Gerekli:                      │  │
│ │    ├─ Demir ×10 (Available: 250) │  │
│ │    ├─ Odun ×5 (Available: 120)   │  │
│ │    └─ Kömür ×2 (Available: 45)   │  │
│ │                                  │  │
│ │ Rarity: COMMON (70% şans)        │  │
│ │ │ UNCOMMON (20% şans)            │  │
│ │ │ RARE (8% şans)                 │  │
│ │ │ EPIC (1.5% şans)               │  │
│ │ │ LEGENDARY (0.5% şans)          │  │
│ │                                  │  │
│ │ [BAŞLAT] [BATCH: 5x] [BATCH: 10x]   │
│ └──────────────────────────────────┘  │
│                                        │
│ BATCH CRAFTING:                        │
│ Aynı anda yapılabilecek: 6             │
│ Tahmini Süre: 6 × 1sa = 6 saat        │
│ (Facility Lv5 → 1.5x hız = 4 saat)   │
│                                        │
│ [HEMEN BAŞLAT] [24SAA SONRA TOPLA]   │
└────────────────────────────────────────┘
```

---

### **PrisonScreen Bağlantı**
```
┌──────────────────────────────────────┐
│ 🚨 TUTUKLANDINIZ                     │
├──────────────────────────────────────┤
│                                      │
│ Sebep: Kaynakların yasadışı toplanması
│                                      │
│ Tutukluluk Süresi:                  │
│ ████████░░░░░░░░░░░░ 45% | 6s 30d  │
│                                      │
│ Çıkış Seçenekleri:                  │
│                                      │
│ 💎 Jeton Öde                         │
│    Maliyet: 150 Gem                 │
│    Süre: Anında                     │
│    Günlük Limit: 3x                 │
│    [Öده]                            │
│                                      │
│ 💰 Rüşvet Ver (Polis)               │
│    Maliyet: 250K Altın              │
│    Başarı: 60%                      │
│    Başarısız: +%50 tutuluk süresi   │
│    Günlük Limit: 2x                 │
│    [RÜŞVETİ VER]                    │
│                                      │
│ ⏰ Bekle (Ücretsiz)                 │
│    [HOŞLANMADI - JETON KULLAN]      │
│                                      │
│ 📊 Tutukluluk Istatistikleri:       │
│    Bu ay: 3x tutukluluk             │
│    Total: 12 gün hapis              │
│    Yüksek Risk Oyuncusu: EVET       │
│    (PvP aktif oyuncular 2x risk)    │
└──────────────────────────────────────┘
```

**PrisonScreen Integration Points:**
- Kaynak toplarken başarısızlık = hapishane
- Şüphe seviyesi yüksekse = daha çok hapishane riski
- Lonca üyeleri daha düşük risk (koruma)
- VIP kullanıcılar %50 daha az tutuluk süresi

---

## 🎮 OYUNCU PROGRESSION ÖRNEKLERI

### **Yeni Oyuncu (Gün 1-7)**
```
❌ Tesisler Kilitli (Tümü 50K+ gerektiriyor)
├─ Enerji = 100, Her kaynağa 5-10 enerji malı
├─ Günlük kaynak toplama: 500-1000 altın (çok düşük)
├─ Hedef: 50K altın toplamak (7-14 gün)
└─ İlk tesis MADEN'i satın al

✅ Tesis Açılmaya Başladı (Gün 8-30)
├─ Maden Lv1: 100 demir/gün → 1K altın/gün pasif
├─ Kereste Lv1: 100 odun/gün
├─ Demirci Lv1 kodu aç (100K malı) → Silah yapımı başladı
├─ Ilk silahlar market'te satılsın → 500-2000 altın/item
└─ Passive income = 15K altın/gün'e ulaştı
```

### **Orta Oyuncu (Gün 30-90)**
```
🎯 Tesis Network'ü Kuruldu
├─ 8-9 tesis Lv2-3
├─ Passive income: 100K-150K altın/gün
├─ Crafted items: Rare → 10K+ altın/item
├─ Daily active play: 30-45 min
│  ├─ Enerji topla (mining)
│  ├─ Tesisler yönet (queue management)
│  ├─ Crafting batch başlat
│  ├─ Market'te item sat
│  └─ PvP/Dungeons yap (loot → kaynak → craft)
└─ Hedef: Demirci + Simya + Enchant Lv5'e ulaşmak

💹 Ekonomik Döngü:
PvP Loot → Kaynak (Alchemist Bazı) → Iksir → 
Buff → PvP Daha Başarılı → Daha Çok Loot → Cycle
```

### **Endgame Oyuncu (Gün 90+)**
```
🏆 Facility Mastermind
├─ 15 Tesis hepsi Lv5
├─ Passive income: 300K-500K altın/gün
├─ Crafted items: Legendary + Enchanted
├─ Market Monopoly: Spesifik item kategorisinde
├─ Lonca Hazinesi: Oyuncu Vault'tan shared production
└─ Yeni Hedef: PvP Ranking #1 (itemler ile mümkün)

🎪 Lonca Economic Warfare:
- Kendi loggında daha ucuz
- Rakip loncanın üretim hızını slow'lamaya çalış (itemler
  fiyatını düşür)
- Sezon sona erince reset → Yeni sıralamasından sonra
  tekrar kurma
```

---

## 🔧 TECHNICAL ARCHITECTURE

### **Database Schema Updates Required**

```sql
-- 1. Facilities Table (Existing, needs expansion)
ALTER TABLE facilities ADD COLUMN (
  facility_type VARCHAR(50),      -- "mine", "blacksmith", etc
  level INT DEFAULT 1,
  max_level INT DEFAULT 5,
  production_rate_bonus FLOAT DEFAULT 1.0,
  suspicion_level INT DEFAULT 0,
  worker_count INT DEFAULT 2,
  is_locked BOOLEAN DEFAULT FALSE,
  unlock_cost INT DEFAULT 50000,
  created_at TIMESTAMP,
  last_collected_at TIMESTAMP
);

-- 2. Recipes Table (New)
CREATE TABLE facility_recipes (
  id UUID PRIMARY KEY,
  facility_type VARCHAR(50),      -- "blacksmith", "alchemy", etc
  recipe_name VARCHAR(100),
  output_item_id VARCHAR(100),
  output_quantity INT DEFAULT 1,
  required_materials JSONB,       -- {"demir": 10, "odun": 5}
  duration_seconds INT,
  success_rate INT DEFAULT 100,   -- 0-100%
  gold_cost INT DEFAULT 0,
  base_suspicion_increase INT DEFAULT 0,
  facility_level_required INT DEFAULT 1,
  enabled BOOLEAN DEFAULT TRUE
);

-- 3. Production Queue (Existing, verify)
CREATE TABLE facility_queue (
  id UUID PRIMARY KEY,
  facility_id UUID REFERENCES facilities(id),
  recipe_id UUID REFERENCES facility_recipes(id),
  quantity INT DEFAULT 1,
  started_at TIMESTAMP,
  completed_at TIMESTAMP,
  is_collected BOOLEAN DEFAULT FALSE,
  actual_output_items JSONB       -- Result with rarity
);

-- 4. Item Rarity Log (New)
CREATE TABLE crafted_items_log (
  id UUID PRIMARY KEY,
  facility_id UUID,
  recipe_id UUID,
  rarity_roll FLOAT,              -- 0-1 random
  rarity_result VARCHAR(50),      -- "COMMON", "UNCOMMON", etc
  stats_modifier FLOAT,           -- 1.0 = normal, 1.1 = flawless
  created_at TIMESTAMP
);

-- 5. Prison Log (Existing, verify)
CREATE TABLE prison_records (
  id UUID PRIMARY KEY,
  player_id UUID REFERENCES auth.users(id),
  reason VARCHAR(255),
  admitted_at TIMESTAMP,
  release_at TIMESTAMP,
  released_via VARCHAR(50),       -- "wait", "gem", "bribe"
  cost_paid INT
);
```

### **API Endpoints**

```
FACILITIES:
GET    /v1/facilities              → [Get all owned facilities]
GET    /v1/facilities/{id}         → [Get single facility details]
POST   /v1/facilities/unlock       → [Unlock facility]
POST   /v1/facilities/{id}/upgrade → [Upgrade facility level]

RECIPES:
GET    /v1/recipes/{facility_type} → [Get recipes for facility type]
POST   /v1/recipes/search          → [Search recipes by output]

PRODUCTION:
POST   /v1/production/start        → [Start crafting job]
GET    /v1/production/{id}/status  → [Check queue status]
POST   /v1/production/{id}/collect → [Collect completed items]
POST   /v1/production/{id}/cancel  → [Cancel queue item]

CRAFTING:
GET    /v1/crafting/simulated      → [Simulate rarity roll]
POST   /v1/crafting/batch          → [Start batch crafting]

ECONOMY:
GET    /v1/economy/facility-stats  → [Global facility data]
GET    /v1/economy/market-prices   → [Item price history]
```

---

## 🛡️ SECURITY & ANTI-CHEAT

### **Server-Side Validations**

1. **Material Validation**
   ```
   Start production: Verify player has materials
   Collect production: Verify collection cooldown
   Batch crafting: Max 10x per batch, verify all slots free
   ```

2. **Suspicion Tracking**
   ```
   Every harvest/craft: +1-5 suspicion
   Bribe: -10 suspicion per 5 gems
   If suspicion > 80: Next harvest = 50% prison risk
   ```

3. **Prison Enforcement**
   ```
   ON harvest attempt:
   IF in_prison AND release_time > NOW:
     REJECT: "Tutuklusunuz"
   ```

4. **Rarity Determination**
   ```
   Client requests craft
   Server generates random(0, 1)
   if random < 0.005: LEGENDARY
   elif random < 0.015: EPIC
   ... apply rarity bonus to stats
   (Client NEVER sees RNG seed)
   ```

---

## 📱 OPTIMIZASYON NOTES

1. **Offline Production Calculation**
   - Login'de last_login timestamp'i kontrol et
   - 24 saat max (cap), fazlası boşa git
   - Production queue'de 3-4 job max (storage optim)

2. **Network Bandwidth**
   - Facility list: 1MB (15 facilityler)
   - Production queue: 50KB (crafting status)
   - Market prices: 200KB (item history)
   - Total per session: 2-5MB max

3. **Client-Side Caching**
   - Facility data cache: 5 min TTL
   - Recipe cache: 30 min TTL
   - Item price cache: 10 min TTL

4. **Mobile Optimization**
   - Button minimum size: 44x44 dp
   - Grid max columns: 2 (portrait), 3 (landscape)
   - Loading spinner: Smooth 60 FPS animation

---

## 📊 KPI & TELEMETRY

### **Tracking Events**

```
facility_unlocked
├─ facility_type
├─ player_level
└─ session_duration

crafting_started
├─ recipe_id
├─ batch_count
└─ expected_duration

crafting_completed
├─ recipe_id
├─ rarity_result
├─ success_rate_actual
└─ items_produced

facility_upgraded
├─ facility_type
├─ old_level → new_level
├─ cost_paid
└─ time_taken

prison_admission
├─ reason
├─ duration_seconds
└─ player_level

market_transaction
├─ item_id
├─ quantity
├─ price_per_unit
└─ profit_margin
```

### **Analytics Dashboard**

```
Daily Active Users (Facility engagement):
├─ % players who crafted today
├─ % players who checked facility queue
└─ Average session length (facility-related)

Economy Health:
├─ Total altın created (production)
├─ Total altın destroyed (upgrades)
├─ Market inflation rate
└─ Item price volatility

Facility Distribution:
├─ Most popular facility type
├─ Average level per facility type
├─ Upgrade completion rate (Lv1→Lv5)
└─ Time to first Lv5 facility

Crafting Success:
├─ Rarity distribution (COMMON vs LEGENDARY)
├─ Average success rate
├─ Batch crafting adoption
└─ Market item source analysis
```

---

## 🚀 IMPLEMENTATION ROADMAP

### **Phase 1: Foundation (Weeks 1-2)**
- [ ] Database schema finalized
- [ ] FacilitiesScreen UI finished
- [ ] Facility detail screen completed
- [ ] Basic production queue logic

### **Phase 2: Crafting (Weeks 3-4)**
- [ ] CraftingScreen UI
- [ ] Rarity RNG system
- [ ] Batch crafting backend
- [ ] Item stat calculation with rarity

### **Phase 3: Prison Integration (Week 5)**
- [ ] PrisonScreen → MiningScreen link
- [ ] Suspicion tracking system
- [ ] Prison admission RNG
- [ ] Bribe & gem release logic

### **Phase 4: Economy (Weeks 6-7)**
- [ ] Market price dynamics
- [ ] Tax collection system
- [ ] Inflation monitoring
- [ ] Admin dashboard

### **Phase 5: Polish & Launch (Weeks 8+)**
- [ ] Mobile optimization
- [ ] Telemetry dashboard
- [ ] Balance tuning
- [ ] Load testing (1000+ concurrent)

---

## 📝 NOTES

> **The Crims Comparison:**
> - Safehouse leveling → Facility leveling ✅
> - Production timers → 24/7 crafting ✅
> - Suspicion system → Prison risk ✅
> - Criminal career → Craft-based progression ✅

> **Knight Online Comparison:**
> - Rarity system (Common → Legendary) ✅
> - Enhancement system (+0 → +10) ✅
> - Item drop system → Crafting outcomes ✅
> - PvP gear progression → Market-driven ✅

> **Key Differentiator:**
> Oyuncular üretim yaparak **pasif gelir** sağlarken, 
> bu geliri kullanarak **daha güçlü silahlar** craftalyıp,
> bunlarla **daha zor dungeonlara** girebilir ve 
> **daha çok premium kaynak** toplayabilirler.
> Loop: Craft → Power ↑ → Content ↑ → Kaynak ↑ → Craft

---

**Versiyon:** 1.0 Draft  
**Yazarı:** Game Design Analyst  
**Son Güncelleme:** 30 Ocak 2026  
**Status:** Ready for Development ✅
