-- ============================================================
-- SUPABASE SQL EDİTÖR - VERİTABANI KURTARMA
-- ============================================================
-- DOSYA 3/5: ANA SİSTEMLER
-- ============================================================
--
-- Bu dosya oyunun ana sistemlerini kurar:
-- ✓ Tesis (Facilities) sistemi
-- ✓ Hapishane (Prison) sistemi
-- ✓ Pazar (Market) sistemi
--
-- TALİMATLAR:
-- 1. Bu dosyanın tüm içeriğini kopyalayın
-- 2. Supabase SQL Editor'e yapıştırın
-- 3. RUN butonuna basın
-- 4. İşlem tamamlanana kadar bekleyin (~20 saniye)
-- 5. Sonra 04_RPC_FONKSIYONLAR.sql dosyasına geçin
--
-- BEKLENEN SÜRE: ~20 saniye
-- BEKLENEN SONUÇ: facilities, prison, market_listings tabloları oluşturuldu
-- ============================================================

-- =============================================================================
-- FACILITIES SYSTEM - DATABASE ENHANCEMENTS
-- Version: 1.0
-- Created: 2026-01-30
-- Uyum: Mevcut facilities, facility_queue, facility_recipes tablolarıyla çalışır
-- =============================================================================

-- ==================== ALTERATIONS TO EXISTING TABLES ====================
-- facilities tablosuna eksik kolonlar ekle

ALTER TABLE public.facilities ADD COLUMN IF NOT EXISTS suspicion_level INT NOT NULL DEFAULT 0 CHECK (suspicion_level >= 0 AND suspicion_level <= 100);
ALTER TABLE public.facilities ADD COLUMN IF NOT EXISTS offline_production_cap INT DEFAULT 0;
ALTER TABLE public.facilities ADD COLUMN IF NOT EXISTS workers INT DEFAULT 0;
ALTER TABLE public.facilities ADD COLUMN IF NOT EXISTS last_production_collected_at TIMESTAMP;
ALTER TABLE public.facilities ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();

-- facility_recipes tablosunun output_item_id'si var, ek kolonlar gerekebilirse ekle
ALTER TABLE public.facility_recipes ADD COLUMN IF NOT EXISTS production_speed_bonus FLOAT DEFAULT 1.0;
ALTER TABLE public.facility_recipes ADD COLUMN IF NOT EXISTS rarity_distribution JSONB DEFAULT '{"COMMON": 70, "UNCOMMON": 20, "RARE": 8, "EPIC": 1.5, "LEGENDARY": 0.5}';
ALTER TABLE public.facility_recipes ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW();

-- facility_queue tablosuna ek kolonlar
ALTER TABLE public.facility_queue ADD COLUMN IF NOT EXISTS rarity_outcome VARCHAR(20);  -- "COMMON", "UNCOMMON", "RARE", "EPIC", "LEGENDARY", "MYTHIC"
ALTER TABLE public.facility_queue ADD COLUMN IF NOT EXISTS collected BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.facility_queue ADD COLUMN IF NOT EXISTS collected_at TIMESTAMP;
ALTER TABLE public.facility_queue ADD COLUMN IF NOT EXISTS failed BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.facility_queue ADD COLUMN IF NOT EXISTS failure_reason VARCHAR(200);
ALTER TABLE public.facility_queue ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW();
ALTER TABLE public.facility_queue ADD COLUMN IF NOT EXISTS estimated_completion_at TIMESTAMP;
ALTER TABLE public.facility_queue ADD COLUMN IF NOT EXISTS duration_seconds INT;

-- ==================== NEW TABLE: CRAFTED ITEMS LOG ====================
-- Üretilen ürünlerin kaydı

CREATE TABLE IF NOT EXISTS public.crafted_items_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  item_id TEXT NOT NULL,
  quantity INT NOT NULL,
  rarity VARCHAR(20) NOT NULL,
  facility_id UUID REFERENCES public.facilities(id) ON DELETE SET NULL,
  recipe_id TEXT,
  enhancement_level INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_crafted_items_log_user_id ON public.crafted_items_log(user_id);
CREATE INDEX IF NOT EXISTS idx_crafted_items_log_facility_id ON public.crafted_items_log(facility_id);

