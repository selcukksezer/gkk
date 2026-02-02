# 15 TESİS SISTEMI - IMPLEMENTATION GUIDE

## ✅ TAMAMLANAN ADIMLAR

### 1. Database Migration (database/migrations/015_facilities_system.sql)
- ✅ 6 ana tablo oluşturuldu
- ✅ RLS policies eklendia
- ✅ 7 PL/pgSQL function yazıldı
- ✅ İnitial recipes data eklenid

### 2. ItemDatabase.gd Genişletildi (+50 item)
- ✅ Material (8 yeni): gold_ore, crystal, diamond, hardwood, bamboo, leather, quality_leather, wool, rare_herb, dragon_blood
- ✅ Crafted Weapons (3): iron_sword, steel_sword, legendary_sword
- ✅ Crafted Armor (3): leather_armor, chain_mail, plate_armor
- ✅ Crafted Potions (3): potion_health, potion_mana, potion_stamina
- ✅ Runes (5): attack_minor, defense_minor, attack_major, defense_major, legendary
- ✅ Gems (3): ruby, sapphire, emerald
- ✅ Scrolls (3): scroll_upgrade_low/middle/high (eski var, high eklenid)

### 3. FacilityManager.gd Refactored
- ✅ FACILITIES_CONFIG eklendia (15 facility definition)
- ✅ Helper fonksiyonlar iyileştirileğia
- ✅ fetch_recipes_for_facility() - yeni recipe sistem
- ✅ unlock_facility() - gold check'i eklendia
- ✅ upgrade_facility() - new, level-based
- ✅ start_production() - recipe validation'la
- ✅ increment_suspicion() - prison check'li
- ✅ bribe_officials() - gem-based
- ✅ _check_prison_admission() - otomatik prison logic

---

## 🚀 SONRAKI ADIMLAR (ÖNERİLEN SIRA)

### ADIM 1: Backend RPC Functions (Supabase Edge Functions)
**Dosya:** `supabase/functions/`
**Tahmini Zaman:** 4-6 saat

Yazılması gereken 10 RPC function:

```sql
-- 1. unlock_facility(p_facility_type VARCHAR)
-- 2. upgrade_facility(p_facility_id BIGINT, p_type VARCHAR)
-- 3. start_facility_production(p_facility_id BIGINT, p_recipe_id VARCHAR, p_quantity INT)
-- 4. collect_facility_production(p_facility_id BIGINT)
-- 5. increment_facility_suspicion(p_facility_id BIGINT, p_amount INT)
-- 6. decrement_facility_suspicion(p_facility_id BIGINT, p_amount INT)
-- 7. bribe_officials(p_facility_id BIGINT, p_gems INT)
-- 8. check_and_admit_to_prison(p_facility_id BIGINT)
-- 9. calculate_offline_production(p_facility_id BIGINT)
-- 10. get_player_facilities(p_player_id UUID)
```

**Sıralı Yazılış Tavsiyesi:**
1. `get_player_facilities()` - Base fetch
2. `unlock_facility()` - Gold check + facility insert
3. `upgrade_facility()` - Level + cost update
4. `start_facility_production()` - Queue insert + rarity determination
5. `collect_facility_production()` - Queue complete + inventory add
6. `increment_facility_suspicion()` - Suspicion update
7. `decrement_facility_suspicion()` - Suspicion decrease
8. `bribe_officials()` - Gem deduct + suspicion decrease
9. `check_and_admit_to_prison()` - Prison admission logic
10. `calculate_offline_production()` - Queue auto-fill for offline

---

### ADIM 2: FacilitiesScreen.gd Iyileştir
**Dosya:** `scenes/ui/screens/FacilitiesScreen.gd`
**Tahmini Zaman:** 3-4 saat

Şu anda sadece 40 satır. Bunu 300+ satıra çıkartmalısın:

```gdscript
# TO-DO:
[ ] 15 facility grid'i göster (4x4, scrollable)
[ ] Her facility card:
    [ ] Icon + Name
    [ ] Level göstergesi
    [ ] Suspicion level bar (kırmızı/sarı/yeşil)
    [ ] "Detaylar" butonu
    [ ] Unlock status
[ ] Bottom sheet: Facility details modal
    [ ] Production queue (real-time timer)
    [ ] Available recipes (level-based)
    [ ] Start production button
    [ ] Suspicion management (bribe button)
    [ ] Upgrade button
```

