// =====================================================
// app/(game)/leaderboard/page.tsx - Sıralama tablosu
// GDScript LeaderboardScreen.gd'den dönüştürüldü
// =====================================================
'use client'

import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { usePlayerStore } from '@/store/playerStore'
import { formatNumber } from '@/lib/utils/mathUtils'

type CategoryType = 'wealth' | 'pvp' | 'quest' | 'economy' | 'guild'

const CATEGORIES: Array<{ id: CategoryType; label: string; icon: string }> = [
  { id: 'wealth', label: 'Zenginlik', icon: '💰' },
  { id: 'pvp', label: 'PvP', icon: '⚔️' },
  { id: 'quest', label: 'Görev', icon: '📜' },
  { id: 'economy', label: 'Ekonomi', icon: '🏭' },
  { id: 'guild', label: 'Lonca', icon: '🏰' },
]

interface LeaderboardEntry {
  rank: number
  username: string
  displayName: string
  value: number
  extra?: string
  isPlayer?: boolean
}

const MOCK_DATA: Record<CategoryType, LeaderboardEntry[]> = {
  wealth: [
    { rank: 1, username: 'altinKral', displayName: 'Altın Kral', value: 9_850_000, extra: '💰' },
    { rank: 2, username: 'hazineCi', displayName: 'Hazine Ci', value: 7_200_000, extra: '💰' },
    { rank: 3, username: 'servetliSir', displayName: 'Servetli Sir', value: 5_400_000, extra: '💰' },
    { rank: 4, username: 'zenginEfendi', displayName: 'Zengin Efendi', value: 4_100_000, extra: '💰' },
    { rank: 5, username: 'ticaretKrali', displayName: 'Ticaret Kralı', value: 3_250_000, extra: '💰' },
    { rank: 6, username: 'bakırTacir', displayName: 'Bakır Tacir', value: 2_600_000, extra: '💰' },
    { rank: 7, username: 'gumusEfendi', displayName: 'Gümüş Efendi', value: 1_980_000, extra: '💰' },
    { rank: 8, username: 'bronzKral', displayName: 'Bronz Kral', value: 1_450_000, extra: '💰' },
    { rank: 9, username: 'demirTacir', displayName: 'Demir Tacir', value: 1_100_000, extra: '💰' },
    { rank: 10, username: 'basitTuccar', displayName: 'Basit Tüccar', value: 820_000, extra: '💰' },
  ],
  pvp: [
    { rank: 1, username: 'karanlıkŞövalye', displayName: 'Karanlık Şövalye', value: 2450, extra: 'ELO' },
    { rank: 2, username: 'gölgeKatil', displayName: 'Gölge Katil', value: 2300, extra: 'ELO' },
    { rank: 3, username: 'demirKral', displayName: 'Demir Kral', value: 2180, extra: 'ELO' },
    { rank: 4, username: 'kanEfendisi', displayName: 'Kan Efendisi', value: 2050, extra: 'ELO' },
    { rank: 5, username: 'zafersever', displayName: 'Zafer Sever', value: 1980, extra: 'ELO' },
    { rank: 6, username: 'savaşUstası', displayName: 'Savaş Ustası', value: 1870, extra: 'ELO' },
    { rank: 7, username: 'acımasız', displayName: 'Acımasız', value: 1790, extra: 'ELO' },
    { rank: 8, username: 'silahşor', displayName: 'Silahşor', value: 1720, extra: 'ELO' },
    { rank: 9, username: 'kahramanKan', displayName: 'Kahraman Kan', value: 1660, extra: 'ELO' },
    { rank: 10, username: 'savaşci', displayName: 'Savaşçı', value: 1590, extra: 'ELO' },
  ],
  quest: [
    { rank: 1, username: 'görevMaster', displayName: 'Görev Master', value: 1240, extra: 'görev' },
    { rank: 2, username: 'maceraPer', displayName: 'Maceraperest', value: 980, extra: 'görev' },
    { rank: 3, username: 'dedektif', displayName: 'Dedektif', value: 870, extra: 'görev' },
    { rank: 4, username: 'görevKıral', displayName: 'Görev Kıralı', value: 760, extra: 'görev' },
    { rank: 5, username: 'kahramanYol', displayName: 'Kahraman Yolcu', value: 650, extra: 'görev' },
    { rank: 6, username: 'izciMaster', displayName: 'İzci Master', value: 540, extra: 'görev' },
    { rank: 7, username: 'yolcuSon', displayName: 'Son Yolcu', value: 430, extra: 'görev' },
    { rank: 8, username: 'görevci', displayName: 'Görevci', value: 340, extra: 'görev' },
    { rank: 9, username: 'maceraci', displayName: 'Maceraci', value: 250, extra: 'görev' },
    { rank: 10, username: 'yeniGörev', displayName: 'Yeni Görevli', value: 180, extra: 'görev' },
  ],
  economy: [
    { rank: 1, username: 'ticaretKral', displayName: 'Ticaret Kral', value: 580_000, extra: 'üretim' },
    { rank: 2, username: 'fabrikaEfendi', displayName: 'Fabrika Efendi', value: 430_000, extra: 'üretim' },
    { rank: 3, username: 'imalatçı', displayName: 'İmalatçı', value: 320_000, extra: 'üretim' },
    { rank: 4, username: 'üretici', displayName: 'Üretici', value: 240_000, extra: 'üretim' },
    { rank: 5, username: 'madenci', displayName: 'Madenci', value: 180_000, extra: 'üretim' },
    { rank: 6, username: 'çiftçi', displayName: 'Çiftçi', value: 140_000, extra: 'üretim' },
    { rank: 7, username: 'sanayici', displayName: 'Sanayici', value: 110_000, extra: 'üretim' },
    { rank: 8, username: 'emekçi', displayName: 'Emekçi', value: 85_000, extra: 'üretim' },
    { rank: 9, username: 'zanaatkar', displayName: 'Zanaatkâr', value: 64_000, extra: 'üretim' },
    { rank: 10, username: 'isci', displayName: 'İşçi', value: 45_000, extra: 'üretim' },
  ],
  guild: [
    { rank: 1, username: 'GölgeKrallar', displayName: 'Gölge Krallar', value: 98_500, extra: 'puan' },
    { rank: 2, username: 'DemirKalkan', displayName: 'Demir Kalkan', value: 84_200, extra: 'puan' },
    { rank: 3, username: 'KanSavaşçılar', displayName: 'Kan Savaşçılar', value: 71_800, extra: 'puan' },
    { rank: 4, username: 'AltınOrdu', displayName: 'Altın Ordu', value: 60_100, extra: 'puan' },
    { rank: 5, username: 'KaranlıkAy', displayName: 'Karanlık Ay', value: 48_900, extra: 'puan' },
    { rank: 6, username: 'MorGece', displayName: 'Mor Gece', value: 38_700, extra: 'puan' },
    { rank: 7, username: 'YıldızKılıç', displayName: 'Yıldız Kılıç', value: 29_400, extra: 'puan' },
    { rank: 8, username: 'BuzKalkan', displayName: 'Buz Kalkan', value: 21_200, extra: 'puan' },
    { rank: 9, username: 'AteşSürüsü', displayName: 'Ateş Sürüsü', value: 14_800, extra: 'puan' },
    { rank: 10, username: 'GenellerOrd', displayName: 'Gönüllüler', value: 9_500, extra: 'puan' },
  ],
}

