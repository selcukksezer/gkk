-- ================================================================================
-- GÖLGE KRALLIK: KADİM MÜHÜR'ÜN ÇÖKÜŞÜ
-- COMPLETE DATABASE SCHEMA MIGRATION (Idempotent)
-- ================================================================================
-- Tarih: 2026-02-07
-- Kaynaklar: GOLGE-KRALLIK-MASTER-GDD.md + plan-golgeEkonomi-DATABASE-detailed.prompt.md
-- 
-- Bu script:
--   • Tablo varsa hata VERMEZ (IF NOT EXISTS)
--   • Sütun eksikse EKLER (ADD COLUMN IF NOT EXISTS)
--   • Index varsa atlar (IF NOT EXISTS)
--   • Policy varsa drop edip yeniden oluşturur
--   • RPC fonksiyonları CREATE OR REPLACE ile günceller
--   • Trigger varsa drop edip yeniden oluşturur
--
-- SQL Editörde (Supabase Dashboard veya psql) doğrudan çalıştırılabilir.
-- ================================================================================

-- ============================================================
-- 0. EXTENSIONS & SCHEMAS
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE SCHEMA IF NOT EXISTS game;
CREATE SCHEMA IF NOT EXISTS analytics;
CREATE SCHEMA IF NOT EXISTS admin;

-- ============================================================
-- 1. GAME.USERS (Ana Oyuncu Tablosu)
-- ============================================================

CREATE TABLE IF NOT EXISTS game.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_id UUID UNIQUE,
    email TEXT UNIQUE,
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT,
    display_name TEXT,
    avatar_url TEXT,
    title TEXT,
    bio TEXT,
    level INT DEFAULT 1,
    xp BIGINT DEFAULT 0,
    gold BIGINT DEFAULT 1000,
    gems INT DEFAULT 100,
    energy INT DEFAULT 100,
    max_energy INT DEFAULT 100,
    energy_last_updated TIMESTAMPTZ DEFAULT NOW(),
    addiction_level INT DEFAULT 0,
    tolerance INT DEFAULT 0,
    last_potion_time TIMESTAMP,
    daily_potion_count INT DEFAULT 0,
    last_tolerance_decay TIMESTAMPTZ,
    hospital_until TIMESTAMP,
    hospital_reason TEXT,
    in_hospital BOOLEAN DEFAULT FALSE,
    prison_until TIMESTAMPTZ,
    prison_reason TEXT,
    in_prison BOOLEAN DEFAULT FALSE,
    guild_id UUID,
    guild_role TEXT,
    guild_contribution INT DEFAULT 0,
    pvp_wins INT DEFAULT 0,
    pvp_losses INT DEFAULT 0,
    pvp_rating INT DEFAULT 1000,
    reputation INT DEFAULT 0,
    account_level INT DEFAULT 1,
    account_xp BIGINT DEFAULT 0,
    attack INT DEFAULT 10,
    defense INT DEFAULT 10,
    health INT DEFAULT 100,
    max_health INT DEFAULT 100,
    power INT DEFAULT 0,
    is_online BOOLEAN DEFAULT FALSE,
    is_banned BOOLEAN DEFAULT FALSE,
    is_muted BOOLEAN DEFAULT FALSE,
    mute_until TIMESTAMP,
    ban_reason TEXT,
    banned_until TIMESTAMPTZ,
    tutorial_completed BOOLEAN DEFAULT FALSE,
    last_daily_reward TIMESTAMPTZ,
    total_playtime_seconds INT DEFAULT 0,
    total_playtime INT DEFAULT 0,
    referral_code TEXT UNIQUE,
    referred_by UUID,
    last_login TIMESTAMP,
    last_login_at TIMESTAMPTZ DEFAULT NOW(),
    last_daily_reset TIMESTAMP,
    last_energy_regen TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT valid_energy CHECK (energy >= 0 AND energy <= max_energy),
    CONSTRAINT valid_level CHECK (level >= 1)
);

-- Sütun ekleme (tablo zaten varsa eksik sütunları ekle)
DO $$
BEGIN
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS auth_id UUID UNIQUE;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS email TEXT;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS password_hash TEXT;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS display_name TEXT;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS avatar_url TEXT;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS title TEXT;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS bio TEXT;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS level INT DEFAULT 1;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS xp BIGINT DEFAULT 0;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS gold BIGINT DEFAULT 1000;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS gems INT DEFAULT 100;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS energy INT DEFAULT 100;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS max_energy INT DEFAULT 100;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS energy_last_updated TIMESTAMPTZ DEFAULT NOW();
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS addiction_level INT DEFAULT 0;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS tolerance INT DEFAULT 0;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS last_potion_time TIMESTAMP;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS daily_potion_count INT DEFAULT 0;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS last_tolerance_decay TIMESTAMPTZ;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS hospital_until TIMESTAMP;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS hospital_reason TEXT;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS in_hospital BOOLEAN DEFAULT FALSE;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS prison_until TIMESTAMPTZ;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS prison_reason TEXT;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS in_prison BOOLEAN DEFAULT FALSE;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS guild_id UUID;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS guild_role TEXT;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS guild_contribution INT DEFAULT 0;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS pvp_wins INT DEFAULT 0;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS pvp_losses INT DEFAULT 0;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS pvp_rating INT DEFAULT 1000;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS reputation INT DEFAULT 0;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS account_level INT DEFAULT 1;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS account_xp BIGINT DEFAULT 0;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS attack INT DEFAULT 10;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS defense INT DEFAULT 10;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS health INT DEFAULT 100;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS max_health INT DEFAULT 100;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS power INT DEFAULT 0;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS is_online BOOLEAN DEFAULT FALSE;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS is_banned BOOLEAN DEFAULT FALSE;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS is_muted BOOLEAN DEFAULT FALSE;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS mute_until TIMESTAMP;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS ban_reason TEXT;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS banned_until TIMESTAMPTZ;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS tutorial_completed BOOLEAN DEFAULT FALSE;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS last_daily_reward TIMESTAMPTZ;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS total_playtime_seconds INT DEFAULT 0;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS total_playtime INT DEFAULT 0;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS referral_code TEXT;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS referred_by UUID;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS last_login TIMESTAMP;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMPTZ DEFAULT NOW();
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS last_daily_reset TIMESTAMP;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS last_energy_regen TIMESTAMPTZ;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_users_username ON game.users(username);
CREATE INDEX IF NOT EXISTS idx_users_auth_id ON game.users(auth_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON game.users(email);
CREATE INDEX IF NOT EXISTS idx_users_guild ON game.users(guild_id);
CREATE INDEX IF NOT EXISTS idx_users_pvp_rating ON game.users(pvp_rating DESC);
CREATE INDEX IF NOT EXISTS idx_users_level ON game.users(level DESC);
CREATE INDEX IF NOT EXISTS idx_users_last_login ON game.users(last_login);

ALTER TABLE game.users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS users_select_own ON game.users;
CREATE POLICY users_select_own ON game.users FOR SELECT USING (auth.uid() = id OR auth.uid() = auth_id);

DROP POLICY IF EXISTS users_update_own ON game.users;
CREATE POLICY users_update_own ON game.users FOR UPDATE USING (auth.uid() = id OR auth.uid() = auth_id);

DROP POLICY IF EXISTS users_select_public ON game.users;
CREATE POLICY users_select_public ON game.users FOR SELECT USING (true);

-- ============================================================
-- 2. GAME.SESSIONS
-- ============================================================

CREATE TABLE IF NOT EXISTS game.sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES game.users(id) ON DELETE CASCADE,
    device_type TEXT,
    device_id TEXT,
    ip_address INET,
    start_time TIMESTAMP DEFAULT NOW(),
    end_time TIMESTAMP,
    duration_seconds INT,
    client_version TEXT,
    platform TEXT
);

