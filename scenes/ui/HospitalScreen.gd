extends Control
## Hospital Screen
## Shows hospital status and early release option

@onready var status_label = $StatusPanel/StatusLabel
@onready var countdown_label = $StatusPanel/CountdownLabel
@onready var reason_label = $StatusPanel/ReasonLabel

@onready var early_release_panel = $EarlyReleasePanel
@onready var gem_cost_label = $EarlyReleasePanel/GemCostLabel
@onready var pay_button = $EarlyReleasePanel/PayButton

@onready var back_button = $BackButton

var _release_time: int = 0
var _countdown_timer: Timer

func _ready() -> void:
	# Connect signals
	pay_button.pressed.connect(_on_pay_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Create countdown timer
	_countdown_timer = Timer.new()
	add_child(_countdown_timer)
	_countdown_timer.timeout.connect(_update_countdown)
	_countdown_timer.wait_time = 1.0
	_countdown_timer.autostart = true
	
	# Track screen
	Telemetry.track_screen("hospital")
	
	# Check hospital status
	_check_hospital_status()

func _check_hospital_status() -> void:
	if State.hospital_until.is_empty():
		# Not hospitalized
		status_label.text = "You are not in hospital"
		early_release_panel.visible = false
		countdown_label.visible = false
		return
	
	# Parse release time
	_release_time = _parse_iso_timestamp(State.hospital_until)
	
	var current_time = Time.get_unix_time_from_system()
	
	if current_time >= _release_time:
		# Already released
		status_label.text = "You have been released!"
		early_release_panel.visible = false
		countdown_label.visible = false
		
		# Clear hospital status
		State.hospital_until = ""
		return
	
	# Still hospitalized
	status_label.text = "You are recovering in hospital"
	reason_label.text = "Reason: Severe PvP Loss"
	countdown_label.visible = true
	early_release_panel.visible = true
	
	# Calculate early release cost
	var time_remaining = _release_time - current_time
	var gem_cost = _calculate_early_release_cost(time_remaining)
	gem_cost_label.text = "Early Release: %d Gems" % gem_cost
	
	# Start countdown
	_countdown_timer.start()
	_update_countdown()

func _parse_iso_timestamp(iso_string: String) -> int:
	# Simple ISO 8601 parser
	# Format: "2024-01-15T10:30:00Z"
	var datetime = Time.get_datetime_dict_from_datetime_string(iso_string, true)
	return Time.get_unix_time_from_datetime_dict(datetime)

func _calculate_early_release_cost(seconds_remaining: int) -> int:
	# Cost formula: 1 gem per minute remaining (rounded up)
	var minutes_remaining = ceil(seconds_remaining / 60.0)
	return max(1, int(minutes_remaining))

func _update_countdown() -> void:
	var current_time = Time.get_unix_time_from_system()
	var time_remaining = _release_time - current_time
	
	if time_remaining <= 0:
		# Released!
		countdown_label.text = "Released!"
		_countdown_timer.stop()
		_check_hospital_status()
		return
	
	# Format time remaining
	var hours = int(time_remaining / 3600)
	var minutes = int((time_remaining % 3600) / 60)
	var seconds = int(time_remaining % 60)
	
	countdown_label.text = "Release in: %02d:%02d:%02d" % [hours, minutes, seconds]
	
	# Update gem cost
	var gem_cost = _calculate_early_release_cost(time_remaining)
	gem_cost_label.text = "Early Release: %d Gems" % gem_cost

func _on_pay_pressed() -> void:
	var current_time = Time.get_unix_time_from_system()
	var time_remaining = _release_time - current_time
	var gem_cost = _calculate_early_release_cost(time_remaining)
	
	# Check gems
	if State.gems < gem_cost:
		print("[Hospital] Insufficient gems")
		return
	
	var body = {
		"gem_cost": gem_cost
	}
	
	var result = await Network.http_post("/hospital/early_release", body)
	_on_early_released(result)
	
	Telemetry.track_gem_spent(gem_cost, "hospital_early_release")

func _on_early_released(result: Dictionary) -> void:
	if result.success:
		print("[Hospital] Early release successful")
		
		# Update state
		State.gems = result.data.get("gems", State.gems)
		State.hospital_until = ""
		
		# Refresh UI
		_check_hospital_status()
		
		# Show success message
		status_label.text = "Released early! Welcome back!"
	else:
		print("[Hospital] Early release failed: ", result.get("error", ""))

func _on_back_pressed() -> void:
	Scenes.change_scene("res://scenes/ui/MainMenu.tscn")
