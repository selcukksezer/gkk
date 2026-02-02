# Kapsamlı Crafting Sistemi Blueprint 🛠️

## Genel Bakış

**Amaç:** 15 kaynak tesisinden toplanan malzemeleri kullanarak tüm oyun itemlerini üretmek için detaylı tarifler oluşturmak.

**Sistem Tasarımı:**
- **Tesisler** = Kaynak toplama (mining, farming, etc.)
- **Simya/Crafting** = Item üretimi (tüm tarifler burada)

---

## 1️⃣ KAYNAK TESİSLERİ VE ÇIKARILABİLİR MALZEMELER

### 🪨 Temel Kaynaklar (1-5)

#### Mining (Maden Ocağı)
**Kaynaklar:**
- `iron_ore` - Demir Cevheri (En yaygın)
- `copper_ore` - Bakır Cevheri (Yaygın)
- `silver_ore` - Gümüş Cevheri (Nadir)
- `gold_ore` - Altın Cevheri (Çok nadir)
- `mithril_ore` - Mithril Cevheri (Efsanevi) *%2 şans*

#### Quarry (Taş Ocağı)
**Kaynaklar:**
- `granite` - Granit (Yaygın)
- `marble` - Mermer (Nadir)
- `crystal_shard` - Kristal Parçası (Nadir)
- `obsidian` - Obsidyen (Çok nadir)
- `moonstone` - Ay Taşı (Efsanevi) *%2 şans*

#### Lumber Mill (Kereste Fabrikası)
**Kaynaklar:**
- `oak_wood` - Meşe Odunu (Yaygın)
- `pine_wood` - Çam Odunu (Yaygın)
- `bamboo` - Bambu (Nadir)
- `elder_wood` - Kadim Ağaç (Çok nadir)
- `world_tree_sap` - Dünya Ağacı Özsuyu (Efsanevi) *%2 şans*

#### Clay Pit (Kil Ocağı)
**Kaynaklar:**
- `ceramic_clay` - Seramik Kili (Yaygın)
- `brick_clay` - Tuğla Kili (Yaygın)
- `enchanted_clay` - Büyülü Kil (Nadir)
- `dragon_clay` - Ejderha Kili (Çok nadir) *%5 şans*

#### Sand Quarry (Kum Ocağı)
**Kaynaklar:**
- `glass_sand` - Cam Kumu (Yaygın)
- `crystal_sand` - Kristal Kumu (Nadir)
- `star_dust` - Yıldız Tozu (Çok nadir)
- `void_sand` - Boşluk Kumu (Efsanevi) *%2 şans*

---

### 🌿 Organik Kaynaklar (6-10)

#### Farming (Çiftlik)
**Kaynaklar:**
- `wheat` - Buğday (Yaygın)
- `vegetables` - Sebze (Yaygın)
- `cotton` - Pamuk (Yaygın) 
- `magical_grain` - Büyülü Tahıl (Nadir)
- `golden_wheat` - Altın Buğday (Çok nadir) *%3 şans*

#### Herb Garden (Ot Bahçesi)
**Kaynaklar:**
- `healing_herb` - Şifalı Ot (Yaygın)
- `poison_herb` - Zehirli Ot (Nadir)
- `rare_flower` - Nadir Çiçek (Nadir)
- `dragon_root` - Ejderha Kökü (Çok nadir)
- `phoenix_petal` - Anka Kuşu Yaprağı (Efsanevi) *%1 şans*

#### Ranch (Hayvancılık)
**Kaynaklar:**
- `leather` - Deri (Yaygın)
- `bone` - Kemik (Yaygın)
- `wool` - Yün (Yaygın)
- `monster_hide` - Canavar Derisi (Nadir)
- `dragon_scale` - Ejderha Pulları (Efsanevi) *%2 şans*

#### Apiary (Arıcılık)
**Kaynaklar:**
- `honey` - Bal (Yaygın)
- `beeswax` - Balmumu (Yaygın)
- `bee_venom` - Arı Zehiri (Nadir)
- `royal_jelly` - Arı Sütü (Çok nadir)
- `celestial_honey` - İlahi Bal (Efsanevi) *%1 şans*

