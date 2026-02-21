// =====================================================
// app/(game)/hospital/page.tsx - Hastane ekranı
// GDScript HospitalScreen.gd'den dönüştürüldü
// =====================================================
'use client'

import { useEffect, useState, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import { motion } from 'framer-motion'
import { usePlayerStore } from '@/store/playerStore'
import { formatCountdown } from '@/lib/utils/dateTimeUtils'
import { ConfirmModal, ErrorModal } from '@/components/ui/Modal'
import LoadingSpinner from '@/components/ui/LoadingSpinner'
import { fetchHospitalStatus, releaseWithGems, calculateGemCost } from '@/lib/managers/hospitalManager'

export default function HospitalPage() {
  const router = useRouter()
  const { inHospital, hospitalReleaseTime, hospitalReason, gems } = usePlayerStore((s) => ({
    inHospital: s.inHospital,
    hospitalReleaseTime: s.hospitalReleaseTime,
    hospitalReason: s.hospitalReason,
    gems: s.gems,
  }))

  const [countdown, setCountdown] = useState(0)
  const [gemCost, setGemCost] = useState(0)
  const [isLoading, setIsLoading] = useState(true)
  const [isReleasing, setIsReleasing] = useState(false)
  const [showConfirm, setShowConfirm] = useState(false)
  const [errorMessage, setErrorMessage] = useState('')
  const [showError, setShowError] = useState(false)
  const [totalDuration, setTotalDuration] = useState(0)

  useEffect(() => {
    loadStatus()
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  const loadStatus = async () => {
    setIsLoading(true)
    await fetchHospitalStatus()
    setIsLoading(false)
  }

  useEffect(() => {
    if (!inHospital || hospitalReleaseTime === 0) return

    const now = Math.floor(Date.now() / 1000)
    const remaining = Math.max(0, hospitalReleaseTime - now)
    setCountdown(remaining)
    setGemCost(calculateGemCost(hospitalReleaseTime))

    // Toplam süreyi tahmin et (ilk yüklendiğinde)
    if (totalDuration === 0 && remaining > 0) {
      setTotalDuration(remaining)
    }

    const interval = setInterval(() => {
      const rem = Math.max(0, hospitalReleaseTime - Math.floor(Date.now() / 1000))
      setCountdown(rem)
      setGemCost(calculateGemCost(hospitalReleaseTime))

      if (rem === 0) {
        clearInterval(interval)
        usePlayerStore.getState().setHospitalStatus(false, 0)
      }
    }, 1000)

    return () => clearInterval(interval)
  }, [inHospital, hospitalReleaseTime]) // eslint-disable-line react-hooks/exhaustive-deps

  const handleEarlyRelease = useCallback(async () => {
    setIsReleasing(true)
    setShowConfirm(false)
    const result = await releaseWithGems()
    setIsReleasing(false)

    if (!result.success) {
      setErrorMessage(result.error ?? 'Erken çıkış başarısız')
      setShowError(true)
    }
  }, [])

  const progressPct = totalDuration > 0 ? Math.max(0, (1 - countdown / totalDuration) * 100) : 0
  const canAffordGems = gems >= gemCost

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <LoadingSpinner message="Hastane durumu yükleniyor..." />
      </div>
    )
  }

  return (
    <>
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
        <div className="text-center mb-6">
          <motion.div
            animate={inHospital ? { scale: [1, 1.05, 1] } : {}}
            transition={{ repeat: Infinity, duration: 2 }}
            className="text-6xl mb-3"
          >
            🏥
          </motion.div>
          <h1 className="gk-title text-2xl">Hastane</h1>
          <p className="text-gk-silver text-sm mt-1">Yaralarınızı iyileştirin</p>
        </div>

        {inHospital ? (
          <div className="space-y-4">
            {/* Durum kartı */}
            <div className="gk-panel border border-yellow-700 bg-yellow-900/10">
              <div className="text-center mb-4">
                <p className="text-yellow-400 font-bold text-lg">Tedavi Görüyorsunuz</p>
                {hospitalReason && (
                  <p className="text-gk-silver text-sm mt-1">Neden: {hospitalReason}</p>
                )}
              </div>

              {/* Geri sayım */}
              <div className="text-center mb-4">
                <p className="text-white text-4xl font-mono font-bold">
                  {formatCountdown(countdown)}
                </p>
                <p className="text-gk-silver text-sm mt-1">Kalan Süre</p>
              </div>

              {/* İlerleme barı */}
              <div className="mb-4">
                <div className="h-3 bg-gk-surface rounded-full overflow-hidden">
                  <motion.div
                    className="h-full rounded-full bg-green-500"
                    animate={{ width: `${progressPct}%` }}
                    transition={{ duration: 1 }}
                  />
                </div>
                <div className="flex justify-between text-xs text-gk-silver mt-1">
                  <span>Tedavi başladı</span>
                  <span>{Math.round(progressPct)}% tamamlandı</span>
                </div>
              </div>
            </div>

            {/* Elmas ile erken çıkış */}
            <div className="gk-panel">
              <h3 className="text-white font-bold mb-2">💎 Erken Çıkış</h3>
              <p className="text-gk-silver text-sm mb-3">
                Elmas harcayarak hemen hastaneden çıkabilirsiniz.
              </p>
              <div className="flex items-center justify-between mb-3">
                <span className="text-gk-silver text-sm">Maliyet</span>
                <span className={`font-bold ${canAffordGems ? 'text-blue-400' : 'text-red-400'}`}>
                  💎 {gemCost}
                </span>
              </div>
              <div className="flex items-center justify-between mb-4">
                <span className="text-gk-silver text-sm">Elmasınız</span>
                <span className={`font-bold ${canAffordGems ? 'text-blue-400' : 'text-red-400'}`}>
                  💎 {gems}
                </span>
              </div>
              <button
                onClick={() => setShowConfirm(true)}
                disabled={!canAffordGems || isReleasing}
                className="gk-btn-gold w-full flex items-center justify-center gap-2"
              >
                {isReleasing ? (
                  <span className="w-4 h-4 border-2 border-gk-darker border-t-transparent rounded-full animate-spin" />
                ) : null}
                {canAffordGems ? '💎 Şimdi Çık' : '💎 Yetersiz Elmas'}
              </button>
            </div>

            {/* Bilgi */}
            <div className="gk-panel bg-gk-surface">
              <p className="text-gk-silver text-xs text-center">
                ℹ️ Hastanedeyken zindan ve PvP yapamazsınız. Süre dolduğunda otomatik taburcu olursunuz.
              </p>
            </div>
          </div>
        ) : (
          /* Hastanede değil */
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            className="gk-panel text-center py-12"
          >
            <div className="text-6xl mb-4">✅</div>
            <h2 className="text-white text-xl font-bold mb-2">Sağlıklısınız!</h2>
            <p className="text-gk-silver text-sm">Şu an hastanede değilsiniz. Maceraya devam edebilirsiniz.</p>
            <button
              onClick={() => router.push('/home')}
              className="gk-btn-gold mt-6 px-8"
            >
              🏠 Ana Sayfaya Dön
            </button>
          </motion.div>
        )}
      </motion.div>

      <ConfirmModal
        isOpen={showConfirm}
        onClose={() => setShowConfirm(false)}
        onConfirm={handleEarlyRelease}
        title="Erken Çıkış"
        message={`💎 ${gemCost} elmas harcayarak hastaneden şimdi çıkmak istiyor musunuz?`}
        confirmText="Evet, Çık"
        isLoading={isReleasing}
      />

      <ErrorModal isOpen={showError} onClose={() => setShowError(false)} message={errorMessage} />
    </>
  )
}
