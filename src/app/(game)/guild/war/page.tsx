// =====================================================
// app/(game)/guild/war/page.tsx - Lonca Savaşı ekranı
// GDScript GuildWarScreen.gd'den dönüştürüldü
// =====================================================
'use client'

import { motion } from 'framer-motion'

const MOCK_WAR: {
  id: string
  attackerGuild: string
  attackerScore: number
  defenderGuild: string
  defenderScore: number
  status: 'active' | 'ended'
  endsIn: string
  zone: string
} = {
  id: 'war_1',
  attackerGuild: 'Gölge Klanı',
  attackerScore: 1250,
  defenderGuild: 'Demir Kaleler',
  defenderScore: 980,
  status: 'active',
  endsIn: '8 saat',
  zone: 'Karanlık Orman',
}

export default function GuildWarPage() {
  const total = MOCK_WAR.attackerScore + MOCK_WAR.defenderScore
  const attackPercent = total > 0 ? (MOCK_WAR.attackerScore / total) * 100 : 50

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="p-4 space-y-4"
    >
      <div className="flex items-center gap-2 mb-2">
        <button onClick={() => window.history.back()} className="text-[#a8a8b8] text-sm">← Lonca</button>
      </div>

      <h1 className="gk-title font-game text-xl">⚔️ Lonca Savaşı</h1>

      {/* Savaş durumu */}
      <div className="gk-panel" style={{ borderColor: '#8b1a1a60' }}>
        <div className="text-center mb-4">
          <div className="text-xs text-[#a8a8b8] mb-1">Bölge: {MOCK_WAR.zone}</div>
          <div className="text-green-400 text-xs font-bold">⚔️ AKTİF SAVAŞ • Bitiş: {MOCK_WAR.endsIn}</div>
        </div>

        {/* Skor tablosu */}
        <div className="grid grid-cols-3 items-center mb-4">
          <div className="text-center">
            <div className="font-game font-bold text-sm text-amber-400">{MOCK_WAR.attackerGuild}</div>
            <div className="text-green-400 font-bold text-2xl mt-1">{MOCK_WAR.attackerScore}</div>
          </div>

          <div className="text-center text-2xl font-bold text-[#a8a8b8]">VS</div>

          <div className="text-center">
            <div className="font-game font-bold text-sm text-red-400">{MOCK_WAR.defenderGuild}</div>
            <div className="text-red-400 font-bold text-2xl mt-1">{MOCK_WAR.defenderScore}</div>
          </div>
        </div>

        {/* İlerleme çubuğu */}
        <div className="h-3 bg-[#12121a] rounded-full overflow-hidden">
          <div
            className="h-full transition-all duration-500"
            style={{
              width: `${attackPercent}%`,
              background: 'linear-gradient(90deg, #22c55e, #16a34a)',
            }}
          />
        </div>
        <div className="flex justify-between text-xs text-[#a8a8b8] mt-1">
          <span>{attackPercent.toFixed(0)}%</span>
          <span>{(100 - attackPercent).toFixed(0)}%</span>
        </div>
      </div>

      {/* Savaş eylemleri */}
      <div className="gk-panel">
        <h2 className="font-semibold mb-3 text-amber-400">Savaş Eylemleri</h2>
        <div className="grid grid-cols-2 gap-3">
          <button className="gk-btn-danger py-3 text-sm">⚔️ Saldır (15⚡)</button>
          <button className="gk-btn-secondary py-3 text-sm">🛡️ Savun</button>
          <button className="gk-btn-secondary py-3 text-sm">📦 Kaynak Gönder</button>
          <button className="gk-btn-secondary py-3 text-sm">📜 Savaş Günlüğü</button>
        </div>
      </div>

      {/* Savaşçılar */}
      <div className="gk-panel">
        <h2 className="font-semibold mb-3 text-amber-400">Aktif Savaşçılar</h2>
        {['Arador', 'Theron', 'Lyra'].map((name) => (
          <div key={name} className="flex items-center gap-3 py-2 border-b border-[#2a2a3a] last:border-0">
            <div className="w-8 h-8 bg-[#12121a] rounded-full flex items-center justify-center text-sm">⚔️</div>
            <div>
              <div className="font-medium text-sm">{name}</div>
              <div className="text-[#a8a8b8] text-xs">Savaşçı • Çevrimiçi</div>
            </div>
          </div>
        ))}
      </div>
    </motion.div>
  )
}
