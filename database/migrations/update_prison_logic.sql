-- Add immunity column to game.users if not exists
ALTER TABLE game.users 
ADD COLUMN IF NOT EXISTS suspicion_immunity_until TIMESTAMPTZ DEFAULT NOW();

-- Add prison_until column if not exists (should be there but just in case)
ALTER TABLE game.users
ADD COLUMN IF NOT EXISTS prison_until TIMESTAMPTZ DEFAULT NOW();

-- Function to Calculate Global Suspicion Risk
CREATE OR REPLACE FUNCTION calculate_global_suspicion(p_user_id UUID)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_active_count INT;
    v_level_sum INT;
    v_immunity TIMESTAMPTZ;
    v_risk FLOAT;
BEGIN
    -- Check Immunity
    SELECT suspicion_immunity_until INTO v_immunity FROM game.users WHERE id = p_user_id;
    
    IF v_immunity > NOW() THEN
        RETURN 0;
    END IF;

    -- Calculate Active Facilities (Production started less than 1 hour ago)
    SELECT 
        COUNT(*),
        COALESCE(SUM(level), 0)
    INTO 
        v_active_count,
        v_level_sum
    FROM public.facilities
    WHERE user_id = p_user_id
        AND production_started_at IS NOT NULL
        AND production_started_at > NOW() - INTERVAL '1 hour';
        
    -- Formula: (Active Count * 5) + (Level Sum * 0.5)
    -- Example: 4 Active (Lvl 1) -> 20 + 2 = 22%
    -- Example: 10 Active (Lvl 5) -> 50 + 25 = 75%
    
    v_risk := (v_active_count * 5.0) + (v_level_sum * 0.5);
    
    -- Clamp and Return
    IF v_risk > 100 THEN v_risk := 100; END IF;
    IF v_risk < 0 THEN v_risk := 0; END IF;
    
    RETURN CAST(v_risk AS INT);
END;
$$;

-- Update Bribe RPC to give Immunity
CREATE OR REPLACE FUNCTION bribe_officials(p_facility_id UUID, p_amount_gems INT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_current_gems INT;
BEGIN
    v_user_id := auth.uid();
    
    -- Check Gems
    SELECT gems INTO v_current_gems FROM game.users WHERE id = v_user_id;
    IF v_current_gems < p_amount_gems THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient gems');
    END IF;
    
    -- Deduct Gems & Grant Immunity (1 Hour)
    UPDATE game.users 
    SET gems = gems - p_amount_gems,
        suspicion_immunity_until = NOW() + INTERVAL '1 hour'
    WHERE id = v_user_id;
    
    -- Note: We don't change facility suspicion_level anymore as it's global now
    
    RETURN jsonb_build_object(
        'success', true, 
        'data', jsonb_build_object(
            'success', true, 
            'new_suspicion', 0,
            'message', 'You have immunity for 1 hour.'
        )
    );
END;
$$;

-- Update Collect Logic to Enforce Prison
CREATE OR REPLACE FUNCTION collect_facility_resources(
    p_facility_id UUID,
    p_resources JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_risk INT;
    v_roll INT;
    v_item JSONB;
    v_item_id TEXT;
    v_quantity INT;
    v_rarity TEXT;
    v_total_collected INT := 0;
    v_max_stack INT := 500;
BEGIN
    v_user_id := auth.uid();
    
    -- 1. Verify Ownership & Reset Timer Logic (Standard)
    IF NOT EXISTS (SELECT 1 FROM public.facilities WHERE id = p_facility_id AND user_id = v_user_id) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Facility not found');
    END IF;

    -- 2. CALCULATE RISK & CHECK PRISON
    v_risk := calculate_global_suspicion(v_user_id);
    v_roll := floor(random() * 100) + 1; -- 1 to 100
    
    -- If roll <= risk, YOU ARE CAUGHT!
    IF v_roll <= v_risk THEN
        -- PENALTY:
        -- 1. Go to Jail (1 Hour)
        UPDATE game.users 
        SET prison_until = NOW() + INTERVAL '1 hour'
        WHERE id = v_user_id;
        
        -- 2. Stop ALL Productions (Resets Risk to 0 for next time)
        UPDATE public.facilities
        SET production_started_at = NULL
        WHERE user_id = v_user_id;
        
        -- 3. Return Error
        RETURN jsonb_build_object(
            'success', false, 
            'error', 'CAUGHT_BY_POLICE',
            'data', jsonb_build_object(
                'prison_hours', 1,
                'message', 'Polis baskını! Tutuklandınız ve tüm üretim durduruldu.'
            )
        );
    END IF;
    
    -- 3. If Safe, Change Production Timestamp to NULL (Production Finished)
    -- Use specific facility update
    UPDATE public.facilities 
    SET last_production_collected_at = NOW(),
        production_started_at = NULL -- Reset production state
    WHERE id = p_facility_id AND user_id = v_user_id;

    -- 4. Add Items to Inventory (Existing Logic)
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_resources)
    LOOP
        v_item_id := v_item->>'item_id';
        v_quantity := (v_item->>'quantity')::INT;
        v_rarity := v_item->>'rarity';
        
        IF v_quantity > 0 THEN
            INSERT INTO public.inventory (user_id, item_id, quantity, max_stack, rarity)
            VALUES (v_user_id, v_item_id, v_quantity, v_max_stack, v_rarity)
            ON CONFLICT (user_id, item_id, rarity)
            DO UPDATE SET 
                quantity = LEAST(inventory.quantity + EXCLUDED.quantity, inventory.max_stack);
                
            v_total_collected := v_total_collected + v_quantity;
        END IF;
    END LOOP;

    RETURN jsonb_build_object(
        'success', true, 
        'total_count', v_total_collected
    );
END;
$$;
