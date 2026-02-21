// =====================================================
// app/(game)/layout.tsx - Oyun içi layout
// Kimlik doğrulama koruması + TopBar + BottomNav
// GDScript Main.gd'den dönüştürüldü
// =====================================================
'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { useSessionStore } from '@/store/sessionStore'
import { usePlayerStore } from '@/store/playerStore'
import TopBar from '@/components/ui/TopBar'
import BottomNav from '@/components/ui/BottomNav'
import LoadingSpinner from '@/components/ui/LoadingSpinner'

export default function GameLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter()
  const { isAuthenticated, loadSession, isLoading: sessionLoading } = useSessionStore()
  const { fetchPlayerProfile, isLoaded } = usePlayerStore()
  const [isInitializing, setIsInitializing] = useState(true)

  useEffect(() => {
    const initialize = async () => {
      // Oturumu yükle
      const sessionValid = await loadSession()

      if (!sessionValid) {
        router.replace('/login')
        return
      }

      // Oyuncu profilini yükle
      if (!isLoaded) {
        await fetchPlayerProfile()
      }

      setIsInitializing(false)
    }

    initialize()
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  // Oturum durumu değişirse yönlendir
  useEffect(() => {
    if (!sessionLoading && !isAuthenticated && !isInitializing) {
      router.replace('/login')
    }
  }, [isAuthenticated, sessionLoading, isInitializing, router])

  if (isInitializing || sessionLoading) {
    return (
      <div className="min-h-screen bg-gk-dark flex flex-col items-center justify-center">
        <div className="text-6xl mb-4">⚔️</div>
        <LoadingSpinner size="lg" message="Gölge Krallık yükleniyor..." />
      </div>
    )
  }

  if (!isAuthenticated) {
    return null // Yönlendirme yapılıyor
  }

  return (
    <div className="gk-screen">
      {/* Üst bilgi çubuğu */}
      <TopBar />

      {/* Ana içerik */}
      <main className="gk-scroll-content">
        {children}
      </main>

      {/* Alt navigasyon */}
      <BottomNav />
    </div>
  )
}
