// =====================================================
// app/(game)/facilities/page.tsx - Tesis yönetim ekranı
// GDScript FacilityScreen.gd'den dönüştürüldü
// =====================================================
'use client'

import { useEffect, useState, useCallback } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { usePlayerStore } from '@/store/playerStore'
import { formatNumber } from '@/lib/utils/mathUtils'
import { Modal, ConfirmModal, ErrorModal } from '@/components/ui/Modal'
import LoadingSpinner from '@/components/ui/LoadingSpinner'
import {
  FACILITIES_CONFIG,
  ALL_FACILITY_TYPES,
  calculateUpgradeCost,
  type FacilityType,
  type PlayerFacility,
} from '@/types/facility'
import { fetchFacilities, unlockFacility, upgradeFacility } from '@/lib/managers/facilityManager'

type FilterType = 'all' | 1 | 2 | 3

export default function FacilitiesPage() {
  const { gold, level } = usePlayerStore((s) => ({ gold: s.gold, level: s.level }))

  const [facilities, setFacilities] = useState<PlayerFacility[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [selectedType, setSelectedType] = useState<FacilityType | null>(null)
  const [showDetail, setShowDetail] = useState(false)
  const [showConfirm, setShowConfirm] = useState(false)
  const [confirmAction, setConfirmAction] = useState<'unlock' | 'upgrade'>('unlock')
  const [isActing, setIsActing] = useState(false)
  const [errorMessage, setErrorMessage] = useState('')
  const [showError, setShowError] = useState(false)
  const [filter, setFilter] = useState<FilterType>('all')

  useEffect(() => {
    loadFacilities()
  }, [])

  const loadFacilities = async () => {
    setIsLoading(true)
    const result = await fetchFacilities()
    if (result.success && result.data) {
      setFacilities(result.data)
    }
    setIsLoading(false)
  }

  const getFacilityData = useCallback((type: FacilityType): PlayerFacility | null => {
    return facilities.find((f) => f.facility_type === type) ?? null
  }, [facilities])

  const handleCardPress = (type: FacilityType) => {
    setSelectedType(type)
    setShowDetail(true)
  }

  const handleUnlock = () => {
    setShowDetail(false)
    setConfirmAction('unlock')
    setShowConfirm(true)
  }

  const handleUpgrade = () => {
    setShowDetail(false)
    setConfirmAction('upgrade')
    setShowConfirm(true)
  }

  const handleConfirm = async () => {
    if (!selectedType) return
    setIsActing(true)
    setShowConfirm(false)

    const result = confirmAction === 'unlock'
      ? await unlockFacility(selectedType)
      : await upgradeFacility(selectedType)

    setIsActing(false)
    if (result.success) {
      await loadFacilities()
    } else {
      setErrorMessage(result.error ?? 'İşlem başarısız')
      setShowError(true)
    }
  }

  const filteredTypes = ALL_FACILITY_TYPES.filter((type) => {
    if (filter === 'all') return true
    return FACILITIES_CONFIG[type].tier === filter
  })

  const selectedConfig = selectedType ? FACILITIES_CONFIG[selectedType] : null
  const selectedFacility = selectedType ? getFacilityData(selectedType) : null
  const upgradeCost = selectedType && selectedFacility
    ? calculateUpgradeCost(selectedType, selectedFacility.level)
    : selectedConfig?.unlock_cost ?? 0

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
          <span className="text-3xl">⚙️</span>
          <div>
            <h1 className="gk-title text-xl">Tesisler</h1>
            <p className="text-gk-silver text-xs">Üretim tesislerini yönet</p>
          </div>
          <div className="ml-auto">
            <span className="text-gk-gold text-sm font-bold">💰 {formatNumber(gold)}</span>
          </div>
        </div>

        {/* Filtreler */}
        <div className="flex gap-2 mb-4 overflow-x-auto pb-1">
          {(['all', 1, 2, 3] as FilterType[]).map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`whitespace-nowrap px-3 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                filter === f ? 'bg-gk-gold text-gk-darker' : 'bg-gk-surface text-gk-silver hover:text-white'
              }`}
            >
              {f === 'all' ? '🏭 Tümü' : f === 1 ? '⛏️ Temel' : f === 2 ? '🌿 Organik' : '🔮 Mistik'}
            </button>
          ))}
        </div>

        {isLoading ? (
          <div className="flex justify-center py-12"><LoadingSpinner message="Tesisler yükleniyor..." /></div>
        ) : (
          <div className="grid grid-cols-2 gap-3">
            {filteredTypes.map((type, i) => {
              const config = FACILITIES_CONFIG[type]
              const facility = getFacilityData(type)
              const isUnlocked = !!facility
              const canAfford = gold >= config.unlock_cost
              const levelOk = level >= config.unlock_level

              return (
                <motion.div
                  key={type}
                  initial={{ opacity: 0, scale: 0.9 }}
                  animate={{ opacity: 1, scale: 1 }}
                  transition={{ delay: i * 0.04 }}
                  onClick={() => handleCardPress(type)}
                  className={`gk-panel cursor-pointer active:scale-95 transition-transform relative overflow-hidden ${
                    !isUnlocked ? 'opacity-70' : ''
                  }`}
                >
                  {/* Tier rozeti */}
                  <div
                    className="absolute top-2 right-2 w-5 h-5 rounded-full flex items-center justify-center text-xs font-bold"
                    style={{
                      background: config.tier === 1 ? '#78716c' : config.tier === 2 ? '#22c55e33' : '#8b5cf633',
                      color: config.tier === 1 ? '#d6d3d1' : config.tier === 2 ? '#22c55e' : '#8b5cf6',
                    }}
                  >
                    {config.tier}
                  </div>

                  <div className="text-3xl mb-2">{config.emoji}</div>
                  <h3 className="text-white text-xs font-bold mb-1 leading-tight">{config.name}</h3>

                  {isUnlocked ? (
                    <>
                      <div className="flex items-center gap-1 mb-2">
                        <span className="text-gk-gold text-xs font-bold">Sv.{facility!.level}</span>
                        <span
                          className="w-2 h-2 rounded-full"
                          style={{ background: facility!.is_active ? '#22c55e' : '#ef4444' }}
                        />
                      </div>
                      {facility!.suspicion_level > 0 && (
                        <div className="mb-2">
                          <div className="h-1 bg-gk-surface rounded-full overflow-hidden">
                            <div
                              className="h-full rounded-full bg-orange-500"
                              style={{ width: `${facility!.suspicion_level}%` }}
                            />
                          </div>
                          <p className="text-orange-400 text-xs mt-0.5">
                            🕵️ {facility!.suspicion_level}% şüphe
                          </p>
                        </div>
                      )}
                      <button
                        onClick={(e) => { e.stopPropagation(); handleCardPress(type) }}
                        className="gk-btn-secondary w-full text-xs py-1.5"
                      >
                        ⬆️ Yükselt
                      </button>
                    </>
                  ) : (
                    <>
                      <p className="text-gk-silver text-xs mb-2">Kapalı</p>
                      <p className="text-gk-gold text-xs font-bold mb-2">
                        💰 {formatNumber(config.unlock_cost)}
                      </p>
                      {!levelOk && (
                        <p className="text-red-400 text-xs mb-1">🔒 Sv.{config.unlock_level}</p>
                      )}
                      <button
                        onClick={(e) => { e.stopPropagation(); handleCardPress(type) }}
                        disabled={!canAfford || !levelOk}
                        className="gk-btn-gold w-full text-xs py-1.5 disabled:opacity-50"
                      >
                        🔓 Aç
                      </button>
                    </>
                  )}
                </motion.div>
              )
            })}
          </div>
        )}
      </motion.div>

      {/* Detay modalı */}
      {selectedConfig && (
        <Modal
          isOpen={showDetail}
          onClose={() => setShowDetail(false)}
          title={`${selectedConfig.emoji} ${selectedConfig.name}`}
          size="lg"
        >
          <div className="space-y-4">
            <p className="text-gk-silver text-sm">{selectedConfig.description}</p>

            <div className="grid grid-cols-2 gap-3">
              <div className="bg-gk-surface rounded-lg p-3">
                <p className="text-gk-silver text-xs mb-1">Üretim Hızı</p>
                <p className="text-gk-gold font-bold">
                  {selectedConfig.base_rate * (selectedFacility?.level ?? 1)}/sa
                </p>
              </div>
              <div className="bg-gk-surface rounded-lg p-3">
                <p className="text-gk-silver text-xs mb-1">Gerekli Seviye</p>
                <p className="text-white font-bold">{selectedConfig.unlock_level}</p>
              </div>
            </div>

            {selectedFacility && (
              <div className="bg-gk-surface rounded-lg p-3">
                <p className="text-gk-silver text-xs mb-2">Kaynaklar</p>
                <div className="flex flex-wrap gap-2">
                  {selectedConfig.resources.map((r) => (
                    <span key={r} className="gk-badge bg-gk-panel text-gk-silver text-xs">{r}</span>
                  ))}
                </div>
              </div>
            )}

            <div className="flex gap-3">
              <button onClick={() => setShowDetail(false)} className="gk-btn-secondary flex-1">
                Kapat
              </button>
              {selectedFacility ? (
                <button
                  onClick={handleUpgrade}
                  disabled={gold < upgradeCost}
                  className="gk-btn-gold flex-1"
                >
                  ⬆️ {formatNumber(upgradeCost)} 💰
                </button>
              ) : (
                <button
                  onClick={handleUnlock}
                  disabled={gold < (selectedConfig.unlock_cost) || level < selectedConfig.unlock_level}
                  className="gk-btn-gold flex-1"
                >
                  🔓 {formatNumber(selectedConfig.unlock_cost)} 💰
                </button>
              )}
            </div>
          </div>
        </Modal>
      )}

      <ConfirmModal
        isOpen={showConfirm}
        onClose={() => setShowConfirm(false)}
        onConfirm={handleConfirm}
        title={confirmAction === 'unlock' ? 'Tesis Aç' : 'Tesis Yükselt'}
        message={
          confirmAction === 'unlock'
            ? `${selectedConfig?.name} tesisini ${formatNumber(selectedConfig?.unlock_cost ?? 0)} 💰 karşılığında açmak istiyor musunuz?`
            : `${selectedConfig?.name} tesisini ${formatNumber(upgradeCost)} 💰 karşılığında yükseltmek istiyor musunuz?`
        }
        isLoading={isActing}
      />

      <ErrorModal isOpen={showError} onClose={() => setShowError(false)} message={errorMessage} />
    </>
  )
}
