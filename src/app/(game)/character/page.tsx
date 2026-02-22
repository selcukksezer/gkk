// =====================================================
// app/(game)/character/page.tsx - Karakter ekranı
// GDScript CharacterScreen.gd'den dönüştürüldü
// =====================================================
'use client'

import { useRouter } from 'next/navigation'
import { motion } from 'framer-motion'
import { usePlayerStore } from '@/store/playerStore'
import { formatNumber } from '@/lib/utils/mathUtils'

function StatRow({ icon, label, value, color = 'text-white' }: { icon: string; label: string; value: number | string; color?: string }) {
  return (
    <div className="flex items-center justify-between py-2 border-b border-gk-border last:border-0">
      <div className="flex items-center gap-2">
        <span className="text-base">{icon}</span>
        <span className="text-gk-silver text-sm">{label}</span>
      </div>
      <span className={`font-bold text-sm ${color}`}>{typeof value === 'number' ? formatNumber(value) : value}</span>
    </div>
  )
}

function ResourceBar({ icon, label, value, max, color }: { icon: string; label: string; value: number; max: number; color: string }) {
  const pct = max > 0 ? Math.min((value / max) * 100, 100) : 0
  return (
    <div className="mb-3">
      <div className="flex justify-between text-xs mb-1">
        <span className="text-gk-silver">{icon} {label}</span>
        <span className="text-white font-bold">{value}/{max}</span>
      </div>
      <div className="h-2.5 bg-gk-surface rounded-full overflow-hidden">
        <motion.div
          initial={{ width: 0 }}
          animate={{ width: `${pct}%` }}
          transition={{ duration: 0.8, delay: 0.2 }}
          className="h-full rounded-full"
          style={{ background: color }}
        />
      </div>
    </div>
  )
}

const REPUTATION_THRESHOLDS = [
  { min: 80, label: 'Efsanevi Kahraman', color: '#ffd700', icon: '👑' },
  { min: 50, label: 'Büyük Kahraman', color: '#22c55e', icon: '🌟' },
  { min: 20, label: 'Kahraman', color: '#4ade80', icon: '⭐' },
  { min: -20, label: 'Vatandaş', color: '#a8a8b8', icon: '🧍' },
  { min: -50, label: 'Şüpheli', color: '#f97316', icon: '😈' },
  { min: -101, label: 'Haydut', color: '#ef4444', icon: '💀' },
]

function getReputationStatus(rep: number) {
  return REPUTATION_THRESHOLDS.find((t) => rep >= t.min) ?? REPUTATION_THRESHOLDS[REPUTATION_THRESHOLDS.length - 1]
}

