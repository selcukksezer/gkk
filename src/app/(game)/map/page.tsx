// =====================================================
// app/(game)/map/page.tsx - Harita ekranı
// GDScript MapScreen.gd'den dönüştürüldü
// =====================================================
'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { motion, AnimatePresence } from 'framer-motion'
import { usePlayerStore } from '@/store/playerStore'
import { Modal } from '@/components/ui/Modal'

type ZoneType = 'dungeon' | 'pvp' | 'city' | 'wild' | 'special'

interface MapLocation {
  id: string
  name: string
  description: string
  type: ZoneType
  icon: string
  requiredLevel: number
  href?: string
  danger: number // 0-100
  tags?: string[]
}

const ZONE_COLORS: Record<ZoneType, string> = {
  dungeon: '#f97316',
  pvp: '#ef4444',
  city: '#22c55e',
  wild: '#84cc16',
  special: '#8b5cf6',
}

const ZONE_LABELS: Record<ZoneType, string> = {
  dungeon: '⚔️ Zindan',
  pvp: '🆚 PvP Alanı',
  city: '🏙️ Şehir',
  wild: '🌲 Doğa',
  special: '✨ Özel',
}

const MAP_LOCATIONS: MapLocation[] = [
  {
    id: 'loc_city', name: 'Gölge Şehri', type: 'city', icon: '🏰', requiredLevel: 1, href: '/home',
    description: 'Krallığın ana şehri. Tüm hizmetlerin merkezi. Güvende ve huzurlu.',
    danger: 0, tags: ['Güvenli', 'Merkez'],
  },
  {
    id: 'loc_market', name: 'Büyük Pazar', type: 'city', icon: '🛍️', requiredLevel: 1, href: '/market',
    description: 'Tüm ticaretin yapıldığı canlı pazar alanı. Alım satım buradan.',
    danger: 0, tags: ['Ticaret'],
  },
  {
    id: 'loc_dungeon_start', name: 'Başlangıç Mağarası', type: 'dungeon', icon: '🕳️', requiredLevel: 1, href: '/dungeon',
    description: 'Yeni kahromanlar için giriş seviyesi zindan. Tehlike düşük.',
    danger: 10, tags: ['Kolay', 'Zindan'],
  },
  {
    id: 'loc_bandit', name: 'Haydut Kampı', type: 'dungeon', icon: '🏕️', requiredLevel: 5, href: '/dungeon',
    description: 'Yolları tutan haydutların gizli üssü. Dikkatli olun!',
    danger: 30, tags: ['Orta', 'Zindan'],
  },
  {
    id: 'loc_pvp_arena', name: 'Gladyatör Arenası', type: 'pvp', icon: '🏟️', requiredLevel: 5, href: '/pvp',
    description: 'PvP savaşlarının yapıldığı büyük arena. En güçlü savaşçılar burada dövüşür.',
    danger: 60, tags: ['PvP', 'Tehlikeli'],
  },
  {
    id: 'loc_dark_forest', name: 'Karanlık Orman', type: 'wild', icon: '🌑', requiredLevel: 10, href: '/dungeon',
    description: 'Gizemli ve tehlikeli karanlık orman. Nadir eşyalar bulunabilir.',
    danger: 50, tags: ['Orta', 'Keşif'],
  },
  {
    id: 'loc_fortress', name: 'Lanetli Kale', type: 'dungeon', icon: '🏯', requiredLevel: 15, href: '/dungeon',
    description: 'Lanetli ruhların yaşadığı eski kale. Yalnız girilmemesi önerilir.',
    danger: 70, tags: ['Zor', 'Zindan', 'Boss'],
  },
  {
    id: 'loc_desert', name: 'Çöl Harabeleri', type: 'wild', icon: '🏜️', requiredLevel: 15, href: '/dungeon',
    description: 'Uzak çöldeki antik harabeler. Lanetli Mezar burada gizlidir.',
    danger: 65, tags: ['Zor', 'Keşif'],
  },
  {
    id: 'loc_pvp_border', name: 'Sınır Toprakları', type: 'pvp', icon: '⚔️', requiredLevel: 10, href: '/pvp',
    description: 'İki krallık arasındaki sınır bölgesi. Sürekli çatışma var.',
    danger: 80, tags: ['PvP', 'Yüksek Risk'],
  },
  {
    id: 'loc_dragon', name: 'Ejder Dağları', type: 'dungeon', icon: '🐉', requiredLevel: 25, href: '/dungeon',
    description: 'Kızıl kanatlı ejderin yuvası. Sadece en güçlü kahramanlar buraya girer.',
    danger: 95, tags: ['Çok Zor', 'Boss', 'Zindan'],
  },
  {
    id: 'loc_guild_hall', name: 'Lonca Binası', type: 'city', icon: '🏰', requiredLevel: 1, href: '/guild',
    description: 'Lonca toplantılarının yapıldığı büyük salon.',
    danger: 0, tags: ['Lonca', 'Güvenli'],
  },
  {
    id: 'loc_rune_temple', name: 'Rune Tapınağı', type: 'special', icon: '🔮', requiredLevel: 20,
    description: 'Antik runların saklandığı gizemli tapınak. Büyülü sırlar bekliyor.',
    danger: 45, tags: ['Özel', 'Büyü'],
  },
]

