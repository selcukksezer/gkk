-- Migration: Fix bribe_officials to use auth_id instead of id and take facility_type instead of facility_id
-- The bribe RPC was not resetting global_suspicion_level because it used wrong column

DROP FUNCTION IF EXISTS public.bribe_officials(UUID, INT);

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
    
    -- Deduct gems using auth_id
    UPDATE public.users
    SET gems = gems - p_amount_gems
    WHERE auth_id = v_user_id;
    
    -- RESET global suspicion to 0 using auth_id
    UPDATE public.users
    SET global_suspicion_level = 0
    WHERE auth_id = v_user_id;
    
    RAISE LOG '[bribe_officials] Successfully reset global suspicion from % to 0', v_global_suspicion;
    
    RETURN jsonb_build_object(
        'success', true, 
        'message', 'Bribed successfully',
        'new_suspicion', 0,
        'gems_spent', p_amount_gems,
        'global_suspicion_before', v_global_suspicion,
        'global_suspicion_after', 0
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.bribe_officials(TEXT, INT) TO authenticated;
