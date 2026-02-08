extends Node
## FacilityManager.gd - Autoload for 15-Facility Production System
## Manages all RPC calls and signal routing for facility operations

# ==================== SIGNALS ====================
signal facilities_updated()
signal facility_unlocked(facility_id: String, facility_name: String)
signal production_started(facility_id: String, recipe_name: String, quantity: int, rarity: String)
signal production_completed(facility_id: String, item_name: String, rarity: String)
signal collection_triggered(facility_id: String, item_count: int)
signal suspicion_changed(facility_id: String, new_suspicion: int)
signal bribe_completed(facility_id: String, cost: int)
signal facility_upgraded(facility_id: String, new_level: int)
signal sent_to_prison(prison_hours: int, suspicion_was: int)

# ==================== FACILITY CONSTANTS ====================
# ==================== FACILITY CONFIGURATION ====================

# 15 Resource Facilities - Organized by Tier
const FACILITY_TYPES = {
	# Temel Kaynaklar (Basic Resources) - Level 1-5
	"mining": "Maden Ocağı",
	"quarry": "Taş Ocağı",
	"lumber_mill": "Kereste Fabrikası",
	"clay_pit": "Kil Ocağı",
	"sand_quarry": "Kum Ocağı",
	
	# Organik Kaynaklar (Organic Resources) - Level 6-10
	"farming": "Çiftlik",
	"herb_garden": "Ot Bahçesi",
	"ranch": "Hayvancılık",
	"apiary": "Arıcılık",
	"mushroom_farm": "Mantar Çiftliği",
	
	# Mistik Kaynaklar (Mystical Resources) - Level 11-15
	"rune_mine": "Rune Madeni",
	"holy_spring": "Kutsal Kaynak",
	"shadow_pit": "Gölge Çukuru",
	"elemental_forge": "Elementel Ocak",
	"time_well": "Zaman Kuyusu"
}

const FACILITIES_CONFIG = {
	# ===== TEMEL KAYNAKLAR (1-5) =====
	"mining": {
		"name": "Maden Ocağı",
		"icon": "res://assets/sprites/facilities/icon_mining.png",
		"description": "Demir, bakır, altın ve gümüş cevheri çıkarır",
		"resources": ["iron_ore", "copper_ore", "gold_ore", "silver_ore"],
		"base_rate": 10.0,  # per hour
		"unlock_level": 1,
		"unlock_cost": 500,
		"base_upgrade_cost": 1000,
		"upgrade_multiplier": 1.5
	},
	"quarry": {
		"name": "Taş Ocağı",
		"icon": "res://assets/sprites/facilities/icon_mining.png",
		"description": "Granit, mermer ve kristal çıkarır",
		"resources": ["granite", "marble", "crystal_shard"],
		"base_rate": 8.0,
		"unlock_level": 2,
		"unlock_cost": 800,
		"base_upgrade_cost": 1200,
		"upgrade_multiplier": 1.5
	},
	"lumber_mill": {
		"name": "Kereste Fabrikası",
		"icon": "res://assets/sprites/facilities/icon_woodworking.png",
		"description": "Meşe, çam ve bambu odunu üretir",
		"resources": ["oak_wood", "pine_wood", "bamboo"],
		"base_rate": 12.0,
		"unlock_level": 3,
		"unlock_cost": 1000,
		"base_upgrade_cost": 1500,
		"upgrade_multiplier": 1.5
	},
	"clay_pit": {
		"name": "Kil Ocağı",
		"icon": "res://assets/sprites/facilities/icon_mining.png",
		"description": "Seramik kili ve tuğla malzemesi çıkarır",
		"resources": ["ceramic_clay", "brick_clay"],
		"base_rate": 15.0,
		"unlock_level": 4,
		"unlock_cost": 1200,
		"base_upgrade_cost": 1800,
		"upgrade_multiplier": 1.5
	},
	"sand_quarry": {
		"name": "Kum Ocağı",
		"icon": "res://assets/sprites/facilities/icon_mining.png",
		"description": "Cam kumu ve kristal kumu toplar",
		"resources": ["glass_sand", "crystal_sand"],
		"base_rate": 20.0,
		"unlock_level": 5,
		"unlock_cost": 1500,
		"base_upgrade_cost": 2000,
		"upgrade_multiplier": 1.5
	},
	
	# ===== ORGANİK KAYNAKLAR (6-10) =====
	"farming": {
		"name": "Çiftlik",
		"icon": "res://assets/sprites/facilities/icon_farming.png",
		"description": "Buğday, sebze ve pamuk yetiştirir",
		"resources": ["wheat", "vegetables", "cotton"],
		"base_rate": 18.0,
		"unlock_level": 6,
		"unlock_cost": 2000,
		"base_upgrade_cost": 2500,
		"upgrade_multiplier": 1.5
	},
	"herb_garden": {
		"name": "Ot Bahçesi",
		"icon": "res://assets/sprites/facilities/icon_farming.png",
		"description": "Şifalı otlar ve nadir bitkiler yetiştirir",
		"resources": ["healing_herb", "poison_herb", "rare_flower"],
		"base_rate": 10.0,
		"unlock_level": 7,
		"unlock_cost": 2500,
		"base_upgrade_cost": 3000,
		"upgrade_multiplier": 1.5
	},
	"ranch": {
		"name": "Hayvancılık",
		"icon": "res://assets/sprites/facilities/icon_farming.png",
		"description": "Deri, kemik ve yün üretir",
		"resources": ["leather", "bone", "wool"],
		"base_rate": 12.0,
		"unlock_level": 8,
		"unlock_cost": 3000,
		"base_upgrade_cost": 3500,
		"upgrade_multiplier": 1.5
	},
	"apiary": {
		"name": "Arıcılık",
		"icon": "res://assets/sprites/facilities/icon_farming.png",
		"description": "Bal, balmumu ve arı zehiri toplar",
		"resources": ["honey", "beeswax", "bee_venom"],
		"base_rate": 8.0,
		"unlock_level": 9,
		"unlock_cost": 3500,
		"base_upgrade_cost": 4000,
		"upgrade_multiplier": 1.5
	},
	"mushroom_farm": {
		"name": "Mantar Çiftliği",
		"icon": "res://assets/sprites/facilities/icon_alchemy.png",
		"description": "Şifalı ve zehirli mantarlar yetiştirir",
		"resources": ["healing_mushroom", "poison_mushroom", "glowing_mushroom"],
		"base_rate": 10.0,
		"unlock_level": 10,
		"unlock_cost": 4000,
		"base_upgrade_cost": 5000,
		"upgrade_multiplier": 1.5
	},
	
	# ===== MİSTİK KAYNAKLAR (11-15) =====
	"rune_mine": {
		"name": "Rune Madeni",
		"icon": "res://assets/sprites/facilities/icon_runesmith.png",
		"description": "Ham rune taşları ve büyülü kristaller çıkarır",
		"resources": ["raw_rune", "magic_crystal", "energy_shard"],
		"base_rate": 5.0,
		"unlock_level": 11,
		"unlock_cost": 5000,
		"base_upgrade_cost": 6000,
		"upgrade_multiplier": 1.6
	},
	"holy_spring": {
		"name": "Kutsal Kaynak",
		"icon": "res://assets/sprites/facilities/icon_alchemy.png",
		"description": "Kutsal su ve mana kristalleri üretir",
		"resources": ["holy_water", "mana_crystal", "purification_water"],
		"base_rate": 6.0,
		"unlock_level": 12,
		"unlock_cost": 6000,
		"base_upgrade_cost": 7000,
		"upgrade_multiplier": 1.6
	},
	"shadow_pit": {
		"name": "Gölge Çukuru",
		"icon": "res://assets/sprites/facilities/icon_mining.png",
		"description": "Karanlık esans ve gölge kristalleri toplar",
		"resources": ["dark_essence", "shadow_crystal", "curse_dust"],
		"base_rate": 4.0,
		"unlock_level": 13,
		"unlock_cost": 7000,
		"base_upgrade_cost": 8000,
		"upgrade_multiplier": 1.6
	},
	"elemental_forge": {
		"name": "Elementel Ocak",
		"icon": "res://assets/sprites/facilities/icon_enhancement.png",
		"description": "Ateş, buz ve yıldırım esansı üretir",
		"resources": ["fire_essence", "ice_crystal", "lightning_core"],
		"base_rate": 5.0,
		"unlock_level": 14,
		"unlock_cost": 8000,
		"base_upgrade_cost": 10000,
		"upgrade_multiplier": 1.6
	},
	"time_well": {
		"name": "Zaman Kuyusu",
		"icon": "res://assets/sprites/facilities/icon_library.png",
		"description": "Zaman kristali ve hızlandırma tozu üretir",
		"resources": ["time_crystal", "aging_dust", "eternity_essence"],
		"base_rate": 3.0,
		"unlock_level": 15,
		"unlock_cost": 10000,
		"base_upgrade_cost": 12000,
		"upgrade_multiplier": 1.7
	}
}