const TYPE_FILTERS: Array<ZoneType | 'all'> = ['all', 'city', 'dungeon', 'pvp', 'wild', 'special']

export default function MapPage() {
  const router = useRouter()
  const { level } = usePlayerStore((s) => ({ level: s.level }))

  const [activeFilter, setActiveFilter] = useState<ZoneType | 'all'>('all')
  const [selectedLocation, setSelectedLocation] = useState<MapLocation | null>(null)
  const [showModal, setShowModal] = useState(false)

  const filteredLocations = MAP_LOCATIONS.filter((loc) =>
    activeFilter === 'all' ? true : loc.type === activeFilter
  )

  const handleLocationPress = (loc: MapLocation) => {
    setSelectedLocation(loc)
    setShowModal(true)
  }

  const handleGo = () => {
    setShowModal(false)
    if (selectedLocation?.href) {
      router.push(selectedLocation.href)
    }
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
          <span className="text-3xl">🗺️</span>
          <div>
            <h1 className="gk-title text-xl">Harita</h1>
            <p className="text-gk-silver text-xs">Gölge Krallık'ı keşfet</p>
          </div>
          <div className="ml-auto">
            <span className="gk-badge bg-gk-surface text-gk-silver">Sv.{level}</span>
          </div>
        </div>

        {/* Filtreler */}
        <div className="flex gap-2 mb-4 overflow-x-auto pb-1">
          {TYPE_FILTERS.map((f) => (
            <button
              key={f}
              onClick={() => setActiveFilter(f)}
              className={`whitespace-nowrap px-3 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                activeFilter === f ? 'bg-gk-gold text-gk-darker' : 'bg-gk-surface text-gk-silver hover:text-white'
              }`}
            >
              {f === 'all' ? '🗺️ Tümü' : ZONE_LABELS[f]}
            </button>
          ))}
        </div>

        {/* Lokasyonlar */}
        <div className="space-y-3">
          {filteredLocations.map((loc, i) => {
            const isAccessible = level >= loc.requiredLevel
            return (
              <motion.div
                key={loc.id}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: i * 0.05 }}
                onClick={() => handleLocationPress(loc)}
                className={`gk-panel cursor-pointer active:scale-98 transition-transform ${!isAccessible ? 'opacity-50' : ''}`}
              >
                <div className="flex items-center gap-3">
                  <div
                    className="w-12 h-12 rounded-xl flex items-center justify-center text-2xl flex-shrink-0"
                    style={{ background: ZONE_COLORS[loc.type] + '22', border: `2px solid ${ZONE_COLORS[loc.type]}55` }}
                  >
                    {loc.icon}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-0.5">
                      <h3 className="text-white font-bold text-sm">{loc.name}</h3>
                      {!isAccessible && <span className="text-red-400 text-xs">🔒 Sv.{loc.requiredLevel}</span>}
                    </div>
                    <p className="text-gk-silver text-xs mb-2 line-clamp-1">{loc.description}</p>
                    <div className="flex gap-2 flex-wrap">
                      <span
                        className="gk-badge text-xs"
                        style={{ color: ZONE_COLORS[loc.type], background: ZONE_COLORS[loc.type] + '22' }}
                      >
                        {ZONE_LABELS[loc.type]}
                      </span>
                      {loc.tags?.slice(0, 2).map((tag) => (
                        <span key={tag} className="gk-badge bg-gk-surface text-gk-silver text-xs">{tag}</span>
                      ))}
                    </div>
                  </div>
                  <div className="flex-shrink-0 text-right">
                    {loc.danger > 0 && (
                      <div>
                        <p className="text-xs" style={{ color: loc.danger > 70 ? '#ef4444' : loc.danger > 40 ? '#f97316' : '#f59e0b' }}>
                          ⚠️ {loc.danger}%
                        </p>
                        <p className="text-gk-silver text-xs">tehlike</p>
                      </div>
                    )}
                  </div>
                </div>
              </motion.div>
            )
          })}
        </div>
      </motion.div>

      {/* Lokasyon detay modalı */}
      {selectedLocation && (
        <Modal
          isOpen={showModal}
          onClose={() => setShowModal(false)}
          title={`${selectedLocation.icon} ${selectedLocation.name}`}
          size="md"
        >
          <div className="space-y-4">
            <div
              className="rounded-xl p-4 text-center"
              style={{ background: ZONE_COLORS[selectedLocation.type] + '22', border: `1px solid ${ZONE_COLORS[selectedLocation.type]}44` }}
            >
              <div className="text-5xl mb-2">{selectedLocation.icon}</div>
              <span
                className="gk-badge text-sm"
                style={{ color: ZONE_COLORS[selectedLocation.type], background: ZONE_COLORS[selectedLocation.type] + '33' }}
              >
                {ZONE_LABELS[selectedLocation.type]}
              </span>
            </div>

            <p className="text-gk-silver text-sm">{selectedLocation.description}</p>

            <div className="grid grid-cols-2 gap-3">
              <div className="bg-gk-surface rounded-lg p-3 text-center">
                <p className="text-white font-bold">Sv. {selectedLocation.requiredLevel}</p>
                <p className="text-gk-silver text-xs">Gereken Seviye</p>
              </div>
              <div className="bg-gk-surface rounded-lg p-3 text-center">
                <p
                  className="font-bold"
                  style={{ color: selectedLocation.danger > 70 ? '#ef4444' : selectedLocation.danger > 40 ? '#f97316' : '#22c55e' }}
                >
                  {selectedLocation.danger === 0 ? 'Güvenli' : `${selectedLocation.danger}%`}
                </p>
                <p className="text-gk-silver text-xs">Tehlike</p>
              </div>
            </div>

            {selectedLocation.tags && (
              <div className="flex flex-wrap gap-2">
                {selectedLocation.tags.map((tag) => (
                  <span key={tag} className="gk-badge bg-gk-surface text-gk-silver text-xs">{tag}</span>
                ))}
              </div>
            )}

            <div className="flex gap-3">
              <button onClick={() => setShowModal(false)} className="gk-btn-secondary flex-1">
                Kapat
              </button>
              <button
                onClick={handleGo}
                disabled={level < selectedLocation.requiredLevel || !selectedLocation.href}
                className="gk-btn-gold flex-1"
              >
                {level < selectedLocation.requiredLevel
                  ? `🔒 Sv.${selectedLocation.requiredLevel}`
                  : selectedLocation.href
                    ? '🚀 Git'
                    : 'Yakında'}
              </button>
            </div>
          </div>
        </Modal>
      )}
    </>
  )
}
