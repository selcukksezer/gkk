// =====================================================
// app/(game)/dungeon/battle/page.tsx - Zindan savaş ekranı
// GDScript DungeonBattleScreen.gd'den dönüştürüldü
// =====================================================
'use client'

import { useEffect, useState, useRef, Suspense } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { motion, AnimatePresence } from 'framer-motion'
import { usePlayerStore } from '@/store/playerStore'
import { formatNumber } from '@/lib/utils/mathUtils'
import { MOCK_DUNGEONS, type DungeonOutcome } from '@/types/dungeon'
import { simulateDungeonOutcome, calculateSuccessRate } from '@/lib/managers/dungeonManager'

type BattlePhase = 'preparation' | 'battle' | 'result'

const BATTLE_MESSAGES = [
  '⚔️ Düşmanlarla savaşıyorsunuz...',
  '🛡️ Saldırıyı savuşturuyorsunuz...',
  '🗡️ Kritik darbe!',
  '✨ Büyü kullanıyorsunuz...',
  '🏃 İlerliyorsunuz...',
  '💥 Güçlü bir saldırı!',
  '🔥 Alevler yükseliyor...',
  '⚡ Şimşek gibi hızlı!',
]

function BattleContent() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const dungeonId = searchParams.get('id')
  const { level, player, setHospitalStatus, updateGold } = usePlayerStore((s) => ({
    level: s.level,
    player: s.player,
    setHospitalStatus: s.setHospitalStatus,
    updateGold: s.updateGold,
  }))

  const [phase, setPhase] = useState<BattlePhase>('preparation')
  const [battleLog, setBattleLog] = useState<string[]>([])
  const [outcome, setOutcome] = useState<DungeonOutcome | null>(null)
  const [progress, setProgress] = useState(0)
  const [currentMessage, setCurrentMessage] = useState(BATTLE_MESSAGES[0])
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null)
  const logRef = useRef<HTMLDivElement>(null)

  const dungeon = MOCK_DUNGEONS.find((d) => d.id === dungeonId)
  const playerPower = player?.power ?? 100

  useEffect(() => {
    if (!dungeon) {
      router.replace('/dungeon')
      return
    }

    // Hazırlık aşaması
    const prepTimer = setTimeout(() => {
      setPhase('battle')
      startBattle()
    }, 2000)

    return () => clearTimeout(prepTimer)
  }, [dungeon]) // eslint-disable-line react-hooks/exhaustive-deps

  const addLog = (msg: string) => {
    setBattleLog((prev) => [...prev, msg])
    setTimeout(() => {
      logRef.current?.scrollTo({ top: logRef.current.scrollHeight, behavior: 'smooth' })
    }, 50)
  }

  const startBattle = () => {
    if (!dungeon) return

    const duration = Math.min(dungeon.estimated_duration_seconds * 1000, 8000)
    const steps = 8
    const stepDuration = duration / steps
    let step = 0

    addLog(`🏰 ${dungeon.name} zindanına girdiniz!`)
    addLog(`⚠️ Tehlike seviyesi: ${dungeon.danger_level}%`)

    timerRef.current = setInterval(() => {
      step++
      setProgress((step / steps) * 100)

      const msg = BATTLE_MESSAGES[step % BATTLE_MESSAGES.length]
      setCurrentMessage(msg)
      addLog(msg)

      if (step >= steps) {
        if (timerRef.current) clearInterval(timerRef.current)
        finalizeBattle()
      }
    }, stepDuration)
  }

  const finalizeBattle = () => {
    if (!dungeon) return

    const result = simulateDungeonOutcome(dungeon, playerPower, level)
    setOutcome(result)

    if (result.success) {
      addLog(`🎉 ${result.message}`)
      addLog(`💰 Kazandınız: ${formatNumber(result.gold_earned)} altın`)
      addLog(`⭐ XP: +${result.xp_earned}`)
      updateGold(result.gold_earned, true)
    } else {
      addLog(`💀 ${result.message}`)
      if (result.hospitalized) {
        addLog('🏥 Hastaneye kaldırıldınız!')
        const releaseTime = Math.floor(Date.now() / 1000) + (result.hospital_duration_minutes ?? 60) * 60
        setHospitalStatus(true, releaseTime, `${dungeon.name} zindanı`)
      }
    }

    setTimeout(() => setPhase('result'), 500)
  }

  useEffect(() => {
    return () => {
      if (timerRef.current) clearInterval(timerRef.current)
    }
  }, [])

  if (!dungeon) return null

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      className="px-4 pt-4 pb-4 max-w-[480px] mx-auto min-h-screen"
    >
      {/* Zindan adı */}
      <div className="text-center mb-6">
        <h1 className="gk-title text-2xl mb-1">{dungeon.name}</h1>
        <p className="text-gk-silver text-sm">{dungeon.zone}</p>
      </div>

      <AnimatePresence mode="wait">
        {/* Hazırlık */}
        {phase === 'preparation' && (
          <motion.div
            key="prep"
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.9 }}
            className="gk-panel text-center py-12"
          >
            <motion.div
              animate={{ scale: [1, 1.1, 1], rotate: [0, 5, -5, 0] }}
              transition={{ repeat: Infinity, duration: 1.5 }}
              className="text-7xl mb-6"
            >
              ⚔️
            </motion.div>
            <h2 className="text-white text-xl font-bold mb-2">Hazırlanıyorsunuz...</h2>
            <p className="text-gk-silver text-sm">Ekipmanlarınızı hazırlayın!</p>
          </motion.div>
        )}

        {/* Savaş */}
        {phase === 'battle' && (
          <motion.div
            key="battle"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="space-y-4"
          >
            {/* Animasyonlu karakter */}
            <div className="gk-panel text-center py-6">
              <motion.div
                animate={{ x: [-5, 5, -5], scale: [1, 1.05, 1] }}
                transition={{ repeat: Infinity, duration: 0.8 }}
                className="text-6xl mb-4"
              >
                🗡️
              </motion.div>
              <p className="text-white font-bold text-lg">{currentMessage}</p>
            </div>

            {/* İlerleme */}
            <div className="gk-panel">
              <div className="flex justify-between text-sm mb-2">
                <span className="text-gk-silver">İlerleme</span>
                <span className="text-gk-gold font-bold">{Math.round(progress)}%</span>
              </div>
              <div className="h-3 bg-gk-surface rounded-full overflow-hidden">
                <motion.div
                  className="h-full rounded-full"
                  style={{ background: 'linear-gradient(90deg, #d4a017, #f0c040)' }}
                  animate={{ width: `${progress}%` }}
                  transition={{ duration: 0.5 }}
                />
              </div>
            </div>

            {/* Savaş günlüğü */}
            <div className="gk-panel">
              <h3 className="text-gk-silver text-xs font-bold mb-2 uppercase tracking-wider">
                Savaş Günlüğü
              </h3>
              <div ref={logRef} className="space-y-1 max-h-40 overflow-y-auto">
                {battleLog.map((msg, i) => (
                  <motion.p
                    key={i}
                    initial={{ opacity: 0, x: -10 }}
                    animate={{ opacity: 1, x: 0 }}
                    className="text-gk-silver text-xs"
                  >
                    {msg}
                  </motion.p>
                ))}
              </div>
            </div>
          </motion.div>
        )}

        {/* Sonuç */}
        {phase === 'result' && outcome && (
          <motion.div
            key="result"
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ type: 'spring', damping: 20 }}
            className="space-y-4"
          >
            {/* Sonuç başlığı */}
            <div className={`gk-panel text-center py-8 border-2 ${outcome.success ? 'border-green-600 bg-green-900/10' : 'border-red-800 bg-red-900/10'}`}>
              <motion.div
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                transition={{ type: 'spring', delay: 0.2 }}
                className="text-7xl mb-4"
              >
                {outcome.success ? '🏆' : outcome.hospitalized ? '🏥' : '💀'}
              </motion.div>
              <h2 className={`text-2xl font-bold mb-2 ${outcome.success ? 'text-green-400' : 'text-red-400'}`}>
                {outcome.success ? 'ZAFER!' : outcome.hospitalized ? 'HASTANEYE KALDIRILDINIZ' : 'MAĞLUBIYET'}
              </h2>
              <p className="text-gk-silver text-sm">{outcome.message}</p>
            </div>

            {/* Ödüller */}
            {outcome.success && (
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.4 }}
                className="gk-panel"
              >
                <h3 className="gk-title text-base mb-3">🎁 Kazanılanlar</h3>
                <div className="grid grid-cols-2 gap-3">
                  <div className="bg-gk-surface rounded-lg p-3 text-center">
                    <p className="text-gk-gold font-bold text-lg">+{formatNumber(outcome.gold_earned)}</p>
                    <p className="text-gk-silver text-xs">💰 Altın</p>
                  </div>
                  <div className="bg-gk-surface rounded-lg p-3 text-center">
                    <p className="text-green-400 font-bold text-lg">+{outcome.xp_earned}</p>
                    <p className="text-gk-silver text-xs">⭐ Deneyim</p>
                  </div>
                </div>
              </motion.div>
            )}

            {/* Hastane uyarısı */}
            {outcome.hospitalized && (
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.4 }}
                className="gk-panel border border-yellow-700 bg-yellow-900/10"
              >
                <p className="text-yellow-400 text-sm text-center">
                  🏥 {outcome.hospital_duration_minutes} dakika süreyle hastanede kalacaksınız.
                </p>
              </motion.div>
            )}

            {/* Butonlar */}
            <div className="flex gap-3">
              {outcome.hospitalized ? (
                <button
                  onClick={() => router.push('/hospital')}
                  className="gk-btn-gold flex-1"
                >
                  🏥 Hastaneye Git
                </button>
              ) : (
                <button
                  onClick={() => router.push('/dungeon')}
                  className="gk-btn-gold flex-1"
                >
                  ⚔️ Tekrar Oyna
                </button>
              )}
              <button
                onClick={() => router.push('/home')}
                className="gk-btn-secondary flex-1"
              >
                🏠 Ana Sayfa
              </button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.div>
  )
}

export default function DungeonBattlePage() {
  return (
    <Suspense fallback={
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <div className="text-6xl mb-4">⚔️</div>
          <p className="text-gk-silver">Zindan yükleniyor...</p>
        </div>
      </div>
    }>
      <BattleContent />
    </Suspense>
  )
}
