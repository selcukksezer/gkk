// =====================================================
// app/(game)/pvp/page.tsx - PvP savaş ekranı
// GDScript PvPScreen.gd'den dönüştürüldü
// =====================================================
'use client'

import { useEffect, useState, useCallback } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { usePlayerStore } from '@/store/playerStore'
import { formatNumber } from '@/lib/utils/mathUtils'
import { Modal, ErrorModal } from '@/components/ui/Modal'
import LoadingSpinner from '@/components/ui/LoadingSpinner'
import {
  fetchPvPTargets,
  attackPlayer,
  fetchPvPHistory,
  fetchPvPStats,
} from '@/lib/managers/pvpManager'
import { OUTCOME_COLORS, OUTCOME_NAMES, PVP_CONFIG, type PvPTarget, type PvPMatch, type PvPStats } from '@/types/pvp'
import { timeAgo } from '@/lib/utils/dateTimeUtils'

type TabType = 'targets' | 'history'

const MOCK_TARGETS: PvPTarget[] = [
  { player_id: 'p1', username: 'KaranlıkŞövalye', display_name: 'Karanlık Şövalye', level: 12, power: 850, reputation: -20, is_online: true, last_seen: '', gold_estimate: 500, win_probability: 0.65 },
  { player_id: 'p2', username: 'GölgeKatil', display_name: 'Gölge Katil', level: 8, power: 420, reputation: 10, is_online: false, last_seen: new Date(Date.now() - 3600000).toISOString(), gold_estimate: 200, win_probability: 0.78 },
  { player_id: 'p3', username: 'DemirKral', display_name: 'Demir Kral', level: 18, power: 1500, reputation: 45, is_online: true, last_seen: '', gold_estimate: 1200, win_probability: 0.35 },
  { player_id: 'p4', username: 'KanEfendisi', display_name: 'Kan Efendisi', level: 15, power: 1100, reputation: -50, is_online: false, last_seen: new Date(Date.now() - 7200000).toISOString(), gold_estimate: 800, win_probability: 0.48 },
]

