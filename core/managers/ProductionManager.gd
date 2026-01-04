extends Node
## Production Manager
## Handles building management, production queues, recipes, and resource collection

signal production_started(building_id: String, recipe_id: String)
signal production_completed(building_id: String, item_id: String, quantity: int)
signal building_upgraded(building_id: String, new_level: int)
signal queue_updated(queue: Array)

const MAX_QUEUE_SIZE = 10

# Building definitions
const BUILDINGS = {
	"farm": {
		"name": "Farm",
		"icon": "🌾",
		"base_cost": 1000,
		"upgrade_multiplier": 1.5
	},
	"mine": {
		"name": "Mine",
		"icon": "⛏️",
		"base_cost": 2000,
		"upgrade_multiplier": 1.6
	},
	"workshop": {
		"name": "Workshop",
		"icon": "🔨",
		"base_cost": 3000,
		"upgrade_multiplier": 1.7
	},
	"alchemy_lab": {
		"name": "Alchemy Lab",
		"icon": "⚗️",
		"base_cost": 5000,
		"upgrade_multiplier": 1.8
	},
	"enchanting_tower": {
		"name": "Enchanting Tower",
		"icon": "✨",
		"base_cost": 10000,
		"upgrade_multiplier": 2.0
	}
}

# Recipe definitions
const RECIPES = {
	"farm": [
		{"id": "wheat", "name": "Wheat", "duration": 60, "materials": {}, "output": {"wheat": 10}, "min_level": 1},
		{"id": "corn", "name": "Corn", "duration": 120, "materials": {}, "output": {"corn": 5}, "min_level": 3},
		{"id": "potato", "name": "Potato", "duration": 180, "materials": {}, "output": {"potato": 8}, "min_level": 5}
	],
	"mine": [
		{"id": "iron_ore", "name": "Iron Ore", "duration": 120, "materials": {}, "output": {"iron_ore": 5}, "min_level": 1},
		{"id": "gold_ore", "name": "Gold Ore", "duration": 300, "materials": {}, "output": {"gold_ore": 3}, "min_level": 5},
		{"id": "diamond", "name": "Diamond", "duration": 600, "materials": {}, "output": {"diamond": 1}, "min_level": 10}
	],
	"workshop": [
		{"id": "iron_sword", "name": "Iron Sword", "duration": 180, "materials": {"iron_ore": 5, "wood": 2}, "output": {"iron_sword": 1}, "min_level": 1},
		{"id": "steel_armor", "name": "Steel Armor", "duration": 300, "materials": {"iron_ore": 10, "coal": 5}, "output": {"steel_armor": 1}, "min_level": 5},
		{"id": "legendary_blade", "name": "Legendary Blade", "duration": 600, "materials": {"diamond": 3, "gold_ore": 10, "mythril": 5}, "output": {"legendary_blade": 1}, "min_level": 15}
	],
	"alchemy_lab": [
		{"id": "health_potion", "name": "Health Potion", "duration": 60, "materials": {"herb": 3}, "output": {"health_potion": 5}, "min_level": 1},
		{"id": "mana_potion", "name": "Mana Potion", "duration": 90, "materials": {"herb": 5, "crystal": 1}, "output": {"mana_potion": 3}, "min_level": 3},
		{"id": "elixir_of_strength", "name": "Elixir of Strength", "duration": 240, "materials": {"rare_herb": 5, "dragon_blood": 1}, "output": {"elixir_of_strength": 1}, "min_level": 10}
	],
	"enchanting_tower": [
		{"id": "basic_rune", "name": "Basic Rune", "duration": 120, "materials": {"magic_dust": 10}, "output": {"basic_rune": 1}, "min_level": 1},
		{"id": "advanced_rune", "name": "Advanced Rune", "duration": 300, "materials": {"magic_dust": 25, "soul_gem": 1}, "output": {"advanced_rune": 1}, "min_level": 7},
		{"id": "legendary_rune", "name": "Legendary Rune", "duration": 900, "materials": {"magic_dust": 100, "soul_gem": 5, "essence": 10}, "output": {"legendary_rune": 1}, "min_level": 15}
	]
}

# Player building states (loaded from backend)
var buildings: Dictionary = {}
var production_queue: Array = []

func _ready() -> void:
	# Connect to state updates
	State.connect("player_updated", _on_player_updated)
	
	# Load initial data
	load_buildings()

func load_buildings() -> void:
	"""Load player's building data from backend"""
	var response = await Network.http_get("/production/buildings")
	
	if response.success:
		buildings = response.data.get("buildings", {})
		production_queue = response.data.get("queue", [])
		queue_updated.emit(production_queue)
	else:
		print("[ProductionManager] Failed to load buildings: ", response.error)

func get_building_level(building_id: String) -> int:
	"""Get current level of a building"""
	return buildings.get(building_id, {}).get("level", 0)

func get_building_info(building_id: String) -> Dictionary:
	"""Get full building information"""
	var base_info = BUILDINGS.get(building_id, {})
	var player_data = buildings.get(building_id, {"level": 0})
	
	return {
		"id": building_id,
		"name": base_info.get("name", "Unknown"),
		"icon": base_info.get("icon", "🏗️"),
		"level": player_data.get("level", 0),
		"upgrade_cost": calculate_upgrade_cost(building_id),
		"recipes": get_available_recipes(building_id)
	}

