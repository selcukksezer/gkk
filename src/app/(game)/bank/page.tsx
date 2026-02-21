// =====================================================
// app/(game)/bank/page.tsx - Banka ekranı
// =====================================================
'use client'

import { motion } from 'framer-motion'
import { usePlayerStore } from '@/store/playerStore'
import { formatNumber } from '@/lib/utils/mathUtils'

export default function BankPage() {
  const { gold, gems } = usePlayerStore()

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="p-4 space-y-4"
    >
      <h1 className="gk-title font-game text-xl">🏦 Banka</h1>

      <div className="gk-panel">
        <h2 className="text-amber-400 font-semibold mb-4">Bakiye</h2>
        <div className="grid grid-cols-2 gap-4">
          <div className="text-center p-4 bg-[#12121a] rounded-xl">
            <div className="text-3xl mb-1">💰</div>
            <div className="text-amber-400 font-bold text-xl">{formatNumber(gold)}</div>
            <div className="text-[#a8a8b8] text-xs mt-1">Altın</div>
          </div>
          <div className="text-center p-4 bg-[#12121a] rounded-xl">
            <div className="text-3xl mb-1">💎</div>
            <div className="text-blue-300 font-bold text-xl">{formatNumber(gems)}</div>
            <div className="text-[#a8a8b8] text-xs mt-1">Elmas</div>
          </div>
        </div>
      </div>

      <div className="gk-panel">
        <h2 className="text-amber-400 font-semibold mb-3">İşlemler</h2>
        <div className="space-y-2">
          {[
            { icon: '⬆️', label: 'Para Yatır', desc: 'Altını bankaya yatır, güvende tut' },
            { icon: '⬇️', label: 'Para Çek', desc: 'Bankadan altın çek' },
            { icon: '💱', label: 'Döviz Çevir', desc: 'Elmas ↔ Altın değişimi' },
          ].map((item) => (
            <button
              key={item.label}
              className="w-full flex items-center gap-3 p-3 bg-[#12121a] rounded-xl hover:bg-[#1e1e2a] transition-colors text-left"
            >
              <span className="text-2xl">{item.icon}</span>
              <div>
                <div className="font-semibold text-sm">{item.label}</div>
                <div className="text-[#a8a8b8] text-xs">{item.desc}</div>
              </div>
            </button>
          ))}
        </div>
      </div>

      <div className="gk-panel">
        <p className="text-[#a8a8b8] text-sm text-center">
          🔒 Banka sistemi yakında aktif olacak!
        </p>
      </div>
    </motion.div>
  )
}
