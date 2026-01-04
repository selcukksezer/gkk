# Gölge Ekonomi — PvP & Hastanelik Sistemi (Detaylı Belge)

> Oyun: Gölge Krallık: Kadim Mühür'ün Çöküşü
> Amaç: Oyuncu vs Oyuncu saldırı, savaş mekanizması, hastanelik ve anti-abuse sisteminin teknik detayları

---

## 1. PvP SALDIRI MEKANİZMASI

### 1.1 Saldırı Koşulları
**Temel gereksinimler:**
- Saldırgan minimum level 10
- Hedef oyuncu online değilse saldırı yapılamaz (MVP)
- Aynı bölgede olma (şehir/harita)
- Güvenli bölge dışında

**Enerji maliyeti:**
- Normal saldırı: 15 enerji
- Misilleme saldırısı: 0 enerji (bedava)

### 1.2 Saldırı Kısıtlamaları
**Aynı hedefe saldırı limiti:**
- 24 saat içinde max 3 saldırı
- Her saldırıda diminishing returns:
  - 1. saldırı: %100 ödül
  - 2. saldırı: %50 ödül
  - 3. saldırı: %25 ödül
  - 4. saldırı: engellenir

**Cooldown:**
- Genel saldırı cooldown: 30 dakika
- Aynı hedefe cooldown: 2 saat

**Korunan oyuncular:**
- Yeni oyuncu (<7 gün veya <level 10)
- Hastanedeki oyuncu
- Shield item kullanan oyuncu (24h immunity)
- Güvenli bölgedeki oyuncu

### 1.3 Güvenli ve Tehlikeli Bölgeler
**Güvenli bölgeler (PvP yok):**
- Şehir merkezi
- Pazar meydanı
- Lonca evi

**Kısmi güvenli (kısıtlı PvP):**
- Şehir dışı (cooldown 2x)
- Köy

**Tehlikeli bölgeler (serbest PvP):**
- Vahşi alanlar
- Zindan girişleri
- Kaynak toplama alanları

---

## 2. GÜÇ HESAPLAMA SİSTEMİ

### 2.1 Savaş Gücü Formülü
```
Combat Power = (
  Base Stats (level × 10) +
  Weapon Power (0-500) +
  Armor Defense (0-300) +
  Skill Bonuses (0-200) +
  Enchantments (0-150) +
  Buff Effects (0-100)
) × Random Multiplier (0.85-1.15)
```

**Örnek hesaplama:**
```python
def calculate_combat_power(player):
    base = player.level * 10
    weapon = sum([item.power for item in player.equipped_weapons])
    armor = sum([item.defense for item in player.equipped_armor])
    skills = sum([skill.bonus for skill in player.active_skills])
    enchantments = sum([ench.value for ench in player.enchantments])
    buffs = sum([buff.value for buff in player.active_buffs])
    
    total = base + weapon + armor + skills + enchantments + buffs
    
    # Random factor for unpredictability
    multiplier = random.uniform(0.85, 1.15)
    
    return int(total * multiplier)
```

### 2.2 Kazanma Olasılığı
```python
def calculate_win_chance(attacker_power, defender_power):
    if defender_power == 0:
        return 0.85  # Max chance
    
    power_ratio = attacker_power / defender_power
    
    # Logarithmic scaling for balance
    base_chance = 0.5 + 0.3 * math.log(power_ratio)
    
    # Clamp between 15% and 85%
    win_chance = max(0.15, min(0.85, base_chance))
    
    return win_chance
```

**Olasılık dağılımı örnekleri:**
| Güç Oranı | Kazanma Şansı |
|-----------|---------------|
| 0.5x (yarı güç) | ~30% |
| 0.75x | ~42% |
| 1.0x (eşit) | ~50% |
| 1.25x | ~57% |
| 1.5x | ~62% |
| 2.0x (çift güç) | ~69% |
| 3.0x | ~76% |
| 5.0x | ~82% |
| 10.0x | ~85% (cap) |

---

## 3. SAVAŞ SONUÇLARI

### 3.1 Sonuç Tipleri
Savaş sonucu RNG ile belirlenir:
1. Kazanma şansı hesaplanır
2. Rastgele sayı üretilir (0-1)
3. Eğer sayı < kazanma_şansı → Saldırgan kazanır
4. Kritik zafer/yenilgi için ekstra roll

