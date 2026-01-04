extends Node
## Enhancement Manager
## Handles item enhancement from +0 to +10 with success rates and runes

signal enhancement_started(item_id: String, current_level: int)
signal enhancement_success(item_id: String, new_level: int)
signal enhancement_failed(item_id: String, level: int, item_destroyed: bool)

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

func calculate_enhancement_cost(current_level: int, rune_type: String = "none") -> Dictionary:
	"""Calculate total cost for enhancement attempt"""
	var base_cost = ENHANCEMENT_COSTS.get(current_level, 0)
	var rune_cost = RUNES.get(rune_type, {}).get("cost", 0)
	
	return {
		"gold": base_cost,
		"rune_cost": rune_cost,
		"total": base_cost + rune_cost
	}

func can_enhance(item: Dictionary, rune_type: String = "none") -> Dictionary:
	"""Check if item can be enhanced"""
	var current_level = item.get("enhancement_level", 0)
	
	# Check max level
	if current_level >= 10:
		return {"can_enhance": false, "reason": "Max enhancement level reached"}
	
	# Check cost
	var cost = calculate_enhancement_cost(current_level, rune_type)
	if State.get_gold() < cost.total:
		return {"can_enhance": false, "reason": "Not enough gold"}
	
	# Check rune availability
	if rune_type != "none":
		var rune_count = State.get_inventory_item_count(rune_type + "_rune")
		if rune_count <= 0:
			return {"can_enhance": false, "reason": "Rune not available"}
	
	return {"can_enhance": true}

func enhance_item(item_id: String, rune_type: String = "none") -> Dictionary:
	"""Attempt to enhance an item"""
	enhancement_started.emit(item_id, 0)
	
	# Send request to backend
	var response = await Network.http_post("/enhancement/enhance", {
		"item_id": item_id,
		"rune_type": rune_type
	})
	
	if response.success:
		var result = response.data
		var success = result.get("success", false)
		var new_level = result.get("new_level", 0)
		var destroyed = result.get("destroyed", false)
		var gold_spent = result.get("gold_spent", 0)
		
		# Update gold
		State.add_gold(-gold_spent)
		
		if success:
			# Success - update item in inventory
			State.update_item_enhancement(item_id, new_level)
			enhancement_success.emit(item_id, new_level)
			
			return {
				"success": true,
				"enhanced": true,
				"new_level": new_level,
				"destroyed": false
			}
		else:
			# Failed - handle penalties
			if destroyed:
				State.remove_from_inventory(item_id, 1)
				enhancement_failed.emit(item_id, new_level, true)
				
				return {
					"success": true,
					"enhanced": false,
					"new_level": 0,
					"destroyed": true
				}
			else:
				# Level decreased
				State.update_item_enhancement(item_id, new_level)
				enhancement_failed.emit(item_id, new_level, false)
				
				return {
					"success": true,
					"enhanced": false,
					"new_level": new_level,
					"destroyed": false
				}
	
	return response

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
