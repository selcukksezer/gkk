// =====================================================
// types/facility.ts - Tesis veri modelleri
// GDScript FacilityManager.gd'den dönüştürüldü
// =====================================================

export type FacilityType =
  // Temel Kaynaklar (1-5)
  | 'mining'
  | 'quarry'
  | 'lumber_mill'
  | 'clay_pit'
  | 'sand_quarry'
  // Organik Kaynaklar (6-10)
  | 'farming'
  | 'herb_garden'
  | 'ranch'
  | 'apiary'
  | 'mushroom_farm'
  // Mistik Kaynaklar (11-15)
  | 'rune_mine'
  | 'holy_spring'
  | 'shadow_pit'
  | 'elemental_forge'
  | 'time_well'

export interface FacilityConfig {
  name: string
  icon: string
  description: string
  resources: string[]
  base_rate: number // saat başına
  unlock_level: number
  unlock_cost: number
  base_upgrade_cost: number
  upgrade_multiplier: number
  tier: 1 | 2 | 3
  emoji: string
}

export interface PlayerFacility {
  id: string
  player_id: string
  facility_type: FacilityType
  level: number
  is_active: boolean
  suspicion_level: number // 0-100
  production_queue: ProductionQueueItem[]
  last_collection: string
  unlocked_at: string
  total_produced: number
}

export interface ProductionQueueItem {
  id: string
  facility_id: string
  recipe_id: string
  recipe_name: string
  quantity: number
  rarity: string
  started_at: string
  duration_seconds: number
  completed_at: string
  status: 'queued' | 'running' | 'completed' | 'collected'
}

export interface FacilityRecipe {
  id: string
  facility_type: FacilityType
  name: string
  output_item_id: string
  output_quantity: number
  duration_seconds: number
  energy_cost: number
  required_level: number
  rarity_options: string[]
  common_chance: number
  uncommon_chance: number
  rare_chance: number
  epic_chance: number
}

