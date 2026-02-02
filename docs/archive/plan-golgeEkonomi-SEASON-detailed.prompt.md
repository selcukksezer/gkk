# Gölge Ekonomi — Sezon & Sıralama Sistemi Detaylı Belge

> Kaynak: plan-golgeEkonomi-part-04.prompt.md (Faza 12)
> Oyun: Gölge Krallık: Kadim Mühür'ün Çöküşü  
> Amaç: Sezon fazları, sıfırlama mekanizması, sıralama kategorileri, ödül sistemi

---

## 1. SEZON SİSTEMİ GENEL BAKIŞ

### 1.1 Tasarım Prensipleri
- **Fresh start:** Her sezon yeni başlangıç
- **Competitive:** Sıralama rekabeti
- **Progression:** Açık ilerleme yolu
- **Retention:** Uzun vadeli bağlılık
- **Economy reset:** Enflasyon kontrolü

### 1.2 Sezon Süresi
```
Sezon süresi: 60-90 gün (beta'da 60, sonra 90)
Faz yapısı: 4 ana faz
Pre-season: 7 gün (hazırlık)
Off-season: 3 gün (geçiş)
```

---

## 2. SEZON FAZLARI

### 2.1 Faz 1: KURULUŞ (Hafta 1-3)

**Özellikler:**
- Temel rekabet başlar
- Leveling yarışı
- İlk loncalar kurulur
- Market stabilize olur

**Oyuncu davranışı:**
```
• Hızlı leveling (günde 4-6 saat)
• Temel ekipman edinme (+0→+5)
• Lonca arama/kurma
• İksir ekonomisi öğrenme
```

**Event'ler:**
```
• "İlk 100" yarışması (level 50'ye ilk ulaşan)
• Çaylak bonusu (+50% XP, 7 gün)
• Hoşgeldin paketi (ücretsiz)
```

**Ekonomi:**
```
Altın supply: Düşük (oyuncular fakir)
İksir fiyatları: Düşük (az talep)
Ekipman fiyatları: Orta (hızlı değişim)
```

### 2.2 Faz 2: REKABET (Hafta 4-8)

**Özellikler:**
- Lonca savaşları başlar
- PvP aktivitesi zirve yapar
- +5/+6 ekipmanlar yaygınlaşır
- İksir talebi artar

**Oyuncu davranışı:**
```
• Günlük görevler rutin
• PvP sıralaması önemli
• Geliştirme (+5→+7 denemeler)
• Lonca bağlılığı artar
```

**Event'ler:**
```
• Haftalık lonca savaşları
• PvP turnuvaları (hafta sonu)
• Özel zindan event (2x loot)
```

**Ekonomi:**
```
Altın supply: Orta-Yüksek
İksir fiyatları: Yükseliyor (tolerance artar)
Ekipman (+7): Çok pahalı (nadir)
```

### 2.3 Faz 3: ZİRVE (Hafta 9-11)

**Özellikler:**
- +8/+9 geliştirme denemeleri
- Legendary item'lar ortaya çıkar
- Sezon finali hazırlığı
- Bağımlılık riski yüksek (dikkat!)

**Oyuncu davranışı:**
```
• Min-max optimize
• Risk alma (+8→+9 push)
• Lonca stratejileri
• Market manipülasyon riski
```

**Event'ler:**
```
• "Son Sprint" (2x XP, son hafta)
• Legendary boss spawn
• Mega lonca savaşı
```

**Ekonomi:**
```
Altın supply: Çok yüksek (enflasyon riski)
İksir fiyatları: PEAK (bağımlılık yaygın)
Rün fiyatları: Astronomik
```

**⚠️ Bağımlılık uyarısı:**
```
Sezon sonu yaklaştıkça oyuncular:
• Daha fazla iksir kullanır (push için)
• Tolerance kritik seviyelere çıkar
• Overdose riski artar (%15→%30)
• Hastane süreler uzar

Game design: Bu kasıtlı! Sezon sonu stresi.
```

### 2.4 Faz 4: FİNAL (Son 3 Gün)

**Özellikler:**
- Sıralama donuyor
- Son savaş: "Kıyamet Günü"
- Ödül dağıtımı
- Sezon özeti

**Kıyamet Savaşı Event:**
```json
{
  "name": "Kıyamet Günü",
  "duration": "24 saat",
  "type": "mega_guild_pvp",
  "description": "Tüm loncalar tek arenada çarpışır",
  "rules": {
    "no_energy_cost": true,
    "no_hospital": true,  // Anında respawn
    "winner_takes_all": true
  },
  "rewards": {
    "winning_guild": "50K💎 (dağıtılır)",
    "participation": "5K💎"
  }
}
```

