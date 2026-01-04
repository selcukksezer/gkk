# Gölge Ekonomi — Geliştirme/Basma Sistemi Detaylı Belge

> Kaynak: plan-golgeEkonomi-part-03.prompt.md (Faza 9)
> Oyun: Gölge Krallık: Kadim Mühür'ün Çöküşü
> Amaç: +0→+10 geliştirme mekanizması, başarı formülleri, rün taşı sistemi, ekonomi entegrasyonu

---

## 1. GELİŞTİRME SİSTEMİ GENEL BAKIŞ

### 1.1 Tasarım Prensipleri
- **Risk/ödül dengesi:** Yüksek seviye = yüksek risk + yüksek ödül
- **Enflasyon kontrolü:** Başarısız denemeler para yakar
- **Supply kontrolü:** Yok olan itemler supply azaltır
- **Pay-to-win değil:** Başarı şansı satın alınamaz (sadece rün taşı)
- **Server-authoritative:** Tüm RNG server'da

### 1.2 Ortaçağ Teması: "Demirci Sistemi"
- Item'lar "Demirci" (Anvil) binasında geliştirilir
- Rün taşları ile başarı şansı artırılır
- Koruma rünleri ile item kaybı önlenebilir
- Efsanevi ekipmanlar için usta demirci gerekir

---

## 2. GELİŞTİRME SEVİYELERİ VE BAŞARI ORANLARI

### 2.1 Seviye Bandları

| Seviye Aralığı | Zorluk | Başarı | Düşme | Yok Olma | İsim |
|----------------|--------|--------|-------|----------|------|
| +0 → +3 | Kolay | %100 | - | - | Temel |
| +4 → +6 | Orta | %70-50 | - | - | İyi |
| +7 | Zor | %35 | %65 | - | Nadir |
| +8 | Çok Zor | %20 | %40 | %40 | Epic |
| +9 | Efsanevi | %10 | %30 | %60 | Efsanevi |
| +10 | İmkansız | %3 | - | %97 | Legendary |

### 2.2 Detaylı Başarı Tablosu

```
+0 → +1: %100 başarı
+1 → +2: %100 başarı
+2 → +3: %100 başarı
+3 → +4: %70 başarı
+4 → +5: %60 başarı
+5 → +6: %50 başarı
+6 → +7: %35 başarı, %65 düşme (→+5)
+7 → +8: %20 başarı, %40 düşme (→+6), %40 yok olma
+8 → +9: %10 başarı, %30 düşme (→+7), %60 yok olma
+9 → +10: %3 başarı, %0 düşme, %97 yok olma
```

### 2.3 Başarı Hesaplama Formülü

**Base formula:**
```
success_chance = base_rate[level] + rune_bonus - penalty
```

**Penalty faktörleri:**
- Item durability < %50: -5% başarı
- Demirci seviyesi yetersiz: -10% başarı
- Aynı item 3+ başarısız: -2% (streak penalty)

**Bonus faktörleri:**
- Rün taşı: +5% → +20%
- Demirci ustası NPC: +5% (ücretli)
- Lonca bonusu: +2% (high-level guild)
- Event zamanı: +5% (özel günler)

**Final formula:**
```typescript
function calculateEnhancementChance(
  itemLevel: number,
  runeBonus: number,
  penalties: number[],
  bonuses: number[]
): number {
  const baseRate = BASE_RATES[itemLevel];
  const totalPenalty = penalties.reduce((a, b) => a + b, 0);
  const totalBonus = bonuses.reduce((a, b) => a + b, 0);
  
  const finalChance = baseRate + runeBonus + totalBonus - totalPenalty;
  
  return clamp(finalChance, 0.01, 0.99); // Min %1, Max %99
}
```

---

## 3. RÜN TAŞI SİSTEMİ

### 3.1 Rün Taşı Tipleri

**A. Başarı Rünleri (Success Runes)**

| Rün Tipi | Bonus | Kullanılabilir Seviye | Nadirlık | Üretim Maliyeti |
|----------|-------|----------------------|----------|-----------------|
| Basit Rün | +5% | +0 → +5 | Yaygın | 500 altın |
| Gelişmiş Rün | +10% | +3 → +7 | Uncommon | 5K altın |
| Usta Rün | +15% | +6 → +8 | Nadir | 50K altın |
| Efsanevi Rün | +20% | +8 → +10 | Epic | 500K altın |

