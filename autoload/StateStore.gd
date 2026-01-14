extends Node
## State Store - Global oyun durumu cache
## Singleton autoload: State

signal state_changed(key: String, value: Variant)
signal player_updated()
signal inventory_updated()
signal energy_updated()
signal tolerance_updated(value: int)

## Player Data
var player: Dictionary = {}
var current_energy: int = 100
var max_energy: int = 100
var tolerance: int = 0
var gold: int = 0
var gems: int = 0
var level: int = 1
var xp: int = 0
var next_level_xp: int = 1000
var pvp_rating: int = 1000
var pvp_wins: int = 0
var pvp_losses: int = 0

## Load player data from API response
func load_player_data(data: Dictionary) -> void:
	player = data
	current_energy = data.get("energy", 100)
	max_energy = data.get("max_energy", 100)
	tolerance = data.get("addiction_level", 0)
	gold = data.get("gold", 1000)  # Test için başlangıç gold'u
	gems = data.get("gems", 0)
	level = data.get("level", 1)
	xp = data.get("xp", 0)
	pvp_rating = data.get("pvp_rating", 1000)
	pvp_wins = data.get("pvp_wins", 0)
	pvp_losses = data.get("pvp_losses", 0)
	
	# Hospital durumu
	if data.has("hospital_until") and data.hospital_until:
		var hospital_time = Time.get_datetime_dict_from_datetime_string(data.hospital_until, false)
		hospital_release_time = Time.get_unix_time_from_datetime_dict(hospital_time)
		var current_time = Time.get_unix_time_from_system()
		in_hospital = current_time < hospital_release_time
	else:
		in_hospital = false
		hospital_release_time = 0
	
	# Guild bilgisi
	if data.has("guild") and data.guild:
		guild_info = data.guild
	
	# Next level XP hesapla
	next_level_xp = calculate_next_level_xp(level)
	
	# Save player data to disk for persistence
	_save_player_data()
	
	player_updated.emit()
	energy_updated.emit()
	print("[StateStore] Player data loaded: Level %d, Gold %d, Energy %d/%d" % [level, gold, current_energy, max_energy])

## XP calculation
func calculate_next_level_xp(current_level: int) -> int:
	# Exponential curve: base_xp * (level ^ 1.5)
	var base_xp = 1000
	return int(base_xp * pow(current_level, 1.5))

## Level up check and processing
func _check_level_up() -> void:
	# Promote player while XP meets threshold
	while xp >= next_level_xp:
		xp -= next_level_xp
		level += 1
		next_level_xp = calculate_next_level_xp(level)
		
		# Update player dictionary and persist
		player["level"] = level
		player["xp"] = xp
		_save_player_data()
		
		# Notify listeners about the level up
		player_updated.emit()
		print("[StateStore] Level up! Reached level %d" % level)
	
	# Ensure player dict always reflects current values
	player["xp"] = xp
	player["level"] = level

## Inventory
var inventory: Array = []
var equipped_items: Dictionary = {}

## Quests
var active_quests: Array = []
var completed_quests: Array = []

## Market Cache
var market_ticker: Dictionary = {}
var market_orders: Dictionary = {}
var _market_cache_time: Dictionary = {}
const MARKET_CACHE_TTL = 10  # 10 saniye

## Guild
var guild_info: Dictionary = {}
var guild_members: Array = []

## PvP
var pvp_history: Array = []
var reputation: int = 0

## Hospital
var in_hospital: bool = false
var hospital_release_time: int = 0
var hospital_reason: String = ""

## Settings
var settings: Dictionary = {
	"music_volume": 0.8,
	"sfx_volume": 1.0,
	"notifications_enabled": true
}

func _ready() -> void:
	print("[State] Initializing...")
	_load_settings()
	# If a session exists (authenticated), prefer server as source of truth and defer loading
	if Session:
		print("[State] Session available; deferring player load to server when authenticated")
		# Connect to session signals to receive player data when available
		Session.logged_in.connect(_on_session_logged_in)
		Session.session_status_checked.connect(_on_session_status_checked)
		# If Session emits profile_missing we will surface it to UI instead of logging out
		if Session.has_signal("profile_missing"):
			Session.connect("profile_missing", Callable(self, "_on_profile_missing"))
		# If not authenticated yet, don't load from disk; wait for session events
		if not Session.is_authenticated:
			print("[State] Session present but not authenticated; waiting for validation")
			return
	# No Session or not authenticated: load local cache
	_load_player_data()

## Player Methods
func get_player_data() -> Dictionary:
	return player

