// =====================================================
// lib/managers/facilityManager.ts - Tesis sistemi
// GDScript FacilityManager.gd (autoload)'dan dönüştürüldü
// =====================================================

import { callEdgeFunction } from '@/lib/supabase'
import { usePlayerStore } from '@/store/playerStore'
import type { PlayerFacility, FacilityType } from '@/types/facility'

/**
 * Tüm tesisleri getir
 */
export async function fetchFacilities(): Promise<{
  success: boolean
  data?: PlayerFacility[]
  error?: string
}> {
  const result = await callEdgeFunction<{ facilities?: PlayerFacility[]; data?: PlayerFacility[] }>(
    'get_player_facilities'
  )

  if (!result.success) {
    return { success: false, error: result.error }
  }

  const facilities = result.data?.facilities ?? result.data?.data ?? []
  return { success: true, data: facilities as PlayerFacility[] }
}

/**
 * Tesis aç
 */
export async function unlockFacility(
  facilityType: FacilityType
): Promise<{ success: boolean; error?: string }> {
  const store = usePlayerStore.getState()

  const result = await callEdgeFunction('unlock_facility', {
    facility_type: facilityType,
    player_id: store.player?.id,
  })

  return { success: result.success, error: result.error }
}

/**
 * Tesis yükselt
 */
export async function upgradeFacility(
  facilityId: string
): Promise<{ success: boolean; newLevel?: number; error?: string }> {
  const result = await callEdgeFunction<{ new_level?: number }>('upgrade_facility', {
    facility_id: facilityId,
  })

  if (result.success && result.data) {
    return { success: true, newLevel: result.data.new_level }
  }

  return { success: false, error: result.error }
}

/**
 * Üretim başlat
 */
export async function startProduction(
  facilityId: string,
  recipeId: string,
  quantity: number,
  rarity: string
): Promise<{ success: boolean; error?: string }> {
  const result = await callEdgeFunction('start_facility_production', {
    facility_id: facilityId,
    recipe_id: recipeId,
    quantity,
    rarity,
  })

  return { success: result.success, error: result.error }
}

/**
 * Üretimi topla
 */
export async function collectProduction(
  facilityId: string
): Promise<{ success: boolean; itemCount?: number; error?: string }> {
  const result = await callEdgeFunction<{ item_count?: number }>('collect_facility_production', {
    facility_id: facilityId,
  })

  if (result.success) {
    return { success: true, itemCount: result.data?.item_count }
  }

  return { success: false, error: result.error }
}

/**
 * Şüphe seviyesini düşür
 */
export async function reduceSuspicion(
  facilityId: string
): Promise<{ success: boolean; newSuspicion?: number; error?: string }> {
  const result = await callEdgeFunction<{ new_suspicion?: number }>('reduce_facility_suspicion', {
    facility_id: facilityId,
  })

  if (result.success) {
    return { success: true, newSuspicion: result.data?.new_suspicion }
  }

  return { success: false, error: result.error }
}

/**
 * Yetkilileri rüşvet ver
 */
export async function bribeOfficials(
  facilityId: string,
  amount: number
): Promise<{ success: boolean; goldSpent?: number; error?: string }> {
  const result = await callEdgeFunction<{ gold_spent?: number }>('bribe_officials', {
    facility_id: facilityId,
    bribe_amount: amount,
  })

  if (result.success) {
    if (result.data?.gold_spent) {
      usePlayerStore.getState().updateGold(-(result.data.gold_spent), true)
    }
    return { success: true, goldSpent: result.data?.gold_spent }
  }

  return { success: false, error: result.error }
}

/**
 * Tesis reçetelerini getir
 */
export async function getFacilityRecipes(
  facilityType: FacilityType
): Promise<{ success: boolean; recipes?: unknown[]; error?: string }> {
  const result = await callEdgeFunction<{ recipes?: unknown[] }>('get_facility_recipes', {
    facility_type: facilityType,
  })

  if (result.success) {
    return { success: true, recipes: result.data?.recipes ?? [] }
  }

  return { success: false, error: result.error }
}

/**
 * Offline üretimi hesapla
 */
export async function calculateOfflineProduction(
  facilityId: string
): Promise<{ success: boolean; pendingItems?: number; error?: string }> {
  const result = await callEdgeFunction<{ pending_items?: number }>('calculate_offline_production', {
    facility_id: facilityId,
  })

  if (result.success) {
    return { success: true, pendingItems: result.data?.pending_items }
  }

  return { success: false, error: result.error }
}
