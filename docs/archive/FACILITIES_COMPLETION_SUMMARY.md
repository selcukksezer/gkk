# 📋 FACILITIES SYSTEM - TAMAMLAMA ÖZETİ
> **Tarih:** 30 Ocak 2026  
> **Durum:** ✅ PLANLAMA TAMAMLANDI - GELIŞTIRMEYE HAZIR

---

## 📊 NE OLUŞTURDUM?

Oyunun ana döngüsü olan **Tesis/Crafting Sistemi** için kapsamlı bir tasarım ve uygulama planı hazırladım.

### 3 Ana Dokümantasyon Dosyası

#### 1️⃣ **FACILITIES_SYSTEM_COMPLETE_PLAN.md** (35+ sayfa)
**İçerik:**
- 🏢 15 tesisin tam detayı (özellikleri, upgrade maliyeti, üretim hızları)
- 💰 Ekonomi dengesi ve ROI hesaplamaları
- 🎮 Oyuncu progression örnekleri (Yeni/Orta/Endgame)
- 🎨 UI/UX wireframe'ler ve layouts
- ⚙️ Technical architecture (Database schema, API endpoints)
- 🛡️ Security & anti-cheat mekanizmaları
- 📱 Mobile optimization notları

**Game Developer Mindset:** Oyuncunun deneyimi, ekonomi dengesi, long-term engagement hedefleri düşünerek tasarlanmış.

---

#### 2️⃣ **FACILITIES_TODO_LIST.md** (126 görev, 110-140 saat)
**Yapılanma:**
```
PHASE 1: Database & Backend (20-24 sa)
├─ 1.1 Database schema (8 task)
├─ 1.2 Backend RPC functions (10 task)
├─ 1.3 API endpoints (8 task)
└─ 1.4 Server-side validations (5 task)

PHASE 2: FacilitiesScreen & DetailScreen (23-28 sa)
├─ 2.1 Main hub UI (10 task)
├─ 2.2 Detail screen main tab (8 task)
├─ 2.3 Production queue tab (7 task)
├─ 2.4 Recipes tab (8 task)
├─ 2.5 Management tab (6 task)
└─ 2.6 Error handling (5 task)

PHASE 3: CraftingScreen (18-22 sa)
├─ 3.1 Main UI (10 task)
├─ 3.2 Recipe cards & materials (5 task)
├─ 3.3 Batch crafting (4 task)
├─ 3.4 Rarity system UI (4 task)
├─ 3.5 Start crafting flow (5 task)
└─ 3.6 Simulated crafting (2 task)

PHASE 4: Prison Integration (8-12 sa) ← MiningScreen'i bağlama
PHASE 5: Economy & Balance (7-10 sa)
PHASE 6: Analytics & Telemetry (6-8 sa)
PHASE 7: Mobile Optimization (6-9 sa)
PHASE 8: Testing & QA (15-20 sa)
PHASE 9: Documentation & Launch (4-5 sa)
```

**Her Task:** Task ID, süre tahmini, bağımlılıkları, detaylı açıklaması ile

---

#### 3️⃣ **FACILITIES_QUICK_REFERENCE.md**
**Hızlı bakış:**
- 📁 İlgili dosyalar ve yerleşimleri
- 🎯 15 tesis tablosu
- ⚡ Oyun loop'u
- 🔗 API endpoints
- ✅ Başlamadan önce checklist

---

## 🎮 15 TESİS SISTEMI ÖZET

### Tesis Kategorileri

**KATEGORİ 1: Temel Kaynaklar (4 tesis)**
- ⛏️ **Maden** - Demir, Kristal, Eter Tozu
- 🪵 **Kereste** - Odun, Tahta, Kömür  
- 🌾 **Çiftlik** - Yiyecek, Bitki, Su (mevsimsel bonus)
- 🪨 **Heykeltaş** - Taş (zırh direnci bonusu)

**KATEGORİ 2: Crafted Items (6 tesis)**
- ⚒️ **Demirci** - Silah (Rarity: Common→Legendary)
- 🛡️ **Zırh Ustası** - Zırh setleri (4 parça = set bonusu)
- ⚗️ **Simya Lab** - İksirler (Minör→Yüce, batch blending)
- ✨ **Rün Master** - Geliştirme taşları (Kızıl/Mavi/Yeşil/Sarı)
- 📜 **Kağıt Yazarhanesi** - Upgrade Scrolls
- 🦌 **Deri İşleme** - Deri zırh & aksesuarlar