#### Mushroom Farm (Mantar Çiftliği)
**Kaynaklar:**
- `healing_mushroom` - Şifalı Mantar (Yaygın)
- `poison_mushroom` - Zehirli Mantar (Nadir)
- `glowing_mushroom` - Parlak Mantar (Nadir)
- `ghost_mushroom` - Hayalet Mantar (Çok nadir)
- `immortality_shroom` - Ölümsüzlük Mantarı (Efsanevi) *%1 şans*

---

### ✨ Mistik Kaynaklar (11-15)

#### Rune Mine (Rune Madeni)
**Kaynaklar:**
- `raw_rune` - Ham Rune (Yaygın)
- `magic_crystal` - Büyü Kristali (Nadir)
- `energy_shard` - Enerji Kırıntısı (Nadir)
- `power_rune` - Güç Rünü (Çok nadir)
- `ancient_rune` - Kadim Rün (Efsanevi) *%2 şans*

#### Holy Spring (Kutsal Kaynak)
**Kaynaklar:**
- `holy_water` - Kutsal Su (Yaygın)
- `mana_crystal` - Mana Kristali (Nadir)
- `purification_water` - Arınma Suyu (Nadir)
- `blessed_essence` - Kutsanmış Öz (Çok nadir)
- `divine_tear` - İlahi Gözyaşı (Efsanevi) *%1 şans*

#### Shadow Pit (Gölge Çukuru)
**Kaynaklar:**
- `dark_essence` - Karanlık Öz (Yaygın)
- `shadow_crystal` - Gölge Kristali (Nadir)
- `curse_dust` - Lanet Tozu (Nadir)
- `void_fragment` - Boşluk Parçası (Çok nadir)
- `abyss_core` - Uçurum Özü (Efsanevi) *%2 şans*

#### Elemental Forge (Elementel Ocak)
**Kaynaklar:**
- `fire_essence` - Ateş Özü (Yaygın)
- `ice_crystal` - Buz Kristali (Yaygın)
- `lightning_core` - Yıldırım Çekirdeği (Nadir)
- `storm_shard` - Fırtına Kırıntısı (Çok nadir)
- `primordial_flame` - İlkel Alev (Efsanevi) *%2 şans*

#### Time Well (Zaman Kuyusu)
**Kaynaklar:**
- `time_crystal` - Zaman Kristali (Nadir)
- `aging_dust` - Yaşlanma Tozu (Yaygın)
- `eternity_essence` - Sonsuzluk Özü (Çok nadir)
- `temporal_shard` - Zamansal Kırıntı (Çok nadir)
- `infinity_stone` - Sonsuzluk Taşı (Efsanevi) *%1 şans*

---

## 2️⃣ CRAFTİNG TARİFLERİ (SIMYA EKRANI)

### ⚔️ Kategori A: SİLAHLAR

#### A1: COMMON Silahlar (Sev 1-5)

**Basit Kılıç** `weapon_sword_basic`
- Malzemeler:
  - iron_ore x10
  - oak_wood x5 (sap için)
  - leather x2 (tutacak için)
- Süre: 30 dakika
- Üretim Yeri: Demirci (Crafting)
- Statlar: +15 Attack

**Basit Mızrak** `weapon_spear_basic`
- Malzemeler:
  - iron_ore x8
  - pine_wood x10
  - leather x1
- Süre: 25 dakika
- Statlar: +12 Attack, +5 Defense

**Basit Yay** `weapon_bow_basic`
- Malzemeler:
  - oak_wood x15
  - cotton x5 (ip için)
  - bone x3
- Süre: 35 dakika
- Statlar: +18 Attack

**Basit Balta** `weapon_axe_basic`
- Malzemeler:
  - iron_ore x12
  - oak_wood x8
  - granite x3
- Süre: 30 dakika
- Statlar: +20 Attack, -5 Defense

**Basit Hançer** `weapon_dagger_basic`
- Malzemeler:
  - iron_ore x5
  - leather x3
  - bone x2
- Süre: 20 dakika
- Statlar: +10 Attack, +10 Power

