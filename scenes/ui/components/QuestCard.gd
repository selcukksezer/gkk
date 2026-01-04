extends PanelContainer
## Quest Card Component
## Displays quest information in a card format

signal quest_selected(quest: QuestData)
signal start_quest_pressed(quest: QuestData)

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var description_label: Label = $MarginContainer/VBoxContainer/DescriptionLabel
@onready var difficulty_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/DifficultyLabel
@onready var energy_cost_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/EnergyCostLabel
@onready var reward_label: Label = $MarginContainer/VBoxContainer/RewardLabel
@onready var progress_bar: ProgressBar = $MarginContainer/VBoxContainer/ProgressBar
@onready var time_remaining_label: Label = $MarginContainer/VBoxContainer/TimeRemainingLabel
@onready var start_button: Button = $MarginContainer/VBoxContainer/StartButton

var quest: QuestData = QuestData.new()

func _ready() -> void:
	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)

func setup(quest_data: QuestData) -> void:
	quest = quest_data
	_update_display()

func _update_display() -> void:
	if not quest:
		return
	
	# Title
	if title_label:
		title_label.text = quest.name
		title_label.add_theme_color_override("font_color", _get_difficulty_color(quest.difficulty))
	
	# Description
	if description_label:
		description_label.text = quest.description
	
	# Difficulty
	if difficulty_label:
		var difficulty_text = QuestData.QuestDifficulty.keys()[quest.difficulty]
		difficulty_label.text = "⭐ " + difficulty_text
		difficulty_label.add_theme_color_override("font_color", _get_difficulty_color(quest.difficulty))
	
	# Energy cost
	if energy_cost_label:
		energy_cost_label.text = "⚡ %d" % quest.energy_cost
		
		# Red if not enough energy
		if State.current_energy < quest.energy_cost:
			energy_cost_label.add_theme_color_override("font_color", Color.RED)
		else:
			energy_cost_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Rewards
	if reward_label:
		var rewards = []
		if quest.gold_reward > 0:
			rewards.append("💰 %s" % MathUtils.format_number_short(quest.gold_reward))
		if quest.xp_reward > 0:
			rewards.append("✨ %s XP" % MathUtils.format_number_short(quest.xp_reward))
		
		reward_label.text = " | ".join(rewards)
	
	# Progress (only for active quests)
	var is_active = quest.status == QuestData.QuestStatus.ACTIVE
	
	if progress_bar:
		progress_bar.visible = is_active
		if is_active and quest.objectives.size() > 0:
			var total_progress = 0.0
			for objective in quest.objectives:
				total_progress += objective.get("progress", 0.0)
			
			var avg_progress = total_progress / quest.objectives.size()
			progress_bar.value = avg_progress * 100
	
	# Time remaining (only for time-limited quests)
	if time_remaining_label:
		if quest.time_limit_seconds > 0 and is_active:
			var remaining = quest.get_remaining_time()
			time_remaining_label.visible = true
			time_remaining_label.text = "⏱️ " + DateTimeUtils.format_duration(remaining)
			
			# Red if running out
			if remaining < 300:  # Less than 5 minutes
				time_remaining_label.add_theme_color_override("font_color", Color.RED)
			else:
				time_remaining_label.add_theme_color_override("font_color", Color.WHITE)
		else:
			time_remaining_label.visible = false
	
	# Start button
	if start_button:
		match quest.status:
			QuestData.QuestStatus.AVAILABLE:
				start_button.visible = true
				start_button.text = "Başlat"
				start_button.disabled = not quest.is_available(State.player.get("level", 1)) or State.current_energy < quest.energy_cost
			QuestData.QuestStatus.ACTIVE:
				start_button.visible = true
				start_button.text = "Devam Et"
				start_button.disabled = false
			QuestData.QuestStatus.COMPLETED:
				start_button.visible = true
				start_button.text = "Tamamla"
				start_button.disabled = false
			_:
				start_button.visible = false

func _get_difficulty_color(difficulty: QuestData.QuestDifficulty) -> Color:
	match difficulty:
		QuestData.QuestDifficulty.EASY:
			return Color.GREEN
		QuestData.QuestDifficulty.MEDIUM:
			return Color.YELLOW
		QuestData.QuestDifficulty.HARD:
			return Color.ORANGE
		QuestData.QuestDifficulty.DUNGEON:
			return Color.RED
		_:
			return Color.WHITE

func _on_start_button_pressed() -> void:
	start_quest_pressed.emit(quest)

## Show detailed quest info
func show_details() -> void:
	if not quest:
		return
	
	var details = """
	%s
	
	%s
	
	Zorluk: %s
	Enerji: %d
	""" % [
		quest.name,
		quest.description,
		QuestData.QuestDifficulty.keys()[quest.difficulty],
		quest.energy_cost
	]
	
	# Objectives
	if quest.objectives.size() > 0:
		details += "\n\nHedefler:"
		for objective in quest.objectives:
			var progress = objective.get("progress", 0.0)
			var required = objective.get("required", 1.0)
			details += "\n• %s (%d/%d)" % [
				objective.get("description", ""),
				int(progress),
				int(required)
			]
	
	# Rewards
	details += "\n\nÖdüller:"
	if quest.gold_reward > 0:
		details += "\n💰 %s Altın" % MathUtils.format_number(quest.gold_reward)
	if quest.xp_reward > 0:
		details += "\n✨ %s XP" % MathUtils.format_number(quest.xp_reward)
	if quest.item_rewards.size() > 0:
		for item_id in quest.item_rewards:
			details += "\n🎁 %s" % item_id
	
	# Requirements
	if quest.required_level > 1:
		details += "\n\nGerekli Seviye: %d" % quest.required_level
	
	# Show dialog
	var dialog_scene = load("res://scenes/ui/dialogs/InfoDialog.tscn")
	if dialog_scene:
		get_tree().root.get_node("Main").show_dialog(dialog_scene, {
			"title": "Görev Detayı",
			"message": details
		})
