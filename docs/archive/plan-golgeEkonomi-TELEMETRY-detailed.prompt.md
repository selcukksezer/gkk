# Gölge Ekonomi — Telemetri ve Analitik Sistemi Detaylı Belge

> Kaynak: Tüm fazlar için telemetri ihtiyacı
> Oyun: Gölge Krallık: Kadim Mühür'ün Çöküşü
> Amaç: Event tracking, metrikler, dashboard, anomali tespiti, A/B test

---

## 1. TELEMETRİ GENEL BAKIŞ

### 1.1 Telemetri Mimarisi

**Veri akış:**
```
Godot Client
    ↓ (batch events)
TelemetryClient (autoload)
    ↓ (HTTPS POST)
Supabase Edge Function
    ↓ (insert)
PostgreSQL analytics tables
    ↓ (cron aggregation)
Metabase Dashboard
```

**Veri tipleri:**
```
1. Event Stream (raw events)
2. Session Data (oyun oturumları)
3. User Metrics (kullanıcı metrikleri)
4. Economy Metrics (ekonomi analizi)
5. Performance Metrics (teknik)
```

---

## 2. EVENT TRACKING

### 2.1 Event Taxonomy

**Kategori yapısı:**
```
category.subcategory.action

Örnek:
- combat.pvp.initiate
- economy.market.order_placed
- progression.quest.completed
- social.guild.joined
```

### 2.2 Core Events

**A. User Lifecycle**
```typescript
// Kayıt
{
  event: "user.registered",
  timestamp: "2026-01-03T10:30:00Z",
  user_id: "uuid",
  properties: {
    referral_source: "organic|ad|friend",
    device_type: "android|ios|pc",
    country: "TR"
  }
}

// İlk oturum
{
  event: "user.first_session",
  timestamp: "2026-01-03T10:32:00Z",
  user_id: "uuid",
  properties: {
    tutorial_completed: false,
    session_duration: 120  // saniye
  }
}

// Login
{
  event: "user.login",
  timestamp: "2026-01-03T14:00:00Z",
  user_id: "uuid",
  properties: {
    login_method: "username|google|apple",
    day_since_last_login: 1
  }
}
```

**B. Progression Events**
```typescript
// Seviye atlama
{
  event: "progression.level_up",
  timestamp: "2026-01-03T11:00:00Z",
  user_id: "uuid",
  properties: {
    old_level: 4,
    new_level: 5,
    time_since_last_levelup: 1800,  // saniye
    total_playtime: 7200
  }
}

// Quest tamamlama
{
  event: "progression.quest.completed",
  timestamp: "2026-01-03T11:15:00Z",
  user_id: "uuid",
  properties: {
    quest_id: "quest_001",
    quest_difficulty: "normal",
    duration: 600,
    rewards: { gold: 1000, xp: 500 }
  }
}

// Başarım
{
  event: "progression.achievement.unlocked",
  timestamp: "2026-01-03T11:20:00Z",
  user_id: "uuid",
  properties: {
    achievement_id: "pvp_master",
    achievement_rarity: "rare"
  }
}
```

**C. Economy Events**
```typescript
// Altın kazanımı
{
  event: "economy.gold.earned",
  timestamp: "2026-01-03T11:30:00Z",
  user_id: "uuid",
  properties: {
    amount: 5000,
    source: "quest|pvp|market|production",
    balance_after: 25000
  }
}

// Altın harcama
{
  event: "economy.gold.spent",
  timestamp: "2026-01-03T11:35:00Z",
  user_id: "uuid",
  properties: {
    amount: 3000,
    sink: "enhancement|market|hospital|production",
    balance_after: 22000
  }
}

// Market emir
{
  event: "economy.market.order_placed",
  timestamp: "2026-01-03T11:40:00Z",
  user_id: "uuid",
  properties: {
    order_type: "buy|sell",
    item_id: "sword_001",
    quantity: 1,
    price: 5000
  }
}

// Gem harcama
{
  event: "economy.gem.spent",
  timestamp: "2026-01-03T11:45:00Z",
  user_id: "uuid",
  properties: {
    amount: 300,
    category: "hospital|cosmetic|slot|premium",
    balance_after: 700
  }
}
```

