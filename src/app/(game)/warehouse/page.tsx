// =====================================================
// app/(game)/warehouse/page.tsx - Depo ekranı
// =====================================================
'use client'

import { motion } from 'framer-motion'

const MOCK_MATERIALS = [
  { id: 'iron_ore', name: 'Demir Cevheri', emoji: '⛏️', quantity: 150, rarity: 'common' },
  { id: 'oak_wood', name: 'Meşe Odunu', emoji: '🪵', quantity: 85, rarity: 'common' },
  { id: 'healing_herb', name: 'Şifalı Ot', emoji: '🌿', quantity: 42, rarity: 'uncommon' },
  { id: 'crystal_shard', name: 'Kristal Parçası', emoji: '💠', quantity: 20, rarity: 'rare' },
  { id: 'honey', name: 'Bal', emoji: '🍯', quantity: 30, rarity: 'common' },
  { id: 'ancient_rune', name: 'Kadim Rune', emoji: '🔮', quantity: 5, rarity: 'epic' },
]

const RARITY_COLORS: Record<string, string> = {
  common: '#9ca3af',
  uncommon: '#22c55e',
  rare: '#3b82f6',
  epic: '#a855f7',
  legendary: '#f59e0b',
}

export default function WarehousePage() {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="p-4 space-y-4"
    >
      <div className="flex items-center justify-between">
        <h1 className="gk-title font-game text-xl">🏛️ Depo</h1>
        <span className="text-[#a8a8b8] text-sm">{MOCK_MATERIALS.length}/{50} slot</span>
      </div>

      {/* Depo doluluk */}
      <div className="gk-panel">
        <div className="flex justify-between text-xs text-[#a8a8b8] mb-2">
          <span>Kapasite</span>
          <span>{MOCK_MATERIALS.length}/50</span>
        </div>
        <div className="h-2 bg-[#12121a] rounded-full overflow-hidden">
          <div
            className="h-full rounded-full"
            style={{
              width: `${(MOCK_MATERIALS.length / 50) * 100}%`,
              background: 'linear-gradient(90deg, #1a6b2e, #22cc44)',
            }}
          />
        </div>
      </div>

      {/* Materyal listesi */}
      <div className="grid grid-cols-2 gap-3">
        {MOCK_MATERIALS.map((mat) => (
          <div key={mat.id} className="gk-panel flex items-center gap-3">
            <span className="text-2xl">{mat.emoji}</span>
            <div className="min-w-0">
              <div className="text-sm font-semibold truncate">{mat.name}</div>
              <div className="text-xs" style={{ color: RARITY_COLORS[mat.rarity] }}>
                {mat.quantity} adet
              </div>
            </div>
          </div>
        ))}
      </div>
    </motion.div>
  )
}