# ==================== CACHE ====================
var cached_facilities: Dictionary = {}
var cached_recipes: Dictionary = {}
var last_cache_time: float = 0.0
var cache_duration: float = 60.0  # 60 seconds cache

# ==================== DETAIL SCREEN STATE ====================
var selected_facility_type: String = ""
var selected_facility_data: Dictionary = {}

# ==================== GETTERS ====================
func get_facility_name(facility_type: String) -> String:
	return FACILITY_TYPES.get(facility_type, facility_type)

func get_cached_facilities() -> Array:
	return cached_facilities.values()

# ==================== RPC WRAPPER: GET PLAYER FACILITIES ====================
func fetch_my_facilities(force_refresh: bool = false) -> Dictionary:
	# Check cache first
	if not force_refresh and Time.get_ticks_msec() / 1000.0 - last_cache_time < cache_duration and not cached_facilities.is_empty():
		# print("[FacilityManager] Returning cached facilities (Age: %.1fs)" % (Time.get_ticks_msec() / 1000.0 - last_cache_time))
		return {"success": true, "data": cached_facilities.values()}

	# Call RPC directly via REST API - no JWT auth header needed for RPC calls
	# RPC endpoint: /rest/v1/rpc/get_player_facilities_with_queue
	# print("[FacilityManager] Calling RPC: /rest/v1/rpc/get_player_facilities_with_queue")
	var response = await Network.http_post("/rest/v1/rpc/get_player_facilities_with_queue", {})
	# print("[FacilityManager] Raw RPC response: %s" % response)
	var result = {}
	
	if response.get("success", false):
		# RPC returns {success, data} where data is facilities array with facility_queue
		var response_data = response.get("data")
		# print("[FacilityManager] Response data type: %s, content: %s" % [typeof(response_data), response_data])
		
		if response_data is Dictionary and response_data.get("success", false):
			var facilities_array = response_data.get("data", [])
			# print("[FacilityManager] Facilities array type: %s, size: %s" % [typeof(facilities_array), facilities_array.size() if facilities_array is Array else "N/A"])
			
			if facilities_array is Array:
				cached_facilities = {}
				for facility in facilities_array:
					# Filter out inactive facilities on client side
					if facility.has("is_active") and not facility.get("is_active"):
						continue
						
					cached_facilities[facility.id] = facility
					var _queue = facility.get("facility_queue", [])
					
					# --- DEBUG REMOVED ---
					# print("[FacilityManager] Facility %s (%s): level=%s, queue_size=%s" % [facility.get("type"), facility.get("id"), facility.get("level"), queue.size()])
					# if queue.size() > 0:
					# 	print("[FacilityManager] Queue content for %s: %s" % [facility.get("type"), queue])
				
				last_cache_time = Time.get_ticks_msec() / 1000.0
				result = {"success": true, "data": facilities_array}
				# print("[FacilityManager] ✅ Fetched %d facilities WITH queue" % facilities_array.size())
				facilities_updated.emit()
			else:
				push_error("FacilityManager: Invalid facilities data type: %s" % typeof(facilities_array))
				result = {"success": false, "data": []}
		else:
			push_error("FacilityManager: RPC failed - success=%s, error=%s" % [response_data.get("success", false) if response_data is Dictionary else "N/A", response_data.get("error", "Unknown error") if response_data is Dictionary else str(response_data)])
			result = {"success": false, "data": []}
	else:
		push_error("FacilityManager: Network request failed - success=%s, error=%s, code=%s" % [response.get("success", false), response.get("error", "Unknown"), response.get("code", "N/A")])
		print("[FacilityManager] Full error response: %s" % response)
		result = {"success": false, "data": []}
	
	return result

