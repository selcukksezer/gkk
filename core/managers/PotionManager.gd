class_name PotionManager
extends RefCounted
## Potion & Addiction System Manager
## Handles tolerance, overdose calculations, and potion consumption

signal tolerance_changed(new_value: int)
signal overdose_occurred(potion_data: Dictionary)

## Tolerance decay timer
var _decay_timer: Timer
const DECAY_CHECK_INTERVAL = 300.0  # 5 minutes (check frequently)

func initialize(parent_node: Node) -> void:
	# Create tolerance decay timer
	_decay_timer = Timer.new()
	_decay_timer.wait_time = DECAY_CHECK_INTERVAL
	_decay_timer.timeout.connect(_on_decay_tick)
	parent_node.add_child(_decay_timer)
	_decay_timer.start()
	
	print("[PotionManager] Initialized")

## Get tolerance decay rate from config (per 6 hours)
func _get_decay_rate() -> int:
	return Config.get_potion_config().get("tolerance_decay_rate", 1)

## Get overdose threshold from config
func _get_overdose_threshold() -> float:
	return Config.get_potion_config().get("overdose_threshold", 0.8)  # 80%

## Get max tolerance from config
func _get_max_tolerance() -> int:
	return Config.get_potion_config().get("max_tolerance", 100)

## Consume potion
func consume_potion(potion_data: Dictionary) -> Dictionary:
	"""
	Returns: {
		"success": bool,
		"overdose": bool,
		"energy_gained": int,
		"tolerance_gained": int,
		"message": String
	}
	"""
	
	var potion_id = potion_data.get("id", "")
	var base_energy = potion_data.get("energy_restore", 0)
	var tolerance_increase = potion_data.get("tolerance_increase", 0)
	var overdose_risk = potion_data.get("overdose_risk", 0.0)
	
	# Calculate effective energy based on tolerance
	var effective_energy = _calculate_effective_energy(base_energy, State.tolerance)
	
	# Check for overdose
	var overdose = _check_overdose(overdose_risk)
	
	if overdose:
		# Overdose occurred - send to hospital
		overdose_occurred.emit(potion_data)
		
		Telemetry.track_potion_usage(potion_id, "overdose", {
			"tolerance": State.tolerance,
			"base_energy": base_energy,
			"overdose_risk": overdose_risk
		})
		
		return {
			"success": false,
			"overdose": true,
			"energy_gained": 0,
			"tolerance_gained": 0,
			"message": "Overdose! You've been hospitalized."
		}
	
	# Successful consumption
	# Add energy
	var energy_manager = EnergyManager.new()
	energy_manager.add_energy(effective_energy, "potion_%s" % potion_id)
	
	# Increase tolerance
	var new_tolerance = min(State.tolerance + tolerance_increase, _get_max_tolerance())
	State.update_tolerance(new_tolerance)
	tolerance_changed.emit(new_tolerance)
	
	Audio.play_potion_drink()
	
	Telemetry.track_potion_usage(potion_id, "consumed", {
		"tolerance": State.tolerance,
		"base_energy": base_energy,
		"effective_energy": effective_energy,
		"tolerance_increase": tolerance_increase
	})
	
	print("[PotionManager] Consumed potion: %s, gained %d energy, tolerance: %d" % [potion_id, effective_energy, new_tolerance])
	
	return {
		"success": true,
		"overdose": false,
		"energy_gained": effective_energy,
		"tolerance_gained": tolerance_increase,
		"message": "Potion consumed successfully!"
	}

## Calculate effective energy based on tolerance
func _calculate_effective_energy(base_energy: int, tolerance: int) -> int:
	# Formula: effective = base * (1 - tolerance/max_tolerance * 0.5)
	# At 0 tolerance: 100% effectiveness
	# At max tolerance: 50% effectiveness
	var max_tolerance = _get_max_tolerance()
	var tolerance_factor = 1.0 - (float(tolerance) / max_tolerance) * 0.5
	var effective = int(base_energy * tolerance_factor)
	return max(1, effective)  # Minimum 1 energy

## Check for overdose
func _check_overdose(base_risk: float) -> bool:
	# Overdose risk increases with tolerance
	# Formula: final_risk = base_risk * (1 + tolerance/max_tolerance)
	var max_tolerance = _get_max_tolerance()
	var tolerance_multiplier = 1.0 + (float(State.tolerance) / max_tolerance)
	var final_risk = base_risk * tolerance_multiplier
	
	# Random check
	var roll = randf()
	var overdose = roll < final_risk
	
	print("[PotionManager] Overdose check: risk=%.2f, roll=%.2f, result=%s" % [final_risk, roll, "OVERDOSE" if overdose else "OK"])
	
	return overdose

## Calculate tolerance decay
func _calculate_tolerance_decay(elapsed_hours: float) -> int:
	# Decay rate per 6 hours
	var decay_rate = _get_decay_rate()
	var decay_amount = int(elapsed_hours / 6.0) * decay_rate
	return decay_amount

## Apply tolerance decay
func apply_tolerance_decay(elapsed_seconds: int) -> void:
	var elapsed_hours = elapsed_seconds / 3600.0
	var decay_amount = _calculate_tolerance_decay(elapsed_hours)
	
	if decay_amount > 0:
		var new_tolerance = max(0, State.tolerance - decay_amount)
		State.update_tolerance(new_tolerance)
		tolerance_changed.emit(new_tolerance)
		
		print("[PotionManager] Tolerance decayed by %d (%.1f hours elapsed)" % [decay_amount, elapsed_hours])

## Tolerance decay tick
func _on_decay_tick() -> void:
	# Check every 5 minutes, decay based on time passed
	# This is a simplified version - in production, you'd want to track last_decay_time
	pass  # Decay is handled through server sync

## Get tolerance percentage
func get_tolerance_percentage() -> float:
	return (float(State.tolerance) / _get_max_tolerance()) * 100.0

## Get tolerance tier (0-4)
func get_tolerance_tier() -> int:
	var pct = get_tolerance_percentage()
	if pct < 20:
		return 0  # Low
	elif pct < 40:
		return 1  # Moderate
	elif pct < 60:
		return 2  # High
	elif pct < 80:
		return 3  # Very High
	else:
		return 4  # Critical

## Get tolerance tier name
func get_tolerance_tier_name() -> String:
	match get_tolerance_tier():
		0: return "Low"
		1: return "Moderate"
		2: return "High"
		3: return "Very High"
		4: return "Critical"
		_: return "Unknown"

## Get effectiveness at current tolerance
func get_current_effectiveness_percentage() -> float:
	var max_tolerance = _get_max_tolerance()
	var factor = 1.0 - (float(State.tolerance) / max_tolerance) * 0.5
	return factor * 100.0

## Stop decay timer
func stop_decay() -> void:
	if _decay_timer:
		_decay_timer.stop()