**D. Combat Events**
```typescript
// PvP başlatma
{
  event: "combat.pvp.initiated",
  timestamp: "2026-01-03T12:00:00Z",
  user_id: "uuid",
  properties: {
    target_id: "opponent_uuid",
    power_diff: 150,  // Saldırganın gücü - savunmanın gücü
    attacker_energy: 80
  }
}

// PvP sonucu
{
  event: "combat.pvp.completed",
  timestamp: "2026-01-03T12:01:00Z",
  user_id: "uuid",
  properties: {
    target_id: "opponent_uuid",
    outcome: "flawless|win|draw|loss|crush",
    gold_change: -500,  // Kaybedilen
    hospital_time: 240,  // dakika
    duration: 60  // saniye
  }
}

// Zindan
{
  event: "combat.dungeon.completed",
  timestamp: "2026-01-03T12:15:00Z",
  user_id: "uuid",
  properties: {
    dungeon_id: "dungeon_003",
    difficulty: "hard",
    success: true,
    duration: 300,
    rewards: { gold: 10000, items: ["sword_epic"] }
  }
}
```

**E. Social Events**
```typescript
// Lonca katılım
{
  event: "social.guild.joined",
  timestamp: "2026-01-03T13:00:00Z",
  user_id: "uuid",
  properties: {
    guild_id: "guild_001",
    guild_size: 25,
    invitation: true
  }
}

// Chat mesajı
{
  event: "social.chat.message_sent",
  timestamp: "2026-01-03T13:05:00Z",
  user_id: "uuid",
  properties: {
    channel: "global|guild|dm",
    message_length: 42,
    contains_link: false
  }
}
```

**F. Monetization Events**
```typescript
// Gem satın alma başlatma
{
  event: "monetization.purchase.initiated",
  timestamp: "2026-01-03T14:00:00Z",
  user_id: "uuid",
  properties: {
    package_id: "medium",
    price_usd: 9.99,
    gem_amount: 1200
  }
}

// Satın alma tamamlandı
{
  event: "monetization.purchase.completed",
  timestamp: "2026-01-03T14:02:00Z",
  user_id: "uuid",
  properties: {
    package_id: "medium",
    price_usd: 9.99,
    gem_amount: 1200,
    payment_method: "credit_card|google_pay|apple_pay",
    first_purchase: false,
    ltv_total: 29.97  // Toplam harcama
  }
}

// Battle pass satın alma
{
  event: "monetization.battlepass.purchased",
  timestamp: "2026-01-03T14:10:00Z",
  user_id: "uuid",
  properties: {
    season_id: "season_003",
    price_gems: 800,
    current_level: 12
  }
}
```

**G. Technical Events**
```typescript
// Crash
{
  event: "technical.crash",
  timestamp: "2026-01-03T15:00:00Z",
  user_id: "uuid",
  properties: {
    error_message: "NullReferenceException...",
    stack_trace: "...",
    device_model: "Pixel 7",
    os_version: "Android 14"
  }
}

// Performans
{
  event: "technical.performance",
  timestamp: "2026-01-03T15:05:00Z",
  user_id: "uuid",
  properties: {
    avg_fps: 58,
    memory_usage_mb: 512,
    load_time_ms: 2300
  }
}
```

### 2.3 Event Implementation (Godot)

