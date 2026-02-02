import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

Deno.serve(async (req) => {
  try {
    if (req.method === 'OPTIONS') {
      return new Response('ok', {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST, OPTIONS',
          'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
        },
      })
    }

    const { p_facility_id, p_building_type } = await req.json()
    const authHeader = req.headers.get('authorization')

    if (!p_facility_id && !p_building_type) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing p_facility_id or p_building_type' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const supabase = createClient(supabaseUrl, supabaseKey)

    // Get user from auth
    const { data: { user }, error: authError } = await supabase.auth.getUser(authHeader?.replace('Bearer ', ''))
    
    if (authError || !user) {
      return new Response(
        JSON.stringify({ success: false, error: 'Unauthorized' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const playerId = user.id

    // If facility_id provided, verify ownership and get building_type
    let buildingType = p_building_type
    if (p_facility_id) {
      const { data: facility, error: facilityError } = await supabase
        .from('facilities')
        .select('facility_type')
        .eq('id', p_facility_id)
        .eq('player_id', playerId)
        .single()

      if (facilityError || !facility) {
        return new Response(
          JSON.stringify({ success: false, error: 'Facility not found or not owned' }),
          { status: 404, headers: { 'Content-Type': 'application/json' } }
        )
      }

      buildingType = facility.facility_type
    }

    console.log(`[get_facility_recipes] Building type: ${buildingType}`)

    // Get recipes for this facility type
    const { data: recipes, error: recipesError } = await supabase
      .from('facility_recipes')
      .select('*')
      .eq('recipe_building_type', buildingType)
      .order('recipe_level', { ascending: true })

    if (recipesError) {
      console.error('[get_facility_recipes] Query error:', recipesError)
      return new Response(
        JSON.stringify({ success: false, error: recipesError.message }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    if (!recipes || recipes.length === 0) {
      return new Response(
        JSON.stringify({
          success: true,
          recipes: [],
          count: 0,
          building_type: buildingType,
          message: 'No recipes found for this facility'
        }),
        {
          status: 200,
          headers: { 
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          }
        }
      )
    }

    // Parse ingredients from JSON string
    const processedRecipes = recipes.map(recipe => ({
      ...recipe,
      ingredients: recipe.ingredients ? JSON.parse(recipe.ingredients) : {},
      outputs: recipe.outputs ? JSON.parse(recipe.outputs) : {}
    }))

    console.log(`[get_facility_recipes] Found ${processedRecipes.length} recipes for ${buildingType}`)

    return new Response(
      JSON.stringify({
        success: true,
        recipes: processedRecipes,
        count: processedRecipes.length,
        building_type: buildingType
      }),
      {
        status: 200,
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      }
    )
  } catch (err) {
    console.error('[get_facility_recipes] Error:', err)
    return new Response(
      JSON.stringify({ success: false, error: err.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
