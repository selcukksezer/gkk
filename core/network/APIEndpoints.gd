class_name APIEndpoints
extends RefCounted
## API Endpoints - Centralized endpoint definitions
## All API endpoints for the game

## Base URLs
const BASE_URL = "https://your-project.supabase.co"
const API_VERSION = "/api/v1"

## Authentication
const AUTH_LOGIN = "/functions/v1/auth-login"
const AUTH_REGISTER = "/functions/v1/auth-register"
const AUTH_LOGOUT = "/auth/v1/logout"
const AUTH_REFRESH = "/auth/v1/token?grant_type=refresh_token"
const AUTH_RESET_PASSWORD = "/auth/v1/recover"

## Player
const PLAYER_PROFILE = API_VERSION + "/player/profile"
const PLAYER_UPDATE = API_VERSION + "/player/update"
const PLAYER_STATS = API_VERSION + "/player/stats"
const PLAYER_SEARCH = API_VERSION + "/player/search"

## Energy
const ENERGY_STATUS = API_VERSION + "/energy/status"
const ENERGY_REFILL = API_VERSION + "/energy/refill"
const ENERGY_SYNC = API_VERSION + "/energy/sync"

## Inventory
const INVENTORY_LIST = API_VERSION + "/inventory"
const INVENTORY_ADD = API_VERSION + "/inventory/add"
const INVENTORY_REMOVE = API_VERSION + "/inventory/remove"
const INVENTORY_EQUIP = API_VERSION + "/inventory/equip"
const INVENTORY_UNEQUIP = API_VERSION + "/inventory/unequip"

## Potion/Addiction
const POTION_USE = API_VERSION + "/potion/use"
const POTION_TOLERANCE = API_VERSION + "/potion/tolerance"
const POTION_LIST = API_VERSION + "/potion/list"

## Hospital
const HOSPITAL_STATUS = API_VERSION + "/hospital/status"
const HOSPITAL_RELEASE = API_VERSION + "/hospital/release"
const HOSPITAL_CALL_HEALER = API_VERSION + "/hospital/healer"
const HOSPITAL_GUILD_HELP = API_VERSION + "/hospital/guild-help"

## Quests
const QUEST_LIST = API_VERSION + "/quests"
const QUEST_START = API_VERSION + "/quests/start"
const QUEST_COMPLETE = API_VERSION + "/quests/complete"
const QUEST_ABANDON = API_VERSION + "/quests/abandon"
const QUEST_DAILY = API_VERSION + "/quests/daily"
const QUEST_PROGRESS = API_VERSION + "/quests/progress"

## PvP
const PVP_LIST_TARGETS = API_VERSION + "/pvp/targets"
const PVP_ATTACK = API_VERSION + "/pvp/attack"
const PVP_REVENGE = API_VERSION + "/pvp/revenge"
const PVP_HISTORY = API_VERSION + "/pvp/history"
const PVP_LEADERBOARD = API_VERSION + "/pvp/leaderboard"

## Market
const MARKET_TICKER = API_VERSION + "/market/ticker"
const MARKET_ORDER_BOOK = API_VERSION + "/market/orderbook"
const MARKET_CREATE_ORDER = API_VERSION + "/market/order"
const MARKET_CANCEL_ORDER = API_VERSION + "/market/order/cancel"
const MARKET_MY_ORDERS = API_VERSION + "/market/orders/mine"
const MARKET_TRADE_HISTORY = API_VERSION + "/market/history"
const MARKET_REGIONS = API_VERSION + "/market/regions"

## Guild
const GUILD_LIST = API_VERSION + "/guild/list"
const GUILD_CREATE = API_VERSION + "/guild/create"
const GUILD_JOIN = API_VERSION + "/guild/join"
const GUILD_LEAVE = API_VERSION + "/guild/leave"
const GUILD_INFO = API_VERSION + "/guild/info"
const GUILD_MEMBERS = API_VERSION + "/guild/members"
const GUILD_INVITE = API_VERSION + "/guild/invite"
const GUILD_KICK = API_VERSION + "/guild/kick"
const GUILD_PROMOTE = API_VERSION + "/guild/promote"
const GUILD_DEMOTE = API_VERSION + "/guild/demote"
const GUILD_TREASURY = API_VERSION + "/guild/treasury"
const GUILD_DONATE = API_VERSION + "/guild/donate"
const GUILD_CHAT = API_VERSION + "/guild/chat"

## Crafting/Enhancement
const CRAFT_RECIPE = API_VERSION + "/craft/recipe"
const CRAFT_ITEM = API_VERSION + "/craft/create"
const ENHANCE_ITEM = API_VERSION + "/enhance"
const ENHANCE_CALCULATE = API_VERSION + "/enhance/calculate"

## Leaderboard
const LEADERBOARD_GLOBAL = API_VERSION + "/leaderboard/global"
const LEADERBOARD_SEASON = API_VERSION + "/leaderboard/season"
const LEADERBOARD_GUILD = API_VERSION + "/leaderboard/guild"

## Shop
const SHOP_LIST = API_VERSION + "/shop/items"
const SHOP_BUY = API_VERSION + "/shop/buy"
const SHOP_BUNDLES = API_VERSION + "/shop/bundles"

## Config
const CONFIG_GAME = API_VERSION + "/config/game"
const CONFIG_ITEMS = API_VERSION + "/config/items"
const CONFIG_QUESTS = API_VERSION + "/config/quests"

## Telemetry
const TELEMETRY_EVENT = API_VERSION + "/telemetry/events"
const TELEMETRY_BATCH = API_VERSION + "/telemetry/events"

## WebSocket
const WS_URL = "wss://your-project.supabase.co/realtime/v1"

## Build full URL
static func get_url(endpoint: String) -> String:
	if endpoint.begins_with("http"):
		return endpoint
	return BASE_URL + endpoint

## Build query string
static func build_query_string(params: Dictionary) -> String:
	if params.is_empty():
		return ""
	
	var parts: Array[String] = []
	for key in params:
		parts.append("%s=%s" % [key, params[key]])
	
	return "?" + "&".join(parts)

## Build endpoint with query params
static func with_params(endpoint: String, params: Dictionary) -> String:
	return endpoint + build_query_string(params)