**TelemetryClient autoload:**
```gdscript
# autoload/TelemetryClient.gd
extends Node

const BATCH_SIZE = 50
const FLUSH_INTERVAL = 30.0  # saniye

var event_queue: Array = []
var flush_timer: Timer

func _ready():
	flush_timer = Timer.new()
	flush_timer.wait_time = FLUSH_INTERVAL
	flush_timer.autostart = true
	flush_timer.timeout.connect(_flush_events)
	add_child(flush_timer)

func track_event(category: String, action: String, properties: Dictionary = {}):
	var event = {
		"event": category + "." + action,
		"timestamp": Time.get_datetime_string_from_system(),
		"user_id": SessionManager.user_id,
		"properties": properties
	}
	
	event_queue.append(event)
	
	# Batch size'a ulaştıysak hemen flush
	if event_queue.size() >= BATCH_SIZE:
		_flush_events()

func _flush_events():
	if event_queue.is_empty():
		return
	
	var batch = event_queue.duplicate()
	event_queue.clear()
	
	# API'ye gönder
	var response = await NetworkManager.post("/analytics/events", {
		"events": batch
	})
	
	if response.error:
		# Hata durumunda queue'ya geri ekle
		event_queue.append_array(batch)

# Kolaylık fonksiyonları
func track_screen_view(screen_name: String):
	track_event("ui", "screen_view", {"screen": screen_name})

func track_button_click(button_name: String):
	track_event("ui", "button_click", {"button": button_name})

func track_gold_earned(amount: int, source: String):
	track_event("economy.gold", "earned", {
		"amount": amount,
		"source": source,
		"balance_after": StateStore.gold
	})

func track_pvp_result(target_id: String, outcome: String, gold_change: int):
	track_event("combat.pvp", "completed", {
		"target_id": target_id,
		"outcome": outcome,
		"gold_change": gold_change,
		"hospital_time": StateStore.hospital_minutes
	})
```

**Kullanım örneği:**
```gdscript
# scenes/ui/MarketScreen.gd
extends Control

func _on_place_order_pressed():
	var order_data = {
		"item_id": selected_item.id,
		"quantity": quantity_spin.value,
		"price": price_spin.value,
		"type": "buy" if buy_radio.button_pressed else "sell"
	}
	
	# Telemetri
	TelemetryClient.track_event("economy.market", "order_placed", order_data)
	
	# API çağrısı
	var response = await NetworkManager.post("/market/place_order", order_data)
	
	if response.success:
		show_success_message()
```

---

## 3. METRIC DEFINITIONS

### 3.1 User Metrics

**DAU/MAU/WAU:**
```sql
-- Daily Active Users
SELECT COUNT(DISTINCT user_id) as dau
FROM analytics_events
WHERE event = 'user.login'
  AND DATE(timestamp) = CURRENT_DATE;

-- Monthly Active Users
SELECT COUNT(DISTINCT user_id) as mau
FROM analytics_events
WHERE event = 'user.login'
  AND timestamp >= CURRENT_DATE - INTERVAL '30 days';

-- Stickiness (DAU/MAU)
SELECT (dau::float / mau) as stickiness
FROM (
  SELECT COUNT(DISTINCT user_id) FILTER (WHERE DATE(timestamp) = CURRENT_DATE) as dau,
         COUNT(DISTINCT user_id) as mau
  FROM analytics_events
  WHERE event = 'user.login'
    AND timestamp >= CURRENT_DATE - INTERVAL '30 days'
) sub;
```

**Retention:**
```sql
-- D1 Retention
WITH cohort AS (
  SELECT user_id, DATE(MIN(timestamp)) as install_date
  FROM analytics_events
  WHERE event = 'user.registered'
  GROUP BY user_id
)
SELECT 
  c.install_date,
  COUNT(DISTINCT c.user_id) as installs,
  COUNT(DISTINCT CASE 
    WHEN DATE(e.timestamp) = c.install_date + 1 
    THEN e.user_id 
  END) as d1_retained,
  (COUNT(DISTINCT CASE WHEN DATE(e.timestamp) = c.install_date + 1 THEN e.user_id END)::float / 
   COUNT(DISTINCT c.user_id)) * 100 as d1_retention_rate
FROM cohort c
LEFT JOIN analytics_events e ON c.user_id = e.user_id AND e.event = 'user.login'
WHERE c.install_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY c.install_date
ORDER BY c.install_date DESC;
```

**Churn:**
```sql
-- 7 gün giriş yapmayan = churned
SELECT 
  COUNT(DISTINCT user_id) as churned_users
FROM users
WHERE last_login < CURRENT_DATE - INTERVAL '7 days'
  AND created_at < CURRENT_DATE - INTERVAL '14 days';
```

### 3.2 Engagement Metrics

**Session Duration:**
```sql
-- Ortalama oturum süresi
SELECT 
  AVG(session_duration) as avg_session_seconds,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY session_duration) as median_session_seconds
FROM analytics_sessions
WHERE DATE(start_time) = CURRENT_DATE;
```

**Sessions per User:**
```sql
SELECT 
  user_id,
  COUNT(*) as session_count,
  AVG(session_duration) as avg_duration
FROM analytics_sessions
WHERE start_time >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY user_id;
```

