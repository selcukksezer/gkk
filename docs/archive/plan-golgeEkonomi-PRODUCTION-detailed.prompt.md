# Gölge Ekonomi — Üretim & Bina Sistemi Detaylı Belge

> Kaynak: plan-golgeEkonomi-part-03.prompt.md (Faza 10)
> Oyun: Gölge Krallık: Kadim Mühür'ün Çöküşü
> Amaç: 5 bina tipi, üretim mekanizmaları, kaynak yönetimi, ekonomi entegrasyonu

---

## 1. ÜRET İM SİSTEMİ GENEL BAKIŞ

### 1.1 Tasarım Prensipleri
- **Pasif gelir:** Binalar offline'ken üretim yapar
- **Supply kontrolü:** Üretim limitleri ile enflasyon önlenir
- **Yatırım-getiri dengesi:** Bina yükseltmesi uzun vadeli yatırım
- **Player interdependence:** Oyuncular birbirine bağımlı (market)
- **Server-authoritative:** Üretim hesaplaması server'da

### 1.2 Ortaçağ Teması: "Kasaba Yönetimi"
- 5 ana bina tipi
- Her bina kaynak üretir
- Kaynaklar birbirine bağımlı (zincir)
- Upgrade sistemi (seviye 1→5)
- Worker/Slave sistemi (optional: ethical concern)

---

## 2. BİNA TİPLERİ VE ÖZELLİKLERİ

### 2.1 Bina Listesi

| Bina | Üretim | Gerekli Kaynak | Kullanım Alanı |
|------|--------|----------------|----------------|
| Demirci | Silah, Zırh | Demir, Odun | PvP, Görev |
| Simyacı | İksir, Rün | Kristal, Bitki | Enerji, Geliştirme |
| Çiftlik | Yiyecek, Bitki | Su, Tohum | Simya, Üretim Booster |
| Maden | Demir, Kristal | - (doğal kaynak) | Demirci, Simya |
| Kereste | Odun | - (doğal kaynak) | Demirci, Bina Upgrade |

### 2.2 DEMİRCİ (Forge/Blacksmith)

**Üretim:**
- Temel Silahlar (kılıç, mızrak, yay)
- Temel Zırhlar (plate, chain, leather)
- Geliştirme hizmeti (enhancement)

**Seviyelere Göre Üretim:**

| Seviye | Üretim Kapasitesi | Üretim Hızı | Ürün Kalitesi | Slot |
|--------|-------------------|-------------|---------------|------|
| 1 | 5 item/gün | 100% | Yaygın | 2 |
| 2 | 10 item/gün | 110% | Yaygın + %10 Uncommon | 3 |
| 3 | 20 item/gün | 120% | %20 Uncommon | 4 |
| 4 | 40 item/gün | 130% | %30 Uncommon + %5 Nadir | 5 |
| 5 | 80 item/gün | 150% | %40 Uncommon + %10 Nadir | 6 |

**Üretim Tarifi (Örnek: Demir Kılıç)**
```json
{
  "item": "iron_sword",
  "tier": "common",
  "materials": {
    "iron_ingot": 10,
    "wood": 5
  },
  "production_time": 3600,  // 1 saat
  "gold_cost": 500,
  "blacksmith_level_required": 1
}
```

**Yükseltme Maliyeti:**
```
Seviye 1→2: 10K altın + 100 odun + 50 demir
Seviye 2→3: 50K altın + 500 odun + 200 demir
Seviye 3→4: 200K altın + 2K odun + 1K demir
Seviye 4→5: 1M altın + 10K odun + 5K demir
```

### 2.3 SİMYACI (Alchemy Lab)

**Üretim:**
- İksirler (Minör, Büyük, Yüce)
- Antidot
- Rün Taşları (Basit → Efsanevi)
- Buff İksiri (PvP/PvE için)

**Seviyelere Göre Üretim:**

