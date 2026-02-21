// =====================================================
// app/(game)/production/page.tsx - Üretim kuyruğu ekranı
// =====================================================
'use client'

import { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { formatCountdown } from '@/lib/utils/dateTimeUtils'

interface ProductionItem {
  id: string
  facilityName: string
  facilityEmoji: string
  recipeName: string
  quantity: number
  rarity: string
  completesAt: Date
  status: 'running' | 'completed'
}

const RARITY_COLORS: Record<string, string> = {
  common: '#9ca3af',
  uncommon: '#22c55e',
  rare: '#3b82f6',
  epic: '#a855f7',
  legendary: '#f59e0b',
}

export default function ProductionPage() {
  const [items, setItems] = useState<ProductionItem[]>([])
  const [tick, setTick] = useState(0)

  // Geri sayım güncelleme
  useEffect(() => {
    const interval = setInterval(() => setTick((t) => t + 1), 1000)
    return () => clearInterval(interval)
  }, [])

  const runningItems = items.filter((i) => i.status === 'running')
  const completedItems = items.filter((i) => i.status === 'completed')

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="p-4 space-y-4"
    >
      <div className="flex items-center justify-between">
        <h1 className="gk-title font-game text-xl">⚙️ Üretim Kuyruğu</h1>
        <span className="text-[#a8a8b8] text-sm">{runningItems.length} aktif</span>
      </div>

      {items.length === 0 ? (
        <div className="gk-panel text-center py-8">
          <div className="text-5xl mb-3">⚙️</div>
          <p className="text-[#a8a8b8] text-sm">Aktif üretim yok.</p>
          <p className="text-[#a8a8b8] text-xs mt-1">Tesisler sayfasından üretim başlatın.</p>
        </div>
      ) : (
        <AnimatePresence>
          {items.map((item) => {
            const remaining = Math.max(0, Math.floor((item.completesAt.getTime() - Date.now()) / 1000))
            const isComplete = remaining === 0

            return (
              <motion.div
                key={item.id}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: 20 }}
                className="gk-panel"
              >
                <div className="flex items-center gap-3">
                  <span className="text-2xl">{item.facilityEmoji}</span>
                  <div className="flex-1 min-w-0">
                    <div className="font-semibold text-sm">{item.recipeName}</div>
                    <div className="text-[#a8a8b8] text-xs">{item.facilityName} • {item.quantity} adet</div>
                    <div className="text-xs mt-1" style={{ color: RARITY_COLORS[item.rarity] ?? '#9ca3af' }}>
                      {item.rarity}
                    </div>
                  </div>
                  <div className="text-right flex-shrink-0">
                    {isComplete ? (
                      <button className="gk-btn-gold text-xs py-1 px-3">
                        Topla
                      </button>
                    ) : (
                      <div className="text-[#00aaff] font-mono text-sm">
                        {formatCountdown(remaining)}
                      </div>
                    )}
                  </div>
                </div>
              </motion.div>
            )
          })}
        </AnimatePresence>
      )}

      {completedItems.length > 0 && (
        <button className="gk-btn-gold w-full py-3">
          Tümünü Topla ({completedItems.length})
        </button>
      )}
    </motion.div>
  )
}
