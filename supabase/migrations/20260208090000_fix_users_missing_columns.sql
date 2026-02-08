-- ================================================================================
-- GÖLGE KRALLIK: Register Hatası Düzeltme
-- public.users - Eksik Sütunları Ekle (gems dahil)
-- ================================================================================

-- game schema yoksa oluştur
CREATE SCHEMA IF NOT EXISTS game;

-- public.users tablosu yoksa oluştur
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    display_name TEXT
);

-- Eksik sütunları ekle
DO $$
BEGIN
    ALTER TABLE public.users ADD COLUMN IF NOT EXISTS gems INT DEFAULT 100;
    ALTER TABLE public.users ADD COLUMN IF NOT EXISTS energy INT DEFAULT 100;
    ALTER TABLE public.users ADD COLUMN IF NOT EXISTS max_energy INT DEFAULT 100;
    ALTER TABLE public.users ADD COLUMN IF NOT EXISTS attack INT DEFAULT 10;
    ALTER TABLE public.users ADD COLUMN IF NOT EXISTS defense INT DEFAULT 10;
    ALTER TABLE public.users ADD COLUMN IF NOT EXISTS health INT DEFAULT 100;
    ALTER TABLE public.users ADD COLUMN IF NOT EXISTS max_health INT DEFAULT 100;
    ALTER TABLE public.users ADD COLUMN IF NOT EXISTS power INT DEFAULT 0;
    ALTER TABLE public.users ADD COLUMN IF NOT EXISTS gold BIGINT DEFAULT 1000;
    ALTER TABLE public.users ADD COLUMN IF NOT EXISTS xp BIGINT DEFAULT 0;
    ALTER TABLE public.users ADD COLUMN IF NOT EXISTS experience INT DEFAULT 0;
    ALTER TABLE public.users ADD COLUMN IF NOT EXISTS level INT DEFAULT 1;
    ALTER TABLE public.users ADD COLUMN IF NOT EXISTS addiction_level INT DEFAULT 0;
    ALTER TABLE public.users ADD COLUMN IF NOT EXISTS tolerance INT DEFAULT 0;
    ALTER TABLE public.users ADD COLUMN IF NOT EXISTS in_hospital BOOLEAN DEFAULT FALSE;
    ALTER TABLE public.users ADD COLUMN IF NOT EXISTS hospital_until TIMESTAMP;
    ALTER TABLE public.users ADD COLUMN IF NOT EXISTS hospital_reason TEXT;
    ALTER TABLE public.users ADD COLUMN IF NOT EXISTS in_prison BOOLEAN DEFAULT FALSE;
    ALTER TABLE public.users ADD COLUMN IF NOT EXISTS prison_until TIMESTAMPTZ;
    ALTER TABLE public.users ADD COLUMN IF NOT EXISTS prison_reason TEXT;
    ALTER TABLE public.users ADD COLUMN IF NOT EXISTS pvp_wins INT DEFAULT 0;
    ALTER TABLE public.users ADD COLUMN IF NOT EXISTS pvp_losses INT DEFAULT 0;
    ALTER TABLE public.users ADD COLUMN IF NOT EXISTS pvp_rating INT DEFAULT 1000;
    ALTER TABLE public.users ADD COLUMN IF NOT EXISTS reputation INT DEFAULT 0;
    ALTER TABLE public.users ADD COLUMN IF NOT EXISTS avatar_url TEXT;
    ALTER TABLE public.users ADD COLUMN IF NOT EXISTS referral_code TEXT UNIQUE;
    ALTER TABLE public.users ADD COLUMN IF NOT EXISTS referred_by UUID;
    ALTER TABLE public.users ADD COLUMN IF NOT EXISTS guild_id UUID;
    ALTER TABLE public.users ADD COLUMN IF NOT EXISTS guild_role TEXT;
    ALTER TABLE public.users ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
    ALTER TABLE public.users ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Column addition error: %', SQLERRM;
END $$;

-- Trigger: auth.users'a yeni kayıt olunca public.users'a profil oluştur
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, game
AS $$
BEGIN
    INSERT INTO public.users (auth_id, email, username, display_name)
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
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

ALTER ROLE authenticated SET pgrst.db_schemas TO 'public,game';

-- Grant minimal privileges so PostgREST (`authenticated`) can access game schema
GRANT USAGE ON SCHEMA game TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA game TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA game GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;

-- Schema cache reload
NOTIFY pgrst, 'reload schema';

-- Schema cache reload
NOTIFY pgrst, 'reload schema';
