# 15 TESİS SISTEMI - MEVCUT KODLA DETAYLI ENTEGRASYON ANALİZİ

## ⚠️ KRİTİK BULGU
Mevcut oyundaki 3 ana sistem var:
1. **BlacksmithScreen.gd** - Silah/Zırh +0→+10 yükseltme (Upgrade Scrolls ile)
2. **AnvilScreen.gd** - Rune ekleyerek geliştirme
3. **CraftingScreen.gd** - Tarif üretimi (Alchemy, Blacksmith, Woodwork, Leatherwork)

**YANLIŞ ANLAŞ**: Ben gerekli hammaddeleri belirtmemiştim. Tarifler **NEREDE** üretilecek, hangi tesis **NEDEN** gerekli vs.

---

## 📊 MEVCUT ITEM VE TARIFLER

### ItemDatabase.gd'de Var Olanlar

**Malzemeleri (Materials):**
- `material_iron_ore` → production_building_type: "mine" (production_rate: 10/saat)
- `material_wood` → production_building_type: "sawmill" (production_rate: 15/saat)
- (Deri, Kristal, Ot vs eklenebilir)

**Tarifler (Recipes):**
- `recipe_sword_basic` 
  - Gerekli: material_iron_ore (3), material_wood (1)
  - Üretim binası: "blacksmith"
  - Üretim süresi: 300 saniye (5 dakika)
  - Sonuç: weapon_sword_basic

**Yükseltme Kaynakları:**
- `scroll_upgrade_low` - Common/Uncommon için
- `scroll_upgrade_middle` - Rare/Epic için
- `scroll_upgrade_high` - Legendary için

**Runeler (Runes):**
- `rune_attack_minor` → rune_success_bonus: 5%, rune_destruction_reduction: 2%
- Diğer rune tipleri eklenebilir

---

## 🏗️ 15 TESIS SISTEMI NASIL UYUMLU OLMALI

### KATEGORİ 1: RAW MATERIALS (4 Tesis)
Bunlar **SADECE** hammadde üretir. Hiç tarif gerektirmez.

#### 1️⃣ MADEN OCAĞI (Mine)
```
Production Building Type: "mine"
Üretir:
  • Demir Cevheri (iron_ore) - 8-12/saat (seviye 1-10)
  • Altın Cevheri (gold_ore) - 4-8/saat (seviye 5+)
  • Gümüş Cevheri (silver_ore) - 6-10/saat (seviye 3+)
  • Kristal (crystal) - 2-4/saat (seviye 7+)
  • Elmas (diamond) - 0.5-1/saat (seviye 10+)
```

**RARITY SİSTEMİ:** ItemDatabase'e ekle
```gdscript
"material_iron_ore": {
    "rarity_outcomes": {
        "COMMON": 70,      # 70% şansı
        "UNCOMMON": 20,    # 20% şansı
        "RARE": 8,         # 8% şansı
        "EPIC": 1.5,       # 1.5% şansı
        "LEGENDARY": 0.5   # 0.5% şansı
    }
}
```

#### 2️⃣ ORMAN (Sawmill)
```
Production Building Type: "sawmill"
Üretir:
  • Kereste (wood) - 12-16/saat
  • Sert Kereste (hardwood) - 6-10/saat (seviye 4+)
  • Bambu (bamboo) - 8-12/saat (seviye 3+)
```

#### 3️⃣ HAYVANCILK ÇIFTLK (Farm)
```
Production Building Type: "farm"
Üretir:
  • Deri (leather) - 8-12/saat
  • Kaliteli Deri (quality_leather) - 4-8/saat (seviye 5+)
  • Yün (wool) - 10-15/saat (seviye 2+)
```

#### 4️⃣ ÖT BAĞ (Herb Garden)
```
Production Building Type: "herb_garden"
Üretir:
  • Tıbbi Ot (herb) - 10-15/saat
  • Nadir Ot (rare_herb) - 4-8/saat (seviye 5+)
  • Ejderhain Kanı (dragon_blood) - 0.5-1/saat (seviye 10+)
```

---

### KATEGORİ 2: CRAFTED ITEMS (6 Tesis)
Bunlar **TARIFLER KULLANIR**, ham malzeme işler → bitmiş ürün yapar.