DO $$
BEGIN
    ALTER TABLE game.sessions ADD COLUMN IF NOT EXISTS device_type TEXT;
    ALTER TABLE game.sessions ADD COLUMN IF NOT EXISTS device_id TEXT;
    ALTER TABLE game.sessions ADD COLUMN IF NOT EXISTS ip_address INET;
    ALTER TABLE game.sessions ADD COLUMN IF NOT EXISTS client_version TEXT;
    ALTER TABLE game.sessions ADD COLUMN IF NOT EXISTS platform TEXT;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_sessions_user ON game.sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_start ON game.sessions(start_time DESC);

-- ============================================================
-- 3. PUBLIC.ITEMS (Item Tanımları - Statik Veri)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.items (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    icon TEXT,
    type TEXT,
    rarity TEXT DEFAULT 'COMMON',
    equip_slot TEXT,
    weapon_type TEXT,
    armor_type TEXT,
    material_type TEXT,
    potion_type TEXT,
    attack INT DEFAULT 0,
    defense INT DEFAULT 0,
    health INT DEFAULT 0,
    power INT DEFAULT 0,
    energy_restore INT DEFAULT 0,
    heal_amount INT DEFAULT 0,
    can_enhance BOOLEAN DEFAULT FALSE,
    max_enhancement INT DEFAULT 0,
    base_price INT DEFAULT 0,
    vendor_sell_price INT DEFAULT 0,
    is_tradeable BOOLEAN DEFAULT TRUE,
    is_stackable BOOLEAN DEFAULT TRUE,
    max_stack INT DEFAULT 999,
    required_level INT DEFAULT 1,
    required_class TEXT,
    tolerance_increase INT DEFAULT 0,
    overdose_risk NUMERIC DEFAULT 0,
    production_building_type TEXT,
    production_rate_per_hour INT DEFAULT 0,
    production_required_level INT DEFAULT 0,
    health_restore INT DEFAULT 0,
    mana_restore INT DEFAULT 0,
    buff_duration INT DEFAULT 0,
    recipe_requirements JSONB DEFAULT '{}'::jsonb,
    recipe_result_item_id TEXT,
    recipe_building_type TEXT,
    recipe_production_time INT DEFAULT 0,
    recipe_required_level INT DEFAULT 0,
    rune_enhancement_type TEXT,
    rune_success_bonus DOUBLE PRECISION DEFAULT 0.0,
    rune_destruction_reduction DOUBLE PRECISION DEFAULT 0.0,
    cosmetic_effect TEXT,
    cosmetic_bind_on_pickup BOOLEAN DEFAULT FALSE,
    cosmetic_showcase_only BOOLEAN DEFAULT FALSE,
    craftable BOOLEAN DEFAULT FALSE,
    craft_time_seconds INT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

DO $$
BEGIN
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS icon TEXT;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS equip_slot TEXT;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS weapon_type TEXT;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS armor_type TEXT;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS material_type TEXT;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS potion_type TEXT;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS attack INT DEFAULT 0;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS defense INT DEFAULT 0;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS health INT DEFAULT 0;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS power INT DEFAULT 0;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS energy_restore INT DEFAULT 0;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS heal_amount INT DEFAULT 0;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS can_enhance BOOLEAN DEFAULT FALSE;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS max_enhancement INT DEFAULT 0;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS base_price INT DEFAULT 0;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS vendor_sell_price INT DEFAULT 0;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS is_tradeable BOOLEAN DEFAULT TRUE;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS is_stackable BOOLEAN DEFAULT TRUE;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS max_stack INT DEFAULT 999;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS required_level INT DEFAULT 1;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS required_class TEXT;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS tolerance_increase INT DEFAULT 0;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS overdose_risk NUMERIC DEFAULT 0;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS production_building_type TEXT;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS production_rate_per_hour INT DEFAULT 0;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS production_required_level INT DEFAULT 0;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS health_restore INT DEFAULT 0;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS mana_restore INT DEFAULT 0;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS buff_duration INT DEFAULT 0;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS recipe_requirements JSONB DEFAULT '{}'::jsonb;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS recipe_result_item_id TEXT;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS recipe_building_type TEXT;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS recipe_production_time INT DEFAULT 0;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS recipe_required_level INT DEFAULT 0;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS rune_enhancement_type TEXT;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS rune_success_bonus DOUBLE PRECISION DEFAULT 0.0;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS rune_destruction_reduction DOUBLE PRECISION DEFAULT 0.0;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS cosmetic_effect TEXT;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS cosmetic_bind_on_pickup BOOLEAN DEFAULT FALSE;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS cosmetic_showcase_only BOOLEAN DEFAULT FALSE;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS craftable BOOLEAN DEFAULT FALSE;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS craft_time_seconds INT;
    ALTER TABLE public.items ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_items_type ON public.items(type);
CREATE INDEX IF NOT EXISTS idx_items_rarity ON public.items(rarity);
CREATE INDEX IF NOT EXISTS idx_items_required_level ON public.items(required_level);
CREATE INDEX IF NOT EXISTS idx_items_equip_slot ON public.items(equip_slot);
CREATE INDEX IF NOT EXISTS idx_items_production_building_type ON public.items(production_building_type);

ALTER TABLE public.items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Items are viewable by everyone" ON public.items;
CREATE POLICY "Items are viewable by everyone" ON public.items FOR SELECT USING (true);
DROP POLICY IF EXISTS "Items insertable by authenticated" ON public.items;
CREATE POLICY "Items insertable by authenticated" ON public.items FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- ============================================================
-- 4. PUBLIC.INVENTORY (Oyuncu Envanteri)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.inventory (
    row_id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE DEFAULT auth.uid(),
    item_id TEXT REFERENCES public.items(id),
    quantity INT DEFAULT 1,
    enhancement_level INT DEFAULT 0,
    is_equipped BOOLEAN DEFAULT FALSE,
    equip_slot TEXT,
    slot_position INT,
    obtained_at BIGINT,
    is_favorite BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

DO $$
BEGIN
    ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS item_id TEXT;
    ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS enhancement_level INT DEFAULT 0;
    ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS is_equipped BOOLEAN DEFAULT FALSE;
    ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS equip_slot TEXT;
    ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS slot_position INT;
    ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS obtained_at BIGINT;
    ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS is_favorite BOOLEAN DEFAULT FALSE;
    ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_inventory_user ON public.inventory(user_id);
CREATE INDEX IF NOT EXISTS idx_inventory_item ON public.inventory(item_id);
CREATE INDEX IF NOT EXISTS idx_inventory_equipped ON public.inventory(user_id) WHERE is_equipped = TRUE;
CREATE INDEX IF NOT EXISTS idx_inventory_slot_position ON public.inventory(user_id, slot_position);

ALTER TABLE public.inventory ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users manage own inventory" ON public.inventory;
CREATE POLICY "Users manage own inventory" ON public.inventory FOR ALL USING (auth.uid() = user_id);

-- Unique index'ler (equip slot ve slot_position çakışma önleme)
DROP INDEX IF EXISTS idx_inventory_user_equip_slot_unique;
CREATE UNIQUE INDEX IF NOT EXISTS idx_inventory_user_equip_slot_unique
    ON public.inventory(user_id, equip_slot) WHERE is_equipped = TRUE AND equip_slot IS NOT NULL;

DROP INDEX IF EXISTS idx_inventory_user_slot_unique;
CREATE UNIQUE INDEX IF NOT EXISTS idx_inventory_user_slot_unique
    ON public.inventory(user_id, slot_position) WHERE slot_position IS NOT NULL AND is_equipped = FALSE;

-- ============================================================
-- 5. PUBLIC.FACILITIES (Üretim Tesisleri)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.facilities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    level INT NOT NULL DEFAULT 1,
    suspicion INT NOT NULL DEFAULT 0 CHECK (suspicion >= 0 AND suspicion <= 100),
    is_active BOOLEAN DEFAULT TRUE,
    is_unlocked BOOLEAN DEFAULT TRUE,
    production_started_at TIMESTAMPTZ,
    last_production TIMESTAMPTZ,
    last_production_collected_at TIMESTAMPTZ,
    offline_production_cap INT DEFAULT 720,
    workers INT DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, type)
);

