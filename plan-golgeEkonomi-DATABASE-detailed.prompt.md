# Gölge Ekonomi — Database Schema ve Migration Plan

> Kaynak: Tüm sistemler için entegre schema
> Oyun: Gölge Krallık: Kadim Mühür'ün Çöküşü
> Amaç: PostgreSQL schema, indexler, RLS, triggerlar, migration stratejisi

---

## 1. DATABASE GENEL BAKIŞ

### 1.1 Mimari Prensipleri

**Design principles:**
- **Server-authoritative:** Tüm kritik veri server'da
- **Audit trail:** Her değişiklik loglanır
- **Row Level Security:** Kullanıcılar sadece kendi verisini görür
- **Denormalization:** Performance için stratejik denormalization
- **Partitioning:** Büyük tablolar partition edilir

### 1.2 Schema Organizasyonu

**Schema'lar:**
```sql
-- Core oyun verileri
CREATE SCHEMA IF NOT EXISTS game;

-- Analitik ve telemetri
CREATE SCHEMA IF NOT EXISTS analytics;

-- Admin ve moderation
CREATE SCHEMA IF NOT EXISTS admin;

-- Geçici ve cache
CREATE SCHEMA IF NOT EXISTS cache;
```

---

## 2. CORE GAME SCHEMA

### 2.1 Users & Auth

**users tablosu:**
```sql
CREATE TABLE game.users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Auth bilgileri (Supabase auth.users ile sync)
  email TEXT UNIQUE,
  username TEXT UNIQUE NOT NULL,
  password_hash TEXT,  -- Supabase auth kullanıyorsa null
  
  -- Profil
  display_name TEXT,
  avatar_url TEXT,
  title TEXT,  -- Kazanılan unvan
  bio TEXT,
  
  -- Oyun durumu
  level INT DEFAULT 1,
  xp BIGINT DEFAULT 0,
  gold BIGINT DEFAULT 1000,
  gems INT DEFAULT 100,
  energy INT DEFAULT 100,
  max_energy INT DEFAULT 100,
  
  -- Addiction sistemi
  addiction_level INT DEFAULT 0,
  last_potion_time TIMESTAMP,
  daily_potion_count INT DEFAULT 0,
  
  -- Hastane
  hospital_until TIMESTAMP,
  hospital_reason TEXT,
  
  -- Lonca
  guild_id UUID REFERENCES game.guilds(id),
  guild_role TEXT,  -- lord|commander|officer|member|squire
  guild_contribution INT DEFAULT 0,
  
  -- PvP
  pvp_wins INT DEFAULT 0,
  pvp_losses INT DEFAULT 0,
  pvp_rating INT DEFAULT 1000,
  
  -- Meta progression
  account_level INT DEFAULT 1,
  account_xp BIGINT DEFAULT 0,
  
  -- Flags
  is_banned BOOLEAN DEFAULT FALSE,
  is_muted BOOLEAN DEFAULT FALSE,
  mute_until TIMESTAMP,
  
  -- Timestamps
  last_login TIMESTAMP,
  last_daily_reset TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT valid_energy CHECK (energy >= 0 AND energy <= max_energy),
  CONSTRAINT valid_addiction CHECK (addiction_level >= 0 AND addiction_level <= 100),
  CONSTRAINT valid_level CHECK (level >= 1)
);

-- Indexes
CREATE INDEX idx_users_username ON game.users(username);
CREATE INDEX idx_users_guild ON game.users(guild_id);
CREATE INDEX idx_users_pvp_rating ON game.users(pvp_rating DESC);
CREATE INDEX idx_users_level ON game.users(level DESC);
CREATE INDEX idx_users_last_login ON game.users(last_login);

-- RLS
ALTER TABLE game.users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own data"
  ON game.users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON game.users FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (
    -- Sadece profil alanlarını güncelleyebilir (gold/gems vb. server-only)
    (NEW.gold = OLD.gold) AND
    (NEW.gems = OLD.gems) AND
    (NEW.energy = OLD.energy)
  );
```

**sessions tablosu:**
```sql
CREATE TABLE game.sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES game.users(id) ON DELETE CASCADE,
  
  -- Session bilgileri
  device_type TEXT,  -- android|ios|web
  device_id TEXT,
  ip_address INET,
  
  -- Timing
  start_time TIMESTAMP DEFAULT NOW(),
  end_time TIMESTAMP,
  duration_seconds INT,
  
  -- Context
  client_version TEXT,
  platform TEXT
);

CREATE INDEX idx_sessions_user ON game.sessions(user_id);
CREATE INDEX idx_sessions_start ON game.sessions(start_time DESC);
```

