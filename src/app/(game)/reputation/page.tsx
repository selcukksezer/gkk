// =====================================================
// app/(game)/reputation/page.tsx - Reputasyon ekranı
// GDScript ReputationScreen.gd'den dönüştürüldü
// =====================================================
'use client'

import { useRouter } from 'next/navigation'
import { motion } from 'framer-motion'
import { usePlayerStore } from '@/store/playerStore'
import { formatNumber } from '@/lib/utils/mathUtils'
import { timeAgo } from '@/lib/utils/dateTimeUtils'

const REPUTATION_LEVELS = [
  { min: 80, max: 100, label: 'Efsanevi Kahraman', icon: '👑', color: '#ffd700', desc: 'Krallığın en büyük kahramanı' },
  { min: 50, max: 79, label: 'Büyük Kahraman', icon: '🌟', color: '#22c55e', desc: 'Halkın sevgisini kazanmış' },
  { min: 20, max: 49, label: 'Kahraman', icon: '⭐', color: '#4ade80', desc: 'İyiliği ile tanınan savaşçı' },
  { min: 0, max: 19, label: 'Vatandaş', icon: '🧍', color: '#a8a8b8', desc: 'Sıradan bir krallık vatandaşı' },
  { min: -49, max: -1, label: 'Şüpheli', icon: '😈', color: '#f97316', desc: 'Güvenilmez biri olarak bilinir' },
  { min: -100, max: -50, label: 'Haydut', icon: '💀', color: '#ef4444', desc: 'Krallığın karanlık yüzü' },
]

function getRepLevel(rep: number) {
  return REPUTATION_LEVELS.find((r) => rep >= r.min && rep <= r.max) ?? REPUTATION_LEVELS[REPUTATION_LEVELS.length - 1]
}

const MOCK_RECENT_BATTLES = [
  { id: 'b1', opponent: 'KaranlıkŞövalye', outcome: 'win', repChange: -3, goldChange: 450, timestamp: new Date(Date.now() - 3600000).toISOString() },
  { id: 'b2', opponent: 'DemirKral', outcome: 'loss', repChange: -3, goldChange: -120, timestamp: new Date(Date.now() - 7200000).toISOString() },
  { id: 'b3', opponent: 'GölgeSavaşçı', outcome: 'win', repChange: -3, goldChange: 280, timestamp: new Date(Date.now() - 86400000).toISOString() },
  { id: 'b4', opponent: 'HızlıKılıç', outcome: 'win', repChange: -3, goldChange: 180, timestamp: new Date(Date.now() - 172800000).toISOString() },
]

const REP_EFFECTS = [
  { threshold: 80, label: 'Kahraman indirimi (dükkan %10)', positive: true },
  { threshold: 50, label: 'Enerji yenileme hızı +5%', positive: true },
  { threshold: 20, label: 'Normal tüccar fiyatları', positive: true },
  { threshold: 0, label: 'Standart kural seti', positive: true },
  { threshold: -30, label: 'Muhafızlar sizi takip eder', positive: false },
  { threshold: -50, label: 'Şehir girişi yasak!', positive: false },
  { threshold: -80, label: 'Ödüllü suçlu ilan edildiniz', positive: false },
]

