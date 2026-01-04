class_name QuestData
extends Resource
## Quest Data Model
## Represents a quest/mission in the game

enum QuestDifficulty {
	EASY,        # 5 enerji
	MEDIUM,      # 10 enerji
	HARD,        # 15 enerji
	DUNGEON      # 20-40 enerji
}

enum QuestStatus {
	AVAILABLE,
	ACTIVE,
	COMPLETED,
	FAILED,
	EXPIRED
}

enum QuestType {
	STORY,       # Ana hikaye
	SIDE,        # Yan görev
	DAILY,       # Günlük
	WEEKLY,      # Haftalık
	SEASONAL,    # Sezonluk
	GUILD,       # Lonca görevi
	REPEATABLE   # Tekrarlanabilir
}

@export var quest_id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var story_text: String = ""
@export var icon: String = ""

@export var quest_type: QuestType = QuestType.SIDE
@export var difficulty: QuestDifficulty = QuestDifficulty.EASY
@export var status: QuestStatus = QuestStatus.AVAILABLE

## Requirements
@export var required_level: int = 1
@export var required_previous_quest: String = ""  # Quest chain
@export var power_requirement: int = 0
@export var energy_cost: int = 5

## Objectives
@export var objectives: Array[Dictionary] = []  # [{type, target, current, required}]
@export var current_objective: int = 0

## Rewards
@export var gold_reward: int = 0
@export var exp_reward: int = 0
@export var item_rewards: Array = []  # Item IDs or Dictionaries
@export var reputation_reward: int = 0

## Risk/Success
@export var success_rate: float = 1.0  # 0.0 to 1.0
@export var critical_failure_rate: float = 0.0  # Chance of hospital
@export var critical_success_multiplier: float = 1.0  # Reward multiplier

## Timing
@export var time_limit: int = 0  # Seconds (0 = no limit)
@export var cooldown: int = 0  # Seconds before can repeat
@export var expires_at: int = 0  # Unix timestamp (0 = never)
@export var started_at: int = 0
@export var completed_at: int = 0

## Meta
@export var is_repeatable: bool = false
@export var times_completed: int = 0
@export var max_completions: int = 0  # 0 = unlimited

## Create from dictionary
static func from_dict(data: Dictionary) -> QuestData:
	var quest = QuestData.new()
	
	quest.quest_id = data.get("id", "")
	quest.name = data.get("name", "")
	quest.description = data.get("description", "")
	quest.story_text = data.get("story_text", "")
	quest.icon = data.get("icon", "")
	
	# Parse enums
	var type_str = data.get("quest_type", "SIDE")
	quest.quest_type = QuestType.get(type_str) if QuestType.has(type_str) else QuestType.SIDE
	
	var diff_str = data.get("difficulty", "EASY")
	quest.difficulty = QuestDifficulty.get(diff_str) if QuestDifficulty.has(diff_str) else QuestDifficulty.EASY
	
	var status_str = data.get("status", "AVAILABLE")
	quest.status = QuestStatus.get(status_str) if QuestStatus.has(status_str) else QuestStatus.AVAILABLE
	
	quest.required_level = data.get("required_level", 1)
	quest.required_previous_quest = data.get("required_previous_quest", "")
	quest.power_requirement = data.get("power_requirement", 0)
	quest.energy_cost = data.get("energy_cost", 5)
	
	if data.has("objectives"):
		quest.objectives.assign(data.objectives)
	quest.current_objective = data.get("current_objective", 0)
	
	quest.gold_reward = data.get("gold_reward", 0)
	quest.exp_reward = data.get("exp_reward", 0)
	if data.has("item_rewards"):
		quest.item_rewards.assign(data.item_rewards)
	quest.reputation_reward = data.get("reputation_reward", 0)
	
	quest.success_rate = data.get("success_rate", 1.0)
	quest.critical_failure_rate = data.get("critical_failure_rate", 0.0)
	quest.critical_success_multiplier = data.get("critical_success_multiplier", 1.0)
	
	quest.time_limit = data.get("time_limit", 0)
	quest.cooldown = data.get("cooldown", 0)
	quest.expires_at = data.get("expires_at", 0)
	quest.started_at = data.get("started_at", 0)
	quest.completed_at = data.get("completed_at", 0)
	
	quest.is_repeatable = data.get("is_repeatable", false)
	quest.times_completed = data.get("times_completed", 0)
	quest.max_completions = data.get("max_completions", 0)
	
	return quest

