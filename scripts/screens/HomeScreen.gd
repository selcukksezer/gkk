extends Control
## Home Screen
## Main game screen showing player status and quick actions

@onready var player_info: PanelContainer = $ScrollContainer/VBoxContainer/PlayerInfoSection
@onready var energy_bar: ProgressBar = $ScrollContainer/VBoxContainer/EnergySection/MarginContainer/VBox/EnergyBar
@onready var tolerance_bar: ProgressBar = $ScrollContainer/VBoxContainer/ToleranceSection/MarginContainer/VBox/ToleranceBar
@onready var quick_actions: HBoxContainer = $ScrollContainer/VBoxContainer/QuickActionsSection
@onready var active_quests_container: VBoxContainer = $ScrollContainer/VBoxContainer/ActiveQuestsSection/VBox/QuestList
@onready var notifications_container: VBoxContainer = $ScrollContainer/VBoxContainer/NotificationsSection/VBox/NotificationList

# Labels
@onready var player_name_label: Label = $ScrollContainer/VBoxContainer/PlayerInfoSection/MarginContainer/VBox/PlayerName
@onready var level_label: Label = $ScrollContainer/VBoxContainer/PlayerInfoSection/MarginContainer/VBox/LevelLabel
@onready var gold_label: Label = $ScrollContainer/VBoxContainer/PlayerInfoSection/MarginContainer/VBox/GoldLabel
@onready var energy_label: Label = $ScrollContainer/VBoxContainer/EnergySection/MarginContainer/VBox/EnergyLabel
@onready var tolerance_label: Label = $ScrollContainer/VBoxContainer/ToleranceSection/MarginContainer/VBox/ToleranceLabel

# Quick action buttons
@onready var quest_button: Button = $ScrollContainer/VBoxContainer/QuickActionsSection/QuestButton
@onready var pvp_button: Button = $ScrollContainer/VBoxContainer/QuickActionsSection/PvPButton
@onready var market_button: Button = $ScrollContainer/VBoxContainer/QuickActionsSection/MarketButton
@onready var use_potion_button: Button = $ScrollContainer/VBoxContainer/QuickActionsSection/UsePotionButton

func _ready() -> void:
	# Connect signals
	State.player_updated.connect(_update_player_info)
	State.energy_updated.connect(_update_energy_display)
	State.tolerance_updated.connect(func(_v): _update_tolerance_display())
	State.state_changed.connect(_on_state_changed)
	
	# Connect buttons
	quest_button.pressed.connect(_on_quest_button_pressed)
	pvp_button.pressed.connect(_on_pvp_button_pressed)
	market_button.pressed.connect(_on_market_button_pressed)
	use_potion_button.pressed.connect(_on_use_potion_button_pressed)
	
	# Add a developer button to grant unlimited energy
	var unlimited_btn = Button.new()
	unlimited_btn.text = "Sınırsız Enerji"
	unlimited_btn.add_theme_font_size_override("font_size", 14)
	unlimited_btn.tooltip_text = "Tüm enerjinizi sınırsız yapar ve sunucuya kaydeder (geliştirme)"
	quick_actions.add_child(unlimited_btn)
	unlimited_btn.pressed.connect(_on_unlimited_energy_pressed)

	# Initial update
	_update_player_info()
	_update_energy_display()
	_update_tolerance_display()
	_load_active_quests()
	_load_notifications()

func _on_state_changed(key: String, _value: Variant) -> void:
	match key:
		"gold", "level", "xp":
			_update_player_info()
		"tolerance":
			_update_tolerance_display()

func _update_player_info() -> void:
	if not is_inside_tree(): return
	
	player_name_label.text = State.player.get("display_name", State.player.get("username", "Oyuncu"))
	level_label.text = "Seviye %d" % State.level
	gold_label.text = "%d Altın" % State.gold
	
	# Update bars too just in case
	_update_energy_display()
	_update_tolerance_display()

func _update_energy_display() -> void:
	if not is_inside_tree(): return
	
	energy_bar.max_value = State.max_energy
	energy_bar.value = State.current_energy
	energy_label.text = "%d / %d" % [State.current_energy, State.max_energy]
	
	# Check if energy is low
	if State.current_energy < 20:
		_show_energy_warning()

func _update_tolerance_display() -> void:
	if not is_inside_tree(): return
	
	tolerance_bar.max_value = 100
	tolerance_bar.value = State.tolerance
	tolerance_label.text = "%d / 100" % State.tolerance
	
	# Color coding for tolerance
	var style = tolerance_bar.get_theme_stylebox("fill")
	if style is StyleBoxFlat:
		if State.tolerance >= 80:
			style.bg_color = Color(0.8, 0.2, 0.2) # Red
		elif State.tolerance >= 50:
			style.bg_color = Color(0.8, 0.8, 0.2) # Yellow
		else:
			style.bg_color = Color(0.2, 0.8, 0.2) # Green

