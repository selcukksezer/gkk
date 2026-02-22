// =====================================================
// app/(game)/profile/page.tsx - Profil ekranı
// GDScript ProfileScreen.gd'den dönüştürüldü
// =====================================================
'use client'

import { useRouter } from 'next/navigation'
import { motion } from 'framer-motion'
import { usePlayerStore } from '@/store/playerStore'
import { formatNumber } from '@/lib/utils/mathUtils'

const TITLES = [
  { minLevel: 1, title: 'Acemi Kahraman', icon: '🌱' },
  { minLevel: 5, title: 'Cesur Savaşçı', icon: '⚔️' },
  { minLevel: 10, title: 'Deneyimli Asker', icon: '🛡️' },
  { minLevel: 15, title: 'Şövalye', icon: '🏰' },
  { minLevel: 20, title: 'Büyük Şövalye', icon: '👑' },
  { minLevel: 30, title: 'Efsanevi Kahraman', icon: '🌟' },
]

function getTitle(level: number) {
  let result = TITLES[0]
  for (const t of TITLES) {
    if (level >= t.minLevel) result = t
  }
  return result
}

const BADGES = [
  { id: 'first_dungeon', icon: '🏰', label: 'İlk Zindan', desc: 'İlk zindanı tamamla', unlocked: true },
  { id: 'pvp_first', icon: '⚔️', label: 'İlk Kan', desc: 'İlk PvP zaferini kazan', unlocked: true },
  { id: 'wealth', icon: '💰', label: 'Zengin', desc: '10.000 altın biriktir', unlocked: false },
  { id: 'guild_join', icon: '🏰', label: 'Lonca Üyesi', desc: 'Bir loncaya katıl', unlocked: false },
  { id: 'dragon', icon: '🐉', label: 'Ejder Avcısı', desc: 'Ejderha Yuvası\'nı tamamla', unlocked: false },
  { id: 'veteran', icon: '🌟', label: 'Veteran', desc: '100 PvP savaşı tamamla', unlocked: false },
]

