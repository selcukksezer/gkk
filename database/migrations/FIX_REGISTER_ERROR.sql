-- ================================================================================
-- GÖLGE KRALLIK: Register Hatası Düzeltme
-- game.users - Eksik Sütunları Ekle
-- ================================================================================

-- Tablo varsa eksik sütunları ekle
DO $$
BEGIN
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS gems INT DEFAULT 100;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS energy INT DEFAULT 100;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS max_energy INT DEFAULT 100;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS attack INT DEFAULT 10;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS defense INT DEFAULT 10;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS health INT DEFAULT 100;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS max_health INT DEFAULT 100;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS power INT DEFAULT 0;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS gold BIGINT DEFAULT 1000;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS xp BIGINT DEFAULT 0;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS level INT DEFAULT 1;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS addiction_level INT DEFAULT 0;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS tolerance INT DEFAULT 0;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS in_hospital BOOLEAN DEFAULT FALSE;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS hospital_until TIMESTAMP;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS hospital_reason TEXT;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS in_prison BOOLEAN DEFAULT FALSE;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS prison_until TIMESTAMPTZ;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS prison_reason TEXT;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS pvp_wins INT DEFAULT 0;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS pvp_losses INT DEFAULT 0;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS pvp_rating INT DEFAULT 1000;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS reputation INT DEFAULT 0;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS guild_id UUID;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS guild_role TEXT;
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
    ALTER TABLE game.users ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
EXCEPTION WHEN OTHERS THEN 
    RAISE NOTICE 'Error message: %', SQLERRM;
END $$;

-- Schema cache'i temizle (Supabase için)
NOTIFY pgrst, 'reload schema';
