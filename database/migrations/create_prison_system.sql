-- Prison System Migration (Mirroring Hospital Logic)
-- v5: FIX - Drop function release_from_prison before recreate

-- 1. Add Prison Columns to game.users
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'game' AND table_name = 'users') THEN
        ALTER TABLE game.users ADD COLUMN IF NOT EXISTS prison_until TIMESTAMPTZ DEFAULT NULL;
        ALTER TABLE game.users ADD COLUMN IF NOT EXISTS prison_reason TEXT DEFAULT NULL;
    ELSE
        RAISE EXCEPTION 'Table game.users not found. Please verify the table holding player profiles.';
    END IF;
END $$;


-- 2. RPC: Release from Prison (Bail via GEMS)
DROP FUNCTION IF EXISTS release_from_prison(boolean);

CREATE OR REPLACE FUNCTION release_from_prison(
    p_use_bail BOOLEAN DEFAULT FALSE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_user RECORD;
    v_now TIMESTAMPTZ;
    v_bail_gems INT; 
    v_remaining_mins INT;
BEGIN
    v_user_id := auth.uid();
    v_now := NOW();
    
    -- Use game.users
    SELECT * INTO v_user FROM game.users WHERE id = v_user_id;
    
    IF v_user IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'User not found in game.users'); END IF;

    IF v_user.prison_until IS NULL OR v_user.prison_until <= v_now THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not in prison');
    END IF;
    
    IF p_use_bail THEN
        v_remaining_mins := CEIL(EXTRACT(EPOCH FROM (v_user.prison_until - v_now)) / 60);
        v_bail_gems := GREATEST(1, v_remaining_mins);
        
        IF v_user.gems < v_bail_gems THEN
            RETURN jsonb_build_object('success', false, 'error', 'Insufficient gems', 'cost', v_bail_gems);
        END IF;
        
        UPDATE game.users SET gems = gems - v_bail_gems WHERE id = v_user_id;
    END IF;
    
    -- Release
    UPDATE game.users 
    SET prison_until = NULL, prison_reason = NULL 
    WHERE id = v_user_id;
    
    RETURN jsonb_build_object('success', true, 'message', 'Released from prison');
END;
$$;

-- 3. Update collect_facility_production
DROP FUNCTION IF EXISTS collect_facility_production(uuid);

CREATE OR REPLACE FUNCTION collect_facility_production(p_facility_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_facility RECORD;
    v_now BIGINT;
    v_queue_item RECORD;
    v_recipe RECORD;
    v_raid_roll INT;
    v_burn_roll INT;
    v_success_count INT := 0;
    v_raid_occurred BOOLEAN := FALSE;
    v_burn_occurred BOOLEAN := FALSE;
    v_final_qty INT;
    v_prison_duration INT;
BEGIN
    v_user_id := auth.uid();
    v_now := EXTRACT(EPOCH FROM NOW())::BIGINT;
    
    -- Check Prison Status on game.users
    IF EXISTS (SELECT 1 FROM game.users WHERE id = v_user_id AND prison_until > NOW()) THEN
        RETURN jsonb_build_object('success', false, 'error', 'You are in prison!');
    END IF;
    
    SELECT * INTO v_facility FROM public.facilities WHERE id = p_facility_id AND user_id = v_user_id;
    
    FOR v_queue_item IN 
        SELECT * FROM public.facility_queue 
        WHERE facility_id = p_facility_id AND completed_at <= v_now AND status = 'in_progress'
    LOOP
        SELECT * INTO v_recipe FROM public.facility_recipes WHERE id = v_queue_item.recipe_id;
        
        -- Raid Check
        v_raid_roll := floor(random() * 100);
        IF v_raid_roll < v_facility.suspicion THEN
            UPDATE public.facility_queue SET status = 'raided', is_raided = TRUE WHERE id = v_queue_item.id;
            v_raid_occurred := TRUE;
            
            -- PRISON LOGIC (50% Chance)
            IF floor(random() * 100) < 50 THEN
                v_prison_duration := GREATEST(10, v_facility.suspicion * 2); 
                
                -- Update game.users
                UPDATE game.users 
                SET prison_until = NOW() + (v_prison_duration || ' minutes')::INTERVAL,
                    prison_reason = 'Facility Raid: ' || v_facility.type
                WHERE id = v_user_id;
                
                UPDATE public.facilities SET suspicion = 0 WHERE id = p_facility_id;
                
                RETURN jsonb_build_object(
                    'success', true, 'raid', true, 'prison', true, 
                    'prison_time', v_prison_duration,
                    'collected_count', v_success_count
                );
            ELSE
                 UPDATE public.facilities SET suspicion = GREATEST(0, suspicion - 30) WHERE id = p_facility_id;
            END IF;
            
            CONTINUE; 
        END IF;
        
        -- Burn Check
        v_burn_roll := floor(random() * 100);
        IF v_burn_roll > v_recipe.success_rate THEN
            UPDATE public.facility_queue SET status = 'burned', is_burned = TRUE WHERE id = v_queue_item.id;
            v_burn_occurred := TRUE;
            CONTINUE;
        END IF;
        
        v_final_qty := v_recipe.output_quantity * v_queue_item.quantity;
        
        INSERT INTO public.inventory (user_id, item_id, quantity, obtained_at)
        VALUES (v_user_id, v_recipe.output_item_id, v_final_qty, v_now);
        
        UPDATE public.facility_queue SET status = 'completed' WHERE id = v_queue_item.id;
        v_success_count := v_success_count + 1;
        
    END LOOP;
    
    RETURN jsonb_build_object(
        'success', true, 
        'raid', v_raid_occurred, 
        'burn', v_burn_occurred, 
        'collected_count', v_success_count
    );
END;
$$;
