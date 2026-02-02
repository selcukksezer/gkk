-- RPC: Upgrade Facility
-- Handles cost calculation and level increment server-side

CREATE OR REPLACE FUNCTION upgrade_facility(
    p_facility_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_facility RECORD;
    v_current_level INT;
    v_cost INT;
    v_user_gold INT;
    v_base_cost INT := 2000;
    v_multiplier FLOAT := 1.6;
BEGIN
    v_user_id := auth.uid();
    
    -- Get facility
    SELECT * INTO v_facility FROM public.facilities WHERE id = p_facility_id AND user_id = v_user_id;
    IF v_facility IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Facility not found');
    END IF;
    
    v_current_level := v_facility.level;
    
    -- Calculate cost: 2000 * (1.6 ^ level)
    -- Note: Power returns float, cast to int
    v_cost := (v_base_cost * power(v_multiplier, v_current_level))::INT;
    
    -- Check user gold
    SELECT gold INTO v_user_gold FROM game.users WHERE id = v_user_id;
    
    IF v_user_gold < v_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient gold', 'cost', v_cost, 'current_gold', v_user_gold);
    END IF;
    
    -- Deduct gold
    UPDATE game.users SET gold = gold - v_cost WHERE id = v_user_id;
    
    -- Increment level
    UPDATE public.facilities 
    SET level = level + 1, updated_at = NOW() 
    WHERE id = p_facility_id;
    
    -- Calculate next cost for UI convenience
    -- next_cost = 2000 * (1.6 ^ (level + 1))
    
    RETURN jsonb_build_object(
        'success', true, 
        'new_level', v_current_level + 1,
        'gold_deducted', v_cost,
        'remaining_gold', v_user_gold - v_cost,
        'next_upgrade_cost', (v_base_cost * power(v_multiplier, v_current_level + 1))::INT
    );
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;
