-- ============================================================
-- PRISON BAIL + HOSPITAL GEM RELEASE — gkk-web uyumlu
-- Kaynak: PrisonScreen.gd + HospitalScreen.gd
-- RPCs: prison_bail, hospital_release_with_gems (alias),
--        check_prison_status (auto-check)
-- ============================================================

-- ============================================================
-- 1. RPC: prison_bail
-- Godot: PrisonManager.pay_bail()
-- Matches gkk-web: api.rpc("prison_bail", { p_method: "gems", p_cost })
-- ============================================================
CREATE OR REPLACE FUNCTION public.prison_bail(
    p_method TEXT DEFAULT 'gems',
    p_cost   INT  DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id       UUID;
    v_user          RECORD;
    v_seconds_left  INT;
    v_gem_cost      INT;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT * INTO v_user FROM public.users WHERE auth_id = v_user_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Kullanıcı bulunamadı');
    END IF;

    -- Not in prison check
    IF v_user.in_prison = FALSE OR v_user.prison_until IS NULL OR v_user.prison_until <= NOW() THEN
        -- Already free — just update status
        UPDATE public.users SET in_prison = FALSE, prison_until = NULL, prison_reason = NULL, updated_at = NOW()
        WHERE auth_id = v_user_id;
        RETURN jsonb_build_object('success', true, 'message', 'Zaten serbest');
    END IF;

    -- Calculate cost (Godot: ceil(seconds/60))
    v_seconds_left := GREATEST(0, EXTRACT(EPOCH FROM (v_user.prison_until - NOW()))::INT);
    v_gem_cost := CEIL(v_seconds_left::NUMERIC / 60)::INT;

    -- Validate provided cost matches
    IF p_cost > 0 AND p_cost < v_gem_cost THEN
        -- Accept if within 1 gem tolerance (clock drift)
        IF v_gem_cost - p_cost > 1 THEN
            RETURN jsonb_build_object('success', false, 'error', format('Gem maliyeti hatalı. Beklenen: %s', v_gem_cost));
        END IF;
        v_gem_cost := p_cost; -- Accept client value within tolerance
    END IF;

    -- Check gems
    IF v_user.gems < v_gem_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Yetersiz elmas', 'required', v_gem_cost, 'current', v_user.gems);
    END IF;

    -- Deduct gems and release
    UPDATE public.users
    SET gems         = gems - v_gem_cost,
        in_prison    = FALSE,
        prison_until = NULL,
        prison_reason = NULL,
        updated_at   = NOW()
    WHERE auth_id = v_user_id;

    -- Update prison record
    UPDATE public.prison_records
    SET released_at = NOW()
    WHERE user_id = v_user_id AND released_at IS NULL;

    RETURN jsonb_build_object(
        'success',   TRUE,
        'cost',      v_gem_cost,
        'message',   'Kefaletle serbest bırakıldınız'
    );
END;
$$;

-- ============================================================
-- 2. RPC: hospital_release_with_gems (alias for release_from_hospital)
-- Godot: HospitalManager.release_with_gems()
-- NOTE: release_from_hospital already exists in hospital_functions.sql
-- This ensures the exact RPC name gkk-web uses works too
-- ============================================================
CREATE OR REPLACE FUNCTION public.hospital_release_with_gems()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id      UUID;
    v_user         RECORD;
    v_seconds_left INT;
    v_gem_cost     INT;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT * INTO v_user FROM public.users WHERE auth_id = v_user_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Kullanıcı bulunamadı');
    END IF;

    -- Not in hospital check
    IF v_user.in_hospital = FALSE OR v_user.hospital_until IS NULL OR v_user.hospital_until <= NOW() THEN
        UPDATE public.users SET in_hospital = FALSE, hospital_until = NULL, hospital_reason = NULL, updated_at = NOW()
        WHERE auth_id = v_user_id;
        RETURN jsonb_build_object('success', true, 'message', 'Zaten serbest');
    END IF;

    -- Gem cost formula (Godot: hours + ceil(remaining_minutes))
    v_seconds_left := GREATEST(0, EXTRACT(EPOCH FROM (v_user.hospital_until - NOW()))::INT);
    DECLARE
        v_hours   INT := v_seconds_left / 3600;
        v_minutes INT := CEIL((v_seconds_left % 3600)::NUMERIC / 60)::INT;
    BEGIN
        v_gem_cost := v_hours + v_minutes;
    END;

    -- Check gems
    IF v_user.gems < v_gem_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Yetersiz elmas', 'required', v_gem_cost, 'current', v_user.gems);
    END IF;

    -- Deduct and release
    UPDATE public.users
    SET gems           = gems - v_gem_cost,
        in_hospital    = FALSE,
        hospital_until = NULL,
        hospital_reason = NULL,
        updated_at     = NOW()
    WHERE auth_id = v_user_id;

    RETURN jsonb_build_object(
        'success',  TRUE,
        'cost',     v_gem_cost,
        'message',  'Taburcu edildiniz'
    );
END;
$$;

-- ============================================================
-- 3. RPC: check_prison_status
-- Godot: PrisonScreen — auto-check if sentence is over
-- ============================================================
CREATE OR REPLACE FUNCTION public.check_prison_status()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id    UUID;
    v_user       RECORD;
    v_released   BOOLEAN := FALSE;
    v_seconds_left INT;
    v_gem_cost   INT;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT auth_id, in_prison, prison_until, prison_reason, gems INTO v_user
    FROM public.users WHERE auth_id = v_user_id;

    -- Auto-release if sentence expired
    IF v_user.in_prison = TRUE AND v_user.prison_until IS NOT NULL AND v_user.prison_until <= NOW() THEN
        UPDATE public.users
        SET in_prison = FALSE, prison_until = NULL, prison_reason = NULL, updated_at = NOW()
        WHERE auth_id = v_user_id;

        UPDATE public.prison_records SET released_at = NOW()
        WHERE user_id = v_user_id AND released_at IS NULL;

        v_released := TRUE;
    END IF;

    -- Re-read status
    SELECT in_prison, prison_until, prison_reason, gems INTO v_user FROM public.users WHERE auth_id = v_user_id;

    v_seconds_left := 0;
    v_gem_cost := 0;
    IF v_user.in_prison AND v_user.prison_until IS NOT NULL THEN
        v_seconds_left := GREATEST(0, EXTRACT(EPOCH FROM (v_user.prison_until - NOW()))::INT);
        v_gem_cost := CEIL(v_seconds_left::NUMERIC / 60)::INT;
    END IF;

    RETURN jsonb_build_object(
        'in_prison',    COALESCE(v_user.in_prison, FALSE),
        'prison_until', v_user.prison_until,
        'prison_reason',v_user.prison_reason,
        'seconds_left', v_seconds_left,
        'gem_cost',     v_gem_cost,
        'auto_released',v_released
    );
END;
$$;

-- ============================================================
-- 4. RPC: check_hospital_status
-- Godot: HospitalScreen — auto-check if treatment is over
-- ============================================================
CREATE OR REPLACE FUNCTION public.check_hospital_status()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id    UUID;
    v_user       RECORD;
    v_released   BOOLEAN := FALSE;
    v_seconds_left INT;
    v_gem_cost   INT;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT auth_id, in_hospital, hospital_until, hospital_reason, gems INTO v_user
    FROM public.users WHERE auth_id = v_user_id;

    -- Auto-release if treatment completed
    IF v_user.in_hospital = TRUE AND v_user.hospital_until IS NOT NULL AND v_user.hospital_until <= NOW() THEN
        UPDATE public.users
        SET in_hospital = FALSE, hospital_until = NULL, hospital_reason = NULL, updated_at = NOW()
        WHERE auth_id = v_user_id;
        v_released := TRUE;
    END IF;

    -- Re-read status
    SELECT in_hospital, hospital_until, hospital_reason, gems INTO v_user FROM public.users WHERE auth_id = v_user_id;

    v_seconds_left := 0;
    v_gem_cost := 0;
    IF v_user.in_hospital AND v_user.hospital_until IS NOT NULL THEN
        v_seconds_left := GREATEST(0, EXTRACT(EPOCH FROM (v_user.hospital_until - NOW()))::INT);
        DECLARE
            v_hours   INT := v_seconds_left / 3600;
            v_minutes INT := CEIL((v_seconds_left % 3600)::NUMERIC / 60)::INT;
        BEGIN
            v_gem_cost := v_hours + v_minutes;
        END;
    END IF;

    RETURN jsonb_build_object(
        'in_hospital',    COALESCE(v_user.in_hospital, FALSE),
        'hospital_until', v_user.hospital_until,
        'hospital_reason',v_user.hospital_reason,
        'seconds_left',   v_seconds_left,
        'gem_cost',       v_gem_cost,
        'auto_released',  v_released
    );
END;
$$;

NOTIFY pgrst, 'reload schema';
