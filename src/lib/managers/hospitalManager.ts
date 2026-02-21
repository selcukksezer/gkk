// =====================================================
// lib/managers/hospitalManager.ts - Hastane sistemi
// GDScript HospitalManager.gd'den dönüştürüldü
// =====================================================

import { callRpc } from '@/lib/supabase'
import { usePlayerStore } from '@/store/playerStore'
import { getRemainingSecondsFromIso } from '@/lib/utils/dateTimeUtils'

/**
 * Hastane durumunu sunucudan çek
 */
export async function fetchHospitalStatus(): Promise<{
  success: boolean
  inHospital: boolean
  releaseTime: number
  reason: string
  error?: string
}> {
  const store = usePlayerStore.getState()
  const authId = store.player?.auth_id ?? ''

  if (!authId) {
    return { success: false, inHospital: false, releaseTime: 0, reason: '', error: 'auth_id yok' }
  }

  const result = await callRpc<Array<{ in_hospital: boolean; release_time: number; hospital_reason: string }>>(
    'get_hospital_status',
    { p_auth_id: authId }
  )

  if (!result.success || !result.data) {
    // Yerel duruma geri dön
    return {
      success: false,
      inHospital: store.inHospital,
      releaseTime: store.hospitalReleaseTime,
      reason: store.hospitalReason,
      error: result.error,
    }
  }

  const rows = result.data
  if (!rows || rows.length === 0) {
    return { success: true, inHospital: false, releaseTime: 0, reason: '' }
  }

  const row = rows[0]
  const inHospital = row.in_hospital ?? false
  const releaseTime = (row.release_time ?? 0) as number

  // Store'u güncelle
  store.setHospitalStatus(inHospital, releaseTime, row.hospital_reason ?? '')

  return {
    success: true,
    inHospital,
    releaseTime,
    reason: row.hospital_reason ?? '',
  }
}

/**
 * Elmas ile hastaneden çık
 */
export async function releaseWithGems(): Promise<{ success: boolean; error?: string }> {
  const store = usePlayerStore.getState()
  const authId = store.player?.auth_id ?? ''

  const result = await callRpc('release_with_gems', { p_auth_id: authId })

  if (result.success) {
    store.setHospitalStatus(false, 0)
    return { success: true }
  }

  return { success: false, error: result.error ?? 'İşlem başarısız' }
}

/**
 * Hastane çıkış gem maliyetini hesapla
 */
export function calculateGemCost(releaseTimeUnix: number): number {
  const remainingSeconds = Math.max(0, releaseTimeUnix - Math.floor(Date.now() / 1000))
  const hours = Math.floor(remainingSeconds / 3600)
  const minutes = Math.ceil((remainingSeconds % 3600) / 60)
  return hours + minutes
}

/**
 * ISO datetime'dan kalan süre hesapla
 */
export function getRemainingHospitalTime(hospitalUntil: string | null): number {
  if (!hospitalUntil) return 0
  return getRemainingSecondsFromIso(hospitalUntil)
}