-- ==================== NEW TABLE: PRISON RECORDS ====================
-- Oyuncu hapishaneye düşüş kaydı

CREATE TABLE IF NOT EXISTS public.prison_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  facility_id UUID REFERENCES public.facilities(id) ON DELETE SET NULL,
  reason VARCHAR(200) NOT NULL,
  sentence_hours INT NOT NULL,
  admitted_at TIMESTAMP DEFAULT NOW(),
  released_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_prison_records_user_id ON public.prison_records(user_id);
CREATE INDEX IF NOT EXISTS idx_prison_records_released_at ON public.prison_records(released_at);

-- =============================================================================
-- VIEWS (Queries kolaylaştırmak için)
-- =============================================================================

-- View: Aktif production queue (tamamlanmamış işler)
CREATE OR REPLACE VIEW public.active_production_queue AS
SELECT 
  fq.id,
  f.user_id,
  f.type,
  f.level as facility_level,
  fq.recipe_id,
  fq.quantity,
  fq.started_at,
  fq.estimated_completion_at,
  EXTRACT(EPOCH FROM (fq.estimated_completion_at - NOW())) as seconds_remaining,
  fq.rarity_outcome,
  fq.failed,
  fq.failure_reason
FROM public.facility_queue fq
JOIN public.facilities f ON fq.facility_id = f.id
WHERE fq.status = 'in_progress' OR fq.status IS NULL;

-- View: Ready to collect (tamamlanmış ama collect edilmemiş işler)
CREATE OR REPLACE VIEW public.ready_to_collect AS
SELECT 
  fq.id,
  f.user_id,
  f.type,
  fq.recipe_id,
  fq.quantity,
  fq.rarity_outcome,
  fr.output_item_id,
  fr.output_quantity
FROM public.facility_queue fq
JOIN public.facilities f ON fq.facility_id = f.id
JOIN public.facility_recipes fr ON fq.recipe_id = fr.id
WHERE fq.collected = false AND fq.status = 'completed';

-- View: Oyuncu suspicion level
CREATE OR REPLACE VIEW public.player_suspicion_levels AS
SELECT 
  user_id,
  SUM(suspicion_level) as total_suspicion,
  ARRAY_AGG(DISTINCT type) as high_suspicion_facilities,
  MAX(suspicion_level) as max_facility_suspicion
FROM public.facilities
GROUP BY user_id;

-- View: Player prison status
CREATE OR REPLACE VIEW public.player_prison_status AS
SELECT 
  user_id,
  CASE WHEN COUNT(*) FILTER (WHERE released_at IS NULL) > 0 THEN true ELSE false END as is_in_prison,
  MIN(CASE WHEN released_at IS NULL THEN released_at END) as next_release_time
FROM public.prison_records
GROUP BY user_id;

-- =============================================================================
-- ROW LEVEL SECURITY (RLS) POLİCİES
-- =============================================================================

-- Facilities table için RLS (eğer zaten yoksa)
ALTER TABLE public.facilities ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS facilities_select ON public.facilities;
DROP POLICY IF EXISTS facilities_insert ON public.facilities;
DROP POLICY IF EXISTS facilities_update ON public.facilities;

CREATE POLICY facilities_select ON public.facilities
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY facilities_insert ON public.facilities
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY facilities_update ON public.facilities
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Facility queue için RLS
ALTER TABLE public.facility_queue ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS queue_select ON public.facility_queue;
DROP POLICY IF EXISTS queue_insert ON public.facility_queue;

CREATE POLICY queue_select ON public.facility_queue
  FOR SELECT
  USING (
    facility_id IN (
      SELECT id FROM public.facilities WHERE user_id = auth.uid()
    )
  );

CREATE POLICY queue_insert ON public.facility_queue
  FOR INSERT
  WITH CHECK (
    facility_id IN (
      SELECT id FROM public.facilities WHERE user_id = auth.uid()
    )
  );

-- Prison records için RLS
ALTER TABLE public.prison_records ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS prison_select ON public.prison_records;

CREATE POLICY prison_select ON public.prison_records
  FOR SELECT
  USING (auth.uid() = user_id);

-- Crafted items log için RLS
ALTER TABLE public.crafted_items_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS crafted_items_select ON public.crafted_items_log;
DROP POLICY IF EXISTS crafted_items_insert ON public.crafted_items_log;