func set_player_data(data: Dictionary) -> void:
	player = data
	
	if data.has("current_energy"):
		current_energy = data.current_energy
	if data.has("max_energy"):
		max_energy = data.max_energy
	if data.has("tolerance"):
		tolerance = data.tolerance
	if data.has("gold"):
		gold = data.gold
	if data.has("level"):
		level = data.level
	
	player_updated.emit()
	state_changed.emit("player", player)

func update_energy(current: int, max_value: int = -1) -> void:
	current_energy = current
	if max_value != -1:
		max_energy = max_value
	
	# Update player dictionary for consistency
	player["energy"] = current_energy
	if max_value != -1:
		player["max_energy"] = max_energy
	
	energy_updated.emit()
	state_changed.emit("energy", {"current": current_energy, "max": max_energy})

func update_tolerance(value: int) -> void:
	tolerance = value
	tolerance_updated.emit(value)
	state_changed.emit("tolerance", tolerance)

func update_gold(amount: int, is_delta: bool = false) -> void:
	if is_delta:
		gold += amount
	else:
		gold = amount
	
	state_changed.emit("gold", gold)
	
	# Update player dictionary for consistency
	player["gold"] = gold
	_sync_to_supabase_background()

func update_gems(amount: int, is_delta: bool = false) -> void:
	if is_delta:
		gems += amount
	else:
		gems = amount
	
	# Update player dictionary for consistency
	player["gems"] = gems
	
	state_changed.emit("gems", gems)
	_sync_to_supabase_background()

func get_player_energy() -> int:
	return current_energy

func get_max_energy() -> int:
	return max_energy

func get_inventory_items() -> Array:
	return inventory

## Inventory Methods
func set_inventory(items: Array) -> void:
	inventory = items
	inventory_updated.emit()
	state_changed.emit("inventory", inventory)

func add_item(item: Dictionary) -> void:
	# IMPORTANT: Parse through ItemData.from_dict() to merge with ItemDatabase
	# This ensures the item has correct properties (icon, rarity, etc.)
	var item_data = ItemData.from_dict(item)
	
	# Check if item is stackable and already exists
	if item_data.is_stackable:
		var existing_index = -1
		for i in range(inventory.size()):
			var inv_item_dict = inventory[i]
			var inv_item_id = inv_item_dict.get("item_id", inv_item_dict.get("id", ""))
			if inv_item_id == item_data.item_id:
				existing_index = i
				break
		
		if existing_index >= 0:
			# Stack with existing item
			var existing_dict = inventory[existing_index]
			var current_qty = existing_dict.get("quantity", 1)
			var new_qty = current_qty + item_data.quantity
			existing_dict["quantity"] = new_qty
			print("[StateStore] Stacked item: ", item_data.item_id, " new quantity: ", new_qty)
			inventory_updated.emit()
			state_changed.emit("inventory", inventory)
			return
	
	# Not stackable or first occurrence - add as new entry
	# Convert back to dict with merged data
	inventory.append(item_data.to_dict())
	print("[StateStore] Added new item: ", item_data.item_id, " stackable: ", item_data.is_stackable)
	inventory_updated.emit()
	state_changed.emit("inventory", inventory)

func add_item_data(item: ItemData) -> void:
	# Already an ItemData object, handle stacking
	if item.is_stackable:
		var existing_index = -1
		for i in range(inventory.size()):
			var inv_item_dict = inventory[i]
			var inv_item_id = inv_item_dict.get("item_id", inv_item_dict.get("id", ""))
			if inv_item_id == item.item_id:
				existing_index = i
				break
		
		if existing_index >= 0:
			# Stack with existing item
			var existing_dict = inventory[existing_index]
			var current_qty = existing_dict.get("quantity", 1)
			var new_qty = current_qty + item.quantity
			existing_dict["quantity"] = new_qty
			print("[StateStore] Stacked ItemData: ", item.item_id, " new quantity: ", new_qty)
			inventory_updated.emit()
			state_changed.emit("inventory", inventory)
			return
	
	# Not stackable or first occurrence
	inventory.append(item.to_dict())
	print("[StateStore] Added new ItemData: ", item.item_id, " stackable: ", item.is_stackable)
	inventory_updated.emit()
	state_changed.emit("inventory", inventory)

func add_item_by_id(item_id: String) -> void:
	var item_dict = ItemDatabase.get_item(item_id)
	if item_dict.is_empty():
		print("[StateStore] Item not found in database: %s" % item_id)
		return
	
	inventory.append(item_dict)
	inventory_updated.emit()
	state_changed.emit("inventory", inventory)
	print("[StateStore] Item added to inventory: %s" % item_id)