DO $$
BEGIN
    ALTER TABLE public.facilities ADD COLUMN IF NOT EXISTS is_unlocked BOOLEAN DEFAULT TRUE;
    ALTER TABLE public.facilities ADD COLUMN IF NOT EXISTS production_started_at TIMESTAMPTZ;
    ALTER TABLE public.facilities ADD COLUMN IF NOT EXISTS last_production TIMESTAMPTZ;
    ALTER TABLE public.facilities ADD COLUMN IF NOT EXISTS last_production_collected_at TIMESTAMPTZ;
    ALTER TABLE public.facilities ADD COLUMN IF NOT EXISTS offline_production_cap INT DEFAULT 720;
    ALTER TABLE public.facilities ADD COLUMN IF NOT EXISTS workers INT DEFAULT 1;
    ALTER TABLE public.facilities ADD COLUMN IF NOT EXISTS suspicion_level INT DEFAULT 0;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_facilities_user ON public.facilities(user_id);
CREATE INDEX IF NOT EXISTS idx_facilities_type ON public.facilities(type);

ALTER TABLE public.facilities ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "facilities_select_own" ON public.facilities;
CREATE POLICY "facilities_select_own" ON public.facilities FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "facilities_manage_own" ON public.facilities;
CREATE POLICY "facilities_manage_own" ON public.facilities FOR ALL USING (auth.uid() = user_id);

-- ============================================================
-- 6. PUBLIC.FACILITY_RECIPES (Üretim Reçeteleri)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.facility_recipes (
    id TEXT PRIMARY KEY,
    facility_type TEXT NOT NULL,
    output_item_id TEXT NOT NULL,
    output_quantity INT NOT NULL DEFAULT 1,
    input_materials JSONB DEFAULT '{}'::jsonb,
    gold_cost INT DEFAULT 0,
    duration_seconds INT NOT NULL DEFAULT 3600,
    required_level INT DEFAULT 1,
    success_rate INT DEFAULT 100,
    base_suspicion_increase INT DEFAULT 0,
    min_facility_level INT DEFAULT 1,
    production_speed_bonus NUMERIC DEFAULT 0,
    rarity_distribution JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

DO $$
BEGIN
    ALTER TABLE public.facility_recipes ADD COLUMN IF NOT EXISTS min_facility_level INT DEFAULT 1;
    ALTER TABLE public.facility_recipes ADD COLUMN IF NOT EXISTS production_speed_bonus NUMERIC DEFAULT 0;
    ALTER TABLE public.facility_recipes ADD COLUMN IF NOT EXISTS rarity_distribution JSONB;
    ALTER TABLE public.facility_recipes ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_facility_recipes_type ON public.facility_recipes(facility_type);
CREATE INDEX IF NOT EXISTS idx_facility_recipes_output ON public.facility_recipes(output_item_id);
CREATE INDEX IF NOT EXISTS idx_facility_recipes_level ON public.facility_recipes(required_level);

-- ============================================================
-- 7. PUBLIC.FACILITY_QUEUE (Üretim Kuyruğu)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.facility_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    facility_id UUID NOT NULL REFERENCES public.facilities(id) ON DELETE CASCADE,
    recipe_id TEXT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    started_at BIGINT NOT NULL DEFAULT EXTRACT(EPOCH FROM NOW())::BIGINT,
    completed_at BIGINT NOT NULL DEFAULT EXTRACT(EPOCH FROM NOW())::BIGINT,
    status TEXT DEFAULT 'in_progress',
    collected BOOLEAN DEFAULT FALSE,
    is_raided BOOLEAN DEFAULT FALSE,
    is_burned BOOLEAN DEFAULT FALSE
);

