extends Control
## Achievement Screen
## Başarımlar ve ödüller

@onready var achievement_list: VBoxContainer = %AchievementList
@onready var progress_label: Label = %ProgressLabel
@onready var back_button: Button = $MarginContainer/VBox/Header/BackButton

var achievements: Array[Dictionary] = []

func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
	_load_achievements()
	print("[AchievementScreen] Ready")

func _load_achievements() -> void:
	var result = await Network.http_get("/v1/achievements")
	if result.success:
		achievements = result.data.get("achievements", [])
		var completed = result.data.get("completed_count", 0)
		var total = achievements.size()
		progress_label.text = "%d/%d" % [completed, total]
		_populate_list()

func _populate_list() -> void:
	for child in achievement_list.get_children():
		child.queue_free()
	
	for ach in achievements:
		var panel = PanelContainer.new()
		var hbox = HBoxContainer.new()
		panel.add_child(hbox)
		
		# Icon
		var icon_label = Label.new()
		icon_label.text = ach.get("icon", "🏅")
		icon_label.theme_override_font_sizes["font_size"] = 48
		hbox.add_child(icon_label)
		
		# Info
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info_vbox)
		
		var name_label = Label.new()
		name_label.text = ach.get("name", "Bilinmeyen")
		name_label.theme_override_font_sizes["font_size"] = 24
		info_vbox.add_child(name_label)
		
		var desc_label = Label.new()
		desc_label.text = ach.get("description", "")
		desc_label.theme_override_font_sizes["font_size"] = 18
		info_vbox.add_child(desc_label)
		
		# Progress
		if not ach.get("completed", false):
			var progress_bar = ProgressBar.new()
			progress_bar.value = (float(ach.get("current", 0)) / ach.get("target", 1)) * 100
			info_vbox.add_child(progress_bar)
		
		# Reward
		var reward_label = Label.new()
		reward_label.text = "Ödül: %s" % ach.get("reward_text", "")
		reward_label.theme_override_font_sizes["font_size"] = 18
		reward_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
		info_vbox.add_child(reward_label)
		
		# Claim button
		if ach.get("completed", false) and not ach.get("claimed", false):
			var claim_button = Button.new()
			claim_button.text = "Al"
			claim_button.custom_minimum_size = Vector2(150, 60)
			claim_button.pressed.connect(func(): _claim_achievement(ach))
			hbox.add_child(claim_button)
		
		achievement_list.add_child(panel)

func _claim_achievement(ach: Dictionary) -> void:
	var result = await Network.http_post("/v1/achievements/claim", {"achievement_id": ach.get("id")})
	if result.success:
		_load_achievements()

func _on_back_button_pressed() -> void:
	get_tree().root.get_node("Main").go_back()