# ==================== RPC WRAPPER: UNLOCK FACILITY ====================
func unlock_facility(facility_type: String) -> Dictionary:
	var player_id = Session.get_player_id()
	print("[FacilityManager] unlock_facility called for type: %s, player: %s" % [facility_type, player_id])
	
	# Server expects p_facility_type
	# Server expects p_type
	var response = await Network.http_post("/rest/v1/rpc/unlock_facility", {"p_type": facility_type})
	print("[FacilityManager] unlock_facility response: %s" % response)
	
	var result = {}
	
	if response is Dictionary and response.get("success", false):
		var rpc_result = response.get("data", {})
		if rpc_result is Dictionary and rpc_result.get("success", false):
			# Update gold in StateStore immediately for top bar refresh
			# RPC doesn't return remaining_gold in basic version, let's check basic impl
			# The basic impl unlock_facility returns {success: true} usually. 
			# Wait, in create_facilities_system.sql line 88 it returns {success: true} only.
			# So we should be careful about relying on returned data.
			# We'll trigger a full refresh.
			
			facility_unlocked.emit("", FACILITY_TYPES.get(facility_type, facility_type))
			facility_unlocked.emit("", FACILITY_TYPES.get(facility_type, facility_type))
			await fetch_my_facilities(true)
			# Refresh all player data from database (gold after unlock_cost deducted)
			await State.refresh_data()
				
			result = {"success": true}
			print("[FacilityManager] Facility unlocked successfully via RPC: %s" % facility_type)
		else:
			var err = rpc_result.get("error", "RPC Error") if rpc_result is Dictionary else "Invalid RPC Response"
			push_error("FacilityManager: Failed to unlock facility %s - %s" % [facility_type, err])
			result = {"success": false, "error": err}
	else:
		push_error("FacilityManager: Failed to unlock facility %s - %s" % [facility_type, response.get("error", "Unknown")])
		result = {"success": false, "error": response.get("error", "Unknown")}
	
	return result

# ==================== GLOBAL SUSPICION / RISK HELPER ====================
func get_global_suspicion_risk() -> int:
	# Calculate risk from facilities with ACTIVE production
	# Formula: (Facility Count * 5) + (Sum of Facility Levels * 0.5)
	# 
	# Risk INCREASES when production starts
	# Risk STAYS SAME while production runs (even if expired/ready for collection)
	# Risk DECREASES only when production is collected and cleared
	
	var active_count = 0
	var level_sum = 0
	
	# Count all facilities with active production (production_started_at != null)
	# Don't check duration — keep counting until collection clears production_started_at
	for facility in cached_facilities.values():
		var production_started_at = facility.get("production_started_at")
		# If production was ever started and not yet collected, count it
		if production_started_at != null:
			active_count += 1
			level_sum += facility.get("level", 1)
	
	# Formula: (Active Count * 5) + (Level Sum * 0.5)
	var risk = (active_count * 5) + (level_sum * 0.5)
	return int(clamp(risk, 0, 100))

# ==================== SYNC GLOBAL RISK TO DATABASE ====================
func sync_global_risk_to_database() -> Dictionary:
	# Calculate current risk and save to database
	# Server will subtract risk_baseline from this to get displayed risk
	var calculated_risk = get_global_suspicion_risk()
	print("[FacilityManager] [SYNC] Calculating risk to sync: %d%%" % calculated_risk)
	
	var response = await Network.http_post("/rest/v1/rpc/update_global_suspicion_level", {
		"p_global_suspicion": calculated_risk
	})
	
	print("[FacilityManager] [SYNC] Full RPC response: %s" % response)
	
	if response is Dictionary and response.get("success", false):
		var rpc_result = response.get("data", {})
		print("[FacilityManager] [SYNC] RPC data: %s" % rpc_result)
		if rpc_result is Dictionary and rpc_result.get("success", false):
			# Use the server-adjusted risk (new_level) which already subtracts baseline
			var adjusted_risk = rpc_result.get("new_level", 0)
			var baseline = rpc_result.get("baseline", 0)
			print("[FacilityManager] ✓ Global risk synced to DB | Calculated: %d%%, Baseline: %d%%, Displayed: %d%%" % [calculated_risk, int(baseline), adjusted_risk])
			# Update State's player data with DISPLAYED risk (after baseline subtraction)
			State.player["global_suspicion_level"] = adjusted_risk
			return {"success": true, "new_risk": adjusted_risk, "calculated_risk": calculated_risk, "baseline": baseline}
		else:
			var err_msg = rpc_result.get("error", "Unknown RPC Error") if rpc_result is Dictionary else str(rpc_result)
			print("[FacilityManager] ✗ Failed to sync global risk: %s" % err_msg)
			return {"success": false, "error": err_msg}
	else:
		var err_msg = response.get("error", "Unknown") if response is Dictionary else str(response)
		print("[FacilityManager] ✗ Failed to sync global risk (HTTP): %s" % err_msg)
		return {"success": false, "error": err_msg}

# ==================== RPC WRAPPER: COLLECT FACILITY PRODUCTION ====================
func collect_facility_production(facility_id: String) -> Dictionary:
	# RPC: collect_facility_production(p_facility_id UUID)
	print("[FacilityManager] Requesting collect_production for facility: %s" % facility_id)
	var response = await Network.http_post("/rest/v1/rpc/collect_facility_production", {"p_facility_id": facility_id})
	print("[FacilityManager] collect_production response: %s" % response)
	var result = {}
	
	if response is Dictionary and response.get("success", false):
		var rpc_result = response.get("data", {})
		# print("[FacilityManager] collect_production RPC data: %s" % rpc_result)
		
		# Check if rpc_result is the actual data or a wrapper
		# If rpc_result is Array, it might be the items directly?
		# Or if it's dictionary with success/data.
		
		# Based on previous pattern, let's assume standard success/data or direct return
		if rpc_result is Dictionary and rpc_result.get("success", false):
			var items = rpc_result.get("collected_items", [])
			collection_triggered.emit(facility_id, items.size())
			await fetch_my_facilities(true)
			# Refresh all player data from database (including gold from production)
			await State.refresh_data()
			# Refresh inventory to show collected items
			if Inventory:
				Inventory.fetch_inventory()
			result = {"success": true, "collected_items": items}
		elif rpc_result is Array: # Maybe it returns just the items array?
			collection_triggered.emit(facility_id, rpc_result.size())
			await fetch_my_facilities(true)
			# Refresh all player data from database (including gold from production)
			await State.refresh_data()
			# Refresh inventory to show collected items
			if Inventory:
				Inventory.fetch_inventory()
			result = {"success": true, "collected_items": rpc_result}
		elif rpc_result is Dictionary and rpc_result.has("error"):
			result = {"success": false, "error": rpc_result.get("error")}
		else:
			# Fallback: maybe the RPC just succeeded?
			print("[FacilityManager] collect_production unexpected structure: %s" % rpc_result)
			result = {"success": false, "error": "Unexpected RPC response structure"}
	else:
		push_error("FacilityManager: Failed to collect production - %s" % response.get("error", "Unknown"))
		result = {"success": false, "collected_items": [], "error": response.get("error", "Unknown")}
	
	return result