CREATE POLICY crafted_items_select ON public.crafted_items_log
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY crafted_items_insert ON public.crafted_items_log
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- =============================================================================
-- FUNCTIONS (Database logic'i)
-- =============================================================================

-- Function: Offline production hesaplama
CREATE OR REPLACE FUNCTION public.calculate_offline_production(
  p_facility_id UUID
) RETURNS INT AS $$
DECLARE
  v_facility public.facilities%ROWTYPE;
  v_queue_count INT;
  v_offline_hours INT;
  v_production_per_hour INT;
  v_total_production INT;
BEGIN
  -- Facility verisini al
  SELECT * INTO v_facility 
  FROM public.facilities 
  WHERE id = p_facility_id;
  
  IF NOT FOUND THEN
    RETURN 0;
  END IF;
  
  -- Queue'deki aktif işleri say
  SELECT COUNT(*) INTO v_queue_count
  FROM public.facility_queue
  WHERE facility_id = p_facility_id 
    AND (status = 'in_progress' OR status IS NULL);
  
  -- Queue dolu mu kontrol et
  IF v_queue_count >= 10 THEN
    RETURN 0;
  END IF;
  
  -- Offline saat hesapla (max 24 saat)
  v_offline_hours := LEAST(24, 
    EXTRACT(EPOCH FROM (NOW() - v_facility.last_production_collected_at)) / 3600
  );
  
  -- Production per hour: level * 50 + workers * 10
  v_production_per_hour := (v_facility.level * 50) + (v_facility.workers * 10);
  
  -- Toplam offline production
  v_total_production := v_production_per_hour * v_offline_hours;
  
  RETURN LEAST(v_total_production, v_facility.offline_production_cap);
END;
$$ LANGUAGE plpgsql;

-- Function: Rarity outcome belirle
CREATE OR REPLACE FUNCTION public.determine_rarity_outcome(
  p_facility_level INT,
  p_suspicion_level INT,
  p_rarity_distribution JSONB
) RETURNS VARCHAR AS $$
DECLARE
  v_roll FLOAT;
  v_facility_bonus FLOAT;
  v_suspicion_penalty FLOAT;
  v_adjusted_common FLOAT;
  v_adjusted_uncommon FLOAT;
  v_adjusted_rare FLOAT;
  v_adjusted_epic FLOAT;
  v_adjusted_legendary FLOAT;
BEGIN
  -- Random roll 0-100
  v_roll := RANDOM() * 100.0;
  
  -- Level bonus: +0.5% per level
  v_facility_bonus := p_facility_level * 0.5;
  
  -- Suspicion penalty: -0.5% per suspicion
  v_suspicion_penalty := p_suspicion_level * 0.5;
  
  -- Base probabilities
  v_adjusted_common := (p_rarity_distribution->>'COMMON')::FLOAT + v_facility_bonus - v_suspicion_penalty;
  v_adjusted_uncommon := (p_rarity_distribution->>'UNCOMMON')::FLOAT + v_facility_bonus - v_suspicion_penalty;
  v_adjusted_rare := (p_rarity_distribution->>'RARE')::FLOAT + v_facility_bonus - v_suspicion_penalty;
  v_adjusted_epic := (p_rarity_distribution->>'EPIC')::FLOAT + v_facility_bonus - v_suspicion_penalty;
  v_adjusted_legendary := (p_rarity_distribution->>'LEGENDARY')::FLOAT + v_facility_bonus - v_suspicion_penalty;
  
  -- Rarity belirle
  IF v_roll < v_adjusted_common THEN
    RETURN 'COMMON';
  ELSIF v_roll < (v_adjusted_common + v_adjusted_uncommon) THEN
    RETURN 'UNCOMMON';
  ELSIF v_roll < (v_adjusted_common + v_adjusted_uncommon + v_adjusted_rare) THEN
    RETURN 'RARE';
  ELSIF v_roll < (v_adjusted_common + v_adjusted_uncommon + v_adjusted_rare + v_adjusted_epic) THEN
    RETURN 'EPIC';
  ELSIF v_roll < (v_adjusted_common + v_adjusted_uncommon + v_adjusted_rare + v_adjusted_epic + v_adjusted_legendary) THEN
    RETURN 'LEGENDARY';
  ELSE
    RETURN 'MYTHIC';
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Function: Suspicion artırma
CREATE OR REPLACE FUNCTION public.increment_facility_suspicion(
  p_facility_id UUID,
  p_amount INT DEFAULT 5
) RETURNS INT AS $$
DECLARE
  v_new_suspicion INT;
BEGIN
  UPDATE public.facilities
  SET suspicion_level = LEAST(suspicion_level + p_amount, 100),
      updated_at = NOW()
  WHERE id = p_facility_id
  RETURNING suspicion_level INTO v_new_suspicion;
  
  RETURN v_new_suspicion;
END;
$$ LANGUAGE plpgsql;

-- Function: Suspicion azaltma (bribe/police)
CREATE OR REPLACE FUNCTION public.decrement_facility_suspicion(
  p_facility_id UUID,
  p_amount INT DEFAULT 10
) RETURNS INT AS $$
DECLARE
  v_new_suspicion INT;
BEGIN
  UPDATE public.facilities
  SET suspicion_level = GREATEST(suspicion_level - p_amount, 0),
      updated_at = NOW()
  WHERE id = p_facility_id
  RETURNING suspicion_level INTO v_new_suspicion;
  
  RETURN v_new_suspicion;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- TRIGGER (Otomatik updates)
-- =============================================================================

-- Trigger: facilities.updated_at otomatik update
CREATE OR REPLACE FUNCTION public.update_facilities_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS facilities_update_timestamp ON public.facilities;
CREATE TRIGGER facilities_update_timestamp
BEFORE UPDATE ON public.facilities
FOR EACH ROW
EXECUTE FUNCTION public.update_facilities_timestamp();

-- Trigger: Set estimated_completion_at on insert to facility_queue
CREATE OR REPLACE FUNCTION public.set_queue_estimated_completion()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.estimated_completion_at IS NULL AND NEW.duration_seconds IS NOT NULL THEN
    NEW.estimated_completion_at := NEW.started_at + (NEW.duration_seconds || ' seconds')::INTERVAL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS queue_set_estimated ON public.facility_queue;
CREATE TRIGGER queue_set_estimated
BEFORE INSERT ON public.facility_queue
FOR EACH ROW
EXECUTE FUNCTION public.set_queue_estimated_completion();

-- =============================================================================
-- END OF MIGRATION
-- =============================================================================

-- ============================================================
-- Hapishane Sistemi / Prison System
-- ============================================================


-- ============================================================
-- Pazar Sistemi / Market System
-- ============================================================

-- Prison System Migration (Mirroring Hospital Logic)
-- v5: FIX - Drop function release_from_prison before recreate

-- 1. Add Prison Columns to game.users
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'game' AND table_name = 'users') THEN
        ALTER TABLE game.users ADD COLUMN IF NOT EXISTS prison_until TIMESTAMPTZ DEFAULT NULL;
        ALTER TABLE game.users ADD COLUMN IF NOT EXISTS prison_reason TEXT DEFAULT NULL;
    ELSE
        RAISE EXCEPTION 'Table game.users not found. Please verify the table holding player profiles.';
    END IF;