### 3.2 Sonuç Tablosu
| Sonuç | Koşul | Saldırgan | Savunan |
|-------|-------|-----------|----------|
| **Kritik Zafer** | Win + roll <10% | +150% ödül + ün | HASTANELİK (4-8h) |
| **Zafer** | Win | +100% ödül | -Altın, -XP |
| **Beraberlik** | %5 şans (her durumda) | - | - |
| **Yenilgi** | Lose | -XP | +XP, +ün |
| **Kritik Yenilgi** | Lose + roll <10% | HASTANELİK (2-4h) | +150% ödül + ün |

### 3.3 Ödül Hesaplama
```python
def calculate_rewards(winner_level, loser_level, loser_gold, outcome):
    # Base reward
    base_reward = loser_level * 100
    
    # Gold steal (max 20% of defender gold)
    gold_steal = min(loser_gold * 0.20, loser_gold)
    
    # XP reward
    xp_reward = loser_level * 5
    
    # Reputation change
    reputation_change = 10 if outcome == "victory" else 5
    
    # Multiplier by outcome
    multipliers = {
        "critical_victory": 1.5,
        "victory": 1.0,
        "defeat": 0.0,
        "critical_defeat": 0.0
    }
    
    multiplier = multipliers.get(outcome, 1.0)
    
    return {
        "gold": int((base_reward + gold_steal) * multiplier),
        "xp": int(xp_reward * multiplier),
        "reputation": reputation_change if multiplier > 0 else -10
    }
```

### 3.4 Hastanelik Koşulları
**Kritik zafer karşısında (savunan):**
- Otomatik hastanelik
- Süre: 4-8 saat (rastgele)
- Sebep: "pvp_critical_defeat"

**Kritik yenilgi (saldırgan):**
- Otomatik hastanelik
- Süre: 2-4 saat (rastgele)
- Sebep: "pvp_critical_defeat"

---

## 4. MİSİLLEME SİSTEMİ

### 4.1 Misilleme Hakkı
**Koşullar:**
- Son 24 saat içinde saldırıya uğramış olmalı
- Sadece 1 kez misilleme yapılabilir (per saldırı)
- Enerji bedava (0 maliyet)
- Güç hesaplaması normal

**Süre sınırı:**
- 24 saat içinde kullanılmalı
- Süresi dolunca hak kaybolur

### 4.2 Misilleme API
```
POST /v1/pvp/retaliate
Body: {
  original_attack_id: "uuid"
}
Response: {
  attack_id: "uuid",
  energy_cost: 0,
  retaliation: true,
  win_chance: 0.45
}
```

---

## 5. ÜN (REPUTATION) SİSTEMİ

### 5.1 Ün Mekanizması
**Ün değeri:** -500 to +500

**Ün değişimi:**
| Aksiyon | Ün Değişimi |
|---------|-------------|
| Saldırı yap | -10 |
| Saldırı kazan | +0 (ün kaybı devam eder) |
| Savunma kazan | +5 |
| Görev tamamla | +2 |
| Yardım et (quest) | +5 |
| Lonca yardımı | +3 |

### 5.2 Ün Seviyeleri ve Etkileri
| Ün Aralığı | Durum | Etiket | Efektler |
|------------|-------|--------|----------|
| 200-500 | Kahraman | 🌟 Kahraman | Tüccar -%10, özel questler |
| 100-199 | İyi | ✅ İyi | Tüccar -%5 |
| 0-99 | Nötr | - | Normal |
| -99 to -1 | Şüpheli | ⚠️ Şüpheli | Muhafız dikkat eder |
| -100 to -199 | Kötü | ❌ Kötü | Tüccar +%10 |
| -200 to -500 | Haydut | ☠️ Haydut | Herkese açık hedef, muhafız saldırır |

### 5.3 Haydut (Red Player) Mekanizması
**-200 ve altı:**
- İsim kırmızı renkte
- Herkes saldırabilir (koruma yok)
- Şehir muhafızları otomatik saldırır
- Tüccar fiyatları +%20
- Market komisyonu +%10
- Güvenli bölgelere giremez

**Ünü düzeltme:**
- Görevler yap
- PvP'den uzak dur (doğal iyileşme: +1/gün)
- "Af" quest zinciri (pahalı, uzun)

---

## 6. HASTANELİK SİSTEMİ (PvP KAYNAĞI)