---

#### A2: UNCOMMON Silahlar (Sev 6-10)

**Çelik Kılıç** `weapon_sword_steel`
- Malzemeler:
  - iron_ore x20
  - copper_ore x10
  - leather x5
  - crystal_shard x2
- Süre: 1 saat
- Statlar: +30 Attack, +5 Power

**Ejderha Mızrağı** `weapon_spear_dragon`
- Malzemeler:
  - iron_ore x15
  - dragon_root x5
  - elder_wood x10
  - monster_hide x3
- Süre: 1.5 saat
- Statlar: +40 Attack, +15 Defense, +10 Power

**Büyülü Asa** `weapon_staff_magic`
- Malzemeler:
  - elder_wood x20
  - magic_crystal x10
  - mana_crystal x5
  - rare_flower x3
- Süre: 2 saat
- Statlar: +10 Attack, +50 Power, +20 Health

---

#### A3: RARE+ Silahlar (Sev 11+)

**Mithril Kılıç** `weapon_sword_mithril`
- Malzemeler:
  - mithril_ore x15
  - silver_ore x20
  - moonstone x5
  - dragon_scale x3
  - ancient_rune x1
- Süre: 3 saat
- Statlar: +80 Attack, +30 Power, +50 Health

**İlahi Balta** `weapon_axe_divine`
- Malzemeler:
  - mithril_ore x20
  - holy_water x30
  - divine_tear x5
  - obsidian x10
  - blessed_essence x8
- Süre: 4 saat
- Statlar: +120 Attack, +40 Defense, +60 Power

---

### 🛡️ Kategori B: ZIRHLAR

#### B1: COMMON Zırhlar

**Deri Zırh (Body)** `armor_leather_chest`
- Malzemeler:
  - leather x20
  - cotton x10
  - bone x5
- Süre: 40 dakika
- Statlar: +20 Defense, +10 Health

**Zincir Zırh (Body)** `armor_chain_chest`
- Malzemeler:
  - iron_ore x25
  - leather x10
  - cotton x5
- Süre: 1 saat
- Statlar: +35 Defense, +15 Health

---

#### B2: UNCOMMON Zırhlar

**Çelik Plaka Zırh** `armor_plate_steel`
- Malzemeler:
  - iron_ore x40
  - copper_ore x20
  - leather x15
  - crystal_shard x5
- Süre: 1.5 saat
- Statlar: +60 Defense, +30 Health, +10 Power

**Büyülü Kaftan** `armor_cloth_magical`
- Malzemeler:
  - cotton x30
  - magical_grain x10
  - mana_crystal x8
  - rare_flower x5
- Süre: 2 saat
- Statlar: +25 Defense, +80 Power, +40 Health

---

### 🧪 Kategori C: İKSİRLER & POTIONLAR

#### C1: Enerji İksirleri

**Basit Enerji İksiri** `potion_energy_small`
- Malzemeler:
  - healing_herb x5
  - honey x3
  - holy_water x2
- Süre: 15 dakika
- Effect: +50 Energy, +5 Tolerance

**Güçlü Enerji İksiri** `potion_energy_large`
- Malzemeler:
  - healing_herb x15
  - royal_jelly x5
  - mana_crystal x3
  - rare_flower x2
- Süre: 30 dakika
- Effect: +150 Energy, +15 Tolerance, Overdose Risk: 10%

**Usta Enerji İksiri** `potion_energy_master`
- Malzemeler:
  - phoenix_petal x3
  - celestial_honey x5
  - mana_crystal x10
  - divine_tear x2
  - immortality_shroom x1
- Süre: 1 saat
- Effect: +300 Energy, +25 Tolerance, Overdose Risk: 20%

---

#### C2: İyileştirme İksirleri

**Basit Can İksiri** `potion_health_small`
- Malzemeler:
  - healing_mushroom x10
  - honey x5
  - wheat x8
- Süre: 20 dakika
- Effect: +100 Health

**Büyük Can İksiri** `potion_health_large`
- Malzemeler:
  - healing_mushroom x20
  - royal_jelly x8
  - golden_wheat x5
  - holy_water x10
