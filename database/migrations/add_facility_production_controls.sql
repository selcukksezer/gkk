-- Add production control columns to facilities
ALTER TABLE public.facilities 
ADD COLUMN IF NOT EXISTS production_started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- RPC: Start Facility Production
-- Deducts 50 Energy and resets production timer
CREATE OR REPLACE FUNCTION public.start_facility_production(
    p_facility_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_energy_cost INT := 50;
    v_current_energy INT;
    v_facility RECORD;
BEGIN
    v_user_id := auth.uid();
    
    -- Check facility ownership
    SELECT * INTO v_facility
    FROM public.facilities
    WHERE id = p_facility_id AND user_id = v_user_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Facility not found');
    END IF;

    -- Check user energy in game.users
    -- Try auth_id first (common pattern), then id
    SELECT energy INTO v_current_energy
    FROM game.users
    WHERE auth_id = v_user_id;
    
    -- Fallback: if auth_id didn't match, maybe id matches?
    IF v_current_energy IS NULL THEN
        SELECT energy INTO v_current_energy
        FROM game.users
        WHERE id = v_user_id;
    END IF;

    IF v_current_energy IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'User profile not found in game.users');
    END IF;

    IF v_current_energy < v_energy_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not enough energy', 'required', v_energy_cost, 'current', v_current_energy);
    END IF;

    -- Deduct Energy
    -- Update based on the same logic (auth_id preferred)
    UPDATE game.users
    SET energy = energy - v_energy_cost
    WHERE auth_id = v_user_id OR (auth_id IS NULL AND id = v_user_id);

    -- Update Facility Production Start Time
    UPDATE public.facilities
    SET production_started_at = NOW()
    WHERE id = p_facility_id;

    RETURN jsonb_build_object(
        'success', true,
        'message', 'Production started',
        'new_energy', v_current_energy - v_energy_cost,
        'production_started_at', NOW()
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

GRANT EXECUTE ON FUNCTION public.start_facility_production(UUID) TO authenticated;
