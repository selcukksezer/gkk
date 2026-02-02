# Gölge Ekonomi — Lonca (Guild) Sistemi Detaylı Belge

> Kaynak: plan-golgeEkonomi-part-04.prompt.md (Faza 11)
> Oyun: Gölge Krallık: Kadim Mühür'ün Çöküşü
> Amaç: Lonca rolleri, depo sistemi, lonca görevleri, lonca savaşları, puan sistemi

---

## 1. LONCA SİSTEMİ GENEL BAKIŞ

### 1.1 Tasarım Prensipleri
- **Sosyal bağlar:** Oyuncular arasında işbirliği
- **Rekabet:** Lonca vs lonca mücadele
- **Ortak hedefler:** Grup görevleri ve bonuslar
- **Hiyerarşi:** Rol sistemi ile yetki dağılımı
- **Ekonomi entegrasyonu:** Lonca deposu ve katkı sistemi

### 1.2 Ortaçağ Teması: "Savaş Lonca"
- Feudal sistemden esinlenilmiş hiyerarşi
- Lord → Komutan → Şövalye → Asker → Çırak
- Lonca kalesi (upgrade edilebilir)
- Lonca banner'ı (kozmetik)
- Bölge kontrolü (territory control)

---

## 2. LONCA KURULUMU VE AYARLARI

### 2.1 Lonca Kurma Gereksinimleri

**Minimum Gereksinimler:**
```
• Level: 20
• Altın: 500,000
• Üye sayısı: 0 (solo kurulum)
• Cooldown: lonca bırakıldıysa 7 gün
```

**İsim kuralları:**
- 3-20 karakter
- Benzersiz (case-insensitive)
- Alfanumerik + boşluk
- Küfür/hakaret yasak

**İlk ayarlar:**
```json
{
  "name": "Kara Şövalyeler",
  "tag": "[KŞ]",  // 2-5 karakter
  "description": "Karanlık güçlerin efendileri",
  "emblem_id": "sword_01",
  "is_public": true,
  "min_level_requirement": 15,
  "language": "tr"
}
```

### 2.2 Lonca Bilgileri

**Profil:**
- İsim, tag, amblem
- Seviye (1-10)
- Üye sayısı (max 50)
- Kuruluş tarihi
- Toplam puan
- Sıralama (sunucu bazlı)

**İstatistikler:**
```json
{
  "total_members": 45,
  "average_level": 35,
  "total_power": 125000,
  "pvp_wins": 320,
  "pvp_losses": 180,
  "quests_completed": 1200,
  "territory_controlled": 3
}
```

---

## 3. ROL VE YETKİ SİSTEMİ

### 3.1 Lonca Rolleri

| Rol | Yetki Seviyesi | Maksimum Sayı | Yetkiler |
|-----|----------------|---------------|----------|
| Lord | 100 | 1 | Tüm yetkiler |
| Komutan | 80 | 3 | Üye yönetimi, depo, savaş |
| Şövalye | 60 | 5 | Üye davet, depo kısıtlı |
| Asker | 40 | 20 | Görev katılımı, chat |
| Çırak | 20 | 21 | Sadece katılım |

### 3.2 Detaylı Yetki Tablosu

| Yetki | Lord | Komutan | Şövalye | Asker | Çırak |
|-------|------|---------|---------|-------|-------|
| Lonca dağıtma | ✓ | ✗ | ✗ | ✗ | ✗ |
| Rol atama | ✓ | ✓ (Şövalye↓) | ✗ | ✗ | ✗ |
| Üye çıkarma | ✓ | ✓ | ✓ (Asker↓) | ✗ | ✗ |
| Üye davet | ✓ | ✓ | ✓ | ✗ | ✗ |
| Depo çekme | ✓ | ✓ | Kısıtlı | ✗ | ✗ |
| Depo yatırma | ✓ | ✓ | ✓ | ✓ | ✓ |
| Savaş başlatma | ✓ | ✓ | ✗ | ✗ | ✗ |
| Ayar değiştirme | ✓ | ✓ | ✗ | ✗ | ✗ |
| Duyuru yapma | ✓ | ✓ | ✓ | ✗ | ✗ |
| Chat yazma | ✓ | ✓ | ✓ | ✓ | ✓ |