END $$;


-- 2. RPC: Release from Prison (Bail via GEMS)
DROP FUNCTION IF EXISTS release_from_prison(boolean);

CREATE OR REPLACE FUNCTION release_from_prison(
    p_use_bail BOOLEAN DEFAULT FALSE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_user RECORD;
    v_now TIMESTAMPTZ;
    v_bail_gems INT; 
    v_remaining_mins INT;
BEGIN
    v_user_id := auth.uid();
    v_now := NOW();
    
    -- Use game.users
    SELECT * INTO v_user FROM game.users WHERE id = v_user_id;
    
    IF v_user IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'User not found in game.users'); END IF;

    IF v_user.prison_until IS NULL OR v_user.prison_until <= v_now THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not in prison');
    END IF;
    
    IF p_use_bail THEN
        v_remaining_mins := CEIL(EXTRACT(EPOCH FROM (v_user.prison_until - v_now)) / 60);
        v_bail_gems := GREATEST(1, v_remaining_mins);
        
        IF v_user.gems < v_bail_gems THEN
            RETURN jsonb_build_object('success', false, 'error', 'Insufficient gems', 'cost', v_bail_gems);
        END IF;
        
        UPDATE game.users SET gems = gems - v_bail_gems WHERE id = v_user_id;
    END IF;
    
    -- Release
    UPDATE game.users 
    SET prison_until = NULL, prison_reason = NULL 
    WHERE id = v_user_id;
    
    RETURN jsonb_build_object('success', true, 'message', 'Released from prison');