#### 5️⃣ DEMİRCİ (Blacksmith)
```
Tesis Tipi: "blacksmith"
Tarifler ItemDatabase'de:
  • recipe_iron_sword - requires: iron_ore (3), wood (1), time: 5min
    → weapon_iron_sword (COMMON-RARE rarity)
  • recipe_steel_sword - requires: iron_ore (5), crystal (1), time: 15min
    → weapon_steel_sword (RARE-EPIC rarity)
  • recipe_legendary_sword - requires: iron_ore (10), diamond (2), gold_ore (3), time: 60min
    → weapon_legendary_sword (LEGENDARY-MYTHIC rarity)

Seviye Bonus: Her seviye +10% hız
```

#### 6️⃣ ZİRH USTASI (Armorer)
```
Tesis Tipi: "armorer"
Tarifler:
  • recipe_leather_armor - requires: leather (5), wood (2), time: 10min
    → armor_leather (COMMON-RARE)
  • recipe_chain_armor - requires: iron_ore (8), leather (3), time: 20min
    → armor_chain (RARE-EPIC)
  • recipe_plate_armor - requires: iron_ore (15), crystal (2), time: 30min
    → armor_plate (EPIC-LEGENDARY)
```

#### 7️⃣ ALKİMY LİAB (Alchemy Lab)
```
Tesis Tipi: "alchemy_lab"
Tarifler:
  • recipe_health_potion - requires: herb (2), wood (1), time: 2min
    → potion_health (COMMON-UNCOMMON) [stackable 50]
  • recipe_mana_potion - requires: herb (3), crystal (1), time: 5min
    → potion_mana (UNCOMMON-RARE)
  • recipe_invisibility_potion - requires: rare_herb (5), diamond (1), time: 20min
    → potion_invisibility (RARE-EPIC) [special effect]
  • recipe_stamina_potion - requires: herb (4), dragon_blood (1), time: 15min
    → potion_stamina (EPIC-LEGENDARY)
```

#### 8️⃣ RÜNCÜ (Runesmith)
```
Tesis Tipi: "runesmith"
Tarifler:
  • recipe_rune_attack - requires: crystal (3), gold_ore (2), time: 10min
    → rune_attack_minor (UNCOMMON)
  • recipe_rune_defense - requires: crystal (5), silver_ore (3), time: 15min
    → rune_defense_minor (UNCOMMON)
  • recipe_rune_advanced - requires: crystal (10), diamond (2), rare_herb (5), time: 30min
    → rune_attack_major (RARE)
  • recipe_rune_legendary - requires: crystal (20), diamond (5), dragon_blood (2), time: 60min
    → rune_legendary (LEGENDARY-MYTHIC)

Rune Bonus: İçerik olarak enhancement başarı şansı arttırır
  - minor: +5% success
  - major: +10% success
  - legendary: +15% success + reduction_bonus +5%
```

#### 9️⃣ KÜTÜPHANE (Scroll Library)
```
Tesis Tipi: "scroll_library"
Tarifler:
  • recipe_scroll_low - requires: herb (5), wood (3), crystal (1), time: 5min
    → scroll_upgrade_low (UNCOMMON) [stackable 50]
  • recipe_scroll_middle - requires: herb (10), crystal (3), gold_ore (2), time: 10min
    → scroll_upgrade_middle (RARE) [stackable 50]
  • recipe_scroll_high - requires: rare_herb (5), crystal (5), diamond (2), time: 20min
    → scroll_upgrade_high (EPIC) [stackable 30]

Bu scrolllar BlacksmithScreen'de kullanılır!
```

#### 🔟 GEMCİ (Gem Cutter)
```
Tesis Tipi: "gem_cutter"
Tarifler:
  • recipe_ruby - requires: crystal (3), dragon_blood (1), time: 10min
    → gem_ruby (RARE)
  • recipe_sapphire - requires: crystal (5), rare_herb (2), time: 15min
    → gem_sapphire (EPIC)
  • recipe_emerald - requires: crystal (8), gold_ore (3), diamond (1), time: 20min
    → gem_emerald (LEGENDARY)

Gem'ler:
  - Accessories'e takılır (EquipSlot.ACCESSORY)
  - Bonus verir (Attack +10, Defense +15, vs.)
  - Cosmetic/enhancement value
```

---

