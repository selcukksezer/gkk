-- RPC: Get Player Facilities WITH Production Queue
-- Joins facilities with facility_queue to include active production jobs

CREATE OR REPLACE FUNCTION get_player_facilities_with_queue()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_facilities JSONB;
    v_facility RECORD;
    v_queue_item RECORD;
    v_facility_obj JSONB;
    v_queue_array JSONB;
    v_facility_count INT := 0;
    v_queue_count INT := 0;
BEGIN
    v_user_id := auth.uid();
    RAISE NOTICE '[RPC] get_player_facilities_with_queue started. User: %', v_user_id;
    
    IF v_user_id IS NULL THEN
        RAISE NOTICE '[RPC] ERROR: User not authenticated';
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;
    
    v_facilities := '[]'::jsonb;
    
    -- Get all facilities for this user
    RAISE NOTICE '[RPC] Fetching facilities for user: %', v_user_id;
    FOR v_facility IN 
        SELECT * FROM public.facilities 
        WHERE user_id = v_user_id 
        ORDER BY type ASC
    LOOP
        v_facility_count := v_facility_count + 1;
        RAISE NOTICE '[RPC] Processing facility #%: id=%, type=%', v_facility_count, v_facility.id, v_facility.type;
        
        -- Build queue array for this facility
        v_queue_array := '[]'::jsonb;
        v_queue_count := 0;
        
        RAISE NOTICE '[RPC] Fetching queue items for facility %', v_facility.id;
        FOR v_queue_item IN 
            SELECT * FROM public.facility_queue 
            WHERE facility_id = v_facility.id 
            ORDER BY started_at ASC
        LOOP
            v_queue_count := v_queue_count + 1;
            RAISE NOTICE '[RPC] Queue item #%: id=%, recipe=%, completed_at=%', 
                v_queue_count, v_queue_item.id, v_queue_item.recipe_id, v_queue_item.completed_at;
            
            v_queue_array := v_queue_array || jsonb_build_object(
                'id', v_queue_item.id,
                'facility_id', v_queue_item.facility_id,
                'recipe_id', v_queue_item.recipe_id,
                'quantity', v_queue_item.quantity,
                'started_at', v_queue_item.started_at,
                'completed_at', v_queue_item.completed_at,
                'status', v_queue_item.status,
                'is_raided', v_queue_item.is_raided,
                'is_burned', v_queue_item.is_burned
            );
        END LOOP;
        
        RAISE NOTICE '[RPC] Facility % has % queue items', v_facility.id, v_queue_count;
        
        -- Build facility object with queue
        RAISE NOTICE '[RPC] Building facility object for: %', v_facility.type;
        v_facility_obj := jsonb_build_object(
            'id', v_facility.id,
            'user_id', v_facility.user_id,
            'type', v_facility.type,
            'level', v_facility.level,
            'suspicion', v_facility.suspicion_level,
            'is_active', v_facility.is_active,
            'production_started_at', v_facility.production_started_at,
            'created_at', v_facility.created_at,
            'updated_at', v_facility.updated_at,
            'facility_queue', v_queue_array
        );
        
        v_facilities := v_facilities || jsonb_build_array(v_facility_obj);
    END LOOP;
    
    RAISE NOTICE '[RPC] Completed. Total facilities: %, facilities_json_keys: %', 
        v_facility_count, jsonb_array_length(v_facilities);
    RAISE NOTICE '[RPC] Final response data: %', v_facilities;
    
    RETURN jsonb_build_object('success', true, 'data', v_facilities);
END;
$$;
