// =====================================================
// app/(game)/inventory/page.tsx - Envanter ekranı
// GDScript InventoryScreen.gd'den dönüştürüldü
// =====================================================
'use client'

import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { usePlayerStore } from '@/store/playerStore'
import { Modal } from '@/components/ui/Modal'
import type { InventoryItem, ItemSlotType } from '@/types/item'

type FilterType = 'all' | 'weapon' | 'armor' | 'consumable' | 'material'

const FILTER_LABELS: Record<FilterType, string> = {
  all: '📦 Tümü',
  weapon: '🗡️ Silah',
  armor: '🛡️ Zırh',
  consumable: '⚗️ İksir',
  material: '🔩 Malzeme',
}

const RARITY_COLORS: Record<string, string> = {
  common: '#a8a8b8',
  uncommon: '#22c55e',
  rare: '#3b82f6',
  epic: '#8b5cf6',
  legendary: '#f59e0b',
  mythic: '#ef4444',
}

const EQUIPMENT_SLOTS: Array<{ slot: ItemSlotType; label: string; emoji: string }> = [
  { slot: 'head', label: 'Baş', emoji: '🪖' },
  { slot: 'chest', label: 'Göğüs', emoji: '👕' },
  { slot: 'legs', label: 'Bacak', emoji: '👖' },
  { slot: 'hands', label: 'El', emoji: '🧤' },
  { slot: 'feet', label: 'Ayak', emoji: '👟' },
  { slot: 'weapon', label: 'Silah', emoji: '🗡️' },
  { slot: 'offhand', label: 'Kalkan', emoji: '🛡️' },
  { slot: 'ring1', label: 'Yüzük 1', emoji: '💍' },
  { slot: 'ring2', label: 'Yüzük 2', emoji: '💍' },
  { slot: 'necklace', label: 'Kolye', emoji: '📿' },
]

const INVENTORY_SIZE = 40