### 3.3 Rol Atama Kuralları

**Terfi:**
```typescript
function promoteМember(
  guildId: string,
  promoterId: string,
  targetId: string,
  newRole: GuildRole
): Result {
  const promoter = getGuildMember(guildId, promoterId);
  const target = getGuildMember(guildId, targetId);
  
  // Yetki kontrolü
  if (promoter.role_level <= newRole.level) {
    return { success: false, error: "Insufficient permissions" };
  }
  
  // Rol slot kontrolü
  const roleCount = countMembersWithRole(guildId, newRole);
  if (roleCount >= newRole.max_count) {
    return { success: false, error: "Role slot full" };
  }
  
  // Terfi
  updateMemberRole(guildId, targetId, newRole);
  
  // Log
  logGuildAction({
    guild_id: guildId,
    actor_id: promoterId,
    target_id: targetId,
    action: "promote",
    old_role: target.role,
    new_role: newRole
  });
  
  return { success: true };
}
```

---

## 4. LONCA DEPOSU (TREASURY)

### 4.1 Depo Yapısı

**Kapasitesi:**
```
Lonca Seviye 1: 100 slot
Lonca Seviye 5: 200 slot
Lonca Seviye 10: 500 slot
```

**Depolanabilir itemler:**
- Altın (sınırsız)
- Kaynaklar (demir, kristal, vs.)
- İksirler
- Rün taşları
- Ekipman (sezon sonu için)

**Katkı tracking:**
```json
{
  "player_id": "uuid",
  "player_name": "KaraSavaşçı",
  "contributions": [
    {"type": "gold", "amount": 50000, "timestamp": "2026-01-03T10:00:00Z"},
    {"type": "crystal", "amount": 100, "timestamp": "2026-01-03T11:00:00Z"}
  ],
  "total_value": 75000,  // Altın cinsinden
  "contribution_rank": 3
}
```

### 4.2 Yatırma/Çekme Kuralları

**Yatırma:**
- Tüm üyeler yatırabilir
- Limit yok
- Geri alınamaz (donation)
- Katkı puanı kazanılır

**Çekme:**
```typescript
interface WithdrawalRule {
  role: GuildRole;
  daily_limit: number;
  item_types: string[];
  requires_approval: boolean;
}

const WITHDRAWAL_RULES: WithdrawalRule[] = [
  {
    role: "lord",
    daily_limit: Infinity,
    item_types: ["all"],
    requires_approval: false
  },
  {
    role: "commander",
    daily_limit: 100000,  // Altın değeri
    item_types: ["all"],
    requires_approval: false
  },
  {
    role: "knight",
    daily_limit: 20000,
    item_types: ["potion", "rune"],
    requires_approval: true  // Lord/Komutan onayı
  }
];
```

**Onay sistemi:**
- Şövalye çekim talebi oluşturur
- Lord/Komutan onaylar veya reddeder
- 24 saat içinde onaylanmazsa otomatik iptal

### 4.3 Depo Kullanım Senaryoları

**1. Lonca savaşı hazırlığı:**
```
Lord → Depoya 500K altın yatırır
Lord → Komutanlara çekim yetkisi verir
Komutan → İksir ve rün alır (üyelere dağıtım için)
```

**2. Yeni üye destekleme:**
```
Asker → 10K altın yatırır
Şövalye → Çırak için çekim talebi oluşturur
Lord → Onaylar
Çırak → Temel ekipman alır
```

**3. Katkı yarışması:**
```
Haftalık event: En çok katkı yapan 3 üye ödül kazanır
Ödül: 50K altın + özel unvan
```

---

## 5. LONCA GÖREVLERİ (GROUP QUESTS)

### 5.1 Görev Tipleri

