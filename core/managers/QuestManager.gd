class_name QuestManager
extends RefCounted
## Quest Management System
## Handles quest fetching, starting, completing, and tracking

signal quest_started(quest: QuestData)
signal quest_completed(quest: QuestData, rewards: Dictionary)
signal quest_failed(quest: QuestData)
signal quest_progress_updated(quest: QuestData, objective_index: int)

const QUEST_ENDPOINT = "/api/v1/quests"

## Fetch available quests
func fetch_available_quests() -> Dictionary:
	var result = await Network.http_get(QUEST_ENDPOINT)
	
	if result.success and result.data.has("quests"):
		var quests: Array[QuestData] = []
		for quest_dict in result.data.quests:
			quests.append(QuestData.from_dict(quest_dict))
		
		return {"success": true, "quests": quests}
	
	return {"success": false, "error": result.get("error", "Failed to fetch quests")}

## Fetch active quests
func fetch_active_quests() -> Dictionary:
	var result = await Network.http_get(QUEST_ENDPOINT + "/active")
	
	if result.success and result.data.has("quests"):
		var quests: Array[QuestData] = []
		for quest_dict in result.data.quests:
			var quest = QuestData.from_dict(quest_dict)
			quests.append(quest)
		
		State.active_quests = quests
		return {"success": true, "quests": quests}
	
	return {"success": false, "error": result.get("error", "Failed to fetch active quests")}

## Start a quest
func start_quest(quest_id: String) -> Dictionary:
	# Check energy
	var quest_config = GameConfig.get_quest(quest_id)
	if quest_config.is_empty():
		return {"success": false, "error": "Quest not found"}
	
	var energy_cost = quest_config.get("energy_cost", 5)
	
	# Check if we have an EnergyManager (it's an autoload)
	if Engine.has_singleton("EnergyManager"):
		var energy_mgr = Engine.get_singleton("EnergyManager")
		if energy_mgr.has_method("has_energy") and not energy_mgr.has_energy(energy_cost):
			return {"success": false, "error": "Not enough energy", "code": "INSUFFICIENT_ENERGY"}
	
	# Start quest on server
	var result = await Network.post_json(QUEST_ENDPOINT + "/start", {"quest_id": quest_id})
	
	if result.success:
		# Consume energy
		if Engine.has_singleton("EnergyManager"):
			var energy_mgr = Engine.get_singleton("EnergyManager")
			if energy_mgr.has_method("consume_energy"):
				energy_mgr.consume_energy(energy_cost, "quest_start")
		
		var quest = QuestData.from_dict(result.data.quest)
		State.active_quests.append(quest)
		quest_started.emit(quest)
		
		Audio.play_quest_start()
		
		Telemetry.track_event("quest_started", {
			"quest_id": quest_id,
			"energy_cost": energy_cost
		})
		
		return {"success": true, "quest": quest}
	
	return {"success": false, "error": result.get("error", "Failed to start quest")}

## Complete a quest
func complete_quest(quest_id: String) -> Dictionary:
	var result = await Network.post_json(QUEST_ENDPOINT + "/complete", {"quest_id": quest_id})
	
	if result.success:
		var quest = QuestData.from_dict(result.data.quest)
		var rewards = result.data.get("rewards", {})
		
		# Apply rewards
		if rewards.has("gold"):
			State.gold += rewards.gold
		if rewards.has("exp"):
			_add_experience(rewards.exp)
		if rewards.has("items"):
			if Engine.has_singleton("InventoryManager"):
				var inv_mgr = Engine.get_singleton("InventoryManager")
				for item in rewards.items:
					if inv_mgr.has_method("add_item"):
						inv_mgr.add_item(item)
		if rewards.has("reputation"):
			State.reputation += rewards.reputation
		
		# Remove from active quests
		for i in State.active_quests.size():
			if State.active_quests[i].quest_id == quest_id:
				State.active_quests.remove_at(i)
				break
		
		# Add to completed
		State.completed_quests.append(quest_id)
		
		quest_completed.emit(quest, rewards)
		Audio.play_quest_complete()
		
		Telemetry.track_event("quest_completed", {
			"quest_id": quest_id,
			"rewards": rewards
		})
		
		return {"success": true, "quest": quest, "rewards": rewards}
	
	return {"success": false, "error": result.get("error", "Failed to complete quest")}

## Abandon a quest
func abandon_quest(quest_id: String) -> Dictionary:
	var result = await Network.post_json(QUEST_ENDPOINT + "/abandon", {"quest_id": quest_id})
	
	if result.success:
		# Remove from active quests
		for i in State.active_quests.size():
			if State.active_quests[i].quest_id == quest_id:
				State.active_quests.remove_at(i)
				break
		
		Telemetry.track_event("quest_abandoned", {"quest_id": quest_id})
		
		return {"success": true}
	
	return {"success": false, "error": result.get("error", "Failed to abandon quest")}

## Update quest progress
func update_quest_progress(quest_id: String, objective_index: int, progress: int) -> void:
	for quest in State.active_quests:
		if quest.quest_id == quest_id:
			quest.update_objective(objective_index, progress)
			quest_progress_updated.emit(quest, objective_index)
			
			# Sync with server
			await Network.http_post(QUEST_ENDPOINT + "/progress", {
				"quest_id": quest_id,
				"objective_index": objective_index,
				"progress": progress
			})
			break

## Get daily quests
func get_daily_quests() -> Array[QuestData]:
	var daily: Array[QuestData] = []
	for quest in State.active_quests:
		if quest.quest_type == QuestData.QuestType.DAILY:
			daily.append(quest)
	return daily

## Check if quest is available
func is_quest_available(quest_id: String) -> bool:
	var quest_config = GameConfig.get_quest(quest_id)
	if quest_config.is_empty():
		return false
	
	var required_level = quest_config.get("required_level", 1)
	if State.player.level < required_level:
		return false
	
	# Check if already active
	for quest in State.active_quests:
		if quest.quest_id == quest_id:
			return false
	
	# Check if already completed (for non-repeatable)
	if not quest_config.get("is_repeatable", false):
		if quest_id in State.completed_quests:
			return false
	
	return true

## Add experience (with level up check)
func _add_experience(experience: int) -> void:
	State.player.experience += experience
	
	# Check level up - player data should have these methods
	# For now, just add exp without level up logic
	# TODO: Implement proper level up in PlayerData
	if State.player.has("level") and State.player.has("experience"):
		var exp_needed = _calculate_exp_for_next_level(State.player.get("level", 1))
		if State.player.experience >= exp_needed:
			State.player.level = State.player.get("level", 1) + 1
			State.player.experience -= exp_needed
			if Engine.has_singleton("AudioManager"):
				var audio_mgr = Engine.get_singleton("AudioManager")
				if audio_mgr.has_method("play_level_up"):
					audio_mgr.play_level_up()
			# Show level up notification

func _calculate_exp_for_next_level(current_level: int) -> int:
	return 100 * (current_level + 1)  # Simple formula