**Feature Usage:**
```sql
-- PvP katılım oranı
SELECT 
  (COUNT(DISTINCT user_id) FILTER (WHERE event = 'combat.pvp.initiated')::float / 
   COUNT(DISTINCT user_id) FILTER (WHERE event = 'user.login')) * 100 as pvp_participation_rate
FROM analytics_events
WHERE DATE(timestamp) = CURRENT_DATE;
```

### 3.3 Economy Metrics

**Gold Velocity:**
```sql
-- Günlük altın akışı
SELECT 
  SUM(amount) FILTER (WHERE event = 'economy.gold.earned') as gold_earned,
  SUM(amount) FILTER (WHERE event = 'economy.gold.spent') as gold_spent,
  SUM(amount) FILTER (WHERE event = 'economy.gold.earned') - 
  SUM(amount) FILTER (WHERE event = 'economy.gold.spent') as net_gold_change
FROM (
  SELECT 
    event,
    (properties->>'amount')::int as amount
  FROM analytics_events
  WHERE DATE(timestamp) = CURRENT_DATE
    AND event IN ('economy.gold.earned', 'economy.gold.spent')
) sub;
```

**Inflation Rate:**
```sql
-- Haftalık enflasyon (market fiyat artışı)
WITH weekly_prices AS (
  SELECT 
    item_id,
    AVG((properties->>'price')::int) as avg_price,
    DATE_TRUNC('week', timestamp) as week
  FROM analytics_events
  WHERE event = 'economy.market.order_filled'
  GROUP BY item_id, week
)
SELECT 
  item_id,
  ((current_week.avg_price - prev_week.avg_price) / prev_week.avg_price::float) * 100 as inflation_rate
FROM weekly_prices current_week
JOIN weekly_prices prev_week ON current_week.item_id = prev_week.item_id 
  AND current_week.week = prev_week.week + INTERVAL '1 week'
ORDER BY inflation_rate DESC;
```

**Conversion Rate (F2P → Paying):**
```sql
SELECT 
  (COUNT(DISTINCT user_id) FILTER (WHERE event = 'monetization.purchase.completed')::float /
   COUNT(DISTINCT user_id) FILTER (WHERE event = 'user.registered')) * 100 as conversion_rate
FROM analytics_events
WHERE timestamp >= CURRENT_DATE - INTERVAL '30 days';
```

### 3.4 Monetization Metrics

**ARPDAU:**
```sql
SELECT 
  SUM((properties->>'price_usd')::numeric) / COUNT(DISTINCT user_id) as arpdau
FROM analytics_events
WHERE event = 'monetization.purchase.completed'
  AND DATE(timestamp) = CURRENT_DATE;
```

**ARPPU:**
```sql
SELECT 
  SUM((properties->>'price_usd')::numeric) / COUNT(DISTINCT user_id) as arppu
FROM analytics_events
WHERE event = 'monetization.purchase.completed'
  AND DATE(timestamp) = CURRENT_DATE;
```

**LTV (Lifetime Value):**
```sql
-- 30-day LTV projection
WITH cohort AS (
  SELECT user_id, DATE(MIN(timestamp)) as install_date
  FROM analytics_events
  WHERE event = 'user.registered'
  GROUP BY user_id
),
revenue AS (
  SELECT 
    c.install_date,
    c.user_id,
    SUM((e.properties->>'price_usd')::numeric) as total_revenue
  FROM cohort c
  LEFT JOIN analytics_events e ON c.user_id = e.user_id 
    AND e.event = 'monetization.purchase.completed'
  WHERE c.install_date >= CURRENT_DATE - INTERVAL '90 days'
  GROUP BY c.install_date, c.user_id
)
SELECT 
  install_date,
  AVG(total_revenue) as avg_ltv_30d
FROM revenue
WHERE install_date <= CURRENT_DATE - INTERVAL '30 days'
GROUP BY install_date
ORDER BY install_date DESC;
```

---

## 4. DASHBOARD TASARIMI

### 4.1 Executive Dashboard

