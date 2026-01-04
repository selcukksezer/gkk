extends PanelContainer
## Quest Card

signal clicked(quest)

@onready var quest_name = $VBox/Name
@onready var difficulty_label = $VBox/Difficulty
@onready var rewards_label = $VBox/Rewards
@onready var status_label = $VBox/Status

var _quest: QuestData

func _ready() -> void:
	gui_input.connect(_on_gui_input)

func set_quest(quest: QuestData) -> void:
	_quest = quest
	
	quest_name.text = quest.name
	difficulty_label.text = "Difficulty: %s" % StringUtils.capitalize_first(QuestData.QuestDifficulty.keys()[quest.difficulty].to_lower())
	rewards_label.text = "Rewards: %d gold, %d XP" % [quest.gold_reward, quest.xp_reward]
	
	# Status indicator
	match quest.status:
		QuestData.QuestStatus.AVAILABLE:
			status_label.text = "Available"
			status_label.add_theme_color_override("font_color", Color.GREEN)
		QuestData.QuestStatus.ACTIVE:
			status_label.text = "In Progress"
			status_label.add_theme_color_override("font_color", Color.YELLOW)
		QuestData.QuestStatus.COMPLETED:
			status_label.text = "Completed"
			status_label.add_theme_color_override("font_color", Color.BLUE)
		_:
			status_label.text = "Unknown"
			status_label.add_theme_color_override("font_color", Color.WHITE)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit(_quest)