| Seviye | İksir/Gün | Rün/Hafta | Antidot/Gün | Slot |
|--------|-----------|-----------|-------------|------|
| 1 | 10 Minör | - | 1 | 2 |
| 2 | 10 Minör + 5 Büyük | 1 Basit | 2 | 3 |
| 3 | 20 Minör + 10 Büyük | 2 Basit + 1 Gelişmiş | 3 | 4 |
| 4 | 20 Büyük + 5 Yüce | 1 Usta | 5 | 5 |
| 5 | 30 Büyük + 10 Yüce | 2 Usta + 1 Efsanevi | 10 | 6 |

**Üretim Tarifi (Örnek: Büyük İyileştirme İksiri)**
```json
{
  "item": "greater_healing_potion",
  "tier": "uncommon",
  "materials": {
    "crystal": 20,
    "herb": 10,
    "water": 5
  },
  "production_time": 7200,  // 2 saat
  "gold_cost": 2000,
  "alchemy_level_required": 2
}
```

**Yükseltme Maliyeti:**
```
Seviye 1→2: 20K altın + 100 kristal + 50 bitki
Seviye 2→3: 100K altın + 500 kristal + 200 bitki
Seviye 3→4: 500K altın + 2K kristal + 1K bitki
Seviye 4→5: 2M altın + 10K kristal + 5K bitki
```

### 2.4 ÇİFTLİK (Farm)

**Üretim:**
- Yiyecek (HP regeneration buff için)
- Bitkiler (simya için)
- Tohum (yeniden üretim için)
- Su (temiz kaynak)

**Seviyelere Göre Üretim:**

| Seviye | Yiyecek/Gün | Bitki/Gün | Tohum/Gün | Su/Gün | Slot |
|--------|-------------|-----------|-----------|--------|------|
| 1 | 50 | 10 | 5 | 20 | 2 |
| 2 | 100 | 20 | 10 | 40 | 3 |
| 3 | 200 | 40 | 20 | 80 | 4 |
| 4 | 400 | 80 | 40 | 160 | 5 |
| 5 | 800 | 160 | 80 | 320 | 6 |

**Özel Özellik: Seasonal Bonus**
- Bahar: +20% bitki
- Yaz: +20% yiyecek
- Sonbahar: +20% tohum
- Kış: -%10 tüm üretim

**Yükseltme Maliyeti:**
```
Seviye 1→2: 5K altın + 50 tohum + 20 su
Seviye 2→3: 25K altın + 200 tohum + 100 su
Seviye 3→4: 100K altın + 1K tohum + 500 su
Seviye 4→5: 500K altın + 5K tohum + 2K su
```

### 2.5 MADEN (Mine)

**Üretim:**
- Demir Cevheri (ham)
- Demir Külçe (işlenmiş)
- Kristal (nadir)
- Eter Tozu (çok nadir)

**Seviyelere Göre Üretim:**

| Seviye | Demir/Gün | Kristal/Gün | Eter Tozu/Hafta | Slot |
|--------|-----------|-------------|-----------------|------|
| 1 | 100 | 0 | 0 | 2 |
| 2 | 200 | 10 | 0 | 3 |
| 3 | 400 | 30 | 1 | 4 |
| 4 | 800 | 80 | 3 | 5 |
| 5 | 1600 | 200 | 10 | 6 |

**Madenci Sayısı:**
- Her seviye +2 madenci
- Madenci başına +10% üretim
- Maksimum: 10 madenci (seviye 5)

**Yükseltme Maliyeti:**
```
Seviye 1→2: 15K altın + 200 odun
Seviye 2→3: 75K altın + 1K odun + 100 demir
Seviye 3→4: 300K altın + 5K odun + 500 demir
Seviye 4→5: 1.5M altın + 20K odun + 2K demir
```

### 2.6 KERESTE (Lumber Mill)