func remove_item(item_id: String) -> void:
	for i in range(inventory.size()):
		var item = inventory[i]
		if item.get("item_id", item.get("id", "")) == item_id:
			print("[StateStore] Removing item: ", item_id)
			inventory.remove_at(i)
			inventory_updated.emit()
			state_changed.emit("inventory", inventory)
			return
	print("[StateStore] Item not found for removal: ", item_id)

func get_inventory_item_count(item_id: String) -> int:
	var count = 0
	for item in inventory:
		if item.get("item_id", item.get("id", "")) == item_id:
			count += item.get("quantity", 1)
	return count

func update_item_quantity(item_id: String, new_quantity: int) -> void:
	for item in inventory:
		if item.get("item_id", item.get("id", "")) == item_id:
			print("[StateStore] Updating item quantity: ", item_id, " to ", new_quantity)
			item["quantity"] = new_quantity
			if new_quantity <= 0:
				remove_item(item_id)
			else:
				inventory_updated.emit()
				state_changed.emit("inventory", inventory)
			return
	print("[StateStore] Item not found for quantity update: ", item_id)

func get_item_by_id(item_id: String) -> Dictionary:
	for item in inventory:
		if item.get("item_id", item.get("id", "")) == item_id:
			return item
	return {}

func get_item_data_by_id(item_id: String) -> ItemData:
	var item_dict = get_item_by_id(item_id)
	if item_dict.is_empty():
		return null
	return ItemData.from_dict(item_dict)

func get_all_items_data() -> Array[ItemData]:
	var items_data: Array[ItemData] = []
	for item_dict in inventory:
		items_data.append(ItemData.from_dict(item_dict))
	return items_data

## Market Methods
func cache_market_ticker(region_id: int, data: Dictionary) -> void:
	market_ticker[region_id] = data
	_market_cache_time[region_id] = Time.get_unix_time_from_system()
	state_changed.emit("market_ticker", data)

func get_cached_ticker(region_id: int) -> Dictionary:
	var cache_time = _market_cache_time.get(region_id, 0)
	var current_time = Time.get_unix_time_from_system()
	
	if current_time - cache_time > MARKET_CACHE_TTL:
		return {}  # Cache expired
	
	return market_ticker.get(region_id, {})

func is_ticker_cached(region_id: int) -> bool:
	return not get_cached_ticker(region_id).is_empty()

## Quest Methods
func set_active_quests(quests: Array) -> void:
	active_quests = quests
	state_changed.emit("active_quests", quests)

func add_quest(quest: Dictionary) -> void:
	active_quests.append(quest)
	state_changed.emit("active_quests", active_quests)

func complete_quest(quest_id: String) -> void:
	for i in range(active_quests.size()):
		if active_quests[i].get("id", "") == quest_id:
			completed_quests.append(active_quests[i])
			active_quests.remove_at(i)
			state_changed.emit("active_quests", active_quests)
			return

## Guild Methods
func set_guild_info(data: Dictionary) -> void:
	guild_info = data
	state_changed.emit("guild_info", guild_info)

func set_guild_members(members: Array) -> void:
	guild_members = members
	state_changed.emit("guild_members", guild_members)

## Hospital Methods
func set_hospital_status(in_hospital_flag: bool, release_time: int = 0) -> void:
	in_hospital = in_hospital_flag
	hospital_release_time = release_time
	state_changed.emit("hospital", {"in_hospital": in_hospital, "release_time": release_time})

func get_hospital_remaining_minutes() -> int:
	if not in_hospital:
		return 0
	
	var current_time = Time.get_unix_time_from_system()
	var remaining = hospital_release_time - current_time
	return max(0, int(remaining / 60.0))

func get_hospital_remaining_seconds() -> int:
	if not in_hospital:
		return 0
	
	var current_time = Time.get_unix_time_from_system()
	var remaining = hospital_release_time - current_time
	return max(0, int(remaining))

## Check and update hospital status if time has expired
func check_hospital_status() -> void:
	if in_hospital and get_hospital_remaining_seconds() <= 0:
		in_hospital = false
		hospital_release_time = 0
		state_changed.emit("hospital", {"in_hospital": false, "release_time": 0})
		print("[StateStore] Hospital time expired, player released")

## Settings
func set_setting(key: String, value: Variant) -> void:
	settings[key] = value
	_save_settings()
	state_changed.emit("settings", settings)

func get_setting(key: String, default: Variant = {}) -> Variant:
	return settings.get(key, default)

