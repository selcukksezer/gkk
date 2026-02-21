// =====================================================
// types/quest.ts - Görev veri modelleri
// GDScript QuestData.gd'den dönüştürüldü
// =====================================================

export type QuestType = 'daily' | 'weekly' | 'story' | 'guild' | 'event'
export type QuestDifficulty = 'easy' | 'medium' | 'hard' | 'dungeon'
export type QuestStatus = 'available' | 'active' | 'completed' | 'failed' | 'locked'

export interface QuestObjective {
  id: string
  description: string
  target_type: string // 'kill_enemies', 'collect_items', 'visit_location', etc.
  target_id?: string
  required_amount: number
  current_amount: number
  completed: boolean
}

export interface QuestReward {
  gold?: number
  gems?: number
  experience?: number
  items?: Array<{ item_id: string; quantity: number }>
  reputation?: number
  season_points?: number
}

export interface QuestData {
  id: string
  name: string
  description: string
  type: QuestType
  difficulty: QuestDifficulty
  status: QuestStatus
  energy_cost: number
  level_requirement: number
  objectives: QuestObjective[]
  rewards: QuestReward
  time_limit?: number // Saniye cinsinden
  started_at?: string
  expires_at?: string
  completed_at?: string
  repeatable: boolean
  cooldown_hours?: number
  icon?: string
  category?: string
}

// Görev zorluk Türkçe adları
export const QUEST_DIFFICULTY_NAMES: Record<QuestDifficulty, string> = {
  easy: 'Kolay',
  medium: 'Orta',
  hard: 'Zor',
  dungeon: 'Zindan',
}

// Görev türü Türkçe adları
export const QUEST_TYPE_NAMES: Record<QuestType, string> = {
  daily: 'Günlük',
  weekly: 'Haftalık',
  story: 'Hikaye',
  guild: 'Lonca',
  event: 'Etkinlik',
}

// Enerji maliyeti config'den alınıyor
export const QUEST_ENERGY_COSTS: Record<QuestDifficulty, number> = {
  easy: 5,
  medium: 10,
  hard: 15,
  dungeon: 20,
}
