// =====================================================
// components/ui/BottomNav.tsx - Alt navigasyon çubuğu
// GDScript BottomNav.gd'den dönüştürüldü
// =====================================================
'use client'

import { usePathname, useRouter } from 'next/navigation'
import { motion } from 'framer-motion'
import { usePlayerStore } from '@/store/playerStore'

interface NavItem {
  path: string
  icon: string
  label: string
  alertKey?: 'inHospital' | 'inPrison'
}

const NAV_ITEMS: NavItem[] = [
  { path: '/home', icon: '🏠', label: 'Ana Sayfa' },
  { path: '/map', icon: '🗺️', label: 'Harita' },
  { path: '/inventory', icon: '🎒', label: 'Envanter' },
  { path: '/market', icon: '🛍️', label: 'Pazar' },
  { path: '/guild', icon: '🏰', label: 'Lonca' },
]

export default function BottomNav() {
  const router = useRouter()
  const pathname = usePathname()
  const { inHospital, inPrison } = usePlayerStore()

  const navigate = (path: string) => {
    router.push(path)
  }

  return (
    <nav className="fixed bottom-0 left-1/2 -translate-x-1/2 w-full max-w-[480px] z-50 safe-bottom">
      <div className="bg-gk-panel border-t border-gk-border">
        <div className="flex items-stretch h-16">
          {NAV_ITEMS.map((item) => {
            const isActive = pathname === item.path || pathname.startsWith(item.path + '/')
            const hasAlert = item.alertKey === 'inHospital' ? inHospital : item.alertKey === 'inPrison' ? inPrison : false

            return (
              <button
                key={item.path}
                onClick={() => navigate(item.path)}
                className={`flex-1 flex flex-col items-center justify-center gap-0.5 transition-all duration-200 relative ${
                  isActive
                    ? 'text-gk-gold'
                    : 'text-gk-silver hover:text-white active:scale-95'
                }`}
              >
                {/* Aktif göstergesi */}
                {isActive && (
                  <motion.div
                    layoutId="nav-indicator"
                    className="absolute top-0 left-1/2 -translate-x-1/2 w-8 h-0.5 bg-gk-gold rounded-b-full"
                    transition={{ type: 'spring', stiffness: 400, damping: 30 }}
                  />
                )}

                {/* İkon */}
                <div className="relative">
                  <span className="text-xl leading-none">{item.icon}</span>
                  {/* Uyarı rozeti */}
                  {hasAlert && (
                    <motion.div
                      animate={{ scale: [1, 1.3, 1] }}
                      transition={{ repeat: Infinity, duration: 1 }}
                      className="absolute -top-1 -right-1 w-3 h-3 bg-red-500 rounded-full border border-gk-panel"
                    />
                  )}
                </div>

                {/* Etiket */}
                <span
                  className={`text-xs font-medium leading-none ${
                    isActive ? 'text-gk-gold' : ''
                  }`}
                >
                  {item.label}
                </span>
              </button>
            )
          })}
        </div>
      </div>
    </nav>
  )
}