## Update player data fields (for dungeon rewards, etc)
func update_player_data(updates: Dictionary) -> void:
	for key in updates:
		player[key] = updates[key]
		if key == "gold":
			gold = updates[key]
			state_changed.emit("gold", gold)
		elif key == "exp" or key == "xp":
			xp = updates[key]
			# Level up kontrolü
			_check_level_up()
			state_changed.emit("xp", xp)
		elif key == "energy":
			current_energy = updates[key]
			energy_updated.emit()
			state_changed.emit("energy", {"current": current_energy, "max": max_energy})
		elif key == "max_energy":
			max_energy = updates[key]
			state_changed.emit("max_energy", max_energy)
		elif key == "level":
			level = updates[key]
			state_changed.emit("level", level)
		elif key == "gems":
			gems = updates[key]
			state_changed.emit("gems", gems)
	_save_player_data()
	# Arka planda Supabase'e sync et
	_sync_to_supabase_background()
	player_updated.emit()
	print("[StateStore] Player data updated: %s" % updates)

func _on_session_logged_in(data: Dictionary) -> void:
	# Load authoritative player data provided by session/login
	if data:
		load_player_data(data)
		print("[StateStore] Player data loaded from session login")
	
	# Load inventory from server
	# InventoryManager should be available as autoload
	var inventory_node = get_node_or_null("/root/InventoryManager")
	if not inventory_node:
		# Try alternative autoload name
		inventory_node = get_node_or_null("/root/Inventory")
	
	if inventory_node and inventory_node.has_method("fetch_inventory"):
		print("[StateStore] Loading inventory from server...")
		var inv_result = await inventory_node.fetch_inventory()
		if inv_result.get("success", false):
			print("[StateStore] Inventory loaded: %d items" % inv_result.get("items", []).size())
		else:
			print("[StateStore] Failed to load inventory: %s" % inv_result.get("error", "Unknown error"))

func _on_session_status_checked(is_authenticated: bool) -> void:
	# If session validated and authenticated, fetch profile from server
	if is_authenticated and Network:
		print("[StateStore] Session validated; fetching player profile from server")
		# Try canonical profile endpoint first
		var profile_result = await Network.http_get(APIEndpoints.PLAYER_PROFILE)
		if profile_result and profile_result.get("success", false) and profile_result.get("data", null):
			load_player_data(profile_result.get("data", {}))
			print("[StateStore] Player profile loaded from server on session check")
			return
		# If profile endpoint missing or returned 404, try fallback via auth user -> users lookup
		print("[StateStore] Primary profile fetch failed, attempting fallback via auth user. Response:", profile_result)
		var auth_user = await Network.http_get("/auth/v1/user")
		if auth_user and auth_user.get("success", false) and auth_user.get("data", null):
			var auth_data = auth_user.get("data", {})
			var auth_id = auth_data.get("id", "")
			print("[StateStore] auth user id: %s" % auth_id)
			if auth_id != "":
				# Query game.users by auth_id
				# Query game.users by auth_id (do not add extra quoting; PostgREST expects bare UUID)
				var users_endpoint = "/rest/v1/users?select=*&auth_id=eq.%s" % auth_id
				print("[StateStore] users_endpoint: %s" % users_endpoint)
				var users_res = await Network.http_get(users_endpoint)
				print("[StateStore] users_res:", users_res)
				var users_data = users_res.get("data", null) if users_res else null
				# Diagnostic: log data type and size when possible
				var users_size = "N/A"
				if users_data:
					if typeof(users_data) == TYPE_ARRAY:
						users_size = str(users_data.size())
					elif typeof(users_data) == TYPE_DICTIONARY:
						users_size = str(users_data.size())
				print("[StateStore] users_data type: %s, size: %s" % [typeof(users_data), users_size])
				if users_res and users_res.get("success", false) and users_data and typeof(users_data) == TYPE_ARRAY and users_data.size() > 0:
					load_player_data(users_data[0])
					print("[StateStore] Player profile loaded via auth->users fallback")
					return
				else:
					print("[StateStore] No game.users row found for auth_id=%s; emitting profile_missing" % auth_id)
					state_changed.emit("profile_missing", auth_id)
					return
		# If all fails, log and continue without player data
		print("[StateStore] Failed to load player profile via all methods; response1:", profile_result, "auth_user:", auth_user)
	else:
		print("[StateStore] Session not authenticated or Network not available")

## Arka planda sync işlemini başlat
func _sync_to_supabase_background():
	await _sync_to_supabase()

