extends Control
## Quest list and quest initiation screen
## Shows available and active quests with start functionality

@onready var quest_list: VBoxContainer = %QuestList
@onready var quest_details: Panel = %QuestDetails
@onready var active_quests_label: Label = %ActiveQuestsLabel
@onready var quest_filter: OptionButton = %QuestFilter

var quest_manager: Node
var selected_quest: Dictionary = {}

enum QuestFilter {
	ALL,
	AVAILABLE,
	ACTIVE,
	COMPLETED
}

var current_filter: QuestFilter = QuestFilter.ALL

func _ready() -> void:
	quest_manager = get_node("/root/QuestManager") if has_node("/root/QuestManager") else null
	
	if quest_manager:
		quest_manager.quest_accepted.connect(_on_quest_accepted)
		quest_manager.quest_completed.connect(_on_quest_completed)
		quest_manager.quest_updated.connect(_on_quest_updated)
	
	_setup_filter()
	_load_quests()

func _setup_filter() -> void:
	quest_filter.clear()
	quest_filter.add_item("Tümü", QuestFilter.ALL)
	quest_filter.add_item("Müsait", QuestFilter.AVAILABLE)
	quest_filter.add_item("Aktif", QuestFilter.ACTIVE)
	quest_filter.add_item("Tamamlanan", QuestFilter.COMPLETED)
	quest_filter.item_selected.connect(_on_filter_changed)

func _load_quests() -> void:
	_clear_quest_list()
	
	if not quest_manager:
		return
	
	var quests = quest_manager.get_available_quests()
	var active_quests = quest_manager.get_active_quests()
	
	# Update active quests counter
	active_quests_label.text = "Aktif Görevler: %d/%d" % [
		active_quests.size(),
		quest_manager.max_active_quests if quest_manager.has("max_active_quests") else 5
	]
	
	# Filter quests based on current filter
	var filtered_quests = _filter_quests(quests, active_quests)
	
	# Create quest items
	for quest in filtered_quests:
		var quest_item = _create_quest_item(quest)
		quest_list.add_child(quest_item)

func _filter_quests(available_quests: Array, active_quests: Array) -> Array:
	var filtered: Array = []
	
	match current_filter:
		QuestFilter.ALL:
			filtered.append_array(active_quests)
			filtered.append_array(available_quests)
		QuestFilter.AVAILABLE:
			filtered = available_quests.duplicate()
		QuestFilter.ACTIVE:
			filtered = active_quests.duplicate()
		QuestFilter.COMPLETED:
			if quest_manager and quest_manager.has_method("get_completed_quests"):
				filtered = quest_manager.get_completed_quests()
	
	return filtered

func _create_quest_item(quest: Dictionary) -> Control:
	var item = PanelContainer.new()
	item.custom_minimum_size = Vector2(0, 80)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	item.add_child(margin)
	
	var hbox = HBoxContainer.new()
	margin.add_child(hbox)
	
	# Quest info container
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)
	
	# Quest name
	var name_label = Label.new()
	name_label.text = quest.get("name", "Görev")
	name_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(name_label)
	
	# Quest description
	var desc_label = Label.new()
	desc_label.text = quest.get("description", "")
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.modulate = Color(0.8, 0.8, 0.8)
	vbox.add_child(desc_label)
	
	# Quest rewards
	var reward_label = Label.new()
	var rewards = quest.get("rewards", {})
	var reward_text = "Ödüller: "
	if rewards.has("gold"):
		reward_text += "%d Altın " % rewards.gold
	if rewards.has("exp"):
		reward_text += "%d XP " % rewards.exp
	reward_label.text = reward_text
	reward_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(reward_label)
	
	# Action button
	var button = Button.new()
	button.custom_minimum_size = Vector2(120, 0)
	
	var is_active = quest.get("is_active", false)
	var is_completed = quest.get("is_completed", false)
	
	if is_completed:
		button.text = "Tamamlandı"
		button.disabled = true
	elif is_active:
		button.text = "Devam Ediyor"
		button.disabled = true
	else:
		button.text = "Başlat"
		button.pressed.connect(_on_start_quest_pressed.bind(quest))
	
	hbox.add_child(button)
	
	# Click to show details
	item.gui_input.connect(_on_quest_item_clicked.bind(quest))
	
	return item

func _on_quest_item_clicked(event: InputEvent, quest: Dictionary) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_show_quest_details(quest)

func _show_quest_details(quest: Dictionary) -> void:
	selected_quest = quest
	quest_details.visible = true
	
	# Update details panel (assumes child nodes exist in scene)
	var title_label = quest_details.get_node_or_null("MarginContainer/VBox/Title")
	if title_label:
		title_label.text = quest.get("name", "")
	
	var desc_label = quest_details.get_node_or_null("MarginContainer/VBox/Description")
	if desc_label:
		desc_label.text = quest.get("description", "")
	
	var objectives_label = quest_details.get_node_or_null("MarginContainer/VBox/Objectives")
	if objectives_label:
		var objectives = quest.get("objectives", [])
		var obj_text = "Hedefler:\n"
		for obj in objectives:
			obj_text += "• %s\n" % obj.get("description", "")
		objectives_label.text = obj_text

func _on_start_quest_pressed(quest: Dictionary) -> void:
	if quest_manager and quest_manager.has_method("start_quest"):
		quest_manager.start_quest(quest.get("id", ""))

func _on_filter_changed(index: int) -> void:
	current_filter = index as QuestFilter
	_load_quests()

func _clear_quest_list() -> void:
	for child in quest_list.get_children():
		child.queue_free()

func _on_quest_accepted(_quest_id: String) -> void:
	_load_quests()

func _on_quest_completed(_quest_id: String) -> void:
	_load_quests()

func _on_quest_updated(_quest_id: String) -> void:
	_load_quests()

func _on_close_details_pressed() -> void:
	quest_details.visible = false
	selected_quest = {}

func refresh() -> void:
	_load_quests()