**B. Koruma Rünleri (Protection Runes)**

| Rün Tipi | Etki | Kullanılabilir Seviye | Nadirlık | Üretim Maliyeti |
|----------|------|----------------------|----------|-----------------|
| Düşme Koruması | Başarısız olursa düşmez | +6 → +7 | Nadir | 20K altın |
| Kısmi Koruma | %50 şans düşme yerine kalır | +7 → +9 | Epic | 100K altın |
| Tam Koruma | Başarısız olursa yok olmaz | +8 → +10 | Legendary | 1M altın |

**C. Özel Rünler**

| Rün Tipi | Etki | Nadirlık |
|----------|------|----------|
| Bereket Rünü | Başarı şansını 2x yapar (tek kullanımlık) | Mythic |
| Kader Rünü | Garantili başarı (tek kullanımlık) | Mythic |
| Yeniden Şans | Başarısız olursa 1 kez daha dene | Legendary |

### 3.2 Rün Taşı Edinme Yolları

**Üretim (Simya):**
```
Basit Rün: 500 altın + 10 kristal + 2 saat
Gelişmiş Rün: 5K altın + 50 kristal + 6 saat
Usta Rün: 50K altın + 200 kristal + 24 saat
Efsanevi Rün: 500K altın + 1000 kristal + 72 saat
```

**Düşüş (Loot):**
- Zindan boss: %5 şans Gelişmiş Rün
- Nadir sandık: %1 şans Usta Rün
- Efsanevi sandık: %0.1 şans Efsanevi Rün

**Market:**
- Oyuncular arası ticaret
- Fiyat arz-talebe göre dinamik
- Yüksek seviye rünler çok pahalı

**Event:**
- Haftalık event: 1x Usta Rün
- Sezon ödülü: 1-3x Efsanevi Rün
- Lonca savaşı: 5x Gelişmiş Rün

### 3.3 Rün Kullanımı Kuralları

**Slot limiti:**
- Her geliştirme denemesinde max 3 rün kullanılabilir
- 1x Başarı Rünü + 1x Koruma Rünü + 1x Özel Rün

**Stack kuralları:**
- Aynı tipten birden fazla rün kullanılamaz
- Örnek: 2x Usta Rün yasak

**Tüketim:**
- Kullanılan rün her durumda tüketilir (başarılı/başarısız)
- Tek istisna: Yeniden Şans rünü başarıda geri döner

---

## 4. GELİŞTİRME MALİYETLERİ

### 4.1 Altın Maliyeti

**Base maliyet formülü:**
```
cost = 1000 × (1.5 ^ current_level) × item_tier_multiplier
```

**Item tier multipliers:**
- Yaygın (Common): 1.0x
- Uncommon: 1.5x
- Nadir (Rare): 2.5x
- Epic: 5.0x
- Legendary: 10.0x

**Örnek maliyetler (Epic item):**
```
+0 → +1: 5,000 altın
+1 → +2: 7,500 altın
+2 → +3: 11,250 altın
+3 → +4: 16,875 altın
+4 → +5: 25,313 altın
+5 → +6: 37,969 altın
+6 → +7: 75,000 altın
+7 → +8: 250,000 altın
+8 → +9: 1,000,000 altın
+9 → +10: 5,000,000 altın
```

### 4.2 Malzeme Maliyeti

**Gerekli malzemeler:**

| Seviye | Demir | Kristal | Eter Tozu | Özel Malzeme |
|--------|-------|---------|-----------|--------------|
| +0→+3 | 10 | 0 | 0 | - |
| +4→+6 | 50 | 5 | 0 | - |
| +7 | 200 | 50 | 10 | - |
| +8 | 500 | 200 | 50 | Ejderha Pulları (5) |
| +9 | 1000 | 500 | 200 | Ejderha Kalbi (1) |
| +10 | 2000 | 1000 | 500 | Kadim Mühür Parçası (1) |

### 4.3 Para Yakma Analizi

