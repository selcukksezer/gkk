// =====================================================
// app/(game)/shop/page.tsx - Dükkân ekranı
// GDScript ShopScreen.gd'den dönüştürüldü
// =====================================================
'use client'

import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { usePlayerStore } from '@/store/playerStore'
import { formatNumber } from '@/lib/utils/mathUtils'
import { Modal, InfoModal } from '@/components/ui/Modal'

type TabType = 'gems' | 'gold' | 'special'

interface ShopItem {
  id: string
  name: string
  description: string
  icon: string
  price: number
  currency: 'real' | 'gems' | 'gold'
  priceLabel: string
  bonus?: string
  tag?: string
  color?: string
}

const GEM_PACKAGES: ShopItem[] = [
  { id: 'gems_starter', name: 'Başlangıç Paketi', description: '100 Elmas', icon: '💎', price: 0.99, currency: 'real', priceLabel: '₺9.99', color: '#3b82f6' },
  { id: 'gems_small', name: 'Küçük Paket', description: '500 Elmas', icon: '💎', price: 4.99, currency: 'real', priceLabel: '₺49.99', color: '#3b82f6' },
  { id: 'gems_medium', name: 'Orta Paket', description: '1.200 Elmas', icon: '💎', price: 9.99, currency: 'real', priceLabel: '₺99.99', bonus: '+200 Bonus', color: '#8b5cf6', tag: 'Popüler' },
  { id: 'gems_large', name: 'Büyük Paket', description: '2.800 Elmas', icon: '💎', price: 19.99, currency: 'real', priceLabel: '₺199.99', bonus: '+600 Bonus', color: '#f59e0b' },
  { id: 'gems_mega', name: 'Mega Paket', description: '6.500 Elmas', icon: '💎', price: 49.99, currency: 'real', priceLabel: '₺499.99', bonus: '+1.500 Bonus', color: '#ef4444', tag: 'En İyi Değer' },
  { id: 'gems_ultra', name: 'Ultra Paket', description: '15.000 Elmas', icon: '💎', price: 99.99, currency: 'real', priceLabel: '₺999.99', bonus: '+5.000 Bonus', color: '#ffd700', tag: '🔥 Fırsat' },
]

const GOLD_PACKAGES: ShopItem[] = [
  { id: 'gold_small', name: 'Küçük Kese', description: '10.000 Altın', icon: '💰', price: 50, currency: 'gems', priceLabel: '50 💎', color: '#d4a017' },
  { id: 'gold_medium', name: 'Orta Kese', description: '50.000 Altın', icon: '💰', price: 200, currency: 'gems', priceLabel: '200 💎', bonus: '+5.000 Bonus', color: '#d4a017', tag: 'Popüler' },
  { id: 'gold_large', name: 'Büyük Kese', description: '150.000 Altın', icon: '💰', price: 500, currency: 'gems', priceLabel: '500 💎', bonus: '+25.000 Bonus', color: '#d4a017' },
  { id: 'gold_mega', name: 'Hazine Sandığı', description: '500.000 Altın', icon: '💰', price: 1500, currency: 'gems', priceLabel: '1.500 💎', bonus: '+100.000 Bonus', color: '#ffd700', tag: 'En İyi Değer' },
]

const SPECIAL_OFFERS: ShopItem[] = [
  {
    id: 'starter_bundle', name: 'Başlangıç Paketi', icon: '🎁',
    description: '500 Altın + 50 Elmas + Başlangıç Zırhı',
    price: 0, currency: 'real', priceLabel: '₺4.99',
    bonus: 'Tek seferlik teklif!', tag: '⏰ Sınırlı', color: '#22c55e',
  },
  {
    id: 'hero_bundle', name: 'Kahraman Paketi', icon: '⚔️',
    description: '5.000 Altın + 500 Elmas + Enerji Dolumu + Nadir Kılıç',
    price: 0, currency: 'real', priceLabel: '₺49.99',
    bonus: '%50 indirim!', tag: '🔥 Çok Satılan', color: '#f59e0b',
  },
  {
    id: 'energy_pack', name: 'Enerji Paketi', icon: '⚡',
    description: '100 Enerji + 3 Günlük Enerji Artışı',
    price: 100, currency: 'gems', priceLabel: '100 💎',
    color: '#00aaff',
  },
  {
    id: 'vip_week', name: 'VIP Haftalık', icon: '👑',
    description: 'Günlük bonus altın, 2x enerji, özel çerçeve',
    price: 0, currency: 'real', priceLabel: '₺19.99',
    bonus: '7 günlük', tag: '⭐ VIP', color: '#ffd700',
  },
]