**Üst seviye KPI'lar (Metabase):**
```
┌─────────────────────────────────────────────────┐
│  GÖLGE KRALLIK - EXECUTIVE DASHBOARD            │
├─────────────────────────────────────────────────┤
│                                                  │
│  DAU: 12,543 (↑ 5.2%)     MAU: 45,231 (↑ 3.1%) │
│  ARPDAU: $0.18 (↑ 2.4%)   ARPPU: $12.34 (↓1.2%)│
│                                                  │
│  D1 Retention: 42%        D7 Retention: 18%     │
│  D30 Retention: 8%        Conversion: 6.2%      │
│                                                  │
│  ┌─────────── DAU TREND (30 days) ────────────┐ │
│  │                              ╱╲              │ │
│  │                          ╱╲ ╱  ╲             │ │
│  │                      ╱╲ ╱  ╲    ╲            │ │
│  │                  ╱╲ ╱  ╲    ╲    ╲╱╲         │ │
│  │              ╱╲ ╱  ╲    ╲            ╲       │ │
│  │          ╱╲ ╱  ╲                       ╲     │ │
│  └───────────────────────────────────────────── │
│                                                  │
│  ┌─────────── REVENUE (7 days) ───────────────┐ │
│  │  Mon  Tue  Wed  Thu  Fri  Sat  Sun          │ │
│  │  ███  ███  ███  ███  ████ ████ ███          │ │
│  │  $1.2K $1.1K $1.3K $1.2K $1.8K $2.1K $1.5K  │ │
│  └───────────────────────────────────────────── │
└─────────────────────────────────────────────────┘
```

### 4.2 User Behavior Dashboard

**Funnel analizi:**
```
REGISTRATION FUNNEL
───────────────────
Tutorial Start:     10,000 (100%)
  ↓ -15%
Tutorial Complete:   8,500 (85%)
  ↓ -20%
First Quest:         6,800 (68%)
  ↓ -25%
First PvP:           5,100 (51%)
  ↓ -30%
Join Guild:          3,570 (36%)
```

**Feature adoption:**
```
FEATURE USAGE (Last 7 days)
───────────────────────────
PvP:           65% users
Market:        52% users
Production:    38% users
Enhancement:   28% users
Guild:         36% users
Dungeon:       42% users
```

### 4.3 Economy Dashboard

**Gold sources/sinks:**
```
GOLD FLOW (Today)
─────────────────
SOURCES:
  Quests:       450M (45%)
  PvP wins:     300M (30%)
  Production:   150M (15%)
  Dungeons:     100M (10%)
  ─────────────────
  TOTAL:        1,000M

SINKS:
  Enhancement:  350M (40%)
  Market fees:  200M (23%)
  PvP losses:   150M (17%)
  Hospital:     100M (11%)
  Production:    80M (9%)
  ─────────────────
  TOTAL:        880M

NET: +120M (inflation risk!)
```

**Market health:**
```
MARKET ACTIVITY (Today)
───────────────────────
Orders placed:  5,234
Orders filled:  4,123 (79%)
Avg fill time:  45 minutes

Top traded items:
1. Epic Sword:    234 trades (avg: 8,500 gold)
2. Gelişmiş Rün:  189 trades (avg: 15,000 gold)
3. Büyük İksir:   456 trades (avg: 500 gold)
```

### 4.4 Monetization Dashboard

**Conversion funnel:**
```
PURCHASE FUNNEL (Last 7 days)
──────────────────────────────
Gem Store Viewed:     2,345 (100%)
  ↓ -60%
Package Selected:       938 (40%)
  ↓ -35%
Payment Initiated:      610 (26%)
  ↓ -8%
Purchase Completed:     561 (24%)

Conversion rate: 24% (target: 22%) ✓
```

**Revenue breakdown:**
```
REVENUE BY PACKAGE (Last 30 days)
──────────────────────────────────
Starter ($0.99):   $1,234 (12%)
Small ($4.99):     $2,456 (24%)
Medium ($9.99):    $4,123 (40%)  ← Best seller
Large ($19.99):    $1,789 (17%)
Mega ($49.99):       $734 (7%)
─────────────────────────────
TOTAL:            $10,336
```

---

## 5. ANOMALİ TESPİTİ

### 5.1 Automated Alerts

