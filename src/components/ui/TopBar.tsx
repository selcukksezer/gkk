// =====================================================
// components/ui/TopBar.tsx - Üst bilgi çubuğu
// GDScript TopBar.gd'den dönüştürüldü
// =====================================================
'use client'

import { useCallback } from 'react'
import { useRouter } from 'next/navigation'
import { motion } from 'framer-motion'
import { usePlayerStore } from '@/store/playerStore'
import { useSessionStore } from '@/store/sessionStore'
import { formatNumber } from '@/lib/utils/mathUtils'

interface TopBarProps {
  showBackButton?: boolean
  title?: string
  onBack?: () => void
}

export default function TopBar({ showBackButton = false, title, onBack }: TopBarProps) {
  const router = useRouter()
  const { currentEnergy, maxEnergy, gold, gems, level, player } = usePlayerStore()
  const { logout } = useSessionStore()

  const handleBack = useCallback(() => {
    if (onBack) {
      onBack()
    } else {
      router.back()
    }
  }, [onBack, router])

  const handleLogout = useCallback(async () => {
    if (window.confirm('Oturumdan çıkmak istiyor musunuz?')) {
      await logout()
      router.replace('/login')
    }
  }, [logout, router])

  const playerName = player?.display_name ?? player?.username ?? 'Oyuncu'
  const energyRatio = maxEnergy > 0 ? currentEnergy / maxEnergy : 0

  const energyColor =
    energyRatio > 0.5 ? '#00aaff' : energyRatio > 0.25 ? '#f59e0b' : '#ef4444'

  return (
    <header className="safe-top bg-gk-panel border-b border-gk-border">
      <div className="flex items-center gap-2 px-3 py-2">

        {/* Sol: geri butonu veya oyuncu adı */}
        <div className="flex items-center gap-2 min-w-0 flex-1">
          {showBackButton ? (
            <button
              onClick={handleBack}
              className="w-8 h-8 flex items-center justify-center rounded-lg bg-gk-surface text-gk-silver hover:text-white hover:bg-gk-border transition-colors flex-shrink-0"
              aria-label="Geri"
            >
              ←
            </button>
          ) : null}

          {title ? (
            <h1 className="font-game text-gk-gold font-semibold text-sm truncate">
              {title}
            </h1>
          ) : (
            <div className="min-w-0">
              <div className="text-white font-semibold text-sm truncate">{playerName}</div>
              <div className="text-gk-silver text-xs">Sv. {level}</div>
            </div>
          )}
        </div>

        {/* Orta: Kaynaklar */}
        <div className="flex items-center gap-3 flex-shrink-0">
          {/* Altın */}
          <div className="flex items-center gap-1">
            <span className="text-base leading-none">💰</span>
            <span className="text-gk-gold font-semibold text-xs">
              {formatNumber(gold)}
            </span>
          </div>

          {/* Elmas */}
          <div className="flex items-center gap-1">
            <span className="text-base leading-none">💎</span>
            <span className="text-blue-300 font-semibold text-xs">
              {formatNumber(gems)}
            </span>
          </div>
        </div>

        {/* Sağ: Enerji + Çıkış */}
        <div className="flex items-center gap-2 flex-shrink-0">
          {/* Enerji */}
          <div className="flex items-center gap-1">
            <motion.span
              animate={{ scale: currentEnergy < 20 ? [1, 1.2, 1] : 1 }}
              transition={{ repeat: currentEnergy < 20 ? Infinity : 0, duration: 1 }}
              className="text-base leading-none"
              style={{ color: energyColor }}
            >
              ⚡
            </motion.span>
            <span className="text-xs font-semibold" style={{ color: energyColor }}>
              {currentEnergy}/{maxEnergy}
            </span>
          </div>

          {/* Çıkış butonu */}
          {!showBackButton && (
            <button
              onClick={handleLogout}
              className="w-7 h-7 flex items-center justify-center rounded-lg bg-gk-surface text-gk-silver hover:text-red-400 hover:bg-red-900/20 transition-colors text-xs"
              aria-label="Çıkış"
            >
              🚪
            </button>
          )}
        </div>
      </div>

      {/* Enerji çubuğu – tam genişlik */}
      <div className="h-1 bg-gk-surface">
        <motion.div
          className="h-full transition-all duration-500"
          style={{
            width: `${energyRatio * 100}%`,
            background: `linear-gradient(90deg, #005580, ${energyColor})`,
          }}
          initial={false}
          animate={{ width: `${energyRatio * 100}%` }}
        />
      </div>
    </header>
  )
}
