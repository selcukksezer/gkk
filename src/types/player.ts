// =====================================================
// types/player.ts - Oyuncu veri modelleri
// GDScript PlayerData.gd'den dönüştürüldü
// =====================================================

export interface PlayerData {
  id: string
  username: string
  display_name: string
  level: number
  experience: number
  experience_to_next_level: number

  // Para birimleri
  gold: number
  gems: number
  season_points: number

  // Enerji sistemi
  current_energy: number
  max_energy: number
  last_energy_regen: number // Unix timestamp

  // Bağımlılık sistemi
  tolerance: number // 0-100
  addiction_level?: number
  last_tolerance_decay: number // Unix timestamp

  // Savaş istatistikleri
  power: number
  defense: number
  attack: number
  health: number
  max_health: number

  // PvP
  reputation: number // -100 ile +100 arası
  pvp_wins: number
  pvp_losses: number
  pvp_rank: number
  pvp_rating: number

  // Hastane
  in_hospital: boolean
  hospital_until: string | null // ISO datetime
  hospital_release_time?: number
  hospital_reason?: string

  // Cezaevi
  in_prison: boolean
  prison_until: string | null // ISO datetime
  prison_reason: string | null
  prison_release_time?: number

  // Lonca
  guild_id: string
  guild_role: GuildRole
  guild?: GuildData

  // İstatistikler
  total_quests_completed: number
  total_pvp_battles: number
  total_gold_earned: number
  total_items_crafted: number

  // Meta
  created_at: string
  last_login: string
  last_save?: string
  auth_id?: string

  // Unvanlar & Kozmetikler
  titles: string[]
  active_title: string
  avatar_url: string
  frame: string
  badge: string

  // Sezon
  xp?: number
  next_level_xp?: number
}

export type GuildRole = 'lord' | 'commander' | 'member' | 'apprentice' | ''

export type ReputationStatus =
  | 'Legendary Hero'
  | 'Hero'
  | 'Noble'
  | 'Citizen'
  | 'Scoundrel'
  | 'Bandit'
  | 'Outlaw'

export function getReputationStatus(reputation: number): ReputationStatus {
  if (reputation >= 80) return 'Legendary Hero'
  if (reputation >= 50) return 'Hero'
  if (reputation >= 20) return 'Noble'
  if (reputation >= -20) return 'Citizen'
  if (reputation >= -50) return 'Scoundrel'
  if (reputation >= -80) return 'Bandit'
  return 'Outlaw'
}

export function calculateExpForLevel(level: number): number {
  return Math.floor(100 * Math.pow(1.15, level - 1))
}

export function calculateNextLevelXp(level: number): number {
  return Math.floor(1000 * Math.pow(level, 1.5))
}

export function formatPlayerData(raw: Record<string, unknown>): PlayerData {
  return {
    id: (raw.id as string) ?? '',
    username: (raw.username as string) ?? '',
    display_name: (raw.display_name as string) ?? (raw.username as string) ?? '',
    level: (raw.level as number) ?? 1,
    experience: (raw.experience as number) ?? 0,
    experience_to_next_level:
      (raw.experience_to_next_level as number) ?? calculateExpForLevel(((raw.level as number) ?? 1) + 1),

    gold: (raw.gold as number) ?? 0,
    gems: (raw.gems as number) ?? 0,
    season_points: (raw.season_points as number) ?? 0,

    current_energy: (raw.energy as number) ?? (raw.current_energy as number) ?? 100,
    max_energy: (raw.max_energy as number) ?? 100,
    last_energy_regen: (raw.last_energy_regen as number) ?? 0,

    tolerance: (raw.tolerance as number) ?? (raw.addiction_level as number) ?? 0,
    addiction_level: (raw.addiction_level as number) ?? 0,
    last_tolerance_decay: (raw.last_tolerance_decay as number) ?? 0,

    power: (raw.power as number) ?? 100,
    defense: (raw.defense as number) ?? 50,
    attack: (raw.attack as number) ?? 50,
    health: (raw.health as number) ?? 100,
    max_health: (raw.max_health as number) ?? 100,

    reputation: (raw.reputation as number) ?? 0,
    pvp_wins: (raw.pvp_wins as number) ?? 0,
    pvp_losses: (raw.pvp_losses as number) ?? 0,
    pvp_rank: (raw.pvp_rank as number) ?? 0,
    pvp_rating: (raw.pvp_rating as number) ?? 1000,

    in_hospital: (raw.in_hospital as boolean) ?? false,
    hospital_until: (raw.hospital_until as string) ?? null,
    hospital_reason: (raw.hospital_reason as string) ?? '',

    in_prison: (raw.in_prison as boolean) ?? false,
    prison_until: (raw.prison_until as string) ?? null,
    prison_reason: (raw.prison_reason as string) ?? null,

    guild_id: (raw.guild_id as string) ?? '',
    guild_role: ((raw.guild_role as GuildRole) ?? '') as GuildRole,
    guild: (raw.guild as GuildData) ?? undefined,

    total_quests_completed: (raw.total_quests_completed as number) ?? 0,
    total_pvp_battles: (raw.total_pvp_battles as number) ?? 0,
    total_gold_earned: (raw.total_gold_earned as number) ?? 0,
    total_items_crafted: (raw.total_items_crafted as number) ?? 0,

    created_at: (raw.created_at as string) ?? '',
    last_login: (raw.last_login as string) ?? '',
    last_save: (raw.last_save as string) ?? undefined,
    auth_id: (raw.auth_id as string) ?? undefined,

    titles: (raw.titles as string[]) ?? [],
    active_title: (raw.active_title as string) ?? '',
    avatar_url: (raw.avatar_url as string) ?? '',
    frame: (raw.frame as string) ?? '',
    badge: (raw.badge as string) ?? '',
  }
}

// Geçici import – circular dependency önlemek için interface burada tanımlanır
export interface GuildData {
  id: string
  name: string
  level: number
  description: string
  member_count: number
  max_members: number
  treasury_gold: number
  leader_id: string
  leader_name: string
  created_at: string
  zone_controlled: string
  emblem: string
  total_power: number
}
