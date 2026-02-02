-- RPC: Unlock Facility (Fixed v2 - Robust)
-- Uses INSERT ON CONFLICT to handle "duplicate key" errors definitively.
-- This bypasses any visibility/RLS issues that might hide the existing row from a SELECT check.

CREATE OR REPLACE FUNCTION unlock_facility(p_type TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_cost INT;
BEGIN
    v_user_id := auth.uid();
    
    -- Determine Cost
    v_cost := CASE 
        WHEN p_type = 'mine' THEN 1000
        WHEN p_type = 'farm' THEN 500
        WHEN p_type = 'lumber_mill' THEN 800
        ELSE 1000
    END;
    
    -- Check Balance
    IF (SELECT gold FROM game.users WHERE id = v_user_id) < v_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient gold');
    END IF;
    
    -- Check if it exists AND is already active (to prevent double-spending on accidental clicks)
    -- We can skip this check if we want to allow "repairing" simply by paying again, 
    -- but usually we want to block paying for something you already have.
    -- However, since the user is blocked by an error, let's trust the UI to hide buttons 
    -- and let the Database handle the "Make it true" logic.
    -- Better safe check:
    IF EXISTS (SELECT 1 FROM public.facilities WHERE user_id = v_user_id AND type = p_type AND is_active = true) THEN
         RETURN jsonb_build_object('success', false, 'error', 'Facility already unlocked');
    END IF;
    
    -- Deduct Gold
    UPDATE game.users SET gold = gold - v_cost WHERE id = v_user_id;
    
    -- Upsert: Insert, or if exists (Conflict), Reactivate it.
    INSERT INTO public.facilities (user_id, type, level, suspicion, is_active) 
    VALUES (v_user_id, p_type, 1, 0, true)
    ON CONFLICT (user_id, type) 
    DO UPDATE SET 
        is_active = true,
        suspicion = 0, -- Reset suspicion on re-open
        updated_at = NOW();

    RETURN jsonb_build_object('success', true);
END;
$$;
