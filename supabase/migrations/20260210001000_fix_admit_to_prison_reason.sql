-- Migration: Fix admit_to_prison to always insert non-null reason
-- Drops existing function and recreates it with explicit `reason` column

DROP FUNCTION IF EXISTS public.admit_to_prison(UUID, INT) CASCADE;

CREATE OR REPLACE FUNCTION public.admit_to_prison(
    p_facility_id UUID,
    p_suspicion_level INT DEFAULT 80
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_sentence_hours INT;
    v_release_time TIMESTAMPTZ;
    v_prison_record_id UUID;
BEGIN
    v_user_id := auth.uid();

    IF NOT EXISTS (
        SELECT 1 FROM public.facilities 
        WHERE id = p_facility_id AND user_id = v_user_id
    ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Facility not found');
    END IF;

    IF EXISTS (
        SELECT 1 FROM public.prison_records
        WHERE user_id = v_user_id AND released_at IS NULL
    ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Already in prison');
    END IF;

    v_sentence_hours := 2 + (p_suspicion_level / 10);
    v_release_time := NOW() + (v_sentence_hours || ' hours')::INTERVAL;

    INSERT INTO public.prison_records (
        user_id, facility_id, reason, sentence_hours, admitted_at, released_at
    ) VALUES (
        v_user_id, p_facility_id, 'High suspicion at facility operations', v_sentence_hours, NOW(), v_release_time
    ) RETURNING id INTO v_prison_record_id;

    UPDATE public.facilities
    SET suspicion_level = 0
    WHERE id = p_facility_id;

    UPDATE public.users
    SET in_prison = true,
        hospital_until = v_release_time
    WHERE id = v_user_id;

    RETURN jsonb_build_object(
        'success', true,
        'message', 'Admitted to prison',
        'prison_record_id', v_prison_record_id,
        'sentence_hours', v_sentence_hours,
        'release_time', v_release_time
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.admit_to_prison(UUID, INT) TO authenticated;
