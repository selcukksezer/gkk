### 🧑‍💻 FAZA 3: SERVER-CLIENT MİMARİSİ (Hafta 11-16)

**1. Mimari Diyagram**
```
CLIENT (Godot 4.x)
├── HTTPRequest (REST API)
├── WebSocketPeer (Real-time)
└── Local Cache (Dictionary)
       ↓
BACKEND (Supabase + Edge Functions)
├── API Gateway
├── PostgreSQL (Ana veri)
├── Redis (Cache)
└── Realtime (WebSocket subscriptions)
```

**2. Authentication Flow**
- JWT tokens (access: 15dk, refresh: 7 gün)
- Device fingerprint + session ID
- Max 3 eşzamanlı cihaz

**3. Real-time vs Request-Response**
| Veri Tipi | Yöntem | Latency |
|-----------|--------|---------|
| Fiyatlar | WebSocket | <1s |
| Chat | WebSocket | <500ms |
| Envanter | REST | 1-3s |
| Görev sonucu | Push notification | Async |
| Enerji güncellemesi | WebSocket | <1s |
| PvP saldırı sonucu | Push notification | Async |

**4. Godot Network Kodu**
- `HTTPRequest` + `WebSocketPeer` hibrit
- Request queue sistemi (offline handling)
- Automatic retry with exponential backoff

---

### 🔐 FAZA 4: GÜVENLİK SİSTEMLERİ (Hafta 17-22)

**1. Server-Side Validation (ZORUNLU)**
- Her işlem için: Auth → Authorization → Input validation → Business rules → Rate limit → Anti-manipulation
- Atomik veritabanı transaction'ları
- Tam audit logging

**2. Client-Side Koruma (Geciktirici)**
- Memory değer şifreleme (XOR + random key)
- APK imza kontrolü
- HTTPS + certificate pinning

**3. API Güvenliği**
- Rate limiting headers
- Request signing (HMAC)
- IP reputation scoring

**4. Session Yönetimi**
- 30 dakika inaktivite timeout
- IP değişikliği soft warning
- Şüpheli aktivite re-auth

**5. Enerji Sistemi Güvenliği**
- Enerji hesaplama sadece server-side
- Her aktivite enerji tüketimi server'da doğrulanır
- İksir kullanımı server-authoritative
- Tolerans hesaplaması server-side
- Overdose RNG server-side

**6. PvP Güvenliği**
- Savaş sonucu server-side RNG
- HP/stat hesaplamaları server-side
- Hastanelik kararı server-side
- Anti-farming: aynı oyuncuya tekrar saldırı limiti

---

### 🎮 FAZA 5: İLK 30 DAKİKA DENEYİMİ (Hafta 23-28)

**1. Dakika Dakika Flow**
| Dakika | Aktivite | Öğretilen Mekanik | Ödül |
|--------|----------|-------------------|------|
| 0-2 | Sinematik (atlanabilir) | - | - |
| 2-5 | İlk görev (%100 başarı) | Tap to action | 500 altın + kılıç |
| 5-8 | İlk ekipman | Envanter | Zırh |
| 8-12 | İkinci görev | Timing/risk | 1,000 altın + XP |
| 12-15 | İlk geliştirme (+1 kılıç) | Anvil sistemi | +10% güç |
| 15-20 | Lonca keşfi | Sosyal sistem | Lonca daveti |
| 20-25 | Pazar tanıtımı | Alım/satım | İlk ticaret |
| 25-30 | **Enerji sistemi tanıtımı** | İksir kullanımı | 5x minör iksir |

**2. Enerji Sistemi Onboarding**
- Dakika 25'te: "Enerjin azaldı!" mesajı
- UI gösterimi: enerji bar
- İlk iksir hediye: 5x minör iksir
- Tooltip: "İksir kullan ama dikkatli ol!"
- Bağımlılık uyarısı (soft)

