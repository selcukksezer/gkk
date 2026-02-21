// =====================================================
// app/(game)/guild/page.tsx - Lonca ekranı
// GDScript GuildScreen.gd'den dönüştürüldü
// =====================================================
'use client'

import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { usePlayerStore } from '@/store/playerStore'
import { formatNumber } from '@/lib/utils/mathUtils'
import { InfoModal } from '@/components/ui/Modal'
import type { GuildData, GuildMember } from '@/types/guild'

const ROLE_LABELS: Record<string, string> = {
  lord: '👑 Lord',
  commander: '⚔️ Komutan',
  member: '🛡️ Üye',
  apprentice: '🌱 Çırak',
}

const MOCK_GUILD: GuildData = {
  id: 'g1',
  name: 'Gölge Kalkan',
  description: 'Krallığın karanlığında ışığı koruyan seçkin savaşçılar.',
  emblem: '🛡️',
  level: 5,
  experience: 48_000,
  member_count: 8,
  max_members: 20,
  treasury_gold: 125_000,
  treasury_gems: 500,
  leader_id: 'p1',
  leader_name: 'KaranlıkŞövalye',
  created_at: '2025-01-01T00:00:00Z',
  zone_controlled: 'Orta Alanlar',
  total_power: 12_400,
  is_recruiting: true,
  min_level_requirement: 5,
  guild_points: 9_850,
}

const MOCK_MEMBERS: GuildMember[] = [
  { id: 'm1', player_id: 'p1', username: 'karanlıkŞövalye', display_name: 'Karanlık Şövalye', role: 'lord', level: 20, power: 2800, joined_at: '2025-01-01T00:00:00Z', last_seen: new Date().toISOString(), contribution_gold: 50_000, contribution_points: 3200, is_online: true },
  { id: 'm2', player_id: 'p2', username: 'demirKral', display_name: 'Demir Kral', role: 'commander', level: 18, power: 2200, joined_at: '2025-01-05T00:00:00Z', last_seen: new Date(Date.now() - 3600000).toISOString(), contribution_gold: 30_000, contribution_points: 2100, is_online: false },
  { id: 'm3', player_id: 'p3', username: 'gölgeSavaşçı', display_name: 'Gölge Savaşçı', role: 'member', level: 15, power: 1800, joined_at: '2025-01-10T00:00:00Z', last_seen: new Date(Date.now() - 7200000).toISOString(), contribution_gold: 18_000, contribution_points: 1400, is_online: true },
  { id: 'm4', player_id: 'p4', username: 'hızlıKıl', display_name: 'Hızlı Kılıç', role: 'member', level: 12, power: 1400, joined_at: '2025-01-15T00:00:00Z', last_seen: new Date(Date.now() - 86400000).toISOString(), contribution_gold: 12_000, contribution_points: 980, is_online: false },
  { id: 'm5', player_id: 'p5', username: 'yeniAsker', display_name: 'Yeni Asker', role: 'apprentice', level: 6, power: 450, joined_at: '2025-02-01T00:00:00Z', last_seen: new Date(Date.now() - 3600000).toISOString(), contribution_gold: 2_000, contribution_points: 120, is_online: true },
]