**Ortalama başarı maliyeti (+0→+7):**
```
Beklenen deneme sayısı:
+3→+4: 1.43 deneme (avg)
+4→+5: 1.67 deneme
+5→+6: 2.00 deneme
+6→+7: 2.86 deneme

Toplam ortalama maliyet: ~350K altın
```

**Başarısızlıkta para yakma:**
- Altın maliyeti: %100 kayıp
- Malzeme maliyeti: %100 kayıp
- Rün maliyeti: %100 kayıp
- Item düşme: supply azalır (fiyat artar)
- Item yok olma: supply daha fazla azalır

---

## 5. DEMİRCİ (ANVIL) BİNASI

### 5.1 Demirci Seviyeleri

| Seviye | Üretim Hızı | Max Geliştirme | Ek Özellik | Yükseltme Maliyeti |
|--------|-------------|----------------|------------|-------------------|
| 1 | 100% | +5 | - | Ücretsiz |
| 2 | 110% | +6 | - | 10K altın |
| 3 | 120% | +7 | +1% bonus | 50K altın |
| 4 | 130% | +8 | +2% bonus | 200K altın |
| 5 | 150% | +10 | +3% bonus | 1M altın |

### 5.2 Usta Demirci NPC

**Hizmetler:**
- +5% başarı bonusu (ücretli)
- Hızlı geliştirme (%50 daha hızlı)
- Özel teklifler (event zamanı)

**Maliyet:**
```
base_fee = enhancement_cost × 0.10  // %10 ekstra
```

### 5.3 Geliştirme Süresi

**Süre formülü:**
```
duration = 30 × (1.5 ^ current_level) seconds
```

**Örnek süreler:**
```
+0→+1: 30 saniye
+1→+2: 45 saniye
+2→+3: 67 saniye
+3→+4: 101 saniye (1.7 dk)
+4→+5: 152 saniye (2.5 dk)
+5→+6: 228 saniye (3.8 dk)
+6→+7: 342 saniye (5.7 dk)
+7→+8: 513 saniye (8.5 dk)
+8→+9: 770 saniye (12.8 dk)
+9→+10: 1155 saniye (19.2 dk)
```

**Hızlandırma:**
- Gem ile: `remaining_seconds × 2` gem
- Demirci ustası: süre -%50
- Premium boost: süre -%30 (7 günlük)

---

## 6. UI/UX TASARIMI

### 6.1 Demirci Ekranı

**Bölümler:**
```
┌─────────────────────────────────────┐
│  DEMİRCİ                            │
├─────────────────────────────────────┤
│  [Item Slot]  →  [+7 → +8]          │
│                                     │
│  Başarı Şansı: 20%                  │
│  ├─ Base: 20%                       │
│  ├─ Rün Bonusu: +15%                │
│  └─ Toplam: 35%                     │
│                                     │
│  Rün Slotları:                      │
│  [Usta Rün] [Kısmi Koruma] [Boş]   │
│                                     │
│  Maliyet:                           │
│  ├─ 250,000 altın                   │
│  ├─ 500 Demir                       │
│  ├─ 200 Kristal                     │
│  └─ 5 Ejderha Pulları               │
│                                     │
│  [GELİŞTİR] [İPTAL]                 │
└─────────────────────────────────────┘
```

### 6.2 Animasyon Akışı

**Başarılı geliştirme:**
```
1. Ekran titrer (shake)
2. Kıvılcımlar saçar (particles)
3. Item parlıyor (glow effect)
4. "+8" sayısı büyür ve pırıldar
5. Başarı efekti (confetti)
6. "+8 Efsanevi Kılıç" yazısı
```

**Başarısız geliştirme (düşme):**
```
1. Ekran titrer
2. Kıvılcımlar saçar
3. Kırmızı ışık (red flash)
4. Item düşüyor efekti (fall animation)
5. "+7" sayısı gösteriliyor
6. "Başarısız! +6'ya düştü" mesajı
```

**Near-miss effect:**
```
1-2. Aynı
3. Yeşil ışık (başarı gibi görünür) - 0.3s
4. Aniden kırmızıya döner
5. "ÇOK YAKINDIN!" mesajı
6. Başarısızlık devam eder
```

### 6.3 Bilgilendirme UI

