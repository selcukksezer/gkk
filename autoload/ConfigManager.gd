extends Node
## Config Manager - Server configuration cache
## Singleton autoload: Config

signal config_loaded()
signal config_updated(key: String, value: Variant)

const CONFIG_ENDPOINT = "/api/v1/config"
const CACHE_FILE = "user://server_config.json"
const CACHE_TTL = 3600  # 1 hour in seconds

var _config: Dictionary = {}
var _cache_timestamp: int = 0
var _loading: bool = false


func _ready() -> void:
	print("[Config] Initializing...")
	_load_cache()
	# Check if cache is expired
	var enable_remote = ProjectSettings.get_setting("game_settings/server/enable_remote_config", false)
	if _is_cache_expired():
		if enable_remote:
			await refresh_config()
		else:
			print("[Config] Remote config disabled, loading local resource")
			_load_local_resource_config()

## Get config value
func get_value(key: String, default: Variant = {}) -> Variant:
	return _config.get(key, default)

## Get nested config value (dot notation)
func get_nested(path: String, default: Variant = {}) -> Variant:
	var keys = path.split(".")
	var current = _config
	
	for key in keys:
		if typeof(current) == TYPE_DICTIONARY and current.has(key):
			current = current[key]
		else:
			return default
	
	return current

## Energy config
func get_energy_config() -> Dictionary:
	return get_value("energy", {
		"max_energy": 100,
		"regen_interval": 180,  # 3 minutes
		"regen_rate": 1,
		"pvp_cost": 20,
		"quest_cost_easy": 10,
		"quest_cost_normal": 20,
		"quest_cost_hard": 30,
		"quest_cost_nightmare": 50
	})

## (Legacy config defaults removed - use gameplay-scoped getters below)

## Check if config has key
func has_key(key: String) -> bool:
	return _config.has(key)

## Refresh config from server
func refresh_config() -> Dictionary:
	if _loading:
		await config_loaded
		return {"success": true, "cached": true}
	
	_loading = true
	print("[Config] Fetching server config...")
	# Use GameHTTPClient for awaited HTTP requests
	var http = GameHTTPClient.new()
	var base = ""
	if has_node("/root/Network"):
		base = Network.BASE_URL
	else:
		base = ProjectSettings.get_setting("game_settings/server/base_url", "")
	http.initialize(self, base)
	var result = await http.http_get(CONFIG_ENDPOINT)
	
	if result.success and result.data.has("config"):
		_config = result.data.config
		_cache_timestamp = Time.get_unix_time_from_system()
		_save_cache()
		config_loaded.emit()
		print("[Config] Config loaded successfully")
	else:
		print("[Config] Failed to load config, using cache")
	
	_loading = false
	return result

## Force refresh (ignore cache)
func force_refresh() -> Dictionary:
	_cache_timestamp = 0
	return await refresh_config()

## Check if cache is expired
func _is_cache_expired() -> bool:
	if _cache_timestamp == 0:
		return true
	
	var current_time = Time.get_unix_time_from_system()
	return (current_time - _cache_timestamp) > CACHE_TTL

## Save cache to disk
func _save_cache() -> void:
	var cache_data = {
		"config": _config,
		"timestamp": _cache_timestamp
	}
	
	var file = FileAccess.open(CACHE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(cache_data, "\t"))
		file.close()

## Load cache from disk
func _load_cache() -> void:
	if not FileAccess.file_exists(CACHE_FILE):
		return
	
	var file = FileAccess.open(CACHE_FILE, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			var data = json.data
			_config = data.get("config", {})
			_cache_timestamp = data.get("timestamp", 0)
			print("[Config] Loaded cached config")

## Load config from bundled resource file
func _load_local_resource_config() -> void:
	var path = "res://resources/configs/game_config.json"
	if not FileAccess.file_exists(path):
		print("[Config] Local config resource not found: %s" % path)
		return
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		var json = JSON.new()
		var err = json.parse(json_string)
		if err == OK:
			var data = json.data
			# If file wraps under "config" key, prefer that, otherwise use top-level
			if typeof(data) == TYPE_DICTIONARY:
				if data.has("config"):
					_config = data.get("config", {})
				else:
					_config = data
				_cache_timestamp = Time.get_unix_time_from_system()
				print("[Config] Loaded local config resource")
				config_loaded.emit()

## Get energy config

## Get potion config
func get_potion_config() -> Dictionary:
	return get_nested("gameplay.potion", {
		"max_tolerance": 100,
		"tolerance_decay_rate": 1,  # per 6 hours
		"overdose_threshold": 0.8,  # 80% of max dose
		"hospital_base_duration": 60  # minutes
	})

## Get PvP config
func get_pvp_config() -> Dictionary:
	return get_nested("gameplay.pvp", {
		"base_win_chance": 0.5,
		"power_factor": 0.01,
		"reputation_gain": 5,
		"reputation_loss": -2,
		"cooldown": 300  # seconds
	})

## Get market config
func get_market_config() -> Dictionary:
	return get_nested("economy.market", {
		"commission_rate": 0.05,  # 5%
		"min_price": 1,
		"max_price": 999999,
		"max_orders_per_player": 20
	})

## Get quest config
func get_quest_config() -> Dictionary:
	return get_nested("gameplay.quest", {
		"max_active": 5,
		"daily_limit": 10,
		"energy_cost": 10,
		"base_reward_gold": 100
	})

## Get guild config
func get_guild_config() -> Dictionary:
	return get_nested("social.guild", {
		"creation_cost": 10000,
		"max_members": 50,
		"min_name_length": 3,
		"max_name_length": 20
	})

## Get monetization config
func get_monetization_config() -> Dictionary:
	return get_nested("monetization", {
		"gem_prices": {
			"100": 0.99,
			"500": 4.99,
			"1000": 9.99,
			"5000": 49.99
		},
		"energy_refill_gem_cost": 50,
		"hospital_instant_release_multiplier": 2.0
	})

## Get feature flags
func is_feature_enabled(feature_name: String) -> bool:
	return get_nested("features.%s" % feature_name, false)

## Get API version
func get_api_version() -> String:
	return get_value("api_version", "v1")

## Get maintenance status
func is_maintenance_mode() -> bool:
	return get_value("maintenance_mode", false)

func get_maintenance_message() -> String:
	return get_value("maintenance_message", "Server is under maintenance. Please try again later.")

## Get minimum supported client version
func get_min_client_version() -> String:
	return get_value("min_client_version", "1.0.0")