**Entegrasyon Noktaları:**
```gdscript
# FacilityManager sinyalleri
FacilityManager.facilities_updated.connect(_refresh_grid)
FacilityManager.production_started.connect(_on_production_started)
FacilityManager.production_completed.connect(_on_production_completed)
FacilityManager.suspicion_changed.connect(_on_suspicion_changed)
FacilityManager.sent_to_prison.connect(_on_sent_to_prison)
```

---

### ADIM 3: FacilityDetailScreen.gd Entegre Et
**Dosya:** `scenes/ui/screens/FacilityDetailScreen.gd`
**Tahmini Zaman:** 4-5 saat

Bu file zaten var ve iyi yapılmış. Ama şunu yapmanız lazım:

```gdscript
# TO-DO:
[ ] Production Queue Tab
    [ ] 15 facility tip için generic hale getir
    [ ] Real-time countdown (every 1 second)
    [ ] Rarity outcome göster (COMMON/UNCOMMON/RARE/etc.)
    [ ] Collect button
    [ ] Collection fail handling (high suspicion)
[ ] Recipes Tab
    [ ] fetch_recipes_for_facility() call et
    [ ] Recipe list göster (level-based filter)
    [ ] Material requirements göster
    [ ] Craft time göster
    [ ] "Start Production" button
[ ] Suspicion Tab
    [ ] Current suspicion level
    [ ] Red meter (0-100%)
    [ ] Bribe option (5 gems = -10 suspicion)
    [ ] Prison risk warning (80+% = danger zone)
[ ] Upgrade Tab
    [ ] Current level + next level benefits
    [ ] Upgrade cost (get_upgrade_cost())
    [ ] Workers per level
    [ ] Upgrade button
```

**Key Changes:**
```gdscript
# Recipe terifleri ItemDatabase'den gelecek
var recipe_data = ItemDatabase.get_item(recipe_id)

# Production queue rarity'ye göre render
if queue_item.rarity_outcome == "COMMON":
    icon_modulate = Color.WHITE
elif queue_item.rarity_outcome == "RARE":
    icon_modulate = Color.CYAN
# ... vs
```

---

### ADIM 4: CraftingScreen.gd - Facilities Entegrasyonu
**Dosya:** `scenes/ui/screens/CraftingScreen.gd`
**Tahmini Zaman:** 3-4 saat

Şu anda:
- ✅ 4 kategori var (alchemy, blacksmith, woodwork, leatherwork)
- ❌ Ama bunlar tesisle bağlanmamış
- ❌ Material check'i yok

Yapılması Gereken:

```gdscript
# TO-DO:
[ ] CategoryTab isimleri değiştir:
    "alchemy" → "Alkimya Lab" (facility_type: "alchemy_lab")
    "blacksmith" → "Demirci" (facility_type: "blacksmith")
    "woodwork" → "Zırh Ustası" (facility_type: "armorer")
    "leatherwork" → "Runesmith" (facility_type: "runesmith")
[ ] Tarifler CraftingScreen yüklenince:
    for each category:
        FacilityManager.fetch_recipes_for_facility(facility_type)
        Recipes cachelensin
[ ] Material availability check:
    for each material in recipe:
        var have = InventoryManager.get_item_count(material_id)
        var need = recipe.required_materials[material_id]
        if have < need: DISABLE craft button
[ ] Craft basılırsa:
    FacilityManager.start_production(facility_type, recipe_id, quantity)
```

**Reference Kod Örneği:**
```gdscript
func _load_recipes() -> void:
    if is_loading: return
    is_loading = true
    _clear_recipe_list()
    
    var facility_type = _get_facility_type_for_category(current_category)
    var result = await FacilityManager.fetch_recipes_for_facility(facility_type)
    
    is_loading = false
    
    if result.success:
        recipes = result.data
        _populate_recipe_list()
```

---

### ADIM 5: MiningScreen Integration (Prison Link)
**Dosya:** `scenes/ui/screens/MiningScreen.tscn` (GDScript içinde)
**Tahmini Zaman:** 2-3 saat

MiningScreen şu anda:
- ✅ 5 resource gathering yapıyor
- ❌ Suspicion tracking yok
- ❌ Prison trigger yok
- ❌ Rarity outcomes yok

