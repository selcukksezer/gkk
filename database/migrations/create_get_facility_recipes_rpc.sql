-- RPC: Get Facility Recipes (fixes facility_level_required column name error)
-- Returns recipes for a facility type with proper column names

CREATE OR REPLACE FUNCTION get_facility_recipes_rpc(p_facility_type TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_recipes JSONB := '[]'::jsonb;
    v_recipe RECORD;
    v_recipe_count INT := 0;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;
    
    IF p_facility_type IS NULL OR p_facility_type = '' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Facility type required');
    END IF;
    
    -- Get recipes for this facility type - uses required_level (correct column name)
    FOR v_recipe IN 
        SELECT 
            id, 
            facility_type, 
            output_item_id, 
            output_quantity, 
            input_materials, 
            gold_cost, 
            duration_seconds, 
            required_level,
            success_rate, 
            base_suspicion_increase,
            production_speed_bonus,
            rarity_distribution,
            created_at
        FROM public.facility_recipes 
        WHERE facility_type = p_facility_type
        ORDER BY required_level ASC
    LOOP
        v_recipe_count := v_recipe_count + 1;
        
        v_recipes := v_recipes || jsonb_build_object(
            'id', v_recipe.id,
            'facility_type', v_recipe.facility_type,
            'output_item_id', v_recipe.output_item_id,
            'output_quantity', v_recipe.output_quantity,
            'input_materials', v_recipe.input_materials,
            'gold_cost', v_recipe.gold_cost,
            'duration_seconds', v_recipe.duration_seconds,
            'required_level', v_recipe.required_level,
            'success_rate', v_recipe.success_rate,
            'base_suspicion_increase', v_recipe.base_suspicion_increase,
            'production_speed_bonus', v_recipe.production_speed_bonus,
            'rarity_distribution', v_recipe.rarity_distribution,
            'created_at', v_recipe.created_at
        );
    END LOOP;
    
    RETURN jsonb_build_object(
        'success', true,
        'recipes', v_recipes,
        'count', v_recipe_count,
        'facility_type', p_facility_type
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_facility_recipes_rpc(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_facility_recipes_rpc(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION get_facility_recipes_rpc(TEXT) TO service_role;
