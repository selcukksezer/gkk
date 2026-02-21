// =====================================================
// app/(game)/season/page.tsx - Sezon ekranı
// GDScript SeasonScreen.gd'den dönüştürüldü
// =====================================================
'use client'

import { useRouter } from 'next/navigation'
import { motion } from 'framer-motion'
import { usePlayerStore } from '@/store/playerStore'
import { formatNumber } from '@/lib/utils/mathUtils'
import { formatCountdown } from '@/lib/utils/dateTimeUtils'
import { useState, useEffect } from 'react'

const SEASON_NUMBER = 3
const SEASON_NAME = 'Gölge Çağı'
const SEASON_END = new Date('2026-03-31T23:59:59Z')

interface SeasonReward {
  level: number
  icon: string
  name: string
  type: 'free' | 'premium'
  value?: string
  claimed: boolean
}

const SEASON_REWARDS: SeasonReward[] = [
  { level: 1, icon: '💰', name: '500 Altın', type: 'free', value: '500', claimed: true },
  { level: 2, icon: '⚡', name: 'Enerji +5', type: 'free', value: '+5', claimed: true },
  { level: 3, icon: '💎', name: '20 Elmas', type: 'premium', value: '20', claimed: false },
  { level: 4, icon: '🗡️', name: 'Gümüş Kılıç', type: 'premium', value: 'Nadir', claimed: false },
  { level: 5, icon: '💰', name: '2.000 Altın', type: 'free', value: '2.000', claimed: false },
  { level: 6, icon: '🛡️', name: 'Gölge Kalkanı', type: 'premium', value: 'Epik', claimed: false },
  { level: 7, icon: '💎', name: '50 Elmas', type: 'premium', value: '50', claimed: false },
  { level: 8, icon: '🏆', name: 'Zafer Rozeti', type: 'free', value: '', claimed: false },
  { level: 9, icon: '🔮', name: 'Rune Parçası', type: 'premium', value: '×10', claimed: false },
  { level: 10, icon: '👑', name: 'Sezon Tacı', type: 'free', value: 'Efsanevi', claimed: false },
  { level: 15, icon: '⚔️', name: 'Sezon Silahı', type: 'premium', value: 'Efsanevi', claimed: false },
  { level: 20, icon: '🌟', name: 'Şampiyonluk Zırhı', type: 'premium', value: 'Mitik', claimed: false },
  { level: 25, icon: '💎', name: '500 Elmas', type: 'premium', value: '500', claimed: false },
  { level: 30, icon: '👑', name: 'Sezon Efendisi Unvanı', type: 'free', value: 'Unvan', claimed: false },
]

