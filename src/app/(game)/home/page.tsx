// =====================================================
// app/(game)/home/page.tsx - Ana sayfa
// GDScript HomeScreen.gd'den dönüştürüldü
// =====================================================
'use client'

import { useEffect, useState, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import { motion, AnimatePresence } from 'framer-motion'
import { usePlayerStore } from '@/store/playerStore'
import { formatNumber } from '@/lib/utils/mathUtils'
import { formatCountdown, getRemainingSecondsFromIso } from '@/lib/utils/dateTimeUtils'

interface Notification {
  id: string
  icon: string
  title: string
  message: string
  type: 'warning' | 'info' | 'danger'
  action?: { label: string; href: string }
}

const QUICK_ACTIONS = [
  { icon: '⚔️', label: 'Zindan', href: '/dungeon', color: 'text-orange-400' },
  { icon: '🆚', label: 'PvP', href: '/pvp', color: 'text-red-400' },
  { icon: '📜', label: 'Görevler', href: '/quests', color: 'text-blue-400' },
  { icon: '⚙️', label: 'Tesisler', href: '/facilities', color: 'text-green-400' },
  { icon: '🛍️', label: 'Pazar', href: '/market', color: 'text-yellow-400' },
  { icon: '🏰', label: 'Lonca', href: '/guild', color: 'text-purple-400' },
]

export default function HomePage() {
  const router = useRouter()
  const {
    player,
    currentEnergy,
    maxEnergy,
    tolerance,
    gold,
    gems,
    level,
    xp,
    nextLevelXp,
    inHospital,
    inPrison,
    hospital_until,
    prison_until,
    pvpWins,
    pvpLosses,
  } = usePlayerStore((s) => ({
    player: s.player,
    currentEnergy: s.currentEnergy,
    maxEnergy: s.maxEnergy,
    tolerance: s.tolerance,
    gold: s.gold,
    gems: s.gems,
    level: s.level,
    xp: s.xp,
    nextLevelXp: s.nextLevelXp,
    inHospital: s.inHospital,
    inPrison: s.inPrison,
    hospital_until: s.player?.hospital_until,
    prison_until: s.player?.prison_until,
    pvpWins: s.pvpWins,
    pvpLosses: s.pvpLosses,
  }))

  const [hospitalCountdown, setHospitalCountdown] = useState(0)
  const [prisonCountdown, setPrisonCountdown] = useState(0)

  // Geri sayım
  useEffect(() => {
    const interval = setInterval(() => {
      if (hospital_until) {
        setHospitalCountdown(getRemainingSecondsFromIso(hospital_until))
      }
      if (prison_until) {
        setPrisonCountdown(getRemainingSecondsFromIso(prison_until))
      }
    }, 1000)
    return () => clearInterval(interval)
  }, [hospital_until, prison_until])

  // Bildirimler
  const notifications: Notification[] = []

  if (inHospital && hospitalCountdown > 0) {
    notifications.push({
      id: 'hospital',
      icon: '🏥',
      title: 'Hastanede',
      message: `Taburcu: ${formatCountdown(hospitalCountdown)}`,
      type: 'warning',
      action: { label: 'Hastane', href: '/hospital' },
    })
  }

  if (inPrison && prisonCountdown > 0) {
    notifications.push({
      id: 'prison',
      icon: '👮',
      title: 'Cezaevinde',
      message: `Tahliye: ${formatCountdown(prisonCountdown)}`,
      type: 'danger',
      action: { label: 'Cezaevi', href: '/prison' },
    })
  }

  if (currentEnergy < maxEnergy * 0.3) {
    notifications.push({
      id: 'energy',
      icon: '⚡',
      title: 'Enerji Düşük',
      message: `${currentEnergy}/${maxEnergy} enerji kaldı`,
      type: 'warning',
    })
  }

  if (tolerance >= 60) {
    notifications.push({
      id: 'tolerance',
      icon: '⚠️',
      title: 'Yüksek Tolerans',
      message: `Bağımlılık riski: %${tolerance}`,
      type: 'danger',
    })
  }

  const displayName = player?.display_name ?? player?.username ?? 'Kahraman'
  const expPercent = nextLevelXp > 0 ? Math.min((xp / nextLevelXp) * 100, 100) : 0
  const energyPercent = maxEnergy > 0 ? (currentEnergy / maxEnergy) * 100 : 0
  const toleranceColor = tolerance >= 80 ? '#ef4444' : tolerance >= 50 ? '#f59e0b' : '#22c55e'

  return (
    <div className="p-4 space-y-4">

      {/* Oyuncu bilgi kartı */}
      <motion.div
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4 }}
        className="gk-panel"
      >
        <div className="flex items-start justify-between mb-3">
          <div>
            <h2 className="font-game text-gk-gold text-xl font-bold">{displayName}</h2>
            <p className="text-gk-silver text-sm">Seviye {level} Kahraman</p>
          </div>
          <div className="text-right">
            <div className="text-gk-gold font-bold text-lg">💰 {formatNumber(gold)}</div>
            <div className="text-blue-300 text-sm">💎 {formatNumber(gems)}</div>
          </div>
        </div>

        {/* XP çubuğu */}
        <div className="mb-3">
          <div className="flex justify-between text-xs text-gk-silver mb-1">
            <span>Deneyim</span>
            <span>{formatNumber(xp)} / {formatNumber(nextLevelXp)}</span>
          </div>
          <div className="h-2 bg-gk-surface rounded-full overflow-hidden">
            <motion.div
              className="h-full rounded-full"
              style={{ background: 'linear-gradient(90deg, #1a6b2e, #22cc44)' }}
              initial={{ width: 0 }}
              animate={{ width: `${expPercent}%` }}
              transition={{ duration: 0.8, ease: 'easeOut' }}
            />
          </div>
        </div>

        {/* Enerji */}
        <div className="mb-3">
          <div className="flex justify-between text-xs mb-1">
            <span className="text-gk-silver">Enerji ⚡</span>
            <span style={{ color: energyPercent > 50 ? '#00aaff' : energyPercent > 25 ? '#f59e0b' : '#ef4444' }}>
              {currentEnergy} / {maxEnergy}
            </span>
          </div>
          <div className="gk-progress-energy">
            <motion.div
              className="gk-progress-energy-fill"
              initial={{ width: 0 }}
              animate={{ width: `${energyPercent}%` }}
              transition={{ duration: 0.6 }}
            />
          </div>
        </div>

        {/* Tolerans */}
        <div>
          <div className="flex justify-between text-xs mb-1">
            <span className="text-gk-silver">Tolerans 🧪</span>
            <span style={{ color: toleranceColor }}>{tolerance} / 100</span>
          </div>
          <div className="gk-progress-tolerance">
            <motion.div
              className="h-full rounded-full transition-all"
              style={{
                width: `${tolerance}%`,
                background: `linear-gradient(90deg, #1a1a1a, ${toleranceColor})`,
              }}
              animate={{ width: `${tolerance}%` }}
            />
          </div>
        </div>
      </motion.div>

      {/* PvP İstatistikleri */}
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.1 }}
        className="grid grid-cols-3 gap-3"
      >
        <div className="gk-panel text-center py-3">
          <div className="text-green-400 font-bold text-xl">{pvpWins}</div>
          <div className="text-gk-silver text-xs">Zafer</div>
        </div>
        <div className="gk-panel text-center py-3">
          <div className="text-red-400 font-bold text-xl">{pvpLosses}</div>
          <div className="text-gk-silver text-xs">Mağlubiyet</div>
        </div>
        <div className="gk-panel text-center py-3">
          <div className="text-gk-gold font-bold text-xl">
            {pvpWins + pvpLosses > 0 ? Math.round((pvpWins / (pvpWins + pvpLosses)) * 100) : 0}%
          </div>
          <div className="text-gk-silver text-xs">Kazanma Oranı</div>
        </div>
      </motion.div>

      {/* Bildirimler */}
      <AnimatePresence>
        {notifications.length > 0 && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="space-y-2"
          >
            <h3 className="text-gk-silver text-xs font-semibold tracking-wider uppercase">
              Bildirimler
            </h3>
            {notifications.map((notif) => (
              <motion.div
                key={notif.id}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: 20 }}
                onClick={() => notif.action && router.push(notif.action.href)}
                className={`flex items-center gap-3 p-3 rounded-xl border cursor-pointer transition-all active:scale-98 ${
                  notif.type === 'danger'
                    ? 'bg-red-900/20 border-red-800 hover:border-red-600'
                    : notif.type === 'warning'
                    ? 'bg-yellow-900/20 border-yellow-800 hover:border-yellow-600'
                    : 'bg-gk-panel border-gk-border hover:border-gk-gold'
                }`}
              >
                <span className="text-2xl">{notif.icon}</span>
                <div className="flex-1 min-w-0">
                  <div className="font-semibold text-sm">{notif.title}</div>
                  <div className="text-gk-silver text-xs truncate">{notif.message}</div>
                </div>
                {notif.action && (
                  <span className="text-gk-silver text-xs flex-shrink-0">›</span>
                )}
              </motion.div>
            ))}
          </motion.div>
        )}
      </AnimatePresence>

      {/* Hızlı eylemler */}
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.2 }}
      >
        <h3 className="text-gk-silver text-xs font-semibold tracking-wider uppercase mb-3">
          Hızlı Eylemler
        </h3>
        <div className="grid grid-cols-3 gap-3">
          {QUICK_ACTIONS.map((action, i) => (
            <motion.button
              key={action.href}
              initial={{ opacity: 0, scale: 0.8 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: 0.3 + i * 0.05 }}
              whileTap={{ scale: 0.95 }}
              onClick={() => router.push(action.href)}
              className="gk-panel flex flex-col items-center gap-2 py-4 hover:border-gk-gold transition-all active:scale-95"
            >
              <span className="text-3xl">{action.icon}</span>
              <span className={`text-xs font-semibold ${action.color}`}>{action.label}</span>
            </motion.button>
          ))}
        </div>
      </motion.div>

      {/* Aktif görevler (placeholder) */}
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.4 }}
      >
        <div className="flex items-center justify-between mb-3">
          <h3 className="text-gk-silver text-xs font-semibold tracking-wider uppercase">
            Aktif Görevler
          </h3>
          <button
            onClick={() => router.push('/quests')}
            className="text-gk-gold text-xs"
          >
            Tümünü gör →
          </button>
        </div>
        <div className="gk-panel">
          <p className="text-gk-silver text-sm text-center py-4">
            Aktif görev yok. Görevler sayfasından yeni görev al!
          </p>
        </div>
      </motion.div>
    </div>
  )
}
