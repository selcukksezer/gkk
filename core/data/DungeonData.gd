## DungeonData.gd - Dungeon ve quest instance veri modeli
## Zindan başlatma, başarı hesaplama, hastalik riski, loot sistemi

class_name DungeonData

# Dungeon İnstance Durumları (şimdi DungeonInstance.gd'de tanımlanıyor)

## Dungeon tanımı (statik metadata)
class DungeonDefinition:
	var id: String
	var name: String
	var description: String
	var story_text: String
	var difficulty: String  # "EASY" | "MEDIUM" | "HARD" | "DUNGEON"
	var required_level: int
	var energy_cost: int
	var danger_level: int  # 0-100, başarı şansını etkiler
	var min_reward_gold: int
	var max_reward_gold: int
	var base_success_rate: float
	var critical_failure_rate: float
	var estimated_duration: int  # saniye
	var is_group: bool = false
	var max_group_size: int = 1
	
	func _init(p_id: String, p_name: String, p_difficulty: String):
		self.id = p_id
		self.name = p_name
		self.difficulty = p_difficulty
		self.description = ""
		self.story_text = ""
		self.required_level = 1
		self.energy_cost = 20
		self.danger_level = 50
		self.min_reward_gold = 100
		self.max_reward_gold = 500
		self.base_success_rate = 0.5
		self.critical_failure_rate = 0.1
		self.estimated_duration = 600
	
	func to_dict() -> Dictionary:
		return {
			"id": id,
			"name": name,
			"description": description,
			"story_text": story_text,
			"difficulty": difficulty,
			"required_level": required_level,
			"energy_cost": energy_cost,
			"danger_level": danger_level,
			"min_reward_gold": min_reward_gold,
			"max_reward_gold": max_reward_gold,
			"base_success_rate": base_success_rate,
			"critical_failure_rate": critical_failure_rate,
			"estimated_duration": estimated_duration,
			"is_group": is_group,
			"max_group_size": max_group_size
		}
	
	static func from_dict(data: Dictionary) -> DungeonDefinition:
		var def = DungeonDefinition.new(
			data.get("id", ""),
			data.get("name", "Bilinmeyen Zindan"),
			data.get("difficulty", "MEDIUM")
		)
		def.description = data.get("description", "")
		def.story_text = data.get("story_text", "")
		def.required_level = data.get("required_level", 1)
		def.energy_cost = data.get("energy_cost", 20)
		def.danger_level = data.get("danger_level", 50)
		def.min_reward_gold = data.get("min_reward_gold", 100)
		def.max_reward_gold = data.get("max_reward_gold", 500)
		def.base_success_rate = data.get("base_success_rate", 0.5)
		def.critical_failure_rate = data.get("critical_failure_rate", 0.1)
		def.estimated_duration = data.get("estimated_duration", 600)
		def.is_group = data.get("is_group", false)
		def.max_group_size = data.get("max_group_size", 1)
		return def

## Helper ID generator
static func generate_id() -> String:
	return "dungeon_%d_%s" % [Time.get_ticks_msec(), str(randi()).substr(0, 8)]
