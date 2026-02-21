// =====================================================
// types/pvp.ts - PvP savaş veri modelleri
// GDScript PvPData.gd, PvPManager.gd'den dönüştürüldü
// =====================================================

export type PvPOutcome = 'major_win' | 'win' | 'draw' | 'loss' | 'major_loss'

export interface PvPMatch {
  id: string
  attacker_id: string
  attacker_username: string
  attacker_level: number
  attacker_power: number
  defender_id: string
  defender_username: string
  defender_level: number
  defender_power: number
  outcome: PvPOutcome
  gold_change: number
  reputation_change: number
  xp_earned: number
  attacker_hospitalized: boolean
  defender_hospitalized: boolean
  occurred_at: string
  is_revenge: boolean
  elo_change?: number
}

export interface PvPTarget {
  player_id: string
  username: string
  display_name: string
  level: number
  power: number
  reputation: number
  guild_name?: string
  avatar_url?: string
  is_online: boolean
  last_seen: string
  gold_estimate: number // Çalınabilir tahmini altın
  win_probability: number // 0.0-1.0
  can_revenge?: boolean
  revenge_expires_at?: string
}

export interface PvPStats {
  wins: number
  losses: number
  draws: number
  rating: number // ELO
  rank: number
  win_streak: number
  best_win_streak: number
  total_gold_earned: number
  total_gold_lost: number
  reputation: number
}

// PvP hesapları
export function calculateWinChance(attackerPower: number, defenderPower: number): number {
  const BASE_CHANCE = 0.5
  const POWER_FACTOR = 0.01
  const powerDiff = attackerPower - defenderPower
  const chance = BASE_CHANCE + powerDiff * POWER_FACTOR
  return Math.max(0.05, Math.min(0.95, chance))
}

// PvP config (game_config.json'dan)
export const PVP_CONFIG = {
  energyCost: 15,
  revengeTimeWindow: 86400,
  revengeEnergyCost: 0,
  criticalChance: 0.1,
  hospitalDurationCritical: 28800,
  goldStealPercentage: 0.05,
  reputationLossPerAttack: -3,
  reputationGainDefend: 5,
  banditReputationThreshold: -50,
  heroReputationThreshold: 50,
  maxAttacksPerDay: 50,
}

// Sonuç Türkçe adları
export const OUTCOME_NAMES: Record<PvPOutcome, string> = {
  major_win: 'Büyük Zafer',
  win: 'Zafer',
  draw: 'Beraberlik',
  loss: 'Mağlubiyet',
  major_loss: 'Büyük Mağlubiyet',
}

// Sonuç renkleri
export const OUTCOME_COLORS: Record<PvPOutcome, string> = {
  major_win: '#22c55e',
  win: '#4ade80',
  draw: '#f59e0b',
  loss: '#f97316',
  major_loss: '#ef4444',
}