DO $$
BEGIN
    ALTER TABLE public.facility_queue ADD COLUMN IF NOT EXISTS collected BOOLEAN DEFAULT FALSE;
    ALTER TABLE public.facility_queue ADD COLUMN IF NOT EXISTS is_raided BOOLEAN DEFAULT FALSE;
    ALTER TABLE public.facility_queue ADD COLUMN IF NOT EXISTS is_burned BOOLEAN DEFAULT FALSE;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_queue_facility ON public.facility_queue(facility_id);
CREATE INDEX IF NOT EXISTS idx_queue_status ON public.facility_queue(status);

-- ============================================================
-- 8. PUBLIC.MARKET_ORDERS (Pazar Emirleri)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.market_orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    seller_id UUID REFERENCES auth.users(id),
    buyer_id UUID REFERENCES auth.users(id),
    item_id TEXT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    price INT NOT NULL CHECK (price >= 0),
    total_price INT,
    status TEXT DEFAULT 'active',
    region_id INT DEFAULT 1,
    listed_at BIGINT DEFAULT EXTRACT(EPOCH FROM NOW())::BIGINT,
    sold_at BIGINT,
    expires_at BIGINT,
    item_data JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

DO $$
BEGIN
    ALTER TABLE public.market_orders ADD COLUMN IF NOT EXISTS buyer_id UUID;
    ALTER TABLE public.market_orders ADD COLUMN IF NOT EXISTS total_price INT;
    ALTER TABLE public.market_orders ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active';
    ALTER TABLE public.market_orders ADD COLUMN IF NOT EXISTS region_id INT DEFAULT 1;
    ALTER TABLE public.market_orders ADD COLUMN IF NOT EXISTS sold_at BIGINT;
    ALTER TABLE public.market_orders ADD COLUMN IF NOT EXISTS expires_at BIGINT;
    ALTER TABLE public.market_orders ADD COLUMN IF NOT EXISTS item_data JSONB DEFAULT '{}'::jsonb;
    ALTER TABLE public.market_orders ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_market_orders_user ON public.market_orders(seller_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.market_orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_item ON public.market_orders(item_id) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_orders_price ON public.market_orders(price) WHERE status = 'active';

ALTER TABLE public.market_orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public read market orders" ON public.market_orders;
CREATE POLICY "Public read market orders" ON public.market_orders FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users manage own orders" ON public.market_orders;
CREATE POLICY "Users manage own orders" ON public.market_orders FOR ALL USING (auth.uid() = seller_id);

-- ============================================================
-- 9. PUBLIC.MARKET_HISTORY (Pazar İşlem Geçmişi)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.market_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    item_id TEXT NOT NULL,
    seller_id UUID NOT NULL,
    buyer_id UUID NOT NULL,
    quantity INT NOT NULL,
    price INT NOT NULL,
    total_price INT,
    market_fee INT,
    sold_at TIMESTAMPTZ DEFAULT NOW()
);

DO $$
BEGIN
    ALTER TABLE public.market_history ADD COLUMN IF NOT EXISTS total_price INT;
    ALTER TABLE public.market_history ADD COLUMN IF NOT EXISTS market_fee INT;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_market_history_buyer ON public.market_history(buyer_id);
CREATE INDEX IF NOT EXISTS idx_market_history_seller ON public.market_history(seller_id);
CREATE INDEX IF NOT EXISTS idx_market_history_item ON public.market_history(item_id);
CREATE INDEX IF NOT EXISTS idx_market_history_time ON public.market_history(sold_at DESC);

ALTER TABLE public.market_history ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public read market history" ON public.market_history;
CREATE POLICY "Public read market history" ON public.market_history FOR SELECT USING (true);

-- ============================================================
-- 10. PUBLIC.GUILDS (Loncalar)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.guilds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    tag TEXT UNIQUE NOT NULL,
    description TEXT,
    logo_url TEXT,
    founder_id UUID,
    leader_id UUID,
    member_count INT DEFAULT 1,
    max_members INT DEFAULT 50,
    level INT DEFAULT 1,
    xp BIGINT DEFAULT 0,
    treasury_gold BIGINT DEFAULT 0,
    tax_rate NUMERIC DEFAULT 0.05,
    season_points INT DEFAULT 0,
    is_recruiting BOOLEAN DEFAULT TRUE,
    min_level_requirement INT DEFAULT 1,
    min_level INT DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

DO $$
BEGIN
    ALTER TABLE public.guilds ADD COLUMN IF NOT EXISTS logo_url TEXT;
    ALTER TABLE public.guilds ADD COLUMN IF NOT EXISTS founder_id UUID;
    ALTER TABLE public.guilds ADD COLUMN IF NOT EXISTS leader_id UUID;
    ALTER TABLE public.guilds ADD COLUMN IF NOT EXISTS tax_rate NUMERIC DEFAULT 0.05;
    ALTER TABLE public.guilds ADD COLUMN IF NOT EXISTS season_points INT DEFAULT 0;
    ALTER TABLE public.guilds ADD COLUMN IF NOT EXISTS min_level_requirement INT DEFAULT 1;
    ALTER TABLE public.guilds ADD COLUMN IF NOT EXISTS min_level INT DEFAULT 1;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_guilds_name ON public.guilds(name);
CREATE INDEX IF NOT EXISTS idx_guilds_season_points ON public.guilds(season_points DESC);
CREATE INDEX IF NOT EXISTS idx_guilds_recruiting ON public.guilds(is_recruiting) WHERE is_recruiting = TRUE;

-- ============================================================
-- 11. PUBLIC.GUILD_ACTIVITIES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.guild_activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    guild_id UUID REFERENCES public.guilds(id) ON DELETE CASCADE,
    activity_type TEXT,
    user_id UUID,
    description TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_guild_activities_guild ON public.guild_activities(guild_id, created_at DESC);

-- ============================================================
-- 12. PUBLIC.GUILD_WARS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.guild_wars (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    guild_1_id UUID REFERENCES public.guilds(id),
    guild_2_id UUID REFERENCES public.guilds(id),
    guild_1_points INT DEFAULT 0,
    guild_2_points INT DEFAULT 0,
    winner_guild_id UUID REFERENCES public.guilds(id),
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    status TEXT DEFAULT 'upcoming',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT different_guilds CHECK (guild_1_id != guild_2_id)
);

