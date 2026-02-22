// =====================================================
// app/(game)/achievements/page.tsx - Başarımlar ekranı
// GDScript AchievementsScreen.gd'den dönüştürüldü
// =====================================================
'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { motion, AnimatePresence } from 'framer-motion'
import { usePlayerStore } from '@/store/playerStore'
import { formatNumber } from '@/lib/utils/mathUtils'

type CategoryType = 'all' | 'combat' | 'economy' | 'social' | 'exploration' | 'special'

const CATEGORIES: Array<{ id: CategoryType; label: string; icon: string }> = [
  { id: 'all', label: 'Tümü', icon: '🏅' },
  { id: 'combat', label: 'Savaş', icon: '⚔️' },
  { id: 'economy', label: 'Ekonomi', icon: '💰' },
  { id: 'social', label: 'Sosyal', icon: '👥' },
  { id: 'exploration', label: 'Keşif', icon: '🗺️' },
  { id: 'special', label: 'Özel', icon: '✨' },
]

interface Achievement {
  id: string
  name: string
  description: string
  icon: string
  category: CategoryType
  unlocked: boolean
  progress?: { current: number; target: number }
  reward?: { type: string; amount: number }
  rarity: 'common' | 'uncommon' | 'rare' | 'epic' | 'legendary'
  unlockedAt?: string
}

const RARITY_COLORS = {
  common: '#a8a8b8',
  uncommon: '#22c55e',
  rare: '#3b82f6',
  epic: '#8b5cf6',
  legendary: '#f59e0b',
}

const ACHIEVEMENTS: Achievement[] = [
  // Savaş
  { id: 'a1', name: 'İlk Kan', description: 'İlk PvP zaferini kazan.', icon: '⚔️', category: 'combat', unlocked: true, rarity: 'common', reward: { type: 'gold', amount: 500 }, unlockedAt: '2025-01-02' },
  { id: 'a2', name: 'Zindan Kaşifi', description: 'İlk zindanı tamamla.', icon: '🏰', category: 'combat', unlocked: true, rarity: 'common', reward: { type: 'xp', amount: 200 }, unlockedAt: '2025-01-01' },
  { id: 'a3', name: 'PvP Savaşçısı', description: '10 PvP savaşı kazan.', icon: '🏆', category: 'combat', unlocked: false, rarity: 'uncommon', reward: { type: 'gems', amount: 20 }, progress: { current: 3, target: 10 } },
  { id: 'a4', name: 'Zindan Ustası', description: '50 zindan tamamla.', icon: '⚡', category: 'combat', unlocked: false, rarity: 'rare', reward: { type: 'gems', amount: 100 }, progress: { current: 8, target: 50 } },
  { id: 'a5', name: 'Ejder Katili', description: 'Ejderha Yuvası\'nı tamamla.', icon: '🐉', category: 'combat', unlocked: false, rarity: 'legendary', reward: { type: 'gems', amount: 500 } },
  { id: 'a6', name: 'Gölge Şampiyonu', description: '100 PvP savaşı kazan.', icon: '👑', category: 'combat', unlocked: false, rarity: 'epic', reward: { type: 'gems', amount: 200 }, progress: { current: 3, target: 100 } },

  // Ekonomi
  { id: 'a7', name: 'İlk Kazanç', description: '1.000 altın kazan.', icon: '💰', category: 'economy', unlocked: true, rarity: 'common', reward: { type: 'gold', amount: 200 }, unlockedAt: '2025-01-01' },
  { id: 'a8', name: 'Zengin Tüccar', description: '100.000 altın biriktir.', icon: '🏦', category: 'economy', unlocked: false, rarity: 'rare', reward: { type: 'gems', amount: 50 }, progress: { current: 12450, target: 100000 } },
  { id: 'a9', name: 'Altın Kral', description: '1.000.000 altın kazan.', icon: '👑', category: 'economy', unlocked: false, rarity: 'legendary', reward: { type: 'title', amount: 0 } },
  { id: 'a10', name: 'Tesis Yöneticisi', description: '5 tesis aç.', icon: '🏭', category: 'economy', unlocked: false, rarity: 'uncommon', reward: { type: 'gems', amount: 30 }, progress: { current: 1, target: 5 } },

  // Sosyal
  { id: 'a11', name: 'Lonca Üyesi', description: 'Bir loncaya katıl.', icon: '🤝', category: 'social', unlocked: false, rarity: 'common', reward: { type: 'gold', amount: 1000 } },
  { id: 'a12', name: 'Lonca Komutanı', description: 'Komutan rütbesine eriş.', icon: '⚔️', category: 'social', unlocked: false, rarity: 'rare', reward: { type: 'gems', amount: 75 } },
  { id: 'a13', name: 'Lonca Liderliği', description: 'Kendi loncanı kur ve yönet.', icon: '🏰', category: 'social', unlocked: false, rarity: 'epic', reward: { type: 'gems', amount: 300 } },

  // Keşif
  { id: 'a14', name: 'Gezgin', description: '5 farklı bölgeyi ziyaret et.', icon: '🗺️', category: 'exploration', unlocked: true, rarity: 'common', reward: { type: 'xp', amount: 500 }, unlockedAt: '2025-01-03' },
  { id: 'a15', name: 'Büyük Kaşif', description: 'Tüm bölgeleri keşfet.', icon: '🌍', category: 'exploration', unlocked: false, rarity: 'epic', reward: { type: 'gems', amount: 150 }, progress: { current: 5, target: 12 } },

  // Özel
  { id: 'a16', name: 'Gölge Doğumlu', description: 'Oyuna ilk kez giriş yaptın!', icon: '🌑', category: 'special', unlocked: true, rarity: 'legendary', reward: { type: 'gems', amount: 50 }, unlockedAt: '2025-01-01' },
  { id: 'a17', name: 'Sezon 3 Savaşçısı', description: 'Sezon 3\'te aktif ol.', icon: '🏅', category: 'special', unlocked: true, rarity: 'rare', reward: { type: 'gold', amount: 5000 }, unlockedAt: '2025-02-01' },
]