export default function ShopPage() {
  const { gems, gold } = usePlayerStore((s) => ({ gems: s.gems, gold: s.gold }))

  const [activeTab, setActiveTab] = useState<TabType>('gems')
  const [selectedItem, setSelectedItem] = useState<ShopItem | null>(null)
  const [showPurchaseModal, setShowPurchaseModal] = useState(false)
  const [infoMessage, setInfoMessage] = useState('')
  const [showInfo, setShowInfo] = useState(false)

  const handlePurchase = (item: ShopItem) => {
    setSelectedItem(item)
    setShowPurchaseModal(true)
  }

  const handleConfirmPurchase = () => {
    setShowPurchaseModal(false)
    if (selectedItem?.currency === 'real') {
      setInfoMessage('Gerçek para ödemesi demo modunda kullanılamaz. Yakında aktif olacak!')
    } else {
      setInfoMessage(`${selectedItem?.name} satın alındı! (Demo modu)`)
    }
    setShowInfo(true)
  }

  const renderItems = (items: ShopItem[]) => (
    <div className="space-y-3">
      {items.map((item, i) => (
        <motion.div
          key={item.id}
          initial={{ opacity: 0, x: -20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: i * 0.06 }}
          className="gk-panel relative overflow-hidden cursor-pointer active:scale-98"
          onClick={() => handlePurchase(item)}
        >
          {item.tag && (
            <div
              className="absolute top-0 right-0 px-2 py-0.5 text-xs font-bold text-white rounded-bl-lg"
              style={{ background: item.color ?? '#d4a017' }}
            >
              {item.tag}
            </div>
          )}

          <div className="flex items-center gap-4">
            <div
              className="w-14 h-14 rounded-2xl flex items-center justify-center text-3xl flex-shrink-0"
              style={{ background: (item.color ?? '#3b82f6') + '33', border: `2px solid ${(item.color ?? '#3b82f6')}55` }}
            >
              {item.icon}
            </div>
            <div className="flex-1">
              <h3 className="text-white font-bold">{item.name}</h3>
              <p className="text-gk-silver text-sm">{item.description}</p>
              {item.bonus && (
                <p className="text-green-400 text-xs font-bold mt-0.5">+ {item.bonus}</p>
              )}
            </div>
            <div className="flex-shrink-0 text-right">
              <button
                className="gk-btn-gold text-sm px-4 py-2"
                style={{ background: item.color }}
              >
                {item.priceLabel}
              </button>
            </div>
          </div>
        </motion.div>
      ))}
    </div>
  )

  return (
    <>
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.3 }}
        className="px-4 pt-4 pb-2 max-w-[480px] mx-auto"
      >
        {/* Başlık */}
        <div className="flex items-center gap-2 mb-2">
          <span className="text-3xl">🏪</span>
          <div>
            <h1 className="gk-title text-xl">Dükkân</h1>
            <p className="text-gk-silver text-xs">Premium içerik ve paketler</p>
          </div>
        </div>

        {/* Bakiye */}
        <div className="flex gap-3 mb-4">
          <div className="gk-panel flex-1 flex items-center gap-2 py-2">
            <span className="text-gk-gold text-lg">💰</span>
            <div>
              <p className="text-gk-gold font-bold text-sm">{formatNumber(gold)}</p>
              <p className="text-gk-silver text-xs">Altın</p>
            </div>
          </div>
          <div className="gk-panel flex-1 flex items-center gap-2 py-2">
            <span className="text-blue-400 text-lg">💎</span>
            <div>
              <p className="text-blue-400 font-bold text-sm">{formatNumber(gems)}</p>
              <p className="text-gk-silver text-xs">Elmas</p>
            </div>
          </div>
        </div>

        {/* Sekmeler */}
        <div className="flex bg-gk-surface rounded-xl p-1 mb-4 gap-1">
          {(['gems', 'gold', 'special'] as TabType[]).map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`flex-1 py-2 rounded-lg text-xs font-semibold transition-all ${
                activeTab === tab ? 'bg-gk-gold text-gk-darker' : 'text-gk-silver hover:text-white'
              }`}
            >
              {tab === 'gems' ? '💎 Elmas' : tab === 'gold' ? '💰 Altın' : '🎁 Özel'}
            </button>
          ))}
        </div>

        <AnimatePresence mode="wait">
          <motion.div key={activeTab} initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
            {activeTab === 'gems' && renderItems(GEM_PACKAGES)}
            {activeTab === 'gold' && renderItems(GOLD_PACKAGES)}
            {activeTab === 'special' && (
              <>
                <div className="gk-panel border border-gk-gold bg-gk-gold/5 mb-4 p-3 text-center">
                  <p className="text-gk-gold font-bold">🎉 Özel Teklifler</p>
                  <p className="text-gk-silver text-xs mt-1">Sınırlı süreli fırsatlar! Kaçırmayın.</p>
                </div>
                {renderItems(SPECIAL_OFFERS)}
              </>
            )}
          </motion.div>
        </AnimatePresence>

        {/* Alt not */}
        <p className="text-gk-silver text-xs text-center mt-4 pb-2">
          🔒 Tüm ödemeler güvenli şekilde işlenir. Satın alımlar iade edilemez.
        </p>
      </motion.div>

      {/* Satın alma modalı */}
      {selectedItem && (
        <Modal
          isOpen={showPurchaseModal}
          onClose={() => setShowPurchaseModal(false)}
          title="Satın Al"
          size="sm"
        >
          <div className="space-y-4">
            <div className="text-center">
              <div className="text-5xl mb-3">{selectedItem.icon}</div>
              <h3 className="text-white font-bold text-lg">{selectedItem.name}</h3>
              <p className="text-gk-silver text-sm mt-1">{selectedItem.description}</p>
              {selectedItem.bonus && (
                <p className="text-green-400 text-sm font-bold mt-1">+ {selectedItem.bonus}</p>
              )}
            </div>
            <div className="bg-gk-surface rounded-lg p-3 text-center">
              <p className="text-gk-gold font-bold text-xl">{selectedItem.priceLabel}</p>
            </div>
            <div className="flex gap-3">
              <button onClick={() => setShowPurchaseModal(false)} className="gk-btn-secondary flex-1">
                İptal
              </button>
              <button onClick={handleConfirmPurchase} className="gk-btn-gold flex-1">
                ✅ Satın Al
              </button>
            </div>
          </div>
        </Modal>
      )}

      <InfoModal isOpen={showInfo} onClose={() => setShowInfo(false)} message={infoMessage} />
    </>
  )
}