CREATE INDEX IF NOT EXISTS idx_guild_wars_guilds ON public.guild_wars(guild_1_id, guild_2_id);
CREATE INDEX IF NOT EXISTS idx_guild_wars_status ON public.guild_wars(status);

-- ============================================================
-- 13. PUBLIC.CHAT_MESSAGES (Sohbet)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    channel TEXT NOT NULL,
    sender_id UUID,
    receiver_id UUID,
    guild_id UUID,
    content TEXT NOT NULL,
    sent_at TIMESTAMPTZ DEFAULT NOW(),
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_by UUID,
    flagged BOOLEAN DEFAULT FALSE,
    flagged_reason TEXT,
    deleted_at TIMESTAMP
);

DO $$
BEGIN
    ALTER TABLE public.chat_messages ADD COLUMN IF NOT EXISTS flagged BOOLEAN DEFAULT FALSE;
    ALTER TABLE public.chat_messages ADD COLUMN IF NOT EXISTS flagged_reason TEXT;
    ALTER TABLE public.chat_messages ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_chat_messages_channel ON public.chat_messages(channel, sent_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender ON public.chat_messages(sender_id, sent_at DESC);

ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "chat_messages_select" ON public.chat_messages;
CREATE POLICY "chat_messages_select" ON public.chat_messages FOR SELECT USING (true);
DROP POLICY IF EXISTS "chat_messages_insert_own" ON public.chat_messages;
CREATE POLICY "chat_messages_insert_own" ON public.chat_messages FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- ============================================================
-- 14. PUBLIC.PVP_BATTLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.pvp_battles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attacker_id UUID,
    defender_id UUID,
    attacker_power INT,
    defender_power INT,
    attacker_energy_before INT,
    outcome TEXT,
    winner_id UUID,
    gold_stolen INT DEFAULT 0,
    attacker_hospital_minutes INT DEFAULT 0,
    defender_hospital_minutes INT DEFAULT 0,
    attacker_energy_cost INT DEFAULT 0,
    rating_change_attacker INT DEFAULT 0,
    rating_change_defender INT DEFAULT 0,
    battled_at TIMESTAMPTZ DEFAULT NOW()
);

DO $$
BEGIN
    ALTER TABLE public.pvp_battles ADD COLUMN IF NOT EXISTS rating_change_attacker INT DEFAULT 0;
    ALTER TABLE public.pvp_battles ADD COLUMN IF NOT EXISTS rating_change_defender INT DEFAULT 0;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_pvp_battles_attacker ON public.pvp_battles(attacker_id, battled_at DESC);
CREATE INDEX IF NOT EXISTS idx_pvp_battles_defender ON public.pvp_battles(defender_id, battled_at DESC);
CREATE INDEX IF NOT EXISTS idx_pvp_battles_time ON public.pvp_battles(battled_at DESC);

-- ============================================================
-- 15. PUBLIC.HOSPITAL_RECORDS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.hospital_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID,
    reason TEXT,
    related_battle_id UUID,
    duration_minutes INT NOT NULL,
    release_time TIMESTAMP NOT NULL DEFAULT NOW() + INTERVAL '30 minutes',
    early_release BOOLEAN DEFAULT FALSE,
    early_release_gem_cost INT,
    early_release_time TIMESTAMP,
    admitted_at TIMESTAMPTZ DEFAULT NOW()
);

DO $$
BEGIN
    ALTER TABLE public.hospital_records ADD COLUMN IF NOT EXISTS early_release BOOLEAN DEFAULT FALSE;
    ALTER TABLE public.hospital_records ADD COLUMN IF NOT EXISTS early_release_gem_cost INT;
    ALTER TABLE public.hospital_records ADD COLUMN IF NOT EXISTS early_release_time TIMESTAMP;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_hospital_user ON public.hospital_records(user_id, release_time);

-- ============================================================
-- 16. PUBLIC.PRISON_RECORDS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.prison_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    facility_id UUID,
    reason VARCHAR(200) NOT NULL DEFAULT 'Unknown',
    sentence_hours INT NOT NULL DEFAULT 1,
    admitted_at TIMESTAMPTZ DEFAULT NOW(),
    released_at TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

DO $$
BEGIN
    ALTER TABLE public.prison_records ADD COLUMN IF NOT EXISTS facility_id UUID;
    ALTER TABLE public.prison_records ADD COLUMN IF NOT EXISTS sentence_hours INT DEFAULT 1;
    ALTER TABLE public.prison_records ADD COLUMN IF NOT EXISTS released_at TIMESTAMP;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_prison_records_user_id ON public.prison_records(user_id);
CREATE INDEX IF NOT EXISTS idx_prison_records_released_at ON public.prison_records(released_at);

-- ============================================================
-- 17. GAME.QUESTS (Görev Tanımları - Statik)
-- ============================================================

