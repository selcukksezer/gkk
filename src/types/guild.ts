// =====================================================
// types/guild.ts - Lonca veri modelleri
// GDScript GuildData.gd, GuildMemberData.gd'den dönüştürüldü
// =====================================================

export type GuildRole = 'lord' | 'commander' | 'member' | 'apprentice'

export interface GuildData {
  id: string
  name: string
  description: string
  emblem: string
  level: number
  experience: number
  member_count: number
  max_members: number
  treasury_gold: number
  treasury_gems: number
  leader_id: string
  leader_name: string
  created_at: string
  zone_controlled: string
  total_power: number
  is_recruiting: boolean
  min_level_requirement: number
  guild_points: number
}

export interface GuildMember {
  id: string
  player_id: string
  username: string
  display_name: string
  role: GuildRole
  level: number
  power: number
  joined_at: string
  last_seen: string
  contribution_gold: number
  contribution_points: number
  is_online: boolean
}

export interface GuildWar {
  id: string
  attacker_guild_id: string
  attacker_guild_name: string
  defender_guild_id: string
  defender_guild_name: string
  status: 'pending' | 'active' | 'ended'
  started_at: string
  ends_at: string
  attacker_score: number
  defender_score: number
  winner_guild_id?: string
  zone?: string
}

export interface GuildTask {
  id: string
  name: string
  description: string
  type: 'collect' | 'kill' | 'craft' | 'donate'
  required_amount: number
  current_amount: number
  reward_points: number
  reward_gold: number
  expires_at: string
}

// Lonca rütbe Türkçe adları
export const GUILD_ROLE_NAMES: Record<GuildRole, string> = {
  lord: 'Lord',
  commander: 'Komutan',
  member: 'Üye',
  apprentice: 'Çırak',
}

// Lonca rütbe hiyerarşisi
export const GUILD_ROLE_LEVELS: Record<GuildRole, number> = {
  lord: 4,
  commander: 3,
  member: 2,
  apprentice: 1,
}
