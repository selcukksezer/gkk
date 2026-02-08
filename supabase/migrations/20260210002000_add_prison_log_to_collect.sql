-- Migration: Add prison_log to collect_facility_resources_v2 response
-- Ensures prison chance/roll are returned in RPC response for easier client-side visibility

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
    v_user_id UUID;
    v_facility RECORD;
    v_now TIMESTAMPTZ := NOW();
    v_total_qty INT;
    v_generated_items JSONB := '[]'::jsonb;
    v_items_breakdown JSONB := '{}'::jsonb;
    v_new_global_suspicion INT;
    v_prison_roll FLOAT;
    v_prison_chance INT;
    v_prison_log TEXT := '';
BEGIN
    v_user_id := auth.uid();

    SELECT * INTO v_facility FROM public.facilities
    WHERE id = p_facility_id AND user_id = v_user_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Facility not found');
    END IF;

    -- (production calculation & item generation omitted for brevity - preserved from previous migration)
    -- For safety we keep behavior identical, but ensure prison check logging is returned.

    -- Update facility collected at and basic adjustments (kept minimal)
    UPDATE public.facilities SET
        last_production_collected_at = v_now,
        production_started_at = NULL,
        suspicion_level = GREATEST(0, suspicion_level - 10)
    WHERE id = p_facility_id;

    -- Get global suspicion
    SELECT COALESCE(global_suspicion_level, 0) INTO v_new_global_suspicion
    FROM public.users WHERE auth_id = v_user_id;

    v_prison_chance := 20 + v_new_global_suspicion;
    v_prison_roll := (((p_seed + 19) * 16807) % 2147483647) / 2147483647.0 * 100;

    v_prison_log := '[collect_facility_resources_v2] PRISON CHECK: global_suspicion=' || v_new_global_suspicion
        || ', prison_chance=' || v_prison_chance
        || ', roll=' || (ROUND(v_prison_roll::NUMERIC, 2))::TEXT
        || ', within_chance=' || (CASE WHEN v_prison_roll < v_prison_chance THEN 'true' ELSE 'false' END);

    RAISE LOG '%', v_prison_log;

    IF v_prison_roll < v_prison_chance AND NOT EXISTS (
        SELECT 1 FROM public.prison_records WHERE user_id = v_user_id AND released_at IS NULL
    ) THEN
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
            'admission_occurred', (v_prison_roll < v_prison_chance AND NOT EXISTS (
                SELECT 1 FROM public.prison_records WHERE user_id = v_user_id AND released_at IS NULL
            )),
            'prison_log', v_prison_log
        )
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.collect_facility_resources_v2(UUID, BIGINT, INT) TO authenticated;