func collect_production(facility_id: String) -> Dictionary:
	return await collect_facility_production(facility_id)

# ==================== RPC WRAPPER: UPGRADE FACILITY ====================
func upgrade_facility(facility_type: String) -> Dictionary:
	# Get the actual facility data to find the UUID
	var facility = get_facility_by_type(facility_type)
	if facility.is_empty():
		return {"success": false, "new_level": 0, "new_cost": 0, "error": "Facility not found"}
	
	var facility_id = facility.get("id", "")
	# RPC: upgrade_facility(p_facility_id UUID)
	# NOTE: We do NOT pass p_type, just p_facility_id, as per our new SQL function.
	var response = await Network.http_post("/rest/v1/rpc/upgrade_facility", {
		"p_facility_id": facility_id
	})
	var result = {}
	
	if response is Dictionary and response.get("success", false):
		var rpc_result = response.get("data", {})
		if rpc_result is Dictionary and rpc_result.get("success", false):
			var new_level = rpc_result.get("new_level", 0)
			
			# OPTIMISTIC UPDATE: Update cache immediately
			if cached_facilities.has(facility_id):
				cached_facilities[facility_id]["level"] = new_level
				# Update gold locally too since we know the cost implicitly or from result?
				# RPC returns remaining_gold, handled below.
			
			# Update gold state
			var remaining_gold = rpc_result.get("remaining_gold", -1)
			if remaining_gold != null and int(remaining_gold) >= 0:
				State.update_gold(int(remaining_gold))
				
			facility_upgraded.emit(facility_id, new_level)
			
			# Emit generic update so UI refreshes without waiting for fetch
			facilities_updated.emit()
			
			# Fetch facilities and refresh player data from database
			await fetch_my_facilities(true)
			await State.refresh_data()
			
			result = {"success": true, "new_level": new_level, "new_cost": rpc_result.get("next_upgrade_cost", 0)}
		else:
			result = {"success": false, "error": rpc_result.get("error", "RPC Error")}
	else:
		push_error("FacilityManager: Failed to upgrade facility - %s" % response.get("error", "Unknown"))
		result = {"success": false, "new_level": 0, "new_cost": 0, "error": response.get("error", "Unknown")}
	
	return result

# ==================== RPC WRAPPER: INCREMENT FACILITY SUSPICION ====================
func increment_facility_suspicion(facility_id: String) -> Dictionary:
	# RPC: increment_facility_suspicion(p_facility_id UUID, p_amount INT)
	var response = await Network.http_post("/rest/v1/rpc/increment_facility_suspicion", {
		"p_facility_id": facility_id,
		"p_amount": 5 # Default amount or logic based on context
	})
	var result = {}
	
	if response is Dictionary and response.get("success", false):
		# RPC returns integer (new suspicion) directly, NOT a JSON object with success field in the root data
		# Wait, the SQL function `RETURNS INT`.
		# So `response.data` will be the integer value directly.
		# Network.http_post returns {success: ..., data: ...}
		# data = 15 (example)
		
		# NOTE: Our logic above assumed JSONB returns for success wrappers.
		# `increment_facility_suspicion` returns INT.
		# So `response.data` is an int.
		
		var new_suspicion = 0
		if response.data is float or response.data is int:
			new_suspicion = int(response.data)
		
		suspicion_changed.emit(facility_id, new_suspicion)
		await fetch_my_facilities(true)
		result = {
			"success": true, 
			"new_suspicion": new_suspicion,
			"sent_to_prison": false, # RPC doesn't check prison logic in simple increment
			"prison_hours": 0
		}
	else:
		result = {"success": false, "error": response.get("error", "Unknown")}
	
	return result

# ==================== RPC WRAPPER: BRIBE OFFICIALS ====================
func bribe_officials(facility_type: String, gems_spent: int) -> Dictionary:
	var response = await Network.http_post("/rest/v1/rpc/bribe_officials", {
		"p_facility_type": facility_type,
		"p_amount_gems": gems_spent
	})
	var result = {}
	
	if response is Dictionary and response.get("success", false):
		var rpc_result = response.get("data", {})
		if rpc_result is Dictionary and rpc_result.get("success", false):
			var new_suspicion = rpc_result.get("new_suspicion", 0)
			var baseline_set = rpc_result.get("baseline_set", 0)
			print("[FacilityManager] ✓ Bribe successful | Baseline set to: %d%%", baseline_set)
			suspicion_changed.emit(facility_type, new_suspicion)
			bribe_completed.emit(facility_type, gems_spent)
			
			# Refresh facilities and player data from database (gems after bribe deducted, baseline set)
			await fetch_my_facilities(true)
			await State.refresh_data()
			
			# Sync global risk to database (calculated risk - baseline = 0 immediately after bribe)
			await sync_global_risk_to_database()
			
			result = {"success": true, "new_suspicion": new_suspicion, "baseline_set": baseline_set}
		else:
			result = {"success": false, "error": rpc_result.get("error", "RPC Error")}
	else:
		push_error("FacilityManager: Failed to bribe officials - %s" % response.get("error", "Unknown"))
		result = {"success": false, "error": response.get("error", "Unknown")}
	
	return result

# ==================== RPC WRAPPER: REDUCE FACILITY SUSPICION ====================
func reduce_facility_suspicion(facility_id: String) -> Dictionary:
	# RPC: decrement_facility_suspicion(p_facility_id UUID, p_amount INT)
	var response = await Network.http_post("/rest/v1/rpc/decrement_facility_suspicion", {
		"p_facility_id": facility_id, 
		"p_amount": 10 # Default
	})
	var result = {}
	
	if response is Dictionary and response.get("success", false):
		# RPC returns INT
		var new_suspicion = 0
		if response.data is float or response.data is int:
			new_suspicion = int(response.data)
			
		suspicion_changed.emit(facility_id, new_suspicion)
		await fetch_my_facilities(true)
		result = {
			"success": true, 
			"reduction_amount": 10,
			"new_suspicion": new_suspicion
		}
	else:
		result = {"success": false, "error": response.get("error", "Unknown")}
	
	return result

