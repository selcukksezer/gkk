# Gölge Ekonomi — API Reference Documentation

> Kaynak: Tüm sistemler için endpoint tanımları
> Oyun: Gölge Krallık: Kadim Mühür'ün Çöküşü
> Amaç: Standart API dökümanı (OpenAPI 3.0 spec)

---

## 1. API GENEL BAKIŞ

### 1.1 Base URL

**Production:**
```
https://your-project.supabase.co/functions/v1
```

**Staging:**
```
https://your-project-staging.supabase.co/functions/v1
```

### 1.2 Authentication

**JWT Token (Bearer):**
```http
Authorization: Bearer <jwt_token>
```

**Token alma:**
```typescript
// Supabase client
const { data, error } = await supabase.auth.signInWithPassword({
  email: "user@example.com",
  password: "password123"
});

const jwt_token = data.session.access_token;
```

### 1.3 Rate Limiting

**Limitler:**
```
Tier 1 (Free): 60 req/min
Tier 2 (Paid): 300 req/min
Tier 3 (Premium): 1000 req/min
```

**Headers:**
```http
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1735891200
```

### 1.4 Error Format

**Standard error response:**
```json
{
  "error": {
    "code": "INSUFFICIENT_GOLD",
    "message": "Yeterli altın yok",
    "details": {
      "required": 5000,
      "current": 2000
    }
  },
  "timestamp": "2026-01-03T10:30:00Z",
  "request_id": "uuid"
}
```

**Error codes:**
```
400 BAD_REQUEST - Geçersiz input
401 UNAUTHORIZED - Auth gerekli
403 FORBIDDEN - Yetkisiz işlem
404 NOT_FOUND - Kayıt bulunamadı
409 CONFLICT - Çakışma (duplicate)
429 RATE_LIMIT_EXCEEDED - Rate limit aşıldı
500 INTERNAL_SERVER_ERROR - Server hatası
503 SERVICE_UNAVAILABLE - Bakım modu
```

---

## 2. AUTH ENDPOINTS

### 2.1 POST /auth/register

**Yeni kullanıcı kaydı**

**Request:**
```json
{
  "email": "user@example.com",
  "username": "shadowknight",
  "password": "SecurePass123!",
  "referral_code": "ABC123"  // optional
}
```