### 2.2 Inventory & Items

**items tablosu (static data):**
```sql
CREATE TABLE game.items (
  id TEXT PRIMARY KEY,
  
  -- Metadata
  name TEXT NOT NULL,
  description TEXT,
  category TEXT,  -- weapon|armor|consumable|material|rune
  rarity TEXT,  -- common|uncommon|rare|epic|legendary
  
  -- Stats (silah/zırh için)
  power INT DEFAULT 0,
  defense INT DEFAULT 0,
  
  -- Ekonomi
  base_price INT,
  vendor_sell_price INT,
  
  -- Flags
  tradeable BOOLEAN DEFAULT TRUE,
  stackable BOOLEAN DEFAULT FALSE,
  max_stack INT DEFAULT 1,
  
  -- Crafting
  craftable BOOLEAN DEFAULT FALSE,
  craft_time_seconds INT,
  
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_items_category ON game.items(category);
CREATE INDEX idx_items_rarity ON game.items(rarity);
```

**inventory tablosu:**
```sql
CREATE TABLE game.inventory (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES game.users(id) ON DELETE CASCADE,
  item_id TEXT REFERENCES game.items(id),
  
  -- Quantity (stackable için)
  quantity INT DEFAULT 1,
  
  -- Enhancement
  enhancement_level INT DEFAULT 0,  -- 0-10
  
  -- Binding
  bound_to_user BOOLEAN DEFAULT FALSE,
  
  -- Slot
  equipped_slot TEXT,  -- weapon|helmet|chest|legs|boots (null = envanterde)
  
  -- Metadata
  acquired_at TIMESTAMP DEFAULT NOW(),
  acquired_from TEXT,  -- quest|market|pvp|craft
  
  CONSTRAINT valid_enhancement CHECK (enhancement_level >= 0 AND enhancement_level <= 10),
  CONSTRAINT valid_quantity CHECK (quantity > 0)
);

CREATE INDEX idx_inventory_user ON game.inventory(user_id);
CREATE INDEX idx_inventory_equipped ON game.inventory(user_id, equipped_slot) WHERE equipped_slot IS NOT NULL;
CREATE INDEX idx_inventory_item ON game.inventory(item_id);

-- RLS
ALTER TABLE game.inventory ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own inventory"
  ON game.inventory FOR SELECT
  USING (auth.uid() = user_id);
```

### 2.3 Market

**market_orders tablosu:**
```sql
CREATE TABLE game.market_orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Order detayları
  user_id UUID REFERENCES game.users(id) ON DELETE CASCADE,
  item_id TEXT REFERENCES game.items(id),
  order_type TEXT NOT NULL,  -- buy|sell
  quantity INT NOT NULL,
  price_per_unit INT NOT NULL,
  
  -- Durum
  status TEXT DEFAULT 'active',  -- active|partially_filled|filled|cancelled|expired
  filled_quantity INT DEFAULT 0,
  remaining_quantity INT,
  
  -- Timing
  expires_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  CONSTRAINT valid_order_type CHECK (order_type IN ('buy', 'sell')),
  CONSTRAINT valid_status CHECK (status IN ('active', 'partially_filled', 'filled', 'cancelled', 'expired')),
  CONSTRAINT valid_quantity CHECK (quantity > 0),
  CONSTRAINT valid_price CHECK (price_per_unit > 0),
  CONSTRAINT valid_filled CHECK (filled_quantity >= 0 AND filled_quantity <= quantity)
);

CREATE INDEX idx_market_orders_user ON game.market_orders(user_id);
CREATE INDEX idx_market_orders_item ON game.market_orders(item_id, order_type, status);
CREATE INDEX idx_market_orders_status ON game.market_orders(status) WHERE status = 'active';
CREATE INDEX idx_market_orders_expires ON game.market_orders(expires_at) WHERE expires_at IS NOT NULL;

-- RLS
ALTER TABLE game.market_orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own orders"
  ON game.market_orders FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view active market orders"
  ON game.market_orders FOR SELECT
  USING (status = 'active');
```