func get_available_recipes(building_id: String) -> Array:
	"""Get recipes available for building based on level"""
	var level = get_building_level(building_id)
	var all_recipes = RECIPES.get(building_id, [])
	var available = []
	
	for recipe in all_recipes:
		if recipe.get("min_level", 1) <= level:
			available.append(recipe)
	
	return available

func calculate_upgrade_cost(building_id: String) -> int:
	"""Calculate gold cost to upgrade building"""
	var base_cost = BUILDINGS.get(building_id, {}).get("base_cost", 1000)
	var multiplier = BUILDINGS.get(building_id, {}).get("upgrade_multiplier", 1.5)
	var current_level = get_building_level(building_id)
	
	return int(base_cost * pow(multiplier, current_level))

func start_production(building_id: String, recipe_id: String) -> Dictionary:
	"""Start a production job"""
	# Validate queue size
	if production_queue.size() >= MAX_QUEUE_SIZE:
		return {"success": false, "error": "Production queue is full"}
	
	# Validate building level
	var building_level = get_building_level(building_id)
	if building_level <= 0:
		return {"success": false, "error": "Building not unlocked"}
	
	# Find recipe
	var recipe = _find_recipe(building_id, recipe_id)
	if recipe.is_empty():
		return {"success": false, "error": "Recipe not found"}
	
	# Check level requirement
	if recipe.get("min_level", 1) > building_level:
		return {"success": false, "error": "Building level too low"}
	
	# Send to backend
	var response = await Network.http_post("/production/start", {
		"building_id": building_id,
		"recipe_id": recipe_id
	})
	
	if response.success:
		production_queue.append(response.data.get("production_item", {}))
		production_started.emit(building_id, recipe_id)
		queue_updated.emit(production_queue)
		
		# Start local timer for UI updates
		_start_production_timer(response.data.get("production_item", {}))
	
	return response

func collect_production(production_id: String) -> Dictionary:
	"""Collect completed production"""
	var response = await Network.http_post("/production/collect", {
		"production_id": production_id
	})
	
	if response.success:
		var collected = response.data.get("collected", {})
		
		# Remove from queue
		production_queue = production_queue.filter(func(item): return item.get("id") != production_id)
		queue_updated.emit(production_queue)
		
		# Emit completion signal
		production_completed.emit(
			collected.get("building_id", ""),
			collected.get("item_id", ""),
			collected.get("quantity", 0)
		)
		
		# Update inventory
		if State.player_data.has("inventory"):
			for item_id in collected.get("items", {}):
				var quantity = collected["items"][item_id]
				State.add_to_inventory(item_id, quantity)
	
	return response

func upgrade_building(building_id: String) -> Dictionary:
	"""Upgrade a building"""
	var cost = calculate_upgrade_cost(building_id)
	
	# Check gold
	if State.get_gold() < cost:
		return {"success": false, "error": "Not enough gold"}
	
	# Send to backend
	var response = await Network.http_post("/production/upgrade", {
		"building_id": building_id
	})
	
	if response.success:
		var new_level = response.data.get("new_level", 1)
		
		# Update local data
		if not buildings.has(building_id):
			buildings[building_id] = {}
		buildings[building_id]["level"] = new_level
		
		# Update gold
		State.add_gold(-cost)
		
		# Emit signal
		building_upgraded.emit(building_id, new_level)
	
	return response

func get_queue_status() -> Array:
	"""Get current production queue with remaining times"""
	var status = []
	
	for item in production_queue:
		var started_at = Time.get_unix_time_from_datetime_string(item.get("started_at", ""))
		var duration = item.get("duration", 0)
		var completed_at = started_at + duration
		var remaining = max(0, completed_at - Time.get_unix_time_from_system())
		
		status.append({
			"id": item.get("id"),
			"building_id": item.get("building_id"),
			"recipe_id": item.get("recipe_id"),
			"recipe_name": item.get("recipe_name"),
			"started_at": started_at,
			"duration": duration,
			"remaining": remaining,
			"progress": clamp(1.0 - (remaining / float(duration)), 0.0, 1.0),
			"is_complete": remaining <= 0
		})
	
	return status

func cancel_production(production_id: String) -> Dictionary:
	"""Cancel a production job (with partial refund)"""
	var response = await Network.http_post("/production/cancel", {
		"production_id": production_id
	})
	
	if response.success:
		# Remove from queue
		production_queue = production_queue.filter(func(item): return item.get("id") != production_id)
		queue_updated.emit(production_queue)
	
	return response

func _find_recipe(building_id: String, recipe_id: String) -> Dictionary:
	"""Find recipe by ID"""
	var recipes = RECIPES.get(building_id, [])
	for recipe in recipes:
		if recipe.get("id") == recipe_id:
			return recipe
	return {}

func _start_production_timer(item: Dictionary) -> void:
	"""Start a timer to update UI when production completes"""
	var duration = item.get("duration", 0)
	
	await get_tree().create_timer(duration).timeout
	
	# Notify UI to refresh
	queue_updated.emit(production_queue)

func _on_player_updated() -> void:
	"""Handle player data updates"""
	# Reload buildings if needed
	if State.player_data.has("buildings"):
		buildings = State.player_data.buildings