export default function GuildPage() {
  const { guildId, level, player } = usePlayerStore((s) => ({
    guildId: s.guildId,
    level: s.level,
    player: s.player,
  }))

  // Mock: assume player has no guild if guildId is empty
  const hasGuild = !!guildId || true // Demo için lonca var kabul et

  const [activeTab, setActiveTab] = useState<'info' | 'members'>('info')
  const [infoMessage, setInfoMessage] = useState('')
  const [showInfo, setShowInfo] = useState(false)

  if (!hasGuild) {
    return (
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="px-4 pt-4 pb-4 max-w-[480px] mx-auto"
      >
        <div className="flex items-center gap-2 mb-6">
          <span className="text-3xl">🏰</span>
          <h1 className="gk-title text-xl">Lonca</h1>
        </div>

        <div className="gk-panel text-center py-10 mb-4">
          <div className="text-6xl mb-4">🏚️</div>
          <h2 className="text-white text-xl font-bold mb-2">Loncaya Katılmadınız</h2>
          <p className="text-gk-silver text-sm">Bir loncaya katılın veya kendi loncanızı oluşturun.</p>
        </div>

        <div className="space-y-3">
          <button
            onClick={() => { setInfoMessage('Lonca arama özelliği yakında gelecek!'); setShowInfo(true) }}
            className="gk-btn-gold w-full text-sm"
          >
            🔍 Lonca Ara
          </button>
          <button
            onClick={() => { setInfoMessage('Lonca oluşturma özelliği yakında gelecek!'); setShowInfo(true) }}
            className="gk-btn-secondary w-full text-sm"
          >
            🏰 Lonca Oluştur
          </button>
        </div>

        <InfoModal isOpen={showInfo} onClose={() => setShowInfo(false)} message={infoMessage} />
      </motion.div>
    )
  }

  return (
    <>
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.3 }}
        className="px-4 pt-4 pb-2 max-w-[480px] mx-auto"
      >
        {/* Lonca başlığı */}
        <div className="gk-panel text-center mb-4 relative overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-b from-purple-900/20 to-transparent" />
          <div className="text-5xl mb-2">{MOCK_GUILD.emblem}</div>
          <h1 className="gk-title text-2xl">{MOCK_GUILD.name}</h1>
          <p className="text-gk-silver text-sm mt-1">{MOCK_GUILD.description}</p>
          <div className="flex justify-center gap-4 mt-3">
            <span className="gk-badge bg-purple-900/40 text-purple-400">⭐ Seviye {MOCK_GUILD.level}</span>
            <span className="gk-badge bg-gk-surface text-gk-silver">👥 {MOCK_GUILD.member_count}/{MOCK_GUILD.max_members}</span>
            {MOCK_GUILD.is_recruiting && (
              <span className="gk-badge bg-green-900/40 text-green-400">✅ Alım Açık</span>
            )}
          </div>
        </div>

        {/* Hızlı istatistikler */}
        <div className="grid grid-cols-3 gap-3 mb-4">
          <div className="gk-panel text-center py-3">
            <p className="text-gk-gold font-bold">{formatNumber(MOCK_GUILD.treasury_gold)}</p>
            <p className="text-gk-silver text-xs">💰 Hazine</p>
          </div>
          <div className="gk-panel text-center py-3">
            <p className="text-blue-400 font-bold">{formatNumber(MOCK_GUILD.total_power)}</p>
            <p className="text-gk-silver text-xs">💪 Güç</p>
          </div>
          <div className="gk-panel text-center py-3">
            <p className="text-purple-400 font-bold">{formatNumber(MOCK_GUILD.guild_points)}</p>
            <p className="text-gk-silver text-xs">🏆 Puan</p>
          </div>
        </div>

        {/* Sekmeler */}
        <div className="flex bg-gk-surface rounded-xl p-1 mb-4 gap-1">
          {(['info', 'members'] as const).map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`flex-1 py-2 rounded-lg text-sm font-semibold transition-all ${
                activeTab === tab ? 'bg-gk-gold text-gk-darker' : 'text-gk-silver hover:text-white'
              }`}
            >
              {tab === 'info' ? '🏰 Bilgi' : '👥 Üyeler'}
            </button>
          ))}
        </div>

        <AnimatePresence mode="wait">
          {activeTab === 'info' && (
            <motion.div key="info" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="space-y-3">
              <div className="gk-panel">
                <h3 className="text-gk-silver text-xs font-bold mb-3 uppercase tracking-wider">Lonca Detayları</h3>
                <div className="space-y-2">
                  {[
                    { label: 'Lider', value: MOCK_GUILD.leader_name, icon: '👑' },
                    { label: 'Kontrol Bölgesi', value: MOCK_GUILD.zone_controlled, icon: '📍' },
                    { label: 'Minimum Seviye', value: `Seviye ${MOCK_GUILD.min_level_requirement}`, icon: '📊' },
                    { label: 'Hazine (Elmas)', value: `💎 ${formatNumber(MOCK_GUILD.treasury_gems)}`, icon: '💎' },
                  ].map((item) => (
                    <div key={item.label} className="flex justify-between items-center">
                      <span className="text-gk-silver text-sm">{item.icon} {item.label}</span>
                      <span className="text-white text-sm font-bold">{item.value}</span>
                    </div>
                  ))}
                </div>
              </div>

              <div className="gk-panel">
                <h3 className="text-gk-silver text-xs font-bold mb-3 uppercase tracking-wider">Lonca Eylemleri</h3>
                <div className="space-y-2">
                  <button
                    onClick={() => { setInfoMessage('Lonca savaşı özelliği yakında gelecek!'); setShowInfo(true) }}
                    className="gk-btn-danger w-full text-sm"
                  >
                    ⚔️ Lonca Savaşı İlan Et
                  </button>
                  <button
                    onClick={() => { setInfoMessage('Lonca hazinesine bağış yapma özelliği yakında!'); setShowInfo(true) }}
                    className="gk-btn-secondary w-full text-sm"
                  >
                    💰 Hazineye Bağış Yap
                  </button>
                </div>
              </div>
            </motion.div>
          )}

          {activeTab === 'members' && (
            <motion.div key="members" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="space-y-2">
              {MOCK_MEMBERS.map((member, i) => (
                <motion.div
                  key={member.id}
                  initial={{ opacity: 0, x: -10 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: i * 0.05 }}
                  className="gk-panel flex items-center gap-3"
                >
                  <div className="relative">
                    <div className="w-10 h-10 rounded-full bg-gk-surface border border-gk-border flex items-center justify-center text-lg">
                      ⚔️
                    </div>
                    <div
                      className="absolute -bottom-0.5 -right-0.5 w-3 h-3 rounded-full border border-gk-panel"
                      style={{ background: member.is_online ? '#22c55e' : '#6b7280' }}
                    />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="text-white text-sm font-bold truncate">{member.display_name}</span>
                      <span className="text-xs text-gk-silver">{ROLE_LABELS[member.role]}</span>
                    </div>
                    <p className="text-gk-silver text-xs">
                      Seviye {member.level} • Güç: {formatNumber(member.power)}
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="text-gk-gold text-xs font-bold">{formatNumber(member.contribution_gold)}</p>
                    <p className="text-gk-silver text-xs">katkı</p>
                  </div>
                </motion.div>
              ))}
            </motion.div>
          )}
        </AnimatePresence>
      </motion.div>

      <InfoModal isOpen={showInfo} onClose={() => setShowInfo(false)} message={infoMessage} />
    </>
  )
}
