extends Control
## Quest Screen
## Displays available quests and active quest progress

@onready var quest_tabs = $TabContainer
@onready var available_list = $TabContainer/Available/ScrollContainer/VBoxContainer
@onready var active_list = $TabContainer/Active/ScrollContainer/VBoxContainer
@onready var completed_list = $TabContainer/Completed/ScrollContainer/VBoxContainer

@onready var quest_details = $QuestDetailsPanel
@onready var quest_title = $QuestDetailsPanel/Title
@onready var quest_description = $QuestDetailsPanel/Description
@onready var quest_rewards = $QuestDetailsPanel/Rewards
@onready var quest_requirements = $QuestDetailsPanel/Requirements
@onready var start_button = $QuestDetailsPanel/StartButton
@onready var claim_button = $QuestDetailsPanel/ClaimButton

@onready var back_button = $BackButton

var _selected_quest: QuestData = QuestData.new()
var _quest_card_scene = preload("res://scenes/prefabs/QuestCard.tscn")

func _ready() -> void:
	# Connect signals
	back_button.pressed.connect(_on_back_pressed)
	start_button.pressed.connect(_on_start_quest)
	claim_button.pressed.connect(_on_claim_quest)
	
	# Track screen
	Telemetry.track_screen("quest")
	
	# Load quests
	_load_quests()

func _load_quests() -> void:
	var result = await Network.http_get("/quests")
	_on_quests_loaded(result)

func _on_quests_loaded(result: Dictionary) -> void:
	if not result.success:
		print("[Quest] Failed to load quests")
		return
	
	var data = result.data
	
	# Clear lists
	for child in available_list.get_children():
		child.queue_free()
	for child in active_list.get_children():
		child.queue_free()
	for child in completed_list.get_children():
		child.queue_free()
	
	# Available quests
	var available = data.get("available", [])
	for quest_dict in available:
		var quest = QuestData.from_dict(quest_dict)
		var card = _quest_card_scene.instantiate()
		available_list.add_child(card)
		card.set_quest(quest)
		card.clicked.connect(_on_quest_selected.bind(quest))
	
	# Active quests
	var active = data.get("active", [])
	for quest_dict in active:
		var quest = QuestData.from_dict(quest_dict)
		var card = _quest_card_scene.instantiate()
		active_list.add_child(card)
		card.set_quest(quest)
		card.clicked.connect(_on_quest_selected.bind(quest))
	
	# Completed quests (last 20)
	var completed = data.get("completed", [])
	for quest_dict in completed:
		var quest = QuestData.from_dict(quest_dict)
		var card = _quest_card_scene.instantiate()
		completed_list.add_child(card)
		card.set_quest(quest)
		card.clicked.connect(_on_quest_selected.bind(quest))

func _on_quest_selected(quest: QuestData) -> void:
	_selected_quest = quest
	_show_quest_details(quest)

func _show_quest_details(quest: QuestData) -> void:
	quest_details.visible = true
	
	quest_title.text = quest.name
	quest_description.text = quest.description
	
	# Show requirements
	var req_text = ""
	req_text += "Energy: %d\n" % quest.energy_cost
	req_text += "Min Level: %d\n" % quest.required_level
	if quest.power_requirement > 0:
		req_text += "Min Power: %d\n" % quest.power_requirement
	quest_requirements.text = req_text
	
	# Show rewards
	var reward_text = ""
	reward_text += "Gold: %d\n" % quest.gold_reward
	reward_text += "XP: %d\n" % quest.exp_reward
	if quest.item_rewards.size() > 0:
		reward_text += "\nItems:\n"
		for item in quest.item_rewards:
			# item_rewards may be strings (IDs) or dictionaries with an item_id key
			var item_id := ""
			match typeof(item):
				TYPE_STRING:
					item_id = item
				TYPE_DICTIONARY:
					item_id = (item as Dictionary).get("item_id", "")
				_:
					item_id = str(item)
			reward_text += "- %s\n" % item_id
	quest_rewards.text = reward_text
	
	# Show appropriate button
	start_button.visible = (quest.status == QuestData.QuestStatus.AVAILABLE)
	claim_button.visible = (quest.status == QuestData.QuestStatus.COMPLETED)

func _on_start_quest() -> void:
	if not _selected_quest:
		return
	
	# Check energy
	var energy_cost = _selected_quest.energy_cost
	if State.current_energy < energy_cost:
		print("[Quest] Insufficient energy")
		return
	
	# Check level
	if State.level < _selected_quest.min_level:
		print("[Quest] Level too low")
		return
	
	var body = {
		"quest_id": _selected_quest.quest_id
	}
	
	var result = await Network.http_post("/quests/start", body)
	_on_quest_started(result)
	
	Telemetry.track_event("quest", "start", {
		"quest_id": _selected_quest.quest_id,
		"difficulty": str(_selected_quest.difficulty),
		"energy_cost": energy_cost
	})

func _on_quest_started(result: Dictionary) -> void:
	if result.success:
		print("[Quest] Quest started successfully")
		
		# Update energy
		State.update_energy(result.data.get("energy", State.current_energy))
		
		# Reload quests
		_load_quests()
		
		# Hide details
		quest_details.visible = false
	else:
		print("[Quest] Failed to start quest: ", result.get("error", ""))

func _on_claim_quest() -> void:
	if not _selected_quest:
		return
	
	var body = {
		"quest_id": _selected_quest.quest_id
	}
	
	var result = await Network.http_post("/quests/claim", body)
	_on_quest_claimed(result)

func _on_quest_claimed(result: Dictionary) -> void:
	if result.success:
		print("[Quest] Quest claimed successfully")
		
		var data = result.data
		
		# Update state
		State.gold += data.get("gold_earned", 0)
		State.xp += data.get("xp_earned", 0)
		
		# Track completion
		Telemetry.track_quest_completed(
			_selected_quest.quest_id,
			QuestData.QuestDifficulty.keys()[_selected_quest.difficulty],
			0  # Duration - server should track
		)
		
		# Reload quests
		_load_quests()
		
		# Hide details
		quest_details.visible = false
	else:
		print("[Quest] Failed to claim quest: ", result.get("error", ""))

func _on_back_pressed() -> void:
	Scenes.change_scene("res://scenes/ui/MainMenu.tscn")
