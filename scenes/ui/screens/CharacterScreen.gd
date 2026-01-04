extends Control
## Character Screen
## Displays detailed character information, stats, and equipment

@onready var character_name_label: Label = %CharacterNameLabel
@onready var level_label: Label = %LevelLabel
@onready var exp_label: Label = %ExpLabel
@onready var exp_bar: ProgressBar = %ExpBar

# Stats
@onready var health_label: Label = %HealthLabel
@onready var attack_label: Label = %AttackLabel
@onready var defense_label: Label = %DefenseLabel
@onready var luck_label: Label = %LuckLabel

# Resources
@onready var gold_label: Label = %GoldLabel
@onready var energy_label: Label = %EnergyLabel
@onready var tolerance_label: Label = %ToleranceLabel

# Equipment
@onready var equipment_container: VBoxContainer = %EquipmentContainer

# Buttons
@onready var stats_button: Button = %StatsButton
@onready var skills_button: Button = %SkillsButton
@onready var achievements_button: Button = %AchievementsButton

var current_player_data: Dictionary = {}

func _ready() -> void:
	# Connect signals
	State.player_updated.connect(_update_character_info)
	
	# Connect buttons
	stats_button.pressed.connect(_on_stats_pressed)
	skills_button.pressed.connect(_on_skills_pressed)
	achievements_button.pressed.connect(_on_achievements_pressed)
	
	# Load character data
	_load_character_data()

func _load_character_data() -> void:
	var player_id = Session.player_id
	if not player_id:
		push_error("No player ID found")
		return
	
	# Use canonical API endpoint for player profile (server may expose /api/v1/player/profile)
	var result = await Network.http_get(APIEndpoints.PLAYER_PROFILE)
	# Fallback: try search endpoint if profile endpoint does not return data
	if not result or not result.get("success", false) or not result.get("data", null):
		var search_endpoint = APIEndpoints.PLAYER_SEARCH + "?id=eq.%s" % str(player_id)
		result = await Network.http_get(search_endpoint)
	_on_character_data_loaded(result)

func _on_character_data_loaded(result: Dictionary) -> void:
	if not result.success:
		push_error("Failed to load character: " + str(result.get("error", "Unknown")))
		return
	
	current_player_data = result.data
	_update_character_info()

func _update_character_info() -> void:
	var player = State.get_player_data()
	if player.is_empty():
		player = current_player_data
	
	if player.is_empty():
		return
	
	# Basic info
	character_name_label.text = player.get("username", "Oyuncu")
	level_label.text = "Seviye " + str(player.get("level", 1))
	
	# Experience
	var current_exp = player.get("experience", 0)
	var next_level_exp = _calculate_exp_for_level(player.get("level", 1) + 1)
	exp_label.text = str(current_exp) + " / " + str(next_level_exp) + " EXP"
	exp_bar.max_value = next_level_exp
	exp_bar.value = current_exp
	
	# Stats
	var stats = player.get("stats", {})
	health_label.text = "Can: " + str(stats.get("health", 100))
	attack_label.text = "Saldırı: " + str(stats.get("attack", 10))
	defense_label.text = "Savunma: " + str(stats.get("defense", 10))
	luck_label.text = "Şans: " + str(stats.get("luck", 5))
	
	# Resources
	gold_label.text = str(player.get("gold", 0)) + " Altın"
	energy_label.text = str(State.current_energy) + " / " + str(State.max_energy) + " Enerji"
	
	var tolerance = player.get("tolerance", 100)
	tolerance_label.text = str(tolerance) + " / 100 Tolerans"
	
	# Equipment
	_update_equipment(player.get("equipment", {}))

func _calculate_exp_for_level(level: int) -> int:
	return int(100 * pow(level, 1.5))

func _update_equipment(equipment: Dictionary) -> void:
	# Clear existing
	for child in equipment_container.get_children():
		child.queue_free()
	
	# Add equipment slots
	var slots = ["Silah", "Zırh", "Kask", "Eldiven", "Ayakkabı", "Aksesuar"]
	for slot in slots:
		var item_card = _create_equipment_slot(slot, equipment.get(slot.to_lower(), null))
		equipment_container.add_child(item_card)

func _create_equipment_slot(slot_name: String, item: Variant) -> PanelContainer:
	var panel = PanelContainer.new()
	var hbox = HBoxContainer.new()
	panel.add_child(hbox)
	
	var slot_label = Label.new()
	slot_label.text = slot_name + ":"
	slot_label.custom_minimum_size = Vector2(150, 0)
	slot_label.add_theme_font_size_override("font_size", 20)
	hbox.add_child(slot_label)
	
	var item_label = Label.new()
	if item:
		item_label.text = str(item.get("name", "Bilinmeyen"))
	else:
		item_label.text = "Boş"
		item_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	item_label.add_theme_font_size_override("font_size", 20)
	hbox.add_child(item_label)
	
	return panel

func _on_stats_pressed() -> void:
	# Show detailed stats screen
	pass

func _on_skills_pressed() -> void:
	# Show skills/abilities screen
	pass

func _on_achievements_pressed() -> void:
	# Show achievements screen
	pass
