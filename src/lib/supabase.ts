// =====================================================
// lib/supabase.ts - Supabase istemcisi
// Godot'tan dönüştürüldü: NetworkManager.gd + SessionManager.gd
// =====================================================

import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL ?? 'https://znvsyzstmxhqvdkkmgdt.supabase.co'
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? 'placeholder-key-set-env-var'

if (supabaseAnonKey === 'placeholder-key-set-env-var') {
  console.warn('[Supabase] NEXT_PUBLIC_SUPABASE_ANON_KEY ortam değişkeni ayarlanmamış! .env.local dosyasına ekleyin.')
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
    storage: typeof window !== 'undefined' ? window.localStorage : undefined,
  },
  realtime: {
    params: {
      eventsPerSecond: 10,
    },
  },
})

// =====================================================
// Supabase Edge Function çağırıcısı (Network.http_post benzeri)
// =====================================================
export async function callEdgeFunction<T = unknown>(
  functionName: string,
  body?: Record<string, unknown>,
  options?: { method?: 'GET' | 'POST' | 'PUT' | 'DELETE' }
): Promise<{ success: boolean; data?: T; error?: string; code?: number }> {
  try {
    const { data, error } = await supabase.functions.invoke<T>(functionName, {
      body,
      method: options?.method ?? 'POST',
    })

    if (error) {
      return { success: false, error: error.message, code: error.status ?? 500 }
    }

    return { success: true, data: data as T }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Bilinmeyen hata'
    return { success: false, error: message, code: 500 }
  }
}

// =====================================================
// Supabase REST API çağırıcısı
// =====================================================
export async function callRestApi<T = unknown>(
  endpoint: string,
  options?: {
    method?: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH'
    body?: Record<string, unknown>
    params?: Record<string, string>
  }
): Promise<{ success: boolean; data?: T; error?: string; code?: number }> {
  try {
    const method = options?.method ?? 'GET'
    let url = `${supabaseUrl}/rest/v1${endpoint}`
    if (options?.params) {
      const query = new URLSearchParams(options.params).toString()
      url = `${url}?${query}`
    }

    const { data: { session } } = await supabase.auth.getSession()
    const token = session?.access_token ?? ''

    const response = await fetch(url, {
      method,
      headers: {
        'apikey': supabaseAnonKey,
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: options?.body ? JSON.stringify(options.body) : undefined,
    })

    const responseData = await response.json() as T

    if (!response.ok) {
      const errMsg =
        typeof responseData === 'object' && responseData !== null
          ? (responseData as Record<string, unknown>).message as string ?? response.statusText
          : response.statusText
      return { success: false, error: errMsg, code: response.status }
    }

    return { success: true, data: responseData, code: response.status }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Bilinmeyen hata'
    return { success: false, error: message, code: 500 }
  }
}

// =====================================================
// RPC çağırıcısı (Supabase PostgreSQL fonksiyonları)
// =====================================================
export async function callRpc<T = unknown>(
  functionName: string,
  params?: Record<string, unknown>
): Promise<{ success: boolean; data?: T; error?: string }> {
  try {
    const { data, error } = await supabase.rpc(functionName, params ?? {})

    if (error) {
      return { success: false, error: error.message }
    }

    return { success: true, data: data as T }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Bilinmeyen hata'
    return { success: false, error: message }
  }
}

export default supabase