# ==================== RPC WRAPPER: GET FACILITY RECIPES ====================
func get_facility_recipes(facility_id: String, facility_type: String = "") -> Dictionary:
	# Use REST RPC to get recipes
	print("[FacilityManager] Fetching recipes for facility_type='%s'" % facility_type)
	var response = await Network.http_post("/rest/v1/rpc/get_facility_recipes_rpc", {
		"p_facility_type": facility_type
	})
	
	print("[FacilityManager] Recipe RPC raw response: %s" % str(response).substr(0, 200))
	
	var result = {}
	
	if response is Dictionary and response.get("success", false):
		# REST API wraps RPC response in response.data
		# response.data contains: {success, recipes, count, facility_type}
		var rpc_response = response.get("data", {})
		print("[FacilityManager] RPC response data: %s" % str(rpc_response).substr(0, 200))
		
		if rpc_response is Dictionary and rpc_response.get("success", false):
			var recipes = rpc_response.get("recipes", [])
			print("[FacilityManager] ✅ Got %d recipes for %s" % [recipes.size(), facility_type])
			cached_recipes[facility_id] = recipes
			result = {"success": true, "data": recipes}
		else:
			var err = rpc_response.get("error", "Unknown") if rpc_response is Dictionary else "Invalid RPC response"
			push_error("FacilityManager: RPC failed for %s - %s" % [facility_type, err])
			result = {"success": false, "data": [], "error": err}
	else:
		push_error("FacilityManager: HTTP request failed for %s - %s" % [facility_type, response.get("error", "Unknown")])
		result = {"success": false, "data": [], "error": response.get("error", "Unknown")}
	
	return result

# Alias for DetailModal compatibility - pass both facility_id and type
func fetch_recipes_for_facility(facility_type: String) -> Dictionary:
	var facility = get_facility_by_type(facility_type)
	if facility.is_empty():
		return {"success": false, "data": [], "error": "Facility not found"}
	return await get_facility_recipes(facility.get("id", ""), facility_type)

# ==================== RPC WRAPPER: CALCULATE OFFLINE PRODUCTION ====================
func calculate_offline_production(facility_id: String) -> Dictionary:
	# RPC: calculate_offline_production(p_facility_id UUID) -> INT
	var response = await Network.http_post("/rest/v1/rpc/calculate_offline_production", {"p_facility_id": facility_id})
	var result = {}
	
	if response is Dictionary and response.get("success", false):
		# RPC returns INT (production amount)
		# NOTE: Our previous implementation expected "completed_items" list.
		# The new SQL function returns a single INT (total production value or count?).
		# Reading calculate_offline_production SQL: returns INT (value).
		# This might break UI if it expects a list of items.
		# However, offline production usually just adds to inventory or claims value.
		# For now, we'll wrap it to satisfy basic expectation or just return usage.
		
		# For now, we'll wrap it to satisfy basic expectation or just return usage.
		
		await fetch_my_facilities(true)
		result = {"success": true, "production_value": response.data}
	else:
		push_error("FacilityManager: Failed to calculate offline production - %s" % response.get("error", "Unknown"))
		result = {"success": false, "error": response.get("error", "Unknown")}
	
	return result

# ==================== UTILITY FUNCTIONS ====================

func get_facility_by_id(facility_id: String) -> Dictionary:
	return cached_facilities.get(facility_id, {})

func get_facility_by_type(facility_type: String) -> Dictionary:
	for facility in cached_facilities.values():
		if facility.get("type") == facility_type:
			return facility
	return {}

func is_facility_unlocked(facility_type: String) -> bool:
	return get_facility_by_type(facility_type).is_empty() == false

func get_facility_level(facility_id: String) -> int:
	return cached_facilities.get(facility_id, {}).get("level", 0)

func get_facility_suspicion(facility_id: String) -> int:
	return cached_facilities.get(facility_id, {}).get("suspicion_level", 0)

func get_production_queue(facility_id: String) -> Array:
	# Support both 'facility_queue' (from RPC) and 'production_queue' (legacy)
	var facility = cached_facilities.get(facility_id, {})
	var queue = facility.get("facility_queue", [])
	if queue.is_empty():
		queue = facility.get("production_queue", [])
	return queue

func get_production_queue_count(facility_id: String) -> int:
	return get_production_queue(facility_id).size()

func is_queue_full(facility_id: String) -> bool:
	return get_production_queue_count(facility_id) >= 10

func get_upgrade_cost(facility_type: String) -> int:
	var _config = FACILITIES_CONFIG.get(facility_type, {})
	var facility = get_facility_by_type(facility_type)
	if facility.is_empty():
		return 0
	
	var base_cost = 2000  # Default base upgrade cost
	var multiplier = 1.6  # Default multiplier
	var current_level = facility.get("level", 1)
	
	# Calculate cost: base_cost * (multiplier ^ current_level)
	return int(base_cost * pow(multiplier, current_level))

# ==================== INITIALIZATION ====================

func _ready() -> void:
	print("[FacilityManager] Initializing...")

	# Set up refresh timer for periodic cache invalidation
	var refresh_timer = Timer.new()
	add_child(refresh_timer)
	refresh_timer.timeout.connect(func():
		if Time.get_ticks_msec() / 1000.0 - last_cache_time > cache_duration:
			fetch_my_facilities()
	)
	refresh_timer.start(30.0)

	# Wait a frame to ensure Session is initialized
	await get_tree().process_frame

	# Only fetch facilities when user logs in
	Session.logged_in.connect(func(_player_data):
		print("[FacilityManager] User logged in, fetching facilities...")
		var result = await fetch_my_facilities(true)
		print("[FacilityManager] Initial fetch result: %s" % result)
	)

	# Check if already authenticated - must have both flag and token
	if Session.is_authenticated and not Session.access_token.is_empty():
		print("[FacilityManager] User already authenticated with token, fetching facilities...")
		var result = await fetch_my_facilities(true)
		print("[FacilityManager] Initial fetch result: %s" % result)
	else:
		print("[FacilityManager] User not authenticated yet, will fetch when logged in")

	print("[FacilityManager] Ready!")

# ==================== DEBUG ====================

func _get_debug_info() -> Dictionary:
	return {
		"facilities_cached": cached_facilities.size(),
		"cache_age_seconds": Time.get_ticks_msec() / 1000.0 - last_cache_time,
		"facility_types_available": FACILITY_TYPES.size()
	}

# ==================== RESOURCE COLLECTION SYSTEM ====================

# Resource Rarity Distribution (for random drops)
const RARITY_DISTRIBUTION = {
	"COMMON": 70.0,      # 70% chance
	"UNCOMMON": 20.0,    # 20% chance
	"RARE": 8.0,         # 8% chance
	"EPIC": 1.5,         # 1.5% chance
	"LEGENDARY": 0.5     # 0.5% chance
}

