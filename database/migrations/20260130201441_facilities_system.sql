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
