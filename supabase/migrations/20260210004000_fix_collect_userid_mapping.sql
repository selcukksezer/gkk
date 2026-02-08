-- Migration: Fix collect_facility_resources_v2 user id mapping
-- Ensures we resolve auth.uid() to users.id before comparing to facility.user_id and prison_records.user_id

DROP FUNCTION IF EXISTS public.collect_facility_resources_v2(UUID, BIGINT, INT) CASCADE;

CREATE OR REPLACE FUNCTION public.collect_facility_resources_v2(
    p_facility_id UUID,
    p_seed BIGINT,
    p_total_count INT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_auth_id UUID := auth.uid();
    v_user_id UUID; -- users.id
    v_facility RECORD;
    v_now TIMESTAMPTZ := NOW();
    v_generated_items JSONB := '[]'::jsonb;
    v_new_global_suspicion INT;
    v_prison_roll FLOAT;
    v_prison_chance INT;
    v_prison_log TEXT := '';
    v_admission_occurs BOOLEAN := false;
BEGIN
    -- Resolve auth UID to users.id
    SELECT id, COALESCE(global_suspicion_level, 0) INTO v_user_id, v_new_global_suspicion
    FROM public.users WHERE auth_id = v_auth_id;

    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'User not found');
    END IF;

    -- Ensure facility belongs to this user (by users.id)
    SELECT * INTO v_facility FROM public.facilities
    WHERE id = p_facility_id AND user_id = v_user_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Facility not found');
    END IF;

    -- Keep production & item generation behavior unchanged (omitted here)

    UPDATE public.facilities SET
        last_production_collected_at = v_now,
        production_started_at = NULL,
        suspicion_level = GREATEST(0, suspicion_level - 10)
    WHERE id = p_facility_id;

    v_prison_chance := 20 + v_new_global_suspicion;
    v_prison_roll := (((p_seed + 19) * 16807) % 2147483647) / 2147483647.0 * 100;

    v_prison_log := '[collect_facility_resources_v2] PRISON CHECK: global_suspicion=' || v_new_global_suspicion
        || ', prison_chance=' || v_prison_chance
        || ', roll=' || (ROUND(v_prison_roll::NUMERIC, 2))::TEXT
        || ', within_chance=' || (CASE WHEN v_prison_roll < v_prison_chance THEN 'true' ELSE 'false' END);

    v_admission_occurs := (v_prison_roll < v_prison_chance) AND NOT EXISTS (
        SELECT 1 FROM public.prison_records WHERE user_id = v_user_id AND released_at IS NULL
    );

    RAISE LOG '%', v_prison_log;
    RAISE LOG '[collect_facility_resources_v2] ADMISSION OCCURS: %', v_admission_occurs;

    IF v_admission_occurs THEN
        PERFORM admit_to_prison(p_facility_id, v_new_global_suspicion);
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'message', 'Resources collected successfully',
        'count', COALESCE(p_total_count, 0),
        'items_generated', v_generated_items,
        'prison_check', jsonb_build_object(
            'global_suspicion', v_new_global_suspicion,
            'prison_chance', v_prison_chance,
            'prison_roll', ROUND(v_prison_roll::NUMERIC, 2),
            'admission_occurred', v_admission_occurs,
            'prison_log', v_prison_log
        )
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.collect_facility_resources_v2(UUID, BIGINT, INT) TO authenticated;