### 6.1 PvP Hastanelik Süreleri
| Sebep | Süre |
|-------|------|
| Kritik yenilgi (saldırgan) | 2-4 saat |
| Kritik zafer karşısında (savunan) | 4-8 saat |

### 6.2 Hastaneden Çıkış (PvP için aynı)
Genel hastane sistemi ile aynı:
1. Süre bekle (ücretsiz)
2. Gem harca (dakika × 3)
3. Hekim çağır (%30-70 başarı)
4. Lonca yardımı (-%20 süre)

### 6.3 PvP Hastane İstatistikleri
Telemetry:
- PvP kaynaklı hastanelik oranı
- Ortalama hastane süresi (PvP)
- Erken çıkış metod dağılımı
- Tekrar saldırıya uğrama oranı

---

## 7. ANTİ-ABUSE & EXPLOIT ÖNLEME

### 7.1 PvP Farming Önleme
**Aynı hedefe spam:**
- 24h içinde max 3 saldırı
- Diminishing returns aktif
- 4. saldırı engellenir

**İki hesap farming:**
- IP/device overlap tespiti
- Aynı iki oyuncu tekrar eden saldırılar → risk flag
- Pattern: A→B, B→A, tekrar → security event
- Ödül azalır (diminishing)

### 7.2 Stat Manipulation
**Güç hesaplama:**
- Her zaman server-side
- Client'a güvenilmez
- Ekipman değişimi server'da doğrulanır
- Buff/skill aktifliği server'da kontrol edilir

### 7.3 Win Trading
**Tespit:**
- Aynı iki oyuncu yüksek frekanslı savaş
- Her iki taraf da kazanıyor (sırayla)
- Ödül akışı dengeli

**Aksiyon:**
- Ödül azaltılır
- Risk flag
- Manual review

### 7.4 Yeni Oyuncu Abuse
**Koruma:**
- İlk 7 gün veya level <10 saldırıya uğramaz
- Sistem otomatik saldırı engeller
- High-level oyuncu low-level'a saldıramaz (level farkı >20)

---

## 8. PvP TELEMETRİ & ANALYTİCS

### 8.1 Kritik Metrikler
**Aktivite:**
- Günlük PvP saldırı sayısı
- Aktif PvP oyuncu oranı
- Ortalama saldırı/oyuncu

**Denge:**
- Ortalama güç farkı (saldırgan/savunan)
- Kazanma oranı dağılımı
- Kritik sonuç oranları
- Level matchup dağılımı

**Ekonomi:**
- PvP'den dolaşan altın
- Ortalama ödül/saldırı
- Hastane maliyeti (gem/hekim)

**Ün:**
- Ün dağılımı (histogram)
- Haydut oyuncu oranı (<-200)
- Ortalama ün

### 8.2 Dashboard Alarmları
- PvP aktivite < 10% aktif oyuncu → düşük
- Ortalama win rate > 70% → dengesiz matchmaking
- Haydut oranı > 15% → ün sistemi çok sert
- Hastanelik oranı (PvP) > 20% → çok brutal

### 8.3 Balance Metrikleri
**Hedef değerler:**
- Eşit güçte kazanma oranı: ~50%
- 2x güçte kazanma oranı: ~70%
- Kritik sonuç oranı: ~10%
- Günlük PvP aktivite: %30-50 oyuncular

---

## 9. API ENDPOINTLERİ

### 9.1 Saldırı Başlatma
```
POST /v1/pvp/attack
Body: {
  target_player_id: "uuid",
  equipped_loadout: {...}
}
Response: {
  attack_id: "uuid",
  energy_cost: 15,
  attacker_power: 1250,
  defender_power: 1100,
  win_chance: 0.65,
  can_retaliate: false
}
```

### 9.2 Saldırı Sonucu
```
GET /v1/pvp/result/{attack_id}
Response: {
  outcome: "critical_victory" | "victory" | "draw" | "defeat" | "critical_defeat",
  attacker: {
    power: 1250,
    rewards: {
      gold: 5000,
      xp: 200,
      reputation: 10
    },
    hospitalized: false
  },
  defender: {
    power: 1100,
    losses: {
      gold: 5000,
      xp: 0
    },
    hospitalized: true,
    hospital_duration_minutes: 360
  },
  combat_log: [
    {"action": "attack", "damage": 150, "attacker": true},
    {"action": "counter", "damage": 120, "attacker": false},
    ...
  ]
}
```