**KATEGORİ 3: Advanced Crafting (3 tesis)**
- 🌠 **Enchantment Academy** - Item enhancement (+0→+10)
- 🧪 **Cincel Workshop** - İksir kombinleme & keşif
- 🏪 **Market Hub** - Trading & price dynamics

**KATEGORİ 4: Hub Tesisleri (2 tesis)**
- 🍺 **Taverna** - Sosyal hub, buff iksiri consumtion
- 🏦 **Vault/Bank** - Storage expansion (50→200 slot)

---

## 💰 EKONOMİ DENGESI

### ROI Hesaplaması (Demirci Örneği)
```
Toplam Yatırım: 1.31M altın + kaynaklar
Günlük Verim (Lv5): 40K altın/gün
ROI: ~33 günde geri kazanılır

Stratejisi:
- Oyuncular hızlı return (Maden: 10 gün)
- Yavaş return (Demirci: 33 gün) çok güçlü → uzun-term
- Balanced: Simya Lab (22 gün)
```

### Inflation Control
```
Altın Sink (Harcama):
- Facility upgrades: 50M-300M (endgame)
- Enhancement: 15M/item
- Market tax: %10 per sale

Altın Source (Kazanç):
- Crafted sales: 10K-100K/item
- Passive production: 15K-50K/day
- Quests: 5K-50K
```

---

## 🎨 UI/UX DESIGN

### FacilitiesScreen (Tesisler Hub)
- 4×3 veya 3×5 grid layout (responsive)
- Her facility: icon, level badge, daily income, status
- Tap → FacilityDetailScreen

### FacilityDetailScreen (5 Tab)
1. **Main:** Status, suspicion, workers
2. **Queue:** Production progress, collect button
3. **Recipes:** Tarif listesi, START button, material check
4. **Management:** Bribe, worker management
5. **Upgrade:** Upgrade cost breakdown, confirm

### CraftingScreen
- Facility tabs
- Recipe cards dengan rarity probabilities
- Material availability check
- Batch selector (1x/5x/10x)
- Simulated outcome preview
- START button dengan confirmation