**market_transactions tablosu:**
```sql
CREATE TABLE game.market_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Taraflar
  buyer_id UUID REFERENCES game.users(id),
  seller_id UUID REFERENCES game.users(id),
  
  -- Order referansları
  buy_order_id UUID REFERENCES game.market_orders(id),
  sell_order_id UUID REFERENCES game.market_orders(id),
  
  -- Trade detayları
  item_id TEXT REFERENCES game.items(id),
  quantity INT NOT NULL,
  price_per_unit INT NOT NULL,
  total_price INT NOT NULL,
  
  -- Fee
  market_fee INT NOT NULL,  -- %2
  
  -- Timestamp
  executed_at TIMESTAMP DEFAULT NOW(),
  
  CONSTRAINT valid_quantity CHECK (quantity > 0),
  CONSTRAINT valid_total CHECK (total_price = quantity * price_per_unit)
);

CREATE INDEX idx_market_transactions_buyer ON game.market_transactions(buyer_id);
CREATE INDEX idx_market_transactions_seller ON game.market_transactions(seller_id);
CREATE INDEX idx_market_transactions_item ON game.market_transactions(item_id, executed_at DESC);
CREATE INDEX idx_market_transactions_time ON game.market_transactions(executed_at DESC);
```

### 2.4 Quests & Dungeons

**quests tablosu (static):**
```sql
CREATE TABLE game.quests (
  id TEXT PRIMARY KEY,
  
  -- Metadata
  name TEXT NOT NULL,
  description TEXT,
  quest_type TEXT,  -- story|daily|weekly|guild
  difficulty TEXT,  -- easy|normal|hard|nightmare
  
  -- Requirements
  min_level INT DEFAULT 1,
  prerequisite_quest_id TEXT REFERENCES game.quests(id),
  
  -- Rewards
  gold_reward INT,
  xp_reward INT,
  item_rewards JSONB,  -- [{"item_id": "...", "quantity": 1}]
  
  -- Timing
  duration_minutes INT,
  energy_cost INT,
  
  created_at TIMESTAMP DEFAULT NOW()
);
```

**user_quests tablosu:**
```sql
CREATE TABLE game.user_quests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES game.users(id) ON DELETE CASCADE,
  quest_id TEXT REFERENCES game.quests(id),
  
  -- Progress
  status TEXT DEFAULT 'in_progress',  -- in_progress|completed|failed|abandoned
  progress JSONB,  -- Quest-specific progress data
  
  -- Timing
  started_at TIMESTAMP DEFAULT NOW(),
  completed_at TIMESTAMP,
  
  CONSTRAINT valid_status CHECK (status IN ('in_progress', 'completed', 'failed', 'abandoned'))
);

CREATE INDEX idx_user_quests_user ON game.user_quests(user_id, status);
CREATE INDEX idx_user_quests_quest ON game.user_quests(quest_id);

-- RLS
ALTER TABLE game.user_quests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own quests"
  ON game.user_quests FOR SELECT
  USING (auth.uid() = user_id);
```

**dungeons tablosu (static):**
```sql
CREATE TABLE game.dungeons (
  id TEXT PRIMARY KEY,
  
  -- Metadata
  name TEXT NOT NULL,
  description TEXT,
  difficulty TEXT,  -- easy|normal|hard|nightmare
  
  -- Requirements
  min_level INT,
  min_power INT,
  energy_cost INT,
  
  -- Rewards
  base_gold_min INT,
  base_gold_max INT,
  loot_table JSONB,  -- [{item_id, drop_rate}]
  
  -- Timing
  estimated_duration_minutes INT
);
```

**dungeon_runs tablosu:**
```sql
CREATE TABLE game.dungeon_runs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES game.users(id) ON DELETE CASCADE,
  dungeon_id TEXT REFERENCES game.dungeons(id),
  
  -- Outcome
  success BOOLEAN,
  duration_seconds INT,
  
  -- Rewards
  gold_earned INT,
  xp_earned INT,
  items_dropped JSONB,
  
  -- Timestamp
  completed_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_dungeon_runs_user ON game.dungeon_runs(user_id);
CREATE INDEX idx_dungeon_runs_dungeon ON game.dungeon_runs(dungeon_id, completed_at DESC);
```

### 2.5 PvP & Hospital

**pvp_battles tablosu:**
```sql
CREATE TABLE game.pvp_battles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Taraflar
  attacker_id UUID REFERENCES game.users(id),
  defender_id UUID REFERENCES game.users(id),
  
  -- Pre-battle stats
  attacker_power INT,
  defender_power INT,
  attacker_energy_before INT,
  
  -- Outcome
  outcome TEXT,  -- flawless|win|draw|loss|crush
  winner_id UUID REFERENCES game.users(id),
  
  -- Consequences
  gold_stolen INT,
  attacker_hospital_minutes INT DEFAULT 0,
  defender_hospital_minutes INT,
  
  -- Energy cost
  attacker_energy_cost INT,
  
  -- Timestamp
  battled_at TIMESTAMP DEFAULT NOW(),
  
  CONSTRAINT valid_outcome CHECK (outcome IN ('flawless', 'win', 'draw', 'loss', 'crush'))
);

CREATE INDEX idx_pvp_battles_attacker ON game.pvp_battles(attacker_id, battled_at DESC);
CREATE INDEX idx_pvp_battles_defender ON game.pvp_battles(defender_id, battled_at DESC);
CREATE INDEX idx_pvp_battles_time ON game.pvp_battles(battled_at DESC);
```

