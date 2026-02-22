// =====================================================
// app/(game)/crafting/page.tsx - El sanatları/üretim ekranı
// =====================================================
'use client'

import { useState } from 'react'
import { motion } from 'framer-motion'

const CRAFTING_CATEGORIES = [
  { id: 'potions', name: 'İksirler', emoji: '🧪' },
  { id: 'weapons', name: 'Silahlar', emoji: '⚔️' },
  { id: 'armor', name: 'Zırh', emoji: '🛡️' },
  { id: 'misc', name: 'Diğer', emoji: '📦' },
]

const CRAFTING_RECIPES = [
  { id: 'health_potion', cat: 'potions', name: 'Sağlık İksiri', emoji: '❤️', desc: 'Can yeniler', mats: 'Şifalı Ot ×3', gold: 50 },
  { id: 'energy_potion', cat: 'potions', name: 'Enerji İksiri', emoji: '⚡', desc: 'Enerji doldurur', mats: 'Enerji Çiçeği ×2', gold: 80 },
  { id: 'poison_potion', cat: 'potions', name: 'Zehir İksiri', emoji: '☠️', desc: 'PvP\'de kullan', mats: 'Zehirli Ot ×4', gold: 120 },
  { id: 'wooden_bow', cat: 'weapons', name: 'Ahşap Yay', emoji: '🏹', desc: '+15 Saldırı', mats: 'Ağaç ×3 + İp ×2', gold: 300 },
]

export default function CraftingPage() {
  const [activeCategory, setActiveCategory] = useState('potions')

  const filteredRecipes = CRAFTING_RECIPES.filter((r) => r.cat === activeCategory)

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="p-4 space-y-4"
    >
      <h1 className="gk-title font-game text-xl">✨ El Sanatları</h1>

      {/* Kategori sekmeleri */}
      <div className="flex gap-2 overflow-x-auto pb-1">
        {CRAFTING_CATEGORIES.map((cat) => (
          <button
            key={cat.id}
            onClick={() => setActiveCategory(cat.id)}
            className={`flex items-center gap-1.5 px-3 py-2 rounded-lg text-sm font-medium flex-shrink-0 transition-all ${
              activeCategory === cat.id
                ? 'bg-amber-500 text-black'
                : 'bg-[#1a1a26] text-[#a8a8b8]'
            }`}
          >
            <span>{cat.emoji}</span>
            <span>{cat.name}</span>
          </button>
        ))}
      </div>

      {/* Reçete listesi */}
      {filteredRecipes.length === 0 ? (
        <div className="gk-panel text-center py-8">
          <p className="text-[#a8a8b8]">Bu kategoride reçete yok.</p>
        </div>
      ) : (
        <div className="space-y-3">
          {filteredRecipes.map((recipe) => (
            <div key={recipe.id} className="gk-panel flex items-center gap-3">
              <span className="text-3xl">{recipe.emoji}</span>
              <div className="flex-1 min-w-0">
                <div className="font-semibold text-sm">{recipe.name}</div>
                <div className="text-[#a8a8b8] text-xs">{recipe.desc}</div>
                <div className="text-[#a8a8b8] text-xs mt-1">📦 {recipe.mats}</div>
              </div>
              <div className="flex-shrink-0 text-right">
                <div className="text-amber-400 text-xs font-bold">💰 {recipe.gold}</div>
                <button className="gk-btn-gold text-xs py-1 px-2 mt-1">Üret</button>
              </div>
            </div>
          ))}
        </div>
      )}
    </motion.div>
  )
}