### KATEGORİ 3: ADVANCED PRODUCTION (3 Tesis)
Bunlar **ZATEN ÜRETİLMİŞ ÜRÜNLERI** işler.

#### 1️⃣1️⃣ DESTEK USTASI (Enhancement Master)
```
Tesis Tipi: "enhancement_master"
ÖZEL: Direkt enhancement yapa olmaz mı? 
İLERİ ARAŞTIRMA: Şimdilik tarif:

  • recipe_enhancement_scroll - requires: scroll_upgrade_low (3), rare_herb (2), time: 10min
    → enhanced_scroll_v2 (Blue scroll, +10% success ekstra)
  
  • recipe_essence - requires: diamond (5), dragon_blood (3), rare_herb (10), time: 60min
    → essence_pure (LEGENDARY) - enhancement ile bonus vermek için
```

#### 1️⃣2️⃣ KİMYAGER (Master Alchemist)
```
Tesis Tipi: "master_alchemist"
Sadece EN YÜKSEK LEVEL POTİYONLAR:

  • recipe_ultimate_potion - requires: potion_health (3), potion_mana (3), potion_stamina (2), rare_herb (10), dragon_blood (2), time: 60min
    → potion_ultimate (MYTHIC) [full heal + all buffs]
  
  • recipe_enchanted_draught - requires: rare_herb (15), crystal (10), diamond (3), potion_invisibility (5), time: 90min
    → potion_enchanted (MYTHIC) - special quest item
```

#### 1️⃣3️⃣ UZMAN ZIRH USTASI (Master Armorer) 
```
Tesis Tipi: "master_armorer"
Yalnızca LEGENDARY ekipman tarafından tarifler:

  • recipe_mythic_plate - requires: armor_plate (1) [EPIC+], gold_ore (20), diamond (10), crystal (15), time: 120min
    → armor_mythic_plate (MYTHIC) - +30 Defense, special glow
  
  • recipe_divine_armor - requires: armor_plate (2), essence_pure (3), dragon_blood (5), gold_ore (30), time: 180min
    → armor_divine (MYTHIC) - +40 Defense, special effect
```

---

### KATEGORİ 4: HUB TESİSLERİ (2 Tesis)
Bunlar **STASH** gibi çalışır - üretim yapmaz, depo/exchange yapar.

#### 1️⃣4️⃣ DEPO (Warehouse)
```
Tesis Tipi: "warehouse"
Fonksiyon: Malzeme depolamak, organize etmek
NOT: CraftingScreen'de materyaller gerekli - buradan referans alır
  - Level ↑ = Storage capacity ↑
  - Level 1: 500 item
  - Level 10: 5000 item

Tarife gerek YOK - management building
```

#### 1️⃣5️⃣ PAZAR (Market Hub)
```
Tesis Tipi: "market_hub"
Fonksiyon: NPC tarafından buy/sell, player trading
  - Level ↑ = Better prices, more NPCs
  - Tarife gerek YOK - hub building
  
Entegrasyon: CraftingScreen'den üretilen ürünler buraya gider
```

---

## 🎯 RARITY DAĞILIMI - ÜRRETIM SİSTEMİ

**Burada devrim yapmalıyız.** Mevcut sistem:
```gdscript
// BlacksmithScreen.gd satır 269-320
var result = await mgr.enhance_item(current_input_item, current_scroll)
if result.success: { /* başarılı */ }
else: { /* başarısız */ }
```

**Yeni sistem (Facility Production):**
```gdscript
// FacilityDetailScreen.gd veya CraftingScreen.gd

func start_production(recipe_id: String, facility_level: int, suspicion_level: int) -> Dictionary:
    var result = {}
    
    # 1. Rarity belirle
    var rarity = _determine_rarity_outcome(recipe_id, facility_level, suspicion_level)
    
    # 2. Üreteceği itemin rarity versiyonunu bul
    var crafted_item = get_recipe_result(recipe_id, rarity)
    
    # 3. Queue'ye ekle
    queue_item(crafted_item, recipe_id, facility_level)
    
    return {"success": true, "rarity": rarity, "item": crafted_item}

func _determine_rarity_outcome(recipe_id: String, facility_level: int, suspicion: int) -> String:
    var roll = randf() * 100.0
    
    # Facility level bonus
    var facility_bonus = facility_level * 1.0  # +1% per level
    
    # Suspicion penalty
    var suspicion_penalty = suspicion * 0.5  # -0.5% per suspicion
    
    # Base probabilities
    if roll < (70 + facility_bonus - suspicion_penalty):
        return "COMMON"
    elif roll < (90 + facility_bonus - suspicion_penalty):
        return "UNCOMMON"
    elif roll < (98 + facility_bonus - suspicion_penalty):
        return "RARE"
    elif roll < (99.5 + facility_bonus - suspicion_penalty):
        return "EPIC"
    elif roll < (99.95 + facility_bonus - suspicion_penalty):
        return "LEGENDARY"
    else:
        return "MYTHIC"
```

