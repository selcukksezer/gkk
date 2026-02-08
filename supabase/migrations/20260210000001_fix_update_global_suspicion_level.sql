-- Migration: Fix update_global_suspicion_level RPC to properly write to database
-- Issue: RPC was returning success but not actually updating the database
-- Solution: Recreate function with proper RETURNING clause and FOUND check

DROP FUNCTION IF EXISTS public.update_global_suspicion_level(INT);

CREATE OR REPLACE FUNCTION public.update_global_suspicion_level(
    p_global_suspicion INT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_new_level INT;
BEGIN
    v_user_id := auth.uid();
    
    RAISE LOG '[update_global_suspicion_level] User: %, Setting suspicion to: %', v_user_id, p_global_suspicion;
    
    IF v_user_id IS NULL THEN
        RAISE LOG '[update_global_suspicion_level] auth.uid() returned NULL';
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;
    
    UPDATE public.users
    SET global_suspicion_level = GREATEST(0, LEAST(100, p_global_suspicion)),
        updated_at = NOW()
    WHERE auth_id = v_user_id
    RETURNING global_suspicion_level INTO v_new_level;
    
    IF NOT FOUND THEN
        RAISE LOG '[update_global_suspicion_level] User not found: %', v_user_id;
        RETURN jsonb_build_object('success', false, 'error', 'User not found');
    END IF;
    
    RAISE LOG '[update_global_suspicion_level] Successfully updated to: %', v_new_level;
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Global suspicion level updated',
        'new_level', v_new_level
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_global_suspicion_level(INT) TO authenticated;
