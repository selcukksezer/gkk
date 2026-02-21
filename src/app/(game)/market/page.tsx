// =====================================================
// app/(game)/market/page.tsx - Pazar ekranı
// GDScript MarketScreen.gd'den dönüştürüldü
// =====================================================
'use client'

import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { usePlayerStore } from '@/store/playerStore'
import { formatNumber } from '@/lib/utils/mathUtils'
import { InfoModal, Modal } from '@/components/ui/Modal'

type TabType = 'browse' | 'sell' | 'orders'

interface MarketListing {
  id: string
  sellerName: string
  itemName: string
  itemIcon: string
  rarity: string
  quantity: number
  pricePerUnit: number
  totalPrice: number
}

const RARITY_COLORS: Record<string, string> = {
  common: '#a8a8b8',
  uncommon: '#22c55e',
  rare: '#3b82f6',
  epic: '#8b5cf6',
  legendary: '#f59e0b',
}

const MOCK_LISTINGS: MarketListing[] = [
  { id: 'l1', sellerName: 'DemirTacir', itemName: 'Demir Cevheri', itemIcon: '⛏️', rarity: 'common', quantity: 100, pricePerUnit: 15, totalPrice: 1500 },
  { id: 'l2', sellerName: 'OtçuUsta', itemName: 'Şifalı Ot', itemIcon: '🌿', rarity: 'uncommon', quantity: 50, pricePerUnit: 45, totalPrice: 2250 },
  { id: 'l3', sellerName: 'KılıçKral', itemName: 'Büyülü Kılıç', itemIcon: '🗡️', rarity: 'rare', quantity: 1, pricePerUnit: 8500, totalPrice: 8500 },
  { id: 'l4', sellerName: 'ArıcıBal', itemName: 'Kraliçe Arısı Tozu', itemIcon: '🍯', rarity: 'epic', quantity: 5, pricePerUnit: 2200, totalPrice: 11000 },
  { id: 'l5', sellerName: 'RuneMaster', itemName: 'Antik Rune', itemIcon: '🔮', rarity: 'rare', quantity: 3, pricePerUnit: 1800, totalPrice: 5400 },
  { id: 'l6', sellerName: 'MeşeUstası', itemName: 'Meşe Odunu', itemIcon: '🪵', rarity: 'common', quantity: 200, pricePerUnit: 8, totalPrice: 1600 },
  { id: 'l7', sellerName: 'KriKrali', itemName: 'Granit Taş', itemIcon: '🪨', rarity: 'common', quantity: 80, pricePerUnit: 20, totalPrice: 1600 },
  { id: 'l8', sellerName: 'MantiMest', itemName: 'Büyülü Mantar', itemIcon: '🍄', rarity: 'uncommon', quantity: 25, pricePerUnit: 90, totalPrice: 2250 },
]

const FILTER_OPTIONS = ['Tümü', 'Silah', 'Zırh', 'Malzeme', 'İksir', 'Nadir']

