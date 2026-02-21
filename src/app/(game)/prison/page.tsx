// =====================================================
// app/(game)/prison/page.tsx - Cezaevi ekranı
// GDScript PrisonScreen.gd'den dönüştürüldü
// =====================================================
'use client'

import { useEffect, useState, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import { motion } from 'framer-motion'
import { usePlayerStore } from '@/store/playerStore'
import { formatCountdown } from '@/lib/utils/dateTimeUtils'
import { formatNumber } from '@/lib/utils/mathUtils'
import { ConfirmModal, ErrorModal } from '@/components/ui/Modal'
import LoadingSpinner from '@/components/ui/LoadingSpinner'
import { fetchPrisonStatus, payBail, calculateBailCost } from '@/lib/managers/prisonManager'

export default function PrisonPage() {
  const router = useRouter()
  const { inPrison, prisonReleaseTime, prisonReason, gold } = usePlayerStore((s) => ({
    inPrison: s.inPrison,
    prisonReleaseTime: s.prisonReleaseTime,
    prisonReason: s.prisonReason,
    gold: s.gold,
  }))

  const [countdown, setCountdown] = useState(0)
  const [bailCost, setBailCost] = useState(0)
  const [isLoading, setIsLoading] = useState(true)
  const [isPaying, setIsPaying] = useState(false)
  const [showConfirm, setShowConfirm] = useState(false)
  const [errorMessage, setErrorMessage] = useState('')
  const [showError, setShowError] = useState(false)
  const [totalDuration, setTotalDuration] = useState(0)

  useEffect(() => {
    loadStatus()
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  const loadStatus = async () => {
    setIsLoading(true)
    await fetchPrisonStatus()
    setIsLoading(false)
  }

  useEffect(() => {
    if (!inPrison || prisonReleaseTime === 0) return

    const now = Math.floor(Date.now() / 1000)
    const remaining = Math.max(0, prisonReleaseTime - now)
    setCountdown(remaining)
    setBailCost(calculateBailCost(prisonReleaseTime))

    if (totalDuration === 0 && remaining > 0) {
      setTotalDuration(remaining)
    }

    const interval = setInterval(() => {
      const rem = Math.max(0, prisonReleaseTime - Math.floor(Date.now() / 1000))
      setCountdown(rem)
      setBailCost(calculateBailCost(prisonReleaseTime))

      if (rem === 0) {
        clearInterval(interval)
        usePlayerStore.getState().setPrisonStatus(false, 0)
      }
    }, 1000)

    return () => clearInterval(interval)
  }, [inPrison, prisonReleaseTime]) // eslint-disable-line react-hooks/exhaustive-deps

  const handlePayBail = useCallback(async () => {
    setIsPaying(true)
    setShowConfirm(false)
    const result = await payBail()
    setIsPaying(false)

    if (!result.success) {
      setErrorMessage(result.error ?? 'Kefalet ödemesi başarısız')
      setShowError(true)
    }
  }, [])

  const progressPct = totalDuration > 0 ? Math.max(0, (1 - countdown / totalDuration) * 100) : 0
  const canAfford = gold >= bailCost

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <LoadingSpinner message="Cezaevi durumu yükleniyor..." />
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
            animate={inPrison ? { rotate: [-3, 3, -3] } : {}}
            transition={{ repeat: Infinity, duration: 2 }}
            className="text-6xl mb-3"
          >
            👮
          </motion.div>
          <h1 className="gk-title text-2xl">Cezaevi</h1>
          <p className="text-gk-silver text-sm mt-1">Suç işleyenlerin yeridir burası</p>
        </div>

        {inPrison ? (
          <div className="space-y-4">
            {/* Durum kartı */}
            <div className="gk-panel border border-red-700 bg-red-900/10">
              <div className="text-center mb-4">
                <p className="text-red-400 font-bold text-lg">Hükümlüsünüz</p>
                {prisonReason && (
                  <p className="text-gk-silver text-sm mt-1">Suç: {prisonReason}</p>
                )}
              </div>

              {/* Geri sayım */}
              <div className="text-center mb-4">
                <p className="text-white text-4xl font-mono font-bold">
                  {formatCountdown(countdown)}
                </p>
                <p className="text-gk-silver text-sm mt-1">Kalan Ceza Süresi</p>
              </div>

              {/* İlerleme barı */}
              <div className="mb-2">
                <div className="h-3 bg-gk-surface rounded-full overflow-hidden">
                  <motion.div
                    className="h-full rounded-full"
                    style={{ background: 'linear-gradient(90deg, #ef4444, #f97316)' }}
                    animate={{ width: `${progressPct}%` }}
                    transition={{ duration: 1 }}
                  />
                </div>
                <div className="flex justify-between text-xs text-gk-silver mt-1">
                  <span>Ceza başladı</span>
                  <span>{Math.round(progressPct)}% tamamlandı</span>
                </div>
              </div>
            </div>

            {/* Kefalet */}
            <div className="gk-panel">
              <h3 className="text-white font-bold mb-2">💰 Kefalet Öde</h3>
              <p className="text-gk-silver text-sm mb-3">
                Altın ödeyerek cezaevinden erken çıkabilirsiniz.
              </p>
              <div className="flex items-center justify-between mb-2">
                <span className="text-gk-silver text-sm">Kefalet Bedeli</span>
                <span className={`font-bold ${canAfford ? 'text-gk-gold' : 'text-red-400'}`}>
                  💰 {formatNumber(bailCost)}
                </span>
              </div>
              <div className="flex items-center justify-between mb-4">
                <span className="text-gk-silver text-sm">Altınınız</span>
                <span className={`font-bold ${canAfford ? 'text-gk-gold' : 'text-red-400'}`}>
                  💰 {formatNumber(gold)}
                </span>
              </div>
              <button
                onClick={() => setShowConfirm(true)}
                disabled={!canAfford || isPaying}
                className="gk-btn-gold w-full flex items-center justify-center gap-2"
              >
                {isPaying ? (
                  <span className="w-4 h-4 border-2 border-gk-darker border-t-transparent rounded-full animate-spin" />
                ) : null}
                {canAfford ? '💰 Kefaleti Öde' : '💰 Yetersiz Altın'}
              </button>
            </div>

            {/* Suç istatistikleri */}
            <div className="gk-panel">
              <h3 className="text-gk-silver text-xs font-bold mb-2 uppercase tracking-wider">
                Ceza Bilgisi
              </h3>
              <div className="grid grid-cols-2 gap-3">
                <div className="bg-gk-surface rounded-lg p-3 text-center">
                  <p className="text-white font-bold">{Math.ceil(countdown / 3600)}sa</p>
                  <p className="text-gk-silver text-xs">Kalan Süre</p>
                </div>
                <div className="bg-gk-surface rounded-lg p-3 text-center">
                  <p className="text-gk-gold font-bold">{formatNumber(bailCost)}</p>
                  <p className="text-gk-silver text-xs">💰 Kefalet</p>
                </div>
              </div>
            </div>

            <div className="gk-panel bg-gk-surface">
              <p className="text-gk-silver text-xs text-center">
                ⚖️ Cezaevindeyken zindan, PvP ve tesis yönetimi yapamazsınız.
              </p>
            </div>
          </div>
        ) : (
          /* Özgür */
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            className="gk-panel text-center py-12"
          >
            <div className="text-6xl mb-4">🕊️</div>
            <h2 className="text-white text-xl font-bold mb-2">Özgürsünüz!</h2>
            <p className="text-gk-silver text-sm">Şu an cezaevinde değilsiniz. Yasalara uyun!</p>
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
        onConfirm={handlePayBail}
        title="Kefalet Öde"
        message={`💰 ${formatNumber(bailCost)} altın ödeyerek cezaevinden çıkmak istiyor musunuz?`}
        confirmText="Evet, Öde"
        isLoading={isPaying}
      />

      <ErrorModal isOpen={showError} onClose={() => setShowError(false)} message={errorMessage} />
    </>
  )
}
