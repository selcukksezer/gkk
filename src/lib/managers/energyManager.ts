// =====================================================
// lib/managers/energyManager.ts - Enerji sistemi
// GDScript EnergyManager.gd'den dönüştürüldü
// =====================================================

import { usePlayerStore } from '@/store/playerStore'
import { clamp, calculateOfflineEnergyRegen } from '@/lib/utils/mathUtils'

// Enerji config değerleri (game_config.json'dan)
const ENERGY_CONFIG = {
  maxEnergy: 100,
  regenRatePerInterval: 1, // interval başına yenileme
  regenIntervalSeconds: 180, // 3 dakikada bir
  refillCostGems: 50,
  dailyRefillsLimit: 5,
}

/**
 * Oyuncunun yeterli enerjisi var mı?
 */
export function hasEnergy(amount: number): boolean {
  const { currentEnergy } = usePlayerStore.getState()
  return currentEnergy >= amount
}

/**
 * Enerji tüket (UI günceller, sunucu doğrular)
 */
export function consumeEnergy(amount: number): boolean {
  const store = usePlayerStore.getState()
  if (!hasEnergy(amount)) return false
  store.updateEnergy(store.currentEnergy - amount)
  return true
}

/**
 * Enerji ekle (ödül, yenileme vs.)
 */
export function addEnergy(amount: number): void {
  const store = usePlayerStore.getState()
  const newEnergy = clamp(store.currentEnergy + amount, 0, store.maxEnergy)
  store.updateEnergy(newEnergy)
}

/**
 * Offline enerji yenilemeyi hesapla ve uygula
 */
export function applyOfflineEnergyRegen(lastRegenTime: number): number {
  const store = usePlayerStore.getState()
  const newEnergy = calculateOfflineEnergyRegen(
    lastRegenTime,
    store.currentEnergy,
    store.maxEnergy,
    ENERGY_CONFIG.regenRatePerInterval / (ENERGY_CONFIG.regenIntervalSeconds / 60)
  )
  const gained = newEnergy - store.currentEnergy
  if (gained > 0) {
    store.updateEnergy(newEnergy)
  }
  return gained
}

/**
 * Enerji yenileme zamanlayıcısı (React hook ile kullanmak için)
 */
export function getEnergyRegenIntervalMs(): number {
  return ENERGY_CONFIG.regenIntervalSeconds * 1000
}

/**
 * Sıradaki enerji yenilemesine kalan süre (saniye)
 */
export function getSecondsUntilNextRegen(lastRegenTime: number): number {
  const now = Math.floor(Date.now() / 1000)
  const nextRegen = lastRegenTime + ENERGY_CONFIG.regenIntervalSeconds
  return Math.max(0, nextRegen - now)
}

export { ENERGY_CONFIG }
