// =====================================================
// lib/utils/dateTimeUtils.ts - Tarih/zaman yardımcıları
// GDScript DateTimeUtils.gd'den dönüştürüldü
// =====================================================

/**
 * Unix timestamp'i Türkçe okunabilir formata çevirir
 */
export function formatTimestamp(unixTimestamp: number): string {
  const date = new Date(unixTimestamp * 1000)
  return date.toLocaleString('tr-TR', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  })
}

/**
 * ISO datetime string'i Türkçe okunabilir formata çevirir
 */
export function formatIsoDateTime(isoString: string): string {
  if (!isoString) return ''
  const date = new Date(isoString)
  if (isNaN(date.getTime())) return isoString
  return date.toLocaleString('tr-TR', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  })
}

/**
 * Saniye cinsinden süreyi HH:MM:SS formatına çevirir
 */
export function formatDuration(seconds: number): string {
  if (seconds <= 0) return '0s'
  const h = Math.floor(seconds / 3600)
  const m = Math.floor((seconds % 3600) / 60)
  const s = Math.floor(seconds % 60)

  if (h > 0) return `${h}s ${m}d ${s}sn`
  if (m > 0) return `${m}d ${s}sn`
  return `${s}sn`
}

/**
 * Kısa süre formatı (geri sayım için)
 */
export function formatCountdown(seconds: number): string {
  if (seconds <= 0) return '00:00:00'
  const h = Math.floor(seconds / 3600)
  const m = Math.floor((seconds % 3600) / 60)
  const s = Math.floor(seconds % 60)
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`
}

/**
 * ISO datetime string'i Unix timestamp'e çevirir
 */
export function isoToUnix(isoString: string): number {
  if (!isoString) return 0
  return Math.floor(new Date(isoString).getTime() / 1000)
}

/**
 * ISO datetime string'inden kalan saniye hesapla
 */
export function getRemainingSecondsFromIso(isoString: string | null): number {
  if (!isoString) return 0
  const releaseTime = new Date(isoString).getTime()
  const now = Date.now()
  return Math.max(0, Math.floor((releaseTime - now) / 1000))
}

/**
 * "x saat önce" veya "x dakika önce" gibi göreli zaman
 */
export function timeAgo(isoString: string): string {
  const date = new Date(isoString)
  const now = new Date()
  const diffSeconds = Math.floor((now.getTime() - date.getTime()) / 1000)

  if (diffSeconds < 60) return 'az önce'
  if (diffSeconds < 3600) return `${Math.floor(diffSeconds / 60)} dakika önce`
  if (diffSeconds < 86400) return `${Math.floor(diffSeconds / 3600)} saat önce`
  if (diffSeconds < 2592000) return `${Math.floor(diffSeconds / 86400)} gün önce`
  return formatIsoDateTime(isoString)
}

/**
 * Şimdiki zamanı ISO formatında döndür
 */
export function nowIso(): string {
  return new Date().toISOString()
}

/**
 * Şimdiki zamanı Unix timestamp olarak döndür
 */
export function nowUnix(): number {
  return Math.floor(Date.now() / 1000)
}