**Haftalık Lonca Görevi:**
```json
{
  "id": "guild_quest_weekly_001",
  "name": "Bölge Temizliği",
  "description": "Kuzey ormanındaki goblin kampını temizleyin",
  "type": "weekly",
  "duration": "7 days",
  "objectives": [
    {"type": "kill_monsters", "target": "goblin", "count": 1000, "current": 0},
    {"type": "collect_items", "target": "goblin_token", "count": 500, "current": 0},
    {"type": "complete_dungeon", "target": "goblin_lair", "count": 10, "current": 0}
  ],
  "rewards": {
    "guild_xp": 5000,
    "guild_gold": 100000,
    "buff": {
      "type": "xp_boost",
      "value": 0.20,
      "duration": 86400  // 24 hours
    }
  }
}
```

**Günlük Lonca Görevi:**
- Daha basit hedefler
- 24 saat süre
- Küçük ödüller

**Özel Event Görevi:**
- Sezon ortası/sonu
- Çok zor hedefler
- Büyük ödüller (legendary item, özel unvan)

### 5.2 Katkı Sistemi

**Bireysel katkı:**
```typescript
interface GuildQuestContribution {
  player_id: string;
  quest_id: string;
  contributions: {
    monster_kills: number;
    items_collected: number;
    dungeons_cleared: number;
  };
  contribution_score: number;
}
```

**Katkı puanı hesaplama:**
```typescript
function calculateContributionScore(contribution: GuildQuestContribution): number {
  return (
    contribution.monster_kills * 1 +
    contribution.items_collected * 5 +
    contribution.dungeons_cleared * 100
  );
}
```

**Katkı lideri:**
- Görev bittiğinde en çok katkı yapan 3 üye ödül alır
- Ödül: 10K altın + özel kozmetik

### 5.3 Buff Sistemi

**Görev başarısında lonca buff:**
```json
{
  "buff_type": "xp_boost",
  "value": 0.20,  // +20% XP
  "duration": 86400,  // 24 saat
  "applies_to": "all_guild_members",
  "expires_at": "2026-01-04T10:00:00Z"
}
```

**Buff tipleri:**
- XP boost: +10-30% XP
- Gold boost: +10-20% altın kazancı
- Drop rate boost: +5-15% loot şansı
- PvP defense: +10% savunma (lonca üyeleri)

---

## 6. LONCA SAVAŞLARI (GUILD WARS)

### 6.1 Savaş Mekanizması

**Turnuva formatı:**
```
Başlangıç: Her Cuma 18:00
Süre: 48 saat (Cuma-Pazar)
Katılım: Otomatik (tüm loncalar)
Hedef: En çok puan toplamak
```

**Puan kaynakları:**
```typescript
interface GuildWarPoints {
  quest_completions: number;     // +10-50 puan/görev
  pvp_victories: number;         // +20-100 puan/zafer
  dungeon_clears: number;        // +50-200 puan/zindan
  market_volume: number;         // +0.1 puan/1K altın (anti-manip)
  territory_control: number;     // +500 puan/bölge/saat
}
```

**Anti-manipulation:**
- Market hacmi cap: günlük max 10K puan
- Aynı zindan tekrarı: diminishing returns (%50 azalma/tekrar)
- PvP farming: aynı loncaya karşı max 3 saldırı/gün

### 6.2 Bölge Kontrolü (Territory Control)

**Bölgeler:**
```json
{
  "territories": [
    {
      "id": "northern_forest",
      "name": "Kuzey Ormanı",
      "controlled_by": "guild_uuid_1",
      "control_since": "2026-01-03T10:00:00Z",
      "bonus": "+10% quest XP in this region",
      "points_per_hour": 100
    },
    {
      "id": "eastern_mines",
      "name": "Doğu Madenleri",
      "controlled_by": "guild_uuid_2",
      "bonus": "+15% mining speed",
      "points_per_hour": 150
    }
  ]
}
```

**Ele geçirme:**
- Lonca üyeleri bölgede aktivite yapar
- En aktif lonca kontrolü ele geçirir
- Kontrol değişimi: 6 saatte bir check

**Savunma:**
- Kontrol eden lonca pasif puan kazanır
- Üyeler bölgede bulunursa bonus puan

### 6.3 Savaş Ödülleri