## Convert to dictionary
func to_dict() -> Dictionary:
	return {
		"id": quest_id,
		"name": name,
		"description": description,
		"story_text": story_text,
		"icon": icon,
		"quest_type": QuestType.keys()[quest_type],
		"difficulty": QuestDifficulty.keys()[difficulty],
		"status": QuestStatus.keys()[status],
		"required_level": required_level,
		"required_previous_quest": required_previous_quest,
		"power_requirement": power_requirement,
		"energy_cost": energy_cost,
		"objectives": objectives,
		"current_objective": current_objective,
		"gold_reward": gold_reward,
		"exp_reward": exp_reward,
		"item_rewards": item_rewards,
		"reputation_reward": reputation_reward,
		"success_rate": success_rate,
		"critical_failure_rate": critical_failure_rate,
		"critical_success_multiplier": critical_success_multiplier,
		"time_limit": time_limit,
		"cooldown": cooldown,
		"expires_at": expires_at,
		"started_at": started_at,
		"completed_at": completed_at,
		"is_repeatable": is_repeatable,
		"times_completed": times_completed,
		"max_completions": max_completions
	}

## Check if quest is available
func is_available(player_level: int) -> bool:
	if status != QuestStatus.AVAILABLE:
		return false
	if player_level < required_level:
		return false
	if expires_at > 0 and Time.get_unix_time_from_system() > expires_at:
		return false
	return true

## Check if quest can be repeated
func can_repeat() -> bool:
	if not is_repeatable:
		return false
	if max_completions > 0 and times_completed >= max_completions:
		return false
	# Check cooldown
	if completed_at > 0 and cooldown > 0:
		var time_since = Time.get_unix_time_from_system() - completed_at
		if time_since < cooldown:
			return false
	return true

## Get remaining time
func get_remaining_time() -> int:
	if time_limit == 0 or started_at == 0:
		return -1
	var elapsed = Time.get_unix_time_from_system() - started_at
	return max(0, time_limit - elapsed)

## Check if expired
func is_expired() -> bool:
	if time_limit > 0 and started_at > 0:
		return get_remaining_time() == 0
	if expires_at > 0:
		return Time.get_unix_time_from_system() > expires_at
	return false

## Get progress percentage
func get_progress() -> float:
	if objectives.is_empty():
		return 0.0
	
	var total = 0.0
	for obj in objectives:
		var current = obj.get("current", 0)
		var required = obj.get("required", 1)
		total += float(current) / float(required)
	
	return (total / objectives.size()) * 100.0

## Check if complete
func is_complete() -> bool:
	if objectives.is_empty():
		return false
	
	for obj in objectives:
		var current = obj.get("current", 0)
		var required = obj.get("required", 1)
		if current < required:
			return false
	
	return true

## Update objective progress
func update_objective(objective_index: int, value: int) -> void:
	if objective_index < 0 or objective_index >= objectives.size():
		return
	
	objectives[objective_index]["current"] = value

## Get difficulty color
func get_difficulty_color() -> Color:
	match difficulty:
		QuestDifficulty.EASY:
			return Color.GREEN
		QuestDifficulty.MEDIUM:
			return Color.YELLOW
		QuestDifficulty.HARD:
			return Color.ORANGE
		QuestDifficulty.DUNGEON:
			return Color.RED
		_:
			return Color.WHITE
