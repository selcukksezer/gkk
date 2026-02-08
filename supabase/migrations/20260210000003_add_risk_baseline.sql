-- Migration: Add risk_baseline column for Baseline Risk system
-- Instead of using cooldown flags, we store the risk % at time of bribe as a baseline
-- Then subtract baseline from calculated risk to show only newly accumulated risk

ALTER TABLE public.users ADD COLUMN IF NOT EXISTS risk_baseline FLOAT DEFAULT 0;

-- Update bribe_officials to save current risk as baseline
CREATE OR REPLACE FUNCTION public.bribe_officials(
    p_facility_type TEXT, 
    p_amount_gems INT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_user_uuid UUID;
    v_current_gems INT;
    v_global_suspicion INT;
BEGIN
    v_user_id := auth.uid();
    
    RAISE LOG '[bribe_officials] User: %, Facility Type: %, Gems: %', v_user_id, p_facility_type, p_amount_gems;
    
    -- Get user's actual UUID from users table using auth_id
    SELECT id, gems, global_suspicion_level 
    INTO v_user_uuid, v_current_gems, v_global_suspicion
    FROM public.users 
    WHERE auth_id = v_user_id;
    
    IF v_user_uuid IS NULL THEN
        RAISE LOG '[bribe_officials] User not found with auth_id: %', v_user_id;
        RETURN jsonb_build_object('success', false, 'error', 'User not found');
    END IF;
    
    IF v_current_gems < p_amount_gems THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient gems');
    END IF;
    
    -- Check if there's any global suspicion to bribe away
    IF v_global_suspicion <= 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'No suspicion to bribe away');
    END IF;
    
    -- Deduct gems, reset global_suspicion to 0, and set risk_baseline to current risk
    UPDATE public.users
    SET gems = gems - p_amount_gems,
        global_suspicion_level = 0,
        risk_baseline = v_global_suspicion
    WHERE auth_id = v_user_id;
    
    RAISE LOG '[bribe_officials] Successfully bribed. Baseline set to: %, gems spent: %', v_global_suspicion, p_amount_gems;
    
    RETURN jsonb_build_object(
        'success', true, 
        'message', 'Bribed successfully',
        'new_suspicion', 0,
        'gems_spent', p_amount_gems,
        'baseline_set', v_global_suspicion,
        'global_suspicion_before', v_global_suspicion,
        'global_suspicion_after', 0
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.bribe_officials(TEXT, INT) TO authenticated;

-- Update update_global_suspicion_level to subtract baseline from calculated risk
CREATE OR REPLACE FUNCTION public.update_global_suspicion_level(
    p_global_suspicion INT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_risk_baseline FLOAT;
    v_adjusted_risk INT;
    v_new_level INT;
BEGIN
    v_user_id := auth.uid();
    
    RAISE LOG '[update_global_suspicion_level] User: %, Calculated risk: %', v_user_id, p_global_suspicion;
    
    IF v_user_id IS NULL THEN
        RAISE LOG '[update_global_suspicion_level] auth.uid() returned NULL';
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;
    
    -- Get current risk baseline
    SELECT risk_baseline 
    INTO v_risk_baseline
    FROM public.users 
    WHERE auth_id = v_user_id;
    
    IF NOT FOUND THEN
        RAISE LOG '[update_global_suspicion_level] User not found: %', v_user_id;
        RETURN jsonb_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Calculate adjusted risk: subtract baseline, clamp to 0-100
    v_adjusted_risk := GREATEST(0, LEAST(100, p_global_suspicion - v_risk_baseline));
    
    RAISE LOG '[update_global_suspicion_level] Baseline: %, Calculated: %, Adjusted: %', v_risk_baseline, p_global_suspicion, v_adjusted_risk;
    
    -- Update global suspicion level with adjusted risk
    UPDATE public.users
    SET global_suspicion_level = v_adjusted_risk,
        updated_at = NOW()
    WHERE auth_id = v_user_id
    RETURNING global_suspicion_level INTO v_new_level;
    
    RAISE LOG '[update_global_suspicion_level] Successfully updated to: %', v_new_level;
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Global suspicion level updated',
        'new_level', v_new_level,
        'baseline', v_risk_baseline,
        'calculated_risk', p_global_suspicion
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_global_suspicion_level(INT) TO authenticated;