**Risk göstergesi:**
```gdscript
func _update_risk_indicator(level: int):
    match level:
        0, 1, 2, 3:
            risk_label.text = "GÜVENLİ"
            risk_label.modulate = Color.GREEN
        4, 5, 6:
            risk_label.text = "DÜŞÜK RİSK"
            risk_label.modulate = Color.YELLOW
        7:
            risk_label.text = "ORTA RİSK"
            risk_label.modulate = Color.ORANGE
        8:
            risk_label.text = "YÜKSEK RİSK"
            risk_label.modulate = Color.RED
        9, 10:
            risk_label.text = "AŞIRI RİSK!"
            risk_label.modulate = Color.DARK_RED
            risk_label.add_theme_font_size_override("font_size", 24)
```

**Onay dialogu (+7 üstü):**
```gdscript
func _show_high_risk_confirmation(level: int, destruction_chance: float):
    var dialog = ConfirmationDialog.new()
    dialog.dialog_text = (
        "DİKKAT!\n\n" +
        "Bu geliştirme çok riskli!\n" +
        "Başarısızlık durumunda:\n\n" +
        "• %%%d şans item YOK OLUR\n" % (destruction_chance * 100) +
        "• Tüm malzemeler harcanır\n" +
        "• İşlem geri alınamaz\n\n" +
        "Devam etmek istediğinden emin misin?"
    )
    dialog.confirmed.connect(_on_high_risk_confirmed)
    add_child(dialog)
```

---

## 7. SERVER-SIDE IMPLEMENTATION

### 7.1 Enhancement API

**Endpoint:**
```
POST /v1/enhancement/enhance
```

**Request:**
```json
{
  "item_instance_id": "uuid",
  "runes": [
    {"type": "success_rune_master", "instance_id": "uuid"},
    {"type": "protection_rune_partial", "instance_id": "uuid"}
  ],
  "use_master_blacksmith": true
}
```

**Response (Success):**
```json
{
  "success": true,
  "result": "success",
  "data": {
    "item_id": "uuid",
    "old_level": 7,
    "new_level": 8,
    "gold_spent": 250000,
    "materials_spent": {
      "iron": 500,
      "crystal": 200,
      "ether_dust": 50,
      "dragon_scale": 5
    },
    "runes_consumed": ["uuid1", "uuid2"]
  }
}
```

**Response (Failure):**
```json
{
  "success": true,
  "result": "failure_downgrade",
  "data": {
    "item_id": "uuid",
    "old_level": 7,
    "new_level": 6,
    "destruction": false,
    "gold_spent": 250000,
    "materials_spent": {...},
    "runes_consumed": ["uuid1"]
  }
}
```

**Response (Destruction):**
```json
{
  "success": true,
  "result": "destruction",
  "data": {
    "item_id": "uuid",
    "old_level": 8,
    "destruction": true,
    "gold_spent": 1000000,
    "materials_spent": {...},
    "runes_consumed": ["uuid1"]
  }
}
```

### 7.2 Enhancement Logic (Pseudocode)