export default function ProfilePage() {
  const router = useRouter()
  const { player, level, xp, nextLevelXp, gold, gems, pvpWins, pvpLosses, pvpRating, activeQuests } = usePlayerStore((s) => ({
    player: s.player,
    level: s.level,
    xp: s.xp,
    nextLevelXp: s.nextLevelXp,
    gold: s.gold,
    gems: s.gems,
    pvpWins: s.pvpWins,
    pvpLosses: s.pvpLosses,
    pvpRating: s.pvpRating,
    activeQuests: s.activeQuests,
  }))

  const title = getTitle(level)
  const xpPct = nextLevelXp > 0 ? (xp / nextLevelXp) * 100 : 0
  const totalPvP = pvpWins + pvpLosses
  const winRate = totalPvP > 0 ? Math.round((pvpWins / totalPvP) * 100) : 0

  const joinDate = player?.created_at
    ? new Date(player.created_at).toLocaleDateString('tr-TR', { year: 'numeric', month: 'long', day: 'numeric' })
    : 'Bilinmiyor'

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

      {/* Avatar ve temel bilgi */}
      <div className="gk-panel text-center mb-4 relative overflow-hidden">
        {/* Dekoratif arka plan */}
        <div className="absolute inset-0 opacity-5 bg-gradient-to-b from-gk-gold to-transparent" />

        <motion.div
          initial={{ scale: 0, rotate: -180 }}
          animate={{ scale: 1, rotate: 0 }}
          transition={{ type: 'spring', delay: 0.1 }}
          className="w-24 h-24 rounded-full bg-gk-surface border-4 border-gk-gold mx-auto mb-3 flex items-center justify-center text-5xl relative"
        >
          ⚔️
          <div className="absolute -bottom-1 -right-1 w-7 h-7 rounded-full bg-gk-darker border-2 border-gk-gold flex items-center justify-center text-sm">
            {title.icon}
          </div>
        </motion.div>

        <h1 className="text-white text-2xl font-bold">
          {player?.display_name ?? player?.username ?? 'Oyuncu'}
        </h1>
        <p className="text-gk-gold text-sm mt-1">{title.icon} {title.title}</p>
        <p className="text-gk-silver text-xs mt-1">@{player?.username ?? 'oyuncu'}</p>
        <p className="text-gk-silver text-xs mt-0.5">Katılım: {joinDate}</p>

        {/* XP barı */}
        <div className="mt-4 px-4">
          <div className="flex justify-between text-xs mb-1">
            <span className="text-gk-silver">Seviye {level}</span>
            <span className="text-gk-gold">{Math.round(xpPct)}%</span>
          </div>
          <div className="h-2 bg-gk-surface rounded-full overflow-hidden">
            <motion.div
              initial={{ width: 0 }}
              animate={{ width: `${xpPct}%` }}
              transition={{ duration: 1, delay: 0.4 }}
              className="h-full rounded-full"
              style={{ background: 'linear-gradient(90deg, #22cc44, #44ff66)' }}
            />
          </div>
        </div>
      </div>

      {/* İstatistikler özeti */}
      <div className="grid grid-cols-3 gap-3 mb-4">
        {[
          { icon: '💰', label: 'Altın', value: formatNumber(gold), color: 'text-gk-gold' },
          { icon: '💎', label: 'Elmas', value: formatNumber(gems), color: 'text-blue-400' },
          { icon: '⭐', label: 'PvP ELO', value: formatNumber(pvpRating), color: 'text-purple-400' },
        ].map((stat) => (
          <div key={stat.label} className="gk-panel text-center py-3">
            <p className="text-lg">{stat.icon}</p>
            <p className={`font-bold text-sm ${stat.color}`}>{stat.value}</p>
            <p className="text-gk-silver text-xs">{stat.label}</p>
          </div>
        ))}
      </div>

      {/* PvP İstatistikleri */}
      <div className="gk-panel mb-4">
        <h2 className="gk-title text-base mb-3">🆚 PvP Özeti</h2>
        <div className="grid grid-cols-4 gap-2 text-center">
          {[
            { label: 'Galibiyet', value: pvpWins, color: 'text-green-400' },
            { label: 'Mağlubiyet', value: pvpLosses, color: 'text-red-400' },
            { label: 'Toplam', value: totalPvP, color: 'text-white' },
            { label: 'Oran', value: `${winRate}%`, color: 'text-gk-gold' },
          ].map((s) => (
            <div key={s.label} className="bg-gk-surface rounded-lg p-2">
              <p className={`font-bold text-sm ${s.color}`}>{s.value}</p>
              <p className="text-gk-silver text-xs">{s.label}</p>
            </div>
          ))}
        </div>
      </div>

      {/* Aktif görevler */}
      <div className="gk-panel mb-4">
        <div className="flex items-center justify-between mb-3">
          <h2 className="gk-title text-base">📜 Aktif Görevler</h2>
          <button onClick={() => router.push('/quests')} className="text-gk-gold text-sm">
            Hepsini gör →
          </button>
        </div>
        {activeQuests.length === 0 ? (
          <p className="text-gk-silver text-sm text-center py-4">Aktif görev yok</p>
        ) : (
          <div className="space-y-2">
            {activeQuests.slice(0, 3).map((q) => (
              <div key={q.id} className="flex items-center gap-2 bg-gk-surface rounded-lg p-2">
                <span className="text-base">📜</span>
                <span className="text-white text-sm flex-1">{q.name}</span>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Rozetler */}
      <div className="gk-panel">
        <h2 className="gk-title text-base mb-3">🏅 Rozetler</h2>
        <div className="grid grid-cols-3 gap-3">
          {BADGES.map((badge) => (
            <div
              key={badge.id}
              className={`text-center p-3 rounded-xl border transition-all ${
                badge.unlocked
                  ? 'bg-gk-surface border-gk-gold'
                  : 'bg-gk-surface/50 border-gk-border opacity-40'
              }`}
            >
              <div className="text-2xl mb-1">{badge.icon}</div>
              <p className="text-white text-xs font-bold">{badge.label}</p>
              <p className="text-gk-silver text-xs mt-0.5">{badge.desc}</p>
            </div>
          ))}
        </div>
      </div>
    </motion.div>
  )
}