---

## 3. SEZON SONU SIFIRLANMASI

### 3.1 Sıfırlanan Şeyler

**❌ TAM SIFIRLAMA:**
```
• Altın (0'a döner)
• Envanter (tüm item'lar)
• Ekipman (tüm +seviyeler)
• Seviye/XP (1'e döner)
• Enerji (100'e döner)
• Bağımlılık/Tolerance (0'a döner)
• Binalar (seviye 1'e döner)
• PvP istatistikleri
• Hastane durumu (temizlenir)
```

**⚙️ KISMİ SIFIRLAMA:**
```
• Lonca (kalır ama XP/seviye sıfırlanır)
• Lonca deposu (sıfırlanır)
• Arkadaş listesi (kalır)
• Block listesi (kalır)
• Chat geçmişi (30 gün tutulur, sonra silinir)
```

**✅ KALıCI:**
```
• Gem (hiç sıfırlanmaz)
• Kozmetikler (skin, renk, efekt)
• Unvanlar/Başarımlar (badge)
• Lonca üyeliği (lonca kalıyorsa)
• Chat ban/mute geçmişi (güvenlik)
• Account level (meta progression)
```

### 3.2 Account Level (Meta Progression)

**Kalıcı ilerle me:**
```typescript
interface AccountLevel {
  level: number;              // 1-100
  total_xp: number;           // Tüm sezonlardan kümülatif
  seasons_played: number;
  best_rank: number;          // En iyi sezon sıralaması
  total_gems_earned: number;
}
```

**Account level bonusları:**
```
Level 10: +5% altın başlangıç bonusu (sezon başı)
Level 25: +1 envanter slotu (kalıcı)
Level 50: Özel unvan + kozmetik
Level 75: +10% XP boost (yeni sezonda)
Level 100: Legendary başlık + özel emote
```

### 3.3 Sıfırlama İşlemi (Teknik)

**Timing:**
```
Sezon biter: Pazar 23:59
Sıfırlama: Pazartesi 00:00-03:00 (maintenance)
Yeni sezon: Pazartesi 10:00
```

**Database operations:**
```sql
-- 1. Ödül dağıtımı
INSERT INTO season_rewards 
SELECT player_id, rank, category, reward_gems, reward_items
FROM season_leaderboard
WHERE season_id = CURRENT_SEASON;

-- 2. Kalıcı verileri kaydet
INSERT INTO player_permanent_data
SELECT player_id, account_xp, cosmetics, titles, achievements
FROM players
WHERE season_id = CURRENT_SEASON;

-- 3. Oyuncu verilerini sıfırla
UPDATE players SET
  gold = 0,
  level = 1,
  xp = 0,
  energy = 100,
  tolerance = 0
WHERE season_id = CURRENT_SEASON;

-- 4. Envanteri temizle
DELETE FROM inventory_items
WHERE season_id = CURRENT_SEASON;

-- 5. Binaları sıfırla
UPDATE player_buildings SET
  level = 1,
  production_queue = '[]'
WHERE season_id = CURRENT_SEASON;

-- 6. Yeni sezon başlat
INSERT INTO seasons (id, name, start_date, end_date)
VALUES (NEW_SEASON_ID, 'Sezon 2', NOW(), NOW() + INTERVAL '90 days');

-- 7. Oyuncuları yeni sezona taşı
UPDATE players SET season_id = NEW_SEASON_ID;
```

---

## 4. SIRALAMA KATEGORİLERİ

### 4.1 Net Worth (Servet)

**Hesaplama:**
```typescript
function calculateNetWorth(playerId: string): number {
  const player = getPlayer(playerId);
  
  let netWorth = 0;
  
  // Altın
  netWorth += player.gold;
  
  // Envanter değeri
  for (const item of player.inventory) {
    netWorth += getMarketValue(item);
  }
  
  // Ekipman değeri (enhancement'a göre üssel)
  for (const equipment of player.equipped_items) {
    const baseValue = equipment.base_value;
    const enhancementMultiplier = Math.pow(2, equipment.enhancement_level);
    netWorth += baseValue * enhancementMultiplier;
  }
  
  // Bina değeri
  for (const building of player.buildings) {
    netWorth += building.upgrade_cost_total;
  }
  
  return netWorth;
}
```

**Sıralama ödülleri:**
```
Top 1: 5000💎 + "Altın Kral" unvanı + Efsanevi sandık
Top 2-10: 2000💎 + "Zengin" unvanı + Nadir sandık
Top 11-50: 1000💎 + İyi sandık
Top 51-100: 500💎
```