**Threshold-based alerts:**
```typescript
interface Alert {
  metric: string;
  condition: string;
  threshold: number;
  severity: "low" | "medium" | "high" | "critical";
  action: string;
}

const ALERTS: Alert[] = [
  {
    metric: "dau",
    condition: "drops_below",
    threshold: 0.80,  // 20% düşüş
    severity: "high",
    action: "notify_team"
  },
  {
    metric: "crash_rate",
    condition: "exceeds",
    threshold: 0.05,  // %5
    severity: "critical",
    action: "notify_team + halt_deployment"
  },
  {
    metric: "gold_inflation",
    condition: "exceeds",
    threshold: 0.10,  // %10 haftalık
    severity: "medium",
    action: "notify_economy_team"
  },
  {
    metric: "conversion_rate",
    condition: "drops_below",
    threshold: 0.70,  // 30% düşüş
    severity: "high",
    action: "notify_monetization_team"
  }
];
```

**Implementation:**
```sql
-- Cron job (her saat)
CREATE OR REPLACE FUNCTION check_anomalies()
RETURNS void AS $$
DECLARE
  current_dau int;
  previous_dau int;
  dau_change float;
BEGIN
  -- DAU kontrolü
  SELECT COUNT(DISTINCT user_id) INTO current_dau
  FROM analytics_events
  WHERE event = 'user.login'
    AND DATE(timestamp) = CURRENT_DATE;
  
  SELECT COUNT(DISTINCT user_id) INTO previous_dau
  FROM analytics_events
  WHERE event = 'user.login'
    AND DATE(timestamp) = CURRENT_DATE - 1;
  
  dau_change := (current_dau - previous_dau)::float / previous_dau;
  
  IF dau_change < -0.20 THEN
    INSERT INTO alerts (metric, message, severity)
    VALUES ('dau', 'DAU dropped by ' || (dau_change * 100)::text || '%', 'high');
  END IF;
  
  -- Diğer metrikler...
END;
$$ LANGUAGE plpgsql;
```

### 5.2 Abuse Detection

**Cheating patterns:**
```sql
-- Gold kazanımı anomalisi (çok hızlı kazanım)
SELECT 
  user_id,
  SUM((properties->>'amount')::int) as total_gold_earned,
  COUNT(*) as earn_events,
  MAX((properties->>'amount')::int) as max_single_earn
FROM analytics_events
WHERE event = 'economy.gold.earned'
  AND timestamp >= NOW() - INTERVAL '1 hour'
GROUP BY user_id
HAVING SUM((properties->>'amount')::int) > 1000000  -- 1M/saat suspicious
   OR MAX((properties->>'amount')::int) > 500000    -- 500K tek seferde
ORDER BY total_gold_earned DESC;
```

**Market manipulation:**
```sql
-- Aynı kullanıcının kendi kendine trade yapması
SELECT 
  buyer_id,
  seller_id,
  COUNT(*) as trade_count
FROM market_transactions
WHERE created_at >= NOW() - INTERVAL '24 hours'
  AND buyer_id = seller_id  -- Kendi kendine alım-satım
GROUP BY buyer_id, seller_id
HAVING COUNT(*) > 5;
```

### 5.3 Statistical Anomaly Detection

**Z-score method:**
```sql
-- Outlier detection (PvP win rate)
WITH stats AS (
  SELECT 
    AVG(win_rate) as mean_win_rate,
    STDDEV(win_rate) as stddev_win_rate
  FROM (
    SELECT 
      user_id,
      COUNT(*) FILTER (WHERE properties->>'outcome' IN ('flawless', 'win'))::float / 
        COUNT(*) as win_rate
    FROM analytics_events
    WHERE event = 'combat.pvp.completed'
      AND timestamp >= NOW() - INTERVAL '7 days'
    GROUP BY user_id
    HAVING COUNT(*) >= 10  -- Min 10 fight
  ) sub
)
SELECT 
  u.user_id,
  u.win_rate,
  (u.win_rate - s.mean_win_rate) / s.stddev_win_rate as z_score
FROM (
  SELECT 
    user_id,
    COUNT(*) FILTER (WHERE properties->>'outcome' IN ('flawless', 'win'))::float / 
      COUNT(*) as win_rate
  FROM analytics_events
  WHERE event = 'combat.pvp.completed'
    AND timestamp >= NOW() - INTERVAL '7 days'
  GROUP BY user_id
  HAVING COUNT(*) >= 10
) u
CROSS JOIN stats s
WHERE ABS((u.win_rate - s.mean_win_rate) / s.stddev_win_rate) > 3  -- 3 sigma
ORDER BY z_score DESC;
```