export default function CharacterPage() {
  const router = useRouter()
  const {
    player, level, xp, nextLevelXp, gold, gems, currentEnergy, maxEnergy,
    tolerance, pvpWins, pvpLosses, pvpRating, inHospital, inPrison,
  } = usePlayerStore((s) => ({
    player: s.player,
    level: s.level,
    xp: s.xp,
    nextLevelXp: s.nextLevelXp,
    gold: s.gold,
    gems: s.gems,
    currentEnergy: s.currentEnergy,
    maxEnergy: s.maxEnergy,
    tolerance: s.tolerance,
    pvpWins: s.pvpWins,
    pvpLosses: s.pvpLosses,
    pvpRating: s.pvpRating,
    inHospital: s.inHospital,
    inPrison: s.inPrison,
  }))

  const reputation = player?.reputation ?? 0
  const repStatus = getReputationStatus(reputation)
  const xpPct = nextLevelXp > 0 ? (xp / nextLevelXp) * 100 : 0

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

      {/* Avatar + Temel Bilgi */}
      <div className="gk-panel text-center mb-4">
        <motion.div
          initial={{ scale: 0 }}
          animate={{ scale: 1 }}
          transition={{ type: 'spring', delay: 0.1 }}
          className="w-20 h-20 rounded-full bg-gk-surface border-2 border-gk-gold mx-auto mb-3 flex items-center justify-center text-4xl"
        >
          ⚔️
        </motion.div>
        <h1 className="text-white text-xl font-bold">
          {player?.display_name ?? player?.username ?? 'Oyuncu'}
        </h1>
        <div className="flex items-center justify-center gap-2 mt-1">
          <span style={{ color: repStatus.color }}>{repStatus.icon} {repStatus.label}</span>
        </div>

        {/* Durum rozeti */}
        {(inHospital || inPrison) && (
          <div className={`mt-2 inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-bold ${inHospital ? 'bg-yellow-900/40 text-yellow-400' : 'bg-red-900/40 text-red-400'}`}>
            {inHospital ? '🏥 Hastanede' : '👮 Cezaevinde'}
          </div>
        )}

        {/* Seviye ve XP */}
        <div className="mt-4">
          <div className="flex justify-between text-xs mb-1">
            <span className="text-gk-silver">Seviye {level}</span>
            <span className="text-gk-gold font-bold">{formatNumber(xp)} / {formatNumber(nextLevelXp)} XP</span>
          </div>
          <div className="h-3 bg-gk-surface rounded-full overflow-hidden">
            <motion.div
              initial={{ width: 0 }}
              animate={{ width: `${xpPct}%` }}
              transition={{ duration: 1, delay: 0.3 }}
              className="h-full rounded-full"
              style={{ background: 'linear-gradient(90deg, #22cc44, #44ff66)' }}
            />
          </div>
          <p className="text-gk-silver text-xs mt-1 text-right">
            Seviye {level + 1} için {formatNumber(nextLevelXp - xp)} XP daha
          </p>
        </div>
      </div>

      {/* Kaynaklar */}
      <div className="gk-panel mb-4">
        <h2 className="gk-title text-base mb-3">💎 Kaynaklar</h2>
        <ResourceBar icon="⚡" label="Enerji" value={currentEnergy} max={maxEnergy} color="linear-gradient(90deg, #0066aa, #00aaff)" />
        <ResourceBar icon="🔴" label="Tolerans" value={tolerance} max={100} color="linear-gradient(90deg, #cc4400, #ff6600)" />
        <div className="grid grid-cols-2 gap-3 mt-3">
          <div className="bg-gk-surface rounded-lg p-3 text-center">
            <p className="text-gk-gold font-bold text-lg">💰 {formatNumber(gold)}</p>
            <p className="text-gk-silver text-xs">Altın</p>
          </div>
          <div className="bg-gk-surface rounded-lg p-3 text-center">
            <p className="text-blue-400 font-bold text-lg">💎 {formatNumber(gems)}</p>
            <p className="text-gk-silver text-xs">Elmas</p>
          </div>
        </div>
      </div>

      {/* Savaş İstatistikleri */}
      <div className="gk-panel mb-4">
        <h2 className="gk-title text-base mb-3">⚔️ Savaş İstatistikleri</h2>
        <StatRow icon="⚔️" label="Saldırı" value={player?.attack ?? 0} color="text-red-400" />
        <StatRow icon="🛡️" label="Savunma" value={player?.defense ?? 0} color="text-blue-400" />
        <StatRow icon="💪" label="Güç" value={player?.power ?? 0} color="text-purple-400" />
        <StatRow icon="❤️" label="Can" value={player?.health ?? player?.max_health ?? 0} color="text-green-400" />
      </div>

      {/* PvP İstatistikleri */}
      <div className="gk-panel mb-4">
        <h2 className="gk-title text-base mb-3">🆚 PvP</h2>
        <div className="grid grid-cols-3 gap-2 text-center">
          <div className="bg-gk-surface rounded-lg p-2">
            <p className="text-green-400 font-bold">{pvpWins}</p>
            <p className="text-gk-silver text-xs">Galibiyet</p>
          </div>
          <div className="bg-gk-surface rounded-lg p-2">
            <p className="text-red-400 font-bold">{pvpLosses}</p>
            <p className="text-gk-silver text-xs">Mağlubiyet</p>
          </div>
          <div className="bg-gk-surface rounded-lg p-2">
            <p className="text-gk-gold font-bold">{formatNumber(pvpRating)}</p>
            <p className="text-gk-silver text-xs">ELO</p>
          </div>
        </div>
      </div>

      {/* Reputasyon */}
      <div className="gk-panel mb-4">
        <h2 className="gk-title text-base mb-3">🏅 İtibar</h2>
        <div className="flex items-center justify-between mb-2">
          <span className="text-gk-silver text-sm">İtibar Puanı</span>
          <span className="font-bold" style={{ color: repStatus.color }}>
            {reputation > 0 ? '+' : ''}{reputation}
          </span>
        </div>
        <div className="h-3 bg-gk-surface rounded-full overflow-hidden mb-2">
          <div
            className="h-full rounded-full transition-all"
            style={{
              width: `${((reputation + 100) / 200) * 100}%`,
              background: repStatus.color,
            }}
          />
        </div>
        <div className="flex justify-between text-xs text-gk-silver">
          <span>Haydut (-100)</span>
          <span>{repStatus.icon} {repStatus.label}</span>
          <span>Efsane (+100)</span>
        </div>
      </div>

      {/* Ekipman özeti */}
      <div className="gk-panel">
        <div className="flex items-center justify-between mb-3">
          <h2 className="gk-title text-base">🗡️ Ekipman</h2>
          <button onClick={() => router.push('/equipment')} className="text-gk-gold text-sm">
            Görüntüle →
          </button>
        </div>
        <div className="grid grid-cols-5 gap-2">
          {['🪖', '👕', '👖', '🧤', '👟', '🗡️', '🛡️', '💍', '💍', '📿'].map((emoji, i) => (
            <div
              key={i}
              className="aspect-square bg-gk-surface border border-gk-border rounded-lg flex items-center justify-center text-xl opacity-40"
            >
              {emoji}
            </div>
          ))}
        </div>
        <p className="text-gk-silver text-xs text-center mt-2">Ekipman slotları boş</p>
      </div>
    </motion.div>
  )
}