END;
$$;

-- 3. Update collect_facility_production
DROP FUNCTION IF EXISTS collect_facility_production(uuid);

CREATE OR REPLACE FUNCTION collect_facility_production(p_facility_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_facility RECORD;
    v_now BIGINT;
    v_queue_item RECORD;
    v_recipe RECORD;
    v_raid_roll INT;
    v_burn_roll INT;
    v_success_count INT := 0;
    v_raid_occurred BOOLEAN := FALSE;
    v_burn_occurred BOOLEAN := FALSE;
    v_final_qty INT;
    v_prison_duration INT;
BEGIN
    v_user_id := auth.uid();
    v_now := EXTRACT(EPOCH FROM NOW())::BIGINT;
    
    -- Check Prison Status on game.users
    IF EXISTS (SELECT 1 FROM game.users WHERE id = v_user_id AND prison_until > NOW()) THEN
        RETURN jsonb_build_object('success', false, 'error', 'You are in prison!');
    END IF;
    
    SELECT * INTO v_facility FROM public.facilities WHERE id = p_facility_id AND user_id = v_user_id;
    
    FOR v_queue_item IN 
        SELECT * FROM public.facility_queue 
        WHERE facility_id = p_facility_id AND completed_at <= v_now AND status = 'in_progress'
    LOOP
        SELECT * INTO v_recipe FROM public.facility_recipes WHERE id = v_queue_item.recipe_id;
        
        -- Raid Check
        v_raid_roll := floor(random() * 100);
        IF v_raid_roll < v_facility.suspicion THEN
            UPDATE public.facility_queue SET status = 'raided', is_raided = TRUE WHERE id = v_queue_item.id;
            v_raid_occurred := TRUE;
            
            -- PRISON LOGIC (50% Chance)
            IF floor(random() * 100) < 50 THEN
                v_prison_duration := GREATEST(10, v_facility.suspicion * 2); 
                
                -- Update game.users
                UPDATE game.users 
                SET prison_until = NOW() + (v_prison_duration || ' minutes')::INTERVAL,
                    prison_reason = 'Facility Raid: ' || v_facility.type
                WHERE id = v_user_id;
                
                UPDATE public.facilities SET suspicion = 0 WHERE id = p_facility_id;
                
                RETURN jsonb_build_object(
                    'success', true, 'raid', true, 'prison', true, 
                    'prison_time', v_prison_duration,
                    'collected_count', v_success_count
                );
            ELSE
                 UPDATE public.facilities SET suspicion = GREATEST(0, suspicion - 30) WHERE id = p_facility_id;
            END IF;
            
            CONTINUE; 
        END IF;
        
        -- Burn Check
        v_burn_roll := floor(random() * 100);
        IF v_burn_roll > v_recipe.success_rate THEN
            UPDATE public.facility_queue SET status = 'burned', is_burned = TRUE WHERE id = v_queue_item.id;
            v_burn_occurred := TRUE;
            CONTINUE;
        END IF;
        
        v_final_qty := v_recipe.output_quantity * v_queue_item.quantity;
        
        INSERT INTO public.inventory (user_id, item_id, quantity, obtained_at)
        VALUES (v_user_id, v_recipe.output_item_id, v_final_qty, v_now);
        
        UPDATE public.facility_queue SET status = 'completed' WHERE id = v_queue_item.id;
        v_success_count := v_success_count + 1;
        
    END LOOP;
    
    RETURN jsonb_build_object(
        'success', true, 
        'raid', v_raid_occurred, 
        'burn', v_burn_occurred, 
        'collected_count', v_success_count
    );
END;
$$;
-- Create market_orders table if not exists
CREATE TABLE IF NOT EXISTS public.market_orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    seller_id UUID REFERENCES auth.users(id) NOT NULL,
    item_id TEXT NOT NULL, -- The base item_id (e.g. 'weapon_sword')
    quantity INT NOT NULL CHECK (quantity > 0),
    price INT NOT NULL CHECK (price >= 0),
    region_id INT DEFAULT 1,
    listed_at BIGINT DEFAULT extract(epoch from now())::bigint,
    item_data JSONB DEFAULT '{}'::jsonb, -- Instance specific data (enhancement, stats)
    
    constraint valid_quantity check (quantity > 0)
);

