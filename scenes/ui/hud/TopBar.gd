extends Control
## Top Bar HUD
## Displays energy, gold, gems, and player info

@onready var energy_bar: ProgressBar = $HBoxContainer/EnergySection/EnergyBar
@onready var energy_label: Label = $HBoxContainer/EnergySection/EnergyLabel
@onready var gold_label: Label = $HBoxContainer/ResourceSection/GoldLabel
@onready var gem_label: Label = $HBoxContainer/ResourceSection/GemLabel
@onready var level_label: Label = $HBoxContainer/PlayerSection/LevelLabel
@onready var avatar_texture: TextureRect = $HBoxContainer/PlayerSection/Avatar

func _ready() -> void:
	# Connect state signals
	State.energy_updated.connect(_on_energy_updated)
	State.player_updated.connect(_on_player_updated)
	
	# Initial update
	_update_display()

func _update_display() -> void:
	_update_energy()
	_update_resources()
	_update_player_info()

func _update_energy() -> void:
	if energy_bar:
		energy_bar.max_value = State.max_energy
		energy_bar.value = State.current_energy
	
	if energy_label:
		energy_label.text = "%d/%d" % [State.current_energy, State.max_energy]
		
		# Color based on energy level
		var ratio = float(State.current_energy) / float(State.max_energy)
		if ratio > 0.5:
			energy_label.add_theme_color_override("font_color", Color.GREEN)
		elif ratio > 0.25:
			energy_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			energy_label.add_theme_color_override("font_color", Color.RED)

func _update_resources() -> void:
	if gold_label:
		gold_label.text = MathUtils.format_number(State.gold)
	
	if gem_label:
		gem_label.text = str(State.player.gems)

func _update_player_info() -> void:
	if level_label:
		level_label.text = "Lv.%d" % State.level
	
	# Avatar will be updated when we have avatar system
	# For now, just show a placeholder

## Button handlers
func _on_energy_pressed() -> void:
	# Fetch fresh energy data from server
	_fetch_energy_from_server()
	
	# Show energy info dialog
	var dialog_scene = load("res://scenes/ui/dialogs/EnergyInfoDialog.tscn")
	if dialog_scene:
		get_tree().root.get_node("Main").show_dialog(dialog_scene)

func _fetch_energy_from_server() -> void:
	print("[TopBar] Fetching energy from server...")
	var energy_mgr = EnergyManager.new()
	var result = await energy_mgr.fetch_energy_status()
	
	if result.success:
		# Update State with fresh data
		State.update_player_data({
			"energy": result.current_energy,
			"max_energy": result.max_energy
		})
		print("[TopBar] Energy updated from server: %d/%d" % [result.current_energy, result.max_energy])
	else:
		print("[TopBar] Failed to fetch energy: %s" % result.get("error", "Unknown error"))

func _on_gold_pressed() -> void:
	# Navigate to shop or show gold info
	pass

func _on_gem_pressed() -> void:
	# Navigate to shop
	pass

func _on_profile_pressed() -> void:
	# Navigate to profile screen
	get_tree().root.get_node("Main").show_screen("profile")

## Signal handlers
func _on_energy_updated() -> void:
	_update_energy()

func _on_player_updated() -> void:
	_update_resources()
	_update_player_info()