**Sıralama ödülleri:**
```typescript
interface GuildWarReward {
  rank: number;
  guild_xp: number;
  guild_gold: number;
  gems_distributed: number;  // Üyelere dağıtılır
  title: string;
  emblem: string;
}

const REWARDS: GuildWarReward[] = [
  {
    rank: 1,
    guild_xp: 10000,
    guild_gold: 500000,
    gems_distributed: 20000,  // Üye başına ~400 gem (50 üye)
    title: "Efsane Lonca",
    emblem: "golden_banner"
  },
  {
    rank: 2,
    guild_xp: 7000,
    guild_gold: 300000,
    gems_distributed: 10000,
    title: "Güçlü Lonca",
    emblem: "silver_banner"
  },
  // ... rank 3-10
];
```

**Katılım ödülü:**
- Savaşa katılan tüm üyeler: 1000💎
- Minimum katkı gereksinimi: 100 puan

---

## 7. LONCA SEVİYE VE BONUSLAR

### 7.1 Seviye Sistemi

**XP kaynakları:**
```
Üye görev tamamlama: +50 XP
Üye PvP zaferi: +100 XP
Lonca görevi başarısı: +5000 XP
Lonca savaşı katılımı: +2000 XP
Depo katkısı: +0.1 XP/1K altın
```

**Seviye gereksinimleri:**
```typescript
const LEVEL_REQUIREMENTS = [
  { level: 1, xp: 0 },
  { level: 2, xp: 10000 },
  { level: 3, xp: 30000 },
  { level: 4, xp: 70000 },
  { level: 5, xp: 150000 },
  { level: 6, xp: 300000 },
  { level: 7, xp: 600000 },
  { level: 8, xp: 1200000 },
  { level: 9, xp: 2500000 },
  { level: 10, xp: 5000000 }
];
```

### 7.2 Lonca Bonusları

| Seviye | Üye Kapasitesi | Depo Slotu | Market Komisyon | Lonca Buff |
|--------|----------------|------------|-----------------|------------|
| 1 | 20 | 100 | -0% | - |
| 2 | 25 | 120 | -2% | +5% XP |
| 3 | 30 | 150 | -5% | +5% XP |
| 4 | 35 | 180 | -8% | +10% XP |
| 5 | 40 | 200 | -10% | +10% XP, +5% Altın |
| 6 | 43 | 250 | -12% | +10% XP, +5% Altın |
| 7 | 46 | 300 | -15% | +15% XP, +10% Altın |
| 8 | 48 | 350 | -18% | +15% XP, +10% Altın |
| 9 | 50 | 400 | -20% | +20% XP, +15% Altın |
| 10 | 50 | 500 | -20% | +20% XP, +15% Altın, +5% Drop |

**Market komisyon indirimi:**
- Lonca üyeleri market'te trade yaparken komisyon azalır
- Max indirim: %20 (seviye 10)

---

## 8. UI/UX TASARIMI

### 8.1 Lonca Ana Ekranı

```
┌─────────────────────────────────────────────┐
│  [KŞ] KARA ŞÖVALYELERİ (Seviye 7)          │
├─────────────────────────────────────────────┤
│  Üyeler: 45/46  |  Puan: 125,430  |  #3    │
│                                             │
│  [ÜYE LİSTESİ]  [DEPO]  [GÖREVLER]          │
│  [SAVAŞ]  [AYARLAR]  [LOG]                  │
│                                             │
│  ──── SON AKTİVİTELER ────                  │
│  • KaraSavaşçı PvP kazandı (+100 puan)     │
│  • AteşKılıcı görev tamamladı (+50 XP)      │
│  • Lord 50K altın yatırdı                   │
│                                             │
│  ──── HAFTALIK GÖREV ────                   │
│  Goblin Kampı Temizliği                     │
│  ████████░░ 85% (850/1000 goblin)           │
│  Süre: 2 gün 14 saat                        │
│                                             │
│  ──── AKTİF BUFF ────                       │
│  🔥 +15% XP (12 saat kaldı)                 │
└─────────────────────────────────────────────┘
```

### 8.2 Üye Listesi