---

## 6. A/B TEST ALTYAPISI

### 6.1 Experiment Framework

**Schema:**
```sql
CREATE TABLE experiments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  start_date TIMESTAMP DEFAULT NOW(),
  end_date TIMESTAMP,
  status TEXT DEFAULT 'running',  -- running|paused|completed
  allocation_percent NUMERIC DEFAULT 50,  -- %50 test, %50 control
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE experiment_variants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  experiment_id UUID REFERENCES experiments(id),
  name TEXT NOT NULL,  -- control|variant_a|variant_b
  config JSONB,  -- Variant ayarları
  allocation_percent NUMERIC  -- Bu variant'a düşen %
);

CREATE TABLE experiment_assignments (
  user_id UUID REFERENCES users(id),
  experiment_id UUID REFERENCES experiments(id),
  variant_id UUID REFERENCES experiment_variants(id),
  assigned_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (user_id, experiment_id)
);
```

**Assignment logic:**
```typescript
async function assignUserToExperiment(
  userId: string,
  experimentId: string
): Promise<string> {
  // Cache kontrolü
  const cached = await redis.get(`exp:${experimentId}:${userId}`);
  if (cached) return cached;
  
  // Daha önce assign edilmiş mi?
  const existing = await supabase
    .from("experiment_assignments")
    .select("variant_id")
    .eq("user_id", userId)
    .eq("experiment_id", experimentId)
    .single();
  
  if (existing.data) {
    return existing.data.variant_id;
  }
  
  // Yeni assignment (consistent hashing)
  const hash = createHash("sha256")
    .update(userId + experimentId)
    .digest("hex");
  
  const hashValue = parseInt(hash.substring(0, 8), 16) / 0xffffffff;
  
  // Variant seç
  const variants = await supabase
    .from("experiment_variants")
    .select("*")
    .eq("experiment_id", experimentId);
  
  let cumulative = 0;
  let selectedVariant = variants.data[0];
  
  for (const variant of variants.data) {
    cumulative += variant.allocation_percent / 100;
    if (hashValue < cumulative) {
      selectedVariant = variant;
      break;
    }
  }
  
  // Kaydet
  await supabase.from("experiment_assignments").insert({
    user_id: userId,
    experiment_id: experimentId,
    variant_id: selectedVariant.id
  });
  
  // Cache
  await redis.setex(
    `exp:${experimentId}:${userId}`,
    86400,  // 24 saat
    selectedVariant.id
  );
  
  return selectedVariant.id;
}
```

### 6.2 Client Implementation

**Feature flag sistem:**
```gdscript
# autoload/ExperimentManager.gd
extends Node

var experiments: Dictionary = {}

func _ready():
	_load_experiments()

func _load_experiments():
	var response = await NetworkManager.get("/experiments/active")
	if response.success:
		for exp in response.data:
			experiments[exp.id] = exp

func get_variant(experiment_name: String) -> Dictionary:
	var exp = _find_experiment(experiment_name)
	if not exp:
		return {"name": "control", "config": {}}
	
	# Server'dan assignment al
	var response = await NetworkManager.get("/experiments/" + exp.id + "/assignment")
	
	if response.success:
		return response.data.variant
	else:
		return {"name": "control", "config": {}}

func _find_experiment(name: String) -> Dictionary:
	for exp_id in experiments:
		if experiments[exp_id].name == name:
			return experiments[exp_id]
	return {}
```

**Kullanım örneği:**
```gdscript
# Test: Battle pass fiyatı
func _ready():
	var variant = await ExperimentManager.get_variant("battlepass_pricing")
	
	match variant.name:
		"control":
			battle_pass_price = 800  # gems
		"variant_a":
			battle_pass_price = 600  # gems (indirim)
		"variant_b":
			battle_pass_price = 1000  # gems (premium)
	
	price_label.text = str(battle_pass_price) + " 💎"
```