export default function InventoryPage() {
  const { inventory, equipment } = usePlayerStore((s) => ({
    inventory: s.inventory,
    equipment: s.equipment,
  }))

  const [activeFilter, setActiveFilter] = useState<FilterType>('all')
  const [selectedItem, setSelectedItem] = useState<InventoryItem | null>(null)
  const [showItemDetail, setShowItemDetail] = useState(false)
  const [activeTab, setActiveTab] = useState<'inventory' | 'equipment'>('inventory')

  const filteredInventory = inventory.filter((item) => {
    if (activeFilter === 'all') return true
    const type = item.item_data?.type ?? ''
    if (activeFilter === 'weapon') return type === 'weapon'
    if (activeFilter === 'armor') return ['armor', 'helmet', 'shield', 'boots', 'gloves'].includes(type)
    if (activeFilter === 'consumable') return type === 'consumable'
    if (activeFilter === 'material') return type === 'material'
    return true
  })

  const handleItemPress = (item: InventoryItem) => {
    setSelectedItem(item)
    setShowItemDetail(true)
  }

  const filledSlots = filteredInventory.length
  const emptySlots = Math.max(0, INVENTORY_SIZE - filledSlots)

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
          <span className="text-3xl">📦</span>
          <div>
            <h1 className="gk-title text-xl">Envanter</h1>
            <p className="text-gk-silver text-xs">{filledSlots}/{INVENTORY_SIZE} slot dolu</p>
          </div>
        </div>

        {/* Ana sekmeler */}
        <div className="flex bg-gk-surface rounded-xl p-1 mb-4 gap-1">
          {(['inventory', 'equipment'] as const).map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`flex-1 py-2 rounded-lg text-sm font-semibold transition-all ${
                activeTab === tab ? 'bg-gk-gold text-gk-darker' : 'text-gk-silver hover:text-white'
              }`}
            >
              {tab === 'inventory' ? '📦 Eşyalar' : '🗡️ Ekipman'}
            </button>
          ))}
        </div>

        <AnimatePresence mode="wait">
          {activeTab === 'inventory' && (
            <motion.div key="inv" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
              {/* Filtreler */}
              <div className="flex gap-2 mb-4 overflow-x-auto pb-1">
                {(Object.keys(FILTER_LABELS) as FilterType[]).map((f) => (
                  <button
                    key={f}
                    onClick={() => setActiveFilter(f)}
                    className={`whitespace-nowrap px-3 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                      activeFilter === f ? 'bg-gk-gold text-gk-darker' : 'bg-gk-surface text-gk-silver hover:text-white'
                    }`}
                  >
                    {FILTER_LABELS[f]}
                  </button>
                ))}
              </div>

              {/* Eşya grid */}
              <div className="grid grid-cols-5 gap-2">
                {filteredInventory.map((item, i) => (
                  <motion.div
                    key={item.id}
                    initial={{ opacity: 0, scale: 0.8 }}
                    animate={{ opacity: 1, scale: 1 }}
                    transition={{ delay: i * 0.02 }}
                    onClick={() => handleItemPress(item)}
                    className="aspect-square bg-gk-surface border border-gk-border rounded-xl flex flex-col items-center justify-center cursor-pointer active:scale-95 transition-transform relative overflow-hidden"
                    style={{
                      borderColor: item.item_data?.rarity ? RARITY_COLORS[item.item_data.rarity] + '66' : undefined,
                    }}
                  >
                    <span className="text-xl">{item.item_data?.icon ?? '📦'}</span>
                    {item.quantity > 1 && (
                      <span className="absolute bottom-0.5 right-1 text-white text-xs font-bold">{item.quantity}</span>
                    )}
                    {item.enhancement_level > 0 && (
                      <span className="absolute top-0.5 right-1 text-gk-gold text-xs font-bold">+{item.enhancement_level}</span>
                    )}
                    {item.is_equipped && (
                      <div className="absolute inset-0 border-2 border-gk-gold rounded-xl opacity-60" />
                    )}
                  </motion.div>
                ))}

                {/* Boş slotlar */}
                {Array.from({ length: Math.min(emptySlots, 10) }).map((_, i) => (
                  <div
                    key={`empty-${i}`}
                    className="aspect-square bg-gk-surface/30 border border-gk-border/30 rounded-xl flex items-center justify-center"
                  >
                    <span className="text-gk-border text-lg">+</span>
                  </div>
                ))}
              </div>

              {inventory.length === 0 && (
                <div className="text-center py-12">
                  <div className="text-6xl mb-3">📦</div>
                  <p className="text-gk-silver">Envanteriniz boş</p>
                  <p className="text-gk-silver text-xs mt-1">Zindanları tamamlayarak eşya kazanın</p>
                </div>
              )}
            </motion.div>
          )}

          {activeTab === 'equipment' && (
            <motion.div key="equip" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
              <div className="gk-panel mb-3">
                <p className="text-gk-silver text-xs text-center mb-4">Giyilen ekipmanlarınız</p>
                <div className="grid grid-cols-2 gap-3">
                  {EQUIPMENT_SLOTS.map((s) => {
                    const equipped = equipment[s.slot]
                    return (
                      <div
                        key={s.slot}
                        className={`flex items-center gap-3 bg-gk-surface rounded-xl p-3 border ${
                          equipped ? 'border-gk-gold/50' : 'border-gk-border/50'
                        }`}
                      >
                        <div className="w-10 h-10 rounded-lg bg-gk-panel border border-gk-border flex items-center justify-center text-xl">
                          {equipped ? (equipped.item_data?.icon ?? s.emoji) : s.emoji}
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="text-gk-silver text-xs">{s.label}</p>
                          {equipped ? (
                            <p className="text-white text-xs font-bold truncate">
                              {equipped.item_data?.name ?? 'Ekipman'}
                              {equipped.enhancement_level > 0 ? ` +${equipped.enhancement_level}` : ''}
                            </p>
                          ) : (
                            <p className="text-gk-border text-xs">Boş</p>
                          )}
                        </div>
                      </div>
                    )
                  })}
                </div>
              </div>
              <p className="text-gk-silver text-xs text-center">
                Eşya takıp çıkarmak için envanterden eşyaya tıklayın
              </p>
            </motion.div>
          )}
        </AnimatePresence>
      </motion.div>

      {/* Eşya detay modalı */}
      {selectedItem && (
        <Modal
          isOpen={showItemDetail}
          onClose={() => setShowItemDetail(false)}
          title={selectedItem.item_data?.name ?? 'Eşya'}
          size="md"
        >
          <div className="space-y-4">
            <div className="text-center">
              <div className="text-5xl mb-2">{selectedItem.item_data?.icon ?? '📦'}</div>
              {selectedItem.item_data?.rarity && (
                <span
                  className="gk-badge text-xs font-bold"
                  style={{ color: RARITY_COLORS[selectedItem.item_data.rarity], background: RARITY_COLORS[selectedItem.item_data.rarity] + '22' }}
                >
                  {selectedItem.item_data.rarity.toUpperCase()}
                </span>
              )}
            </div>
            {selectedItem.item_data?.description && (
              <p className="text-gk-silver text-sm text-center">{selectedItem.item_data.description}</p>
            )}
            {selectedItem.item_data?.stats && Object.keys(selectedItem.item_data.stats).length > 0 && (
              <div className="bg-gk-surface rounded-lg p-3 space-y-1">
                {Object.entries(selectedItem.item_data.stats).map(([stat, val]) => (
                  <div key={stat} className="flex justify-between text-sm">
                    <span className="text-gk-silver capitalize">{stat}</span>
                    <span className="text-green-400 font-bold">+{val}</span>
                  </div>
                ))}
              </div>
            )}
            <div className="flex gap-3">
              <button onClick={() => setShowItemDetail(false)} className="gk-btn-secondary flex-1">
                Kapat
              </button>
              <button className="gk-btn-gold flex-1">
                {selectedItem.is_equipped ? '🔓 Çıkar' : '⚔️ Giy'}
              </button>
            </div>
          </div>
        </Modal>
      )}
    </>
  )
}