export default function AchievementsPage() {
  const router = useRouter()
  const { level, pvpWins } = usePlayerStore((s) => ({ level: s.level, pvpWins: s.pvpWins }))

  const [activeCategory, setActiveCategory] = useState<CategoryType>('all')

  const filteredAchievements = ACHIEVEMENTS.filter((a) =>
    activeCategory === 'all' ? true : a.category === activeCategory
  )

  const unlockedCount = ACHIEVEMENTS.filter((a) => a.unlocked).length
  const totalCount = ACHIEVEMENTS.length

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

      {/* Başlık */}
      <div className="flex items-center gap-2 mb-4">
        <span className="text-3xl">🏅</span>
        <div>
          <h1 className="gk-title text-xl">Başarımlar</h1>
          <p className="text-gk-silver text-xs">{unlockedCount}/{totalCount} tamamlandı</p>
        </div>
        <div className="ml-auto">
          <div className="gk-badge bg-gk-gold/20 text-gk-gold font-bold">
            {Math.round((unlockedCount / totalCount) * 100)}%
          </div>
        </div>
      </div>

      {/* İlerleme barı */}
      <div className="gk-panel mb-4">
        <div className="h-3 bg-gk-surface rounded-full overflow-hidden mb-2">
          <motion.div
            initial={{ width: 0 }}
            animate={{ width: `${(unlockedCount / totalCount) * 100}%` }}
            transition={{ duration: 1 }}
            className="h-full rounded-full"
            style={{ background: 'linear-gradient(90deg, #d4a017, #f0c040)' }}
          />
        </div>
        <p className="text-gk-silver text-xs text-center">
          {unlockedCount} başarım kilidi açıldı, {totalCount - unlockedCount} kaldı
        </p>
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

      {/* Başarım listesi */}
      <AnimatePresence mode="wait">
        <motion.div
          key={activeCategory}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="space-y-3"
        >
          {filteredAchievements.map((achievement, i) => (
            <motion.div
              key={achievement.id}
              initial={{ opacity: 0, x: -10 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: i * 0.04 }}
              className={`gk-panel flex items-start gap-3 ${!achievement.unlocked ? 'opacity-50' : ''}`}
            >
              {/* İkon */}
              <div
                className={`w-12 h-12 rounded-xl flex items-center justify-center text-2xl flex-shrink-0 border-2 ${
                  achievement.unlocked ? '' : 'grayscale'
                }`}
                style={{
                  background: RARITY_COLORS[achievement.rarity] + '22',
                  borderColor: achievement.unlocked ? RARITY_COLORS[achievement.rarity] : '#2a2a3a',
                }}
              >
                {achievement.unlocked ? achievement.icon : '🔒'}
              </div>

              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 mb-0.5">
                  <h3 className={`font-bold text-sm ${achievement.unlocked ? 'text-white' : 'text-gk-silver'}`}>
                    {achievement.name}
                  </h3>
                  <span
                    className="text-xs font-bold"
                    style={{ color: RARITY_COLORS[achievement.rarity] }}
                  >
                    ●
                  </span>
                </div>
                <p className="text-gk-silver text-xs mb-2">{achievement.description}</p>

                {/* İlerleme */}
                {!achievement.unlocked && achievement.progress && (
                  <div>
                    <div className="flex justify-between text-xs mb-1">
                      <span className="text-gk-silver">{achievement.progress.current}/{achievement.progress.target}</span>
                      <span className="text-gk-gold">{Math.round((achievement.progress.current / achievement.progress.target) * 100)}%</span>
                    </div>
                    <div className="h-1.5 bg-gk-surface rounded-full overflow-hidden">
                      <div
                        className="h-full rounded-full bg-gk-gold"
                        style={{ width: `${(achievement.progress.current / achievement.progress.target) * 100}%` }}
                      />
                    </div>
                  </div>
                )}

                {achievement.unlocked && achievement.unlockedAt && (
                  <p className="text-green-400 text-xs">✅ {achievement.unlockedAt} tarihinde kazanıldı</p>
                )}
              </div>

              {/* Ödül */}
              {achievement.reward && (
                <div className="flex-shrink-0 text-right">
                  <div className="bg-gk-surface rounded-lg p-2 text-center">
                    <p className="text-gk-gold text-xs font-bold">
                      {achievement.reward.type === 'gold' ? `💰${formatNumber(achievement.reward.amount)}` :
                       achievement.reward.type === 'gems' ? `💎${achievement.reward.amount}` :
                       achievement.reward.type === 'xp' ? `⭐${achievement.reward.amount}` :
                       '🏷️ Unvan'}
                    </p>
                    <p className="text-gk-silver text-xs">Ödül</p>
                  </div>
                </div>
              )}
            </motion.div>
          ))}
        </motion.div>
      </AnimatePresence>
    </motion.div>
  )
}
