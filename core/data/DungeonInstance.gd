## DungeonInstance.gd - Dungeon instance veri sınıfı
## Ayrı dosya olarak; GDScript inner class compatibility sorunlarını önlemek için

class_name DungeonInstance

# Dungeon Instance Durumları
enum DungeonState {
	PENDING,      # Başlanmış ama çözülmemiş
	SUCCESS,      # Başarılı tamamlandı
	FAILURE,      # Başarısız
	HOSPITALIZED  # Hastaneliğe alındı
}

var id: String
var player_id: String
var dungeon_id: String
var dungeon_name: String
var state: DungeonState = DungeonState.PENDING
var started_at: int
var resolved_at: int = 0

var energy_cost: int
var base_success_rate: float
var estimated_duration: int  # saniye

var min_reward_gold: int = 100
var max_reward_gold: int = 500

var actual_success: bool = false
var success_rate_calculated: float = 0.0  # Gerçek başarı şansı

var rewards: Dictionary = {}  # gold, exp, items
var loot: Array[String] = []  # item_id leri

var is_hospitalized: bool = false
var hospitalized_reason: String = ""
var hospital_duration_minutes: int = 0

## Başarı/başarısızlık roll'u
var success_roll: float = 0.0

func _init(p_id: String, d_id: String, d_name: String, energy: int, success_rate: float, duration: int):
	self.id = generate_id()
	self.player_id = p_id
	self.dungeon_id = d_id
	self.dungeon_name = d_name
	self.energy_cost = energy
	self.base_success_rate = success_rate
	self.estimated_duration = duration
	self.started_at = int(Time.get_ticks_msec() / 1000.0)

func to_dict() -> Dictionary:
	return {
		"id": id,
		"player_id": player_id,
		"dungeon_id": dungeon_id,
		"dungeon_name": dungeon_name,
		"state": state,
		"started_at": started_at,
		"resolved_at": resolved_at,
		"energy_cost": energy_cost,
		"base_success_rate": base_success_rate,
		"estimated_duration": estimated_duration,
		"min_reward_gold": min_reward_gold,
		"max_reward_gold": max_reward_gold,
		"actual_success": actual_success,
		"success_rate_calculated": success_rate_calculated,
		"rewards": rewards,
		"loot": loot,
		"is_hospitalized": is_hospitalized,
		"hospitalized_reason": hospitalized_reason,
		"hospital_duration_minutes": hospital_duration_minutes,
		"success_roll": success_roll
	}

static func from_dict(data: Dictionary) -> DungeonInstance:
	var inst = DungeonInstance.new(
		data.get("player_id", ""),
		data.get("dungeon_id", ""),
		data.get("dungeon_name", ""),
		data.get("energy_cost", 20),
		data.get("base_success_rate", 0.5),
		data.get("estimated_duration", 600)
	)
	inst.id = data.get("id", inst.id)
	inst.state = data.get("state", DungeonState.PENDING)
	inst.resolved_at = data.get("resolved_at", 0)
	inst.actual_success = data.get("actual_success", false)
	inst.success_rate_calculated = data.get("success_rate_calculated", 0.0)
	inst.rewards = data.get("rewards", {})
	inst.loot = data.get("loot", [])
	inst.min_reward_gold = data.get("min_reward_gold", inst.min_reward_gold)
	inst.max_reward_gold = data.get("max_reward_gold", inst.max_reward_gold)
	inst.is_hospitalized = data.get("is_hospitalized", false)
	inst.hospitalized_reason = data.get("hospitalized_reason", "")
	inst.hospital_duration_minutes = data.get("hospital_duration_minutes", 0)
	inst.success_roll = data.get("success_roll", 0.0)
	return inst

## Helper ID generator
static func generate_id() -> String:
	return "dungeon_%d_%s" % [Time.get_ticks_msec(), str(randi()).substr(0, 8)]