- Süre: 45 dakika
- Effect: +500 Health

---

#### C3: Buff İksirleri

**Güç İksiri** `potion_buff_power`
- Malzemeler:
  - dragon_root x5
  - fire_essence x10
  - lightning_core x3
  - poison_herb x8
- Süre: 40 dakika
- Effect: +50% Power (30 dakika)

**Zırh İksiri** `potion_buff_defense`
- Malzemeler:
  - granite x15
  - obsidian x5
  - honey x10
  - bone x20
- Süre: 40 dakika
- Effect: +50% Defense (30 dakika)

---

#### C4: Antidote

**Arınma İksiri** `potion_antidote`
- Malzemeler:
  - purification_water x10
  - healing_herb x15
  - blessed_essence x5
  - phoenix_petal x2
- Süre: 1 saat
- Effect: -50 Tolerance, %100 Success Rate

---

### 📜 Kategori D: RÜNLER

#### D1: Basit Rünler

**Saldırı Rünü I** `rune_attack_1`
- Malzemeler:
  - raw_rune x5
  - energy_shard x3
  - fire_essence x5
- Süre: 30 dakika
- Effect: +10% Enhancement Success (Attack items only)

**Savunma Rünü I** `rune_defense_1`
- Malzemeler:
  - raw_rune x5
  - energy_shard x3
  - granite x10
- Süre: 30 dakika
- Effect: +10% Enhancement Success (Defense items only)

---

#### D2: Gelişmiş Rünler

**Kadim Güç Rünü** `rune_power_ancient`
- Malzemeler:
  - ancient_rune x3
  - magic_crystal x15
  - power_rune x5
  - primordial_flame x2
- Süre: 2 saat
- Effect: +25% Enhancement Success, -10% Destruction Risk

---

### 📋 Kategori E: SCROLLLAR

**Geliştirme Parşömeni +1** `scroll_enhance_1`
- Malzemeler:
  - cotton x20
  - ink (from vegetables) x10
  - magic_crystal x5
- Süre: 30 dakika
- Effect: +1 Enhancement Level (100% success for +0→+1)

**Geliştirme Parşömeni +5** `scroll_enhance_5`
- Malzemeler:
  - cotton x50
  - magic_crystal x20
  - mana_crystal x10
  - blessed_essence x5
- Süre: 1.5 saat
- Effect: +1 Enhancement Level (Guaranteed +4→+5)

---

### 💎 Kategori F: AKSESUARLAR

**Güç Yüzüğü** `accessory_ring_power`
- Malzemeler:
  - gold_ore x10
  - magic_crystal x5
  - fire_essence x8
- Süre: 1 saat
- Statlar: +30 Power

**Ejderha Kolyesi** `accessory_necklace_dragon`
- Malzemeler:
  - dragon_scale x5
  - gold_ore x15
  - moonstone x3
  - dragon_root x10
- Süre: 2 saat
- Statlar: +50 Attack, +50 Defense, +100 Power

---

## 3️⃣ ÜRETİM ZİNCİRLERİ

### Temel → İleri Craft Örnekleri

#### Zincir 1: Basit Kılıç → Mithril Kılıç
```
1. Mining → iron_ore, mithril_ore
2. Lumber Mill → oak_wood, elder_wood
3. Ranch → leather, monster_hide, dragon_scale
4. Quarry → moonstone
5. Rune Mine → ancient_rune

Crafting:
- Basit Kılıç (Seviye 1)
- Çelik Kılıç (Seviye 6) 
- Mithril Kılıç (Seviye 11)
```

#### Zincir 2: Enerji İksiri Progression
```
1. Herb Garden → healing_herb, phoenix_petal
2. Apiary → honey, royal_jelly, celestial_honey
3. Holy Spring → holy_water, mana_crystal, divine_tear
4. Mushroom Farm → immortality_shroom

Crafting:
- Basit Enerji İksiri (Seviye 1)
- Güçlü Enerji İksiri (Seviye 8)
- Usta Enerji İksiri (Seviye 15)
```

---

## 4️⃣ UYGULAMA PLANI