# Facility Resources Mapping (all rarities)
const FACILITY_RESOURCES_FULL = {
	"mining": ["iron_ore", "copper_ore", "silver_ore", "gold_ore", "mithril_ore"],
	"quarry": ["granite", "marble", "crystal_shard", "obsidian", "moonstone"],
	"lumber_mill": ["oak_wood", "pine_wood", "bamboo", "elder_wood", "world_tree_sap"],
	"clay_pit": ["ceramic_clay", "brick_clay", "enchanted_clay", "dragon_clay"],
	"sand_quarry": ["glass_sand", "crystal_sand", "star_dust", "void_sand"],
	"farming": ["wheat", "vegetables", "cotton", "magical_grain", "golden_wheat"],
	"herb_garden": ["healing_herb", "poison_herb", "rare_flower", "dragon_root", "phoenix_petal"],
	"ranch": ["leather", "bone", "wool", "monster_hide", "dragon_scale"],
	"apiary": ["honey", "beeswax", "bee_venom", "royal_jelly", "celestial_honey"],
	"mushroom_farm": ["healing_mushroom", "poison_mushroom", "glowing_mushroom", "ghost_mushroom", "immortality_shroom"],
	"rune_mine": ["raw_rune", "magic_crystal", "energy_shard", "power_rune", "ancient_rune"],
	"holy_spring": ["holy_water", "mana_crystal", "purification_water", "blessed_essence", "divine_tear"],
	"shadow_pit": ["dark_essence", "shadow_crystal", "curse_dust", "void_fragment", "abyss_core"],
	"elemental_forge": ["fire_essence", "ice_crystal", "lightning_core", "storm_shard", "primordial_flame"],
	"time_well": ["time_crystal", "aging_dust", "eternity_essence", "temporal_shard", "infinity_stone"]
}

# Resource Rarity Mapping
const RESOURCE_RARITY_TIERS = {
	0: "COMMON",
	1: "COMMON",
	2: "UNCOMMON",
	3: "RARE",
	4: "LEGENDARY"  # 4th index (5th item) is highest tier, map to Legendary effectively
}

# Unlock Levels for Rarities
const RARITY_UNLOCK_LEVELS = {
	"COMMON": 1,
	"UNCOMMON": 3,
	"RARE": 5,
	"EPIC": 7,
	"LEGENDARY": 10
}

## Get rarity weights and percentage chances for a specific level
func get_rarity_chances_at_level(level: int) -> Dictionary:
	# Weights determine the probability relative to total weight
	# Base weights (Level 1) -> Target roughly: 70%, 20%, 8%, 1.5%, 0.5%
	var weights = {
		"COMMON": 700.0,
		"UNCOMMON": 200.0,
		"RARE": 80.0,
		"EPIC": 15.0,
		"LEGENDARY": 5.0
	}
	
	if level > 1:
		# Increase weights for higher tiers per level
		# Result: Common stays same, others grow, eating into Common's percentage share
		weights["UNCOMMON"] += (level - 1) * 15.0
		weights["RARE"] += (level - 1) * 8.0
		weights["EPIC"] += (level - 1) * 3.0
		weights["LEGENDARY"] += (level - 1) * 1.5
		
		# Allow Common to slightly decrease in weight to faster shift balance?
		# No, kept constant weight effectively means its % drops as total weight rises.
	
	var total_weight = 0.0
	for w in weights.values():
		total_weight += w
		
	var chances = {}
	for rarity in weights:
		chances[rarity] = (weights[rarity] / total_weight) * 100.0
		
	return {
		"weights": weights,
		"total_weight": total_weight,
		"chances": chances
	}

