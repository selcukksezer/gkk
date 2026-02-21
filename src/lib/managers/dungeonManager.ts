// =====================================================
// lib/managers/dungeonManager.ts - Zindan sistemi
// GDScript DungeonManager.gd'den dönüştürüldü
// =====================================================

import supabase from '@/lib/supabase'
import { usePlayerStore } from '@/store/playerStore'
import { clamp, randInt } from '@/lib/utils/mathUtils'
import type { DungeonDefinition, DungeonOutcome, DungeonDifficulty } from '@/types/dungeon'
import {
  BASE_SUCCESS_RATES,
  HOSPITALIZE_RATES,
  DUNGEON_SUCCESS_WEIGHTS,
} from '@/types/dungeon'
import { consumeEnergy, hasEnergy } from './energyManager'

// Başarı oranı ağırlıkları (DungeonManager.gd'den)
const MIN_SUCCESS_RATE = 0.10
const MAX_SUCCESS_RATE = 0.95

/**
 * Zindan başarı oranını hesapla (istemci tarafı önizleme)
 * Gerçek hesaplama sunucu tarafında yapılır.
 */
export function calculateSuccessRate(
  dungeon: DungeonDefinition,
  playerPower: number,
  playerLevel: number
): number {
  const baseRate = BASE_SUCCESS_RATES[dungeon.difficulty]

  // Gear etkisi
  const gearBonus = Math.min(playerPower / 1000, 1.0) * DUNGEON_SUCCESS_WEIGHTS.gear
  // Seviye etkisi (seviye gereksiniminin üzerindeyse bonus)
  const levelBonus =
    (playerLevel / Math.max(dungeon.required_level, 1)) * DUNGEON_SUCCESS_WEIGHTS.level

  // Tehlike penaltısı
  const dangerPenalty = (dungeon.danger_level / 100) * DUNGEON_SUCCESS_WEIGHTS.danger

  const successRate = baseRate + gearBonus + levelBonus - dangerPenalty
  return clamp(successRate, MIN_SUCCESS_RATE, MAX_SUCCESS_RATE)
}

/**
 * Zindanı başlat
 */
export async function startDungeon(
  dungeon: DungeonDefinition
): Promise<{ success: boolean; error?: string; instance_id?: string }> {
  const store = usePlayerStore.getState()

  // Enerji kontrolü
  if (!hasEnergy(dungeon.energy_cost)) {
    return {
      success: false,
      error: `Yetersiz enerji (${store.currentEnergy}/${dungeon.energy_cost})`,
    }
  }

  // Hastane / cezaevi kontrolü
  if (store.inHospital) {
    return { success: false, error: 'Hastanede olduğunuz için zindana giremezsiniz' }
  }
  if (store.inPrison) {
    return { success: false, error: 'Cezaevinde olduğunuz için zindana giremezsiniz' }
  }

  try {
    const { data, error } = await supabase
      .from('dungeon_instances')
      .insert({
        player_id: store.player?.id,
        dungeon_id: dungeon.id,
        dungeon_name: dungeon.name,
        difficulty: dungeon.difficulty,
        energy_cost: dungeon.energy_cost,
        status: 'running',
      })
      .select('id')
      .single()

    if (error) {
      return { success: false, error: error.message }
    }

    // Enerji tüket
    consumeEnergy(dungeon.energy_cost)

    return { success: true, instance_id: data?.id as string }
  } catch (err) {
    // Tablo mevcut değilse (geliştirme ortamı) simüle et
    console.warn('[DungeonManager] DB not available, simulating locally')
    consumeEnergy(dungeon.energy_cost)
    return { success: true, instance_id: `local-${Date.now()}` }
  }
}

/**
 * Zindan sonucunu hesapla (sunucu simülasyonu – geliştirme için)
 */
export function simulateDungeonOutcome(
  dungeon: DungeonDefinition,
  playerPower: number,
  playerLevel: number
): DungeonOutcome {
  const successRate = calculateSuccessRate(dungeon, playerPower, playerLevel)
  const roll = Math.random()
  const success = roll <= successRate

  if (success) {
    const goldEarned = randInt(dungeon.min_reward_gold, dungeon.max_reward_gold)
    const xpEarned = Math.floor(goldEarned * 0.5)

    return {
      success: true,
      hospitalized: false,
      gold_earned: goldEarned,
      xp_earned: xpEarned,
      items_earned: [],
      message: getSuccessMessage(dungeon.difficulty),
    }
  } else {
    const hospRisk = HOSPITALIZE_RATES[dungeon.difficulty]
    const hospitalized = Math.random() < hospRisk

    return {
      success: false,
      hospitalized,
      gold_earned: 0,
      xp_earned: Math.floor(randInt(10, 50)),
      items_earned: [],
      message: hospitalized
        ? 'Başarısız oldunuz ve hastaneye kaldırıldınız!'
        : 'Başarısız oldunuz ama sağ salim çıkmayı başardınız.',
      hospital_duration_minutes: hospitalized ? randInt(60, 360) : undefined,
    }
  }
}

function getSuccessMessage(difficulty: DungeonDifficulty): string {
  const messages: Record<DungeonDifficulty, string[]> = {
    EASY: ['Kolay bir zafer!', 'Hiç terlemedik.', 'Sıradan bir gün.'],
    MEDIUM: ['İyi iş çıkardınız!', 'Dengeli bir savaş.', 'Zordu ama başardınız.'],
    HARD: ['Harika! Zorlu bir düşmanı yendiniz!', 'Epik bir zafer!', 'Zor kazanıldı.'],
    DUNGEON: [
      'MUHTEŞEM! Efsanevi bir zafer!',
      'Zindan tamanlanandı – efsane olmak bu!',
      'Destansı bir başarı!',
    ],
  }
  const opts = messages[difficulty]
  return opts[Math.floor(Math.random() * opts.length)]
}