**hospital_records tablosu:**
```sql
CREATE TABLE game.hospital_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES game.users(id) ON DELETE CASCADE,
  
  -- Reason
  reason TEXT,  -- pvp_loss|pvp_attack|dungeon_failure
  related_battle_id UUID REFERENCES game.pvp_battles(id),
  
  -- Duration
  duration_minutes INT NOT NULL,
  release_time TIMESTAMP NOT NULL,
  
  -- Early release
  early_release BOOLEAN DEFAULT FALSE,
  early_release_gem_cost INT,
  early_release_time TIMESTAMP,
  
  -- Timestamp
  admitted_at TIMESTAMP DEFAULT NOW(),
  
  CONSTRAINT valid_duration CHECK (duration_minutes > 0)
);

CREATE INDEX idx_hospital_user ON game.hospital_records(user_id, release_time);
```

### 2.6 Guilds

**guilds tablosu:**
```sql
CREATE TABLE game.guilds (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Basic info
  name TEXT UNIQUE NOT NULL,
  tag TEXT UNIQUE NOT NULL,  -- 2-4 char
  description TEXT,
  logo_url TEXT,
  
  -- Founder
  founder_id UUID REFERENCES game.users(id),
  
  -- Stats
  member_count INT DEFAULT 1,
  max_members INT DEFAULT 50,
  level INT DEFAULT 1,
  xp BIGINT DEFAULT 0,
  
  -- Treasury
  treasury_gold BIGINT DEFAULT 0,
  
  -- Sezon stats
  season_points INT DEFAULT 0,
  
  -- Settings
  is_recruiting BOOLEAN DEFAULT TRUE,
  min_level_requirement INT DEFAULT 1,
  
  -- Timestamps
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  CONSTRAINT valid_tag_length CHECK (LENGTH(tag) >= 2 AND LENGTH(tag) <= 4),
  CONSTRAINT valid_member_count CHECK (member_count >= 1 AND member_count <= max_members)
);

CREATE INDEX idx_guilds_name ON game.guilds(name);
CREATE INDEX idx_guilds_season_points ON game.guilds(season_points DESC);
CREATE INDEX idx_guilds_recruiting ON game.guilds(is_recruiting) WHERE is_recruiting = TRUE;
```

**guild_activities tablosu:**
```sql
CREATE TABLE game.guild_activities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  guild_id UUID REFERENCES game.guilds(id) ON DELETE CASCADE,
  
  -- Activity
  activity_type TEXT,  -- member_join|member_leave|donation|level_up|war_win
  user_id UUID REFERENCES game.users(id),
  description TEXT,
  metadata JSONB,
  
  -- Timestamp
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_guild_activities_guild ON game.guild_activities(guild_id, created_at DESC);
```

**guild_wars tablosu:**
```sql
CREATE TABLE game.guild_wars (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Taraflar
  guild_1_id UUID REFERENCES game.guilds(id),
  guild_2_id UUID REFERENCES game.guilds(id),
  
  -- Scores
  guild_1_points INT DEFAULT 0,
  guild_2_points INT DEFAULT 0,
  
  -- Winner
  winner_guild_id UUID REFERENCES game.guilds(id),
  
  -- Timing
  start_time TIMESTAMP,
  end_time TIMESTAMP,
  status TEXT DEFAULT 'upcoming',  -- upcoming|active|completed|cancelled
  
  created_at TIMESTAMP DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('upcoming', 'active', 'completed', 'cancelled')),
  CONSTRAINT different_guilds CHECK (guild_1_id != guild_2_id)
);

CREATE INDEX idx_guild_wars_guilds ON game.guild_wars(guild_1_id, guild_2_id);
CREATE INDEX idx_guild_wars_status ON game.guild_wars(status);
```

### 2.7 Production & Buildings