## Supabase'e güncelleme gönder (async coroutine)
func _sync_to_supabase() -> void:
	if not Network:
		print("[StateStore] Network manager not available")
		return
	
	# Eğer player ID yoksa sync etme
	if not player.has("id") or player["id"].is_empty():
		print("[StateStore] No player ID, skipping sync")
		return
	
	var player_id = player["id"]
	
	# Oyuncu verilerini güncelle - sadece değişen fields (PATCH için)
	# Ensure max_energy >= energy to satisfy DB CHECK constraint
	var safe_max_energy = max(max_energy, current_energy)
	var update_data = {
		"xp": xp,
		"gold": gold,
		"gems": gems,
		"level": level,
		"energy": current_energy,
		"max_energy": safe_max_energy
	}
	
	print("[StateStore] Attempting Supabase sync for player %s with data: %s" % [player_id, update_data])
	
	# Supabase REST API: PATCH /rest/v1/users?id=eq.{player_id}
	var endpoint = "/rest/v1/users?id=eq.%s" % player_id
	var response = await Network.http_patch(endpoint, update_data)
	
	print("[StateStore] Sync response code: %s, success: %s" % [response.get("code", "?"), response.get("success", false)])
	
	if response and response.get("success", false):
		print("[StateStore] ✓ Successfully synced to Supabase for player %s" % player_id)
	else:
		var error_msg = response.get("error", "Unknown error") if response else "No response"
		var response_code = response.get("code", "N/A") if response else "N/A"
		var error_data = response.get("data", {}) if response else {}
		print("[StateStore] ✗ Supabase sync failed! Code: %s, Error: %s, Message: %s" % [response_code, error_msg, error_data.get("message", "")])

func _save_settings() -> void:
	var config = ConfigFile.new()
	for key in settings:
		config.set_value("settings", key, settings[key])
	config.save("user://settings.cfg")

func _load_settings() -> void:
	var config = ConfigFile.new()
	var error = config.load("user://settings.cfg")
	if error == OK:
		for key in config.get_section_keys("settings"):
			settings[key] = config.get_value("settings", key)

## Clear State (logout)
func clear_state() -> void:
	player = {}
	inventory = []
	equipped_items = {}
	active_quests = []
	guild_info = {}
	guild_members = []
	pvp_history = []
	market_ticker = {}
	market_orders = {}
	_market_cache_time = {}
	
	current_energy = 100
	max_energy = 100
	tolerance = 0
	gold = 0
	gems = 0
	level = 1
	reputation = 0
	# Emit updates so UI can refresh immediately
	player_updated.emit()
	inventory_updated.emit()
	state_changed.emit("player", player)
	state_changed.emit("inventory", inventory)
	in_hospital = false
	hospital_release_time = 0
	
	print("[State] State cleared")

## Logout - clear state and reset
func logout() -> void:
	print("[StateStore] Logout called")
	clear_state()
	# Delete saved data
	var config = ConfigFile.new()
	var path = "user://player.cfg"
	if ResourceLoader.exists(path):
		var dir = DirAccess.open(path.get_base_dir())
		if dir:
			dir.remove(path)
	print("[StateStore] Logout complete - state cleared and cache deleted")
## Save player data to disk for persistence
func _save_player_data() -> void:
	# If a session is authenticated, avoid local persistence — database is source of truth
	if Session and Session.is_authenticated:
		print("[StateStore] Session authenticated — skipping local save (server is authoritative)")
		return

	var config = ConfigFile.new()
	config.set_value("player", "data", player)
	var path = "user://player.cfg"
	var error = config.save(path)
	if error != OK:
		print("[StateStore] Failed to save player data: ", error)
	else:
		print("[StateStore] Player data saved to disk")

## Load player data from disk at startup
func _load_player_data() -> bool:
	# Only load from disk if user is NOT authenticated; server is source of truth otherwise
	if Session and Session.is_authenticated:
		print("[StateStore] Skipping local load because session is authenticated")
		return false

	var config = ConfigFile.new()
	var path = "user://player.cfg"
	
	var error = config.load(path)
	if error != OK:
		print("[StateStore] No saved player data found")
		return false
	
	var saved_player = config.get_value("player", "data", {})
	if not saved_player.is_empty():
		# Load without re-saving (to avoid recursion)
		player = saved_player
		current_energy = saved_player.get("energy", 100)
		max_energy = saved_player.get("max_energy", 100)
		tolerance = saved_player.get("addiction_level", 0)
		gold = saved_player.get("gold", 0)
		gems = saved_player.get("gems", 0)
		level = saved_player.get("level", 1)
		xp = saved_player.get("xp", 0)
		pvp_rating = saved_player.get("pvp_rating", 1000)
		pvp_wins = saved_player.get("pvp_wins", 0)
		pvp_losses = saved_player.get("pvp_losses", 0)
		print("[StateStore] Player data loaded from disk: Level %d" % level)
		return true
	
	return false
