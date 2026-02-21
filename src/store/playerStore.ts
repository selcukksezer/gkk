// =====================================================
// store/playerStore.ts - Oyuncu veri store'u
// GDScript StateStore.gd'den dönüştürüldü
// =====================================================
'use client'

import { create } from 'zustand'
import { subscribeWithSelector } from 'zustand/middleware'
import type { PlayerData } from '@/types/player'
import type { InventoryItem, EquipmentSlots } from '@/types/item'
import type { QuestData } from '@/types/quest'
import { formatPlayerData, calculateNextLevelXp } from '@/types/player'
import supabase, { callEdgeFunction } from '@/lib/supabase'

interface PlayerState {
  // Oyuncu verileri
  player: PlayerData | null
  isLoaded: boolean

  // Hızlı erişim değerleri (StateStore.gd benzeri)
  currentEnergy: number
  maxEnergy: number
  tolerance: number
  gold: number
  gems: number
  level: number
  xp: number
  nextLevelXp: number
  pvpRating: number
  pvpWins: number
  pvpLosses: number

  // Hastane / Cezaevi durumu
  inHospital: boolean
  hospitalReleaseTime: number // Unix timestamp
  hospitalReason: string
  inPrison: boolean
  prisonReleaseTime: number // Unix timestamp
  prisonReason: string

  // Envanter
  inventory: InventoryItem[]
  equipment: EquipmentSlots

  // Aktif görevler
  activeQuests: QuestData[]

  // Lonca
  guildId: string
  guildRole: string

  // Eylemler
  loadPlayerData: (data: Record<string, unknown>) => void
  updateEnergy: (value: number) => void
  updateGold: (delta: number, relative?: boolean) => void
  updateTolerance: (value: number) => void
  setHospitalStatus: (inHospital: boolean, releaseTime: number, reason?: string) => void
  setPrisonStatus: (inPrison: boolean, releaseTime: number, reason?: string) => void
  setInventory: (items: InventoryItem[]) => void
  setEquipment: (slots: EquipmentSlots) => void
  addQuestToActive: (quest: QuestData) => void
  removeQuestFromActive: (questId: string) => void
  logout: () => void
  fetchPlayerProfile: () => Promise<{ success: boolean; data?: PlayerData; error?: string }>
  checkHospitalStatus: () => void
  checkPrisonStatus: () => void
}

