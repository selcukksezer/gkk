import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

interface FacilityData {
  id: number
  player_id: string
  facility_type: string
  level: number
  suspicion_level: number
  experience: number
  offline_production_cap: number
  workers: number
  is_unlocked: boolean
  unlock_cost: number
  upgrade_cost: number
  last_production_collected_at: string | null
  created_at: string
  updated_at: string
  facility_production_queue?: any[]
}

Deno.serve(async (req) => {
  try {
    // CORS headers
    if (req.method === 'OPTIONS') {
      return new Response('ok', {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST, OPTIONS',
          'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
        },
      })
    }

    // Parse request
    const { p_player_id } = await req.json()
    
    if (!p_player_id) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing p_player_id' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    console.log(`[get_player_facilities] Fetching facilities for player: ${p_player_id}`)

    const supabase = createClient(supabaseUrl, supabaseKey)

    // Get player's facilities with their production queues
    const { data: facilities, error } = await supabase
      .from('facilities')
      .select(`
        id,
        player_id,
        facility_type,
        level,
        suspicion_level,
        experience,
        offline_production_cap,
        workers,
        is_unlocked,
        unlock_cost,
        upgrade_cost,
        last_production_collected_at,
        created_at,
        updated_at,
        facility_production_queue(
          id,
          recipe_id,
          quantity,
          started_at,
          duration_seconds,
          estimated_completion_at,
          rarity_outcome,
          completed_at,
          collected,
          collected_at,
          failed,
          failure_reason
        )
      `)
      .eq('player_id', p_player_id)
      .order('facility_type', { ascending: true })

    if (error) {
      console.error('[get_player_facilities] Database error:', error)
      return new Response(
        JSON.stringify({ success: false, error: error.message }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    console.log(`[get_player_facilities] Found ${facilities?.length || 0} facilities`)

    return new Response(
      JSON.stringify({
        success: true,
        data: facilities || [],
        count: facilities?.length || 0
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
    console.error('[get_player_facilities] Error:', err)
    return new Response(
      JSON.stringify({ success: false, error: err.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
