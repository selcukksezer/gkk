// =====================================================
// lib/api/endpoints.ts - API endpoint sabitleri
// GDScript APIEndpoints.gd'den dönüştürüldü
// =====================================================

export const API = {
  // Kimlik doğrulama (Supabase Edge Functions)
  AUTH: {
    LOGIN: 'auth-login',
    REGISTER: 'auth-register',
  },

  // Oyuncu
  PLAYER: {
    PROFILE: 'player-profile',
  },

  // Enerji
  ENERGY: {
    STATUS: 'energy-status',
    REFILL: 'energy-refill',
  },

  // Hastane (Supabase RPC)
  HOSPITAL: {
    GET_STATUS: 'get_hospital_status',
    ADMIT: 'admit_to_hospital',
    RELEASE: 'release_from_hospital',
    RELEASE_WITH_GEMS: 'release_with_gems',
  },

  // Cezaevi (Supabase RPC)
  PRISON: {
    GET_STATUS: 'get_prison_status',
    RELEASE: 'release_from_prison',
    PAY_BAIL: 'pay_prison_bail',
  },

  // Tesisler (Supabase Edge Functions)
  FACILITIES: {
    GET_ALL: 'get_player_facilities',
    UNLOCK: 'unlock_facility',
    UPGRADE: 'upgrade_facility',
    START_PRODUCTION: 'start_facility_production',
    COLLECT: 'collect_facility_production',
    OFFLINE: 'calculate_offline_production',
    ADD_SUSPICION: 'increment_facility_suspicion',
    REDUCE_SUSPICION: 'reduce_facility_suspicion',
    BRIBE: 'bribe_officials',
    RECIPES: 'get_facility_recipes',
  },

  // REST endpoints (Supabase PostgREST)
  REST: {
    USERS: '/users',
    INVENTORY: '/inventory',
    EQUIPMENT: '/equipment',
    QUESTS: '/quests',
    ACTIVE_QUESTS: '/active_quests',
    PVP_HISTORY: '/pvp_battles',
    GUILD: '/guilds',
    GUILD_MEMBERS: '/guild_members',
    LEADERBOARD: '/leaderboard',
    MARKET_LISTINGS: '/market_listings',
    MARKET_ORDERS: '/market_orders',
    SEASON: '/seasons',
    ACHIEVEMENTS: '/achievements',
    CHAT_MESSAGES: '/chat_messages',
  },
} as const

// Supabase proje URL'i
export const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL ?? 'https://znvsyzstmxhqvdkkmgdt.supabase.co'