CREATE TABLE IF NOT EXISTS game.quests (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    quest_type TEXT,
    difficulty TEXT,
    min_level INT DEFAULT 1,
    prerequisite_quest_id TEXT,
    gold_reward INT,
    xp_reward INT,
    item_rewards JSONB,
    duration_minutes INT,
    energy_cost INT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_quests_type ON game.quests(quest_type);
CREATE INDEX IF NOT EXISTS idx_quests_level ON game.quests(min_level);

-- ============================================================
-- 18. GAME.USER_QUESTS (Oyuncu Görev İlerlemesi)
-- ============================================================

CREATE TABLE IF NOT EXISTS game.user_quests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES game.users(id) ON DELETE CASCADE,
    quest_id TEXT,
    status TEXT DEFAULT 'in_progress',
    progress JSONB,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_user_quests_user ON game.user_quests(user_id, status);
CREATE INDEX IF NOT EXISTS idx_user_quests_quest ON game.user_quests(quest_id);

ALTER TABLE game.user_quests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own quests" ON game.user_quests;
CREATE POLICY "Users can view own quests" ON game.user_quests FOR SELECT USING (auth.uid() = user_id);

-- ============================================================
-- 19. GAME.DUNGEONS (Zindan Tanımları - Statik)
-- ============================================================

CREATE TABLE IF NOT EXISTS game.dungeons (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    difficulty TEXT,
    min_level INT,
    min_power INT,
    energy_cost INT,
    base_gold_min INT,
    base_gold_max INT,
    loot_table JSONB,
    estimated_duration_minutes INT
);

-- ============================================================
-- 20. GAME.DUNGEON_RUNS (Zindan Koşuları)
-- ============================================================

CREATE TABLE IF NOT EXISTS game.dungeon_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES game.users(id) ON DELETE CASCADE,
    dungeon_id TEXT,
    success BOOLEAN,
    duration_seconds INT,
    gold_earned INT,
    xp_earned INT,
    items_dropped JSONB,
    completed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_dungeon_runs_user ON game.dungeon_runs(user_id);
CREATE INDEX IF NOT EXISTS idx_dungeon_runs_dungeon ON game.dungeon_runs(dungeon_id, completed_at DESC);

-- ============================================================
-- 21. GAME.ENHANCEMENT_HISTORY (Geliştirme Geçmişi)
-- ============================================================

CREATE TABLE IF NOT EXISTS game.enhancement_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES game.users(id) ON DELETE CASCADE,
    inventory_item_id UUID,
    item_id TEXT,
    from_level INT,
    to_level INT,
    success BOOLEAN,
    gold_cost INT,
    rune_used TEXT,
    item_destroyed BOOLEAN DEFAULT FALSE,
    enhanced_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_enhancement_history_user ON game.enhancement_history(user_id);
CREATE INDEX IF NOT EXISTS idx_enhancement_history_item ON game.enhancement_history(item_id);
CREATE INDEX IF NOT EXISTS idx_enhancement_history_time ON game.enhancement_history(enhanced_at DESC);

-- ============================================================
-- 22. GAME.SEASONS (Sezonlar)
-- ============================================================

CREATE TABLE IF NOT EXISTS game.seasons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    season_number INT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    theme TEXT,
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP NOT NULL,
    phase TEXT DEFAULT 'foundation',
    status TEXT DEFAULT 'upcoming',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_seasons_status ON game.seasons(status);
CREATE INDEX IF NOT EXISTS idx_seasons_dates ON game.seasons(start_date, end_date);

-- ============================================================
-- 23. GAME.SEASON_LEADERBOARDS
-- ============================================================

CREATE TABLE IF NOT EXISTS game.season_leaderboards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    season_id UUID REFERENCES game.seasons(id) ON DELETE CASCADE,
    category TEXT NOT NULL,
    rankings JSONB,
    last_updated TIMESTAMPTZ DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_season_leaderboards_unique ON game.season_leaderboards(season_id, category);

-- ============================================================
-- 24. GAME.BATTLE_PASS_PROGRESS
-- ============================================================

CREATE TABLE IF NOT EXISTS game.battle_pass_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES game.users(id) ON DELETE CASCADE,
    season_id UUID REFERENCES game.seasons(id) ON DELETE CASCADE,
    level INT DEFAULT 1,
    xp INT DEFAULT 0,
    is_premium BOOLEAN DEFAULT FALSE,
    purchased_at TIMESTAMP,
    free_rewards_claimed JSONB,
    premium_rewards_claimed JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_battle_pass_user_season ON game.battle_pass_progress(user_id, season_id);
CREATE INDEX IF NOT EXISTS idx_battle_pass_season ON game.battle_pass_progress(season_id);

-- ============================================================
-- 25. GAME.PURCHASES (Satın Almalar)
-- ============================================================

CREATE TABLE IF NOT EXISTS game.purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES game.users(id) ON DELETE CASCADE,
    package_id TEXT NOT NULL,
    gems INT NOT NULL,
    price_usd NUMERIC NOT NULL,
    currency TEXT DEFAULT 'USD',
    payment_method TEXT,
    payment_provider_transaction_id TEXT UNIQUE,
    status TEXT DEFAULT 'pending',
    first_purchase BOOLEAN DEFAULT FALSE,
    country TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_purchases_user ON game.purchases(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_purchases_status ON game.purchases(status);
CREATE INDEX IF NOT EXISTS idx_purchases_time ON game.purchases(completed_at DESC) WHERE status = 'completed';

-- ============================================================
-- 26. PUBLIC.CRAFTED_ITEMS_LOG (Üretilmiş Item Kayıdı)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.crafted_items_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID,
    item_id TEXT,
    item_name TEXT,
    rarity VARCHAR(20),
    facility_id UUID,
    recipe_id TEXT,
    enhancement_level INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_crafted_items_log_user_id ON public.crafted_items_log(user_id);
CREATE INDEX IF NOT EXISTS idx_crafted_items_log_facility_id ON public.crafted_items_log(facility_id);

-- ============================================================
-- 27. ANALYTICS.ANALYTICS_EVENTS
-- ============================================================

CREATE TABLE IF NOT EXISTS analytics.analytics_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event TEXT NOT NULL,
    user_id UUID,
    properties JSONB,
    session_id UUID,
    device_type TEXT,
    timestamp TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_analytics_events_user ON analytics.analytics_events(user_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_analytics_events_event ON analytics.analytics_events(event, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_analytics_events_time ON analytics.analytics_events(timestamp DESC);

-- ============================================================
-- 28. ANALYTICS.ANALYTICS_DAILY_AGGREGATES
-- ============================================================

CREATE TABLE IF NOT EXISTS analytics.analytics_daily_aggregates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date DATE NOT NULL UNIQUE,
    dau INT,
    new_users INT,
    avg_session_duration_seconds INT,
    total_sessions INT,
    total_gold_earned BIGINT,
    total_gold_spent BIGINT,
    revenue_usd NUMERIC,
    paying_users INT,
    calculated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_analytics_daily_date ON analytics.analytics_daily_aggregates(date DESC);

-- ============================================================
-- 29. ADMIN.AUDIT_LOGS
-- ============================================================

CREATE TABLE IF NOT EXISTS admin.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID,
    admin_user_id UUID,
    action TEXT NOT NULL,
    table_name TEXT,
    record_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    timestamp TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON admin.audit_logs(user_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_admin ON admin.audit_logs(admin_user_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON admin.audit_logs(action, timestamp DESC);

-- ============================================================
-- 30. ADMIN.BANS
-- ============================================================

CREATE TABLE IF NOT EXISTS admin.bans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID,
    reason TEXT NOT NULL,
    evidence TEXT,
    banned_until TIMESTAMP,
    banned_by UUID,
    active BOOLEAN DEFAULT TRUE,
    banned_at TIMESTAMPTZ DEFAULT NOW(),
    unbanned_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_bans_user ON admin.bans(user_id);
CREATE INDEX IF NOT EXISTS idx_bans_active ON admin.bans(active) WHERE active = TRUE;

-- ============================================================
-- 31. VIEWS
-- ============================================================

-- Envanter + Item detayları
CREATE OR REPLACE VIEW public.v_inventory_with_items AS
SELECT
    i.*,
    it.name, it.description, it.icon,
    it.type AS item_type, it.rarity AS item_rarity, it.equip_slot AS item_equip_slot,
    it.attack, it.defense, it.health, it.power
FROM public.inventory i
LEFT JOIN public.items it ON i.item_id = it.id;

-- Market + Item detayları
CREATE OR REPLACE VIEW public.market_listings_view AS
SELECT
    m.id,
    m.seller_id,
    m.item_id,
    m.quantity,
    m.price,
    m.listed_at,
    m.item_data,
    m.status,
    it.name AS item_name,
    it.icon AS item_icon,
    it.rarity AS item_rarity,
    it.type AS item_type
FROM public.market_orders m
LEFT JOIN public.items it ON m.item_id = it.id
WHERE m.status = 'active' OR m.quantity > 0;

-- Aktif üretim kuyruğu
CREATE OR REPLACE VIEW public.active_production_queue AS
SELECT
    fq.id,
    f.user_id,
    f.type,
    f.level AS facility_level,
    fq.recipe_id,
    fq.quantity,
    fq.started_at,
    fq.completed_at,
    fq.status,
    fr.output_item_id,
    fr.output_quantity
FROM public.facility_queue fq
JOIN public.facilities f ON fq.facility_id = f.id
LEFT JOIN public.facility_recipes fr ON fq.recipe_id = fr.id
WHERE fq.status = 'in_progress';

-- ============================================================
-- 32. TRIGGER FUNCTIONS
-- ============================================================

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Gold validation
CREATE OR REPLACE FUNCTION validate_gold_transaction()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.gold < 0 THEN
        RAISE EXCEPTION 'Gold cannot be negative: user_id=%', NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- XP -> Level Up
CREATE OR REPLACE FUNCTION check_level_up()
RETURNS TRIGGER AS $$
DECLARE
    required_xp BIGINT;
    new_level INT;
BEGIN
    new_level := NEW.level;
    LOOP
        required_xp := 1000 * POWER(new_level, 1.5);
        EXIT WHEN NEW.xp < required_xp;
        new_level := new_level + 1;
    END LOOP;
    IF new_level > NEW.level THEN
        NEW.level := new_level;
        NEW.gems := NEW.gems + (10 * (new_level - OLD.level));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Tolerance decay
CREATE OR REPLACE FUNCTION decay_tolerance()
RETURNS TRIGGER AS $$
DECLARE
    hours_passed INT;
    decay_amount INT;
BEGIN
    IF OLD.last_tolerance_decay IS NOT NULL THEN
        hours_passed := EXTRACT(EPOCH FROM (NOW() - OLD.last_tolerance_decay)) / 3600;
        IF hours_passed >= 6 THEN
            decay_amount := hours_passed / 6;
            NEW.tolerance := GREATEST(0, NEW.tolerance - decay_amount);
            NEW.last_tolerance_decay := NOW();
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Referral code generator
CREATE OR REPLACE FUNCTION generate_referral_code()
RETURNS TEXT LANGUAGE plpgsql AS $$
DECLARE
    chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    result TEXT := '';
    i INT;
BEGIN
    FOR i IN 1..8 LOOP
        result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
    END LOOP;
    RETURN result;
END;
$$;

CREATE OR REPLACE FUNCTION set_referral_code()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.referral_code IS NULL THEN
        NEW.referral_code := generate_referral_code();
        WHILE EXISTS (SELECT 1 FROM game.users WHERE referral_code = NEW.referral_code) LOOP
            NEW.referral_code := generate_referral_code();
        END LOOP;
    END IF;
    RETURN NEW;
END;
$$;

-- ============================================================
-- 33. TRIGGERS (DROP IF EXISTS + CREATE)
-- ============================================================

-- game.users triggers
DROP TRIGGER IF EXISTS trigger_update_users_updated_at ON game.users;
CREATE TRIGGER trigger_update_users_updated_at
    BEFORE UPDATE ON game.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS validate_gold ON game.users;
CREATE TRIGGER validate_gold
    BEFORE UPDATE ON game.users
    FOR EACH ROW EXECUTE FUNCTION validate_gold_transaction();

DROP TRIGGER IF EXISTS trigger_level_up ON game.users;
CREATE TRIGGER trigger_level_up
    BEFORE UPDATE OF xp ON game.users
    FOR EACH ROW EXECUTE FUNCTION check_level_up();

DROP TRIGGER IF EXISTS trigger_set_referral_code ON game.users;
CREATE TRIGGER trigger_set_referral_code
    BEFORE INSERT ON game.users
    FOR EACH ROW EXECUTE FUNCTION set_referral_code();

-- public.guilds trigger (mevcut tablo varsa)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'guilds') THEN
        DROP TRIGGER IF EXISTS update_guilds_updated_at ON public.guilds;
        CREATE TRIGGER update_guilds_updated_at
            BEFORE UPDATE ON public.guilds
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- market_orders trigger
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'market_orders') THEN
        DROP TRIGGER IF EXISTS update_market_orders_updated_at ON public.market_orders;
        CREATE TRIGGER update_market_orders_updated_at
            BEFORE UPDATE ON public.market_orders
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- ============================================================
-- 34. AUTH TRIGGER (Yeni kullanıcı kaydında game.users profili oluştur)
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, game
AS $$
BEGIN
    INSERT INTO game.users (auth_id, email, username, display_name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1))
    )
    ON CONFLICT (auth_id) DO NOTHING;
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Failed to create game profile for user %: %', NEW.id, SQLERRM;
        RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- 35. HELPER RPC FUNCTIONS
-- ============================================================

-- Safe JSONB to INT conversion
CREATE OR REPLACE FUNCTION public._jsonb_to_int(val jsonb, default_val int DEFAULT 0)
RETURNS int AS $$
DECLARE text_val text;
BEGIN
    IF val IS NULL OR val = 'null'::jsonb THEN RETURN default_val; END IF;
    BEGIN RETURN (val)::int;
    EXCEPTION WHEN OTHERS THEN
        BEGIN RETURN (val::numeric)::int;
        EXCEPTION WHEN OTHERS THEN
            BEGIN
                text_val := trim(both '"' from val::text);
                RETURN (text_val::numeric)::int;
            EXCEPTION WHEN OTHERS THEN RETURN default_val;
            END;
        END;
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- _find_first_empty_slot helper
CREATE OR REPLACE FUNCTION public._find_first_empty_slot(p_user_id uuid)
RETURNS int LANGUAGE plpgsql AS $$
DECLARE v_slot int;
BEGIN
    SELECT MIN(slot_num) INTO v_slot
    FROM generate_series(0, 19) slot_num
    WHERE NOT EXISTS (
        SELECT 1 FROM public.inventory
        WHERE user_id = p_user_id AND slot_position = slot_num
    );
    RETURN v_slot;
END;
$$;

-- ============================================================
-- 36. CORE RPC FUNCTIONS
-- ============================================================

-- get_current_user
CREATE OR REPLACE FUNCTION public.get_current_user()
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_user_id UUID; v_user JSONB;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Not authenticated'); END IF;
    SELECT jsonb_build_object(
        'id', id, 'auth_id', auth_id, 'username', username, 'email', email,
        'display_name', display_name, 'avatar_url', avatar_url,
        'level', level, 'xp', xp, 'gold', gold, 'gems', gems,
        'energy', energy, 'max_energy', max_energy,
        'attack', attack, 'defense', defense, 'health', health, 'max_health', max_health, 'power', power,
        'pvp_wins', pvp_wins, 'pvp_losses', pvp_losses, 'pvp_rating', pvp_rating,
        'reputation', reputation, 'tolerance', tolerance,
        'in_hospital', in_hospital, 'hospital_until', hospital_until,
        'in_prison', in_prison, 'prison_until', prison_until,
        'guild_id', guild_id, 'guild_role', guild_role,
        'tutorial_completed', tutorial_completed, 'referral_code', referral_code,
        'created_at', created_at, 'last_login_at', last_login_at
    ) INTO v_user FROM game.users WHERE auth_id = v_user_id;
    IF v_user IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'User profile not found'); END IF;
    RETURN jsonb_build_object('success', true, 'data', v_user);
END;
$$;

-- update_user_profile
CREATE OR REPLACE FUNCTION public.update_user_profile(p_display_name TEXT DEFAULT NULL, p_avatar_url TEXT DEFAULT NULL)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Not authenticated'); END IF;
    UPDATE game.users SET
        display_name = COALESCE(p_display_name, display_name),
        avatar_url = COALESCE(p_avatar_url, avatar_url),
        updated_at = NOW()
    WHERE auth_id = v_user_id;
    RETURN jsonb_build_object('success', true, 'message', 'Profile updated');
END;
$$;

-- update_last_login
CREATE OR REPLACE FUNCTION public.update_last_login()
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Not authenticated'); END IF;
    UPDATE game.users SET last_login_at = NOW() WHERE auth_id = v_user_id;
    RETURN jsonb_build_object('success', true);
END;
$$;

-- upgrade_item_enhancement
CREATE OR REPLACE FUNCTION public.upgrade_item_enhancement(p_row_id UUID, p_new_level INT)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_affected_rows INT;
BEGIN
    UPDATE public.inventory SET enhancement_level = p_new_level, updated_at = NOW() WHERE row_id = p_row_id;
    GET DIAGNOSTICS v_affected_rows = ROW_COUNT;
    IF v_affected_rows > 0 THEN RETURN json_build_object('success', true, 'new_level', p_new_level);
    ELSE RETURN json_build_object('success', false, 'error', 'Item not found or permission denied');
    END IF;
EXCEPTION WHEN OTHERS THEN RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- ============================================================
-- 37. PERMISSIONS / GRANTS
-- ============================================================

GRANT USAGE ON SCHEMA game TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE ON game.users TO authenticated;
GRANT SELECT ON game.users TO anon;

GRANT SELECT ON public.items TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.inventory TO authenticated;

GRANT SELECT ON public.market_orders TO authenticated, anon;
GRANT SELECT ON public.market_history TO authenticated, anon;
GRANT SELECT ON public.market_listings_view TO authenticated, anon;

GRANT SELECT, INSERT, UPDATE ON public.facilities TO authenticated;
GRANT SELECT ON public.facility_recipes TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE ON public.facility_queue TO authenticated;

GRANT SELECT ON public.guilds TO authenticated, anon;
GRANT SELECT, INSERT ON public.chat_messages TO authenticated;

-- ============================================================
-- 38. VERIFICATION QUERIES
-- ============================================================

DO $$
DECLARE
    tbl_count INT;
BEGIN
    -- game schema tablo sayısı
    SELECT COUNT(*) INTO tbl_count
    FROM information_schema.tables
    WHERE table_schema = 'game';
    RAISE NOTICE '✓ game schema: % tablo', tbl_count;

    -- public schema oyun tabloları
    SELECT COUNT(*) INTO tbl_count
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name IN ('items', 'inventory', 'facilities', 'facility_recipes', 'facility_queue',
                         'market_orders', 'market_history', 'guilds', 'guild_activities', 'guild_wars',
                         'chat_messages', 'pvp_battles', 'hospital_records', 'prison_records', 'crafted_items_log');
    RAISE NOTICE '✓ public schema: % oyun tablosu', tbl_count;

    -- analytics schema
    SELECT COUNT(*) INTO tbl_count
    FROM information_schema.tables
    WHERE table_schema = 'analytics';
    RAISE NOTICE '✓ analytics schema: % tablo', tbl_count;

    -- admin schema
    SELECT COUNT(*) INTO tbl_count
    FROM information_schema.tables
    WHERE table_schema = 'admin';
    RAISE NOTICE '✓ admin schema: % tablo', tbl_count;
END $$;

-- ============================================================
-- MIGRATION TAMAMLANDI
-- ============================================================
-- Toplam:
--   game schema   : users, sessions, quests, user_quests, dungeons, dungeon_runs,
--                    enhancement_history, seasons, season_leaderboards,
--                    battle_pass_progress, purchases
--   public schema : items, inventory, facilities, facility_recipes, facility_queue,
--                    market_orders, market_history, guilds, guild_activities, guild_wars,
--                    chat_messages, pvp_battles, hospital_records, prison_records,
--                    crafted_items_log
--   analytics     : analytics_events, analytics_daily_aggregates
--   admin         : audit_logs, bans
--   views         : v_inventory_with_items, market_listings_view, active_production_queue
--   triggers      : updated_at, gold_validation, level_up, referral_code, auth_user_created
--   RPC           : get_current_user, update_user_profile, update_last_login,
--                   upgrade_item_enhancement, _jsonb_to_int, _find_first_empty_slot
-- ============================================================