### 9.3 Savunma Geçmişi
```
GET /v1/pvp/defense-log
Response: {
  recent_attacks: [
    {
      id: "uuid",
      attacker_id: "uuid",
      attacker_name: "DarkKnight",
      timestamp: "2026-01-02T09:30:00Z",
      outcome: "defeat",
      losses: {gold: 2000},
      can_retaliate: true,
      retaliation_expires_at: "2026-01-03T09:30:00Z"
    }
  ],
  total_attacks_today: 3,
  win_rate: 0.40
}
```

### 9.4 Ün Sorgulama
```
GET /v1/player/reputation
Response: {
  reputation: -150,
  status: "bad",
  label: "❌ Kötü",
  effects: {
    merchant_price_modifier: 1.10,
    market_commission_modifier: 1.05,
    can_enter_safe_zones: true,
    guard_aggro: "medium"
  }
}
```

---

## 10. UX/UI DETAYLARI

### 10.1 Saldırı Onay Ekranı
**Gösterilen bilgiler:**
- Hedef oyuncu adı + seviye
- Tahmini güç farkı (bar gösterimi)
- Kazanma şansı (~%65)
- Enerji maliyeti
- Olası ödül aralığı
- Risk uyarısı (kritik yenilgi → hastane)

**Onay butonu:**
- "Saldır" (yeşil, kazanma >50%)
- "Riskli Saldır" (kırmızı, kazanma <50%)

### 10.2 Savaş Animasyonu
**Minimum animasyon (MVP):**
- İki karakter sprite
- Atak animasyonları (3-5 saniye)
- HP bar azalma
- Sonuç ekranı

**Gelişmiş (post-MVP):**
- Skill efektleri
- Critical hit animasyonu
- Combo zinciri
- Arka plan müzik

### 10.3 Savunma Bildirimi
**Push notification:**
- "DarkKnight sana saldırdı!"
- Sonuç özeti (kazan/kaybet)
- Misilleme hakkı varsa vurgu

**In-game notification:**
- Pop-up (oyuncu online ise)
- Chat mesajı
- Savunma log'a ekleme

### 10.4 Haydut UI
**Kırmızı oyuncu için:**
- İsim kırmızı renk
- Özel icon (☠️)
- Uyarı: "Bu oyuncu herkese açık hedef!"
- Saldırı maliyeti %50 daha ucuz (teşvik)

---

## 11. OPERASYON PLAYBOOK

### Durum 1: PvP Dengesizliği
**Belirti:** Top 10 oyuncu %85+ win rate

**Aksiyon:**
1. Güç hesaplama formülünü review
2. Level-based matchmaking değerlendir
3. Yeni oyuncu korumasını uzat (14 gün)
4. Shield item drop rate artır

### Durum 2: Düşük PvP Aktivitesi
**Belirti:** Günlük PvP < %10 oyuncular

**Aksiyon:**
1. Event: "PvP Turnuvası" (ödül bonusu)
2. Günlük quest: "1 PvP zafer kazan"
3. Enerji maliyeti geçici düşür (10 → 5)
4. Ödül bonusu (+%50, 72 saat)

### Durum 3: Yüksek Haydut Oranı
**Belirti:** %20+ oyuncular ün <-200

**Aksiyon:**
1. Ün sistemi yumuşat (saldırı cezası -10 → -5)
2. "Af" quest kolaylaştır
3. Doğal ün iyileşme hızını artır (+2/gün)
4. Awareness: "Ün sistemi nasıl çalışır?"

---

## 12. DEFINITION OF DONE

- [ ] PvP saldırı akışı çalışıyor (start → resolve)
- [ ] Güç hesaplama doğru
- [ ] Kazanma olasılığı dengeli
- [ ] Sonuç tipleri doğru dağılıyor
- [ ] Ödül hesaplama doğru
- [ ] Hastanelik (PvP) çalışıyor
- [ ] Misilleme sistemi çalışıyor
- [ ] Ün sistemi çalışıyor
- [ ] Anti-abuse limitleri aktif
- [ ] Telemetri kaydediliyor
- [ ] UI/UX feedbackler net
- [ ] Push notifications çalışıyor

---

**Son Güncelleme:** 2 Ocak 2026  
**Versiyon:** 2.0 (PvP & Hastanelik Sistemi)