## Calculate idle resources generated for a facility
## Production: 1 hour duration. After 1 hour, status=expired.
## User can collect resources ANYTIME during active/expired.
## After collection: production_started_at NOT reset, continues from where it left off.
func calculate_idle_resources(facility: Dictionary) -> Dictionary:
	var facility_type = facility.get("type", "")
	var facility_level = facility.get("level", 1)
	var last_collected = facility.get("last_production_collected_at")
	var offline_cap = facility.get("offline_production_cap", 720)
	
	var config = FACILITIES_CONFIG.get(facility_type, {})
	var base_rate = config.get("base_rate", 10.0)
	var resources_pool = FACILITY_RESOURCES_FULL.get(facility_type, [])
	
	if resources_pool.is_empty():
		return {"resources": [], "total_count": 0, "status": "stopped"}
	
	var now = Time.get_unix_time_from_system()
	var production_started_at = facility.get("production_started_at")
	
	# If production never started, return stopped
	if production_started_at == null:
		return {"resources": [], "total_count": 0, "status": "stopped"}
	
	# Parse production start time
	var start_time = 0
	if production_started_at is String:
		var dt = Time.get_datetime_dict_from_datetime_string(production_started_at, false)
		start_time = Time.get_unix_time_from_datetime_dict(dt)
	elif production_started_at is int or production_started_at is float:
		start_time = int(production_started_at)
	else:
		return {"resources": [], "total_count": 0, "status": "stopped"}
	
	# Production duration: 120 seconds (2 minutes) for testing - originally 1 hour (3600)
	var production_duration = 120
	var end_time = start_time + production_duration
	
	# Check if production has expired (after 120 seconds)
	var current_status = "expired" if now >= end_time else "active"
	var remaining_seconds = max(0, end_time - now)
	
	# Parse last collection time (for calculating only NEW resources since last collection)
	var last_collected_time = start_time  # Default: start from production start
	if last_collected is String:
		var dt = Time.get_datetime_dict_from_datetime_string(last_collected, false)
		last_collected_time = Time.get_unix_time_from_datetime_dict(dt)
	elif last_collected is int or last_collected is float:
		last_collected_time = int(last_collected)
	
	# **CRITICAL FIX**: If production expired and was collected after duration expired,
	# don't continue generating resources. Only generate UP TO the end_time.
	var calculation_time = now
	if now > end_time:
		# Production expired - calculate only UP TO end_time
		if last_collected_time < end_time:
			# Last collection was before expiry - generate from last_collected to end_time only
			calculation_time = end_time
		else:
			# Last collection was AFTER expiry - no new resources!
			return {"resources": [], "total_count": 0, "status": current_status, "remaining_seconds": remaining_seconds}
	
	# Calculate resources from last_collected_time to calculation_time (capped at end_time)
	var elapsed_seconds = calculation_time - last_collected_time
	if elapsed_seconds <= 0:
		return {"resources": [], "total_count": 0, "status": current_status, "remaining_seconds": remaining_seconds}
	
	var hours_elapsed = elapsed_seconds / 3600.0
	var production_rate = base_rate * facility_level * 10  # 10x multiplier for testing
	var total_resources = int(hours_elapsed * production_rate)
	
	# Cap at 100 — must match server collect_facility_resources_v2
	if total_resources > 100:
		total_resources = 100
	
	if total_resources <= 0:
		return {"resources": [], "total_count": 0, "status": current_status, "remaining_seconds": remaining_seconds}
	
	# Generate resources with rarity distribution
	var rarity_data = get_rarity_chances_at_level(facility_level)
	var weights = rarity_data.weights
	var total_weight = rarity_data.total_weight
	var unlocked_rarities = []
	
	for rarity in RARITY_UNLOCK_LEVELS:
		if facility_level >= RARITY_UNLOCK_LEVELS[rarity]:
			unlocked_rarities.append(rarity)
	
	var collected_resources = []
	
	# ====== DETERMINISTIC SEED — must match server exactly ======
	# Server uses: hash(production_started_at_string) % 2147483647
	var production_started_at_str = ""
	if production_started_at is String:
		production_started_at_str = production_started_at
	else:
		production_started_at_str = str(production_started_at)
	var det_seed = hash(production_started_at_str) % 2147483647
	if det_seed < 0:
		det_seed = -det_seed
	
	# ====== SERVER-MATCHING ITEM GENERATION (LCG RNG) ======
	# Server loop: FOR v_i IN 1..v_total_qty  (1-indexed!)
	# RNG formula: ((seed + v_i) * 16807.0 % 2147483647.0) / 2147483647.0
	for i in range(1, total_resources + 1):
		# LCG RNG matching server exactly
		var rng_val = fmod(float(det_seed + i) * 16807.0, 2147483647.0) / 2147483647.0
		
		# Pick rarity based on weights (same logic as server)
		var selected_rarity = "COMMON"
		var common_pct = weights.get("COMMON", 700.0) / total_weight
		if common_pct <= rng_val:
			# Not COMMON → find which rarity
			var cum = common_pct
			if cum + weights.get("UNCOMMON", 0.0) / total_weight > rng_val:
				selected_rarity = "UNCOMMON"
			elif cum + weights.get("UNCOMMON", 0.0) / total_weight + weights.get("RARE", 0.0) / total_weight > rng_val:
				selected_rarity = "RARE"
			elif cum + weights.get("UNCOMMON", 0.0) / total_weight + weights.get("RARE", 0.0) / total_weight + weights.get("EPIC", 0.0) / total_weight > rng_val:
				selected_rarity = "EPIC"
			else:
				selected_rarity = "LEGENDARY"
		
		# Downgrade if not unlocked
		if selected_rarity not in unlocked_rarities:
			if "EPIC" in unlocked_rarities and selected_rarity == "LEGENDARY":
				selected_rarity = "EPIC"
			elif "RARE" in unlocked_rarities and (selected_rarity == "EPIC" or selected_rarity == "LEGENDARY"):
				selected_rarity = "RARE"
			elif "UNCOMMON" in unlocked_rarities and (selected_rarity == "RARE" or selected_rarity == "EPIC" or selected_rarity == "LEGENDARY"):
				selected_rarity = "UNCOMMON"
			else:
				selected_rarity = "COMMON"
		
		# Pick resource index — same as server
		var resource_index = 0
		match selected_rarity:
			"COMMON":
				resource_index = (det_seed + i) % 2  # matches server: ((p_seed + v_i) % 2)
			"UNCOMMON":
				resource_index = 2
			"RARE":
				resource_index = 3
			"EPIC":
				resource_index = 3  # server uses 3 for EPIC
			"LEGENDARY":
				resource_index = 4
		
		if resource_index >= resources_pool.size():
			resource_index = resources_pool.size() - 1
		
		var resource_id = resources_pool[resource_index]
		
		# Add to collected resources
		var found = false
		for res in collected_resources:
			if res.item_id == resource_id:
				res.quantity += 1
				found = true
				break
		
		if not found:
			collected_resources.append({
				"item_id": resource_id,
				"quantity": 1,
				"rarity": selected_rarity
			})
	
	return {
		"resources": collected_resources,
		"total_count": total_resources,
		"status": current_status,
		"remaining_seconds": remaining_seconds
	}

## Start Production for Facility (Costs Energy)
func start_facility_production(facility_id: String) -> Dictionary:
	print("[FacilityManager] Requesting start_production for facility: %s" % facility_id)
	
	# Energy cost for production
	var energy_cost = 50
	var player_energy = State.current_energy
	
	# Check if player has enough energy
	if player_energy < energy_cost:
		return {"success": false, "error": "Yetersiz enerji. Gerekli: %d, Mevcut: %d" % [energy_cost, player_energy]}
	
	var result = await Network.http_post("/rest/v1/rpc/start_facility_production", {
		"p_facility_id": facility_id
	})
	print("[FacilityManager] start_production response: %s" % result)
	
	var final_result = {"success": false, "error": "Unknown error"}
	
	if result.success and result.data is Dictionary and result.data.get("success", false):
		# Deduct energy from player
		State.consume_energy(energy_cost)
		
		# Update local cache immediately to reflect change
		if cached_facilities.has(facility_id):
			var facility = cached_facilities[facility_id]
			# Use UTC (true) to match server/unix time logic
			facility["production_started_at"] = Time.get_datetime_string_from_system(true, true)
			print("[FacilityManager] Set local production_started_at: ", facility["production_started_at"])
			facility["is_active"] = true
		
		# Refetch facilities from server to ensure production_started_at is correct
		await fetch_my_facilities(true)
		
		# Sync global risk to database after production started
		await sync_global_risk_to_database()
		
		# Refresh player data from database (gets updated global_suspicion_level)
		await State.refresh_data()
		
		facilities_updated.emit()
		final_result = {"success": true, "new_energy": State.current_energy}
	else:
		var err = "RPC Failed"
		if result.data is Dictionary:
			err = result.data.get("error", "Unknown RPC Error")
		final_result = {"success": false, "error": err}
		
	return final_result