### Prison Integration
- MiningScreen'de suspicion warning
- Harvest fail → Prison RNG trigger
- 2-8 saat tutuluk (suspicion'a göre)
- Çıkış: Gem (instant) / Rüşvet (50% success) / Bekle (free)

---

## 🔧 TEKNİK ÖZETİ

### Database (Yeni Tablolar)
```sql
facilities
├─ facility_type, level, max_level
├─ production_rate_bonus, suspicion_level
├─ worker_count, unlock_cost

facility_recipes  
├─ output_item_id, duration_seconds
├─ required_materials (JSONB)
├─ success_rate, facility_level_required

facility_queue
├─ facility_id, recipe_id, quantity
├─ started_at, completed_at
├─ actual_output_items (with rarity)

crafted_items_log
├─ rarity_roll (0-1 random)
├─ rarity_result, stats_modifier
```

### API Endpoints (8 ana endpoint)
```
POST   /v1/facilities/unlock
POST   /v1/facilities/{id}/upgrade
GET    /v1/recipes/{facility_type}
POST   /v1/production/start
POST   /v1/production/{id}/collect
GET    /v1/production/queue
GET    /v1/economy/facility-stats
POST   /v1/admin/facility-stats
```

### Server-Side RNG
- Rarity determination: 0-1 random → COMMON/UNCOMMON/RARE/EPIC/LEGENDARY
- Prison admission: suspicion% chance
- Bribe success: 50% success rate
- Craft critical: 5% flawless, 2% failsafe

---

## 🎯 OYUNCU PROGRESSION

### Yeni Oyuncu (Gün 1-7)
- Enerji ile kaynak topla (MiningScreen)
- 50K+ altın tasarla
- İlk tesiyi satın al (Maden)

### Orta Oyuncu (Gün 30-90)
- 8-9 tesis kurulmuş
- 100K-150K/gün passive income
- Crafted rare/epic itemler yapıyor

### Endgame Oyuncu (Gün 90+)
- 15 tesis hepsi Lv5
- 300K-500K/gün passive income
- Legendary itemler craftiyor
- Lonca economisini yönetiyor

---

## 📱 PLATFORM OPTİMİZASYONU

- 44×44 dp minimum button size
- Responsive grid (2 col portrait, 3 col landscape)
- Virtual scrolling (>20 facility için)
- 5-10 dakika data cache TTL
- <100MB memory target
- Offline SQLite caching

---

## ✅ SUCCESS CRITERIA

- [x] 15 facility tipi tasarlandı
- [x] Rarity system tanımlandı (70/20/8/1.5/0.5%)
- [x] Upgrade maliyetleri balanced edildi
- [x] Prison integration planned
- [x] Economy analysis tamamlandı
- [ ] Database implementation (PHASE 1)
- [ ] Frontend implementation (PHASE 2-3)
- [ ] Testing & launch (PHASE 8-9)

---

## 📈 TAHMINI ZAMAN ÇİZELGESİ

```
HAFTA 1-2:   Database & Backend (PHASE 1)
HAFTA 3-4:   FacilitiesScreen UI (PHASE 2)
HAFTA 5:     CraftingScreen UI (PHASE 3)
HAFTA 6:     Prison Integration (PHASE 4)
HAFTA 7:     Economy, Analytics, Mobile (PHASE 5-7)
HAFTA 8:     Testing & QA (PHASE 8)
HAFTA 9:     Launch (PHASE 9)

Total: 6-9 HAFTA
Tek Developer: 8-10 hafta
3 Kişi Takım: 2-3 hafta
```

---

## 🎓 KULLANILAN REFERANSLAR

**Game Design:**
- The Crims (mobile crime simulator)
- Knight Online (item rarity & enhancement)
- Gölge Krallık oyun tasarım dökümanı

**Proje Dosyaları:**
- `OYUN-OZET-v2.0.md` - Main game design
- `plan-golgeEkonomi-*` - Detailed economy plans
- `DUNGEON-MECHANICS-GUIDE.md` - Item rarity system
- `core/data/ItemData.gd` - Existing item system

---

## 🚀 SONRAKI ADIMLAR

1. **Dökümanları oku** (2-3 saat)
   - FACILITIES_SYSTEM_COMPLETE_PLAN.md
   - FACILITIES_TODO_LIST.md
   - FACILITIES_QUICK_REFERENCE.md

2. **Database setup yap** (PHASE 1)
   - SQL migration scripts yaz
   - Supabase tables oluştur
   - RPC functions implement et

3. **Frontend geliştir** (PHASE 2-3)
   - FacilitiesScreen.gd güncelle
   - FacilityDetailScreen.gd tabs ekle
   - CraftingScreen.gd yeni oluştur

4. **Integration & Testing** (PHASE 4-8)
   - Prison linkage
   - Economy balance
   - QA & bug fixes

5. **Launch** (PHASE 9)
   - Soft launch beta testers'a
   - Full launch

---

## 📝 NOTLAR

> **The Crims + Knight Online Hybrid Oyunu**
> 
> Oyuncular:
> 1. Enerji ile kaynak toplar → **Mining risk** (hapishane)
> 2. Kaynakları tesislerde işler → **Passive income**
> 3. Crafted itemler ile market'te ticaret → **Economy**
> 4. Güçlü itemler ile dungeons → **More resources**
> 5. Loop devam et
>
> Bu sistem:
> - Short-term: Daily mining & crafting (aktif oyun)
> - Mid-term: Facility investments (2-4 hafta)
> - Long-term: Endgame economy (sonsuza kadar)

---

## 🎉 CONCLUSION

Oyun tasarımında "The Crims benzeri" ve "Knight Online benzeri" birleştirme başarıyla yapıldı. 15 tesis, 50+ crafting recipe, rarity system, prison integration, ve kapsamlı economy balancing ile **oyuncular için 3-6 ay oynanabilecek** bir sistem tasarladım.

Dökümanlar game developer'ların hemen implementeye başlayabileceği kadar detaylıdır.

**Status:** ✅ **READY FOR DEVELOPMENT**

---

**Hazırlayan:** Game Designer Assistant  
**Tarih:** 30 Ocak 2026  
**Version:** 1.0 Complete  
**Saatler Harcanan:** ~4-5 saat (tasarım + dokümantasyon)
