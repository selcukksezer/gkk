import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

const BRIBE_COST_GEMS = 5
const BRIBE_SUSPICION_REDUCTION = 10

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

    const { p_facility_id, p_gems } = await req.json()
    const authHeader = req.headers.get('authorization')

    if (!p_facility_id) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing p_facility_id' }),
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
    const gemsAmount = p_gems || BRIBE_COST_GEMS

    console.log(`[bribe_officials] Player ${playerId}, Facility ${p_facility_id}, Cost: ${gemsAmount} gems`)

    // Get facility
    const { data: facility, error: facilityError } = await supabase
      .from('facilities')
      .select('*')
      .eq('id', p_facility_id)
      .eq('player_id', playerId)
      .single()

    if (facilityError || !facility) {
      return new Response(
        JSON.stringify({ success: false, error: 'Facility not found or not owned' }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Get player gems
    const { data: playerData } = await supabase
      .from('users')
      .select('gems')
      .eq('id', playerId)
      .single()

    if (!playerData || playerData.gems < gemsAmount) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: `Insufficient gems. Required: ${gemsAmount}, Have: ${playerData?.gems || 0}` 
        }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Calculate new suspicion (reduce by amount, minimum 0)
    const suspicionReduction = BRIBE_SUSPICION_REDUCTION
    const newSuspicion = Math.max(facility.suspicion_level - suspicionReduction, 0)

    // Update facility
    const { data: updatedFacility, error: updateError } = await supabase
      .from('facilities')
      .update({
        suspicion_level: newSuspicion,
        updated_at: new Date().toISOString()
      })
      .eq('id', p_facility_id)
      .select()
      .single()

    if (updateError) {
      console.error('[bribe_officials] Update error:', updateError)
      return new Response(
        JSON.stringify({ success: false, error: updateError.message }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Deduct gems
    const { error: gemError } = await supabase
      .from('users')
      .update({ gems: playerData.gems - gemsAmount })
      .eq('id', playerId)

    if (gemError) {
      console.error('[bribe_officials] Gem deduction error:', gemError)
    }

    console.log(`[bribe_officials] Suspicion reduced from ${facility.suspicion_level} to ${newSuspicion}, cost: ${gemsAmount} gems`)

    return new Response(
      JSON.stringify({
        success: true,
        facility: updatedFacility,
        old_suspicion: facility.suspicion_level,
        new_suspicion: newSuspicion,
        gems_deducted: gemsAmount,
        remaining_gems: playerData.gems - gemsAmount,
        suspicion_reduced: suspicionReduction
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
    console.error('[bribe_officials] Error:', err)
    return new Response(
      JSON.stringify({ success: false, error: err.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