**buildings tablosu:**
```sql
CREATE TABLE game.buildings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES game.users(id) ON DELETE CASCADE,
  
  -- Building type
  building_type TEXT NOT NULL,  -- farm|mine|forge|alchemy|workshop
  
  -- Level
  level INT DEFAULT 1,
  
  -- Production
  production_queue JSONB,  -- [{item_id, quantity, complete_at}]
  last_collected_at TIMESTAMP DEFAULT NOW(),
  
  -- Timestamps
  built_at TIMESTAMP DEFAULT NOW(),
  upgraded_at TIMESTAMP,
  
  CONSTRAINT valid_building_type CHECK (building_type IN ('farm', 'mine', 'forge', 'alchemy', 'workshop')),
  CONSTRAINT valid_level CHECK (level >= 1 AND level <= 10)
);

CREATE INDEX idx_buildings_user ON game.buildings(user_id);
CREATE INDEX idx_buildings_type ON game.buildings(building_type);

-- RLS
ALTER TABLE game.buildings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own buildings"
  ON game.buildings FOR SELECT
  USING (auth.uid() = user_id);
```

**production_history tablosu:**
```sql
CREATE TABLE game.production_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  building_id UUID REFERENCES game.buildings(id) ON DELETE CASCADE,
  user_id UUID REFERENCES game.users(id),
  
  -- Production
  item_id TEXT REFERENCES game.items(id),
  quantity INT,
  
  -- Timing
  started_at TIMESTAMP,
  completed_at TIMESTAMP DEFAULT NOW(),
  duration_seconds INT
);

CREATE INDEX idx_production_history_user ON game.production_history(user_id);
CREATE INDEX idx_production_history_building ON game.production_history(building_id);
```

### 2.8 Enhancement

**enhancement_history tablosu:**
```sql
CREATE TABLE game.enhancement_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES game.users(id) ON DELETE CASCADE,
  
  -- Item
  inventory_item_id UUID REFERENCES game.inventory(id) ON DELETE SET NULL,
  item_id TEXT REFERENCES game.items(id),
  
  -- Enhancement
  from_level INT,
  to_level INT,
  success BOOLEAN,
  
  -- Cost
  gold_cost INT,
  rune_used TEXT,  -- null|success|protection|special
  
  -- Outcome
  item_destroyed BOOLEAN DEFAULT FALSE,
  
  -- Timestamp
  enhanced_at TIMESTAMP DEFAULT NOW(),
  
  CONSTRAINT valid_levels CHECK (from_level >= 0 AND from_level <= 10 AND to_level >= 0 AND to_level <= 10)
);

CREATE INDEX idx_enhancement_history_user ON game.enhancement_history(user_id);
CREATE INDEX idx_enhancement_history_item ON game.enhancement_history(item_id);
CREATE INDEX idx_enhancement_history_time ON game.enhancement_history(enhanced_at DESC);
```

### 2.9 Chat

**chat_messages tablosu:**
```sql
CREATE TABLE game.chat_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Sender
  user_id UUID REFERENCES game.users(id) ON DELETE CASCADE,
  
  -- Channel
  channel_type TEXT NOT NULL,  -- global|guild|dm|trade
  channel_id TEXT,  -- guild_id veya dm için conversation_id
  
  -- Message
  content TEXT NOT NULL,
  
  -- Moderation
  flagged BOOLEAN DEFAULT FALSE,
  flagged_reason TEXT,
  deleted BOOLEAN DEFAULT FALSE,
  deleted_by UUID REFERENCES game.users(id),
  deleted_at TIMESTAMP,
  
  -- Timestamp
  sent_at TIMESTAMP DEFAULT NOW(),
  
  CONSTRAINT valid_channel CHECK (channel_type IN ('global', 'guild', 'dm', 'trade')),
  CONSTRAINT valid_content_length CHECK (LENGTH(content) >= 1 AND LENGTH(content) <= 500)
);

-- Partition by time (her ay)
CREATE TABLE game.chat_messages_2026_01 PARTITION OF game.chat_messages
  FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

CREATE INDEX idx_chat_messages_channel ON game.chat_messages(channel_type, channel_id, sent_at DESC);
CREATE INDEX idx_chat_messages_user ON game.chat_messages(user_id, sent_at DESC);
CREATE INDEX idx_chat_messages_flagged ON game.chat_messages(flagged) WHERE flagged = TRUE;
```

### 2.10 Seasons

**seasons tablosu:**
```sql
CREATE TABLE game.seasons (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Metadata
  season_number INT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  theme TEXT,
  
  -- Timing
  start_date TIMESTAMP NOT NULL,
  end_date TIMESTAMP NOT NULL,
  phase TEXT DEFAULT 'foundation',  -- foundation|competition|peak|final
  
  -- Status
  status TEXT DEFAULT 'upcoming',  -- upcoming|active|completed
  
  created_at TIMESTAMP DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('upcoming', 'active', 'completed')),
  CONSTRAINT valid_phase CHECK (phase IN ('foundation', 'competition', 'peak', 'final')),
  CONSTRAINT valid_dates CHECK (end_date > start_date)
);

CREATE INDEX idx_seasons_status ON game.seasons(status);
CREATE INDEX idx_seasons_dates ON game.seasons(start_date, end_date);
```

