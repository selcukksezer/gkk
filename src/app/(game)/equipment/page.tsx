// =====================================================
// app/(game)/equipment/page.tsx - Ekipman ekranı
// GDScript EquipmentScreen.gd'den dönüştürüldü
// =====================================================
'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { motion, AnimatePresence } from 'framer-motion'
import { usePlayerStore } from '@/store/playerStore'
import { Modal, InfoModal } from '@/components/ui/Modal'
import type { ItemSlotType, InventoryItem } from '@/types/item'

interface EquipmentSlotDef {
  slot: ItemSlotType
  label: string
  emoji: string
  description: string
}

const EQUIPMENT_SLOTS: EquipmentSlotDef[] = [
  { slot: 'head', label: 'Baş', emoji: '🪖', description: 'Kask, miğfer veya şapka' },
  { slot: 'chest', label: 'Göğüs', emoji: '👕', description: 'Zırh veya kıyafet' },
  { slot: 'legs', label: 'Bacak', emoji: '👖', description: 'Pantolon veya zırh' },
  { slot: 'hands', label: 'El', emoji: '🧤', description: 'Eldiven veya bilezik' },
  { slot: 'feet', label: 'Ayak', emoji: '👟', description: 'Bot veya sandalet' },
  { slot: 'weapon', label: 'Silah', emoji: '🗡️', description: 'Ana silah' },
  { slot: 'offhand', label: 'Kalkan', emoji: '🛡️', description: 'Kalkan veya ikinci silah' },
  { slot: 'ring1', label: 'Yüzük I', emoji: '💍', description: 'Birinci yüzük slotu' },
  { slot: 'ring2', label: 'Yüzük II', emoji: '💍', description: 'İkinci yüzük slotu' },
  { slot: 'necklace', label: 'Kolye', emoji: '📿', description: 'Kolye veya madalyon' },
]

const RARITY_COLORS: Record<string, string> = {
  common: '#a8a8b8',
  uncommon: '#22c55e',
  rare: '#3b82f6',
  epic: '#8b5cf6',
  legendary: '#f59e0b',
  mythic: '#ef4444',
}

const RARITY_NAMES: Record<string, string> = {
  common: 'Yaygın',
  uncommon: 'Nadir Olmayan',
  rare: 'Nadir',
  epic: 'Epik',
  legendary: 'Efsanevi',
  mythic: 'Mitik',
}

// Total stats from equipped items
function calculateTotalStats(equipment: Record<string, InventoryItem>): Record<string, number> {
  const totals: Record<string, number> = {}
  Object.values(equipment).forEach((item) => {
    if (item.item_data?.stats) {
      Object.entries(item.item_data.stats).forEach(([stat, val]) => {
        totals[stat] = (totals[stat] ?? 0) + (val as number)
      })
    }
  })
  return totals
}