**ÖRNEK SENARYO:**

🛠️ **Blacksmith Ekranından:**
1. Demir Kılıç tarifi seç (recipe_iron_sword)
2. Gerekli: iron_ore (3), wood (1)
3. "Başla" butonu
4. **Backend → Database:**
   ```sql
   INSERT INTO facility_queue (facility_id, recipe_id, quantity, started_at, rarity_outcome)
   VALUES (1, 'recipe_iron_sword', 1, NOW(), 'UNCOMMON');  ← Rarity random!
   ```
5. **5 dakika sonra:**
   ```sql
   INSERT INTO inventory (player_id, item_id, enhancement_level, rarity)
   VALUES (123, 'weapon_iron_sword', 0, 'UNCOMMON');  ← Başarıyla eklendi
   ```

---

## 🔗 ENTEGRASYON NOKTALARI

### 1️⃣ BlacksmithScreen + Scrolls
```gdscript
// BlacksmithScreen.gd satır 213-214
var current_scroll: ItemData = null
```

**Scroll nereden gelir?**
→ **Scroll Library tesisindan** (`recipe_scroll_low`, `recipe_scroll_middle`, `recipe_scroll_high`)
→ CraftingScreen'de üretilir
→ Inventory'de depolanır
→ BlacksmithScreen'de item upgrade etmek için kullanılır

### 2️⃣ AnvilScreen + Runes
```gdscript
// AnvilScreen.gd satır 19
var selected_runes: Array[Dictionary] = [{}, {}, {}]
```

**Rune nereden gelir?**
→ **Runesmith tesisindan** (`recipe_rune_attack`, `recipe_rune_defense`, vb.)
→ CraftingScreen'de üretilir
→ AnvilScreen'de equipment upgrade'de kullanılır

### 3️⃣ CraftingScreen + Facilities
```gdscript
// CraftingScreen.gd satır 31-34
alchemy_button.pressed.connect(func(): _change_category("alchemy"))
blacksmith_button.pressed.connect(func(): _change_category("blacksmith"))
woodwork_button.pressed.connect(func(): _change_category("woodwork"))
leatherwork_button.pressed.connect(func(): _change_category("leatherwork"))
```

**Tarif seçince:**
1. `/v1/crafting/recipes?category=alchemy` çağrı yapılır
2. Backend hangi facility tipinin recipes'ini döner
3. Tarife basınca `/v1/crafting/start` → facility production queue'ye gider
4. Timeline'da queue gösterilir

### 4️⃣ Facility Production Queue
```gdscript
// ProductionManager.gd satır 81
var production_queue: Array = []
```

**Queue nasıl güncellenir?**
```
Bunu DEĞİŞTİRMELİYİZ - mevcut sadece 5 building'e bakar
```

Yeni sistem:
```gdscript
var facility_queue: Array = []  // Her facility kendi queue'su
// facility_queue[facility_id].push_back({
//     recipe_id: "recipe_iron_sword",
//     started_at: timestamp,
//     duration: 300,
//     rarity_outcome: "UNCOMMON",
//     completed: false
// })
```

---

## 📋 DATABASE SCHEMA (Backend entegrasyonu)