**3. Hook Points**
- Progress bar'lar (%87 complete göster)
- Daily streak (loss aversion)
- Near-miss animasyonu (upgrade'de)
- Leaderboard teaser
- Enerji dolum bildirimi

**4. Push Notification Stratejisi**
- 2 saat: "Enerji doldu!"
- 4 saat: "Günlük görevler bekliyor!"
- 24 saat: "Günlük ödülün hazır!"
- 3 gün: "Hediye var!"
- 7 gün: "Lonca seni bekliyor!"

---

### ⚡ ENERJİ & İKSİR SİSTEMİ API ENDPOINTLERİ

**1. Enerji Sorgulama**
```
GET /v1/player/energy
Response: {
  current_energy: 75,
  max_energy: 100,
  regen_rate: 1/5min,
  next_regen_at: "2026-01-02T10:15:00Z"
}
```

**2. İksir Kullanımı**
```
POST /v1/player/use-potion
Body: {
  potion_instance_id: "uuid",
  action: "restore_energy"
}
Response: {
  success: true,
  energy_restored: 20,
  new_energy: 95,
  tolerance_increase: 2,
  new_tolerance: 42,
  overdose_risk: false
}
```

**3. Bağımlılık Durumu**
```
GET /v1/player/tolerance
Response: {
  tolerance: 42,
  status: "hafif_tolerans",
  potion_effectiveness: 0.8,
  overdose_risk: 0.0,
  next_decay_at: "2026-01-02T16:00:00Z"
}
```

**4. Tedavi/Antidot**
```
POST /v1/player/treatment
Body: {
  treatment_type: "antidote" | "healer"
}
Response: {
  success: true,
  tolerance_reduced: 30,
  new_tolerance: 12,
  cost: 5000
}
```

---

### 🏥 HASTANELİK SİSTEMİ API

**1. Hastane Durumu**
```
GET /v1/player/hospital-status
Response: {
  in_hospital: true,
  reason: "overdose" | "pvp_defeat" | "dungeon_critical",
  admitted_at: "2026-01-02T10:00:00Z",
  release_at: "2026-01-02T16:00:00Z",
  remaining_minutes: 360
}
```

**2. Erken Çıkış (Gem)**
```
POST /v1/hospital/early-release
Body: {
  method: "gem" | "healer"
}
Response: {
  success: true,
  gem_cost: 1080,
  released_at: "2026-01-02T10:05:00Z"
}
```

**3. Hekim Çağırma**
```
POST /v1/hospital/call-healer
Body: {
  healer_id: "uuid"
}
Response: {
  success: true | false,
  roll: 0.65,
  success_chance: 0.70,
  time_reduced_minutes: 180,
  new_release_at: "2026-01-02T13:00:00Z",
  cost: 2500
}
```

---

### ⚔️ PvP SALDIRI API

**1. Saldırı Başlatma**
```
POST /v1/pvp/attack
Body: {
  target_player_id: "uuid",
  equipped_loadout: {...}
}
Response: {
  attack_id: "uuid",
  energy_cost: 15,
  estimated_power: 1250,
  target_power: 1100,
  win_chance: 0.65
}
```

**2. Saldırı Sonucu**
```
GET /v1/pvp/result/{attack_id}
Response: {
  outcome: "critical_victory" | "victory" | "draw" | "defeat" | "critical_defeat",
  attacker_rewards: {
    gold: 5000,
    xp: 200,
    reputation: 10
  },
  defender_impact: {
    gold_lost: 5000,
    hospitalized: true,
    hospital_duration_minutes: 240
  },
  combat_log: [...]
}
```

**3. Savunma Geçmişi**
```
GET /v1/pvp/defense-log
Response: {
  recent_attacks: [
    {
      attacker_name: "DarkKnight",
      timestamp: "2026-01-02T09:30:00Z",
      outcome: "defeat",
      can_retaliate: true,
      retaliation_expires_at: "2026-01-03T09:30:00Z"
    }
  ]
}
```

**4. Misilleme (Retaliation)**
```
POST /v1/pvp/retaliate
Body: {
  original_attack_id: "uuid"
}
Response: {
  // Saldırı gibi ama enerji bedava
  energy_cost: 0,
  ...
}
```

---

### 📊 TELEMETRY EVENTS

**Enerji & İksir:**
- `energy_depleted` - enerji 0'a düştü
- `potion_used` - iksir kullanıldı
- `tolerance_threshold_crossed` - tolerans eşik aştı
- `overdose_occurred` - overdose oldu
- `treatment_purchased` - tedavi alındı

**PvP:**
- `pvp_attack_initiated`
- `pvp_attack_completed`
- `pvp_hospitalized`
- `pvp_retaliation`

**Hastane:**
- `hospital_admitted`
- `hospital_early_release`
- `hospital_healer_attempt`
- `hospital_natural_release`

---

### 🔒 ANTİ-ABUSE: ENERJİ & PvP

**1. Enerji Manipülasyonu**
- Client'ta enerji değeri asla trust edilmez
- Server her aktivite öncesi enerji check yapar
- Aktivite sonrası enerji düşer
- İksir kullanımı idempotent (aynı token tekrar kullanılamaz)

**2. İksir Abuse**
- Aynı iksir instance ID tekrar kullanılamaz
- Günlük iksir kullanım limiti (200 adet)
- Overdose risk hesaplaması server-side
- Tolerans değeri client'a güvenilmez

**3. PvP Farming**
- Aynı oyuncuya 24 saat içinde max 3 saldırı
- Her saldırıda diminishing returns (ödül azalır)
- Yeni oyuncu koruması (level <10, 7 gün)
- Güvenli bölgeler (şehir merkezi)

**4. Hastane Abuse**
- Erken çıkış gem maliyeti değiştirilemez (server hesaplar)
- Hekim success rate server RNG
- Başarısız hekim çağrısı süreyi artırır

---

### 💾 VERİ MODELİ GÜNCELLEMELERİ

**player_energy**
```sql
CREATE TABLE player_energy (
  player_id UUID PRIMARY KEY,
  current_energy INTEGER NOT NULL DEFAULT 100,
  max_energy INTEGER NOT NULL DEFAULT 100,
  last_update TIMESTAMP NOT NULL,
  daily_energy_used INTEGER DEFAULT 0,
  last_daily_reset TIMESTAMP
);
```

**player_hospital**
```sql
CREATE TABLE player_hospital (
  player_id UUID PRIMARY KEY,
  in_hospital BOOLEAN DEFAULT FALSE,
  reason TEXT,
  admitted_at TIMESTAMP,
  release_at TIMESTAMP,
  healer_attempts INTEGER DEFAULT 0,
  early_release_count INTEGER DEFAULT 0
);
```

**pvp_attacks**
```sql
CREATE TABLE pvp_attacks (
  id UUID PRIMARY KEY,
  attacker_id UUID NOT NULL,
  defender_id UUID NOT NULL,
  outcome TEXT NOT NULL,
  attacker_power INTEGER,
  defender_power INTEGER,
  rewards JSONB,
  combat_log JSONB,
  timestamp TIMESTAMP NOT NULL,
  is_retaliation BOOLEAN DEFAULT FALSE
);
```

**pvp_restrictions**
```sql
CREATE TABLE pvp_restrictions (
  player_id UUID NOT NULL,
  target_id UUID NOT NULL,
  attack_count INTEGER DEFAULT 0,
  last_attack TIMESTAMP,
  retaliation_available BOOLEAN DEFAULT FALSE,
  retaliation_expires_at TIMESTAMP,
  PRIMARY KEY (player_id, target_id)
);
```
