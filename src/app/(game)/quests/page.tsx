// =====================================================
// app/(game)/quests/page.tsx - Görevler ekranı
// GDScript QuestScreen.gd'den dönüştürüldü
// =====================================================
'use client'

import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { usePlayerStore } from '@/store/playerStore'
import { formatNumber } from '@/lib/utils/mathUtils'
import { Modal, InfoModal } from '@/components/ui/Modal'
import {
  QUEST_DIFFICULTY_NAMES,
  QUEST_TYPE_NAMES,
  type QuestData,
  type QuestType,
} from '@/types/quest'

const DIFFICULTY_COLORS: Record<string, string> = {
  easy: '#22c55e',
  medium: '#f59e0b',
  hard: '#f97316',
  dungeon: '#ef4444',
}

const TYPE_COLORS: Record<QuestType, string> = {
  daily: '#3b82f6',
  weekly: '#8b5cf6',
  story: '#f59e0b',
  guild: '#22c55e',
  event: '#ef4444',
}

const MOCK_QUESTS: QuestData[] = [
  {
    id: 'q1', name: 'İlk Adım', description: 'Başlangıç Mağarası\'nı tamamla.', type: 'daily',
    difficulty: 'easy', status: 'available', energy_cost: 5, level_requirement: 1,
    objectives: [{ id: 'o1', description: 'Zindan tamamla', target_type: 'dungeon', required_amount: 1, current_amount: 0, completed: false }],
    rewards: { gold: 200, experience: 100 }, repeatable: true, cooldown_hours: 24,
  },
  {
    id: 'q2', name: 'Haydut Avcısı', description: 'Haydut Kampı\'nı 3 kez tamamla.', type: 'daily',
    difficulty: 'medium', status: 'available', energy_cost: 10, level_requirement: 5,
    objectives: [{ id: 'o2', description: 'Haydut Kampı tamamla', target_type: 'dungeon', required_amount: 3, current_amount: 1, completed: false }],
    rewards: { gold: 800, experience: 400, gems: 5 }, repeatable: true, cooldown_hours: 24,
  },
  {
    id: 'q3', name: 'PvP Ustası', description: 'Bu hafta 10 PvP savaşı kazan.', type: 'weekly',
    difficulty: 'hard', status: 'active', energy_cost: 0, level_requirement: 10,
    objectives: [{ id: 'o3', description: 'PvP savaşı kazan', target_type: 'pvp_win', required_amount: 10, current_amount: 4, completed: false }],
    rewards: { gold: 5000, experience: 2000, gems: 20, reputation: 10 }, repeatable: true, cooldown_hours: 168,
  },
  {
    id: 'q4', name: 'Karanlık Geçmiş', description: 'Krallığın karanlık sırlarını keşfet.', type: 'story',
    difficulty: 'medium', status: 'available', energy_cost: 15, level_requirement: 8,
    objectives: [
      { id: 'o4a', description: 'Karanlık Kale\'yi keşfet', target_type: 'location', required_amount: 1, current_amount: 0, completed: false },
      { id: 'o4b', description: 'İpucu bul', target_type: 'collect', required_amount: 3, current_amount: 0, completed: false },
    ],
    rewards: { gold: 1500, experience: 800, items: [{ item_id: 'dark_relic', quantity: 1 }] }, repeatable: false,
  },
  {
    id: 'q5', name: 'Lonca Görevi', description: 'Loncanın kaynaklarını topla.', type: 'guild',
    difficulty: 'easy', status: 'locked', energy_cost: 8, level_requirement: 5,
    objectives: [{ id: 'o5', description: 'Kaynak topla', target_type: 'collect', required_amount: 50, current_amount: 0, completed: false }],
    rewards: { gold: 500, experience: 250 }, repeatable: true, cooldown_hours: 48,
  },
  {
    id: 'q6', name: 'Ejder\'in Gölgesi', description: 'Ejderha Yuvası\'na gir ve hayatta dön.', type: 'story',
    difficulty: 'dungeon', status: 'locked', energy_cost: 40, level_requirement: 25,
    objectives: [{ id: 'o6', description: 'Ejderha Yuvası\'nı tamamla', target_type: 'dungeon', required_amount: 1, current_amount: 0, completed: false }],
    rewards: { gold: 15000, experience: 8000, gems: 50, reputation: 25 }, repeatable: false,
  },
]

const FILTER_TYPES: Array<QuestType | 'all'> = ['all', 'daily', 'weekly', 'story', 'guild']

