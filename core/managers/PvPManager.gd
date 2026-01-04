class_name PvPManager
extends RefCounted
## PvP Combat Manager
## Handles combat power calculation, attack outcomes, and reputation

signal attack_completed(result: Dictionary)
signal reputation_changed(new_reputation: int)

const PVP_ENDPOINT = "/api/v1/pvp"

## Attack another player
func attack_player(target_player_id: String) -> Dictionary:
	"""
	Returns: {
		"success": bool,
		"outcome": String,  # "major_win", "win", "draw", "loss", "major_loss"
		"gold_change": int,
		"reputation_change": int,
		"target_hospitalized": bool,
		"attacker_hospitalized": bool,
		"message": String
	}
	"""
	
	# Check energy
	var energy_cost = 10  # TODO: Get from config
	var energy_manager = EnergyManager.new()
	
	if not energy_manager.has_energy(energy_cost):
		return {
			"success": false,
			"error": "Not enough energy"
		}
	
	# Make API call
	var result = await Network.post_json(PVP_ENDPOINT + "/attack", {
		"target_player_id": target_player_id
	})
	
	if not result.success:
		return {
			"success": false,
			"error": result.get("error", "Attack failed")
		}
	
	# Consume energy
	energy_manager.consume_energy(energy_cost, "pvp_attack")
	
	# Process result
	var outcome_data = result.data
	var outcome = outcome_data.get("outcome", "draw")
	var gold_change = outcome_data.get("gold_change", 0)
	var reputation_change = outcome_data.get("reputation_change", 0)
	
	# Update local state
	if gold_change != 0:
		State.update_gold(gold_change, true)
	
	if reputation_change != 0:
		State.reputation += reputation_change
		reputation_changed.emit(State.reputation)
	
	# Check if hospitalized
	if outcome_data.get("attacker_hospitalized", false):
		State.set_hospital_status(true, outcome_data.get("release_time", 0))
	
	# Play audio
	if outcome in ["major_win", "win"]:
		Audio.play_success()
	else:
		Audio.play_error()
	
	# Track telemetry
	Telemetry.track_pvp("attack", target_player_id, outcome, {
		"gold_change": gold_change,
		"reputation_change": reputation_change
	})
	
	attack_completed.emit(outcome_data)
	
	return outcome_data

## Calculate win chance (client-side preview)
func calculate_win_chance(attacker_power: int, defender_power: int) -> float:
	var config = Config.get_pvp_config()
	var base_chance = config.get("base_win_chance", 0.5)
	var power_factor = config.get("power_factor", 0.01)
	
	var power_diff = attacker_power - defender_power
	var win_chance = base_chance + (power_diff * power_factor)
	
	# Clamp between 5% and 95%
	win_chance = clamp(win_chance, 0.05, 0.95)
	
	return win_chance

## Get outcome description
func get_outcome_description(outcome: String) -> String:
	match outcome:
		"major_win":
			return "Crushing Victory! You dominated your opponent and looted significant gold."
		"win":
			return "Victory! You defeated your opponent and claimed some gold."
		"draw":
			return "Draw! The battle was evenly matched. No gold changed hands."
		"loss":
			return "Defeat! Your opponent bested you and took some gold."
		"major_loss":
			return "Crushing Defeat! You were thoroughly beaten and lost significant gold."
		_:
			return "Unknown outcome"

## Get reputation tier
func get_reputation_tier() -> Dictionary:
	var rep = State.reputation
	
	if rep >= 1000:
		return {"name": "Legendary", "color": Color.GOLD}
	elif rep >= 500:
		return {"name": "Champion", "color": Color.PURPLE}
	elif rep >= 200:
		return {"name": "Warrior", "color": Color.BLUE}
	elif rep >= 50:
		return {"name": "Fighter", "color": Color.GREEN}
	elif rep >= 0:
		return {"name": "Novice", "color": Color.WHITE}
	elif rep >= -50:
		return {"name": "Outlaw", "color": Color.ORANGE}
	else:
		return {"name": "Villain", "color": Color.RED}

## Get PvP cooldown remaining
func get_cooldown_remaining(last_attack_time: int) -> int:
	var config = Config.get_pvp_config()
	var cooldown = config.get("cooldown", 300)  # 5 minutes
	var current_time = Time.get_unix_time_from_system()
	var elapsed = current_time - last_attack_time
	var remaining = cooldown - elapsed
	return max(0, remaining)

## Check if can attack
func can_attack(last_attack_time: int) -> bool:
	return get_cooldown_remaining(last_attack_time) == 0

## Get cooldown formatted
func get_cooldown_formatted(last_attack_time: int) -> String:
	var seconds = get_cooldown_remaining(last_attack_time)
	var minutes = int(seconds / 60)
	var secs = seconds % 60
	return "%02d:%02d" % [minutes, secs]

## Get PvP history
func fetch_pvp_history(limit: int = 20) -> Dictionary:
	var result = await Network.http_get(PVP_ENDPOINT + "/history?limit=%d" % limit)
	
	if result.success and result.data.has("battles"):
		State.pvp_history = result.data.battles
		return {"success": true, "battles": result.data.battles}
	
	return {"success": false, "error": result.get("error", "Failed to fetch history")}

## Get leaderboard
func fetch_leaderboard(limit: int = 50) -> Dictionary:
	var result = await Network.http_get(PVP_ENDPOINT + "/leaderboard?limit=%d" % limit)
	
	if result.success and result.data.has("leaderboard"):
		return {"success": true, "leaderboard": result.data.leaderboard}
	
	return {"success": false, "error": result.get("error", "Failed to fetch leaderboard")}