func _show_energy_warning() -> void:
	# Show warning if not already shown in this session
	# Using a flag in State instead of checking has()
	if State.player.get("_energy_warning_shown", false) == false:
		var dialog_scene = load("res://scenes/ui/dialogs/InfoDialog.tscn")
		if dialog_scene:
			get_tree().root.get_node("Main").show_dialog(dialog_scene, {
				"title": "Enerji Düşük",
				"message": "Enerjin azaldı! İksir kullanabilir veya bekleme yapabilirsin."
			})
		State.player["_energy_warning_shown"] = true

func _load_active_quests() -> void:
	# Clear existing
	for child in active_quests_container.get_children():
		child.queue_free()
	
	# TODO: Load active quests from QuestManager
	# For now, show placeholder
	var label = Label.new()
	label.text = "Aktif görev yok"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	active_quests_container.add_child(label)

func _load_notifications() -> void:
	# Clear existing
	for child in notifications_container.get_children():
		child.queue_free()
	
	# Check for hospital status
	var hospital_until_val = null
	if typeof(State.player) == TYPE_DICTIONARY:
		hospital_until_val = State.player.get("hospital_until", null)
	var hospital_until_ts = 0
	if hospital_until_val != null:
		# Can be numeric timestamp or ISO string; try to handle numeric first
		if typeof(hospital_until_val) == TYPE_INT or typeof(hospital_until_val) == TYPE_FLOAT:
			hospital_until_ts = int(hospital_until_val)
		elif typeof(hospital_until_val) == TYPE_STRING:
			# Try to parse datetime string to timestamp
			var dt = Time.get_datetime_dict_from_datetime_string(hospital_until_val, false)
			if dt.has("year"):
				hospital_until_ts = Time.get_unix_time_from_datetime_dict(dt)
	
	if hospital_until_ts > Time.get_unix_time_from_system():
		_add_notification("🏥 Hastanedesin", "Çıkış: %s" % DateTimeUtils.format_timestamp(hospital_until_ts))
	
	# Check for low energy
	if State.current_energy < State.max_energy * 0.3:
		_add_notification("⚡ Enerji Düşük", "%d/%d enerji kaldı" % [State.current_energy, State.max_energy])
	
	# Check for high tolerance
	if State.tolerance >= 60:
		_add_notification("⚠️ Yüksek Tolerans", "Bağımlılık riski: %%%d" % State.tolerance)
	
	# If no notifications
	if notifications_container.get_child_count() == 0:
		var label = Label.new()
		label.text = "Bildirim yok"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		notifications_container.add_child(label)

func _add_notification(title: String, message: String) -> void:
	var notification_panel = PanelContainer.new()
	var vbox = VBoxContainer.new()
	
	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title_label)
	
	var message_label = Label.new()
	message_label.text = message
	message_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(message_label)
	
	notification_panel.add_child(vbox)
	notifications_container.add_child(notification_panel)

## Button handlers
func _on_quest_button_pressed() -> void:
	get_tree().root.get_node("Main").show_screen("quest")

func _on_pvp_button_pressed() -> void:
	# Check if in hospital
	if State.player.hospital_until > Time.get_unix_time_from_system():
		_show_error("Hastanedeyken PvP yapamazsın!")
		return
	
	# Check energy
	var pvp_energy_cost = GameConfig.get_config("pvp", "energy_cost", 15)
	if State.current_energy < pvp_energy_cost:
		_show_error("Yeterli enerji yok! (Gerekli: %d)" % pvp_energy_cost)
		return
	
	get_tree().root.get_node("Main").show_screen("pvp")

func _on_market_button_pressed() -> void:
	get_tree().root.get_node("Main").show_screen("market")

func _on_use_potion_button_pressed() -> void:
	# Show potion use dialog
	var dialog_scene = load("res://scenes/ui/dialogs/PotionUseDialog.tscn")
	if dialog_scene:
		get_tree().root.get_node("Main").show_dialog(dialog_scene)

func _on_unlimited_energy_pressed() -> void:
	# Grant effectively infinite energy for now and persist
	var unlimited = 999999
	State.update_player_data({"energy": unlimited, "max_energy": unlimited})
	_update_energy_display()
	_add_notification("✅ Sınırsız Enerji", "Enerjin sınırsız yapıldı ve sunucuya kaydedildi.")
	print("[HomeScreen] Unlimited energy granted: %d" % unlimited)

func _show_error(message: String) -> void:
	var dialog_scene = load("res://scenes/ui/dialogs/ErrorDialog.tscn")
	if dialog_scene:
		get_tree().root.get_node("Main").show_dialog(dialog_scene, {
			"title": "Hata",
			"message": message
		})

## Refresh data
func refresh() -> void:
	_update_player_info()
	_load_active_quests()
	_load_notifications()