**season_leaderboards tablosu:**
```sql
CREATE TABLE game.season_leaderboards (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  season_id UUID REFERENCES game.seasons(id) ON DELETE CASCADE,
  
  -- Category
  category TEXT NOT NULL,  -- net_worth|pvp|quest|economy|guild
  
  -- Rankings (JSONB array for performance)
  rankings JSONB,  -- [{user_id, rank, score}]
  
  -- Timestamp
  last_updated TIMESTAMP DEFAULT NOW(),
  
  CONSTRAINT valid_category CHECK (category IN ('net_worth', 'pvp', 'quest', 'economy', 'guild'))
);

CREATE UNIQUE INDEX idx_season_leaderboards_unique ON game.season_leaderboards(season_id, category);
```

**battle_pass_progress tablosu:**
```sql
CREATE TABLE game.battle_pass_progress (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES game.users(id) ON DELETE CASCADE,
  season_id UUID REFERENCES game.seasons(id) ON DELETE CASCADE,
  
  -- Progress
  level INT DEFAULT 1,
  xp INT DEFAULT 0,
  
  -- Premium
  is_premium BOOLEAN DEFAULT FALSE,
  purchased_at TIMESTAMP,
  
  -- Rewards claimed
  free_rewards_claimed JSONB,  -- [1, 3, 5, ...] (levels)
  premium_rewards_claimed JSONB,  -- [1, 2, 3, ...]
  
  -- Timestamp
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  CONSTRAINT valid_level CHECK (level >= 1 AND level <= 50)
);

CREATE UNIQUE INDEX idx_battle_pass_user_season ON game.battle_pass_progress(user_id, season_id);
CREATE INDEX idx_battle_pass_season ON game.battle_pass_progress(season_id);
```

### 2.11 Purchases

**purchases tablosu:**
```sql
CREATE TABLE game.purchases (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES game.users(id) ON DELETE CASCADE,
  
  -- Package
  package_id TEXT NOT NULL,
  gems INT NOT NULL,
  
  -- Pricing
  price_usd NUMERIC NOT NULL,
  currency TEXT DEFAULT 'USD',
  
  -- Payment
  payment_method TEXT,  -- credit_card|google_pay|apple_pay|paypal
  payment_provider_transaction_id TEXT UNIQUE,
  
  -- Status
  status TEXT DEFAULT 'pending',  -- pending|completed|failed|refunded
  
  -- Metadata
  first_purchase BOOLEAN DEFAULT FALSE,
  country TEXT,
  
  -- Timestamps
  created_at TIMESTAMP DEFAULT NOW(),
  completed_at TIMESTAMP,
  
  CONSTRAINT valid_status CHECK (status IN ('pending', 'completed', 'failed', 'refunded'))
);

CREATE INDEX idx_purchases_user ON game.purchases(user_id, created_at DESC);
CREATE INDEX idx_purchases_status ON game.purchases(status);
CREATE INDEX idx_purchases_time ON game.purchases(completed_at DESC) WHERE status = 'completed';
```

---

## 3. ANALYTICS SCHEMA

### 3.1 Events

**analytics_events tablosu:**
```sql
CREATE TABLE analytics.analytics_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Event
  event TEXT NOT NULL,
  user_id UUID REFERENCES game.users(id) ON DELETE CASCADE,
  
  -- Properties
  properties JSONB,
  
  -- Context
  session_id UUID,
  device_type TEXT,
  
  -- Timestamp
  timestamp TIMESTAMP DEFAULT NOW()
) PARTITION BY RANGE (timestamp);

-- Partitions (her ay)
CREATE TABLE analytics.analytics_events_2026_01 PARTITION OF analytics.analytics_events
  FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

CREATE INDEX idx_analytics_events_user ON analytics.analytics_events(user_id, timestamp DESC);
CREATE INDEX idx_analytics_events_event ON analytics.analytics_events(event, timestamp DESC);
CREATE INDEX idx_analytics_events_time ON analytics.analytics_events(timestamp DESC);
```

### 3.2 Aggregates

