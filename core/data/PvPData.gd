class_name PvPData
extends Resource
## PvP Data Model
## Represents PvP battle data and results

enum BattleResult {
	CRITICAL_VICTORY,  # Kritik zafer (+150% ödül, rakip hastane 8 saat)
	VICTORY,           # Zafer (+100% ödül)
	DRAW,              # Beraberlik (enerji gider, ödül yok)
	DEFEAT,            # Yenilgi (enerji gider, kayıp var)
	CRITICAL_DEFEAT    # Kritik yenilgi (hastane 8 saat)
}

@export var battle_id: String = ""
@export var attacker_id: String = ""
@export var defender_id: String = ""
@export var attacker_name: String = ""
@export var defender_name: String = ""

## Battle stats are now only in static functions, not instance vars
@export var attacker_power: int = 0
@export var defender_power: int = 0
@export var attacker_level: int = 0
@export var defender_level: int = 0

## Battle result
@export var result: BattleResult = BattleResult.DRAW
@export var is_revenge: bool = false  # Misilleme mi?

## Rewards/Losses
@export var gold_change: int = 0  # + for gain, - for loss
@export var reputation_change: int = 0
@export var exp_gained: int = 0

## Hospital
@export var attacker_hospitalized: bool = false
@export var defender_hospitalized: bool = false
@export var hospital_duration: int = 0  # Hours

## Meta
@export var battle_timestamp: int = 0
@export var region: String = "central"

## Create from dictionary
static func from_dict(data: Dictionary) -> PvPData:
	var pvp = PvPData.new()
	
	pvp.battle_id = data.get("id", "")
	pvp.attacker_id = data.get("attacker_id", "")
	pvp.defender_id = data.get("defender_id", "")
	pvp.attacker_name = data.get("attacker_name", "")
	pvp.defender_name = data.get("defender_name", "")
	
	pvp.attacker_power = data.get("attacker_power", 0)
	pvp.defender_power = data.get("defender_power", 0)
	pvp.attacker_level = data.get("attacker_level", 0)
	pvp.defender_level = data.get("defender_level", 0)
	
	var result_str = data.get("result", "DRAW")
	pvp.result = BattleResult.get(result_str) if BattleResult.has(result_str) else BattleResult.DRAW
	
	pvp.is_revenge = data.get("is_revenge", false)
	
	pvp.gold_change = data.get("gold_change", 0)
	pvp.reputation_change = data.get("reputation_change", 0)
	pvp.exp_gained = data.get("exp_gained", 0)
	
	pvp.attacker_hospitalized = data.get("attacker_hospitalized", false)
	pvp.defender_hospitalized = data.get("defender_hospitalized", false)
	pvp.hospital_duration = data.get("hospital_duration", 0)
	
	pvp.battle_timestamp = data.get("battle_timestamp", 0)
	pvp.region = data.get("region", "central")
	
	return pvp

func to_dict() -> Dictionary:
	return {
		"id": battle_id,
		"attacker_id": attacker_id,
		"defender_id": defender_id,
		"attacker_name": attacker_name,
		"defender_name": defender_name,
		"attacker_power": attacker_power,
		"defender_power": defender_power,
		"attacker_level": attacker_level,
		"defender_level": defender_level,
		"result": BattleResult.keys()[result],
		"is_revenge": is_revenge,
		"gold_change": gold_change,
		"reputation_change": reputation_change,
		"exp_gained": exp_gained,
		"attacker_hospitalized": attacker_hospitalized,
		"defender_hospitalized": defender_hospitalized,
		"hospital_duration": hospital_duration,
		"battle_timestamp": battle_timestamp,
		"region": region
	}

## Calculate victory chance based on power difference
static func calculate_win_chance(atk_power: int, def_power: int) -> float:
	var power_ratio = float(atk_power) / float(max(def_power, 1))
	
	# Base chance 50%
	var base_chance = 0.5
	
	# Power influence (capped at +/- 30%)
	var power_influence = clamp((power_ratio - 1.0) * 0.3, -0.3, 0.3)
	
	return clamp(base_chance + power_influence, 0.1, 0.9)

## Calculate battle result
static func determine_result(atk_power: int, def_power: int) -> BattleResult:
	var win_chance = calculate_win_chance(atk_power, def_power)
	var roll = randf()
	
	if roll < win_chance:
		# Attacker wins
		if randf() < 0.1:  # 10% critical
			return BattleResult.CRITICAL_VICTORY
		else:
			return BattleResult.VICTORY
	else:
		# Defender wins
		if randf() < 0.1:  # 10% critical
			return BattleResult.CRITICAL_DEFEAT
		else:
			return BattleResult.DEFEAT
	
	# Fallback
	return BattleResult.DEFEAT

## Get result message
func get_result_message(is_attacker: bool) -> String:
	var _is_winner = (is_attacker and result in [BattleResult.VICTORY, BattleResult.CRITICAL_VICTORY]) or \
	                (not is_attacker and result in [BattleResult.DEFEAT, BattleResult.CRITICAL_DEFEAT])
	
	match result:
		BattleResult.CRITICAL_VICTORY:
			return "Kritik Zafer!" if is_attacker else "Ağır Yenilgi!"
		BattleResult.VICTORY:
			return "Zafer!" if is_attacker else "Yenilgi"
		BattleResult.DRAW:
			return "Beraberlik"
		BattleResult.DEFEAT:
			return "Yenilgi" if is_attacker else "Zafer!"
		BattleResult.CRITICAL_DEFEAT:
			return "Ağır Yenilgi!" if is_attacker else "Kritik Zafer!"
		_:
			return "Bilinmeyen Sonuç"

## Get result color
func get_result_color(is_attacker: bool) -> Color:
	var is_winner = (is_attacker and result in [BattleResult.VICTORY, BattleResult.CRITICAL_VICTORY]) or \
	                (not is_attacker and result in [BattleResult.DEFEAT, BattleResult.CRITICAL_DEFEAT])
	
	if result == BattleResult.DRAW:
		return Color.GRAY
	elif is_winner:
		return Color.GREEN
	else:
		return Color.RED

## Calculate gold reward/loss
static func calculate_gold_change(battle_result: BattleResult, defender_gold: int) -> int:
	var base_amount = int(defender_gold * 0.05)  # 5% of defender's gold
	
	match battle_result:
		BattleResult.CRITICAL_VICTORY:
			return int(base_amount * 1.5)
		BattleResult.VICTORY:
			return base_amount
		BattleResult.DRAW:
			return 0
		BattleResult.DEFEAT:
			return -int(base_amount * 0.5)
		BattleResult.CRITICAL_DEFEAT:
			return -base_amount
		_:
			return 0

## Calculate reputation change
static func calculate_reputation_change(battle_result: BattleResult, is_attacker: bool) -> int:
	if is_attacker:
		# Attackers lose reputation
		match battle_result:
			BattleResult.CRITICAL_VICTORY:
				return -5
			BattleResult.VICTORY:
				return -3
			BattleResult.DRAW:
				return -1
			BattleResult.DEFEAT:
				return -1
			BattleResult.CRITICAL_DEFEAT:
				return -1
			_:
				return 0
	else:
		# Defenders gain reputation
		match battle_result:
			BattleResult.CRITICAL_DEFEAT:  # Defender wins critically
				return 10
			BattleResult.DEFEAT:  # Defender wins
				return 5
			BattleResult.DRAW:
				return 0
			BattleResult.VICTORY:  # Defender loses
				return -2
			BattleResult.CRITICAL_VICTORY:  # Defender loses critically
				return -5
			_:
				return 0
