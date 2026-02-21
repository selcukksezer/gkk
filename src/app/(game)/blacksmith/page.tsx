// =====================================================
// app/(game)/blacksmith/page.tsx - Demirci ekranı
// GDScript BlacksmithScreen.gd'den dönüştürüldü
// =====================================================
'use client'

import { useState } from 'react'
import { motion } from 'framer-motion'

const SMITHING_RECIPES = [
  { id: 'iron_sword', name: 'Demir Kılıcı', emoji: '⚔️', materials: [{ name: 'Demir Cevheri', qty: 5 }, { name: 'Odun', qty: 2 }], result_stat: '+25 Saldırı', duration: '30dk', gold_cost: 200 },
  { id: 'steel_shield', name: 'Çelik Kalkan', emoji: '🛡️', materials: [{ name: 'Çelik İngo', qty: 3 }, { name: 'Deri', qty: 2 }], result_stat: '+30 Savunma', duration: '45dk', gold_cost: 350 },
  { id: 'chain_armor', name: 'Zincir Zırh', emoji: '🥋', materials: [{ name: 'Demir Cevheri', qty: 8 }, { name: 'Deri', qty: 4 }], result_stat: '+40 Savunma', duration: '1sa', gold_cost: 600 },
  { id: 'mithril_ring', name: 'Mithril Yüzük', emoji: '💍', materials: [{ name: 'Mithril', qty: 2 }, { name: 'Enerji Taşı', qty: 1 }], result_stat: '+15 Güç', duration: '2sa', gold_cost: 1200 },
]

export default function BlacksmithPage() {
  const [selectedRecipe, setSelectedRecipe] = useState<typeof SMITHING_RECIPES[0] | null>(null)

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="p-4 space-y-4"
    >
      <h1 className="gk-title font-game text-xl">🔨 Demirci</h1>

      <div className="space-y-3">
        {SMITHING_RECIPES.map((recipe) => (
          <motion.div
            key={recipe.id}
            whileTap={{ scale: 0.98 }}
            onClick={() => setSelectedRecipe(recipe === selectedRecipe ? null : recipe)}
            className={`gk-panel cursor-pointer transition-all ${
              selectedRecipe?.id === recipe.id ? 'border-amber-500' : ''
            }`}
          >
            <div className="flex items-center gap-3">
              <span className="text-3xl">{recipe.emoji}</span>
              <div className="flex-1">
                <div className="font-semibold">{recipe.name}</div>
                <div className="text-green-400 text-xs">{recipe.result_stat}</div>
                <div className="text-[#a8a8b8] text-xs mt-1">⏱ {recipe.duration} • 💰 {recipe.gold_cost}</div>
              </div>
              <span className="text-[#a8a8b8] text-sm">{selectedRecipe?.id === recipe.id ? '▲' : '▼'}</span>
            </div>

            {selectedRecipe?.id === recipe.id && (
              <motion.div
                initial={{ height: 0, opacity: 0 }}
                animate={{ height: 'auto', opacity: 1 }}
                className="mt-3 pt-3 border-t border-[#2a2a3a]"
              >
                <div className="text-xs text-[#a8a8b8] mb-2">Gerekli Malzemeler:</div>
                <div className="flex flex-wrap gap-2 mb-3">
                  {recipe.materials.map((mat) => (
                    <span key={mat.name} className="text-xs bg-[#12121a] px-2 py-1 rounded-full">
                      {mat.name} ×{mat.qty}
                    </span>
                  ))}
                </div>
                <button className="gk-btn-gold w-full py-2 text-sm">
                  🔨 Üret
                </button>
              </motion.div>
            )}
          </motion.div>
        ))}
      </div>
    </motion.div>
  )
}