const RANK_COLORS = ['#ffd700', '#c0c0c0', '#cd7f32']
const RANK_EMOJIS = ['🥇', '🥈', '🥉']

export default function LeaderboardPage() {
  const { player, pvpRating, gold, pvpWins } = usePlayerStore((s) => ({
    player: s.player,
    pvpRating: s.pvpRating,
    gold: s.gold,
    pvpWins: s.pvpWins,
  }))

  const [activeCategory, setActiveCategory] = useState<CategoryType>('wealth')
  const leaderboardData = MOCK_DATA[activeCategory]

  const getPlayerRank = (): number => {
    if (activeCategory === 'pvp') {
      const below = leaderboardData.filter((e) => e.value > pvpRating).length
      return below + 1
    }
    return 42 // Mock rank for player
  }

  const playerRank = getPlayerRank()

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
      className="px-4 pt-4 pb-2 max-w-[480px] mx-auto"
    >
      {/* Başlık */}
      <div className="flex items-center gap-2 mb-4">
        <span className="text-3xl">🏆</span>
        <div>
          <h1 className="gk-title text-xl">Sıralama</h1>
          <p className="text-gk-silver text-xs">En iyi oyuncular</p>
        </div>
        <div className="ml-auto gk-badge bg-gk-gold/20 text-gk-gold">
          #{playerRank} sırada
        </div>
      </div>

      {/* Kategori seçimi */}
      <div className="flex gap-2 mb-4 overflow-x-auto pb-1">
        {CATEGORIES.map((cat) => (
          <button
            key={cat.id}
            onClick={() => setActiveCategory(cat.id)}
            className={`whitespace-nowrap flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-semibold transition-all ${
              activeCategory === cat.id ? 'bg-gk-gold text-gk-darker' : 'bg-gk-surface text-gk-silver hover:text-white'
            }`}
          >
            {cat.icon} {cat.label}
          </button>
        ))}
      </div>

      {/* Top 3 */}
      <div className="flex justify-center gap-4 mb-6">
        {[1, 0, 2].map((rankIdx) => {
          const entry = leaderboardData[rankIdx]
          if (!entry) return null
          const isTop = rankIdx === 0
          return (
            <motion.div
              key={entry.rank}
              initial={{ opacity: 0, y: isTop ? -20 : 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.1 * rankIdx }}
              className={`flex flex-col items-center ${isTop ? 'order-2 -mt-4' : rankIdx === 1 ? 'order-1' : 'order-3'}`}
            >
              <div
                className={`rounded-full flex items-center justify-center font-bold text-gk-darker mb-1 ${isTop ? 'w-16 h-16 text-2xl border-4' : 'w-12 h-12 text-lg border-2'}`}
                style={{ background: RANK_COLORS[rankIdx], borderColor: RANK_COLORS[rankIdx] + '88' }}
              >
                {RANK_EMOJIS[rankIdx]}
              </div>
              <p className="text-white text-xs font-bold text-center max-w-[70px] truncate">{entry.displayName}</p>
              <p className="text-gk-gold text-xs">{formatNumber(entry.value)}</p>
            </motion.div>
          )
        })}
      </div>

      {/* Liste */}
      <AnimatePresence mode="wait">
        <motion.div
          key={activeCategory}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="space-y-2"
        >
          {leaderboardData.map((entry, i) => (
            <motion.div
              key={entry.rank}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: i * 0.04 }}
              className={`flex items-center gap-3 rounded-xl p-3 border ${
                entry.rank <= 3
                  ? 'bg-gk-panel border-gk-gold/30'
                  : 'bg-gk-surface border-gk-border'
              }`}
            >
              {/* Sıra */}
              <div
                className="w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm flex-shrink-0"
                style={{
                  background: entry.rank <= 3 ? RANK_COLORS[entry.rank - 1] + '33' : 'transparent',
                  color: entry.rank <= 3 ? RANK_COLORS[entry.rank - 1] : '#a8a8b8',
                  border: `1px solid ${entry.rank <= 3 ? RANK_COLORS[entry.rank - 1] : '#2a2a3a'}`,
                }}
              >
                {entry.rank <= 3 ? RANK_EMOJIS[entry.rank - 1] : entry.rank}
              </div>

              {/* Avatar */}
              <div className="w-8 h-8 rounded-full bg-gk-panel border border-gk-border flex items-center justify-center text-sm flex-shrink-0">
                ⚔️
              </div>

              {/* İsim */}
              <div className="flex-1 min-w-0">
                <p className={`font-bold text-sm truncate ${entry.isPlayer ? 'text-gk-gold' : 'text-white'}`}>
                  {entry.displayName} {entry.isPlayer ? '(Sen)' : ''}
                </p>
              </div>

              {/* Değer */}
              <div className="text-right flex-shrink-0">
                <p className="text-gk-gold font-bold text-sm">{formatNumber(entry.value)}</p>
                {entry.extra && <p className="text-gk-silver text-xs">{entry.extra}</p>}
              </div>
            </motion.div>
          ))}

          {/* Oyuncunun sırası */}
          {playerRank > 10 && (
            <>
              <div className="text-center text-gk-silver text-xs py-1">• • •</div>
              <div className="flex items-center gap-3 rounded-xl p-3 border-2 border-gk-gold/50 bg-gk-gold/10">
                <div className="w-8 h-8 rounded-full bg-gk-gold/20 border border-gk-gold flex items-center justify-center font-bold text-sm text-gk-gold">
                  {playerRank}
                </div>
                <div className="w-8 h-8 rounded-full bg-gk-panel border border-gk-border flex items-center justify-center text-sm">
                  ⚔️
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-bold text-sm text-gk-gold truncate">
                    {player?.display_name ?? 'Sen'}
                  </p>
                </div>
                <div className="text-right">
                  <p className="text-gk-gold font-bold text-sm">
                    {activeCategory === 'pvp' ? formatNumber(pvpRating) : formatNumber(gold)}
                  </p>
                </div>
              </div>
            </>
          )}
        </motion.div>
      </AnimatePresence>
    </motion.div>
  )
}