**Üretim:**
- Ham Odun (ağaç kesimi)
- İşlenmiş Tahta (yapı malzemesi)
- Kömür (demirci için)

**Seviyelere Göre Üretim:**

| Seviye | Odun/Gün | Tahta/Gün | Kömür/Gün | Slot |
|--------|----------|-----------|-----------|------|
| 1 | 100 | 20 | 0 | 2 |
| 2 | 200 | 50 | 10 | 3 |
| 3 | 400 | 120 | 30 | 4 |
| 4 | 800 | 300 | 80 | 5 |
| 5 | 1600 | 700 | 200 | 6 |

**Özel Mekanik: Orman Yönetimi**
- Her kesim sonrası yeniden ağaç dikilebilir
- Dikilmeyen ağaçlar: üretim -%5/hafta (kümülatif)
- Maksimum ceza: -%50

**Yükseltme Maliyeti:**
```
Seviye 1→2: 8K altın + 100 tohum
Seviye 2→3: 40K altın + 500 tohum + 50 demir
Seviye 3→4: 150K altın + 2K tohum + 200 demir
Seviye 4→5: 800K altın + 10K tohum + 1K demir
```

---

## 3. ÜRETİM MEKANİZMASI

### 3.1 Üretim Döngüsü

**Üretim başlatma:**
1. Oyuncu bina seçer
2. Tarif seçilir (available recipes)
3. Malzemeler kontrol edilir
4. Üretim kuyruğuna eklenir
5. Süre başlar (offline da çalışır)

**Üretim hesaplama (Server-side):**
```typescript
function calculateProduction(
  buildingId: string,
  recipeId: string,
  startTime: number,
  currentTime: number
): ProductionResult {
  const building = getBuilding(buildingId);
  const recipe = getRecipe(recipeId);
  
  // Geçen süre
  const elapsed = currentTime - startTime;
  
  // Üretim hızı bonusu
  const speedMultiplier = building.level * 0.1 + 1.0;  // Lv1: 1.1x, Lv5: 1.5x
  
  // Etkili üretim süresi
  const effectiveTime = elapsed * speedMultiplier;
  
  // Tamamlanan üretim sayısı
  const completed = Math.floor(effectiveTime / recipe.production_time);
  
  // Kalan süre
  const remainingTime = (effectiveTime % recipe.production_time) / speedMultiplier;
  
  return {
    completed_count: completed,
    remaining_time: remainingTime,
    items_produced: recipe.output * completed
  };
}
```

### 3.2 Offline Üretim

**Hesaplama:**
- Son login timestamp'i kayıtlı
- Maksimum offline üretim: 24 saat
- 24 saatten fazla: cap uygulanır

```typescript
function calculateOfflineProduction(
  playerId: string,
  lastLoginTime: number,
  currentTime: number
): OfflineProduction {
  const MAX_OFFLINE_HOURS = 24;
  const elapsed = currentTime - lastLoginTime;
  const hours = Math.min(elapsed / 3600, MAX_OFFLINE_HOURS);
  
  const buildings = getPlayerBuildings(playerId);
  const results = [];
  
  for (const building of buildings) {
    if (building.queue.length === 0) continue;
    
    const production = calculateProduction(
      building.id,
      building.queue[0].recipe_id,
      lastLoginTime,
      lastLoginTime + hours * 3600
    );
    
    results.push({
      building_id: building.id,
      items_produced: production.items_produced
    });
  }
  
  return {
    hours_passed: hours,
    capped: elapsed / 3600 > MAX_OFFLINE_HOURS,
    productions: results
  };
}
```

### 3.3 Üretim Kuyruğu (Queue)

**Her binada:**
- Slot sayısı (seviye ile artar)
- FIFO (First In First Out)
- Otomatik devam (optional)

**Queue management:**
```typescript
interface ProductionQueue {
  building_id: string;
  slots: ProductionSlot[];
  auto_continue: boolean;
}

interface ProductionSlot {
  recipe_id: string;
  quantity: number;
  started_at: number;
  estimated_completion: number;
}
```