export default function QuestsPage() {
  const { level, currentEnergy, addQuestToActive } = usePlayerStore((s) => ({
    level: s.level,
    currentEnergy: s.currentEnergy,
    addQuestToActive: s.addQuestToActive,
  }))

  const [activeFilter, setActiveFilter] = useState<QuestType | 'all'>('all')
  const [selectedQuest, setSelectedQuest] = useState<QuestData | null>(null)
  const [showDetail, setShowDetail] = useState(false)
  const [infoMessage, setInfoMessage] = useState('')
  const [showInfo, setShowInfo] = useState(false)

  const filteredQuests = MOCK_QUESTS.filter((q) =>
    activeFilter === 'all' ? true : q.type === activeFilter
  )

  const handleStart = (quest: QuestData) => {
    if (quest.status === 'locked') { setInfoMessage('Bu görevi başlatmak için gerekli koşulları sağlamalısınız.'); setShowInfo(true); return }
    if (level < quest.level_requirement) { setInfoMessage(`Bu görev için Seviye ${quest.level_requirement} gerekli.`); setShowInfo(true); return }
    if (currentEnergy < quest.energy_cost) { setInfoMessage(`Bu görev için ⚡${quest.energy_cost} enerji gerekli.`); setShowInfo(true); return }

    addQuestToActive({ ...quest, status: 'active', started_at: new Date().toISOString() })
    setShowDetail(false)
    setInfoMessage(`"${quest.name}" görevi başlatıldı!`)
    setShowInfo(true)
  }

  const statusIcon = (status: string) => {
    if (status === 'active') return '🔄'
    if (status === 'completed') return '✅'
    if (status === 'locked') return '🔒'
    return '📜'
  }

  return (
    <>
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.3 }}
        className="px-4 pt-4 pb-2 max-w-[480px] mx-auto"
      >
        {/* Başlık */}
        <div className="flex items-center gap-2 mb-4">
          <span className="text-3xl">📜</span>
          <div>
            <h1 className="gk-title text-xl">Görevler</h1>
            <p className="text-gk-silver text-xs">Maceralarınızı tamamlayın</p>
          </div>
          <div className="ml-auto">
            <span className="text-gk-energy text-sm font-bold">⚡ {currentEnergy}</span>
          </div>
        </div>

        {/* Filtreler */}
        <div className="flex gap-2 mb-4 overflow-x-auto pb-1">
          {FILTER_TYPES.map((f) => (
            <button
              key={f}
              onClick={() => setActiveFilter(f)}
              className={`whitespace-nowrap px-3 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                activeFilter === f ? 'bg-gk-gold text-gk-darker' : 'bg-gk-surface text-gk-silver hover:text-white'
              }`}
            >
              {f === 'all' ? '📋 Tümü' : QUEST_TYPE_NAMES[f]}
            </button>
          ))}
        </div>

        {/* Görev listesi */}
        <div className="space-y-3">
          {filteredQuests.map((quest, i) => {
            const objProgress = quest.objectives[0]
            const pct = objProgress ? (objProgress.current_amount / objProgress.required_amount) * 100 : 0

            return (
              <motion.div
                key={quest.id}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: i * 0.06 }}
                onClick={() => { setSelectedQuest(quest); setShowDetail(true) }}
                className={`gk-panel cursor-pointer active:scale-98 transition-transform ${
                  quest.status === 'locked' ? 'opacity-60' : ''
                }`}
              >
                <div className="flex items-start justify-between mb-2">
                  <div className="flex items-center gap-2">
                    <span className="text-xl">{statusIcon(quest.status)}</span>
                    <div>
                      <h3 className="text-white font-bold text-sm">{quest.name}</h3>
                      <div className="flex gap-2 mt-0.5">
                        <span
                          className="text-xs font-bold"
                          style={{ color: TYPE_COLORS[quest.type] }}
                        >
                          {QUEST_TYPE_NAMES[quest.type]}
                        </span>
                        <span className="text-xs" style={{ color: DIFFICULTY_COLORS[quest.difficulty] }}>
                          • {QUEST_DIFFICULTY_NAMES[quest.difficulty]}
                        </span>
                      </div>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="text-gk-gold text-xs font-bold">💰 {formatNumber(quest.rewards.gold ?? 0)}</p>
                    {quest.rewards.gems && (
                      <p className="text-blue-400 text-xs">💎 {quest.rewards.gems}</p>
                    )}
                  </div>
                </div>

                <p className="text-gk-silver text-xs mb-3">{quest.description}</p>

                {/* Görev ilerlemesi */}
                {quest.status === 'active' && objProgress && (
                  <div className="mb-3">
                    <div className="flex justify-between text-xs mb-1">
                      <span className="text-gk-silver">{objProgress.description}</span>
                      <span className="text-white font-bold">{objProgress.current_amount}/{objProgress.required_amount}</span>
                    </div>
                    <div className="h-2 bg-gk-surface rounded-full overflow-hidden">
                      <div
                        className="h-full rounded-full bg-gk-gold transition-all"
                        style={{ width: `${pct}%` }}
                      />
                    </div>
                  </div>
                )}

                <div className="flex items-center justify-between">
                  <div className="flex gap-2 text-xs text-gk-silver">
                    <span>⚡ {quest.energy_cost}</span>
                    {quest.level_requirement > 1 && <span>📊 Sv.{quest.level_requirement}</span>}
                  </div>
                  {quest.status === 'available' && (
                    <button
                      onClick={(e) => { e.stopPropagation(); handleStart(quest) }}
                      disabled={currentEnergy < quest.energy_cost || level < quest.level_requirement}
                      className="gk-btn-gold text-xs px-3 py-1.5"
                    >
                      ▶️ Başlat
                    </button>
                  )}
                  {quest.status === 'active' && (
                    <span className="text-blue-400 text-xs font-bold">Devam Ediyor</span>
                  )}
                  {quest.status === 'locked' && (
                    <span className="text-gk-silver text-xs">🔒 Kilitli</span>
                  )}
                </div>
              </motion.div>
            )
          })}
        </div>
      </motion.div>

      {/* Görev detay modalı */}
      {selectedQuest && (
        <Modal
          isOpen={showDetail}
          onClose={() => setShowDetail(false)}
          title={selectedQuest.name}
          size="lg"
        >
          <div className="space-y-4">
            <div className="flex gap-2">
              <span
                className="gk-badge text-xs"
                style={{ color: TYPE_COLORS[selectedQuest.type], background: TYPE_COLORS[selectedQuest.type] + '22' }}
              >
                {QUEST_TYPE_NAMES[selectedQuest.type]}
              </span>
              <span
                className="gk-badge text-xs"
                style={{ color: DIFFICULTY_COLORS[selectedQuest.difficulty], background: DIFFICULTY_COLORS[selectedQuest.difficulty] + '22' }}
              >
                {QUEST_DIFFICULTY_NAMES[selectedQuest.difficulty]}
              </span>
            </div>

            <p className="text-gk-silver text-sm">{selectedQuest.description}</p>

            <div>
              <p className="text-gk-silver text-xs font-bold mb-2 uppercase tracking-wider">Hedefler</p>
              <div className="space-y-2">
                {selectedQuest.objectives.map((obj) => (
                  <div key={obj.id} className="flex items-center gap-2 bg-gk-surface rounded-lg p-2">
                    <span>{obj.completed ? '✅' : '⭕'}</span>
                    <span className="text-gk-silver text-xs flex-1">{obj.description}</span>
                    <span className="text-white text-xs font-bold">{obj.current_amount}/{obj.required_amount}</span>
                  </div>
                ))}
              </div>
            </div>

            <div>
              <p className="text-gk-silver text-xs font-bold mb-2 uppercase tracking-wider">Ödüller</p>
              <div className="grid grid-cols-3 gap-2">
                {selectedQuest.rewards.gold && (
                  <div className="bg-gk-surface rounded-lg p-2 text-center">
                    <p className="text-gk-gold font-bold text-sm">💰 {formatNumber(selectedQuest.rewards.gold)}</p>
                    <p className="text-gk-silver text-xs">Altın</p>
                  </div>
                )}
                {selectedQuest.rewards.experience && (
                  <div className="bg-gk-surface rounded-lg p-2 text-center">
                    <p className="text-green-400 font-bold text-sm">⭐ {formatNumber(selectedQuest.rewards.experience)}</p>
                    <p className="text-gk-silver text-xs">XP</p>
                  </div>
                )}
                {selectedQuest.rewards.gems && (
                  <div className="bg-gk-surface rounded-lg p-2 text-center">
                    <p className="text-blue-400 font-bold text-sm">💎 {selectedQuest.rewards.gems}</p>
                    <p className="text-gk-silver text-xs">Elmas</p>
                  </div>
                )}
              </div>
            </div>

            <div className="flex gap-3">
              <button onClick={() => setShowDetail(false)} className="gk-btn-secondary flex-1">
                Kapat
              </button>
              {selectedQuest.status === 'available' && (
                <button
                  onClick={() => handleStart(selectedQuest)}
                  disabled={currentEnergy < selectedQuest.energy_cost || level < selectedQuest.level_requirement}
                  className="gk-btn-gold flex-1"
                >
                  ▶️ Başlat (⚡{selectedQuest.energy_cost})
                </button>
              )}
            </div>
          </div>
        </Modal>
      )}

      <InfoModal isOpen={showInfo} onClose={() => setShowInfo(false)} message={infoMessage} />
    </>
  )
}
