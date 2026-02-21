// =====================================================
// types/dungeon.ts - Zindan veri modelleri
// GDScript DungeonData.gd, DungeonInstance.gd'den dönüştürüldü
// =====================================================

export type DungeonDifficulty = 'EASY' | 'MEDIUM' | 'HARD' | 'DUNGEON'

export interface DungeonDefinition {
  id: string
  name: string
  description: string
  difficulty: DungeonDifficulty
  required_level: number
  energy_cost: number
  danger_level: number // 0-100
  min_reward_gold: number
  max_reward_gold: number
  base_success_rate: number // 0.0-1.0
  estimated_duration_seconds: number
  hospitalization_risk: number // 0.0-1.0
  icon?: string
  loot_table?: DungeonLootEntry[]
  boss_name?: string
  zone?: string
  is_group?: boolean
  max_participants?: number
}

export interface DungeonLootEntry {
  item_id: string
  drop_chance: number // 0.0-1.0
  min_quantity: number
  max_quantity: number
  rarity_weight: number
}

// Aktif zindan koşusu
export interface DungeonInstance {
  instance_id: string
  player_id: string
  dungeon_id: string
  dungeon_name: string
  difficulty: DungeonDifficulty
  started_at: string
  energy_cost: number
  base_success_rate: number
  estimated_duration: number
  status: 'running' | 'completed' | 'failed' | 'hospitalized'
  outcome?: DungeonOutcome
}

export interface DungeonOutcome {
  success: boolean
  hospitalized: boolean
  gold_earned: number
  xp_earned: number
  items_earned: Array<{ item_id: string; quantity: number; rarity: string }>
  message: string
  hospital_duration_minutes?: number
}

// Zindan başarı oranı ağırlıkları (GDScript DungeonManager.gd'den)
export const DUNGEON_SUCCESS_WEIGHTS = {
  gear: 0.25,
  skill: 0.15,
  level: 0.15,
  difficulty: 0.20,
  danger: 0.15,
}

// Temel başarı oranları
export const BASE_SUCCESS_RATES: Record<DungeonDifficulty, number> = {
  EASY: 0.85,
  MEDIUM: 0.70,
  HARD: 0.55,
  DUNGEON: 0.45,
}

// Hastanelik riskleri
export const HOSPITALIZE_RATES: Record<DungeonDifficulty, number> = {
  EASY: 0.0,
  MEDIUM: 0.05,
  HARD: 0.15,
  DUNGEON: 0.25,
}

// Zindan güçlük Türkçe adları
export const DUNGEON_DIFFICULTY_NAMES: Record<DungeonDifficulty, string> = {
  EASY: 'Kolay',
  MEDIUM: 'Orta',
  HARD: 'Zor',
  DUNGEON: 'Zindan',
}

// Güçlük renkleri
export const DUNGEON_DIFFICULTY_COLORS: Record<DungeonDifficulty, string> = {
  EASY: '#22c55e',
  MEDIUM: '#f59e0b',
  HARD: '#f97316',
  DUNGEON: '#ef4444',
}

// Mock zindan verisi (backend hazır olana kadar)
export const MOCK_DUNGEONS: DungeonDefinition[] = [
  {
    id: 'dungeon_tutorial_grotto',
    name: 'Başlangıç Mağarası',
    description: 'Yeni kahramanlar için basit düşmanlar ve küçük ödüller.',
    difficulty: 'EASY',
    required_level: 1,
    energy_cost: 5,
    danger_level: 10,
    min_reward_gold: 10,
    max_reward_gold: 50,
    base_success_rate: 0.90,
    estimated_duration_seconds: 300,
    hospitalization_risk: 0.0,
    zone: 'Başlangıç Alanı',
  },
  {
    id: 'dungeon_bandit_camp',
    name: 'Haydut Kampı',
    description: 'Yolları tutan haydutların üssünü temizle.',
    difficulty: 'MEDIUM',
    required_level: 5,
    energy_cost: 10,
    danger_level: 30,
    min_reward_gold: 100,
    max_reward_gold: 400,
    base_success_rate: 0.70,
    estimated_duration_seconds: 600,
    hospitalization_risk: 0.05,
    zone: 'Orta Alanlar',
  },
  {
    id: 'dungeon_dark_fortress',
    name: 'Karanlık Kale',
    description: 'Lanetli kaledeki kötü ruhları temizle.',
    difficulty: 'HARD',
    required_level: 15,
    energy_cost: 15,
    danger_level: 60,
    min_reward_gold: 500,
    max_reward_gold: 2000,
    base_success_rate: 0.55,
    estimated_duration_seconds: 1200,
    hospitalization_risk: 0.15,
    zone: 'Karanlık Orman',
  },
  {
    id: 'dungeon_dark_forest',
    name: 'Karanlık Orman Zindanı',
    description: "Karanlık Orman'ın derinliklerini keşfet ve bos'u yen.",
    difficulty: 'DUNGEON',
    required_level: 10,
    energy_cost: 25,
    danger_level: 50,
    min_reward_gold: 500,
    max_reward_gold: 2000,
    base_success_rate: 0.45,
    estimated_duration_seconds: 1800,
    hospitalization_risk: 0.25,
    boss_name: 'Karanlık Ağaç Ruhu',
    zone: 'Karanlık Orman',
  },
  {
    id: 'dungeon_cursed_tomb',
    name: 'Lanetli Mezar',
    description: "Lanetli Mezar'ın sırlarını keşfet.",
    difficulty: 'DUNGEON',
    required_level: 15,
    energy_cost: 30,
    danger_level: 70,
    min_reward_gold: 1000,
    max_reward_gold: 5000,
    base_success_rate: 0.40,
    estimated_duration_seconds: 2400,
    hospitalization_risk: 0.30,
    boss_name: 'Lanetli Firavun',
    zone: 'Çöl Harabeleri',
  },
  {
    id: 'dungeon_dragon_lair',
    name: 'Ejderha Yuvası',
    description: "Ejderha Yuvası'na gir ve hazinesini al.",
    difficulty: 'DUNGEON',
    required_level: 25,
    energy_cost: 40,
    danger_level: 90,
    min_reward_gold: 3000,
    max_reward_gold: 10000,
    base_success_rate: 0.35,
    estimated_duration_seconds: 3000,
    hospitalization_risk: 0.35,
    boss_name: 'Kızıl Kanatlı Ejder',
    zone: 'Ejder Dağları',
  },
]