**Auto-continue özelliği:**
- Queue boşalınca son tarifi tekrar başlat
- Malzeme yeterli olduğu sürece
- Premium özellik (7 günlük: 200💎)

---

## 4. KAYNAK YÖNETİMİ VE DEPOLAMA

### 4.1 Depo Kapasitesi

**Her kaynağın stack limiti:**
```
Temel kaynaklar (demir, odun, kristal): 10,000/stack
İşlenmiş kaynaklar (külçe, tahta): 5,000/stack
İksir: 500/stack
Rün: 100/stack
Ekipman: 1/stack
```

**Depo yükseltme:**
```
Depo Seviye 1: 20 slot (base)
Depo Seviye 2: 30 slot (+10K altın)
Depo Seviye 3: 40 slot (+50K altın)
Depo Seviye 4: 60 slot (+200K altın)
Depo Seviye 5: 80 slot (+1M altın)
```

### 4.2 Kaynak Zinciri (Dependency Chain)

```
[Maden] → Demir → [Demirci] → Silah/Zırh
         ↓
      Kristal → [Simyacı] → İksir/Rün
                   ↑
[Çiftlik] → Bitki ──┘
            ↓
         Yiyecek (buff)

[Kereste] → Odun → [Demirci]
                 → [Bina Upgrade]

[Çiftlik] → Su → [Simyacı]
```

**Örnek tam üretim zinciri (Büyük İksir):**
```
1. Çiftlik → Bitki (1 saat)
2. Maden → Kristal (1 saat)
3. Çiftlik → Su (30 dk)
4. Simyacı → Büyük İksir (2 saat)

Toplam: ~4.5 saat (paralel üretim ile 2-3 saat)
```

### 4.3 Kaynak Pazarı Entegrasyonu

**Oyuncular arası ticaret:**
- Her kaynak market'te satılabilir
- Fiyat arz-talebe göre
- Bölgesel pazar farkları

**Kaynak fiyat örneği (Ana şehir):**
```
Demir: 10-20 altın/adet
Kristal: 50-100 altın/adet
Bitki: 20-40 altın/adet
Odun: 5-10 altın/adet
Eter Tozu: 1K-5K altın/adet
```

---

## 5. EKONOMİ ENTEGRASYONU

### 5.1 Para Yakma (Gold Sink)