-- Enable RLS
ALTER TABLE public.market_orders ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read orders (Idempotent: Drop first)
DROP POLICY IF EXISTS "Public read market orders" ON public.market_orders;
CREATE POLICY "Public read market orders" ON public.market_orders
    FOR SELECT USING (true);

-- Allow users to manage their own orders
DROP POLICY IF EXISTS "Users manage own orders" ON public.market_orders;
CREATE POLICY "Users manage own orders" ON public.market_orders
    FOR ALL USING (auth.uid() = seller_id);


-- RPC: Place Sell Order
-- Removes item from inventory and creates a market listing
CREATE OR REPLACE FUNCTION place_sell_order(
    p_item_row_id UUID, -- The UUID of the row in inventory
    p_quantity INT,
    p_price INT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_item_record RECORD;
    v_item_data JSONB;
BEGIN
    v_user_id := auth.uid();
    
    -- 1. Verify item ownership and quantity
    SELECT * INTO v_item_record
    FROM public.inventory
    WHERE row_id = p_item_row_id AND user_id = v_user_id;
    
    IF v_item_record IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Item not found');
    END IF;
    
    IF v_item_record.quantity < p_quantity THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not enough quantity');
    END IF;

    IF v_item_record.is_equipped = TRUE THEN
        RETURN jsonb_build_object('success', false, 'error', 'Cannot sell equipped item');
    END IF;

    -- 2. Prepare Item Data (Snapshot stats, enhancement, etc.)
    -- Note: inventory table uses enhancement_level, not upgrade_level
    v_item_data := jsonb_build_object(
        'enhancement_level', v_item_record.enhancement_level, 
        'obtained_at', v_item_record.obtained_at
    );

    -- 3. Create Market Order
    INSERT INTO public.market_orders (
        seller_id, item_id, quantity, price, item_data
    ) VALUES (
        v_user_id, v_item_record.item_id, p_quantity, p_price, v_item_data
    );

    -- 4. Update Inventory
    IF v_item_record.quantity = p_quantity THEN
        -- Sold all -> Delete row
        DELETE FROM public.inventory WHERE row_id = p_item_row_id;
    ELSE
        -- Sold partial -> Decrease quantity
        UPDATE public.inventory 
        SET quantity = quantity - p_quantity 
        WHERE row_id = p_item_row_id;
    END IF;

    RETURN jsonb_build_object('success', true);
END;
$$;

-- RPC: Cancel Sell Order
-- Restores item to inventory if space exists
CREATE OR REPLACE FUNCTION cancel_sell_order(
    p_order_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_order_record RECORD;
    v_slot INT;
BEGIN
    v_user_id := auth.uid();
    
    -- 1. Find Order
    SELECT * INTO v_order_record
    FROM public.market_orders
    WHERE id = p_order_id AND seller_id = v_user_id;
    
    IF v_order_record IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Order not found');
    END IF;
    
    -- 2. Check Inventory Space using Helper
    -- We'll assume the helper handles finding a slot
    -- If we support stacking on return (optional for v1), we'd check that here.
    
    v_slot := public._find_first_empty_slot(v_user_id);
    
    IF v_slot IS NULL THEN
         RETURN jsonb_build_object('success', false, 'error', 'Inventory full');
    END IF;

    -- 3. Restore Item
    INSERT INTO public.inventory (
       user_id, item_id, quantity, slot_position, 
       enhancement_level, obtained_at, is_equipped, row_id
    ) VALUES (
       v_user_id, 
       v_order_record.item_id, 
       v_order_record.quantity, 
       v_slot, 
       (v_order_record.item_data->>'enhancement_level')::int,
       (v_order_record.item_data->>'obtained_at')::bigint,
       FALSE,
       gen_random_uuid()
    );

    -- 4. Delete Order
    DELETE FROM public.market_orders WHERE id = p_order_id;
    
    RETURN jsonb_build_object('success', true);
END;
$$;
