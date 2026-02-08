-- Migration: Remove conflicting global_suspicion_level updates from other RPC functions
-- Purpose: Centralize risk calculation to client-side only via update_global_suspicion_level RPC
-- Previously: increment_facility_suspicion and collect_facility_resources_v2 were both updating global_suspicion_level with AVG calculations
-- Now: Only client can update global_suspicion_level via update_global_suspicion_level RPC

-- Fix increment_facility_suspicion to NOT update global_suspicion_level
CREATE OR REPLACE FUNCTION public.increment_facility_suspicion(
    p_facility_id UUID,
    p_amount INT DEFAULT 1
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_new_suspicion INT;
BEGIN
    v_user_id := auth.uid();
    
    UPDATE public.facilities
    SET suspicion_level = LEAST(suspicion_level + p_amount, 100)
    WHERE id = p_facility_id AND user_id = v_user_id
    RETURNING suspicion_level INTO v_new_suspicion;
    
    IF v_new_suspicion IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Facility not found or not owned');
    END IF;
    
    -- NOTE: Don't update global_suspicion_level here!
    -- Client handles risk calculation and syncs via update_global_suspicion_level RPC
    -- This keeps risk sync centralized and prevents conflicts
    
    RETURN jsonb_build_object(
        'success', true,
        'facility_suspicion', v_new_suspicion,
        'global_suspicion', 0,
        'message', CASE WHEN v_new_suspicion >= 80 THEN 'High suspicion! Risk of prison!' ELSE 'OK' END
    );
END;
$$;

-- This function is used by collection, but the v2 version is now primary
-- Keeping minimal here to avoid conflicts
CREATE OR REPLACE FUNCTION public.collect_facility_resources(
    p_facility_id UUID,
    p_seed BIGINT,
    p_debug BOOLEAN DEFAULT false
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_message TEXT;
BEGIN
    v_user_id := auth.uid();
    
    -- This function is deprecated in favor of collect_facility_resources_v2
    -- It should not be used anymore. Redirecting to v2.
    RETURN jsonb_build_object(
        'success', false,
        'error', 'Use collect_facility_resources_v2 instead',
        'message', 'This function is deprecated. Use collect_facility_resources_v2 with p_total_count parameter.'
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.increment_facility_suspicion(UUID, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.collect_facility_resources(UUID, BIGINT, BOOLEAN) TO authenticated;
