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
    const { email, username, password, referral_code } = await req.json()

    // Validation
    if (!email || !username || !password) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: { message: 'Email, kullanıcı adı ve şifre gerekli' }
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400
        }
      )
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    if (!emailRegex.test(email)) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: { message: 'Geçersiz e-posta formatı' }
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400
        }
      )
    }

    // Validate username
    if (username.length < 3 || username.length > 20) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: { message: 'Kullanıcı adı 3-20 karakter olmalı' }
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400
        }
      )
    }

    // Validate password
    if (password.length < 8) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: { message: 'Şifre en az 8 karakter olmalı' }
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

    // Check if username already exists
    const { data: existingUsername } = await supabaseAdmin
      .from('users')
      .select('id')
      .eq('username', username)
      .single()

    if (existingUsername) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: { message: 'Bu kullanıcı adı zaten kullanılıyor' }
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400
        }
      )
    }

    // Check if email already exists
    const { data: existingEmail } = await supabaseAdmin
      .from('users')
      .select('id')
      .eq('email', email)
      .single()

    if (existingEmail) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: { message: 'Bu e-posta zaten kayıtlı' }
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400
        }
      )
    }

    // Validate referral code if provided
    let referrer_id = null
    if (referral_code && referral_code.trim() !== '') {
      const { data: referrer } = await supabaseAdmin
        .from('users')
        .select('id')
        .eq('referral_code', referral_code.toUpperCase())
        .single()

      if (!referrer) {
        return new Response(
          JSON.stringify({ 
            success: false, 
            error: { message: 'Geçersiz referans kodu' }
          }),
          { 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400
          }
        )
      }
      referrer_id = referrer.id
    }

    // Create auth user with metadata
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true, // Auto-confirm email for simplicity
      user_metadata: {
        username,
        display_name: username
      }
    })

    if (authError) {
      console.error('Auth creation error:', authError)
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: { message: authError.message || 'Kayıt başarısız oldu' }
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400
        }
      )
    }

    // The trigger will auto-create the user profile, but we can also update it with referral
    if (referrer_id) {
      await supabaseAdmin
        .from('users')
        .update({ referred_by: referrer_id })
        .eq('auth_id', authData.user.id)
    }

    // Sign in the user to get session tokens
    const { data: sessionData, error: sessionError } = await supabaseAdmin.auth.signInWithPassword({
      email,
      password
    })

    if (sessionError) {
      console.error('Session creation error:', sessionError)
      // User is created but couldn't auto-login
      return new Response(
        JSON.stringify({ 
          success: true, 
          message: 'Kayıt başarılı! Lütfen giriş yapın.',
          data: {
            user: authData.user
          }
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200
        }
      )
    }

    // Get the full user profile
    const { data: userProfile } = await supabaseAdmin
      .from('users')
      .select('*')
      .eq('auth_id', authData.user.id)
      .single()

    return new Response(
      JSON.stringify({ 
        success: true,
        message: 'Kayıt başarılı!',
        data: {
          session: sessionData.session,
          user: userProfile || authData.user
        }
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200
      }
    )

  } catch (error) {
    console.error('Registration error:', error)
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