**Response (201 Created):**
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "username": "shadowknight",
    "level": 1,
    "gold": 1000,
    "gems": 100,
    "created_at": "2026-01-03T10:30:00Z"
  },
  "session": {
    "access_token": "jwt...",
    "refresh_token": "jwt...",
    "expires_at": "2026-01-03T22:30:00Z"
  }
}
```

**Errors:**
```
409 USERNAME_TAKEN
409 EMAIL_TAKEN
400 INVALID_PASSWORD (min 8 char, uppercase, number)
400 INVALID_USERNAME (3-20 char, alphanumeric)
```

### 2.2 POST /auth/login

**Kullanıcı girişi**

**Request:**
```json
{
  "username": "shadowknight",
  "password": "SecurePass123!"
}
```

**Response (200 OK):**
```json
{
  "user": {
    "id": "uuid",
    "username": "shadowknight",
    "level": 5,
    "gold": 25000,
    "gems": 350,
    "energy": 80,
    "max_energy": 100,
    "hospital_until": null,
    "last_login": "2026-01-02T15:00:00Z"
  },
  "session": {
    "access_token": "jwt...",
    "refresh_token": "jwt...",
    "expires_at": "2026-01-03T22:30:00Z"
  }
}
```

**Errors:**
```
401 INVALID_CREDENTIALS
403 ACCOUNT_BANNED
429 TOO_MANY_ATTEMPTS (5 failed login → 15 min cooldown)
```

### 2.3 POST /auth/logout

**Oturum kapatma**

**Request:**
```json
{}
```

**Response (200 OK):**
```json
{
  "message": "Logout successful"
}
```

---

## 3. USER ENDPOINTS

### 3.1 GET /user/profile

**Kullanıcı profilini getir**

**Response (200 OK):**
```json
{
  "id": "uuid",
  "username": "shadowknight",
  "display_name": "Shadow Knight",
  "title": "Zindanların Efendisi",
  "level": 12,
  "xp": 45000,
  "next_level_xp": 50000,
  "gold": 125000,
  "gems": 850,
  "energy": 75,
  "max_energy": 100,
  "hospital_until": null,
  "pvp_rating": 1250,
  "pvp_wins": 34,
  "pvp_losses": 12,
  "guild": {
    "id": "uuid",
    "name": "Karanlık Şövalyeler",
    "tag": "DK",
    "role": "officer"
  },
  "account_level": 3,
  "created_at": "2025-12-01T10:00:00Z",
  "last_login": "2026-01-03T09:30:00Z"
}
```

### 3.2 PATCH /user/profile

**Profil güncelle (sadece kosmetik alanlar)**

**Request:**
```json
{
  "display_name": "Shadow Knight II",
  "bio": "Veteran player since Season 1",
  "avatar_url": "https://..."
}
```

**Response (200 OK):**
```json
{
  "message": "Profile updated",
  "user": { ... }
}
```

**Errors:**
```
400 INVALID_DISPLAY_NAME (max 30 char)
400 INVALID_BIO (max 200 char)
```

### 3.3 GET /user/inventory

**Envanter listesi**

**Query params:**
```
?category=weapon (optional: weapon|armor|consumable|material|rune)
?equipped=true (optional: sadece equipped itemler)
?page=1
?limit=50
```

**Response (200 OK):**
```json
{
  "items": [
    {
      "id": "uuid",
      "item_id": "sword_epic_001",
      "name": "Legendary Blade",
      "category": "weapon",
      "rarity": "epic",
      "power": 250,
      "enhancement_level": 3,
      "equipped_slot": "weapon",
      "bound": false,
      "acquired_at": "2026-01-01T12:00:00Z",
      "acquired_from": "dungeon"
    },
    // ...
  ],
  "pagination": {
    "page": 1,
    "limit": 50,
    "total": 142,
    "has_next": true
  }
}
```

### 3.4 POST /user/equip

**Item ekipler**

**Request:**
```json
{
  "inventory_item_id": "uuid",
  "slot": "weapon"  // weapon|helmet|chest|legs|boots
}
```

**Response (200 OK):**
```json
{
  "message": "Item equipped",
  "previous_item_id": "uuid_or_null",
  "new_power": 1250
}
```

**Errors:**
```
404 ITEM_NOT_FOUND
400 INVALID_SLOT (helmet için weapon item)
403 ITEM_BOUND (başka karakter bound)
```

---

## 4. QUEST ENDPOINTS

### 4.1 GET /quests/available

**Mevcut görevler**

**Query params:**
```
?type=daily (optional: daily|weekly|story|guild)
```

**Response (200 OK):**
```json
{
  "quests": [
    {
      "id": "quest_daily_001",
      "name": "Günlük Av",
      "description": "10 düşman yenilmeli",
      "type": "daily",
      "difficulty": "normal",
      "requirements": {
        "min_level": 3,
        "energy_cost": 20
      },
      "rewards": {
        "gold": 2000,
        "xp": 500,
        "items": [
          {"item_id": "potion_medium", "quantity": 3}
        ]
      },
      "duration_minutes": 30,
      "progress": {
        "current": 7,
        "required": 10
      },
      "expires_at": "2026-01-04T00:00:00Z"
    }
  ]
}
```

### 4.2 POST /quests/start

**Görevi başlat**

**Request:**
```json
{
  "quest_id": "quest_daily_001"
}
```

**Response (200 OK):**
```json
{
  "message": "Quest started",
  "quest": {
    "id": "uuid",
    "quest_id": "quest_daily_001",
    "status": "in_progress",
    "started_at": "2026-01-03T10:45:00Z",
    "complete_at": "2026-01-03T11:15:00Z"
  },
  "user": {
    "energy": 60  // 80 - 20
  }
}
```

**Errors:**
```
400 INSUFFICIENT_ENERGY
400 QUEST_ALREADY_STARTED
403 LEVEL_REQUIREMENT_NOT_MET
```

### 4.3 POST /quests/complete

**Görevi tamamla (otomatik)**

**Request:**
```json
{
  "user_quest_id": "uuid"
}
```

**Response (200 OK):**
```json
{
  "message": "Quest completed",
  "rewards": {
    "gold": 2000,
    "xp": 500,
    "items": [
      {"item_id": "potion_medium", "quantity": 3}
    ],
    "level_up": false
  },
  "user": {
    "gold": 27000,
    "xp": 45500,
    "level": 12
  }
}
```

---

## 5. MARKET ENDPOINTS

### 5.1 GET /market/orders

**Market emirlerini listele**

**Query params:**
```
?item_id=sword_epic_001 (required)
?type=buy (optional: buy|sell|all, default: all)
?status=active (optional, default: active)
?limit=20
```

**Response (200 OK):**
```json
{
  "buy_orders": [
    {
      "id": "uuid",
      "user_id": "uuid",
      "username": "buyer123",
      "quantity": 1,
      "price_per_unit": 8500,
      "total_price": 8500,
      "remaining_quantity": 1,
      "created_at": "2026-01-03T09:00:00Z",
      "expires_at": "2026-01-10T09:00:00Z"
    }
  ],
  "sell_orders": [
    {
      "id": "uuid",
      "user_id": "uuid",
      "username": "seller456",
      "quantity": 2,
      "price_per_unit": 9000,
      "total_price": 18000,
      "remaining_quantity": 1,
      "created_at": "2026-01-03T08:30:00Z",
      "expires_at": "2026-01-10T08:30:00Z"
    }
  ],
  "market_stats": {
    "lowest_sell": 9000,
    "highest_buy": 8500,
    "last_trade_price": 8800,
    "24h_volume": 45,
    "24h_avg_price": 8750
  }
}
```

### 5.2 POST /market/place_order

**Emir ver**

**Request:**
```json
{
  "item_id": "sword_epic_001",
  "order_type": "buy",  // buy|sell
  "quantity": 1,
  "price_per_unit": 8500
}
```

**Response (201 Created):**
```json
{
  "message": "Order placed successfully",
  "order": {
    "id": "uuid",
    "item_id": "sword_epic_001",
    "order_type": "buy",
    "quantity": 1,
    "price_per_unit": 8500,
    "total_price": 8500,
    "status": "active",
    "created_at": "2026-01-03T10:50:00Z",
    "expires_at": "2026-01-10T10:50:00Z"
  },
  "user": {
    "gold": 18500  // 27000 - 8500 (escrow)
  },
  "matched": false  // Hemen match olduysa true
}
```

**Errors:**
```
400 INSUFFICIENT_GOLD (alım için)
400 ITEM_NOT_FOUND (satım için)
400 ORDER_LIMIT_EXCEEDED (max 20 aktif emir)
400 INVALID_PRICE (min: 1, max: 1M)
403 CANNOT_TRADE_OWN_ITEM
```

### 5.3 DELETE /market/cancel_order

**Emri iptal et**

**Request:**
```json
{
  "order_id": "uuid"
}
```

**Response (200 OK):**
```json
{
  "message": "Order cancelled",
  "refund": {
    "gold": 8500  // Buy order için escrow iadesi
  },
  "user": {
    "gold": 27000
  }
}
```

**Errors:**
```
404 ORDER_NOT_FOUND
403 NOT_YOUR_ORDER
400 ORDER_ALREADY_FILLED
```

---

## 6. PVP ENDPOINTS

### 6.1 GET /pvp/targets

**PvP hedef listesi**

**Query params:**
```
?min_power=1000
?max_power=1500
?limit=10
```

**Response (200 OK):**
```json
{
  "targets": [
    {
      "id": "uuid",
      "username": "victim123",
      "level": 11,
      "power": 1200,
      "gold": 35000,  // Görünür altın (~%10)
      "pvp_rating": 1180,
      "hospital_until": null,
      "guild": {
        "name": "Guildname",
        "tag": "TAG"
      },
      "win_probability": 0.65  // Tahmini kazanma şansı
    }
  ]
}
```

### 6.2 POST /pvp/attack

**PvP saldırısı başlat**

**Request:**
```json
{
  "target_id": "uuid"
}
```

**Response (200 OK):**
```json
{
  "message": "Battle completed",
  "battle": {
    "id": "uuid",
    "outcome": "win",  // flawless|win|draw|loss|crush
    "attacker": {
      "power": 1250,
      "energy_before": 75,
      "energy_after": 55,  // -20
      "hospital_minutes": 0
    },
    "defender": {
      "power": 1200,
      "hospital_minutes": 180  // 3 saat
    },
    "rewards": {
      "gold_stolen": 3500,
      "pvp_rating_change": +15
    }
  },
  "user": {
    "gold": 30500,
    "energy": 55,
    "pvp_rating": 1265,
    "pvp_wins": 35
  }
}
```

**Errors:**
```
400 INSUFFICIENT_ENERGY (min 20)
400 TARGET_IN_HOSPITAL
400 ATTACKER_IN_HOSPITAL
429 PVP_COOLDOWN (30 saniye beklenmeli)
403 CANNOT_ATTACK_GUILD_MEMBER
```

### 6.3 GET /pvp/history

**PvP geçmişi**

**Query params:**
```
?limit=20
?page=1
```

**Response (200 OK):**
```json
{
  "battles": [
    {
      "id": "uuid",
      "attacker_id": "uuid",
      "attacker_username": "shadowknight",
      "defender_id": "uuid",
      "defender_username": "victim123",
      "outcome": "win",
      "gold_stolen": 3500,
      "hospital_minutes": 0,
      "battled_at": "2026-01-03T10:50:00Z",
      "is_attacker": true
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 46,
    "has_next": true
  }
}
```

---

## 7. HOSPITAL ENDPOINTS

### 7.1 GET /hospital/status

**Hastane durumu**

**Response (200 OK):**
```json
{
  "in_hospital": true,
  "reason": "pvp_loss",
  "admitted_at": "2026-01-03T10:50:00Z",
  "release_time": "2026-01-03T13:50:00Z",
  "remaining_minutes": 180,
  "early_release_cost_gems": 540  // remaining_minutes * 3
}
```

### 7.2 POST /hospital/early_release

**Erken çıkış (gem ile)**

**Request:**
```json
{
  "use_gems": true
}
```

**Response (200 OK):**
```json
{
  "message": "Early release successful",
  "cost": {
    "gems": 540
  },
  "user": {
    "gems": 310,  // 850 - 540
    "hospital_until": null
  }
}
```

**Errors:**
```
400 NOT_IN_HOSPITAL
400 INSUFFICIENT_GEMS
429 EARLY_RELEASE_LIMIT_EXCEEDED (max 3/gün)
```

---

## 8. GUILD ENDPOINTS

### 8.1 GET /guilds/search

**Lonca arama**

**Query params:**
```
?name=shadow (partial match)
?min_level=1
?recruiting_only=true
?limit=20
```

**Response (200 OK):**
```json
{
  "guilds": [
    {
      "id": "uuid",
      "name": "Shadow Warriors",
      "tag": "SW",
      "description": "Active guild, daily wars",
      "level": 8,
      "member_count": 42,
      "max_members": 50,
      "is_recruiting": true,
      "min_level_requirement": 5,
      "season_points": 12500,
      "created_at": "2025-11-01T10:00:00Z"
    }
  ]
}
```

### 8.2 POST /guilds/join

**Loncaya katıl**

**Request:**
```json
{
  "guild_id": "uuid"
}
```

**Response (200 OK):**
```json
{
  "message": "Joined guild successfully",
  "guild": {
    "id": "uuid",
    "name": "Shadow Warriors",
    "role": "squire"
  }
}
```

**Errors:**
```
400 ALREADY_IN_GUILD
400 GUILD_FULL
403 LEVEL_REQUIREMENT_NOT_MET
403 GUILD_NOT_RECRUITING
```

### 8.3 POST /guilds/leave

**Loncadan ayrıl**

**Request:**
```json
{}
```

**Response (200 OK):**
```json
{
  "message": "Left guild successfully"
}
```

**Errors:**
```
400 NOT_IN_GUILD
403 FOUNDER_CANNOT_LEAVE (önce transfer et)
```

### 8.4 POST /guilds/donate

**Hazineye bağış**

**Request:**
```json
{
  "amount": 10000  // gold
}
```

**Response (200 OK):**
```json
{
  "message": "Donation successful",
  "contribution": {
    "amount": 10000,
    "total_contribution": 45000
  },
  "guild": {
    "treasury_gold": 250000
  },
  "user": {
    "gold": 115000,  // 125000 - 10000
    "guild_contribution": 45000
  }
}
```

**Errors:**
```
400 NOT_IN_GUILD
400 INSUFFICIENT_GOLD
400 INVALID_AMOUNT (min: 100, max: 1M)
```

---

## 9. PRODUCTION ENDPOINTS

### 9.1 GET /production/buildings

**Bina listesi**

**Response (200 OK):**
```json
{
  "buildings": [
    {
      "id": "uuid",
      "type": "farm",
      "level": 3,
      "production_queue": [
        {
          "item_id": "wheat",
          "quantity": 50,
          "started_at": "2026-01-03T09:00:00Z",
          "complete_at": "2026-01-03T12:00:00Z"
        }
      ],
      "last_collected_at": "2026-01-03T08:00:00Z",
      "offline_production_available": true,
      "offline_production_amount": 120  // 24 saatlik cap
    },
    {
      "id": "uuid",
      "type": "forge",
      "level": 2,
      "production_queue": []
    }
  ]
}
```

### 9.2 POST /production/start

**Üretim başlat**

**Request:**
```json
{
  "building_id": "uuid",
  "item_id": "iron_ore",
  "quantity": 100
}
```

**Response (200 OK):**
```json
{
  "message": "Production started",
  "production": {
    "item_id": "iron_ore",
    "quantity": 100,
    "started_at": "2026-01-03T11:00:00Z",
    "complete_at": "2026-01-03T14:00:00Z",
    "cost": {
      "gold": 5000
    }
  },
  "user": {
    "gold": 120000
  }
}
```

**Errors:**
```
404 BUILDING_NOT_FOUND
400 PRODUCTION_QUEUE_FULL (max 3)
400 INSUFFICIENT_GOLD
400 INVALID_ITEM_FOR_BUILDING
```

### 9.3 POST /production/collect

**Üretimi topla**

**Request:**
```json
{
  "building_id": "uuid"
}
```

**Response (200 OK):**
```json
{
  "message": "Production collected",
  "collected": [
    {
      "item_id": "wheat",
      "quantity": 50
    }
  ],
  "offline_bonus": {
    "item_id": "wheat",
    "quantity": 120  // 24h offline cap
  }
}
```

---

## 10. ENHANCEMENT ENDPOINTS

### 10.1 POST /enhancement/enhance

**Item geliştir**

**Request:**
```json
{
  "inventory_item_id": "uuid",
  "use_rune": "success"  // null|success|protection|special
}
```

**Response (200 OK - Success):**
```json
{
  "message": "Enhancement successful",
  "result": {
    "success": true,
    "from_level": 3,
    "to_level": 4,
    "item_destroyed": false,
    "new_power": 320,  // +30 per level
    "near_miss": false
  },
  "cost": {
    "gold": 15000,
    "rune_used": "success"
  },
  "user": {
    "gold": 105000
  }
}
```

**Response (200 OK - Failure):**
```json
{
  "message": "Enhancement failed",
  "result": {
    "success": false,
    "from_level": 7,
    "to_level": 7,
    "item_destroyed": true,  // %10 şans +7'den itibaren
    "near_miss": true  // %20 şans, +1% success bonus next time
  },
  "cost": {
    "gold": 80000,
    "rune_used": null
  }
}
```

**Errors:**
```
404 ITEM_NOT_FOUND
400 ALREADY_MAX_LEVEL (+10)
400 INSUFFICIENT_GOLD
400 RUNE_NOT_FOUND
```

---

## 11. CHAT ENDPOINTS

### 11.1 GET /chat/messages

**Chat mesajlarını getir**

**Query params:**
```
?channel=global (required: global|guild|trade)
?limit=50
?before=2026-01-03T11:00:00Z (pagination)
```

**Response (200 OK):**
```json
{
  "messages": [
    {
      "id": "uuid",
      "user_id": "uuid",
      "username": "shadowknight",
      "title": "Zindan Efendisi",
      "content": "LF guild for season 3!",
      "sent_at": "2026-01-03T10:55:00Z",
      "edited": false,
      "deleted": false
    }
  ],
  "has_more": true
}
```

### 11.2 POST /chat/send

**Mesaj gönder**

**Request:**
```json
{
  "channel": "global",
  "content": "Looking for Epic Sword +5!"
}
```

**Response (201 Created):**
```json
{
  "message": "Message sent",
  "chat_message": {
    "id": "uuid",
    "content": "Looking for Epic Sword +5!",
    "sent_at": "2026-01-03T11:00:00Z"
  }
}
```

**Errors:**
```
400 EMPTY_MESSAGE
400 MESSAGE_TOO_LONG (max 500 char)
400 PROFANITY_DETECTED
429 RATE_LIMIT_EXCEEDED (max 10/min)
403 USER_MUTED
```

---

## 12. SEASON ENDPOINTS

### 12.1 GET /season/current

**Aktif sezon bilgisi**

**Response (200 OK):**
```json
{
  "season": {
    "id": "uuid",
    "season_number": 3,
    "name": "Age of Shadows",
    "theme": "Dark forces rise",
    "start_date": "2026-01-01T00:00:00Z",
    "end_date": "2026-02-28T23:59:59Z",
    "phase": "competition",  // foundation|competition|peak|final
    "days_remaining": 56,
    "status": "active"
  }
}
```

### 12.2 GET /season/leaderboard

**Sezon sıralaması**

**Query params:**
```
?category=net_worth (required: net_worth|pvp|quest|economy|guild)
?limit=100
```

**Response (200 OK):**
```json
{
  "category": "net_worth",
  "leaderboard": [
    {
      "rank": 1,
      "user_id": "uuid",
      "username": "richplayer",
      "score": 5000000,  // Net worth (altın + item değeri)
      "guild": {
        "name": "Top Guild",
        "tag": "TOP"
      }
    },
    {
      "rank": 2,
      "user_id": "uuid",
      "username": "shadowknight",
      "score": 4500000
    }
  ],
  "your_rank": {
    "rank": 42,
    "score": 2500000
  },
  "last_updated": "2026-01-03T10:00:00Z"
}
```

### 12.3 GET /season/battlepass

**Battle pass durumu**

**Response (200 OK):**
```json
{
  "season_id": "uuid",
  "level": 28,
  "xp": 27500,
  "next_level_xp": 28000,
  "is_premium": true,
  "purchased_at": "2026-01-05T12:00:00Z",
  "free_rewards_claimed": [1, 3, 5, 10, 15, 20, 25],
  "premium_rewards_claimed": [1, 2, 3, 5, 7, 10, 12, 15, 18, 20, 25],
  "next_reward": {
    "level": 30,
    "free": {
      "gems": 300
    },
    "premium": {
      "gems": 500,
      "item": {"item_id": "skin_legendary", "quantity": 1}
    }
  }
}
```

### 12.4 POST /season/battlepass/claim

**Battle pass ödülü al**

**Request:**
```json
{
  "level": 30
}
```

**Response (200 OK):**
```json
{
  "message": "Reward claimed",
  "rewards": {
    "free": {
      "gems": 300
    },
    "premium": {
      "gems": 500,
      "items": [
        {"item_id": "skin_legendary", "quantity": 1}
      ]
    }
  },
  "user": {
    "gems": 1650
  }
}
```

**Errors:**
```
400 LEVEL_NOT_REACHED
400 REWARD_ALREADY_CLAIMED
```

---

## 13. MONETIZATION ENDPOINTS

### 13.1 GET /shop/packages

**Gem paketleri listesi**

**Response (200 OK):**
```json
{
  "packages": [
    {
      "id": "starter",
      "gems": 100,
      "bonus_gems": 0,
      "price_usd": 0.99,
      "price_local": {
        "currency": "TRY",
        "amount": 9.99
      },
      "first_time_bonus": 50,
      "available": true
    },
    {
      "id": "medium",
      "gems": 1200,
      "bonus_gems": 480,  // %40
      "price_usd": 9.99,
      "price_local": {
        "currency": "TRY",
        "amount": 299.99
      },
      "best_value": true,
      "available": true
    }
  ],
  "special_offers": [
    {
      "id": "weekly_special",
      "name": "Haftalık Süper Teklif",
      "gems": 800,
      "bonus_gems": 240,  // %30
      "price_usd": 4.99,
      "expires_at": "2026-01-05T00:00:00Z"
    }
  ]
}
```

### 13.2 POST /shop/purchase

**Satın alma başlat (payment gateway'e yönlendir)**

**Request:**
```json
{
  "package_id": "medium"
}
```

**Response (200 OK):**
```json
{
  "message": "Purchase initiated",
  "purchase_id": "uuid",
  "payment_url": "https://payment-provider.com/checkout?token=...",
  "expires_at": "2026-01-03T11:15:00Z"  // 15 dakika
}
```

### 13.3 POST /shop/webhook/payment_complete

**Payment provider callback (internal)**

**Request (from payment provider):**
```json
{
  "transaction_id": "provider_tx_123",
  "purchase_id": "uuid",
  "status": "completed",
  "amount": 9.99,
  "currency": "USD"
}
```

**Response (200 OK):**
```json
{
  "message": "Payment processed",
  "user": {
    "gems": 2330  // 850 + 1200 + 480 (bonus)
  }
}
```

---

## 14. ADMIN ENDPOINTS (Internal)

### 14.1 POST /admin/ban_user

**Kullanıcı banla**

**Request:**
```json
{
  "user_id": "uuid",
  "reason": "Cheating detected",
  "duration_days": 7,  // null = permanent
  "evidence": "Screenshot: ..."
}
```

**Response (200 OK):**
```json
{
  "message": "User banned",
  "ban": {
    "id": "uuid",
    "user_id": "uuid",
    "banned_until": "2026-01-10T11:00:00Z",
    "banned_by": "admin_uuid"
  }
}
```

### 14.2 GET /admin/analytics/summary

**Analitik özeti (dashboard için)**

**Response (200 OK):**
```json
{
  "date": "2026-01-03",
  "metrics": {
    "dau": 12543,
    "new_users": 342,
    "revenue_usd": 1856.23,
    "arpdau": 0.148,
    "arppu": 12.45,
    "paying_users": 149,
    "conversion_rate": 0.062
  },
  "trends": {
    "dau_change_percent": 5.2,
    "revenue_change_percent": 8.1
  }
}
```

---

## 15. WEBHOOKS

### 15.1 Server → Client Events (WebSocket)

**Connection:**
```typescript
const ws = new WebSocket('wss://your-project.supabase.co/realtime/v1');

ws.send(JSON.stringify({
  event: 'subscribe',
  payload: {
    channel: 'user:' + user_id,
    access_token: jwt_token
  }
}));
```

**Events:**

**Energy regen:**
```json
{
  "event": "energy_update",
  "payload": {
    "energy": 82,
    "max_energy": 100,
    "next_regen_at": "2026-01-03T11:05:00Z"
  }
}
```

**Hospital release:**
```json
{
  "event": "hospital_release",
  "payload": {
    "message": "Hastaneden çıktın!",
    "timestamp": "2026-01-03T13:50:00Z"
  }
}
```

**Market order filled:**
```json
{
  "event": "market_order_filled",
  "payload": {
    "order_id": "uuid",
    "quantity_filled": 1,
    "total_price": 8500,
    "status": "filled"
  }
}
```

**PvP attacked:**
```json
{
  "event": "pvp_attacked",
  "payload": {
    "attacker": {
      "username": "enemy123",
      "power": 1300
    },
    "outcome": "loss",
    "gold_lost": 2000,
    "hospital_minutes": 240
  }
}
```

**Guild notification:**
```json
{
  "event": "guild_notification",
  "payload": {
    "type": "war_started",
    "message": "Lonca savaşı başladı: Shadow Warriors vs Dark Knights",
    "metadata": {
      "war_id": "uuid",
      "opponent_guild": "Dark Knights"
    }
  }
}
```

---

## 16. OPENAPI SPEC (YAML)

**openapi.yaml (excerpt):**
```yaml
openapi: 3.0.3
info:
  title: Gölge Krallık API
  version: 1.0.0
  description: API documentation for Gölge Krallık: Kadim Mühür'ün Çöküşü

servers:
  - url: https://your-project.supabase.co/functions/v1
    description: Production server

security:
  - BearerAuth: []

paths:
  /auth/register:
    post:
      summary: Register new user
      tags: [Auth]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [email, username, password]
              properties:
                email:
                  type: string
                  format: email
                username:
                  type: string
                  minLength: 3
                  maxLength: 20
                password:
                  type: string
                  minLength: 8
                referral_code:
                  type: string
      responses:
        '201':
          description: User created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/RegisterResponse'
        '409':
          description: Username or email taken
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'

  /market/place_order:
    post:
      summary: Place market order
      tags: [Market]
      security:
        - BearerAuth: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/PlaceOrderRequest'
      responses:
        '201':
          description: Order placed
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/PlaceOrderResponse'

components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

  schemas:
    ErrorResponse:
      type: object
      properties:
        error:
          type: object
          properties:
            code:
              type: string
            message:
              type: string
            details:
              type: object
        timestamp:
          type: string
          format: date-time
        request_id:
          type: string
          format: uuid

    RegisterResponse:
      type: object
      properties:
        user:
          $ref: '#/components/schemas/User'
        session:
          $ref: '#/components/schemas/Session'

    User:
      type: object
      properties:
        id:
          type: string
          format: uuid
        username:
          type: string
        email:
          type: string
        level:
          type: integer
        gold:
          type: integer
        gems:
          type: integer
        created_at:
          type: string
          format: date-time

    PlaceOrderRequest:
      type: object
      required: [item_id, order_type, quantity, price_per_unit]
      properties:
        item_id:
          type: string
        order_type:
          type: string
          enum: [buy, sell]
        quantity:
          type: integer
          minimum: 1
        price_per_unit:
          type: integer
          minimum: 1
```

---

## 17. DEFINITION OF DONE

- [ ] Tüm endpoint'ler tanımlandı
- [ ] Request/response şemaları belirtildi
- [ ] Error kodları dökümente edildi
- [ ] Rate limit kuralları belirtildi
- [ ] Authentication flow açıklandı
- [ ] WebSocket event'leri listelendi
- [ ] OpenAPI spec oluşturuldu
- [ ] Postman collection export edildi

---

Bu döküman, Gölge Krallık API'sinin tam referans dökümanını, tüm endpoint'leri, request/response formatlarını, error handling'i ve WebSocket event'lerini içerir.
