-- ============================================
-- AUTHENTICATION & USERS TABLE
-- ============================================
-- This creates the core users table for game data
-- Integrates with Supabase Auth (auth.users)

-- Create users table for game data
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- User Info
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    display_name TEXT,
    avatar_url TEXT,
    
    -- Game Stats
    level INT DEFAULT 1,
    experience INT DEFAULT 0,
    gold INT DEFAULT 1000,
    energy INT DEFAULT 100,
    max_energy INT DEFAULT 100,
    energy_last_updated TIMESTAMPTZ DEFAULT NOW(),
    
    -- Player Stats
    attack INT DEFAULT 10,
    defense INT DEFAULT 10,
    health INT DEFAULT 100,
    max_health INT DEFAULT 100,
    power INT DEFAULT 0,
    
    -- Status
    is_online BOOLEAN DEFAULT FALSE,
    is_banned BOOLEAN DEFAULT FALSE,
    ban_reason TEXT,
    banned_until TIMESTAMPTZ,
    
    -- Progression
    tutorial_completed BOOLEAN DEFAULT FALSE,
    last_daily_reward TIMESTAMPTZ,
    total_playtime_seconds INT DEFAULT 0,
    
    -- Social
    guild_id UUID,
    guild_role TEXT,
    referral_code TEXT UNIQUE,
    referred_by UUID REFERENCES public.users(id),
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_login_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_auth_id ON public.users(auth_id);
CREATE INDEX IF NOT EXISTS idx_users_username ON public.users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_level ON public.users(level);
CREATE INDEX IF NOT EXISTS idx_users_guild_id ON public.users(guild_id);
CREATE INDEX IF NOT EXISTS idx_users_referral_code ON public.users(referral_code);
CREATE INDEX IF NOT EXISTS idx_users_referred_by ON public.users(referred_by);

-- Enable Row Level Security
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read their own data
CREATE POLICY users_select_own ON public.users
    FOR SELECT
    USING (auth.uid() = auth_id);

-- Policy: Users can update their own data (limited fields)
CREATE POLICY users_update_own ON public.users
    FOR UPDATE
    USING (auth.uid() = auth_id)
    WITH CHECK (auth.uid() = auth_id);

-- Policy: Allow reading other users' public data (for leaderboards, PvP, etc.)
CREATE POLICY users_select_public ON public.users
    FOR SELECT
    USING (true);

-- Function to generate unique referral code
CREATE OR REPLACE FUNCTION generate_referral_code()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
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

-- Trigger to auto-generate referral code
CREATE OR REPLACE FUNCTION set_referral_code()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.referral_code IS NULL THEN
        NEW.referral_code := generate_referral_code();
        -- Ensure uniqueness
        WHILE EXISTS (SELECT 1 FROM public.users WHERE referral_code = NEW.referral_code) LOOP
            NEW.referral_code := generate_referral_code();
        END LOOP;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_set_referral_code
    BEFORE INSERT ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION set_referral_code();

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to create user profile after auth signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Create user profile in public.users
    INSERT INTO public.users (auth_id, email, username, display_name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1))
    );
    RETURN NEW;
END;
$$;

-- Trigger on auth.users to auto-create game profile
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON public.users TO authenticated;
GRANT SELECT ON public.users TO anon;

-- RPC function to get current user profile
CREATE OR REPLACE FUNCTION public.get_current_user()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_user JSONB;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;
    
    SELECT jsonb_build_object(
        'id', id,
        'auth_id', auth_id,
        'username', username,
        'email', email,
        'display_name', display_name,
        'avatar_url', avatar_url,
        'level', level,
        'experience', experience,
        'gold', gold,
        'energy', energy,
        'max_energy', max_energy,
        'attack', attack,
        'defense', defense,
        'health', health,
        'max_health', max_health,
        'power', power,
        'tutorial_completed', tutorial_completed,
        'guild_id', guild_id,
        'guild_role', guild_role,
        'referral_code', referral_code,
        'created_at', created_at,
        'last_login_at', last_login_at
    )
    INTO v_user
    FROM public.users
    WHERE auth_id = v_user_id;
    
    IF v_user IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'User profile not found');
    END IF;
    
    RETURN jsonb_build_object('success', true, 'data', v_user);
END;
$$;

-- RPC function to update user profile
CREATE OR REPLACE FUNCTION public.update_user_profile(
    p_display_name TEXT DEFAULT NULL,
    p_avatar_url TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;
    
    UPDATE public.users
    SET
        display_name = COALESCE(p_display_name, display_name),
        avatar_url = COALESCE(p_avatar_url, avatar_url),
        updated_at = NOW()
    WHERE auth_id = v_user_id;
    
    RETURN jsonb_build_object('success', true, 'message', 'Profile updated');
END;
$$;

-- RPC function to update last login time
CREATE OR REPLACE FUNCTION public.update_last_login()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;
    
    UPDATE public.users
    SET last_login_at = NOW()
    WHERE auth_id = v_user_id;
    
    RETURN jsonb_build_object('success', true);
END;
$$;
