// =====================================================
// lib/managers/pvpManager.ts - PvP sistemi
// GDScript PvPManager.gd'den dönüştürüldü
// =====================================================

import supabase from '@/lib/supabase'
import { usePlayerStore } from '@/store/playerStore'
import { calculateWinChance, PVP_CONFIG } from '@/types/pvp'
import { hasEnergy, consumeEnergy } from './energyManager'
import type { PvPMatch, PvPTarget, PvPStats } from '@/types/pvp'

/**
 * PvP hedeflerini getir
 */
export async function fetchPvPTargets(): Promise<PvPTarget[]> {
  const store = usePlayerStore.getState()

  try {
    const { data, error } = await supabase
      .from('users')
      .select('id, username, display_name, level, power, reputation, guild_id, avatar_url')
      .neq('id', store.player?.id)
      .order('level', { ascending: false })
      .limit(20)

    if (error) return []

    return (data ?? []).map((u: Record<string, unknown>) => ({
      player_id: u.id as string,
      username: u.username as string,
      display_name: u.display_name as string ?? u.username as string,
      level: u.level as number ?? 1,
      power: u.power as number ?? 100,
      reputation: u.reputation as number ?? 0,
      avatar_url: u.avatar_url as string ?? '',
      is_online: false,
      last_seen: '',
      gold_estimate: Math.floor((u.level as number ?? 1) * 100 * PVP_CONFIG.goldStealPercentage),
      win_probability: calculateWinChance(
        store.player?.power ?? 100,
        u.power as number ?? 100
      ),
    }))
  } catch {
    return []
  }
}

/**
 * Oyuncuya saldır
 */
export async function attackPlayer(
  targetPlayerId: string
): Promise<{ success: boolean; match?: PvPMatch; error?: string }> {
  const store = usePlayerStore.getState()

  // Enerji kontrolü
  if (!hasEnergy(PVP_CONFIG.energyCost)) {
    return {
      success: false,
      error: `Yetersiz enerji. PvP için ${PVP_CONFIG.energyCost} enerji gerekli.`,
    }
  }

  // Hastane / cezaevi kontrolü
  if (store.inHospital) {
    return { success: false, error: 'Hastanede olduğunuz için PvP yapamazsınız' }
  }
  if (store.inPrison) {
    return { success: false, error: 'Cezaevinde olduğunuz için PvP yapamazsınız' }
  }

  try {
    // Gerçek sunucu saldırısı (ilerde edge function ile)
    const attackerPower = store.player?.power ?? 100
    const { data: targetData } = await supabase
      .from('users')
      .select('id, username, level, power, gold, reputation')
      .eq('id', targetPlayerId)
      .single()

    if (!targetData) {
      return { success: false, error: 'Hedef oyuncu bulunamadı' }
    }

    // Sonucu simüle et
    const winChance = calculateWinChance(attackerPower, (targetData as Record<string, unknown>).power as number ?? 100)
    const won = Math.random() < winChance

    const goldChange = won
      ? Math.floor(((targetData as Record<string, unknown>).gold as number ?? 0) * PVP_CONFIG.goldStealPercentage)
      : 0
    const reputationChange = won
      ? PVP_CONFIG.reputationLossPerAttack
      : PVP_CONFIG.reputationLossPerAttack * 2

    // Enerji tüket
    consumeEnergy(PVP_CONFIG.energyCost)

    // Altını güncelle
    if (goldChange > 0) {
      store.updateGold(goldChange, true)
    }

    const match: PvPMatch = {
      id: `pvp-${Date.now()}`,
      attacker_id: store.player?.id ?? '',
      attacker_username: store.player?.username ?? '',
      attacker_level: store.player?.level ?? 1,
      attacker_power: attackerPower,
      defender_id: targetPlayerId,
      defender_username: (targetData as Record<string, unknown>).username as string ?? '',
      defender_level: (targetData as Record<string, unknown>).level as number ?? 1,
      defender_power: (targetData as Record<string, unknown>).power as number ?? 100,
      outcome: won ? 'win' : 'loss',
      gold_change: won ? goldChange : 0,
      reputation_change: reputationChange,
      xp_earned: Math.floor(Math.random() * 50) + 10,
      attacker_hospitalized: false,
      defender_hospitalized: won && Math.random() < 0.1,
      occurred_at: new Date().toISOString(),
      is_revenge: false,
    }

    return { success: true, match }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'PvP saldırısı başarısız'
    return { success: false, error: message }
  }
}

/**
 * PvP istatistiklerini getir
 */
export async function fetchPvPStats(): Promise<PvPStats> {
  const store = usePlayerStore.getState()

  const defaultStats: PvPStats = {
    wins: store.pvpWins,
    losses: store.pvpLosses,
    draws: 0,
    rating: store.pvpRating,
    rank: 0,
    win_streak: 0,
    best_win_streak: 0,
    total_gold_earned: 0,
    total_gold_lost: 0,
    reputation: store.player?.reputation ?? 0,
  }

  try {
    const { data } = await supabase
      .from('pvp_stats')
      .select('*')
      .eq('player_id', store.player?.id)
      .single()

    if (!data) return defaultStats
    return { ...defaultStats, ...(data as Partial<PvPStats>) }
  } catch {
    return defaultStats
  }
}

/**
 * PvP geçmişini getir
 */
export async function fetchPvPHistory(
  type: 'attack' | 'defense' = 'attack'
): Promise<PvPMatch[]> {
  const store = usePlayerStore.getState()

  try {
    const column = type === 'attack' ? 'attacker_id' : 'defender_id'
    const { data, error } = await supabase
      .from('pvp_battles')
      .select('*')
      .eq(column, store.player?.id)
      .order('occurred_at', { ascending: false })
      .limit(20)

    if (error) return []
    return (data ?? []) as PvPMatch[]
  } catch {
    return []
  }
}
