// =====================================================
// app/(game)/events/page.tsx - Etkinlikler ekranı
// =====================================================
'use client'

import { motion } from 'framer-motion'

const MOCK_EVENTS = [
  {
    id: 'blood_moon',
    name: '🌑 Kanlı Ay Etkinliği',
    description: 'Kanlı Ay altında tüm PvP ödülleri 2 kat! Bu geceyi kaçırma.',
    endsAt: '3 gün',
    type: 'pvp',
    bonus: '×2 PvP Ödülü',
    color: '#8b1a1a',
  },
  {
    id: 'dungeon_rush',
    name: '⚔️ Zindan Akını',
    description: 'Bu hafta zindanlardan extra XP kazan. Seviye atla!',
    endsAt: '5 gün',
    type: 'dungeon',
    bonus: '+50% XP',
    color: '#1a3a8b',
  },
  {
    id: 'gold_rush',
    name: '💰 Altın Hücumu',
    description: 'Tüm üretim tesislerinden altın üretimi 3 kat artırıldı!',
    endsAt: '1 gün',
    type: 'production',
    bonus: '×3 Üretim',
    color: '#8b6914',
  },
]

export default function EventsPage() {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="p-4 space-y-4"
    >
      <div className="flex items-center justify-between">
        <h1 className="gk-title font-game text-xl">🎪 Etkinlikler</h1>
        <span className="text-[#a8a8b8] text-sm">{MOCK_EVENTS.length} aktif</span>
      </div>

      {MOCK_EVENTS.map((event, i) => (
        <motion.div
          key={event.id}
          initial={{ opacity: 0, x: -20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: i * 0.1 }}
          className="gk-panel overflow-hidden relative"
          style={{ borderColor: event.color + '60' }}
        >
          {/* Arka plan rengi */}
          <div
            className="absolute inset-0 opacity-10"
            style={{ background: event.color }}
          />

          <div className="relative z-10">
            <div className="flex items-start justify-between gap-3 mb-2">
              <h3 className="font-game font-bold text-base">{event.name}</h3>
              <span
                className="text-xs font-bold px-2 py-0.5 rounded-full flex-shrink-0"
                style={{ background: event.color + '40', color: event.color }}
              >
                {event.bonus}
              </span>
            </div>

            <p className="text-[#a8a8b8] text-sm mb-3">{event.description}</p>

            <div className="flex items-center justify-between">
              <span className="text-[#a8a8b8] text-xs">⏰ Bitiş: {event.endsAt}</span>
              <button className="gk-btn-gold text-xs py-1 px-3">Katıl</button>
            </div>
          </div>
        </motion.div>
      ))}

      <div className="gk-panel text-center">
        <p className="text-[#a8a8b8] text-sm">
          🔔 Yeni etkinlikler için bildirim alıyorsunuz.
        </p>
      </div>
    </motion.div>
  )
}
