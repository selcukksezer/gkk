-- RPC: Unlock Facility (public.unlock_facility)
-- Exposes /rest/v1/rpc/unlock_facility expected by the client

CREATE OR REPLACE FUNCTION public.unlock_facility(p_type TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id UUID;
    v_gold INT := 0;
    v_cost INT := 0;
    v_facility RECORD;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    -- Determine unlock cost to match client config in FacilityManager
    v_cost := CASE p_type
        WHEN 'mining' THEN 500
        WHEN 'quarry' THEN 800
        WHEN 'lumber_mill' THEN 1000
        WHEN 'clay_pit' THEN 1200
        WHEN 'sand_quarry' THEN 1500
        WHEN 'farming' THEN 2000
        WHEN 'herb_garden' THEN 2500
        WHEN 'ranch' THEN 3000
        WHEN 'apiary' THEN 3500
        WHEN 'mushroom_farm' THEN 4000
        WHEN 'rune_mine' THEN 5000
        WHEN 'holy_spring' THEN 6000
        WHEN 'shadow_pit' THEN 7000
        WHEN 'elemental_forge' THEN 8000
        WHEN 'time_well' THEN 10000
        ELSE 1000
    END;

    -- Read player's gold using auth_id mapping (public.users stores auth_id)
    SELECT coalesce(gold, 0) INTO v_gold FROM public.users WHERE auth_id = v_user_id LIMIT 1;

    IF v_gold < v_cost THEN
        RETURN jsonb_build_object('success', false, 'error', format('Insufficient gold. Required: %s, Have: %s', v_cost, v_gold));
    END IF;

    -- Check existing facility for this user and type
    SELECT * INTO v_facility FROM public.facilities WHERE user_id = v_user_id AND type = p_type LIMIT 1;

    IF v_facility IS NOT NULL AND v_facility.is_active THEN
        RETURN jsonb_build_object('success', false, 'error', 'Facility already unlocked');
    END IF;

    -- Deduct gold
    UPDATE public.users SET gold = gold - v_cost, updated_at = NOW() WHERE auth_id = v_user_id;

    IF v_facility IS NOT NULL THEN
        -- Reactivate existing facility
        UPDATE public.facilities
        SET is_active = true,
            suspicion_level = 0,
            updated_at = NOW()
        WHERE id = v_facility.id;
    ELSE
        -- Create new facility record
        INSERT INTO public.facilities (user_id, type, level, suspicion_level, is_active, created_at, updated_at)
        VALUES (v_user_id, p_type, 1, 0, true, NOW(), NOW());
    END IF;

    RETURN jsonb_build_object('success', true, 'cost', v_cost);
END;
$$;

-- Tell PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