### 6.3 Statistical Analysis

**T-test (conversion rate karşılaştırma):**
```sql
WITH variant_stats AS (
  SELECT 
    ea.variant_id,
    COUNT(DISTINCT ea.user_id) as total_users,
    COUNT(DISTINCT CASE 
      WHEN ae.event = 'monetization.purchase.completed' 
      THEN ae.user_id 
    END) as converted_users,
    COUNT(DISTINCT CASE 
      WHEN ae.event = 'monetization.purchase.completed' 
      THEN ae.user_id 
    END)::float / COUNT(DISTINCT ea.user_id) as conversion_rate
  FROM experiment_assignments ea
  LEFT JOIN analytics_events ae ON ea.user_id = ae.user_id
  WHERE ea.experiment_id = '...'
    AND ae.timestamp >= ea.assigned_at
  GROUP BY ea.variant_id
)
SELECT 
  v1.name as control_variant,
  v2.name as test_variant,
  s1.conversion_rate as control_conversion,
  s2.conversion_rate as test_conversion,
  ((s2.conversion_rate - s1.conversion_rate) / s1.conversion_rate) * 100 as lift_percent,
  -- T-test hesaplaması (simplified)
  CASE 
    WHEN ABS(s2.conversion_rate - s1.conversion_rate) / 
         SQRT((s1.conversion_rate * (1 - s1.conversion_rate) / s1.total_users) + 
              (s2.conversion_rate * (1 - s2.conversion_rate) / s2.total_users)) > 1.96
    THEN 'significant'
    ELSE 'not significant'
  END as statistical_significance
FROM variant_stats s1
JOIN variant_stats s2 ON s1.variant_id != s2.variant_id
JOIN experiment_variants v1 ON s1.variant_id = v1.id
JOIN experiment_variants v2 ON s2.variant_id = v2.id
WHERE v1.name = 'control';
```

---

## 7. PRİVACY & GDPR

### 7.1 Data Collection Consent

**Opt-in/opt-out:**
```gdscript
# Settings
var analytics_enabled: bool = true
var personalized_ads_enabled: bool = false

func _on_analytics_toggle(enabled: bool):
	analytics_enabled = enabled
	ConfigManager.set_config("analytics_enabled", enabled)
	
	if not enabled:
		# Tüm event queue'yu temizle
		TelemetryClient.event_queue.clear()
```

### 7.2 Data Retention

**Otomatik silme:**
```sql
-- 90 gün sonra raw events sil
DELETE FROM analytics_events
WHERE timestamp < NOW() - INTERVAL '90 days';

-- Aggregated data 2 yıl sakla
DELETE FROM analytics_daily_aggregates
WHERE date < CURRENT_DATE - INTERVAL '730 days';
```

### 7.3 User Data Export/Deletion

**GDPR compliance:**
```typescript
// Edge Function: /user/export_data
export async function exportUserData(userId: string) {
  const events = await supabase
    .from("analytics_events")
    .select("*")
    .eq("user_id", userId);
  
  const purchases = await supabase
    .from("purchases")
    .select("*")
    .eq("user_id", userId);
  
  // ... diğer veriler
  
  return {
    events: events.data,
    purchases: purchases.data,
    // ...
  };
}

// Edge Function: /user/delete_data
export async function deleteUserData(userId: string) {
  await supabase.from("analytics_events").delete().eq("user_id", userId);
  await supabase.from("purchases").delete().eq("user_id", userId);
  // ... cascade deletes
}
```

---

## 8. DEFINITION OF DONE

- [ ] Event tracking sistemi çalışıyor (client + server)
- [ ] Tüm core events tanımlı ve log ediliyor
- [ ] Metrikler hesaplanıyor (DAU/MAU/retention/revenue)
- [ ] Dashboard'lar kuruldu (Metabase)
- [ ] Anomali tespiti aktif (alertler çalışıyor)
- [ ] A/B test altyapısı hazır
- [ ] GDPR compliance sağlandı
- [ ] Documentation tamamlandı

---

Bu döküman, telemetri sisteminin tam teknik spesifikasyonunu, event taxonomy'sini, metric tanımlarını, anomali tespitini ve A/B test altyapısını içerir.