**analytics_daily_aggregates tablosu:**
```sql
CREATE TABLE analytics.analytics_daily_aggregates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Date
  date DATE NOT NULL,
  
  -- User metrics
  dau INT,
  new_users INT,
  
  -- Engagement
  avg_session_duration_seconds INT,
  total_sessions INT,
  
  -- Economy
  total_gold_earned BIGINT,
  total_gold_spent BIGINT,
  
  -- Monetization
  revenue_usd NUMERIC,
  paying_users INT,
  
  -- Timestamp
  calculated_at TIMESTAMP DEFAULT NOW(),
  
  CONSTRAINT unique_date UNIQUE (date)
);

CREATE INDEX idx_analytics_daily_date ON analytics.analytics_daily_aggregates(date DESC);
```

---

## 4. ADMIN SCHEMA

### 4.1 Audit Logs

**audit_logs tablosu:**
```sql
CREATE TABLE admin.audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Actor
  user_id UUID REFERENCES game.users(id),
  admin_user_id UUID REFERENCES game.users(id),
  
  -- Action
  action TEXT NOT NULL,  -- insert|update|delete|ban|unban|mute|etc.
  table_name TEXT,
  record_id UUID,
  
  -- Changes
  old_values JSONB,
  new_values JSONB,
  
  -- Context
  ip_address INET,
  user_agent TEXT,
  
  -- Timestamp
  timestamp TIMESTAMP DEFAULT NOW()
) PARTITION BY RANGE (timestamp);

CREATE TABLE admin.audit_logs_2026_01 PARTITION OF admin.audit_logs
  FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

CREATE INDEX idx_audit_logs_user ON admin.audit_logs(user_id, timestamp DESC);
CREATE INDEX idx_audit_logs_admin ON admin.audit_logs(admin_user_id, timestamp DESC);
CREATE INDEX idx_audit_logs_action ON admin.audit_logs(action, timestamp DESC);
```

### 4.2 Bans & Moderation

**bans tablosu:**
```sql
CREATE TABLE admin.bans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES game.users(id) ON DELETE CASCADE,
  
  -- Ban details
  reason TEXT NOT NULL,
  evidence TEXT,
  
  -- Duration
  banned_until TIMESTAMP,  -- null = permanent
  
  -- Issuer
  banned_by UUID REFERENCES game.users(id),
  
  -- Status
  active BOOLEAN DEFAULT TRUE,
  
  -- Timestamps
  banned_at TIMESTAMP DEFAULT NOW(),
  unbanned_at TIMESTAMP
);

CREATE INDEX idx_bans_user ON admin.bans(user_id);
CREATE INDEX idx_bans_active ON admin.bans(active) WHERE active = TRUE;
```

---

## 5. TRIGGERS & FUNCTIONS

### 5.1 Updated_at Trigger

**Auto-update updated_at:**
```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON game.users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_guilds_updated_at BEFORE UPDATE ON game.guilds
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_market_orders_updated_at BEFORE UPDATE ON game.market_orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

### 5.2 Audit Trigger

**Auto-audit changes:**
```sql
CREATE OR REPLACE FUNCTION audit_trigger_func()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'UPDATE') THEN
    INSERT INTO admin.audit_logs (user_id, action, table_name, record_id, old_values, new_values)
    VALUES (
      COALESCE(NEW.user_id, OLD.user_id),
      'update',
      TG_TABLE_NAME,
      OLD.id,
      to_jsonb(OLD),
      to_jsonb(NEW)
    );
    RETURN NEW;
  ELSIF (TG_OP = 'DELETE') THEN
    INSERT INTO admin.audit_logs (user_id, action, table_name, record_id, old_values)
    VALUES (
      OLD.user_id,
      'delete',
      TG_TABLE_NAME,
      OLD.id,
      to_jsonb(OLD)
    );
    RETURN OLD;
  ELSIF (TG_OP = 'INSERT') THEN
    INSERT INTO admin.audit_logs (user_id, action, table_name, record_id, new_values)
    VALUES (
      NEW.user_id,
      'insert',
      TG_TABLE_NAME,
      NEW.id,
      to_jsonb(NEW)
    );
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Apply to critical tables
CREATE TRIGGER audit_users AFTER INSERT OR UPDATE OR DELETE ON game.users
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

CREATE TRIGGER audit_purchases AFTER INSERT OR UPDATE OR DELETE ON game.purchases
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();
```

### 5.3 Gold Transaction Validation

**Prevent negative gold:**
```sql
CREATE OR REPLACE FUNCTION validate_gold_transaction()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.gold < 0 THEN
    RAISE EXCEPTION 'Gold cannot be negative: user_id=%', NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validate_gold BEFORE UPDATE ON game.users
  FOR EACH ROW EXECUTE FUNCTION validate_gold_transaction();