export default function EquipmentPage() {
  const router = useRouter()
  const { equipment, inventory, player } = usePlayerStore((s) => ({
    equipment: s.equipment,
    inventory: s.inventory,
    player: s.player,
  }))

  const [selectedSlot, setSelectedSlot] = useState<EquipmentSlotDef | null>(null)
  const [showSlotModal, setShowSlotModal] = useState(false)
  const [infoMessage, setInfoMessage] = useState('')
  const [showInfo, setShowInfo] = useState(false)

  const totalStats = calculateTotalStats(equipment)

  const handleSlotPress = (slot: EquipmentSlotDef) => {
    setSelectedSlot(slot)
    setShowSlotModal(true)
  }

  const equippedInSlot = selectedSlot ? equipment[selectedSlot.slot] : null
  const availableItems = inventory.filter((item) =>
    item.item_data?.slot === selectedSlot?.slot && !item.is_equipped
  )

  return (
    <>
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.3 }}
        className="px-4 pt-4 pb-4 max-w-[480px] mx-auto"
      >
        {/* Geri butonu */}
        <button
          onClick={() => router.back()}
          className="flex items-center gap-2 text-gk-silver hover:text-white mb-4 transition-colors"
        >
          ← Geri
        </button>

        {/* Başlık */}
        <div className="flex items-center gap-2 mb-4">
          <span className="text-3xl">🗡️</span>
          <div>
            <h1 className="gk-title text-xl">Ekipman</h1>
            <p className="text-gk-silver text-xs">Karakterini donat</p>
          </div>
          <div className="ml-auto">
            <div className="gk-badge bg-gk-surface text-gk-silver">
              {Object.keys(equipment).length}/{EQUIPMENT_SLOTS.length} Slot
            </div>
          </div>
        </div>

        {/* Karakter önizleme */}
        <div className="gk-panel text-center mb-4 relative overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-b from-gk-gold/5 to-transparent" />
          <motion.div
            animate={{ y: [0, -4, 0] }}
            transition={{ repeat: Infinity, duration: 3 }}
            className="text-7xl mb-3"
          >
            🧙
          </motion.div>
          <p className="text-white font-bold">{player?.display_name ?? 'Oyuncu'}</p>
          <div className="flex justify-center gap-4 mt-2">
            <span className="text-gk-silver text-xs">💪 {player?.power ?? 0} Güç</span>
            <span className="text-gk-silver text-xs">🛡️ {player?.defense ?? 0} Savunma</span>
            <span className="text-gk-silver text-xs">⚔️ {player?.attack ?? 0} Saldırı</span>
          </div>
        </div>

        {/* Toplam istatistikler (eğer ekipman varsa) */}
        {Object.keys(totalStats).length > 0 && (
          <div className="gk-panel mb-4">
            <h2 className="text-gk-silver text-xs font-bold mb-2 uppercase tracking-wider">Ekipman Bonusları</h2>
            <div className="grid grid-cols-2 gap-2">
              {Object.entries(totalStats).map(([stat, val]) => (
                <div key={stat} className="flex justify-between bg-gk-surface rounded-lg px-3 py-1.5">
                  <span className="text-gk-silver text-xs capitalize">{stat}</span>
                  <span className="text-green-400 text-xs font-bold">+{val}</span>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Ekipman slotları */}
        <div className="grid grid-cols-2 gap-3">
          {EQUIPMENT_SLOTS.map((slotDef, i) => {
            const item = equipment[slotDef.slot]

            return (
              <motion.div
                key={slotDef.slot}
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: i * 0.05 }}
                onClick={() => handleSlotPress(slotDef)}
                className={`gk-panel cursor-pointer active:scale-95 transition-transform ${
                  item ? 'border-gk-gold/40' : 'border-gk-border/50 opacity-70'
                }`}
              >
                <div className="flex items-center gap-3">
                  <div
                    className={`w-12 h-12 rounded-xl flex items-center justify-center text-2xl flex-shrink-0 ${
                      item ? 'bg-gk-gold/10 border border-gk-gold/40' : 'bg-gk-surface border border-gk-border'
                    }`}
                  >
                    {item ? (item.item_data?.icon ?? slotDef.emoji) : slotDef.emoji}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-gk-silver text-xs">{slotDef.label}</p>
                    {item ? (
                      <>
                        <p
                          className="text-xs font-bold truncate"
                          style={{ color: item.item_data?.rarity ? RARITY_COLORS[item.item_data.rarity] : '#a8a8b8' }}
                        >
                          {item.item_data?.name ?? 'Ekipman'}
                        </p>
                        {item.enhancement_level > 0 && (
                          <p className="text-gk-gold text-xs">+{item.enhancement_level}</p>
                        )}
                      </>
                    ) : (
                      <p className="text-gk-border text-xs">Boş slot</p>
                    )}
                  </div>
                </div>
              </motion.div>
            )
          })}
        </div>

        {/* Envantere git */}
        <div className="mt-4">
          <button
            onClick={() => router.push('/inventory')}
            className="gk-btn-secondary w-full"
          >
            📦 Envanterden Ekipman Seç
          </button>
        </div>
      </motion.div>

      {/* Slot detay modalı */}
      {selectedSlot && (
        <Modal
          isOpen={showSlotModal}
          onClose={() => setShowSlotModal(false)}
          title={`${selectedSlot.emoji} ${selectedSlot.label} Slotu`}
          size="lg"
        >
          <div className="space-y-4">
            <p className="text-gk-silver text-sm">{selectedSlot.description}</p>

            {/* Mevcut ekipman */}
            {equippedInSlot ? (
              <div>
                <p className="text-gk-silver text-xs font-bold mb-2 uppercase tracking-wider">Takılı Ekipman</p>
                <div
                  className="bg-gk-surface rounded-xl p-3 border"
                  style={{ borderColor: equippedInSlot.item_data?.rarity ? RARITY_COLORS[equippedInSlot.item_data.rarity] + '66' : '#2a2a3a' }}
                >
                  <div className="flex items-center gap-3">
                    <div className="text-3xl">{equippedInSlot.item_data?.icon ?? selectedSlot.emoji}</div>
                    <div className="flex-1">
                      <p className="text-white font-bold">{equippedInSlot.item_data?.name ?? 'Ekipman'}</p>
                      {equippedInSlot.item_data?.rarity && (
                        <p className="text-xs" style={{ color: RARITY_COLORS[equippedInSlot.item_data.rarity] }}>
                          {RARITY_NAMES[equippedInSlot.item_data.rarity]}
                          {equippedInSlot.enhancement_level > 0 ? ` +${equippedInSlot.enhancement_level}` : ''}
                        </p>
                      )}
                    </div>
                  </div>
                  {equippedInSlot.item_data?.stats && Object.keys(equippedInSlot.item_data.stats).length > 0 && (
                    <div className="mt-2 grid grid-cols-2 gap-1">
                      {Object.entries(equippedInSlot.item_data.stats).map(([stat, val]) => (
                        <div key={stat} className="flex justify-between text-xs bg-gk-panel rounded px-2 py-1">
                          <span className="text-gk-silver capitalize">{stat}</span>
                          <span className="text-green-400 font-bold">+{val as number}</span>
                        </div>
                      ))}
                    </div>
                  )}
                  <button
                    className="gk-btn-danger w-full mt-3 text-sm"
                    onClick={() => { setShowSlotModal(false); setInfoMessage('Ekipman çıkarma özelliği yakında.'); setShowInfo(true) }}
                  >
                    🔓 Çıkar
                  </button>
                </div>
              </div>
            ) : (
              <div className="bg-gk-surface rounded-xl p-4 text-center">
                <p className="text-4xl mb-2 opacity-30">{selectedSlot.emoji}</p>
                <p className="text-gk-silver text-sm">Bu slot boş</p>
              </div>
            )}

            {/* Mevcut eşyalar */}
            {availableItems.length > 0 && (
              <div>
                <p className="text-gk-silver text-xs font-bold mb-2 uppercase tracking-wider">
                  Takılabilir Eşyalar ({availableItems.length})
                </p>
                <div className="space-y-2 max-h-40 overflow-y-auto">
                  {availableItems.map((item) => (
                    <div key={item.id} className="flex items-center gap-3 bg-gk-surface rounded-lg p-2">
                      <span className="text-xl">{item.item_data?.icon ?? '📦'}</span>
                      <div className="flex-1">
                        <p className="text-white text-sm font-bold">{item.item_data?.name ?? 'Eşya'}</p>
                        {item.item_data?.rarity && (
                          <p className="text-xs" style={{ color: RARITY_COLORS[item.item_data.rarity] }}>
                            {RARITY_NAMES[item.item_data.rarity]}
                          </p>
                        )}
                      </div>
                      <button
                        className="gk-btn-gold text-xs px-2 py-1"
                        onClick={() => { setShowSlotModal(false); setInfoMessage('Ekipman takma özelliği yakında.'); setShowInfo(true) }}
                      >
                        Giy
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            )}

            <button onClick={() => setShowSlotModal(false)} className="gk-btn-secondary w-full">
              Kapat
            </button>
          </div>
        </Modal>
      )}

      <InfoModal isOpen={showInfo} onClose={() => setShowInfo(false)} message={infoMessage} />
    </>
  )
}
