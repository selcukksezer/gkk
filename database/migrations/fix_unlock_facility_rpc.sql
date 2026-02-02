-- RPC: Unlock Facility (Fixed)
-- Fixes issue where inactive facilities blocked unlocking
-- Now reactivates inactive facilities instead of erroring

CREATE OR REPLACE FUNCTION unlock_facility(p_type TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_cost INT;
    v_facility RECORD;
BEGIN
    v_user_id := auth.uid();
    
    -- Check if facility exists (fetch full record)
    SELECT * INTO v_facility FROM public.facilities WHERE user_id = v_user_id AND type = p_type;
    
    -- If exists AND is actively running -> Error
    IF v_facility IS NOT NULL AND v_facility.is_active THEN
        RETURN jsonb_build_object('success', false, 'error', 'Facility already unlocked');
    END IF;
    
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
    
    -- Deduct Gold
    UPDATE game.users SET gold = gold - v_cost WHERE id = v_user_id;
    
    IF v_facility IS NOT NULL THEN
        -- Reactivate existing facility (Treat as 'Repairing/Re-opening')
        -- We won't reset level so if you mistakenly closed it, you keep progress.
        -- But we reset suspicion to be nice.
        UPDATE public.facilities 
        SET is_active = true, 
            suspicion = 0,
            updated_at = NOW()
        WHERE id = v_facility.id;
    ELSE
        -- Insert new facility
        INSERT INTO public.facilities (user_id, type, level, suspicion, is_active) 
        VALUES (v_user_id, p_type, 1, 0, true);
    END IF;
    
    RETURN jsonb_build_object('success', true);
END;
$$;
