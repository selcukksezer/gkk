// =====================================================
// store/sessionStore.ts - Oturum yönetim store'u
// GDScript SessionManager.gd'den dönüştürüldü
// Zustand ile global state yönetimi
// =====================================================
'use client'

import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'
import supabase, { callEdgeFunction } from '@/lib/supabase'
import { formatPlayerData } from '@/types/player'
import type { PlayerData } from '@/types/player'

export interface AuthCredentials {
  email: string
  username: string
  password: string
}

interface SessionState {
  // Oturum bilgileri
  isAuthenticated: boolean
  accessToken: string
  refreshToken: string
  playerId: string
  username: string
  deviceId: string

  // Yükleme durumu
  isLoading: boolean
  authError: string | null

  // Eylemler
  login: (emailOrUsername: string, password: string) => Promise<{ success: boolean; error?: string }>
  register: (credentials: AuthCredentials) => Promise<{ success: boolean; error?: string }>
  logout: () => Promise<void>
  loadSession: () => Promise<boolean>
  clearError: () => void
  setTokens: (access: string, refresh: string) => void
}

// Device ID oluştur veya mevcut olanı yükle
function getOrCreateDeviceId(): string {
  if (typeof window === 'undefined') return 'ssr-device'
  const stored = localStorage.getItem('gk_device_id')
  if (stored) return stored
  const id = `${Date.now()}-${Math.floor(Math.random() * 999999)}`
  localStorage.setItem('gk_device_id', id)
  return id
}

