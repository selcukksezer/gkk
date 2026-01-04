extends Control
## PvP Screen
## Player vs Player combat interface

@onready var target_search = $TopPanel/TargetSearch
@onready var search_button = $TopPanel/SearchButton
@onready var random_button = $TopPanel/RandomButton

@onready var target_list = $TargetList/ScrollContainer/VBoxContainer
@onready var target_details = $TargetDetailsPanel
@onready var target_username = $TargetDetailsPanel/Username
@onready var target_level = $TargetDetailsPanel/Level
@onready var target_power = $TargetDetailsPanel/Power
@onready var target_defense = $TargetDetailsPanel/Defense
@onready var target_gold = $TargetDetailsPanel/Gold
@onready var win_chance = $TargetDetailsPanel/WinChance

@onready var attack_button = $AttackButton
@onready var back_button = $BackButton

@onready var result_popup = $ResultPopup
@onready var result_outcome = $ResultPopup/Outcome
@onready var result_gold = $ResultPopup/GoldChange
@onready var result_rating = $ResultPopup/RatingChange
@onready var result_close = $ResultPopup/CloseButton

var _selected_target: Dictionary = {}
var _target_card_scene = preload("res://scenes/prefabs/PvPTargetCard.tscn")

func _ready() -> void:
	# Connect signals
	search_button.pressed.connect(_on_search_pressed)
	random_button.pressed.connect(_on_random_pressed)
	attack_button.pressed.connect(_on_attack_pressed)
	back_button.pressed.connect(_on_back_pressed)
	result_close.pressed.connect(_on_result_close)
	
	# Track screen
	Telemetry.track_screen("pvp")
	
	# Load random targets
	_load_targets()

func _load_targets(username: String = "") -> void:
	var endpoint = "/pvp/targets"
	if not username.is_empty():
		endpoint += "?username=" + username
	
	var result = await Network.http_get(endpoint)
	_on_targets_loaded(result)

func _on_targets_loaded(result: Dictionary) -> void:
	if not result.success:
		print("[PvP] Failed to load targets")
		return
	
	# Clear list
	for child in target_list.get_children():
		child.queue_free()
	
	# Populate target list
	var targets = result.data.get("targets", [])
	for target_dict in targets:
		var card = _target_card_scene.instantiate()
		target_list.add_child(card)
		card.set_target(target_dict)
		card.clicked.connect(_on_target_selected.bind(target_dict))

func _on_search_pressed() -> void:
	var search_text = target_search.text.strip_edges()
	if search_text.is_empty():
		return
	
	_load_targets(search_text)
	Telemetry.track_event("pvp", "search", {"username": search_text})

func _on_random_pressed() -> void:
	_load_targets()
	Telemetry.track_event("pvp", "random_targets", {})

func _on_target_selected(target: Dictionary) -> void:
	_selected_target = target
	_show_target_details(target)

func _show_target_details(target: Dictionary) -> void:
	target_details.visible = true
	
	target_username.text = target.get("username", "Unknown")
	target_level.text = "Lv. %d" % target.get("level", 1)
	target_power.text = "Power: %d" % target.get("power", 0)
	target_defense.text = "Defense: %d" % target.get("defense", 0)
	target_gold.text = "Gold: %d" % target.get("gold", 0)
	
	# Calculate win chance
	var my_power = State.calculate_total_power()
	var their_defense = target.get("defense", 0)
	var power_diff = my_power - their_defense
	
	var chance = _calculate_win_chance(power_diff)
	win_chance.text = "Win Chance: %d%%" % chance
	
	# Enable attack button
	attack_button.disabled = false

func _calculate_win_chance(power_diff: int) -> int:
	# Based on power difference
	# -200+ = 5%, -100 = 25%, 0 = 50%, +100 = 75%, +200+ = 95%
	var base_chance = 50
	var modifier = power_diff * 0.25  # 0.25% per power point
	var chance = clamp(base_chance + modifier, 5, 95)
	return int(chance)

func _on_attack_pressed() -> void:
	if _selected_target.is_empty():
		return
	
	# Check energy
	var pvp_config = Config.get_pvp_config()
	var energy_cost = pvp_config.get("energy_cost", 20)
	
	if State.current_energy < energy_cost:
		print("[PvP] Insufficient energy")
		return
	
	# Check cooldown
	if not _can_attack():
		print("[PvP] PvP on cooldown")
		return
	
	var target_id = _selected_target.get("id", "")
	var my_power = State.calculate_total_power()
	var their_defense = _selected_target.get("defense", 0)
	
	var body = {
		"target_user_id": target_id
	}
	
	# Track initiation
	Telemetry.track_pvp_initiated(target_id, my_power - their_defense)
	
	var result = await Network.http_post("/pvp/attack", body)
	_on_attack_result(result)
	
	# Disable button during request
	attack_button.disabled = true

func _can_attack() -> bool:
	# TODO: Check last_pvp_at timestamp
	return true

func _on_attack_result(result: Dictionary) -> void:
	attack_button.disabled = false
	
	if not result.success:
		print("[PvP] Attack failed: ", result.get("error", ""))
		return
	
	var data = result.data
	var outcome = data.get("outcome", "")
	var gold_change = data.get("gold_change", 0)
	var rating_change = data.get("rating_change", 0)
	
	# Update state
	State.current_energy = data.get("energy", State.current_energy)
	State.gold += gold_change
	State.pvp_rating += rating_change
	
	if outcome == "win":
		State.pvp_wins += 1
	else:
		State.pvp_losses += 1
	
	# Check hospital
	if outcome == "severe_loss":
		State.hospital_until = data.get("hospital_until", "")
	
	# Track completion
	Telemetry.track_pvp_completed(
		_selected_target.get("id", ""),
		outcome,
		gold_change
	)
	
	# Show result popup
	_show_result_popup(outcome, gold_change, rating_change)

func _show_result_popup(outcome: String, gold_change: int, rating_change: int) -> void:
	result_popup.visible = true
	
	# Outcome text and color
	var outcome_text = ""
	var outcome_color = Color.WHITE
	
	match outcome:
		"critical_win":
			outcome_text = "CRITICAL WIN! 🎉"
			outcome_color = Color.GOLD
		"win":
			outcome_text = "Victory!"
			outcome_color = Color.GREEN
		"draw":
			outcome_text = "Draw"
			outcome_color = Color.YELLOW
		"loss":
			outcome_text = "Defeat"
			outcome_color = Color.ORANGE
		"severe_loss":
			outcome_text = "SEVERE LOSS - Hospital!"
			outcome_color = Color.RED
	
	result_outcome.text = outcome_text
	result_outcome.add_theme_color_override("font_color", outcome_color)
	
	# Gold change
	var gold_text = ""
	if gold_change > 0:
		gold_text = "+%d Gold" % gold_change
	elif gold_change < 0:
		gold_text = "%d Gold" % gold_change
	else:
		gold_text = "No Gold Change"
	result_gold.text = gold_text
	
	# Rating change
	var rating_text = ""
	if rating_change > 0:
		rating_text = "+%d Rating" % rating_change
	elif rating_change < 0:
		rating_text = "%d Rating" % rating_change
	else:
		rating_text = "No Rating Change"
	result_rating.text = rating_text

func _on_result_close() -> void:
	result_popup.visible = false
	
	# Check if hospitalized
	if not State.hospital_until.is_empty():
		# Go to hospital screen
		Scenes.change_scene("res://scenes/ui/HospitalScreen.tscn")

func _on_back_pressed() -> void:
	Scenes.change_scene("res://scenes/ui/MainMenu.tscn")
