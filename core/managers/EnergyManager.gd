class_name EnergyManager
extends RefCounted
## Energy System Manager
## Handles energy regeneration, consumption, and validation

## Energy regen callback
signal energy_regenerated(amount: int)

var _regen_timer: Timer
var _last_regen_time: int = 0

## Initialize energy system
func initialize(parent_node: Node) -> void:
	# Create regen timer
	_regen_timer = Timer.new()
	_regen_timer.wait_time = _get_regen_interval()
	_regen_timer.timeout.connect(_on_regen_tick)
	parent_node.add_child(_regen_timer)
	
	_last_regen_time = int(Time.get_unix_time_from_system())
	_regen_timer.start()
	
	print("[EnergyManager] Initialized with interval: %d seconds" % _get_regen_interval())

## Get regen interval from config
func _get_regen_interval() -> int:
	return Config.get_energy_config().get("regen_interval", 180)  # 3 minutes

## Get regen rate from config
func _get_regen_rate() -> int:
	return Config.get_energy_config().get("regen_rate", 1)  # 1 energy per interval

## Get max energy from config
func get_max_energy() -> int:
	return Config.get_energy_config().get("max_energy", 100)

## Check if player has enough energy
func has_energy(amount: int) -> bool:
	return State.current_energy >= amount

## Consume energy (returns true if successful)
func consume_energy(amount: int, reason: String = "") -> bool:
	if not has_energy(amount):
		print("[EnergyManager] Not enough energy: %d/%d" % [State.current_energy, amount])
		return false
	
	State.update_energy(State.current_energy - amount)
	
	print("[EnergyManager] Consumed %d energy. Remaining: %d" % [amount, State.current_energy])
	
	# Track telemetry
	Telemetry.track_event("energy_consumed", {
		"amount": amount,
		"reason": reason,
		"remaining": State.current_energy
	})
	
	return true

## Add energy (from refill, reward, etc)
func add_energy(amount: int, reason: String = "") -> void:
	var new_energy = min(State.current_energy + amount, State.max_energy)
	State.update_energy(new_energy)
	
	print("[EnergyManager] Added %d energy. Current: %d" % [amount, State.current_energy])
	
	# Track telemetry
	Telemetry.track_event("energy_added", {
		"amount": amount,
		"reason": reason,
		"current": State.current_energy
	})

## Refill energy to max (with gems)
func refill_energy() -> bool:
	var cost = Config.get_monetization_config().get("energy_refill_gem_cost", 50)
	
	# Check if player has gems (假设有gem系统)
	# TODO: Add gem check when currency system is implemented
	
	State.update_energy(State.max_energy)
	
	print("[EnergyManager] Energy refilled to max")
	
	Telemetry.track_event("energy_refill", {
		"cost": cost,
		"method": "gems"
	})
	
	return true

## Calculate energy regeneration from last login
func calculate_offline_regen(last_login_timestamp: int) -> int:
	var current_time = Time.get_unix_time_from_system()
	var elapsed = current_time - last_login_timestamp
	var interval = _get_regen_interval()
	var regen_rate = _get_regen_rate()
	
	# Calculate how many intervals passed
	var intervals = int(elapsed / interval)
	var total_regen = intervals * regen_rate
	
	print("[EnergyManager] Offline regen: %d intervals, %d energy" % [intervals, total_regen])
	
	return total_regen

## Apply offline regen on login
func apply_offline_regen(last_login_timestamp: int) -> void:
	var regen_amount = calculate_offline_regen(last_login_timestamp)
	
	if regen_amount > 0:
		add_energy(regen_amount, "offline_regen")

## Energy regen tick
func _on_regen_tick() -> void:
	if State.current_energy >= State.max_energy:
		return  # Already at max
	
	var regen_rate = _get_regen_rate()
	add_energy(regen_rate, "natural_regen")
	energy_regenerated.emit(regen_rate)
	
	_last_regen_time = int(Time.get_unix_time_from_system())

## Get time until next regen (seconds)
func get_time_to_next_regen() -> int:
	var current_time = Time.get_unix_time_from_system()
	var interval = _get_regen_interval()
	var elapsed = current_time - _last_regen_time
	var remaining = interval - elapsed
	return max(0, remaining)

## Get formatted time string (MM:SS)
func get_next_regen_time_formatted() -> String:
	var seconds = get_time_to_next_regen()
	var minutes = seconds / 60
	var secs = seconds % 60
	return "%02d:%02d" % [minutes, secs]

## Stop regen (on logout)
func stop_regen() -> void:
	if _regen_timer:
		_regen_timer.stop()

## Fetch energy status from server
func fetch_energy_status() -> Dictionary:
	if not Network:
		push_error("[EnergyManager] Network not available")
		return {"success": false, "error": "Network not available"}
	
	var endpoint = "/functions/v1/energy/status"
	var result = await Network.http_get(endpoint)
	
	if result and result.success and result.data:
		print("[EnergyManager] Energy status fetched: %s" % result.data)
		return {
			"success": true,
			"current_energy": result.data.get("current_energy", 100),
			"max_energy": result.data.get("max_energy", 100)
		}
	else:
		var error_msg = result.get("error", "Unknown error") if result else "Network error"
		push_error("[EnergyManager] Failed to fetch energy status: %s" % error_msg)
		return {"success": false, "error": error_msg}
