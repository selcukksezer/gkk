# 🚀 FACILITIES SYSTEM - QUICK REFERENCE GUIDE
> Hızlı bakış, önemli linkler ve dosya yerleşimi

---

## 📁 İLGİLİ DOSYALAR

### Taslak & Tasarım Dökümanları
- `FACILITIES_SYSTEM_COMPLETE_PLAN.md` ← **START HERE** - Tam sistem tasarımı
- `FACILITIES_TODO_LIST.md` ← To-do list (126 task, 110-140 saat)
- `plan-golgeEkonomi-PRODUCTION-detailed.prompt.md` - Üretim sistemi

### GDScript Dosyaları (Mevcut)
- `scenes/ui/screens/FacilitiesScreen.gd` - Tesisler hub (GELİŞTİRİLMELİ)
- `scenes/ui/screens/FacilityDetailScreen.gd` - Detay ekranı (MEVCUT)
- `scenes/ui/screens/CraftingScreen.gd` - Crafting (HAZIRLANACAK)
- `scenes/ui/screens/MiningScreen.tscn` - Kaynak toplama (hazır, Prison'a bağlı değil)
- `scenes/ui/screens/PrisonScreen.gd` - Hapishane (MEVCUT)
- `core/managers/FacilityManager.gd` - Backend manager (GELİŞTİRİLMELİ)
- `core/data/ItemData.gd` - Item sistemi (İyi tasarlanmış)

### Database Dosyaları
- `database/migrations/` - Tüm migrations buraya ekle
- SQL Scripts:
  - `00_create_facilities_table.sql`
  - `01_create_facility_recipes.sql`
  - `02_create_production_queue.sql`
  - `03_create_rpc_functions.sql`

---

## 🎯 15 TESİS HIZLI ÖZET

| # | Tesis | Level | Kaynakları | Kullanım |
|---|-------|-------|------------|----------|
| 1 | ⛏️ Maden | 1-5 | Demir, Kristal | Temel |
| 2 | 🪵 Kereste | 1-5 | Odun, Tahta | Temel |
| 3 | 🌾 Çiftlik | 1-5 | Bitki, Yiyecek | Temel |
| 4 | 🪨 Heykeltaş | 1-5 | Taş | Temel |
| 5 | ⚒️ Demirci | 1-5 | Silah (rarity) | Craft |
| 6 | 🛡️ Zırh Ustası | 1-5 | Zırh (rarity) | Craft |
| 7 | ⚗️ Simya Lab | 1-5 | İksir (rarity) | Craft |
| 8 | ✨ Rün Master | 1-5 | Rünler | Craft |
| 9 | 📜 Kağıt Yazarı | 1-5 | Upgrade Scroll | Craft |
| 10 | 🦌 Deri İşleme | 1-5 | Deri Zırh | Craft |
| 11 | 🌠 Enchanter | 1-5 | Geliştirme (+0→+10) | Special |
| 12 | 🧪 Cincel Lab | 1-5 | İksir Blending | Special |
| 13 | 🏪 Market Hub | - | Satış/Alış | Special |
| 14 | 🍺 Taverna | 1-5 | Sosyal Hub | Hub |
| 15 | 🏦 Vault/Bank | 1-5 | Storage Expansion | Hub |

---

## ⚡ OYUN LOOP (Oyuncu Perspektifi)

```
1. KAYNAKAĞINI TOPLA (MiningScreen)
   └─ Enerji kullan → Riski: Hapishane
   
2. HAP İSHANEYE GİRERSE (PrisonScreen)
   └─ Cikartıl: Gem / Rüşvet / Bekle
   
3. TESİS SATINALSA (FacilitiesScreen)
   └─ 50K-300K altın → Lv1'den başla
   
4. TESİS UPGRADE ETSE (FacilityDetailScreen)
   └─ Seviye arttır (Lv1→5)
   
5. CRAFTING BAŞLATSA (CraftingScreen)
   └─ Malzeme seç → Batch → Başlat
   
6. ÜRETİM BİTSİ (FacilityDetailScreen Queue)
   └─ Topla → Inventory'ye ekle
   
7. MARKET'TE SATAŞ (PazarScreen)
   └─ Aldığı gelirle tekrar #3'e dön
   
8. GÜÇ ARTTIKÇA (Craft rarity artıyor)
   └─ Daha zor dungeon → Daha çok kaynak
```

---

## 🔧 TEKN İK STACK

| Katman | Teknoloji | Dosyalar |
|--------|-----------|----------|
| **Frontend** | GDScript 4.x | scenes/ui/screens/*.gd |
| **Backend** | Supabase + Edge Functions | REST API |
| **Database** | PostgreSQL | database/*.sql |
| **Cache** | In-memory (Godot) | autoload/StateStore.gd |
| **Analytics** | Telemetry | autoload/TelemetryClient.gd |

---

## 📊 KRITIK HESAPLAMALAR

### Upgrade ROI Örneği (Demirci)
```
Lv1 Satın Al: 50K
Lv1→Lv2: 10K + 100 odun + 50 demir
Lv2→Lv3: 50K + 500 odun + 200 demir
Lv3→Lv4: 200K + 2K odun + 1K demir
Lv4→Lv5: 1M + 10K odun + 5K demir
──────────────────
Toplam: 1.31M altın + kaynaklar

Günlük Verim (Lv5):
80 silah × 500 altın (avg market price) = 40K/gün

ROI: 1.31M ÷ 40K = 32.75 gün
(Yavaş ama stratejik)
```

### Suspicion & Prison
```
Her harvest: +1-5 suspicion
Bribe: -10 suspicion per 5 gems

Prison Risk Tetiklemesi:
IF suspicion > 80:
  Harvest başarı şansı: %50
  Prison RNG: 50% (Lv1), 10% (Lv5)
  
Sentence: Lv × 0.5-1.5 saat
Orn: Suspicion 80, Harvest başarısızlık
→ 2-8 saat hapishane
```

---

## 🎨 UI LAYOUT HIZLISI

### FacilitiesScreen (Grid)
```
┌──────────┐ ┌──────────┐ ┌──────────┐
│ Maden    │ │Kereste   │ │Çiftlik   │
│ Lv3      │ │Lv2       │ │Lv1       │
│45K/gün   │ │30K/gün   │ │25K/gün   │
└──────────┘ └──────────┘ └──────────┘

┌──────────┐ ┌──────────┐ ┌──────────┐
│Demirci   │ │Zırh U.   │ │Simya     │
│Lv5       │ │Lv3       │ │Lv4       │
│50K/gün   │ │35K/gün   │ │60K/gün   │
└──────────┘ └──────────┘ └──────────┘

[Toplam Passive: 240K/gün]
```

### FacilityDetailScreen (Tabs)
```
┌─────────────────────────────────┐
│ DEMIRCI ⚒️ | UPGRADE | MANAGE   │
├─────────────────────────────────┤
│ Status (Lv, Suspicion, Workers) │
│ Üretim Kuyruğu (Progress bars)  │
│ Tarifler (Recipe List)          │
│ Yönetim (Bribe, Workers)        │
└─────────────────────────────────┘
```

---

## 🔗 API ENDPOINTS (QUICK REFERENCE)

```bash
# Facility Management
POST   /v1/facilities/unlock              ← Unlock facility
POST   /v1/facilities/{id}/upgrade        ← Upgrade level
GET    /v1/facilities/{id}                ← Get facility details

# Recipes
GET    /v1/recipes/{facility_type}        ← Get all recipes

# Production
POST   /v1/production/start               ← Start crafting
GET    /v1/production/queue               ← Get queue status
POST   /v1/production/{id}/collect        ← Collect finished item
POST   /v1/production/{id}/cancel         ← Cancel job

# Economy
GET    /v1/economy/facility-stats         ← Global stats
GET    /v1/economy/market-prices          ← Prices

# Admin
GET    /v1/admin/facility-stats           ← Analytics dashboard
```

---

## 🎓 LEARNING RESOURCES

1. **Game Design**
   - `OYUN-OZET-v2.0.md` - Full game design doc
   - `plan-golgeEkonomi-part-*.md` - Detailed feature docs

2. **Item System**
   - `core/data/ItemData.gd` - Rarity, enhancement, stats
   - `DUNGEON-MECHANICS-GUIDE.md` - Rarity bonuses

3. **Economy**
   - `plan-golgeEkonomi-part-01a-detailed.prompt.md` - Market algorithm
   - `FACILITIES_SYSTEM_COMPLETE_PLAN.md` - Facility economics

4. **Prison System**
   - `scenes/ui/screens/PrisonScreen.gd` - Mevcut implementasyon
   - `FACILITIES_TODO_LIST.md` - Phase 4 için detaylar

---

## ✅ BAŞLAMADAN ÖNCE CHECKLIST

### Setup
- [ ] Tüm markdown dosyalarını oku (1-2 saat)
- [ ] FacilityDetailScreen.gd mevcut kodunu incele
- [ ] FacilityManager.gd'de ne var ne yok kontrol et
- [ ] Supabase tabloları var mı kontrol et (facilities, facility_recipes, facility_queue)
- [ ] ItemData.gd'deki rarity sistemi anla

### Database Prep
- [ ] `FACILITIES_TODO_LIST.md` Phase 1'i tamamla
- [ ] SQL migration scripts yaz
- [ ] RPC functions implement et
- [ ] API endpoints test et

### Frontend Start
- [ ] FacilitiesScreen.gd güncelle (Phase 2.1)
- [ ] FacilityDetailScreen.gd tabs ekle (Phase 2.2-2.5)
- [ ] CraftingScreen.gd yeni oluştur (Phase 3)
- [ ] Prison linkage ekle (Phase 4)

---

## 🎯 SUCCESS METRICS

```
Başlama: 30 Ocak 2026
Hedef: 10-17 Mart 2026 (6 hafta)

✅ Phase 1 (Database): Hafta 1
✅ Phase 2 (FacilitiesUI): Hafta 2-3
✅ Phase 3 (CraftingUI): Hafta 4
✅ Phase 4 (Prison): Hafta 4-5
✅ Phase 5-7 (Economy, Analytics, Mobile): Hafta 5-6
✅ Phase 8 (Testing): Hafta 6-7
✅ Phase 9 (Launch): Hafta 7-8
```

---

## 🚨 RED FLAGS (Dikkat Edilecekler)

1. **Database Performance**
   - facility_queue 100K+ records → Indexing kritik
   - Rarity RNG server-side olmak zorunda (client manipulation)
   
2. **Prison Integration**
   - MiningScreen henüz Prison'a linkli değil
   - Suspicion tracking uygulanmadı
   - Risk RNG server'da hesaplanmalı

3. **Rarity Distribution**
   - Client'a RNG seed vermemeyi kapat
   - Craft outcome async beklenmeli
   - Simulated vs actual outcome ayrı tutmalı

4. **Market Economy**
   - Inflation kontrol edil (too much free gold)
   - Item sink mekanizması ekle (crafting costs)
   - Market price floor/ceiling belirle

---

## 📞 QUICK HELP

**Soru: Rarity nasıl hesaplanır?**  
Cevap: `plan-golgeEkonomi-PRODUCTION-detailed.prompt.md` → "2. BİNA TİPLERİ" → "2.2 DEMİRCİ" → "Rarity System"

**Soru: Prison risk ne?**  
Cevap: `FACILITIES_TODO_LIST.md` → "PHASE 4"

**Soru: Facility ROI hesaplaması?**  
Cevap: `FACILITIES_SYSTEM_COMPLETE_PLAN.md` → "💰 EKONOMI DENGESI"

**Soru: 15 tesis ne?**  
Cevap: `FACILITIES_SYSTEM_COMPLETE_PLAN.md` → "🏢 15 TESİS TİPİ DETAYLARI"

---

## 🔄 UPDATE WORKFLOW

1. **Kod yazıldığında:**
   - Commit message: `feat: [PHASE-X] [Task ID] - Description`
   - Örn: `feat: [PHASE-2.1] [2.1.3] - Add facility card icons`

2. **Task tamamlandığında:**
   - `FACILITIES_TODO_LIST.md`'de status güncelle
   - 🔴 → 🟡 (in-progress) → 🟢 (done)

3. **Phase tamamlandığında:**
   - Testing ve QA geç
   - Hataları Phase 8'de fixle

---

**Last Updated:** 30 Ocak 2026  
**Version:** 1.0  
**Status:** Ready to Start Development ✅