### 4.2 PvP Şampiyonu

**Hesaplama:**
```typescript
interface PvPScore {
  total_wins: number;
  total_losses: number;
  win_rate: number;
  kill_death_ratio: number;
  highest_streak: number;
}

function calculatePvPRank(score: PvPScore): number {
  return (
    score.total_wins * 10 +
    score.win_rate * 1000 +
    score.highest_streak * 50 +
    score.kill_death_ratio * 100
  );
}
```

**Sıralama ödülleri:**
```
Top 1: 5000💎 + "Savaş Tanrısı" + Özel silah skini
Top 2-10: 2000💎 + "Şövalye" unvanı
Top 11-50: 1000💎 + "Savaşçı" unvanı
```

### 4.3 Görev Ustası

**Hesaplama:**
```typescript
interface QuestScore {
  total_quests_completed: number;
  dungeon_clears: number;
  quest_success_rate: number;
  rare_loot_found: number;
}

function calculateQuestRank(score: QuestScore): number {
  return (
    score.total_quests_completed * 5 +
    score.dungeon_clears * 50 +
    score.quest_success_rate * 500 +
    score.rare_loot_found * 100
  );
}
```

**Sıralama ödülleri:**
```
Top 1: 5000💎 + "Macera Kralı"
Top 2-10: 2000💎 + "Kaşif"
Top 11-50: 1000💎
```

### 4.4 Ekonomi Kralı

**Hesaplama:**
```typescript
interface EconomyScore {
  total_market_trades: number;
  market_volume: number;  // Altın cinsinden
  profit_margin: number;
  successful_arbitrage: number;
}

function calculateEconomyRank(score: EconomyScore): number {
  return (
    score.market_volume * 0.001 +
    score.profit_margin * 10 +
    score.successful_arbitrage * 100
  );
}
```

**Sıralama ödülleri:**
```
Top 1: 5000💎 + "Ticaret Lorduhttps"
Top 2-10: 2000💎 + "Tüccar"
Top 11-50: 1000💎
```

### 4.5 Lonca Lideri

**Hesaplama:**
```typescript
interface GuildScore {
  guild_level: number;
  total_guild_points: number;
  war_victories: number;
  member_count: number;
  average_member_level: number;
}

function calculateGuildRank(score: GuildScore): number {
  return (
    score.guild_level * 1000 +
    score.total_guild_points * 1 +
    score.war_victories * 500 +
    score.member_count * 10 +
    score.average_member_level * 5
  );
}
```

**Sıralama ödülleri (lonca çapında):**
```
Top 1: 20K💎 (dağıtılır) + "Efsane Lonca" + Banner
Top 2-5: 10K💎 + "Güçlü Lonca"
Top 6-10: 5K💎
```

---

## 5. SEZON GEÇİŞİ SÜRECİ

### 5.1 Pre-Season (Hazırlık)

**7 gün önceden:**
```
• Duyuru: "Sezon X, 7 gün sonra başlıyor!"
• Yeni sezon özellikleri tanıtımı
• Önceki sezon leaderboard dondurulur
• Beta testçiler pre-season oynayabilir (optional)
```

### 5.2 Season End (Son Gün)

**Son 24 saat:**
```
• Countdown timer UI'da
• "Son şans!" event'leri
• Sıralama güncelleme durdurulur (freeze)
• Leaderboard son hali kaydedilir
```

### 5.3 Maintenance (Bakım)

**3 saat süre:**
```
00:00 - Sunucular kapanır
00:15 - Database backup
00:30 - Ödül hesaplaması
01:00 - Sıfırlama scripti çalışır
02:00 - Yeni sezon verisi yüklenir
02:30 - Test ve doğrulama
03:00 - Sunucular açılır
```

### 5.4 Season Start (Yeni Sezon)

**İlk gün:**
```
• Hoşgeldin mesajı
• Sezon hedefleri gösterimi
• Başlangıç paketi (ücretsiz)
• "İlk 100" yarışması başlar
```

---

## 6. SEZON BATTLE PASS

### 6.1 İki Track Sistemi

**Free Track (Ücretsiz):**
```
Level 1: 1000 altın
Level 5: Minör iksir x10
Level 10: Kozmetik (basit)
Level 20: 500💎
Level 30: Nadir sandık
Level 50: Unvan "Sezon Veteranı"
```

**Premium Track (800💎):**
```
Level 1: 5000 altın + Free track ödülü
Level 5: Büyük iksir x10 + Free track
Level 10: Özel kozmetik (animasyonlu)
Level 15: Rün (Gelişmiş) x5
Level 20: 1500💎 (gem geri kazanımı)
Level 30: Epic sandık
Level 40: +7 garanti başarı rünü x1
Level 50: Efsanevi silah skini + Unvan
```

