// =====================================================
// lib/utils/mathUtils.ts - Matematik yardımcıları
// GDScript MathUtils.gd'den dönüştürüldü
// =====================================================

/**
 * Sayıyı okunabilir formata çevirir (K, M, B)
 * Örnek: 1234567 → "1.23M"
 */
export function formatNumber(value: number): string {
  if (value >= 1_000_000_000) {
    return `${(value / 1_000_000_000).toFixed(2)}B`
  }
  if (value >= 1_000_000) {
    return `${(value / 1_000_000).toFixed(2)}M`
  }
  if (value >= 1_000) {
    return `${(value / 1_000).toFixed(1)}K`
  }
  return value.toLocaleString('tr-TR')
}

/**
 * Yüzde formatı
 */
export function formatPercent(value: number, decimals = 1): string {
  return `${(value * 100).toFixed(decimals)}%`
}

/**
 * Bir değeri minimum ve maksimum arasında kısıtla
 */
export function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value))
}

/**
 * Rastgele sayı üret (min-max dahil)
 */
export function randInt(min: number, max: number): number {
  return Math.floor(Math.random() * (max - min + 1)) + min
}

/**
 * Rastgele float üret (min-max)
 */
export function randFloat(min: number, max: number): number {
  return Math.random() * (max - min) + min
}

/**
 * Lineer interpolasyon
 */
export function lerp(from: number, to: number, weight: number): number {
  return from + (to - from) * weight
}

/**
 * Seviyeye göre XP hesapla (üstel eğri)
 */
export function calculateXpForLevel(level: number): number {
  const BASE_XP = 1000
  return Math.floor(BASE_XP * Math.pow(level, 1.5))
}

/**
 * Enerji yenileme: offline geçen süreye göre enerji hesapla
 */
export function calculateOfflineEnergyRegen(
  lastRegenTime: number,
  currentEnergy: number,
  maxEnergy: number,
  regenRatePerMinute: number
): number {
  const now = Math.floor(Date.now() / 1000)
  const elapsedSeconds = now - lastRegenTime
  const elapsedMinutes = elapsedSeconds / 60
  const gained = Math.floor(elapsedMinutes * regenRatePerMinute)
  return Math.min(currentEnergy + gained, maxEnergy)
}

/**
 * Hastane kuyruğundaki kalan süreyi saniye cinsinden hesapla
 */
export function getRemainingSeconds(releaseTimeIso: string): number {
  const releaseMs = new Date(releaseTimeIso).getTime()
  const nowMs = Date.now()
  return Math.max(0, Math.floor((releaseMs - nowMs) / 1000))
}

/**
 * Tesis üretim hızını seviyeye göre hesapla
 */
export function calculateProductionRate(baseRate: number, level: number): number {
  return baseRate * level
}

/**
 * Güçlenme maliyeti hesaplama (üstel)
 */
export function calculateEnhancementCost(currentLevel: number, baseValue: number): number {
  return Math.floor(baseValue * Math.pow(1.8, currentLevel))
}

/**
 * ELO değişimi hesapla
 */
export function calculateEloChange(
  myRating: number,
  opponentRating: number,
  won: boolean,
  kFactor = 32
): number {
  const expectedScore = 1 / (1 + Math.pow(10, (opponentRating - myRating) / 400))
  const actualScore = won ? 1 : 0
  return Math.round(kFactor * (actualScore - expectedScore))
}