**Üretim maliyetleri:**
- Her üretim: recipe.gold_cost
- Bina yükseltme: büyük maliyet
- Malzeme alımı (NPC'den): yüksek fiyat

**Aylık tahmin (1000 oyuncu):**
```
Bina yükseltmeleri: ~50M altın
Üretim maliyetleri: ~30M altın
NPC alımları: ~20M altın

Toplam: ~100M altın/ay
```

### 5.2 Supply Kontrolü

**Üretim limitleri:**
- Günlük üretim cap'i
- Offline üretim cap'i
- Slot limiti

**Enflasyon önleme:**
- Malzeme tüketimi (geliştirme, PvP)
- Item durability loss
- Yok olan itemler

### 5.3 Player Interdependence

**Üretim uzmanlaşması:**
- Tüm binaları max yapmak çok pahalı
- Oyuncular uzmanlaşır:
  - "Demirci oyuncusu" → silah üreticisi
  - "Simyacı oyuncusu" → iksir üreticisi
  - "Madenci oyuncusu" → ham kaynak

**Market bağımlılığı:**
- Hiçbir oyuncu self-sufficient değil
- Market zorunlu
- Ekonomi canlı kalır

---

## 6. UI/UX TASARIMI

### 6.1 Bina Yönetimi Ekranı

```
┌─────────────────────────────────────────────┐
│  BİNALARIM                                  │
├─────────────────────────────────────────────┤
│                                             │
│  [Demirci Lv3]  [Simyacı Lv2]  [Çiftlik Lv4] │
│  [Maden Lv2]    [Kereste Lv1]              │
│                                             │
│  Toplam Slot: 5/10                         │
│  [YENİ BİNA EKLE] [+300💎]                 │
└─────────────────────────────────────────────┘
```

### 6.2 Üretim Ekranı (Demirci Örneği)

```
┌─────────────────────────────────────────────┐
│  DEMİRCİ (Seviye 3)                         │
├─────────────────────────────────────────────┤
│  TARİFLER:                                  │
│  • Demir Kılıç [10 Demir, 5 Odun] - 1h     │
│  • Çelik Zırh [20 Demir, 10 Odun] - 2h     │
│  • Mızrak [15 Demir, 8 Odun] - 1.5h        │
│                                             │
│  ÜRETİM KUYRUGU:                            │
│  1. [Demir Kılıç] ████████░░ 80% (12dk)    │
│  2. [Çelik Zırh] ░░░░░░░░░░ 0% (kuyrukte)  │
│  3. [Boş]                                   │
│  4. [Boş]                                   │
│                                             │
│  [YENİ ÜRETİM EKLE]  [OTOMATIK DEVAM: ✓]   │
└─────────────────────────────────────────────┘
```

### 6.3 Offline Üretim Özeti

```
┌─────────────────────────────────────────────┐
│  HOŞGELDİN!                                 │
│                                             │
│  24 saat boyunca offline'dın.              │
│  İşte üretimler:                           │
│                                             │
│  🔨 Demirci: 15x Demir Kılıç               │
│  ⚗️ Simyacı: 8x Büyük İksir                │
│  🌾 Çiftlik: 200x Bitki, 100x Yiyecek      │
│  ⛏️ Maden: 400x Demir, 50x Kristal         │
│  🪵 Kereste: 300x Odun                      │
│                                             │
│  Toplam değer: ~150K altın                 │
│                                             │
│  [TOPLARI AL]  [MARKET'E KOY]              │
└─────────────────────────────────────────────┘
```

---

## 7. SERVER-SIDE IMPLEMENTATION

### 7.1 Production API

**Start production:**
```
POST /v1/production/start
Body: {
  "building_id": "uuid",
  "recipe_id": "uuid",
  "quantity": 5
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "queue_position": 2,
    "estimated_completion": "2026-01-04T12:30:00Z",
    "materials_consumed": {
      "iron": 50,
      "wood": 25
    },
    "gold_spent": 2500
  }
}
```

**Collect production:**
```
POST /v1/production/collect
Body: {
  "building_id": "uuid"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "items_collected": [
      {"item_id": "iron_sword", "quantity": 5}
    ],
    "total_value": 15000
  }
}
```

### 7.2 Production Calculation (TypeScript)

```typescript
async function startProduction(
  playerId: string,
  buildingId: string,
  recipeId: string,
  quantity: number
): Promise<ProductionResult> {
  // [1] Validate building ownership
  const building = await getBuilding(buildingId);
  if (building.owner_id !== playerId) {
    throw new Error("Not building owner");
  }
  
  // [2] Check recipe availability
  const recipe = await getRecipe(recipeId);
  if (recipe.required_level > building.level) {
    throw new Error("Building level too low");
  }
  
  // [3] Check materials
  const player = await getPlayer(playerId);
  const totalCost = {
    gold: recipe.gold_cost * quantity,
    materials: {}
  };
  
  for (const [material, amount] of Object.entries(recipe.materials)) {
    totalCost.materials[material] = amount * quantity;
  }
  
  if (player.gold < totalCost.gold) {
    throw new Error("Insufficient gold");
  }
  
  for (const [material, amount] of Object.entries(totalCost.materials)) {
    if (player.inventory[material] < amount) {
      throw new Error(`Insufficient ${material}`);
    }
  }
  
  // [4] Check queue slots
  const queue = await getProductionQueue(buildingId);
  if (queue.slots.filter(s => s !== null).length >= building.max_slots) {
    throw new Error("Queue full");
  }
  
  // [5] Calculate completion time
  const speedMultiplier = 1.0 + (building.level - 1) * 0.1;
  const productionTime = recipe.production_time / speedMultiplier;
  const now = Date.now();
  
  // Find last item in queue
  const lastItem = queue.slots.filter(s => s !== null).pop();
  const startTime = lastItem 
    ? lastItem.estimated_completion 
    : now;
  
  const estimatedCompletion = startTime + productionTime * quantity;
  
  // [6] Database transaction
  await supabase.transaction(async (tx) => {
    // Deduct costs
    await tx.update('players')
      .set({ gold: player.gold - totalCost.gold })
      .eq('id', playerId);
    
    for (const [material, amount] of Object.entries(totalCost.materials)) {
      await tx.update('inventory_materials')
        .decrement({ [material]: amount })
        .eq('player_id', playerId);
    }
    
    // Add to queue
    await tx.insert('production_queue').values({
      building_id: buildingId,
      recipe_id: recipeId,
      quantity,
      started_at: startTime,
      estimated_completion: estimatedCompletion,
      status: 'in_progress'
    });
    
    // Ledger
    await tx.insert('ledger_entries').values({
      player_id: playerId,
      type: 'production_start',
      amount: -totalCost.gold,
      balance_after: player.gold - totalCost.gold,
      metadata: {
        building_id: buildingId,
        recipe_id: recipeId,
        quantity
      }
    });
  });
  
  // [7] Telemetry
  await trackEvent('production_started', {
    player_id: playerId,
    building_type: building.type,
    recipe_id: recipeId,
    quantity,
    gold_spent: totalCost.gold
  });
  
  return {
    success: true,
    queue_position: queue.slots.filter(s => s !== null).length + 1,
    estimated_completion: new Date(estimatedCompletion),
    materials_consumed: totalCost.materials,
    gold_spent: totalCost.gold
  };
}
```

---

## 8. ANTI-ABUSE VE EXPLOIT ÖNLEME

### 8.1 Time Manipulation
**Önlem:**
- Tüm timestamp'ler server'da
- Client time trust edilmez
- Offline calculation server-side

### 8.2 Resource Duplication
**Önlem:**
- Material deduction atomic
- Optimistic locking
- Idempotency check

### 8.3 Queue Manipulation
**Önlem:**
- Queue state server'da
- Her değişiklik audit edilir
- Rate limiting (10 production start/min)

### 8.4 Unlimited Offline Production
**Önlem:**
- 24 saat cap (hard limit)
- Notification: "24 saat geçti, üretim durdu"
- Premium: 48 saat cap (optional)

---

## 9. TELEMETRY VE METRIKLER

### 9.1 Tracked Events
```typescript
trackEvent('building_constructed', {...});
trackEvent('building_upgraded', {...});
trackEvent('production_started', {...});
trackEvent('production_completed', {...});
trackEvent('offline_production_collected', {...});
```

### 9.2 KPI'lar
- Ortalama bina seviyesi/oyuncu
- Günlük üretim hacmi (altın değeri)
- En popüler tarif
- Offline üretim oranı (%cap'e ulaşan)
- Material flow (supply/demand dengesi)

---

## 10. DEFINITION OF DONE

- [ ] 5 bina tipi çalışıyor
- [ ] Üretim kuyruğu sistemi aktif
- [ ] Offline üretim hesaplaması doğru
- [ ] Material deduction atomic
- [ ] Queue UI çalışıyor
- [ ] Bina upgrade çalışıyor
- [ ] Anti-abuse limitleri aktif
- [ ] Telemetry toplanuyor

---

Bu döküman, üretim/bina sisteminin tam teknik spesifikasyonunu, ekonomi entegrasyonunu ve production-ready implementasyon detaylarını içerir.
