// =====================================================
// types/item.ts - Eşya veri modelleri
// GDScript ItemData.gd, InventoryItemData.gd, ItemDatabase.gd'den dönüştürüldü
// =====================================================

export type ItemRarity = 'common' | 'uncommon' | 'rare' | 'epic' | 'legendary' | 'mythic'
export type ItemType =
  | 'weapon'
  | 'armor'
  | 'helmet'
  | 'shield'
  | 'boots'
  | 'gloves'
  | 'ring'
  | 'necklace'
  | 'consumable'
  | 'material'
  | 'quest'
  | 'misc'

export type ItemSlotType =
  | 'head'
  | 'chest'
  | 'legs'
  | 'hands'
  | 'feet'
  | 'weapon'
  | 'offhand'
  | 'ring1'
  | 'ring2'
  | 'necklace'
  | 'none'

export interface ItemStats {
  attack?: number
  defense?: number
  health?: number
  speed?: number
  luck?: number
  magic?: number
  power?: number
}

// Eşya şablonu (items_database.json'dan gelen)
export interface ItemData {
  id: string
  name: string
  description: string
  type: ItemType
  rarity: ItemRarity
  slot: ItemSlotType
  stats: ItemStats
  value: number // Altın değeri
  gem_value?: number
  level_requirement: number
  icon: string // icon adı/url
  stackable: boolean
  max_stack: number
  consumable_effect?: {
    energy_restore?: number
    health_restore?: number
    tolerance_add?: number
    duration?: number
  }
  enhancement_max_level?: number
  sell_price: number
  buy_price?: number
}

// Oyuncunun envanterindeki eşya örneği
export interface InventoryItem {
  id: string // UUID
  player_id: string
  item_id: string
  item_data?: ItemData // Bağlı şablon
  quantity: number
  enhancement_level: number // 0-10
  slot_index: number // Envanter pozisyonu
  is_equipped: boolean
  equipped_slot?: ItemSlotType
  acquired_at: string
}

// Ekipman slotları
export type EquipmentSlots = Partial<Record<ItemSlotType, InventoryItem>>

// Nadirlik renk haritası
export const RARITY_COLORS: Record<ItemRarity, string> = {
  common: '#9ca3af',
  uncommon: '#22c55e',
  rare: '#3b82f6',
  epic: '#a855f7',
  legendary: '#f59e0b',
  mythic: '#ef4444',
}

// Nadirlik Türkçe adları
export const RARITY_NAMES: Record<ItemRarity, string> = {
  common: 'Sıradan',
  uncommon: 'Sıradışı',
  rare: 'Nadir',
  epic: 'Destansı',
  legendary: 'Efsanevi',
  mythic: 'Mitsel',
}

// Tür Türkçe adları
export const ITEM_TYPE_NAMES: Record<ItemType, string> = {
  weapon: 'Silah',
  armor: 'Zırh',
  helmet: 'Miğfer',
  shield: 'Kalkan',
  boots: 'Bot',
  gloves: 'Eldiven',
  ring: 'Yüzük',
  necklace: 'Kolye',
  consumable: 'Sarf Malzeme',
  material: 'Malzeme',
  quest: 'Görev Eşyası',
  misc: 'Diğer',
}

// Geliştirme maliyeti hesaplama
export function calculateEnhancementCost(currentLevel: number, baseValue: number): number {
  return Math.floor(baseValue * Math.pow(1.8, currentLevel))
}

// Geliştirme başarı şansı
export function calculateEnhancementChance(currentLevel: number): number {
  const chances = [100, 90, 80, 70, 60, 50, 40, 30, 25, 20, 15]
  return chances[Math.min(currentLevel, chances.length - 1)]
}
