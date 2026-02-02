import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

// Facility configuration (must match FacilityManager.gd)
const FACILITIES_CONFIG: Record<string, any> = {
  mine: {
    base_unlock_cost: 5000,
    base_upgrade_cost: 2000,
    upgrade_multiplier: 1.6,
    workers_per_level: 2,
    offline_cap_per_level: 50
  },
  sawmill: {
    base_unlock_cost: 4000,
    base_upgrade_cost: 1500,
    upgrade_multiplier: 1.5,
    workers_per_level: 2,
    offline_cap_per_level: 50
  },
  farm: {
    base_unlock_cost: 3000,
    base_upgrade_cost: 1200,
    upgrade_multiplier: 1.5,
    workers_per_level: 2,
    offline_cap_per_level: 50
  },
  herb_garden: {
    base_unlock_cost: 4500,
    base_upgrade_cost: 1800,
    upgrade_multiplier: 1.6,
    workers_per_level: 2,
    offline_cap_per_level: 50
  },
  blacksmith: {
    base_unlock_cost: 8000,
    base_upgrade_cost: 3000,
    upgrade_multiplier: 1.7,
    workers_per_level: 3,
    offline_cap_per_level: 100
  },
  armorer: {
    base_unlock_cost: 8000,
    base_upgrade_cost: 3000,
    upgrade_multiplier: 1.7,
    workers_per_level: 3,
    offline_cap_per_level: 100
  },
  alchemy_lab: {
    base_unlock_cost: 7000,
    base_upgrade_cost: 2500,
    upgrade_multiplier: 1.6,
    workers_per_level: 2,
    offline_cap_per_level: 100
  },
  runesmith: {
    base_unlock_cost: 10000,
    base_upgrade_cost: 4000,
    upgrade_multiplier: 1.8,
    workers_per_level: 3,
    offline_cap_per_level: 120
  },
  scroll_library: {
    base_unlock_cost: 9000,
    base_upgrade_cost: 3500,
    upgrade_multiplier: 1.7,
    workers_per_level: 2,
    offline_cap_per_level: 120
  },
  gem_cutter: {
    base_unlock_cost: 8500,
    base_upgrade_cost: 3200,
    upgrade_multiplier: 1.7,
    workers_per_level: 2,
    offline_cap_per_level: 100
  },
  enhancement_master: {
    base_unlock_cost: 15000,
    base_upgrade_cost: 5000,
    upgrade_multiplier: 1.8,
    workers_per_level: 3,
    offline_cap_per_level: 150
  },
  master_alchemist: {
    base_unlock_cost: 16000,
    base_upgrade_cost: 5500,
    upgrade_multiplier: 1.8,
    workers_per_level: 3,
    offline_cap_per_level: 150
  },
  master_armorer: {
    base_unlock_cost: 17000,
    base_upgrade_cost: 6000,
    upgrade_multiplier: 1.8,
    workers_per_level: 3,
    offline_cap_per_level: 160
  },
  warehouse: {
    base_unlock_cost: 6000,
    base_upgrade_cost: 2000,
    upgrade_multiplier: 1.5,
    workers_per_level: 1,
    offline_cap_per_level: 0
  },
  market_hub: {
    base_unlock_cost: 7000,
    base_upgrade_cost: 2500,
    upgrade_multiplier: 1.5,
    workers_per_level: 1,
    offline_cap_per_level: 0
  }
}

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

    const { p_facility_type } = await req.json()
    const authHeader = req.headers.get('authorization')
    
    if (!p_facility_type) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing p_facility_type' }),
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
    console.log(`[unlock_facility] Unlocking ${p_facility_type} for player ${playerId}`)

    // Validate facility type
    if (!FACILITIES_CONFIG[p_facility_type]) {
      return new Response(
        JSON.stringify({ success: false, error: 'Invalid facility type' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const config = FACILITIES_CONFIG[p_facility_type]
    const unlockCost = config.base_unlock_cost

    // Check if facility already exists
    const { data: existingFacility } = await supabase
      .from('facilities')
      .select('id')
      .eq('player_id', playerId)
      .eq('facility_type', p_facility_type)
      .single()

    if (existingFacility) {
      return new Response(
        JSON.stringify({ success: false, error: 'Facility already unlocked' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Get player's gold
    const { data: playerData, error: playerError } = await supabase
      .from('users')
      .select('gold')
      .eq('id', playerId)
      .single()

    if (playerError || !playerData) {
      return new Response(
        JSON.stringify({ success: false, error: 'Player not found' }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      )
    }

    if (playerData.gold < unlockCost) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: `Insufficient gold. Required: ${unlockCost}, Have: ${playerData.gold}` 
        }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Calculate upgrade cost for level 2
    const upgradeCost = Math.floor(config.base_upgrade_cost * Math.pow(config.upgrade_multiplier, 1))

    // Insert new facility
    const { data: newFacility, error: insertError } = await supabase
      .from('facilities')
      .insert({
        player_id: playerId,
        facility_type: p_facility_type,
        level: 1,
        suspicion_level: 0,
        experience: 0,
        offline_production_cap: config.offline_cap_per_level,
        workers: config.workers_per_level,
        is_unlocked: true,
        unlock_cost: unlockCost,
        upgrade_cost: upgradeCost
      })
      .select()
      .single()

    if (insertError) {
      console.error('[unlock_facility] Insert error:', insertError)
      return new Response(
        JSON.stringify({ success: false, error: insertError.message }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Deduct gold from player
    const { error: updateError } = await supabase
      .from('users')
      .update({ gold: playerData.gold - unlockCost })
      .eq('id', playerId)

    if (updateError) {
      console.error('[unlock_facility] Update error:', updateError)
      return new Response(
        JSON.stringify({ success: false, error: updateError.message }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    console.log(`[unlock_facility] Successfully unlocked ${p_facility_type}, cost: ${unlockCost}`)

    return new Response(
      JSON.stringify({
        success: true,
        facility: newFacility,
        gold_deducted: unlockCost,
        remaining_gold: playerData.gold - unlockCost
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
    console.error('[unlock_facility] Error:', err)
    return new Response(
      JSON.stringify({ success: false, error: err.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