```typescript
async function enhanceItem(
  playerId: string,
  itemInstanceId: string,
  runes: Rune[],
  useMasterBlacksmith: boolean
): Promise<EnhancementResult> {
  // [1] Validation
  const item = await getItem(itemInstanceId);
  if (item.owner_id !== playerId) {
    throw new Error("Not owner");
  }
  
  const player = await getPlayer(playerId);
  const cost = calculateEnhancementCost(item.level, item.tier);
  
  if (player.gold < cost.gold) {
    throw new Error("Insufficient gold");
  }
  
  // [2] Calculate success chance
  const baseRate = BASE_RATES[item.level];
  let totalBonus = 0;
  
  // Rune bonuses
  for (const rune of runes) {
    totalBonus += RUNE_BONUSES[rune.type];
  }
  
  // Master blacksmith
  if (useMasterBlacksmith) {
    totalBonus += 0.05;
  }
  
  // Guild bonus
  if (player.guild_id) {
    const guild = await getGuild(player.guild_id);
    if (guild.level >= 5) {
      totalBonus += 0.02;
    }
  }
  
  const successChance = clamp(baseRate + totalBonus, 0.01, 0.99);
  
  // [3] RNG (Server-side)
  const roll = Math.random();
  let result: string;
  let newLevel = item.level;
  let destruction = false;
  
  if (roll < successChance) {
    // Success
    result = "success";
    newLevel = item.level + 1;
  } else {
    // Failure
    const downgradeChance = DOWNGRADE_RATES[item.level];
    const destructionChance = DESTRUCTION_RATES[item.level];
    
    // Check protection runes
    const hasProtection = runes.some(r => r.type.includes("protection"));
    
    if (hasProtection) {
      // Protection rune prevents destruction/downgrade
      result = "failure_protected";
      newLevel = item.level; // No change
    } else if (Math.random() < destructionChance) {
      result = "destruction";
      destruction = true;
    } else if (Math.random() < downgradeChance) {
      result = "failure_downgrade";
      newLevel = item.level - 1;
    } else {
      result = "failure";
      newLevel = item.level;
    }
  }
  
  // [4] Database transaction
  await supabase.transaction(async (tx) => {
    // Deduct costs
    await tx.update('players')
      .set({ gold: player.gold - cost.gold })
      .eq('id', playerId);
    
    await tx.update('inventory_materials')
      .set({ quantity: quantity - cost.materials[...] })
      .eq('player_id', playerId);
    
    // Consume runes
    for (const rune of runes) {
      await tx.delete('inventory_items')
        .eq('id', rune.instance_id);
    }
    
    // Update item
    if (destruction) {
      await tx.delete('inventory_items')
        .eq('id', itemInstanceId);
    } else {
      await tx.update('inventory_items')
        .set({ enhancement_level: newLevel })
        .eq('id', itemInstanceId);
    }
    
    // Ledger
    await tx.insert('ledger_entries').values({
      player_id: playerId,
      type: 'enhancement',
      amount: -cost.gold,
      balance_after: player.gold - cost.gold,
      metadata: {
        item_id: itemInstanceId,
        old_level: item.level,
        new_level: newLevel,
        result,
        destruction
      }
    });
  });
  
  // [5] Audit log
  await auditLog('enhancement', {
    player_id: playerId,
    item_id: itemInstanceId,
    old_level: item.level,
    new_level: newLevel,
    success_chance: successChance,
    roll,
    result,
    destruction,
    runes_used: runes.map(r => r.type),
    gold_spent: cost.gold
  });
  
  // [6] Telemetry
  await trackEvent('item_enhanced', {
    player_id: playerId,
    item_tier: item.tier,
    old_level: item.level,
    new_level: newLevel,
    result,
    destruction,
    success_chance: successChance
  });
  
  return {
    success: true,
    result,
    old_level: item.level,
    new_level: newLevel,
    destruction,
    gold_spent: cost.gold,
    materials_spent: cost.materials,
    runes_consumed: runes.map(r => r.instance_id)
  };
}
```

---

## 8. ANTI-ABUSE VE EXPLOIT ÖNLEME

### 8.1 Enhancement Spam
**Limit:**
- Max 100 geliştirme denemesi / gün
- Cooldown: 10 saniye (hızlı spam önleme)

**Tespit:**
```typescript
async function checkEnhancementRateLimit(playerId: string): Promise<boolean> {
  const key = `enhancement_limit:${playerId}`;
  const today = new Date().toISOString().split('T')[0];
  
  const count = await redis.incr(`${key}:${today}`);
  
  if (count === 1) {
    await redis.expire(`${key}:${today}`, 86400); // 24 hours
  }
  
  return count <= 100;
}
```

### 8.2 Rune Duplication
**Önlem:**
- Her rün instance ID benzersiz
- Kullanımda idempotency check
- Transaction içinde consume

```typescript
async function consumeRune(runeInstanceId: string): Promise<void> {
  const result = await supabase
    .from('inventory_items')
    .delete()
    .eq('id', runeInstanceId)
    .eq('consumed', false);
  
  if (result.count === 0) {
    throw new Error("Rune already consumed or not found");
  }
}
```

### 8.3 Success Rate Manipulation
**Önlem:**
- Tüm hesaplama server-side
- Client'a sadece result gönderilir
- RNG seed server'da
- Audit logging (anomali tespiti)

### 8.4 Item Cloning
**Önlem:**
- Item transaction atomic
- Optimistic locking
- Version number kontrolü