## Collect resources from a facility (RPC V2 - Advanced)
func collect_facility_resources(facility_id: String) -> Dictionary:
	print("[FacilityManager] Collecting resources from facility: %s" % facility_id)
	
	# Find facility in cache
	var facility = cached_facilities.get(facility_id)
	if not facility:
		print("[FacilityManager] Facility not found in cache: %s" % facility_id)
		return {"success": false, "error": "Facility not found"}
	
	# Calculate resources for preview (same algorithm as server)
	var result = calculate_idle_resources(facility)
	print("[FacilityManager] Resources to show: total_count=%d, status=%s" % [result.total_count, result.get("status", "unknown")])
	
	if result.total_count == 0:
		return {"success": false, "error": "No resources to collect"}
	
	# Generate deterministic seed — same as calculate_idle_resources uses
	var started_at = facility.get("production_started_at")
	var started_at_str = ""
	if started_at is String:
		started_at_str = started_at
	else:
		started_at_str = str(started_at)
	var seed = hash(started_at_str) % 2147483647
	if seed < 0:
		seed = -seed
	
	print("[FacilityManager] Using seed: %d for deterministic RNG" % seed)
	
	# Call RPC V2 with seed and total_count for deterministic generation
	var rpc_payload = {
		"p_facility_id": facility_id,
		"p_seed": seed,
		"p_total_count": result.total_count
	}
	
	var response = await Network.http_post("/rest/v1/rpc/collect_facility_resources_v2", rpc_payload)
	
	# Check if HTTP request succeeded
	if not response.get("success", false):
		print("[FacilityManager] HTTP request failed!")
		print("[FacilityManager] Response code: %s" % response.get("code", "?"))
		print("[FacilityManager] Response data: %s" % response.get("data", null))
		print("[FacilityManager] Response error: %s" % response.get("error", null))
		return {"success": false, "error": response.get("error", "Network error")}
	
	# Check if RPC itself succeeded
	var rpc_result = response.get("data", {})
	if not (rpc_result is Dictionary and rpc_result.get("success", false)):
		var err = rpc_result.get("error", "Unknown RPC error") if rpc_result is Dictionary else "Invalid RPC response"
		print("[FacilityManager] RPC failed: %s" % err)
		return {
			"success": false,
			"error": err,
			"required_slots": rpc_result.get("required_slots", null) if rpc_result is Dictionary else null,
			"available_slots": rpc_result.get("available_slots", null) if rpc_result is Dictionary else null
		}
	
	# ===== VALIDATION =====
	var shown_count = result.total_count
	var added_count = rpc_result.get("count", 0)
	var items_generated = rpc_result.get("items_generated", [])
	var items_breakdown = rpc_result.get("items_breakdown", {})
	
	# ===== PRISON CHECK DEBUG =====
	var prison_check = rpc_result.get("prison_check", {})
	if prison_check:
		print("\n[FacilityManager] ===== PRISON CHECK DEBUG =====")
		print("[FacilityManager] Global Suspicion: %d" % prison_check.get("global_suspicion", 0))
		print("[FacilityManager] Prison Chance: %d%%" % prison_check.get("prison_chance", 0))
		print("[FacilityManager] Prison Roll: %.2f" % prison_check.get("prison_roll", 0.0))
		print("[FacilityManager] Admission Occurred: %s" % str(prison_check.get("admission_occurred", false)))
		print("[FacilityManager] Prison Log: %s" % prison_check.get("prison_log", "N/A"))
		print("[FacilityManager] ===== END PRISON CHECK =====\n")
	
	print("\n[FacilityManager] ===== COLLECTION REPORT =====")
	print("[FacilityManager] Shown to player: %d items" % shown_count)
	print("[FacilityManager] Actually added to inventory: %d items" % added_count)
	print("[FacilityManager] Number of different item types: %d" % items_generated.size())
	print("[FacilityManager] Breakdown by item:")
	
	for item in items_generated:
		var item_name = item.get("item_name", "?")
		var item_qty = item.get("quantity", 0)
		print("  → %s: %d" % [item_name, item_qty])
	
	if shown_count == added_count:
		print("[FacilityManager] ✅ MATCH: Shown == Added")
	else:
		print("[FacilityManager] ⚠️  MISMATCH: Shown (%d) != Added (%d)" % [shown_count, added_count])
	
	print("[FacilityManager] Seed used: %d" % rpc_result.get("seed_used", seed))
	print("[FacilityManager] ===== END REPORT =====\n")
	
	# ===== CHECK IF PRISON ADMISSION OCCURRED =====
	var admission_occurred = prison_check.get("admission_occurred", false) if prison_check else false
	
	if admission_occurred:
		print("[FacilityManager] Player admitted to prison! Not adding resources to inventory.")
		# Don't add items to inventory — player is in prison
		added_count = 0
	
	# Refresh facilities cache (production cleared on server)
	await fetch_my_facilities(true)
	
	# Sync global risk to database after collection
	# This will update State.player["global_suspicion_level"] 
	await sync_global_risk_to_database()
	
	# Immediately refresh inventory so player sees items right away (if not imprisoned)
	if not admission_occurred and Inventory:
		await Inventory.fetch_inventory()
	
	# Refresh player data from server (gets latest global_suspicion_level and in_prison status)
	await State.refresh_data()
	
	# If admitted to prison, show prison screen
	if admission_occurred:
		print("[FacilityManager] Showing PrisonScreen...")
		if Scenes:
			Scenes.change_scene("PrisonScreen")
	
	# Emit collection completed signal for other screens
	collection_triggered.emit(facility_id, added_count)
	
	# Return detailed result for UI — use server count as authoritative
	return {
		"success": true,
		"count": added_count,
		"total_count": added_count if not admission_occurred else 0,
		"items_generated": items_generated if not admission_occurred else [],
		"breakdown": items_breakdown if not admission_occurred else {},
		"shown_count": shown_count if not admission_occurred else 0,
		"match": (shown_count == added_count) if not admission_occurred else false,
		"message": "Resources collected: %d items" % added_count if not admission_occurred else "Sent to prison! Resources lost.",
		"admission_occurred": admission_occurred
	}

## Get estimated resources ready for collection (for UI display)
func get_resources_ready(facility: Dictionary) -> int:
	var result = calculate_idle_resources(facility)
	return result.total_count

## TESTING: Reset ALL facility production (clears production for ALL facilities)
func reset_all_facility_production() -> Dictionary:
	var response = await Network.http_post("/rest/v1/rpc/reset_all_facility_production", {})
	
	if not response.get("success", false):
		print("[FacilityManager] Reset all failed: %s" % response.get("error", "Unknown error"))
		return {"success": false, "error": response.get("error")}
	
	var result = response.get("data", {})
	print("[FacilityManager] ✅ All production reset: %s" % result.get("message", "Done"))
	print("[FacilityManager] Facilities reset: %d" % result.get("facilities_reset", 0))
	print("[FacilityManager] Queue items deleted: %d" % result.get("queue_items_deleted", 0))
	
	# Refresh and sync global risk (should be 0 now)
	await fetch_my_facilities(true)
	await sync_global_risk_to_database()
	
	return {
		"success": true,
		"message": result.get("message", "All production reset"),
		"facilities_reset": result.get("facilities_reset", 0),
		"queue_items_deleted": result.get("queue_items_deleted", 0)
	}