export default function ReputationPage() {
  const router = useRouter()
  const { player, pvpWins, pvpLosses } = usePlayerStore((s) => ({
    player: s.player,
    pvpWins: s.pvpWins,
    pvpLosses: s.pvpLosses,
  }))

  const reputation = player?.reputation ?? 0
  const repLevel = getRepLevel(reputation)

  // Normalize -100..100 to 0..100%
  const barPct = ((reputation + 100) / 200) * 100

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

      {/* Ana reputasyon kartı */}
      <div
        className="gk-panel text-center mb-4 relative overflow-hidden"
        style={{ borderColor: repLevel.color + '44' }}
      >
        <div
          className="absolute inset-0 opacity-5"
          style={{ background: `linear-gradient(to bottom, ${repLevel.color}, transparent)` }}
        />
        <motion.div
          animate={{ scale: [1, 1.05, 1] }}
          transition={{ repeat: Infinity, duration: 3 }}
          className="text-6xl mb-3"
        >
          {repLevel.icon}
        </motion.div>
        <h1 className="text-2xl font-bold mb-1" style={{ color: repLevel.color }}>
          {repLevel.label}
        </h1>
        <p className="text-gk-silver text-sm mb-4">{repLevel.desc}</p>

        {/* Büyük puan */}
        <div className="text-5xl font-bold mb-4" style={{ color: repLevel.color }}>
          {reputation > 0 ? '+' : ''}{reputation}
        </div>

        {/* İtibar barı */}
        <div className="px-4 mb-2">
          <div className="h-4 bg-gk-surface rounded-full overflow-hidden relative">
            {/* Gradient arka plan */}
            <div className="absolute inset-0 rounded-full" style={{
              background: 'linear-gradient(90deg, #ef4444 0%, #f97316 25%, #a8a8b8 50%, #22c55e 75%, #ffd700 100%)'
            }} />
            {/* Beyaz gösterge */}
            <div
              className="absolute top-0 bottom-0 w-1 rounded-full bg-white shadow-lg"
              style={{ left: `calc(${barPct}% - 2px)` }}
            />
          </div>
          <div className="flex justify-between text-xs text-gk-silver mt-1">
            <span>💀 Haydut (-100)</span>
            <span>👑 Efsane (+100)</span>
          </div>
        </div>
      </div>

      {/* Reputasyon seviyeleri */}
      <div className="gk-panel mb-4">
        <h2 className="text-gk-silver text-xs font-bold mb-3 uppercase tracking-wider">İtibar Seviyeleri</h2>
        <div className="space-y-2">
          {REPUTATION_LEVELS.map((level) => {
            const isActive = reputation >= level.min && reputation <= level.max
            return (
              <div
                key={level.label}
                className={`flex items-center gap-3 p-2 rounded-xl transition-all ${
                  isActive ? 'bg-gk-surface border border-gk-gold/50' : ''
                }`}
              >
                <span className="text-xl flex-shrink-0">{level.icon}</span>
                <div className="flex-1">
                  <p className="text-sm font-bold" style={{ color: isActive ? level.color : '#a8a8b8' }}>
                    {level.label}
                  </p>
                  <p className="text-gk-silver text-xs">{level.min} - {level.max > 0 ? '+' : ''}{level.max}</p>
                </div>
                {isActive && <span className="text-gk-gold text-xs font-bold">← Şu An</span>}
              </div>
            )
          })}
        </div>
      </div>

      {/* Reputasyon etkileri */}
      <div className="gk-panel mb-4">
        <h2 className="text-gk-silver text-xs font-bold mb-3 uppercase tracking-wider">İtibar Etkileri</h2>
        <div className="space-y-2">
          {REP_EFFECTS.map((effect, i) => {
            const isActive = reputation >= effect.threshold
            return (
              <div key={i} className={`flex items-center gap-2 text-xs ${isActive ? '' : 'opacity-40'}`}>
                <span>{effect.positive ? '✅' : '❌'}</span>
                <span
                  style={{ color: isActive ? (effect.positive ? '#22c55e' : '#ef4444') : '#a8a8b8' }}
                >
                  {effect.label}
                </span>
                <span className="text-gk-border ml-auto">[{effect.threshold > 0 ? '+' : ''}{effect.threshold}]</span>
              </div>
            )
          })}
        </div>
      </div>

      {/* PvP özeti */}
      <div className="gk-panel mb-4">
        <h2 className="text-gk-silver text-xs font-bold mb-3 uppercase tracking-wider">PvP İstatistikleri</h2>
        <div className="grid grid-cols-3 gap-3 text-center">
          <div className="bg-gk-surface rounded-lg p-3">
            <p className="text-green-400 font-bold text-lg">{pvpWins}</p>
            <p className="text-gk-silver text-xs">Galibiyet</p>
          </div>
          <div className="bg-gk-surface rounded-lg p-3">
            <p className="text-red-400 font-bold text-lg">{pvpLosses}</p>
            <p className="text-gk-silver text-xs">Mağlubiyet</p>
          </div>
          <div className="bg-gk-surface rounded-lg p-3">
            <p className="text-gk-gold font-bold text-lg">
              {pvpWins + pvpLosses > 0 ? Math.round((pvpWins / (pvpWins + pvpLosses)) * 100) : 0}%
            </p>
            <p className="text-gk-silver text-xs">Galibiyet Oranı</p>
          </div>
        </div>
      </div>

      {/* Son savaşlar */}
      <div className="gk-panel">
        <h2 className="text-gk-silver text-xs font-bold mb-3 uppercase tracking-wider">Son PvP Savaşları</h2>
        <div className="space-y-2">
          {MOCK_RECENT_BATTLES.map((battle) => (
            <div key={battle.id} className="flex items-center justify-between bg-gk-surface rounded-lg p-3">
              <div className="flex items-center gap-2">
                <span className="text-lg">{battle.outcome === 'win' ? '🏆' : '💀'}</span>
                <div>
                  <p className="text-white text-sm font-bold">{battle.opponent}</p>
                  <p className="text-gk-silver text-xs">{timeAgo(battle.timestamp)}</p>
                </div>
              </div>
              <div className="text-right">
                <p className={`text-sm font-bold ${battle.goldChange > 0 ? 'text-gk-gold' : 'text-red-400'}`}>
                  {battle.goldChange > 0 ? '+' : ''}{formatNumber(battle.goldChange)} 💰
                </p>
                <p className={`text-xs ${battle.repChange >= 0 ? 'text-green-400' : 'text-orange-400'}`}>
                  İtibar: {battle.repChange > 0 ? '+' : ''}{battle.repChange}
                </p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </motion.div>
  )
}
