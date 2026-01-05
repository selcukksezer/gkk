extends Node
## Enhancement Manager
## Handles item enhancement from +0 to +10 with success rates and runes

signal enhancement_started(item_id: String, current_level: int)
signal enhancement_success(item_id: String, new_level: int)
signal enhancement_failed(item_id: String, level: int, item_destroyed: bool)

# Import required classes
const InventoryManager = preload("res://autoload/InventoryManager.gd")
const ItemDatabase = preload("res://core/data/ItemDatabase.gd")

# Enhancement success rates by level
const BASE_SUCCESS_RATES = {
	0: 100,
	1: 95,
	2: 90,
	3: 80,
	4: 70,
	5: 60,
	6: 50,
	7: 40,
	8: 30,
	9: 20
}

# Enhancement costs in gold by level
const ENHANCEMENT_COSTS = {
	0: 100,
	1: 200,
	2: 400,
	3: 800,
	4: 1600,
	5: 3200,
	6: 6400,
	7: 12800,
	8: 25600,
	9: 51200
}

# Rune types and their effects
const RUNES = {
	"none": {
		"name": "None",
		"success_bonus": 0,
		"cost": 0,
		"prevent_destruction": false
	},
	"basic": {
		"name": "Basic Rune",
		"success_bonus": 5,
		"cost": 100,
		"prevent_destruction": false
	},
	"advanced": {
		"name": "Advanced Rune",
		"success_bonus": 10,
		"cost": 500,
		"prevent_destruction": false
	},
	"superior": {
		"name": "Superior Rune",
		"success_bonus": 20,
		"cost": 2000,
		"prevent_destruction": false
	},
	"legendary": {
		"name": "Legendary Rune",
		"success_bonus": 30,
		"cost": 10000,
		"prevent_destruction": false
	},
	"protection": {
		"name": "Protection Rune",
		"success_bonus": 0,
		"cost": 5000,
		"prevent_destruction": true
	}
}

# Failure penalties by level
const FAILURE_PENALTIES = {
	0: {"level_loss": 0, "can_destroy": false},
	1: {"level_loss": 0, "can_destroy": false},
	2: {"level_loss": 0, "can_destroy": false},
	3: {"level_loss": 1, "can_destroy": false},
	4: {"level_loss": 1, "can_destroy": false},
	5: {"level_loss": 2, "can_destroy": false},
	6: {"level_loss": 2, "can_destroy": true},
	7: {"level_loss": 3, "can_destroy": true},
	8: {"level_loss": 3, "can_destroy": true},
	9: {"level_loss": 4, "can_destroy": true}
}

func _ready() -> void:
	pass

func calculate_success_rate(current_level: int, rune_type: String = "none") -> float:
	"""Calculate success rate for enhancement"""
	if current_level >= 10:
		return 0.0

	var base_rate = BASE_SUCCESS_RATES.get(current_level, 0)
	var rune_bonus = RUNES.get(rune_type, {}).get("success_bonus", 0)

	return clamp(base_rate + rune_bonus, 0, 100)

func calculate_success_rate_with_rune(item: ItemData, rune: ItemData = null) -> float:
	"""Calculate success rate using ItemData rune system"""
	if item.enhancement_level >= item.max_enhancement:
		return 0.0

	var base_rate = item.get_enhancement_success_rate() * 100

	if rune and rune.is_rune() and rune.can_apply_to_item(item):
		base_rate += rune.rune_success_bonus

	return clamp(base_rate, 0, 100)

func calculate_enhancement_cost(current_level: int, rune_type: String = "none") -> Dictionary:
	"""Calculate total cost for enhancement attempt"""
	var base_cost = ENHANCEMENT_COSTS.get(current_level, 0)
	var rune_cost = RUNES.get(rune_type, {}).get("cost", 0)
	
	return {
		"gold": base_cost,
		"rune_cost": rune_cost,
		"total": base_cost + rune_cost
	}

func can_enhance(item: ItemData, rune: ItemData = null) -> Dictionary:
	"""Check if item can be enhanced using ItemData"""
	# Check if item can be enhanced
	if not item.can_enhance:
		return {"can_enhance": false, "reason": "Item cannot be enhanced"}

	# Check max level
	if item.enhancement_level >= item.max_enhancement:
		return {"can_enhance": false, "reason": "Max enhancement level reached"}

	# Check cost
	var cost = calculate_enhancement_cost(item.enhancement_level, "none")  # Legacy cost calculation
	if State.gold < cost.total:
		return {"can_enhance": false, "reason": "Not enough gold"}

	# Check rune availability
	if rune:
		if not rune.is_rune():
			return {"can_enhance": false, "reason": "Invalid rune"}
		if not rune.can_apply_to_item(item):
			return {"can_enhance": false, "reason": "Rune cannot be applied to this item"}
		if State.get_inventory_item_count(rune.item_id) <= 0:
			return {"can_enhance": false, "reason": "Rune not available"}

	return {"can_enhance": true}