export const usePlayerStore = create<PlayerState>()(
  subscribeWithSelector((set, get) => ({
    player: null,
    isLoaded: false,
    currentEnergy: 100,
    maxEnergy: 100,
    tolerance: 0,
    gold: 0,
    gems: 0,
    level: 1,
    xp: 0,
    nextLevelXp: 1000,
    pvpRating: 1000,
    pvpWins: 0,
    pvpLosses: 0,
    inHospital: false,
    hospitalReleaseTime: 0,
    hospitalReason: '',
    inPrison: false,
    prisonReleaseTime: 0,
    prisonReason: '',
    inventory: [],
    equipment: {},
    activeQuests: [],
    guildId: '',
    guildRole: '',

    loadPlayerData: (data: Record<string, unknown>) => {
      const player = formatPlayerData(data)

      // Hastane durumu
      let inHospital = (data.in_hospital as boolean) ?? false
      let hospitalReleaseTime = 0
      const hospitalUntil = data.hospital_until as string | null
      if (hospitalUntil) {
        hospitalReleaseTime = Math.floor(new Date(hospitalUntil).getTime() / 1000)
        inHospital = hospitalReleaseTime > Math.floor(Date.now() / 1000)
      }

      // Cezaevi durumu
      let inPrison = (data.in_prison as boolean) ?? false
      let prisonReleaseTime = 0
      const prisonUntil = data.prison_until as string | null
      if (prisonUntil) {
        prisonReleaseTime = Math.floor(new Date(prisonUntil).getTime() / 1000)
        inPrison = prisonReleaseTime > Math.floor(Date.now() / 1000)
      }

      const level = (data.level as number) ?? 1
      const currentEnergy = (data.energy as number) ?? (data.current_energy as number) ?? 100

      set({
        player,
        isLoaded: true,
        currentEnergy,
        maxEnergy: (data.max_energy as number) ?? 100,
        tolerance: (data.addiction_level as number) ?? (data.tolerance as number) ?? 0,
        gold: (data.gold as number) ?? 0,
        gems: (data.gems as number) ?? 0,
        level,
        xp: (data.experience as number) ?? (data.xp as number) ?? 0,
        nextLevelXp: calculateNextLevelXp(level),
        pvpRating: (data.pvp_rating as number) ?? 1000,
        pvpWins: (data.pvp_wins as number) ?? 0,
        pvpLosses: (data.pvp_losses as number) ?? 0,
        inHospital,
        hospitalReleaseTime,
        hospitalReason: (data.hospital_reason as string) ?? '',
        inPrison,
        prisonReleaseTime,
        prisonReason: (data.prison_reason as string) ?? '',
        guildId: (data.guild_id as string) ?? '',
        guildRole: (data.guild_role as string) ?? '',
      })
    },

    updateEnergy: (value: number) => {
      set((state) => ({
        currentEnergy: Math.max(0, Math.min(value, state.maxEnergy)),
        player: state.player ? { ...state.player, current_energy: value } : null,
      }))
    },

    updateGold: (delta: number, relative = false) => {
      set((state) => {
        const newGold = relative ? state.gold + delta : delta
        return {
          gold: Math.max(0, newGold),
          player: state.player ? { ...state.player, gold: Math.max(0, newGold) } : null,
        }
      })
    },

    updateTolerance: (value: number) => {
      set((state) => ({
        tolerance: Math.max(0, Math.min(100, value)),
        player: state.player ? { ...state.player, tolerance: value } : null,
      }))
    },

    setHospitalStatus: (inHospital: boolean, releaseTime: number, reason = '') => {
      set((state) => ({
        inHospital,
        hospitalReleaseTime: releaseTime,
        hospitalReason: reason,
        player: state.player
          ? { ...state.player, in_hospital: inHospital, hospital_release_time: releaseTime }
          : null,
      }))
    },

    setPrisonStatus: (inPrison: boolean, releaseTime: number, reason = '') => {
      set((state) => ({
        inPrison,
        prisonReleaseTime: releaseTime,
        prisonReason: reason,
        player: state.player
          ? { ...state.player, in_prison: inPrison, prison_reason: reason }
          : null,
      }))
    },

    setInventory: (items: InventoryItem[]) => set({ inventory: items }),
    setEquipment: (slots: EquipmentSlots) => set({ equipment: slots }),

    addQuestToActive: (quest: QuestData) => {
      set((state) => ({ activeQuests: [...state.activeQuests, quest] }))
    },

    removeQuestFromActive: (questId: string) => {
      set((state) => ({ activeQuests: state.activeQuests.filter((q) => q.id !== questId) }))
    },

    logout: () => {
      set({
        player: null,
        isLoaded: false,
        currentEnergy: 100,
        maxEnergy: 100,
        tolerance: 0,
        gold: 0,
        gems: 0,
        level: 1,
        xp: 0,
        nextLevelXp: 1000,
        pvpRating: 1000,
        pvpWins: 0,
        pvpLosses: 0,
        inHospital: false,
        hospitalReleaseTime: 0,
        hospitalReason: '',
        inPrison: false,
        prisonReleaseTime: 0,
        prisonReason: '',
        inventory: [],
        equipment: {},
        activeQuests: [],
        guildId: '',
        guildRole: '',
      })
    },

    fetchPlayerProfile: async () => {
      try {
        const result = await callEdgeFunction<Record<string, unknown>>('player-profile')

        if (result.success && result.data) {
          get().loadPlayerData(result.data)
          const player = formatPlayerData(result.data)
          return { success: true, data: player }
        }

        return { success: false, error: result.error ?? 'Profil yüklenemedi' }
      } catch (err) {
        const message = err instanceof Error ? err.message : 'Bilinmeyen hata'
        return { success: false, error: message }
      }
    },

    checkHospitalStatus: () => {
      const { inHospital, hospitalReleaseTime } = get()
      if (inHospital && hospitalReleaseTime > 0) {
        const now = Math.floor(Date.now() / 1000)
        if (now >= hospitalReleaseTime) {
          set({ inHospital: false, hospitalReleaseTime: 0, hospitalReason: '' })
        }
      }
    },

    checkPrisonStatus: () => {
      const { inPrison, prisonReleaseTime } = get()
      if (inPrison && prisonReleaseTime > 0) {
        const now = Math.floor(Date.now() / 1000)
        if (now >= prisonReleaseTime) {
          set({ inPrison: false, prisonReleaseTime: 0, prisonReason: '' })
        }
      }
    },
  }))
)

// Oturum kapanınca player store'u sıfırla
if (typeof window !== 'undefined') {
  window.addEventListener('player-logout', () => {
    usePlayerStore.getState().logout()
  })

  window.addEventListener('player-data-loaded', ((e: Event) => {
    const customEvent = e as CustomEvent<Record<string, unknown>>
    usePlayerStore.getState().loadPlayerData(customEvent.detail)
  }) as EventListener)

  // Supabase auth değişikliklerini dinle
  supabase.auth.onAuthStateChange((event) => {
    if (event === 'SIGNED_OUT') {
      usePlayerStore.getState().logout()
    }
  })
}
