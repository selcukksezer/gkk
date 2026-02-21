// =====================================================
// app/(game)/settings/page.tsx - Ayarlar ekranı
// GDScript SettingsScreen.gd'den dönüştürüldü
// =====================================================
'use client'

import { useState, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import { motion } from 'framer-motion'
import { useSessionStore } from '@/store/sessionStore'
import { usePlayerStore } from '@/store/playerStore'
import { ConfirmModal, InfoModal } from '@/components/ui/Modal'

const APP_VERSION = '1.0.0-alpha'

interface ToggleSetting {
  id: string
  label: string
  description: string
  icon: string
  value: boolean
}

const LANGUAGE_OPTIONS = [
  { code: 'tr', label: '🇹🇷 Türkçe' },
  { code: 'en', label: '🇬🇧 English' },
  { code: 'de', label: '🇩🇪 Deutsch' },
]

function ToggleRow({ setting, onToggle }: { setting: ToggleSetting; onToggle: () => void }) {
  return (
    <div className="flex items-center justify-between py-3 border-b border-gk-border last:border-0">
      <div className="flex items-center gap-3">
        <span className="text-xl">{setting.icon}</span>
        <div>
          <p className="text-white text-sm font-medium">{setting.label}</p>
          <p className="text-gk-silver text-xs">{setting.description}</p>
        </div>
      </div>
      <button
        onClick={onToggle}
        className={`w-12 h-6 rounded-full transition-all duration-300 flex items-center ${
          setting.value ? 'bg-gk-gold justify-end' : 'bg-gk-border justify-start'
        }`}
      >
        <div className="w-5 h-5 rounded-full bg-white shadow mx-0.5" />
      </button>
    </div>
  )
}

export default function SettingsPage() {
  const router = useRouter()
  const { logout: sessionLogout } = useSessionStore()
  const { logout: playerLogout, player } = usePlayerStore((s) => ({
    logout: s.logout,
    player: s.player,
  }))

  const [selectedLanguage, setSelectedLanguage] = useState('tr')
  const [showLogoutConfirm, setShowLogoutConfirm] = useState(false)
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false)
  const [infoMessage, setInfoMessage] = useState('')
  const [showInfo, setShowInfo] = useState(false)

  const [toggles, setToggles] = useState<ToggleSetting[]>([
    { id: 'sound_enabled', label: 'Ses Efektleri', description: 'Oyun ses efektleri', icon: '🔊', value: true },
    { id: 'music_enabled', label: 'Arka Plan Müziği', description: 'Oyun müziği', icon: '🎵', value: true },
    { id: 'notifications', label: 'Bildirimler', description: 'Oyun bildirimleri al', icon: '🔔', value: true },
    { id: 'push_notifications', label: 'Anlık Bildirim', description: 'Enerji dolumu ve görev hatırlatmaları', icon: '📱', value: true },
    { id: 'vibration', label: 'Titreşim', description: 'Savaş ve önemli anlar için titreşim', icon: '📳', value: false },
    { id: 'auto_battle', label: 'Otomatik Savaş', description: 'Zindan savaşlarını otomatik yönet', icon: '🤖', value: false },
    { id: 'show_damage', label: 'Hasar Göster', description: 'Savaşta verilen hasarı göster', icon: '⚡', value: true },
    { id: 'low_data_mode', label: 'Düşük Veri Modu', description: 'Mobil veri tasarrufu', icon: '📡', value: false },
  ])

  const handleToggle = useCallback((id: string) => {
    setToggles((prev) => prev.map((t) => t.id === id ? { ...t, value: !t.value } : t))
  }, [])

  const handleLogout = useCallback(async () => {
    setShowLogoutConfirm(false)
    playerLogout()
    await sessionLogout()
    router.replace('/login')
  }, [sessionLogout, playerLogout, router])

  const handleDeleteAccount = () => {
    setShowDeleteConfirm(false)
    setInfoMessage('Hesap silme talebi alındı. Bu özellik henüz aktif değil.')
    setShowInfo(true)
  }

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
        <div className="flex items-center gap-2 mb-6">
          <span className="text-3xl">⚙️</span>
          <h1 className="gk-title text-xl">Ayarlar</h1>
        </div>

        {/* Hesap bilgisi */}
        <div className="gk-panel mb-4">
          <h2 className="text-gk-silver text-xs font-bold mb-3 uppercase tracking-wider">Hesap</h2>
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-full bg-gk-surface border border-gk-border flex items-center justify-center text-2xl">
              ⚔️
            </div>
            <div>
              <p className="text-white font-bold">{player?.display_name ?? 'Oyuncu'}</p>
              <p className="text-gk-silver text-sm">@{player?.username ?? 'oyuncu'}</p>
            </div>
          </div>
        </div>

        {/* Ses ve Müzik */}
        <div className="gk-panel mb-4">
          <h2 className="text-gk-silver text-xs font-bold mb-2 uppercase tracking-wider">Ses & Müzik</h2>
          {toggles.filter((t) => ['sound_enabled', 'music_enabled', 'vibration'].includes(t.id)).map((t) => (
            <ToggleRow key={t.id} setting={t} onToggle={() => handleToggle(t.id)} />
          ))}
        </div>

        {/* Bildirimler */}
        <div className="gk-panel mb-4">
          <h2 className="text-gk-silver text-xs font-bold mb-2 uppercase tracking-wider">Bildirimler</h2>
          {toggles.filter((t) => ['notifications', 'push_notifications'].includes(t.id)).map((t) => (
            <ToggleRow key={t.id} setting={t} onToggle={() => handleToggle(t.id)} />
          ))}
        </div>

        {/* Oyun */}
        <div className="gk-panel mb-4">
          <h2 className="text-gk-silver text-xs font-bold mb-2 uppercase tracking-wider">Oyun</h2>
          {toggles.filter((t) => ['auto_battle', 'show_damage', 'low_data_mode'].includes(t.id)).map((t) => (
            <ToggleRow key={t.id} setting={t} onToggle={() => handleToggle(t.id)} />
          ))}
        </div>

        {/* Dil seçimi */}
        <div className="gk-panel mb-4">
          <h2 className="text-gk-silver text-xs font-bold mb-3 uppercase tracking-wider">Dil</h2>
          <div className="space-y-2">
            {LANGUAGE_OPTIONS.map((lang) => (
              <button
                key={lang.code}
                onClick={() => setSelectedLanguage(lang.code)}
                className={`w-full flex items-center justify-between p-3 rounded-xl border transition-all ${
                  selectedLanguage === lang.code
                    ? 'border-gk-gold bg-gk-gold/10'
                    : 'border-gk-border bg-gk-surface'
                }`}
              >
                <span className="text-white text-sm">{lang.label}</span>
                {selectedLanguage === lang.code && <span className="text-gk-gold">✓</span>}
              </button>
            ))}
          </div>
        </div>

        {/* Destek linkleri */}
        <div className="gk-panel mb-4">
          <h2 className="text-gk-silver text-xs font-bold mb-3 uppercase tracking-wider">Destek</h2>
          <div className="space-y-2">
            {[
              { label: '📞 Destek Merkezi', action: () => { setInfoMessage('Destek sayfası yakında açılacak!'); setShowInfo(true) } },
              { label: '📄 Gizlilik Politikası', action: () => { setInfoMessage('Gizlilik politikası yakında.'); setShowInfo(true) } },
              { label: '📋 Kullanım Şartları', action: () => { setInfoMessage('Kullanım şartları yakında.'); setShowInfo(true) } },
              { label: '🐛 Hata Bildir', action: () => { setInfoMessage('Hata bildir özelliği yakında.'); setShowInfo(true) } },
            ].map((item) => (
              <button
                key={item.label}
                onClick={item.action}
                className="w-full flex items-center justify-between p-3 rounded-xl bg-gk-surface hover:bg-gk-panel transition-all text-left"
              >
                <span className="text-gk-silver text-sm">{item.label}</span>
                <span className="text-gk-border">›</span>
              </button>
            ))}
          </div>
        </div>

        {/* Versiyon */}
        <div className="gk-panel mb-4 text-center">
          <p className="text-gk-silver text-xs">Gölge Krallık v{APP_VERSION}</p>
          <p className="text-gk-border text-xs mt-0.5">© 2025 Shadow Kingdom Studios</p>
        </div>

        {/* Tehlikeli işlemler */}
        <div className="space-y-3">
          <button
            onClick={() => setShowLogoutConfirm(true)}
            className="gk-btn-secondary w-full flex items-center justify-center gap-2"
          >
            🚪 Hesaptan Çık
          </button>
          <button
            onClick={() => setShowDeleteConfirm(true)}
            className="gk-btn-danger w-full flex items-center justify-center gap-2 opacity-70"
          >
            🗑️ Hesabı Sil
          </button>
        </div>
      </motion.div>

      <ConfirmModal
        isOpen={showLogoutConfirm}
        onClose={() => setShowLogoutConfirm(false)}
        onConfirm={handleLogout}
        title="Çıkış Yap"
        message="Hesabınızdan çıkmak istediğinizden emin misiniz?"
        confirmText="Evet, Çık"
        danger
      />

      <ConfirmModal
        isOpen={showDeleteConfirm}
        onClose={() => setShowDeleteConfirm(false)}
        onConfirm={handleDeleteAccount}
        title="Hesabı Sil"
        message="Hesabınızı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz."
        confirmText="Evet, Hesabımı Sil"
        danger
      />

      <InfoModal isOpen={showInfo} onClose={() => setShowInfo(false)} message={infoMessage} />
    </>
  )
}