export default function PvPPage() {
  const { level, currentEnergy, pvpWins, pvpLosses, pvpRating, inHospital, inPrison, player } = usePlayerStore((s) => ({
    level: s.level,
    currentEnergy: s.currentEnergy,
    pvpWins: s.pvpWins,
    pvpLosses: s.pvpLosses,
    pvpRating: s.pvpRating,
    inHospital: s.inHospital,
    inPrison: s.inPrison,
    player: s.player,
  }))

  const [activeTab, setActiveTab] = useState<TabType>('targets')
  const [targets, setTargets] = useState<PvPTarget[]>(MOCK_TARGETS)
  const [history, setHistory] = useState<PvPMatch[]>([])
  const [stats, setStats] = useState<PvPStats | null>(null)
  const [isLoading, setIsLoading] = useState(false)
  const [isAttacking, setIsAttacking] = useState(false)
  const [selectedTarget, setSelectedTarget] = useState<PvPTarget | null>(null)
  const [showResultModal, setShowResultModal] = useState(false)
  const [battleResult, setBattleResult] = useState<PvPMatch | null>(null)
  const [errorMessage, setErrorMessage] = useState('')
  const [showError, setShowError] = useState(false)

  useEffect(() => {
    loadData()
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  const loadData = async () => {
    setIsLoading(true)
    const [targetList, pvpStats] = await Promise.all([
      fetchPvPTargets(),
      fetchPvPStats(),
    ])
    if (targetList.length > 0) setTargets(targetList)
    setStats(pvpStats)
    setIsLoading(false)
  }

  const loadHistory = useCallback(async () => {
    const h = await fetchPvPHistory('attack')
    setHistory(h)
  }, [])

  useEffect(() => {
    if (activeTab === 'history') {
      loadHistory()
    }
  }, [activeTab, loadHistory])

  const handleAttack = useCallback(async (target: PvPTarget) => {
    if (inHospital) { setErrorMessage('Hastanede olduğunuz için PvP yapamazsınız'); setShowError(true); return }
    if (inPrison) { setErrorMessage('Cezaevinde olduğunuz için PvP yapamazsınız'); setShowError(true); return }
    if (currentEnergy < PVP_CONFIG.energyCost) { setErrorMessage(`PvP için ⚡${PVP_CONFIG.energyCost} enerji gerekli`); setShowError(true); return }

    setSelectedTarget(target)
    setIsAttacking(true)

    const result = await attackPlayer(target.player_id)
    setIsAttacking(false)

    if (result.success && result.match) {
      setBattleResult(result.match)
      setShowResultModal(true)
    } else {
      setErrorMessage(result.error ?? 'Saldırı başarısız')
      setShowError(true)
    }
  }, [inHospital, inPrison, currentEnergy])

  const winRate = pvpWins + pvpLosses > 0
    ? Math.round((pvpWins / (pvpWins + pvpLosses)) * 100)
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
          <span className="text-3xl">🆚</span>
          <div>
            <h1 className="gk-title text-xl">PvP Arena</h1>
            <p className="text-gk-silver text-xs">Diğer oyuncularla savaş</p>
          </div>
          <div className="ml-auto text-right">
            <span className="text-gk-energy text-sm font-bold">⚡ {currentEnergy}</span>
          </div>
        </div>

        {/* İstatistikler */}
        <div className="grid grid-cols-4 gap-2 mb-4">
          {[
            { label: 'Galibiyet', value: pvpWins, color: 'text-green-400', icon: '🏆' },
            { label: 'Mağlubiyet', value: pvpLosses, color: 'text-red-400', icon: '💀' },
            { label: 'Oran', value: `${winRate}%`, color: 'text-gk-gold', icon: '📊' },
            { label: 'Puan', value: formatNumber(pvpRating), color: 'text-blue-400', icon: '⭐' },
          ].map((stat) => (
            <div key={stat.label} className="bg-gk-surface rounded-xl p-2 text-center">
              <p className="text-base">{stat.icon}</p>
              <p className={`font-bold text-sm ${stat.color}`}>{stat.value}</p>
              <p className="text-gk-silver text-xs">{stat.label}</p>
            </div>
          ))}
        </div>

        {/* Durum uyarıları */}
        {(inHospital || inPrison) && (
          <div className="gk-panel border-red-800 bg-red-900/10 mb-4 p-3">
            <p className="text-red-400 text-sm text-center">
              {inHospital ? '🏥 Hastanede PvP yapamazsınız' : '👮 Cezaevinde PvP yapamazsınız'}
            </p>
          </div>
        )}

        {/* Sekmeler */}
        <div className="flex bg-gk-surface rounded-xl p-1 mb-4 gap-1">
          {(['targets', 'history'] as TabType[]).map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`flex-1 py-2 rounded-lg text-sm font-semibold transition-all duration-200 ${
                activeTab === tab ? 'bg-gk-gold text-gk-darker' : 'text-gk-silver hover:text-white'
              }`}
            >
              {tab === 'targets' ? '🎯 Hedefler' : '📜 Geçmiş'}
            </button>
          ))}
        </div>

        {/* Hedefler */}
        {activeTab === 'targets' && (
          <div className="space-y-3">
            {isLoading ? (
              <div className="flex justify-center py-8"><LoadingSpinner /></div>
            ) : targets.map((target, i) => (
              <motion.div
                key={target.player_id}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: i * 0.06 }}
                className="gk-panel"
              >
                <div className="flex items-center gap-3 mb-3">
                  <div className="w-10 h-10 rounded-full bg-gk-surface border border-gk-border flex items-center justify-center text-lg">
                    ⚔️
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center gap-2">
                      <span className="font-bold text-white">{target.display_name}</span>
                      {target.is_online && (
                        <span className="w-2 h-2 rounded-full bg-green-500 inline-block" />
                      )}
                    </div>
                    <p className="text-gk-silver text-xs">
                      Seviye {target.level} • Güç: {formatNumber(target.power)}
                    </p>
                  </div>
                  <div className="text-right">
                    <p
                      className="font-bold text-sm"
                      style={{ color: target.win_probability >= 0.5 ? '#22c55e' : '#ef4444' }}
                    >
                      {Math.round(target.win_probability * 100)}%
                    </p>
                    <p className="text-gk-silver text-xs">kazanma</p>
                  </div>
                </div>

                <div className="flex gap-2 items-center mb-3 text-xs text-gk-silver">
                  <span>💰 ~{formatNumber(target.gold_estimate)} çalınabilir</span>
                  {target.reputation < -30 && <span className="text-red-400">🔴 Haydut</span>}
                  {target.reputation > 30 && <span className="text-yellow-400">⭐ Kahraman</span>}
                </div>

                <button
                  onClick={() => handleAttack(target)}
                  disabled={isAttacking || currentEnergy < PVP_CONFIG.energyCost || inHospital || inPrison}
                  className="gk-btn-danger w-full text-sm flex items-center justify-center gap-2"
                >
                  {isAttacking && selectedTarget?.player_id === target.player_id ? (
                    <span className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                  ) : null}
                  ⚔️ Saldır ({PVP_CONFIG.energyCost} ⚡)
                </button>
              </motion.div>
            ))}
          </div>
        )}

        {/* Geçmiş */}
        {activeTab === 'history' && (
          <div className="space-y-3">
            {history.length === 0 && (
              <div className="gk-panel text-center py-8">
                <p className="text-4xl mb-2">📜</p>
                <p className="text-gk-silver">Henüz PvP geçmişiniz yok</p>
              </div>
            )}
            {history.map((match, i) => (
              <motion.div
                key={match.id}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: i * 0.06 }}
                className="gk-panel"
              >
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-white text-sm font-bold">vs {match.defender_username}</p>
                    <p className="text-gk-silver text-xs">{timeAgo(match.occurred_at)}</p>
                  </div>
                  <div className="text-right">
                    <p className="font-bold" style={{ color: OUTCOME_COLORS[match.outcome] }}>
                      {OUTCOME_NAMES[match.outcome]}
                    </p>
                    {match.gold_change !== 0 && (
                      <p className={`text-xs ${match.gold_change > 0 ? 'text-gk-gold' : 'text-red-400'}`}>
                        {match.gold_change > 0 ? '+' : ''}{formatNumber(match.gold_change)} 💰
                      </p>
                    )}
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
        )}
      </motion.div>

      {/* Saldırı sonucu modal */}
      {battleResult && (
        <Modal
          isOpen={showResultModal}
          onClose={() => setShowResultModal(false)}
          title="Savaş Sonucu"
          size="md"
        >
          <div className="text-center space-y-4">
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              className="text-6xl"
            >
              {battleResult.outcome === 'win' || battleResult.outcome === 'major_win' ? '🏆' : '💀'}
            </motion.div>
            <h2
              className="text-2xl font-bold"
              style={{ color: OUTCOME_COLORS[battleResult.outcome] }}
            >
              {OUTCOME_NAMES[battleResult.outcome]}
            </h2>
            <p className="text-gk-silver text-sm">vs {battleResult.defender_username}</p>

            <div className="grid grid-cols-2 gap-3">
              {battleResult.gold_change > 0 && (
                <div className="bg-gk-surface rounded-lg p-3 text-center">
                  <p className="text-gk-gold font-bold">+{formatNumber(battleResult.gold_change)}</p>
                  <p className="text-gk-silver text-xs">💰 Altın Kazandı</p>
                </div>
              )}
              <div className="bg-gk-surface rounded-lg p-3 text-center">
                <p className="text-green-400 font-bold">+{battleResult.xp_earned}</p>
                <p className="text-gk-silver text-xs">⭐ XP</p>
              </div>
            </div>

            <button onClick={() => setShowResultModal(false)} className="gk-btn-gold w-full">
              Tamam
            </button>
          </div>
        </Modal>
      )}

      <ErrorModal isOpen={showError} onClose={() => setShowError(false)} message={errorMessage} />
    </>
  )
}