**Değişiklikler:**

```gdscript
# TO-DO:
[ ] Gather sırasında suspicion artışı
    on_mining_success():
        FacilityManager.increment_suspicion("mine", 3-8)
        # random 3-8 arasında
[ ] High suspicion warning
    if suspicion >= 60:
        show_warning("Yüksek riskli! Yakalama şansı %X")
[ ] Prison admission check
    FacilityManager._check_prison_admission() otomatik çalışır
    Ama MiningScreen'den başlatmalısın
[ ] Rarity outcomes (OPTIONAL - ileri aşama)
    Normal gathering yerine:
    var rarity = determine_rarity(suspicion_level)
    _show_rarity_effect(rarity)
```

---

### ADIM 6: BlacksmithScreen & AnvilScreen Scroll/Rune Support
**Dosya:** `scenes/ui/screens/BlacksmithScreen.gd`, `AnvilScreen.gd`
**Tahmini Zaman:** 2 saat

Şu anda:
- ✅ BlacksmithScreen scrolllar kullanıyor (eski sistem)
- ✅ AnvilScreen rune desteği var (eski sistem)

**Yapılması Gereken:**
```gdscript
# TO-DO:
[ ] BlacksmithScreen'de scroll kaynağı göster
    "Scrolllar Parşömen Kütüphanesi'nden üretilir"
    İçinde facility link
[ ] AnvilScreen'de rune kaynağı göster
    "Runeler Rüncü'nden üretilir"
    İçinde facility link
[ ] Direct farming link?
    "Şimdi Parşömen Kütüphanesi'ne git" button → CraftingScreen
```

---

## 🎯 CRITICAL INTEGRATION POINTS

### ENTEGRASYON 1: Production Queue'ye Items Eklenmesi

```
FacilityDetailScreen.gd (User başlatır)
    ↓
FacilityManager.start_production(facility_type, recipe_id, qty)
    ↓
Backend RPC: start_facility_production()
    ├─ Validate recipe & materials
    ├─ Determine rarity_outcome
    ├─ INSERT into facility_production_queue
    └─ Deduct materials from inventory
    ↓
Frontend: production_started emit
    ↓
FacilityDetailScreen (Queue tab) yenilenir
```

### ENTEGRASYON 2: Production Completion & Collection

```
Backend (timed job or frontend polling):
    IF now() >= estimated_completion_at:
        UPDATE facility_production_queue SET completed_at = NOW()

FacilityDetailScreen.gd (_update_ui every 1 sec):
    IF queue_item.completed_at != NULL AND collected == false:
        Show "Topla" button

User "Topla" basarsa:
    ↓
FacilityManager.collect_production(facility_type)
    ↓
Backend RPC: collect_facility_production()
    ├─ Get completed items from queue
    ├─ INSERT into inventory (with rarity)
    ├─ Mark as collected
    └─ Return { success, items_collected }
    ↓
Frontend: production_collected emit
    ├─ Inventory refresh
    ├─ FacilitiesScreen refresh
    └─ Show success dialog with rarity
```

### ENTEGRASYON 3: Suspicion → Prison

```
Any risky action (high suspicion at harvest):
    FacilityManager.increment_suspicion(facility_type, amount)
    ↓
Backend checks: IF new_suspicion >= 80:
    Call check_and_admit_to_prison()
        ├─ Roll: 50% + suspicion% = imprisonment chance
        ├─ IF imprisoned:
        │   ├─ INSERT into prison_records
        │   ├─ Set State.in_prison = true
        │   ├─ Set release_time = now() + sentence_hours
        │   └─ Return { admitted: true, hours: 2-8 }
        └─ ELSE: return { admitted: false }
    ↓
Frontend: sent_to_prison signal emit
    ├─ PrisonScreen açılır otomatik
    ├─ State.in_prison = true
    └─ Show "X saat hapis cezası!" dialog
```

---

## 📋 DATABASE SCHEMA REVIEW

**Tamamlanan Tables:**

| Tabel | Satır | Amaç |
|-------|-------|------|
| `facilities` | 20+ | Oyuncu tesisleri ve state |
| `facility_recipes` | 20+ | Her tesisin tarifler |
| `facility_production_queue` | 20+ | Üretim kuyruk ve geçmiş |
| `crafted_items_log` | 15+ | Üretilen items log |
| `prison_records` | 15+ | Hapishane kayıtları |
| `facility_workers` | 10+ | Çalışan yönetimi (future) |

