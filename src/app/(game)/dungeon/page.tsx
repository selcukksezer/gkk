// =====================================================
// app/(game)/dungeon/page.tsx - Zindan seçim ekranı
// GDScript DungeonScreen.gd'den dönüştürüldü
// =====================================================
'use client'

import { useState, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import { motion, AnimatePresence } from 'framer-motion'
import { usePlayerStore } from '@/store/playerStore'
import { formatNumber } from '@/lib/utils/mathUtils'
import { Modal, ConfirmModal, ErrorModal } from '@/components/ui/Modal'
import LoadingSpinner from '@/components/ui/LoadingSpinner'
import {
  MOCK_DUNGEONS,
  DUNGEON_DIFFICULTY_COLORS,
  DUNGEON_DIFFICULTY_NAMES,
  type DungeonDefinition,
} from '@/types/dungeon'
import { startDungeon, calculateSuccessRate } from '@/lib/managers/dungeonManager'

type TabType = 'solo' | 'group'

const DANGER_LABELS = ['Güvenli', 'Az Tehlikeli', 'Tehlikeli', 'Çok Tehlikeli', 'Ölümcül']

function getDangerLabel(dangerLevel: number): string {
  const idx = Math.min(Math.floor(dangerLevel / 25), 4)
  return DANGER_LABELS[idx]
}

function getDangerColor(dangerLevel: number): string {
  if (dangerLevel < 20) return '#22c55e'
  if (dangerLevel < 40) return '#f59e0b'
  if (dangerLevel < 60) return '#f97316'
  if (dangerLevel < 80) return '#ef4444'
  return '#dc2626'
}

export default function DungeonPage() {
  const router = useRouter()
  const { level, currentEnergy, inHospital, inPrison, player } = usePlayerStore((s) => ({
    level: s.level,
    currentEnergy: s.currentEnergy,
    inHospital: s.inHospital,
    inPrison: s.inPrison,
    player: s.player,
  }))

  const [activeTab, setActiveTab] = useState<TabType>('solo')
  const [selectedDungeon, setSelectedDungeon] = useState<DungeonDefinition | null>(null)
  const [showDetailModal, setShowDetailModal] = useState(false)
  const [showConfirmModal, setShowConfirmModal] = useState(false)
  const [errorMessage, setErrorMessage] = useState('')
  const [showError, setShowError] = useState(false)
  const [isLoading, setIsLoading] = useState(false)

  const solodungeons = MOCK_DUNGEONS.filter((d) => !d.is_group)
  const groupDungeons = MOCK_DUNGEONS.filter((d) => d.is_group)
  const displayedDungeons = activeTab === 'solo' ? solodungeons : groupDungeons

  const playerPower = player?.power ?? 100

  const handleDungeonPress = useCallback((dungeon: DungeonDefinition) => {
    setSelectedDungeon(dungeon)
    setShowDetailModal(true)
  }, [])

  const handleEnterDungeon = useCallback(() => {
    setShowDetailModal(false)
    setShowConfirmModal(true)
  }, [])

  const handleConfirmEnter = useCallback(async () => {
    if (!selectedDungeon) return
    setIsLoading(true)
    setShowConfirmModal(false)

    const result = await startDungeon(selectedDungeon)

    setIsLoading(false)
    if (result.success) {
      router.push(`/dungeon/battle?id=${selectedDungeon.id}`)
    } else {
      setErrorMessage(result.error ?? 'Zindan başlatılamadı')
      setShowError(true)
    }
  }, [selectedDungeon, router])

  const successRate = selectedDungeon
    ? calculateSuccessRate(selectedDungeon, playerPower, level)
    : 0

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
          <span className="text-3xl">⚔️</span>
          <div>
            <h1 className="gk-title text-xl">Zindan</h1>
            <p className="text-gk-silver text-xs">Macerana başla, ödülleri kazan</p>
          </div>
          <div className="ml-auto text-right">
            <span className="text-gk-energy text-sm font-bold">⚡ {currentEnergy}</span>
          </div>
        </div>

        {/* Durum uyarıları */}
        <AnimatePresence>
          {inHospital && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              className="gk-panel border-yellow-600 bg-yellow-900/20 mb-4 p-3"
            >
              <p className="text-yellow-400 text-sm text-center">
                🏥 Hastanede olduğunuz için zindana giremezsiniz
              </p>
            </motion.div>
          )}
          {inPrison && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              className="gk-panel border-red-600 bg-red-900/20 mb-4 p-3"
            >
              <p className="text-red-400 text-sm text-center">
                👮 Cezaevinde olduğunuz için zindana giremezsiniz
              </p>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Sekme seçimi */}
        <div className="flex bg-gk-surface rounded-xl p-1 mb-4 gap-1">
          {(['solo', 'group'] as TabType[]).map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`flex-1 py-2 rounded-lg text-sm font-semibold transition-all duration-200 ${
                activeTab === tab
                  ? 'bg-gk-gold text-gk-darker'
                  : 'text-gk-silver hover:text-white'
              }`}
            >
              {tab === 'solo' ? '🗡️ Solo' : '👥 Grup'}
            </button>
          ))}
        </div>

        {/* Zindan listesi */}
        <div className="space-y-3">
          {displayedDungeons.length === 0 && (
            <div className="gk-panel text-center py-8">
              <p className="text-gk-silver">Henüz grup zindanı yok</p>
            </div>
          )}
          {displayedDungeons.map((dungeon, i) => {
            const rate = calculateSuccessRate(dungeon, playerPower, level)
            const canEnter = currentEnergy >= dungeon.energy_cost && !inHospital && !inPrison
            const levelOk = level >= dungeon.required_level

            return (
              <motion.div
                key={dungeon.id}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: i * 0.06 }}
                className={`gk-panel cursor-pointer active:scale-98 transition-transform ${
                  !levelOk ? 'opacity-50' : ''
                }`}
                onClick={() => handleDungeonPress(dungeon)}
              >
                <div className="flex items-start justify-between mb-2">
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <span className="text-xl">{dungeon.icon ?? '🏰'}</span>
                      <h3 className="font-bold text-white text-base">{dungeon.name}</h3>
                      {dungeon.boss_name && <span className="text-xs text-red-400">👑 Boss</span>}
                    </div>
                    <p className="text-gk-silver text-xs mb-2">{dungeon.description}</p>
                    <div className="flex flex-wrap gap-2">
                      <span
                        className="gk-badge text-xs font-bold"
                        style={{ color: DUNGEON_DIFFICULTY_COLORS[dungeon.difficulty], background: `${DUNGEON_DIFFICULTY_COLORS[dungeon.difficulty]}22` }}
                      >
                        {DUNGEON_DIFFICULTY_NAMES[dungeon.difficulty]}
                      </span>
                      <span className="gk-badge bg-gk-surface text-gk-silver">
                        📍 {dungeon.zone}
                      </span>
                      {!levelOk && (
                        <span className="gk-badge bg-red-900/40 text-red-400">
                          🔒 Seviye {dungeon.required_level}
                        </span>
                      )}
                    </div>
                  </div>
                </div>

                <div className="grid grid-cols-3 gap-2 text-center mb-3">
                  <div className="bg-gk-surface rounded-lg p-2">
                    <p className="text-gk-energy text-xs font-bold">⚡ {dungeon.energy_cost}</p>
                    <p className="text-gk-silver text-xs">Enerji</p>
                  </div>
                  <div className="bg-gk-surface rounded-lg p-2">
                    <p className="text-gk-gold text-xs font-bold">
                      {formatNumber(dungeon.min_reward_gold)}-{formatNumber(dungeon.max_reward_gold)}
                    </p>
                    <p className="text-gk-silver text-xs">Altın</p>
                  </div>
                  <div className="bg-gk-surface rounded-lg p-2">
                    <p className="text-xs font-bold" style={{ color: getDangerColor(dungeon.danger_level) }}>
                      ⚠️ {dungeon.danger_level}%
                    </p>
                    <p className="text-gk-silver text-xs">Tehlike</p>
                  </div>
                </div>

                {/* Başarı oranı barı */}
                <div className="mb-3">
                  <div className="flex justify-between text-xs mb-1">
                    <span className="text-gk-silver">Başarı Şansı</span>
                    <span className="font-bold" style={{ color: rate >= 0.6 ? '#22c55e' : rate >= 0.4 ? '#f59e0b' : '#ef4444' }}>
                      {Math.round(rate * 100)}%
                    </span>
                  </div>
                  <div className="h-2 bg-gk-surface rounded-full overflow-hidden">
                    <div
                      className="h-full rounded-full transition-all duration-500"
                      style={{
                        width: `${rate * 100}%`,
                        background: rate >= 0.6 ? '#22c55e' : rate >= 0.4 ? '#f59e0b' : '#ef4444',
                      }}
                    />
                  </div>
                </div>

                <button
                  onClick={(e) => { e.stopPropagation(); handleDungeonPress(dungeon) }}
                  disabled={!canEnter || !levelOk}
                  className="gk-btn-gold w-full text-sm"
                >
                  {!levelOk ? `🔒 Seviye ${dungeon.required_level} Gerekli` : !canEnter ? '⚡ Yetersiz Enerji' : '⚔️ Gir'}
                </button>
              </motion.div>
            )
          })}
        </div>
      </motion.div>

      {/* Zindan Detay Modalı */}
      {selectedDungeon && (
        <Modal
          isOpen={showDetailModal}
          onClose={() => setShowDetailModal(false)}
          title={selectedDungeon.name}
          size="lg"
        >
          <div className="space-y-4">
            <p className="text-gk-silver text-sm">{selectedDungeon.description}</p>

            <div className="grid grid-cols-2 gap-3">
              <div className="bg-gk-surface rounded-lg p-3 text-center">
                <p className="text-gk-energy font-bold">⚡ {selectedDungeon.energy_cost}</p>
                <p className="text-gk-silver text-xs">Enerji Maliyeti</p>
              </div>
              <div className="bg-gk-surface rounded-lg p-3 text-center">
                <p className="text-gk-gold font-bold">
                  {formatNumber(selectedDungeon.min_reward_gold)}-{formatNumber(selectedDungeon.max_reward_gold)}
                </p>
                <p className="text-gk-silver text-xs">Altın Ödülü</p>
              </div>
              <div className="bg-gk-surface rounded-lg p-3 text-center">
                <p className="font-bold text-green-400">{Math.round(successRate * 100)}%</p>
                <p className="text-gk-silver text-xs">Başarı Şansı</p>
              </div>
              <div className="bg-gk-surface rounded-lg p-3 text-center">
                <p className="font-bold" style={{ color: getDangerColor(selectedDungeon.danger_level) }}>
                  {getDangerLabel(selectedDungeon.danger_level)}
                </p>
                <p className="text-gk-silver text-xs">Tehlike Seviyesi</p>
              </div>
            </div>

            {selectedDungeon.boss_name && (
              <div className="bg-red-900/20 border border-red-800 rounded-lg p-3">
                <p className="text-red-400 text-sm">
                  👑 <strong>Boss:</strong> {selectedDungeon.boss_name}
                </p>
              </div>
            )}

            {selectedDungeon.hospitalization_risk > 0 && (
              <div className="bg-yellow-900/20 border border-yellow-800 rounded-lg p-3">
                <p className="text-yellow-400 text-sm">
                  🏥 Hastanelik riski: <strong>{Math.round(selectedDungeon.hospitalization_risk * 100)}%</strong>
                </p>
              </div>
            )}

            <div className="flex gap-3">
              <button onClick={() => setShowDetailModal(false)} className="gk-btn-secondary flex-1">
                İptal
              </button>
              <button
                onClick={handleEnterDungeon}
                disabled={currentEnergy < selectedDungeon.energy_cost || inHospital || inPrison}
                className="gk-btn-gold flex-1"
              >
                ⚔️ Zindana Gir
              </button>
            </div>
          </div>
        </Modal>
      )}

      {/* Onay Modalı */}
      <ConfirmModal
        isOpen={showConfirmModal}
        onClose={() => setShowConfirmModal(false)}
        onConfirm={handleConfirmEnter}
        title="Zindana Gir"
        message={`${selectedDungeon?.name} zindanına girmek için ⚡${selectedDungeon?.energy_cost} enerji harcayacaksınız. Devam etmek istiyor musunuz?`}
        confirmText="Evet, Gir!"
        isLoading={isLoading}
      />

      {/* Hata Modalı */}
      <ErrorModal
        isOpen={showError}
        onClose={() => setShowError(false)}
        message={errorMessage}
      />

      {isLoading && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <LoadingSpinner size="lg" message="Zindan hazırlanıyor..." />
        </div>
      )}
    </>
  )
}
