-- Fix release_from_prison to use auth_id instead of id
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

    -- Use public.users with auth_id
    SELECT * INTO v_user FROM public.users WHERE auth_id = v_user_id;

    IF v_user IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'User not found in public.users'); END IF;

    IF v_user.prison_until IS NULL OR v_user.prison_until <= v_now THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not in prison');
    END IF;

    IF p_use_bail THEN
        v_remaining_mins := CEIL(EXTRACT(EPOCH FROM (v_user.prison_until - v_now)) / 60);
        v_bail_gems := GREATEST(1, v_remaining_mins);

        IF v_user.gems < v_bail_gems THEN
            RETURN jsonb_build_object('success', false, 'error', 'Insufficient gems', 'cost', v_bail_gems);
        END IF;

        -- Deduct gems and release
        UPDATE public.users SET
            gems = gems - v_bail_gems,
            in_prison = false,
            prison_until = NULL,
            prison_reason = NULL,
            updated_at = v_now
        WHERE auth_id = v_user_id;

        RETURN jsonb_build_object('success', true, 'message', 'Released from prison via bail', 'gems_spent', v_bail_gems);
    ELSE
        -- Time-based release
        UPDATE public.users SET
            in_prison = false,
            prison_until = NULL,
            prison_reason = NULL,
            updated_at = v_now
        WHERE auth_id = v_user_id;

        RETURN jsonb_build_object('success', true, 'message', 'Prison time served');
    END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION release_from_prison(boolean) TO authenticated;