func enhance_item(item: ItemData, rune: ItemData = null) -> Dictionary:
	"""Attempt to enhance an item using ItemData"""
	enhancement_started.emit(item.item_id, item.enhancement_level)

	# Calculate success rate
	var success_rate = calculate_success_rate_with_rune(item, rune) / 100.0
	var roll = randf()

	print("[Enhancement] Attempting enhancement: level %d -> %d, success_rate: %.2f%%, roll: %.2f" % [
		item.enhancement_level, item.enhancement_level + 1, success_rate * 100, roll
	])

	if roll < success_rate:
		# Success
		item.enhancement_level += 1

		# Consume rune if used
		if rune:
			var inventory_manager = InventoryManager.new()
			await inventory_manager.remove_item(rune.item_id, 1)

		# Update item in state
		State.update_inventory_item(item.item_id, item.to_dict())

		enhancement_success.emit(item.item_id, item.enhancement_level)

		Telemetry.track_enhancement("success", item.item_id, {
			"from_level": item.enhancement_level - 1,
			"to_level": item.enhancement_level,
			"rune_used": rune.item_id if rune else "none"
		})

		return {"success": true, "new_level": item.enhancement_level}
	else:
		# Failure - calculate penalties
		var destruction_rate = item.get_enhancement_destruction_rate()
		var destruction_roll = randf()

		var item_destroyed = destruction_roll < destruction_rate
		var level_loss = 0

		if not item_destroyed:
			# Apply level loss based on current level
			var penalties = FAILURE_PENALTIES.get(item.enhancement_level, {"level_loss": 1, "can_destroy": false})
			level_loss = penalties.level_loss
			item.enhancement_level = max(0, item.enhancement_level - level_loss)

		print("[Enhancement] Failed: destroyed=%s, level_loss=%d" % [item_destroyed, level_loss])

		# Consume rune if used (even on failure)
		if rune:
			var inventory_manager = InventoryManager.new()
			await inventory_manager.remove_item(rune.item_id, 1)

		if item_destroyed:
			# Remove item from inventory
			var inventory_manager = InventoryManager.new()
			await inventory_manager.remove_item(item.item_id, 1)
		else:
			# Update item with reduced level
			State.update_inventory_item(item.item_id, item.to_dict())

		enhancement_failed.emit(item.item_id, item.enhancement_level, item_destroyed)

		Telemetry.track_enhancement("failure", item.item_id, {
			"level": item.enhancement_level,
			"destroyed": item_destroyed,
			"level_loss": level_loss,
			"rune_used": rune.item_id if rune else "none"
		})

		return {"success": false, "destroyed": item_destroyed, "level_loss": level_loss}

func simulate_enhancement(current_level: int, rune_type: String = "none") -> Dictionary:
	"""Simulate enhancement for UI preview (client-side only)"""
	var success_rate = calculate_success_rate(current_level, rune_type)
	var roll = randf() * 100
	
	var success = roll <= success_rate
	
	if success:
		return {
			"success": true,
			"new_level": current_level + 1,
			"destroyed": false
		}
	else:
		var penalty = FAILURE_PENALTIES.get(current_level, {})
		var level_loss = penalty.get("level_loss", 0)
		var can_destroy = penalty.get("can_destroy", false)
		
		# Check protection rune
		var is_protected = RUNES.get(rune_type, {}).get("prevent_destruction", false)
		
		var destroyed = false
		if can_destroy and not is_protected:
			# 20% chance of destruction on eligible levels
			destroyed = randf() < 0.2
		
		if destroyed:
			return {
				"success": false,
				"new_level": 0,
				"destroyed": true
			}
		else:
			return {
				"success": false,
				"new_level": max(0, current_level - level_loss),
				"destroyed": false
			}

func get_enhancement_info(current_level: int, rune_type: String = "none") -> Dictionary:
	"""Get comprehensive enhancement information for UI"""
	var success_rate = calculate_success_rate(current_level, rune_type)
	var cost = calculate_enhancement_cost(current_level, rune_type)
	var penalty = FAILURE_PENALTIES.get(current_level, {})
	
	return {
		"current_level": current_level,
		"max_level": 10,
		"can_enhance": current_level < 10,
		"success_rate": success_rate,
		"cost": cost,
		"rune": RUNES.get(rune_type, {}),
		"failure_penalty": {
			"level_loss": penalty.get("level_loss", 0),
			"can_destroy": penalty.get("can_destroy", false)
		}
	}

func get_available_runes() -> Array:
	"""Get list of runes player owns"""
	var available = []
	
	for rune_id in RUNES.keys():
		if rune_id == "none":
			available.append({"id": "none", "name": "None", "count": 999})
			continue
		
		var rune_item_id = rune_id + "_rune"
		var count = State.get_inventory_item_count(rune_item_id)
		
		if count > 0:
			available.append({
				"id": rune_id,
				"name": RUNES[rune_id].name,
				"count": count,
				"bonus": RUNES[rune_id].success_bonus,
				"prevents_destruction": RUNES[rune_id].prevent_destruction
			})
	
	return available

func get_enhancement_stats() -> Dictionary:
	"""Get player's enhancement statistics"""
	var stats = State.player_data.get("enhancement_stats", {})
	
	return {
		"total_attempts": stats.get("total_attempts", 0),
		"successful": stats.get("successful", 0),
		"failed": stats.get("failed", 0),
		"destroyed": stats.get("destroyed", 0),
		"success_rate": _calculate_success_percentage(stats),
		"highest_level": stats.get("highest_level", 0),
		"gold_spent": stats.get("gold_spent", 0)
	}

func _calculate_success_percentage(stats: Dictionary) -> float:
	var total = stats.get("total_attempts", 0)
	if total == 0:
		return 0.0
	
	var successful = stats.get("successful", 0)
	return (successful / float(total)) * 100.0
