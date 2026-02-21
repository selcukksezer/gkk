// =====================================================
// app/(game)/trade/page.tsx - Ticaret ekranı
// =====================================================
'use client'

import { motion } from 'framer-motion'

export default function TradePage() {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="p-4 space-y-4"
    >
      <h1 className="gk-title font-game text-xl">🤝 Ticaret</h1>

      <div className="gk-panel">
        <h2 className="text-amber-400 font-semibold mb-3">Oyuncu ile Ticaret</h2>
        <p className="text-[#a8a8b8] text-sm mb-4">
          Diğer oyuncularla eşya takası yapın.
        </p>
        <input
          type="text"
          placeholder="Oyuncu adı ara..."
          className="gk-input"
        />
        <button className="gk-btn-gold w-full mt-3 py-2">🔍 Ara</button>
      </div>

      <div className="gk-panel">
        <h2 className="text-amber-400 font-semibold mb-3">Son Teklifler</h2>
        <div className="text-center py-6">
          <div className="text-4xl mb-2">🤝</div>
          <p className="text-[#a8a8b8] text-sm">Gelen ticaret teklifi yok.</p>
        </div>
      </div>

      <div className="gk-panel">
        <p className="text-[#a8a8b8] text-xs text-center">
          ⚠️ Ticaret sistemi geliştirme aşamasında.
        </p>
      </div>
    </motion.div>
  )
}
