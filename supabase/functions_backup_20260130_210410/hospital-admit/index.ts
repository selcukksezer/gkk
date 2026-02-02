import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req: Request) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    const { data: { user } } = await supabaseClient.auth.getUser()

    if (!user) {
      return new Response(
        JSON.stringify({ success: false, error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Parse request body
    let body: any = {}
    try {
      const text = await req.text()
      if (text) {
        body = JSON.parse(text)
      }
    } catch (e) {
      console.log("Could not parse body:", e)
    }

    const { duration_minutes = 120, reason = 'Zindan başarısızlığı' } = body

    if (!duration_minutes || duration_minutes < 1) {
      return new Response(
        JSON.stringify({ success: false, error: 'Invalid duration_minutes' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Calculate release time
    const now = new Date()
    const releaseDate = new Date(now.getTime() + duration_minutes * 60 * 1000)

    // Update user in database
    const { error: updateError } = await supabaseClient
      .from('game.users')
      .update({
        hospital_until: releaseDate.toISOString(),
        hospital_reason: reason,
        updated_at: new Date().toISOString()
      })
      .eq('auth_id', user.id)

    if (updateError) {
      return new Response(
        JSON.stringify({ success: false, error: updateError.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({
        success: true,
        hospital_until: releaseDate.toISOString(),
        release_time: Math.floor(releaseDate.getTime() / 1000),
        duration_minutes: duration_minutes,
        reason: reason
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error:', error)
    const errorMessage = error instanceof Error ? error.message : 'Unknown error'
    return new Response(
      JSON.stringify({ success: false, error: errorMessage }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
