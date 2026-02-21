// =====================================================
// app/(game)/anvil/page.tsx - Örs (Güçlendirme) ekranı
// GDScript AnvilScreen.gd'den dönüştürüldü
// =====================================================
'use client'

import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { ConfirmModal } from '@/components/ui/Modal'

const ENHANCEMENT_COSTS = [0, 500, 1200, 2500, 5000, 10000, 20000, 40000, 80000, 160000, 320000]
const ENHANCEMENT_CHANCES = [100, 90, 80, 70, 60, 50, 40, 30, 25, 20, 15]

export default function AnvilPage() {
  const [selectedLevel, setSelectedLevel] = useState(3)
  const [showConfirm, setShowConfirm] = useState(false)
  const [lastResult, setLastResult] = useState<null | { success: boolean; newLevel: number }>(null)

  const cost = ENHANCEMENT_COSTS[selectedLevel] ?? 0
  const chance = ENHANCEMENT_CHANCES[selectedLevel] ?? 0

  const handleEnhance = () => {
    const success = Math.random() * 100 < chance
    setLastResult({ success, newLevel: success ? selectedLevel + 1 : selectedLevel })
    if (success) setSelectedLevel((l) => Math.min(l + 1, 10))
    setShowConfirm(false)
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="p-4 space-y-4"
    >
      <h1 className="gk-title font-game text-xl">⚒️ Örs – Eşya Güçlendirme</h1>

      {/* Güçlendirme seviyesi gösterimi */}
      <div className="gk-panel text-center">
        <div className="text-6xl mb-3">⚔️</div>
        <div className="text-amber-400 font-bold text-2xl">+{selectedLevel}</div>
        <div className="text-[#a8a8b8] text-sm mt-1">Efsanevi Kılıç</div>

        <div className="flex justify-center gap-2 mt-4">
          {Array.from({ length: 11 }, (_, i) => (
            <button
              key={i}
              onClick={() => setSelectedLevel(i)}
              className={`w-7 h-7 rounded text-xs font-bold transition-all ${
                i === selectedLevel
                  ? 'bg-amber-400 text-black'
                  : i < selectedLevel
                  ? 'bg-green-700 text-white'
                  : 'bg-[#12121a] text-[#a8a8b8]'
              }`}
            >
              {i}
            </button>
          ))}
        </div>
      </div>

      {/* Güçlendirme bilgisi */}
      <div className="gk-panel">
        <div className="grid grid-cols-2 gap-4 text-center">
          <div>
            <div className="text-amber-400 font-bold text-lg">💰 {cost.toLocaleString()}</div>
            <div className="text-[#a8a8b8] text-xs">Maliyet</div>
          </div>
          <div>
            <div className="text-green-400 font-bold text-lg">%{chance}</div>
            <div className="text-[#a8a8b8] text-xs">Başarı Şansı</div>
          </div>
        </div>
      </div>

      {/* Son sonuç */}
      <AnimatePresence>
        {lastResult && (
          <motion.div
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0 }}
            className={`p-4 rounded-xl text-center ${
              lastResult.success
                ? 'bg-green-900/30 border border-green-700'
                : 'bg-red-900/30 border border-red-800'
            }`}
          >
            <div className="text-3xl mb-2">{lastResult.success ? '✨' : '💔'}</div>
            <div className="font-bold">
              {lastResult.success
                ? `Başarılı! +${lastResult.newLevel} oldu!`
                : 'Başarısız! Seviye değişmedi.'}
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      <button
        onClick={() => setShowConfirm(true)}
        disabled={selectedLevel >= 10}
        className="gk-btn-gold w-full py-3 text-base"
      >
        {selectedLevel >= 10 ? '✅ Maksimum Seviye' : `⚒️ +${selectedLevel + 1} Güçlendir`}
      </button>

      <ConfirmModal
        isOpen={showConfirm}
        onClose={() => setShowConfirm(false)}
        onConfirm={handleEnhance}
        title="Güçlendirme"
        message={`${cost.toLocaleString()} altın harcayarak %${chance} şansla güçlendirmek istiyor musunuz?`}
        confirmText="Güçlendir"
        cancelText="İptal"
      />
    </motion.div>
  )
}
