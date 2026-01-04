class_name GameConfig
extends Resource
## Game Configuration Loader
## Loads and provides access to game configuration

static var _config: Dictionary = {}
static var _items_db: Array = []
static var _quests_db: Array = []

## Load all configuration files
static func load_all() -> void:
	load_game_config()
	load_items_database()
	load_quests_database()
	print("[GameConfig] All configurations loaded")

## Load main game configuration
static func load_game_config() -> void:
	var file = FileAccess.open("res://resources/configs/game_config.json", FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_text)
		
		if parse_result == OK:
			_config = json.data
			print("[GameConfig] Game config loaded successfully")
		else:
			push_error("[GameConfig] Failed to parse game_config.json")
	else:
		push_error("[GameConfig] Failed to open game_config.json")

## Load items database
static func load_items_database() -> void:
	var file = FileAccess.open("res://resources/items/items_database.json", FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_text)
		
		if parse_result == OK:
			_items_db = json.data
			print("[GameConfig] Items database loaded: %d items" % _items_db.size())
		else:
			push_error("[GameConfig] Failed to parse items_database.json")
	else:
		push_error("[GameConfig] Failed to open items_database.json")

## Load quests database
static func load_quests_database() -> void:
	var file = FileAccess.open("res://resources/quests/quests_database.json", FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_text)
		
		if parse_result == OK:
			_quests_db = json.data
			print("[GameConfig] Quests database loaded: %d quests" % _quests_db.size())
		else:
			push_error("[GameConfig] Failed to parse quests_database.json")
	else:
		push_error("[GameConfig] Failed to open quests_database.json")

## Get configuration value
static func get_config(section: String, key: String = "", default = null) -> Variant:
	if not _config.has(section):
		return default
	
	if key.is_empty():
		return _config.get(section, default)
	
	var section_data = _config.get(section, {})
	return section_data.get(key, default)

## Get energy configuration
static func get_energy_config() -> Dictionary:
	return _config.get("energy", {})

## Get potion configuration
static func get_potion_config() -> Dictionary:
	return _config.get("potion", {})

## Get PvP configuration
static func get_pvp_config() -> Dictionary:
	return _config.get("pvp", {})

## Get quest configuration
static func get_quest_config() -> Dictionary:
	return _config.get("quest", {})

## Get hospital configuration
static func get_hospital_config() -> Dictionary:
	return _config.get("hospital", {})

## Get market configuration
static func get_market_config() -> Dictionary:
	return _config.get("market", {})

## Get guild configuration
static func get_guild_config() -> Dictionary:
	return _config.get("guild", {})

## Get enhancement configuration
static func get_enhancement_config() -> Dictionary:
	return _config.get("enhancement", {})

## Get monetization configuration
static func get_monetization_config() -> Dictionary:
	return _config.get("monetization", {})

## Get season configuration
static func get_season_config() -> Dictionary:
	return _config.get("season", {})

## Get item by ID
static func get_item(item_id: String) -> Dictionary:
	for item in _items_db:
		if item.get("id", "") == item_id:
			return item
	return {}

## Get all items
static func get_all_items() -> Array:
	return _items_db

## Get items by type
static func get_items_by_type(item_type: String) -> Array:
	var filtered = []
	for item in _items_db:
		if item.get("item_type", "") == item_type:
			filtered.append(item)
	return filtered

## Get items by rarity
static func get_items_by_rarity(rarity: String) -> Array:
	var filtered = []
	for item in _items_db:
		if item.get("rarity", "") == rarity:
			filtered.append(item)
	return filtered

## Get quest by ID
static func get_quest(quest_id: String) -> Dictionary:
	for quest in _quests_db:
		if quest.get("id", "") == quest_id:
			return quest
	return {}

## Get all quests
static func get_all_quests() -> Array:
	return _quests_db

## Get quests by type
static func get_quests_by_type(quest_type: String) -> Array:
	var filtered = []
	for quest in _quests_db:
		if quest.get("quest_type", "") == quest_type:
			filtered.append(quest)
	return filtered

## Get quests by difficulty
static func get_quests_by_difficulty(difficulty: String) -> Array:
	var filtered = []
	for quest in _quests_db:
		if quest.get("difficulty", "") == difficulty:
			filtered.append(quest)
	return filtered

## Get daily quests
static func get_daily_quests() -> Array:
	return get_quests_by_type("DAILY")

## Get weekly quests
static func get_weekly_quests() -> Array:
	return get_quests_by_type("WEEKLY")

## Get story quests
static func get_story_quests() -> Array:
	return get_quests_by_type("STORY")
