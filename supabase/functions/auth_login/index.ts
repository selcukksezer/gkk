/// <reference lib="deno.window" />
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { email, username, password } = await req.json()

    // Validation
    if (!password) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: { message: 'Şifre gerekli' }
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400
        }
      )
    }

    if (!email && !username) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: { message: 'E-posta veya kullanıcı adı gerekli' }
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400
        }
      )
    }

    // Create Supabase client
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    // Determine login method
    let loginEmail = email

    // If username is provided instead of email, look up the email
    if (!loginEmail && username) {
      const { data: user } = await supabaseAdmin
        .from('users')
        .select('email')
        .eq('username', username)
        .single()

      if (!user) {
        return new Response(
          JSON.stringify({ 
            success: false, 
            error: { message: 'Kullanıcı bulunamadı' }
          }),
          { 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 401
          }
        )
      }
      loginEmail = user.email
    }

    // Validate password length
    if (password.length < 8) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: { message: 'Geçersiz şifre' }
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 401
        }
      )
    }

    // Sign in with email and password
    const { data: sessionData, error: sessionError } = await supabaseAdmin.auth.signInWithPassword({
      email: loginEmail,
      password
    })

    if (sessionError) {
      console.error('Login error:', sessionError)
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: { message: 'E-posta veya şifre hatalı' }
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 401
        }
      )
    }

    if (!sessionData || !sessionData.user) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: { message: 'Giriş başarısız oldu' }
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 401
        }
      )
    }

    // Get the full user profile
    const { data: userProfile, error: profileError } = await supabaseAdmin
      .from('users')
      .select('*')
      .eq('auth_id', sessionData.user.id)
      .single()

    if (profileError || !userProfile) {
      console.error('Profile fetch error:', profileError)
      // Return basic auth user data if profile doesn't exist
      return new Response(
        JSON.stringify({ 
          success: true,
          message: 'Giriş başarılı!',
          data: {
            session: sessionData.session,
            user: {
              id: sessionData.user.id,
              email: sessionData.user.email,
              username: sessionData.user.user_metadata?.username || email?.split('@')[0]
            }
          }
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200
        }
      )
    }

    // Update last login timestamp
    await supabaseAdmin
      .from('users')
      .update({
        last_login_at: new Date().toISOString(),
        is_online: true
      })
      .eq('auth_id', sessionData.user.id)

    return new Response(
      JSON.stringify({ 
        success: true,
        message: 'Giriş başarılı!',
        data: {
          session: sessionData.session,
          user: userProfile
        }
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200
      }
    )

  } catch (error) {
    console.error('Login error:', error)
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: { message: error.message || 'Bir hata oluştu' }
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500
      }
    )
  }
})
