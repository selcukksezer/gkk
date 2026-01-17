-- Create Collect RPC and Implement Prison Logic

CREATE OR REPLACE FUNCTION collect_facility_production(p_facility_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_now BIGINT;
    v_job RECORD;
    v_recipe RECORD;
    v_facility RECORD;
    v_existing_inv RECORD;
    v_collected_items JSONB := '[]'::jsonb;
    v_count INT := 0;
    v_prison_time TIMESTAMPTZ;
BEGIN
    v_user_id := auth.uid();
    v_now := EXTRACT(EPOCH FROM NOW())::BIGINT;
    
    -- 1. Check Facility and Suspicion (Prison Check)
    SELECT * INTO v_facility FROM public.facilities WHERE id = p_facility_id AND user_id = v_user_id;
    IF v_facility IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Facility not found'); END IF;

    -- PRISON CHECK: If suspicion is 100 (or more), send to jail!
    IF v_facility.suspicion >= 100 THEN
        -- Jail for 15 minutes
        v_prison_time := NOW() + INTERVAL '15 minutes';
        UPDATE game.users 
        SET prison_until = v_prison_time, 
            prison_reason = 'Illegal Production (Suspicion 100%)' 
        WHERE id = v_user_id;
        
        -- Reset Suspicion
        UPDATE public.facilities SET suspicion = 0 WHERE id = p_facility_id;
        
        -- Return specific error or status so Client can redirect
        RETURN jsonb_build_object(
            'success', false, 
            'error', 'POLICE RAID! You are in prison.', 
            'in_prison', true
        );
    END IF;

    -- 2. Loop through completed jobs
    FOR v_job IN 
        SELECT * FROM public.facility_queue 
        WHERE facility_id = p_facility_id 
        AND completed_at <= v_now
    LOOP
        -- Get output details
        SELECT * INTO v_recipe FROM public.facility_recipes WHERE id = v_job.recipe_id;
        
        IF v_recipe IS NOT NULL THEN
            -- Add to Inventory
            -- Try to find existing stack (simple approach: find any row with same item_id)
            SELECT * INTO v_existing_inv FROM public.inventory 
            WHERE user_id = v_user_id AND item_id = v_recipe.output_item_id LIMIT 1;
            
            IF v_existing_inv IS NOT NULL THEN
                UPDATE public.inventory 
                SET quantity = quantity + (v_recipe.output_quantity * v_job.quantity)
                WHERE row_id = v_existing_inv.row_id;
            ELSE
                INSERT INTO public.inventory (user_id, item_id, quantity)
                VALUES (v_user_id, v_recipe.output_item_id, (v_recipe.output_quantity * v_job.quantity));
            END IF;
            
            -- Add to result log
            v_collected_items := v_collected_items || jsonb_build_object('item', v_recipe.output_item_id, 'qty', v_recipe.output_quantity * v_job.quantity);
            v_count := v_count + 1;
        END IF;

        -- Remove job
        DELETE FROM public.facility_queue WHERE id = v_job.id;
    END LOOP;

    IF v_count = 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'No completed production found');
    END IF;

    RETURN jsonb_build_object('success', true, 'collected', v_collected_items);
END;
$$;
