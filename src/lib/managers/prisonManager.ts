// =====================================================
// lib/managers/prisonManager.ts - Cezaevi sistemi
// GDScript PrisonManager.gd'den dönüştürüldü
// =====================================================

import { callRpc } from '@/lib/supabase'
import { usePlayerStore } from '@/store/playerStore'
import { getRemainingSecondsFromIso } from '@/lib/utils/dateTimeUtils'

/**
 * Cezaevi durumunu sunucudan çek
 */
export async function fetchPrisonStatus(): Promise<{
  success: boolean
  inPrison: boolean
  releaseTime: number
  reason: string
  error?: string
}> {
  const store = usePlayerStore.getState()
  const authId = store.player?.auth_id ?? ''

  if (!authId) {
    return { success: false, inPrison: false, releaseTime: 0, reason: '', error: 'auth_id yok' }
  }

  const result = await callRpc<Array<{
    in_prison: boolean
    release_time: number
    prison_reason: string
  }>>('get_prison_status', { p_auth_id: authId })

  if (!result.success || !result.data) {
    return {
      success: false,
      inPrison: store.inPrison,
      releaseTime: store.prisonReleaseTime,
      reason: store.prisonReason,
      error: result.error,
    }
  }

  const rows = result.data
  if (!rows || rows.length === 0) {
    return { success: true, inPrison: false, releaseTime: 0, reason: '' }
  }

  const row = rows[0]
  const inPrison = row.in_prison ?? false
  const releaseTime = (row.release_time ?? 0) as number

  store.setPrisonStatus(inPrison, releaseTime, row.prison_reason ?? '')

  return {
    success: true,
    inPrison,
    releaseTime,
    reason: row.prison_reason ?? '',
  }
}

/**
 * Kefalet öde
 */
export async function payBail(): Promise<{ success: boolean; error?: string }> {
  const store = usePlayerStore.getState()
  const authId = store.player?.auth_id ?? ''

  const result = await callRpc('pay_prison_bail', { p_auth_id: authId })

  if (result.success) {
    store.setPrisonStatus(false, 0)
    return { success: true }
  }

  return { success: false, error: result.error ?? 'Kefalet ödemesi başarısız' }
}

/**
 * Kalan cezaevi süresi (saniye)
 */
export function getRemainingPrisonTime(prisonUntil: string | null): number {
  if (!prisonUntil) return 0
  return getRemainingSecondsFromIso(prisonUntil)
}

/**
 * Kefalet altın maliyeti hesapla
 */
export function calculateBailCost(releaseTimeUnix: number): number {
  const remainingSeconds = Math.max(0, releaseTimeUnix - Math.floor(Date.now() / 1000))
  const remainingHours = remainingSeconds / 3600
  const BASE_BAIL_PER_HOUR = 500
  return Math.ceil(remainingHours * BASE_BAIL_PER_HOUR)
}