```typescript
async function updateItem(itemId: string, newLevel: number, version: number): Promise<void> {
  const result = await supabase
    .from('inventory_items')
    .update({
      enhancement_level: newLevel,
      version: version + 1,
      updated_at: new Date()
    })
    .eq('id', itemId)
    .eq('version', version); // Optimistic lock
  
  if (result.count === 0) {
    throw new Error("Item version mismatch - possible concurrent modification");
  }
}
```

---

## 9. EKONOMİ ENTEGRASYONU

### 9.1 Para Yakma (Gold Sink)

**Geliştirme maliyeti projeksiyonu:**
```
+0 → +7 (ortalama):
  Maliyet: ~350K altın
  Para yakma: ~350K (tüm denemeler)

+7 → +8 (ortalama):
  Başarı için: 2.86 deneme
  Maliyet: 250K × 2.86 = 715K altın
  
+8 → +9 (ortalama):
  Başarı için: 10 deneme
  Maliyet: 1M × 10 = 10M altın
  
+9 → +10 (ortalama):
  Başarı için: 33 deneme
  Maliyet: 5M × 33 = 165M altın
```

**Aylık para yakma (tahmin):**
- 1000 aktif oyuncu
- Ortalama 5-10 geliştirme denemesi / oyuncu / gün
- Günlük yakma: ~10M altın
- Aylık yakma: ~300M altın

### 9.2 Item Supply Kontrolü

**Yok olan item'lar:**
- +8 denemelerinde %40 yok olma
- +9 denemelerinde %60 yok olma
- +10 denemelerinde %97 yok olma

**Supply etkisi:**
- Yüksek seviye item'lar nadir olur
- Market fiyatları artar
- Demand/supply dengesi doğal kalır

### 9.3 Rün Ekonomisi

**Rün fiyat dinamiği:**
- Usta Rün: 50K-200K altın (market)
- Efsanevi Rün: 500K-2M altın
- Tam Koruma Rünü: 1M-5M altın

**Arz kaynakları:**
- Simya üretimi (yavaş)
- Zindan loot (nadir)
- Event (sınırlı)

**Talep:**
- Yüksek seviye geliştirmelerde zorunlu
- Sürekli tüketilir

---

## 10. TELEMETRY VE METRIKLER

### 10.1 Tracked Events

```typescript
// Enhancement attempt
trackEvent('enhancement_attempt', {
  player_id: string,
  item_id: string,
  item_tier: string,
  current_level: number,
  target_level: number,
  success_chance: number,
  runes_used: string[],
  gold_spent: number
});

// Enhancement result
trackEvent('enhancement_result', {
  player_id: string,
  item_id: string,
  result: 'success' | 'failure' | 'downgrade' | 'destruction',
  old_level: number,
  new_level: number,
  roll: number
});

// Rune usage
trackEvent('rune_used', {
  player_id: string,
  rune_type: string,
  enhancement_level: number,
  success: boolean
});
```

### 10.2 KPI'lar

**Başarı oranları:**
- Target: gerçek başarı oranı ≈ teorik oran (±%5)
- Alert: %10'dan fazla sapma

**Para yakma:**
- Target: 300M-500M altın / ay
- Alert: <200M (yetersiz sink)

**Item supply:**
- Target: +8 item'lar <1% toplam item
- Target: +9 item'lar <0.1%
- Target: +10 item'lar <0.01%

**Rün kullanımı:**
- Target: %80+ oyuncu rün kullanıyor
- Target: ortalama 1.5 rün / geliştirme

---

## 11. DEFINITION OF DONE

- [ ] +0→+10 geliştirme akışı çalışıyor
- [ ] Başarı oranları doğru hesaplanıyor
- [ ] Rün sistemi çalışıyor (3 slot)
- [ ] Near-miss animasyonu var
- [ ] High-risk onay dialogu var
- [ ] Server-side RNG doğrulanmış
- [ ] Audit logging aktif
- [ ] Anti-abuse limitleri çalışıyor
- [ ] Para yakma metrikleri izleniyor
- [ ] Item supply kontrol ediliyor

---

Bu döküman, geliştirme/basma sisteminin tam teknik spesifikasyonunu, ekonomi entegrasyonunu ve production-ready implementasyon detaylarını içerir.