```

---

## 6. MIGRATION STRATEGY

### 6.1 Migration Tool: Flyway

**flyway.conf:**
```
flyway.url=jdbc:postgresql://db.xxx.supabase.co:5432/postgres
flyway.user=postgres
flyway.password=${SUPABASE_DB_PASSWORD}
flyway.schemas=game,analytics,admin
flyway.locations=filesystem:./migrations
```

### 6.2 Versioned Migrations

**V001__initial_schema.sql:**
```sql
-- Create schemas
CREATE SCHEMA IF NOT EXISTS game;
CREATE SCHEMA IF NOT EXISTS analytics;
CREATE SCHEMA IF NOT EXISTS admin;

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create tables (users, items, etc.)
-- ... (full schema creation)
```

**V002__add_seasons.sql:**
```sql
CREATE TABLE game.seasons (...);
CREATE TABLE game.season_leaderboards (...);
CREATE TABLE game.battle_pass_progress (...);
```

**V003__add_analytics_partitions.sql:**
```sql
CREATE TABLE analytics.analytics_events_2026_02 PARTITION OF analytics.analytics_events
  FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
```

### 6.3 Rollback Strategy

**Down migrations (manual):**
```sql
-- V002__add_seasons.sql rollback
DROP TABLE game.battle_pass_progress;
DROP TABLE game.season_leaderboards;
DROP TABLE game.seasons;
```

---

## 7. PERFORMANCE OPTIMIZATION

### 7.1 Indexing Strategy

**Composite indexes:**
```sql
-- Hot query: Find active market orders for item
CREATE INDEX idx_market_orders_item_active 
  ON game.market_orders(item_id, status, price_per_unit)
  WHERE status = 'active';

-- Hot query: User's recent PvP battles
CREATE INDEX idx_pvp_battles_user_time
  ON game.pvp_battles(attacker_id, battled_at DESC)
  INCLUDE (outcome, gold_stolen);
```

### 7.2 Partitioning

**Time-based partitioning (chat, analytics, audit):**
```sql
-- Auto-create partitions (cron job)
CREATE OR REPLACE FUNCTION create_next_month_partitions()
RETURNS void AS $$
DECLARE
  next_month DATE := DATE_TRUNC('month', CURRENT_DATE + INTERVAL '1 month');
  month_after DATE := next_month + INTERVAL '1 month';
BEGIN
  -- Analytics events
  EXECUTE format('
    CREATE TABLE IF NOT EXISTS analytics.analytics_events_%s PARTITION OF analytics.analytics_events
    FOR VALUES FROM (%L) TO (%L)
  ', TO_CHAR(next_month, 'YYYY_MM'), next_month, month_after);
  
  -- Chat messages
  EXECUTE format('
    CREATE TABLE IF NOT EXISTS game.chat_messages_%s PARTITION OF game.chat_messages
    FOR VALUES FROM (%L) TO (%L)
  ', TO_CHAR(next_month, 'YYYY_MM'), next_month, month_after);
END;
$$ LANGUAGE plpgsql;

-- Schedule (cron)
SELECT cron.schedule('create_partitions', '0 0 1 * *', 'SELECT create_next_month_partitions()');
```

### 7.3 Materialized Views

**Leaderboard cache:**
```sql
CREATE MATERIALIZED VIEW game.pvp_leaderboard AS
SELECT 
  u.id,
  u.username,
  u.pvp_rating,
  u.pvp_wins,
  u.pvp_losses,
  RANK() OVER (ORDER BY u.pvp_rating DESC) as rank
FROM game.users u
WHERE u.is_banned = FALSE
ORDER BY u.pvp_rating DESC
LIMIT 100;

CREATE UNIQUE INDEX idx_pvp_leaderboard_id ON game.pvp_leaderboard(id);

-- Refresh her 5 dakika
SELECT cron.schedule('refresh_pvp_leaderboard', '*/5 * * * *', 'REFRESH MATERIALIZED VIEW CONCURRENTLY game.pvp_leaderboard');
```

---

## 8. DEFINITION OF DONE

- [ ] Tüm tablolar oluşturuldu
- [ ] Index'ler optimize edildi
- [ ] RLS policy'leri tanımlandı
- [ ] Trigger'lar çalışıyor (audit, validation)
- [ ] Partitioning yapılandırıldı
- [ ] Migration tool kuruldu
- [ ] Backup stratejisi belirlendi
- [ ] Performance test yapıldı

---

Bu döküman, Gölge Krallık oyununun tüm veritabanı şemasını, index stratejisini, RLS policy'lerini, trigger'larını ve migration planını içerir.