### 6.2 XP Kazanımı

**Battle pass XP kaynakları:**
```
Günlük görev: +100 BP XP
Haftalık görev: +500 BP XP
Zindan clear: +50 BP XP
PvP zafer: +25 BP XP
Lonca görevi: +200 BP XP
```

**Level gereksinimleri:**
```
Level 1→2: 100 XP
Level 2→3: 150 XP
Level 3→4: 200 XP
...
Level 49→50: 2000 XP

Toplam: ~50,000 BP XP (60 gün'de makul)
```

### 6.3 Catch-up Mekanizması

**Geç katılan oyuncular:**
```
• Geçmiş seviyelerin görevleri hala yapılabilir
• "Hızlandırılmış XP" (+50% bonus, son 2 hafta)
• Level atlama satın alınabilir (150💎/level, max 10)
```

---

## 7. UI/UX TASARIMI

### 7.1 Sezon Bilgi Ekranı

```
┌─────────────────────────────────────────────┐
│  SEZON 1: KARANLIK AYDINLANMA               │
│  🗓️ Kalan Süre: 45 gün 12 saat            │
├─────────────────────────────────────────────┤
│  ──── MEVCUT FAZINIZ ────                   │
│  📊 REKABET (Hafta 4-8)                     │
│  • Lonca savaşları aktif                    │
│  • PvP turnuvaları başladı                  │
│                                             │
│  ──── SIRALAMAN ────                        │
│  💰 Net Worth: #127 (2.5M altın)           │
│  ⚔️ PvP: #45 (320 zafer)                   │
│  📜 Görev: #89 (450 görev)                  │
│                                             │
│  [DETAYLI SIRALAMA]  [ÖDÜLLER]              │
└─────────────────────────────────────────────┘
```

### 7.2 Leaderboard Ekranı

```
┌─────────────────────────────────────────────┐
│  SIRALAMA: NET WORTH          [Kategori ▼]  │
├─────────────────────────────────────────────┤
│  🥇 1. KaraTanrı - 50M altın               │
│  🥈 2. AteşRuhu - 45M altın                │
│  🥉 3. GölgeKral - 42M altın               │
│  4. BuzKralı - 38M altın                   │
│  5. ŞimşekNinja - 35M altın                │
│  ...                                        │
│  127. Sen - 2.5M altın                     │
│  ...                                        │
│                                             │
│  💎 Ödüller: Top 1-10 gem kazanır!         │
│  [ÖDÜL DETAYLARI]                           │
└─────────────────────────────────────────────┘
```

### 7.3 Sezon Sonu Özeti

```
┌─────────────────────────────────────────────┐
│  🎉 SEZON 1 BİTTİ!                         │
├─────────────────────────────────────────────┤
│  Performansın:                              │
│                                             │
│  💰 Net Worth: #127 → 500💎                │
│  ⚔️ PvP: #45 → 1000💎 + "Savaşçı"          │
│  📜 Görev: #89 → 500💎                      │
│                                             │
│  Toplam Kazanç: 2000💎                      │
│  + "Savaşçı" Unvanı                         │
│  + Nadir Sandık x3                          │
│                                             │
│  Yeni sezon 3 gün sonra başlıyor!           │
│  [DETAYLARI GÖR]  [HAZIRIM!]                │
└─────────────────────────────────────────────┘
```

---

## 8. TELEMETRY VE METRIKLER

### 8.1 Tracked Events
```typescript
trackEvent('season_started', {season_id, player_count});
trackEvent('season_ended', {season_id, top_players});
trackEvent('player_rank_changed', {player_id, category, old_rank, new_rank});
trackEvent('season_reward_claimed', {player_id, category, reward});
```

### 8.2 KPI'lar
- Sezon başı D1 retention: >60%
- Sezon ortası MAU: >50% peak
- Sezon sonu D1: >80% (excitement)
- Battle pass conversion: >15%
- Average playtime increase: +30% final week

---

## 9. DEFINITION OF DONE

- [ ] Sezon döngüsü çalışıyor (başlangıç/bitiş)
- [ ] Sıfırlama scripti test edildi
- [ ] 5 sıralama kategorisi aktif
- [ ] Ödül dağıtımı otomatik
- [ ] Battle pass sistemi çalışıyor
- [ ] UI ekranları hazır
- [ ] Telemetry toplanuyor

---

Bu döküman, sezon sisteminin tam teknik spesifikasyonunu, sıfırlama mekanizmalarını ve production-ready implementasyondetaylarını içerir.