export default function MarketPage() {
  const { gold, inventory } = usePlayerStore((s) => ({ gold: s.gold, inventory: s.inventory }))

  const [activeTab, setActiveTab] = useState<TabType>('browse')
  const [searchTerm, setSearchTerm] = useState('')
  const [activeFilter, setActiveFilter] = useState('Tümü')
  const [selectedListing, setSelectedListing] = useState<MarketListing | null>(null)
  const [showBuyModal, setShowBuyModal] = useState(false)
  const [infoMessage, setInfoMessage] = useState('')
  const [showInfo, setShowInfo] = useState(false)

  const filteredListings = MOCK_LISTINGS.filter((l) => {
    const matchSearch = l.itemName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      l.sellerName.toLowerCase().includes(searchTerm.toLowerCase())
    return matchSearch
  })

  const handleBuy = (listing: MarketListing) => {
    if (gold < listing.totalPrice) {
      setInfoMessage(`Yetersiz altın. ${formatNumber(listing.totalPrice)} 💰 gerekiyor.`)
      setShowInfo(true)
      return
    }
    setSelectedListing(listing)
    setShowBuyModal(true)
  }

  const handleConfirmBuy = () => {
    setShowBuyModal(false)
    setInfoMessage(`${selectedListing?.itemName} satın alındı! (Demo)`)
    setShowInfo(true)
  }

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
          <span className="text-3xl">🛍️</span>
          <div>
            <h1 className="gk-title text-xl">Pazar</h1>
            <p className="text-gk-silver text-xs">Alım satım merkezi</p>
          </div>
          <div className="ml-auto">
            <span className="text-gk-gold text-sm font-bold">💰 {formatNumber(gold)}</span>
          </div>
        </div>

        {/* Sekmeler */}
        <div className="flex bg-gk-surface rounded-xl p-1 mb-4 gap-1">
          {(['browse', 'sell', 'orders'] as TabType[]).map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`flex-1 py-2 rounded-lg text-xs font-semibold transition-all ${
                activeTab === tab ? 'bg-gk-gold text-gk-darker' : 'text-gk-silver hover:text-white'
              }`}
            >
              {tab === 'browse' ? '👁️ Göz At' : tab === 'sell' ? '💱 Sat' : '📋 Emirlerim'}
            </button>
          ))}
        </div>

        <AnimatePresence mode="wait">
          {activeTab === 'browse' && (
            <motion.div key="browse" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
              {/* Arama */}
              <input
                className="gk-input mb-3"
                placeholder="🔍 Eşya veya satıcı ara..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />

              {/* Filtreler */}
              <div className="flex gap-2 mb-4 overflow-x-auto pb-1">
                {FILTER_OPTIONS.map((f) => (
                  <button
                    key={f}
                    onClick={() => setActiveFilter(f)}
                    className={`whitespace-nowrap px-3 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                      activeFilter === f ? 'bg-gk-gold text-gk-darker' : 'bg-gk-surface text-gk-silver hover:text-white'
                    }`}
                  >
                    {f}
                  </button>
                ))}
              </div>

              {/* İlanlar */}
              <div className="space-y-3">
                {filteredListings.map((listing, i) => (
                  <motion.div
                    key={listing.id}
                    initial={{ opacity: 0, x: -10 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: i * 0.04 }}
                    className="gk-panel"
                  >
                    <div className="flex items-center gap-3">
                      <div
                        className="w-12 h-12 rounded-xl bg-gk-surface border flex items-center justify-center text-2xl flex-shrink-0"
                        style={{ borderColor: RARITY_COLORS[listing.rarity] + '66' }}
                      >
                        {listing.itemIcon}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2">
                          <h3 className="text-white font-bold text-sm truncate">{listing.itemName}</h3>
                          <span
                            className="text-xs font-bold"
                            style={{ color: RARITY_COLORS[listing.rarity] }}
                          >
                            ●
                          </span>
                        </div>
                        <p className="text-gk-silver text-xs">Satıcı: {listing.sellerName}</p>
                        <p className="text-gk-silver text-xs">Adet: {listing.quantity}</p>
                      </div>
                      <div className="text-right flex-shrink-0">
                        <p className="text-gk-gold font-bold text-sm">{formatNumber(listing.totalPrice)} 💰</p>
                        <p className="text-gk-silver text-xs">{formatNumber(listing.pricePerUnit)}/adet</p>
                        <button
                          onClick={() => handleBuy(listing)}
                          className="gk-btn-gold text-xs px-2 py-1 mt-1"
                        >
                          Satın Al
                        </button>
                      </div>
                    </div>
                  </motion.div>
                ))}
              </div>
            </motion.div>
          )}

          {activeTab === 'sell' && (
            <motion.div key="sell" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
              <div className="gk-panel text-center py-8 mb-4">
                <div className="text-5xl mb-3">💱</div>
                <h3 className="text-white font-bold mb-2">Eşya Sat</h3>
                <p className="text-gk-silver text-sm mb-4">Envanterinizdeki eşyaları pazarda satışa koyun.</p>
                {inventory.length === 0 ? (
                  <p className="text-gk-silver text-xs">Satacak eşyanız yok. Önce eşya kazanın.</p>
                ) : (
                  <button
                    onClick={() => { setInfoMessage('Satış özelliği yakında gelecek!'); setShowInfo(true) }}
                    className="gk-btn-gold px-8"
                  >
                    📦 Envantere Git
                  </button>
                )}
              </div>

              <div className="gk-panel">
                <h3 className="text-gk-silver text-xs font-bold mb-2 uppercase tracking-wider">Satış İpuçları</h3>
                <div className="space-y-2 text-xs text-gk-silver">
                  <p>💡 Nadir eşyalar daha yüksek fiyata satılır</p>
                  <p>💡 Fiyatı piyasa fiyatına göre ayarlayın</p>
                  <p>💡 Satış ücreti toplam tutarın %5'idir</p>
                </div>
              </div>
            </motion.div>
          )}

          {activeTab === 'orders' && (
            <motion.div key="orders" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
              <div className="gk-panel text-center py-12">
                <div className="text-5xl mb-3">📋</div>
                <h3 className="text-white font-bold mb-2">Aktif Emirleriniz</h3>
                <p className="text-gk-silver text-sm">Henüz aktif satış emiriniz yok.</p>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </motion.div>

      {/* Satın alma modalı */}
      {selectedListing && (
        <Modal
          isOpen={showBuyModal}
          onClose={() => setShowBuyModal(false)}
          title="Satın Al"
          size="sm"
        >
          <div className="space-y-4">
            <div className="text-center">
              <div className="text-4xl mb-2">{selectedListing.itemIcon}</div>
              <p className="text-white font-bold">{selectedListing.itemName}</p>
              <p className="text-gk-silver text-sm">x{selectedListing.quantity} adet</p>
            </div>
            <div className="bg-gk-surface rounded-lg p-3 flex justify-between">
              <span className="text-gk-silver">Toplam Tutar</span>
              <span className="text-gk-gold font-bold">💰 {formatNumber(selectedListing.totalPrice)}</span>
            </div>
            <div className="flex gap-3">
              <button onClick={() => setShowBuyModal(false)} className="gk-btn-secondary flex-1">İptal</button>
              <button onClick={handleConfirmBuy} className="gk-btn-gold flex-1">✅ Satın Al</button>
            </div>
          </div>
        </Modal>
      )}

      <InfoModal isOpen={showInfo} onClose={() => setShowInfo(false)} message={infoMessage} />
    </>
  )
}