export default function SeasonPage() {
  const router = useRouter()
  const { player } = usePlayerStore((s) => ({ player: s.player }))

  const seasonPoints = player?.season_points ?? 0
  const seasonLevel = Math.floor(seasonPoints / 1000) + 1
  const levelProgress = seasonPoints % 1000
  const progressPct = (levelProgress / 1000) * 100
  const isPremium = false // Mock: no premium pass

  const [timeLeft, setTimeLeft] = useState(0)

  useEffect(() => {
    const calc = () => {
      const diff = Math.max(0, Math.floor((SEASON_END.getTime() - Date.now()) / 1000))
      setTimeLeft(diff)
    }
    calc()
    const interval = setInterval(calc, 1000)
    return () => clearInterval(interval)
  }, [])

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
      className="px-4 pt-4 pb-4 max-w-[480px] mx-auto"
    >
      {/* Geri butonu */}
      <button
        onClick={() => router.back()}
        className="flex items-center gap-2 text-gk-silver hover:text-white mb-4 transition-colors"
      >
        ← Geri
      </button>

      {/* Sezon başlığı */}
      <div className="gk-panel text-center mb-4 relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-b from-purple-900/30 to-transparent" />
        <motion.div
          animate={{ rotate: [0, 5, -5, 0] }}
          transition={{ repeat: Infinity, duration: 4 }}
          className="text-6xl mb-3"
        >
          ⚔️
        </motion.div>
        <p className="text-gk-silver text-sm uppercase tracking-widest">Sezon {SEASON_NUMBER}</p>
        <h1 className="gk-title text-2xl mt-1">{SEASON_NAME}</h1>
        <div className="mt-3 flex items-center justify-center gap-2">
          <span className="text-gk-silver text-sm">Bitiş:</span>
          <span className="text-white font-mono font-bold text-sm">{formatCountdown(timeLeft)}</span>
        </div>
      </div>

      {/* Sezon seviyesi */}
      <div className="gk-panel mb-4">
        <div className="flex items-center justify-between mb-2">
          <div>
            <h2 className="text-white font-bold text-lg">Sezon Seviye {seasonLevel}</h2>
            <p className="text-gk-silver text-xs">{formatNumber(seasonPoints)} sezon puanı</p>
          </div>
          <div className="text-right">
            <div className={`gk-badge ${isPremium ? 'bg-gk-gold/20 text-gk-gold' : 'bg-gk-surface text-gk-silver'}`}>
              {isPremium ? '👑 Premium' : '🆓 Ücretsiz'}
            </div>
          </div>
        </div>

        <div className="h-3 bg-gk-surface rounded-full overflow-hidden mb-1">
          <motion.div
            initial={{ width: 0 }}
            animate={{ width: `${progressPct}%` }}
            transition={{ duration: 1 }}
            className="h-full rounded-full"
            style={{ background: 'linear-gradient(90deg, #8b5cf6, #d4a017)' }}
          />
        </div>
        <div className="flex justify-between text-xs text-gk-silver">
          <span>{levelProgress} / 1.000 puan</span>
          <span>Sonraki: Seviye {seasonLevel + 1}</span>
        </div>
      </div>

      {/* Premium teşvik */}
      {!isPremium && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="gk-panel mb-4 border border-gk-gold/50 bg-gk-gold/5"
        >
          <div className="flex items-center gap-3">
            <span className="text-3xl">👑</span>
            <div className="flex-1">
              <p className="text-gk-gold font-bold">Premium Battle Pass</p>
              <p className="text-gk-silver text-xs">Tüm ödüllerin kilidini aç!</p>
            </div>
            <button className="gk-btn-gold text-sm px-3 py-1.5">
              💎 499
            </button>
          </div>
        </motion.div>
      )}

      {/* Ödüller */}
      <div>
        <h2 className="gk-title text-base mb-3">🎁 Sezon Ödülleri</h2>
        <div className="space-y-2">
          {SEASON_REWARDS.map((reward, i) => {
            const isUnlocked = seasonLevel >= reward.level
            const isCurrent = seasonLevel === reward.level

            return (
              <motion.div
                key={reward.level}
                initial={{ opacity: 0, x: -10 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: i * 0.04 }}
                className={`flex items-center gap-3 rounded-xl p-3 border transition-all ${
                  reward.claimed
                    ? 'bg-green-900/10 border-green-800/50 opacity-60'
                    : isCurrent
                      ? 'bg-gk-panel border-gk-gold'
                      : isUnlocked
                        ? 'bg-gk-panel border-gk-border'
                        : 'bg-gk-surface/50 border-gk-border/30 opacity-50'
                }`}
              >
                {/* Seviye */}
                <div
                  className="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold flex-shrink-0"
                  style={{
                    background: isCurrent ? '#d4a017' : isUnlocked ? '#22c55e33' : '#2a2a3a',
                    color: isCurrent ? '#0a0a0f' : isUnlocked ? '#22c55e' : '#a8a8b8',
                  }}
                >
                  {reward.level}
                </div>

                {/* İkon */}
                <div
                  className={`w-10 h-10 rounded-xl flex items-center justify-center text-xl flex-shrink-0 border ${
                    reward.type === 'premium'
                      ? 'border-gk-gold/50 bg-gk-gold/10'
                      : 'border-gk-border bg-gk-surface'
                  }`}
                >
                  {reward.icon}
                </div>

                {/* Bilgi */}
                <div className="flex-1 min-w-0">
                  <p className="text-white text-sm font-bold truncate">{reward.name}</p>
                  <div className="flex items-center gap-2">
                    {reward.value && <span className="text-gk-gold text-xs">{reward.value}</span>}
                    <span
                      className={`text-xs ${reward.type === 'premium' ? 'text-gk-gold' : 'text-gk-silver'}`}
                    >
                      {reward.type === 'premium' ? '👑 Premium' : '🆓 Ücretsiz'}
                    </span>
                  </div>
                </div>

                {/* Durum */}
                <div className="flex-shrink-0">
                  {reward.claimed ? (
                    <span className="text-green-400 text-sm">✅</span>
                  ) : isUnlocked && !reward.claimed ? (
                    <button className="gk-btn-gold text-xs px-2 py-1">Al</button>
                  ) : (
                    <span className="text-gk-border text-sm">🔒</span>
                  )}
                </div>
              </motion.div>
            )
          })}
        </div>
      </div>
    </motion.div>
  )
}