**Views:**

| View | Amaç |
|------|------|
| `active_production_queue` | Aktif işleri sorgulamak |
| `ready_to_collect` | Toplanacak işleri bulma |
| `player_suspicion_levels` | Oyuncu total suspicion |
| `player_prison_status` | Oyuncu prison status |

**Functions (PL/pgSQL):**

| Fonksiyon | Parametre | Return |
|-----------|-----------|--------|
| `calculate_offline_production()` | facility_id | INT |
| `determine_rarity_outcome()` | level, suspicion, dist | VARCHAR |
| `increment_facility_suspicion()` | facility_id, amount | INT |
| `decrement_facility_suspicion()` | facility_id, amount | INT |
| `calculate_upgrade_cost()` | facility_id | INT |

---

## 🔗 DOSYA LOCATIONS

**Yazılan/Değiştirilen Dosyalar:**

```
✅ database/migrations/015_facilities_system.sql     (NEW - 500+ satır)
✅ core/data/ItemDatabase.gd                         (MODIFIED - +50 item)
✅ core/managers/FacilityManager.gd                  (REFACTORED - 200+ satır)
⏳ supabase/functions/facilities/*                   (TODO - Backend RPCs)
⏳ scenes/ui/screens/FacilitiesScreen.gd             (TODO - Hub UI)
⏳ scenes/ui/screens/FacilityDetailScreen.gd         (TODO - Detail UI)
⏳ scenes/ui/screens/CraftingScreen.gd               (TODO - Recipes entegration)
⏳ scenes/ui/screens/MiningScreen.tscn               (TODO - Suspicion/Prison)
```

---

## 📊 IMPLEMENTATION TIMELINE

**Total Tahmini Zaman: 20-25 saat**

| Adım | Tahmini | Status |
|------|---------|--------|
| Database + RPC Functions | 6-8 saat | ⏳ Sırada |
| FacilitiesScreen UI | 4-5 saat | ⏳ Sonra |
| FacilityDetailScreen Integration | 5-6 saat | ⏳ Sonra |
| CraftingScreen Facilities Link | 3-4 saat | ⏳ Sonra |
| MiningScreen Suspicion/Prison | 2-3 saat | ⏳ Sonra |
| BlacksmithScreen & AnvilScreen Links | 1-2 saat | ⏳ Sonra |
| Testing & Bug Fixes | 2-3 saat | ⏳ Sonra |

---

## ✨ FEATURES COMPLETED

### Yeni Sistem Features:

1. ✅ **15 Facility Types** - FACILITIES_CONFIG ile tanımlı
2. ✅ **Item Database Expansion** - 50+ yeni item (materials, weapons, potions, runes, gems)
3. ✅ **Production Recipe System** - facility_recipes tablosu + metadata
4. ✅ **Rarity Outcome RNG** - determine_rarity_outcome() function
5. ✅ **Suspicion Tracking** - facility-level suspicion sistem
6. ✅ **Prison Integration** - check_and_admit_to_prison() logic
7. ✅ **Offline Production** - calculate_offline_production() function
8. ✅ **Worker System** - workers_per_level + offline_cap_per_level
9. ✅ **Upgrade Costs** - dynamic cost calculation based on level
10. ✅ **FacilityManager API** - 15 facility support'lu refactored

---

## 🚨 NEXT IMMEDIATE ACTION

**Başlama:** Backend RPC functions yazma (supabase/functions/)

**İlk 3 RPC:**
1. `get_player_facilities(p_player_id UUID)` - Tüm tesisleri fetch
2. `unlock_facility(p_facility_type VARCHAR)` - Kilit aç
3. `start_facility_production(...)` - Üretim başlat

**Yazarken:**
- Hata handling ekle
- RLS policies'i respect et
- Transaction'lar kap (atomicity)
- Logging'i console'a yazdır

---

## 📞 QUESTIONS / DOUBTS?

Bu implementation guide'da:
1. Tüm 15 tesis tanımlı
2. Tüm database tables/functions ready
3. Frontend yapılması gereken yapı ortada
4. Integration points çok açık

Devam etmek için "Backend RPC yazma" ile başlamanızı öneriyor