// 15 Tesis yapılandırması (FacilityManager.gd'den dönüştürüldü)
export const FACILITIES_CONFIG: Record<FacilityType, FacilityConfig> = {
  // ===== TEMEL KAYNAKLAR (Tier 1) =====
  mining: {
    name: 'Maden Ocağı',
    icon: 'mining',
    emoji: '⛏️',
    description: 'Demir, bakır, altın ve gümüş cevheri çıkarır',
    resources: ['iron_ore', 'copper_ore', 'gold_ore', 'silver_ore'],
    base_rate: 10.0,
    unlock_level: 1,
    unlock_cost: 500,
    base_upgrade_cost: 1000,
    upgrade_multiplier: 1.5,
    tier: 1,
  },
  quarry: {
    name: 'Taş Ocağı',
    icon: 'quarry',
    emoji: '🪨',
    description: 'Granit, mermer ve kristal çıkarır',
    resources: ['granite', 'marble', 'crystal_shard'],
    base_rate: 8.0,
    unlock_level: 2,
    unlock_cost: 800,
    base_upgrade_cost: 1200,
    upgrade_multiplier: 1.5,
    tier: 1,
  },
  lumber_mill: {
    name: 'Kereste Fabrikası',
    icon: 'lumber_mill',
    emoji: '🪵',
    description: 'Meşe, çam ve bambu odunu üretir',
    resources: ['oak_wood', 'pine_wood', 'bamboo'],
    base_rate: 12.0,
    unlock_level: 3,
    unlock_cost: 1000,
    base_upgrade_cost: 1500,
    upgrade_multiplier: 1.5,
    tier: 1,
  },
  clay_pit: {
    name: 'Kil Ocağı',
    icon: 'clay_pit',
    emoji: '🏺',
    description: 'Seramik kili ve tuğla malzemesi çıkarır',
    resources: ['ceramic_clay', 'brick_clay'],
    base_rate: 15.0,
    unlock_level: 4,
    unlock_cost: 1200,
    base_upgrade_cost: 1800,
    upgrade_multiplier: 1.5,
    tier: 1,
  },
  sand_quarry: {
    name: 'Kum Ocağı',
    icon: 'sand_quarry',
    emoji: '🏖️',
    description: 'Cam kumu ve kristal kumu toplar',
    resources: ['glass_sand', 'crystal_sand'],
    base_rate: 20.0,
    unlock_level: 5,
    unlock_cost: 1500,
    base_upgrade_cost: 2000,
    upgrade_multiplier: 1.5,
    tier: 1,
  },
  // ===== ORGANİK KAYNAKLAR (Tier 2) =====
  farming: {
    name: 'Çiftlik',
    icon: 'farming',
    emoji: '🌾',
    description: 'Buğday, sebze ve pamuk yetiştirir',
    resources: ['wheat', 'vegetables', 'cotton'],
    base_rate: 18.0,
    unlock_level: 6,
    unlock_cost: 2000,
    base_upgrade_cost: 2500,
    upgrade_multiplier: 1.5,
    tier: 2,
  },
  herb_garden: {
    name: 'Ot Bahçesi',
    icon: 'herb_garden',
    emoji: '🌿',
    description: 'Şifalı otlar ve nadir bitkiler yetiştirir',
    resources: ['healing_herb', 'poison_herb', 'rare_flower'],
    base_rate: 10.0,
    unlock_level: 7,
    unlock_cost: 2500,
    base_upgrade_cost: 3000,
    upgrade_multiplier: 1.5,
    tier: 2,
  },
  ranch: {
    name: 'Hayvancılık',
    icon: 'ranch',
    emoji: '🐄',
    description: 'Et, deri ve kemik üretir',
    resources: ['meat', 'leather', 'bone'],
    base_rate: 8.0,
    unlock_level: 8,
    unlock_cost: 3000,
    base_upgrade_cost: 3500,
    upgrade_multiplier: 1.5,
    tier: 2,
  },
  apiary: {
    name: 'Arıcılık',
    icon: 'apiary',
    emoji: '🍯',
    description: 'Bal, balmumu ve kraliçe arı tozu üretir',
    resources: ['honey', 'beeswax', 'royal_jelly'],
    base_rate: 6.0,
    unlock_level: 9,
    unlock_cost: 3500,
    base_upgrade_cost: 4000,
    upgrade_multiplier: 1.5,
    tier: 2,
  },
  mushroom_farm: {
    name: 'Mantar Çiftliği',
    icon: 'mushroom_farm',
    emoji: '🍄',
    description: 'Yenilebilir mantarlar ve zehirli mantarlar yetiştirir',
    resources: ['edible_mushroom', 'poison_mushroom', 'magic_spore'],
    base_rate: 14.0,
    unlock_level: 10,
    unlock_cost: 4000,
    base_upgrade_cost: 4500,
    upgrade_multiplier: 1.5,
    tier: 2,
  },
  // ===== MİSTİK KAYNAKLAR (Tier 3) =====
  rune_mine: {
    name: 'Rune Madeni',
    icon: 'rune_mine',
    emoji: '🔮',
    description: 'Antik runlar ve büyülü kristaller çıkarır',
    resources: ['ancient_rune', 'magic_crystal', 'void_shard'],
    base_rate: 4.0,
    unlock_level: 11,
    unlock_cost: 6000,
    base_upgrade_cost: 7000,
    upgrade_multiplier: 2.0,
    tier: 3,
  },
  holy_spring: {
    name: 'Kutsal Kaynak',
    icon: 'holy_spring',
    emoji: '💧',
    description: 'Kutsal su, aziz tozu ve mistik çiçek toplar',
    resources: ['holy_water', 'saint_dust', 'mystic_petal'],
    base_rate: 3.0,
    unlock_level: 12,
    unlock_cost: 7000,
    base_upgrade_cost: 8000,
    upgrade_multiplier: 2.0,
    tier: 3,
  },
  shadow_pit: {
    name: 'Gölge Çukuru',
    icon: 'shadow_pit',
    emoji: '🌑',
    description: 'Gölge özü, karanlık taş ve kara tüy toplar',
    resources: ['shadow_essence', 'dark_stone', 'black_feather'],
    base_rate: 5.0,
    unlock_level: 13,
    unlock_cost: 8000,
    base_upgrade_cost: 9000,
    upgrade_multiplier: 2.0,
    tier: 3,
  },
  elemental_forge: {
    name: 'Elementel Ocak',
    icon: 'elemental_forge',
    emoji: '🔥',
    description: 'Ateş taşı, buz kristali ve şimşek tozu üretir',
    resources: ['fire_stone', 'ice_crystal', 'thunder_dust'],
    base_rate: 3.5,
    unlock_level: 14,
    unlock_cost: 10000,
    base_upgrade_cost: 12000,
    upgrade_multiplier: 2.0,
    tier: 3,
  },
  time_well: {
    name: 'Zaman Kuyusu',
    icon: 'time_well',
    emoji: '⌛',
    description: 'Zaman tozu, kadim yankı ve sonsuz ip toplar',
    resources: ['time_dust', 'ancient_echo', 'eternity_thread'],
    base_rate: 2.0,
    unlock_level: 15,
    unlock_cost: 15000,
    base_upgrade_cost: 18000,
    upgrade_multiplier: 2.5,
    tier: 3,
  },
}

// Tüm tesis tipleri
export const ALL_FACILITY_TYPES = Object.keys(FACILITIES_CONFIG) as FacilityType[]

// Seviye yükseltme maliyeti hesaplama
export function calculateUpgradeCost(facilityType: FacilityType, currentLevel: number): number {
  const config = FACILITIES_CONFIG[facilityType]
  return Math.floor(config.base_upgrade_cost * Math.pow(config.upgrade_multiplier, currentLevel - 1))
}

// Üretim oranı hesaplama
export function calculateProductionRate(facilityType: FacilityType, level: number): number {
  const config = FACILITIES_CONFIG[facilityType]
  return config.base_rate * level
}