export const useSessionStore = create<SessionState>()(
  persist(
    (set, get) => ({
      isAuthenticated: false,
      accessToken: '',
      refreshToken: '',
      playerId: '',
      username: '',
      deviceId: getOrCreateDeviceId(),
      isLoading: false,
      authError: null,

      clearError: () => set({ authError: null }),

      setTokens: (access: string, refresh: string) => {
        set({ accessToken: access, refreshToken: refresh })
      },

      login: async (emailOrUsername: string, password: string) => {
        set({ isLoading: true, authError: null })

        // Kullanıcı adı ile girişe izin ver: önce e-posta dönüşümünü dene
        let loginEmail = emailOrUsername
        if (!emailOrUsername.includes('@')) {
          // Kullanıcı adı girildi – Edge Function bunu çözecek
          loginEmail = emailOrUsername
        }

        try {
          const result = await callEdgeFunction<{
            session?: { access_token: string; refresh_token: string }
            user?: { id: string; username: string }
            data?: { session?: { access_token: string; refresh_token: string }; user?: { id: string; username: string } }
          }>('auth-login', {
            email: loginEmail,
            password,
            device_id: get().deviceId,
          })

          if (!result.success || !result.data) {
            const errMsg = result.error ?? 'Giriş başarısız'
            set({ isLoading: false, authError: errMsg })
            return { success: false, error: errMsg }
          }

          // Yanıt yapısını normalize et
          const responseData = result.data
          const sessionData =
            (responseData.data?.session) ?? responseData.session
          const userData = (responseData.data?.user) ?? responseData.user

          if (!sessionData) {
            set({ isLoading: false, authError: 'Sunucu yanıtı geçersiz (oturum verisi eksik)' })
            return { success: false, error: 'Sunucu yanıtı geçersiz' }
          }

          // Supabase oturumunu güncelle
          await supabase.auth.setSession({
            access_token: sessionData.access_token,
            refresh_token: sessionData.refresh_token,
          })

          set({
            isAuthenticated: true,
            accessToken: sessionData.access_token,
            refreshToken: sessionData.refresh_token,
            playerId: userData?.id ?? '',
            username: userData?.username ?? loginEmail,
            isLoading: false,
            authError: null,
          })

          // Player store'a yükleme sinyali gönder (döngüsel import yerine event)
          if (userData) {
            window.dispatchEvent(
              new CustomEvent('player-data-loaded', { detail: userData })
            )
          }

          return { success: true }
        } catch (err) {
          const message = err instanceof Error ? err.message : 'Bilinmeyen hata'
          set({ isLoading: false, authError: message })
          return { success: false, error: message }
        }
      },

      register: async (credentials: AuthCredentials) => {
        set({ isLoading: true, authError: null })

        try {
          const result = await callEdgeFunction<{
            session?: { access_token: string; refresh_token: string }
            user?: { id: string; username: string }
            data?: { session?: { access_token: string; refresh_token: string }; user?: { id: string; username: string } }
          }>('auth-register', {
            email: credentials.email,
            username: credentials.username,
            password: credentials.password,
            device_id: get().deviceId,
          })

          if (!result.success || !result.data) {
            const errMsg = result.error ?? 'Kayıt başarısız'
            set({ isLoading: false, authError: errMsg })
            return { success: false, error: errMsg }
          }

          const responseData = result.data
          const sessionData =
            (responseData.data?.session) ?? responseData.session
          const userData = (responseData.data?.user) ?? responseData.user

          if (!sessionData) {
            // E-posta doğrulaması gerekiyor olabilir
            set({ isLoading: false })
            return { success: true }
          }

          await supabase.auth.setSession({
            access_token: sessionData.access_token,
            refresh_token: sessionData.refresh_token,
          })

          set({
            isAuthenticated: true,
            accessToken: sessionData.access_token,
            refreshToken: sessionData.refresh_token,
            playerId: userData?.id ?? '',
            username: userData?.username ?? credentials.username,
            isLoading: false,
            authError: null,
          })

          if (userData) {
            window.dispatchEvent(
              new CustomEvent('player-data-loaded', { detail: userData })
            )
          }

          return { success: true }
        } catch (err) {
          const message = err instanceof Error ? err.message : 'Bilinmeyen hata'
          set({ isLoading: false, authError: message })
          return { success: false, error: message }
        }
      },

      logout: async () => {
        await supabase.auth.signOut()
        set({
          isAuthenticated: false,
          accessToken: '',
          refreshToken: '',
          playerId: '',
          username: '',
          authError: null,
        })
        // Player store'u temizle
        window.dispatchEvent(new CustomEvent('player-logout'))
      },

      loadSession: async () => {
        set({ isLoading: true })
        try {
          const { data: { session }, error } = await supabase.auth.getSession()

          if (error || !session) {
            set({ isAuthenticated: false, isLoading: false })
            return false
          }

          // Mevcut kullanıcı bilgisini al
          const { data: { user } } = await supabase.auth.getUser()
          if (!user) {
            set({ isAuthenticated: false, isLoading: false })
            return false
          }

          // game.users tablosundan oyuncu verisini çek
          const { data: usersData } = await supabase
            .from('users')
            .select('*')
            .eq('auth_id', user.id)
            .limit(1)

          if (usersData && usersData.length > 0) {
            const playerRow = usersData[0] as Record<string, unknown>
            set({
              isAuthenticated: true,
              accessToken: session.access_token,
              refreshToken: session.refresh_token,
              playerId: playerRow.id as string ?? '',
              username: playerRow.username as string ?? '',
              isLoading: false,
            })

            window.dispatchEvent(
              new CustomEvent('player-data-loaded', { detail: formatPlayerData(playerRow) })
            )
            return true
          }

          set({ isAuthenticated: false, isLoading: false })
          return false
        } catch {
          set({ isAuthenticated: false, isLoading: false })
          return false
        }
      },
    }),
    {
      name: 'gk-session',
      storage: createJSONStorage(() =>
        typeof window !== 'undefined' ? localStorage : {
          getItem: () => null,
          setItem: () => undefined,
          removeItem: () => undefined,
        }
      ),
      partialize: (state) => ({
        accessToken: state.accessToken,
        refreshToken: state.refreshToken,
        playerId: state.playerId,
        username: state.username,
        deviceId: state.deviceId,
        isAuthenticated: state.isAuthenticated,
      }),
    }
  )
)