```
┌─────────────────────────────────────────────┐
│  ÜYE LİSTESİ (45/46)            [DAVET ET]  │
├─────────────────────────────────────────────┤
│  🔷 LORD                                     │
│  • KaraTanrı (Lv 50) [Online]               │
│                                             │
│  🔹 KOMUTAN (2/3)                           │
│  • AteşRuhu (Lv 48) [Online]                │
│  • BuzSavaşçı (Lv 45) [2 saat önce]         │
│                                             │
│  ⚔️ ŞÖVALYEonline (4/5)                        │
│  • KaraSavaşçı (Lv 42) [Online]             │
│  • GölgeKatil (Lv 40) [5 dk önce]           │
│  ... (2 daha)                               │
│                                             │
│  [Daha fazla...]                            │
└─────────────────────────────────────────────┘
```

### 8.3 Lonca Deposu

```
┌─────────────────────────────────────────────┐
│  LONCA DEPOSU              Kapasite: 180/300│
├─────────────────────────────────────────────┤
│  💰 Altın: 1,250,000                        │
│  ⛏️ Demir: 5,000                            │
│  💎 Kristal: 1,200                          │
│  ⚗️ İksir (Büyük): 150                      │
│  📜 Rün (Usta): 20                          │
│                                             │
│  [YATIR]  [ÇEK]  [KATKI SIRALAMASI]         │
│                                             │
│  ──── EN ÇOK KATKI YAPANLAR ────            │
│  1. KaraTanrı - 350K altın değeri           │
│  2. AteşRuhu - 280K altın değeri            │
│  3. KaraSavaşçı - 175K altın değeri         │
└─────────────────────────────────────────────┘
```

---

## 9. SERVER-SIDE IMPLEMENTATION

### 9.1 Guild Creation API

```
POST /v1/guild/create
Body: {
  "name": "Kara Şövalyeler",
  "tag": "KŞ",
  "description": "...",
  "emblem_id": "sword_01",
  "is_public": true,
  "min_level": 15
}
```

### 9.2 Guild Contribution Tracking

```typescript
async function trackContribution(
  guildId: string,
  playerId: string,
  type: string,
  amount: number
): Promise<void> {
  const value = calculateGoldValue(type, amount);
  
  await supabase
    .from('guild_contributions')
    .insert({
      guild_id: guildId,
      player_id: playerId,
      type,
      amount,
      gold_value: value,
      timestamp: new Date()
    });
  
  // Update player's total contribution
  await supabase.rpc('increment_player_contribution', {
    p_guild_id: guildId,
    p_player_id: playerId,
    p_amount: value
  });
  
  // Telemetry
  await trackEvent('guild_contribution', {
    guild_id: guildId,
    player_id: playerId,
    type,
    amount,
    value
  });
}
```

---

## 10. ANTI-ABUSE VE EXPLOIT ÖNLEME

### 10.1 Guild Hopping
**Önlem:**
- Lonca bırakma cooldown: 24 saat
- Yeni loncaya katılma cooldown: 7 gün
- Savaş zamanı lonca değiştirme yasak

### 10.2 Treasury Abuse
**Önlem:**
- Çekim limitleri (rol bazlı)
- Audit log (tüm işlemler)
- Şüpheli aktivite flag

### 10.3 Point Farming
**Önlem:**
- Diminishing returns
- Market hacmi cap
- PvP saldırı limiti

---

## 11. TELEMETRY VE METRIKLER

### 11.1 KPI'lar
- Aktif lonca oranı: >60%
- Ortalama lonca seviyesi: 4-5
- Lonca savaşı katılımı: >80%
- Depo kullanım oranı: >50%

---

## 12. DEFINITION OF DONE

- [ ] Lonca kurma/katılma çalışıyor
- [ ] Rol sistemi aktif
- [ ] Depo çalışıyor
- [ ] Lonca görevi sistemi aktif
- [ ] Lonca savaşı mekanizması çalışıyor
- [ ] Anti-abuse kuralları aktif

---

Bu döküman, lonca sisteminin tam teknik spesifikasyonunu içerir.