### Adım 1: Database Migration
- Tüm yeni kaynak item'larını `items` tablosuna ekle (75+ yeni item)
- Crafting tariflerini `facility_recipes` veya yeni `crafting_recipes` tablosuna ekle

### Adım 2: CraftingScreen UI
- Kategori sekmele ri: Silahlar, Zırhlar, İksirler, Rünler, Scrolllar, Aksesuarlar
- Malzeme önizleme (sahip olduğu/gereken karşılaştırma)
- Seviye gereksinimleri kontrolü
- Başarı oranı göstergesi

### Adım 3: Production System
- Recipe validation (malzeme kontrolü)
- Crafting queue (birden fazla item sırada)
- Success/Fail mekaniği
- XP kazanımı

---

## 5️⃣ BALANCE NOTLARI

### Üretim Süreleri
- Common: 15-40 dakika
- Uncommon: 1-2 saat
- Rare: 2-4 saat
- Epic: 4-8 saat
- Legendary: 8-16 saat
- Mythic: 24+ saat

### Kaynak Drop Oranları
- Common resources: %100
- Uncommon resources: %10-20
- Rare resources: %5-10
- Very Rare: %2-5
- Legendary: %1-2

### Ekonomi
- Tesisler idle çalışır (saatte X kaynak)
- Crafting manuel başlatılır
- Market'te hem kaynaklar hem de finished items satılabilir

---

**ÖNEMLİ:** Bu blueprint'i onayladıktan sonra:
1. Database migration SQL'leri oluşturacağım
2. CraftingScreen UI'ı güncelleyeceğim
3. Crafting manager'ı yazacağım


---

## 6️⃣ TESİS SEVİYESİNE GÖRE DÜŞME ORANLARI (1-20)

Aşağıdaki tablo, tesis seviyesi arttıkça eşya nadirliklerinin düşme şanslarının (yüzdesel) nasıl değiştiğini gösterir.

| Seviye | Common (Yaygın) | Uncommon (Az) | Rare (Nadir) | Epic (Destansı) | Legendary (Efsane) |
| :---: | :---: | :---: | :---: | :---: | :---: |
| **1** | %70.00 | %20.00 | %8.00 | %1.50 | %0.50 |
| **2** | %68.16 | %20.91 | %8.56 | %1.75 | %0.63 |
| **3** | %66.38 | %21.80 | %9.10 | %1.99 | %0.76 |
| **4** | %64.67 | %22.62 | %9.60 | %2.22 | %0.88 |
| **5** | %63.06 | %23.42 | %10.09 | %2.43 | %0.99 |
| **6** | %61.46 | %24.16 | %10.53 | %2.63 | %1.10 |
| **7** | %59.95 | %24.87 | %10.96 | %2.83 | %1.20 |
| **8** | %58.55 | %25.56 | %11.38 | %3.01 | %1.30 |
| **9** | %57.26 | %26.22 | %11.78 | %3.19 | %1.39 |
| **10** | **%56.11** | **%26.85** | **%12.18** | **%3.37** | **%1.48** |
| **11** | %54.91 | %27.45 | %12.55 | %3.53 | %1.57 |
| **12** | %53.76 | %28.03 | %12.90 | %3.69 | %1.65 |
| **13** | %52.67 | %28.59 | %13.24 | %3.84 | %1.73 |
| **14** | %51.62 | %29.13 | %13.57 | %3.98 | %1.81 |
| **15** | %50.61 | %29.65 | %13.88 | %4.12 | %1.88 |
| **16** | %49.65 | %30.14 | %14.18 | %4.26 | %1.95 |
| **17** | %48.72 | %30.61 | %14.48 | %4.38 | %2.02 |
| **18** | %47.81 | %31.06 | %14.75 | %4.51 | %2.08 |
| **19** | %46.90 | %31.47 | %15.01 | %4.62 | %2.14 |
| **20** | **%45.98** | **%31.86** | **%15.24** | **%4.73** | **%2.20** |

*Not: Seviye arttıkça "Common" (değersiz) eşya şansı azalırken, diğer tüm kategorilerin şansı artar.*