```sql
-- Facilities tablosu
CREATE TABLE facilities (
  id BIGSERIAL PRIMARY KEY,
  player_id UUID REFERENCES auth.users(id),
  facility_type VARCHAR(50),  -- "mine", "blacksmith", "alchemy_lab", etc.
  level INT DEFAULT 1,
  suspicion_level INT DEFAULT 0,
  offline_production_cap INT DEFAULT 500,  -- hour, level * 50
  workers INT DEFAULT 0,  -- level * 2
  is_locked BOOLEAN DEFAULT true,
  unlock_cost INT,
  upgrade_cost INT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Facility Queue (Production)
CREATE TABLE facility_queue (
  id BIGSERIAL PRIMARY KEY,
  facility_id BIGINT REFERENCES facilities(id),
  recipe_id VARCHAR(100),
  quantity INT DEFAULT 1,
  started_at TIMESTAMP DEFAULT NOW(),
  duration_seconds INT,
  rarity_outcome VARCHAR(20),  -- COMMON, UNCOMMON, RARE, EPIC, LEGENDARY, MYTHIC
  completed_at TIMESTAMP,
  collected BOOLEAN DEFAULT false
);

-- Crafted Items Log
CREATE TABLE crafted_items_log (
  id BIGSERIAL PRIMARY KEY,
  player_id UUID REFERENCES auth.users(id),
  item_id VARCHAR(100),
  quantity INT,
  rarity VARCHAR(20),
  facility_id BIGINT REFERENCES facilities(id),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Prison Records
CREATE TABLE prison_records (
  id BIGSERIAL PRIMARY KEY,
  player_id UUID REFERENCES auth.users(id),
  facility_id BIGINT REFERENCES facilities(id),
  reason VARCHAR(200),  -- "High suspicion", "Failed production", etc.
  sentence_hours INT,
  admitted_at TIMESTAMP DEFAULT NOW(),
  released_at TIMESTAMP
);
```

---

## 🚨 ÖNEMLİ: DOSYA DEĞŞTIRILECEKLERI

### A. Core Managers
- [ ] `core/managers/FacilityManager.gd` - GENIŞLET (sadece 40 satır)
- [ ] `core/managers/ProductionManager.gd` - REFACTOR (5 building'den 15'e)

### B. ItemDatabase
- [ ] `core/data/ItemDatabase.gd` - EKLE:
  - [ ] 12 yeni material item
  - [ ] 30+ yeni recipe item
  - [ ] 8 yeni rune type
  - [ ] 5 yeni gem type

### C. UI Screens
- [ ] `scenes/ui/screens/BlacksmithScreen.gd` - Scroll desteği (VAR ✅)
- [ ] `scenes/ui/screens/AnvilScreen.gd` - Rune desteği (VAR ✅)
- [ ] `scenes/ui/screens/CraftingScreen.gd` - Category'ler (VAR ✅, ama sadece 4 type)
- [ ] `scenes/ui/screens/FacilitiesScreen.gd` - 15 facility hub (40 satırlık! 🚨)
- [ ] `scenes/ui/screens/FacilityDetailScreen.gd` - Queue management (VAR ✅)

### D. Backend (Supabase)
- [ ] 5 yeni table'dan SQL migration
- [ ] 15 yeni RPC function
- [ ] Row-level security policies

---

## 🎮 GAMEPLAY LOOP

```
1. PASSIV GELİR:
   Oyuncu Blacksmith tesisin level 3'üne yükseltir
   ↓
   CraftingScreen'de "Demir Kılıç" tarifi seçer
   ↓
   5 dakika sonra UNCOMMON Demir Kılıç (random rarity)
   ↓
   Onu BlacksmithScreen'de +2'ye yükseltir (Scroll + Rune gerekli)
   ↓
   Başarı! → Equipment'e takıyor

2. RİSK LOOP:
   Suspicion level yükseldikçe:
   - Rarity daha LOW çıkma olasılığı artar
   - Harvesting fail olabilir
   - Hapishaneye düşebilir
   
3. META:
   En yüksek rarity → En güçlü item
   En güçlü item → Quest/Dungeon başarısı ↑ → Loot ↑
```

---

## ✅ SONUÇ: NASIL BAŞLAMALI

1. **ItemDatabase.gd'yi genişlet**: Tüm 15 tesisin material/recipe tanımlarını ekle
2. **FacilityManager.gd'yi refactor et**: 15 facility type'ı support et
3. **CraftingScreen'i fix et**: Categories ekle, facility entegrasyonu yap
4. **Database migration**: Facility production queue table'ını oluştur
5. **Prison integration**: MiningScreen → Suspicion tracking → Prison admission

Hazır mısın?
