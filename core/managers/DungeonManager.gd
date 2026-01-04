## DungeonManager.gd - Zindan sistemi yönetimi
## Başarı olasılığı hesaplama, hastalik riski, loot distribution, API integration

extends Node

class_name DungeonManager

signal dungeon_started(instance: DungeonInstance)
signal dungeon_resolved(instance: DungeonInstance)
#signal dungeon_hospitalized(instance: DungeonInstance)  # TODO: Implement when signal is used

## Dungeon başarı olasılığı parametreleri
var BASE_SUCCESS_RATES = {
	"EASY": 0.85,
	"MEDIUM": 0.70,
	"HARD": 0.55,
	"DUNGEON": 0.45  # Solo dungeon
}

var GROUP_SUCCESS_MODIFIER = 0.60  # Grup bonusu

## Hastanelik riski parametreleri - başarısızlıkta yapı hasarı riski
var HOSPITALIZE_RATES = {
	"EASY": 0.0,
	"MEDIUM": 0.05,
	"HARD": 0.15,
	"DUNGEON": 0.25
}

var HOSPITAL_DURATION_RANGE = {
	"EASY": [0, 0],
	"MEDIUM": [120, 240],
	"HARD": [240, 360],
	"DUNGEON": [120, 360]
}

## Success rate formula weights - karakter gücü ve zorluk dengelemesi
var GEAR_WEIGHT = 0.25         # Ekipman etkisi (silah + zırh)
var SKILL_WEIGHT = 0.15        # Beceri/Başarı oranı
var LEVEL_WEIGHT = 0.15        # Seviye faktörü
var DIFFICULTY_WEIGHT = 0.20   # Zorluk penaltısı
var DANGER_WEIGHT = 0.15       # Risk faktörü (critical multiplier)

var MIN_SUCCESS_RATE = 0.10
var MAX_SUCCESS_RATE = 0.95

## Loot tables (dungeon_id -> {item_id: rarity_weight})
var LOOT_TABLES: Dictionary = {}

## Aktif dungeon instances (player_id -> DungeonInstance)
var active_dungeons: Dictionary = {}

func _ready() -> void:
	print("[DungeonManager] Ready")
	_load_loot_tables()

## 1. Dungeon başlatma
func start_dungeon(dungeon_def: DungeonData.DungeonDefinition, player_data: Dictionary) -> Dictionary:
	print("[DungeonManager] Starting dungeon: %s" % dungeon_def.name)
	
	# Not: Seviye kontrolü kaldırıldı - tüm zindanlara girilebilsin
	# Ama başarı olasılığı seviyeye göre düşecek
	
	# Kontrol: enerji
	var current_energy = player_data.get("energy", 0)
	if current_energy < dungeon_def.energy_cost:
		return {"success": false, "error": "Yeterli enerjin yok (%d/%d)" % [current_energy, dungeon_def.energy_cost]}
	
	# Dungeon instance oluştur
	var instance = DungeonInstance.new(
		player_data.get("id", ""),
		dungeon_def.id,
		dungeon_def.name,
		dungeon_def.energy_cost,
		dungeon_def.base_success_rate,
		dungeon_def.estimated_duration
	)
	
	# Enerji tüket
	player_data["energy"] = max(0, current_energy - dungeon_def.energy_cost)
	
	# Başarı olasılığını hesapla
	instance.success_rate_calculated = _calculate_success_rate(
		dungeon_def,
		player_data
	)
	
	# Set instance min/max reward from dungeon_def for later use
	instance.min_reward_gold = dungeon_def.min_reward_gold
	instance.max_reward_gold = dungeon_def.max_reward_gold

	# Instance'ı kaydet
	active_dungeons[player_data.get("id", "")] = instance
	
	# Telemetry: dungeon started
	if player_data and player_data.has("id"):
		Telemetry.track_event("combat.dungeon", "started", {
			"user_id": player_data.get("id", ""),
			"dungeon_id": dungeon_def.id,
			"difficulty": dungeon_def.difficulty,
			"mode": ("group" if dungeon_def.is_group else "solo"),
			"calculated_success": instance.success_rate_calculated
		})

	dungeon_started.emit(instance)
	return {"success": true, "data": instance.to_dict()}

## 2. Başarı olasılığı hesaplama
## Risk/Ödül dengesinin merkezinde - ekipman, seviye, zorluk faktörleri
func _calculate_success_rate(dungeon_def: DungeonData.DungeonDefinition, player_data: Dictionary) -> float:
	var base_rate = BASE_SUCCESS_RATES.get(dungeon_def.difficulty, 0.5)
	
	# Ekipman faktörü (silah gücü + zırh savunması = karakter gücü)
	var weapon_power = _get_gear_power(player_data.get("equipped_weapon", {}))
	var armor_defense = _get_gear_defense(player_data.get("equipped_armor", {}))
	# Normalize 0-1: max ekipman 150 (weapon) + 150 (armor) = 300
	var gear_score = clamp((weapon_power + armor_defense) / 300.0, 0.0, 1.0)
	
	# Seviye faktörü - karakter seviyesi vs. gereken seviye
	var level = float(player_data.get("level", 1))
	var required_level = float(dungeon_def.required_level)
	var level_advantage = level - required_level
	var level_score = clamp(level_advantage / 50.0, -1.0, 1.0)  # -50 seviye fark = %0, +50 = %100
	
	# Seviye cezası - gerekli seviyeye ulaşmamışsa başarı olasılığını düşür
	var level_penalty = 0.0
	if level < required_level:
		level_penalty = (required_level - level) * 0.08  # Seviye farkı başına %8 ceza (artırıldı)
		print("[DungeonManager] Level penalty applied: %.2f%% (have: %d, need: %d)" % [
			level_penalty * 100, int(level), int(required_level)
		])
	
	# Beceri puanı (ileriki versiyonda PlayerData.skill_points olacak)
	var skill_score = 0.2
	
	# Zorluk/Risk faktörü - danger_level joystick
	var difficulty_penalty = dungeon_def.danger_level / 100.0
	
	# Kritik başarısızlık riski ekipman ile azalır (iyiyse daha dirençli)
	var critical_fail_reduction = gear_score * 0.1
	
	# Final hesaplama: temel oran + bonuslar - cezalar
	var calculated_rate = base_rate + \
		(GEAR_WEIGHT * gear_score) + \
		(SKILL_WEIGHT * skill_score) + \
		(LEVEL_WEIGHT * level_score) - \
		(DIFFICULTY_WEIGHT * difficulty_penalty) - \
		(DANGER_WEIGHT * difficulty_penalty * 0.8) - \
		level_penalty - \
		critical_fail_reduction * 0.5
	
	# Sınırla
	calculated_rate = clamp(calculated_rate, MIN_SUCCESS_RATE, MAX_SUCCESS_RATE)
	
	print("[DungeonManager] Success rate: %.1f%% (base: %.0f%%, gear: %+.0f%%, level: %+.0f%%, diff: %-.0f%%)" % [
		calculated_rate * 100,
		base_rate * 100,
		GEAR_WEIGHT * gear_score * 100,
		LEVEL_WEIGHT * level_score * 100,
		DIFFICULTY_WEIGHT * difficulty_penalty * 100
	])
	
	return calculated_rate

# Public helper: returns breakdown of success rate components for UI preview
func preview_success_rate(dungeon_def: DungeonData.DungeonDefinition, player_data: Dictionary) -> Dictionary:
	var base_rate = BASE_SUCCESS_RATES.get(dungeon_def.difficulty, 0.5)

	var weapon_power = _get_gear_power(player_data.get("equipped_weapon", {}))
	var armor_defense = _get_gear_defense(player_data.get("equipped_armor", {}))
	var gear_score = clamp((weapon_power + armor_defense) / 200.0, 0.0, 1.0)

	var level = float(player_data.get("level", 1))
	var required_level = float(dungeon_def.required_level)
	var level_score = clamp(level / 50.0, 0.0, 1.0)

	var level_penalty = 0.0
	if level < required_level:
		level_penalty = (required_level - level) * 0.05

	var skill_score = 0.2

	var difficulty_penalty = dungeon_def.danger_level / 100.0

	# Effects as fractions
	var gear_effect = GEAR_WEIGHT * gear_score
	var level_effect = LEVEL_WEIGHT * level_score
	var difficulty_effect = DIFFICULTY_WEIGHT * difficulty_penalty + DANGER_WEIGHT * (difficulty_penalty * 0.5)

	var calculated_rate = base_rate + gear_effect + (SKILL_WEIGHT * skill_score) + level_effect - difficulty_effect - level_penalty
	calculated_rate = clamp(calculated_rate, MIN_SUCCESS_RATE, MAX_SUCCESS_RATE)

	return {
		"base_rate": base_rate,
		"gear_score": gear_score,
		"gear_effect": gear_effect,
		"level_score": level_score,
		"level_effect": level_effect,
		"level_penalty": level_penalty,
		"difficulty_penalty": difficulty_penalty,
		"difficulty_effect": difficulty_effect,
		"calculated_rate": calculated_rate
	}

## Gear power helper (weapon)
func _get_gear_power(weapon: Dictionary) -> float:
	if weapon.is_empty():
		return 10.0  # Base power
	var rarity_bonus = weapon.get("rarity", "common") == "rare" and 20.0 or 10.0
	return float(weapon.get("power", 10)) + rarity_bonus

## Gear defense helper (armor)
func _get_gear_defense(armor: Dictionary) -> float:
	if armor.is_empty():
		return 10.0  # Base defense
	var rarity_bonus = armor.get("rarity", "common") == "rare" and 20.0 or 10.0
	return float(armor.get("defense", 10)) + rarity_bonus

## 3. Dungeon çözümleme (başarı/başarısızlık RNG)
func resolve_dungeon(instance_id: String, player_data: Dictionary) -> Dictionary:
	var instance = _find_active_dungeon(instance_id)
	if not instance:
		return {"success": false, "error": "Aktif zindan bulunamadı"}
	
	print("[DungeonManager] Resolving dungeon: %s (success_rate: %.2f)" % [
		instance.dungeon_name, instance.success_rate_calculated * 100
	])
	
	# Success roll (0-1)
	instance.success_roll = randf()
	instance.actual_success = instance.success_roll < instance.success_rate_calculated
	
	# Sonuç hesapla
	if instance.actual_success:
		_calculate_success_rewards(instance, player_data)
	else:
		_calculate_failure_rewards(instance, player_data)
	
	# Hastanelik riski (başarısızlıkta)
	if not instance.actual_success:
		if _should_hospitalize(instance):
			_apply_hospitalization(instance, player_data)

	instance.resolved_at = int(Time.get_ticks_msec() / 1000.0)
	instance.state = DungeonInstance.DungeonState.SUCCESS if instance.actual_success else DungeonInstance.DungeonState.FAILURE
	
	if instance.is_hospitalized:
		instance.state = DungeonInstance.DungeonState.HOSPITALIZED

	# Telemetry: dungeon completed
	var duration = instance.resolved_at - instance.started_at if instance.resolved_at and instance.started_at else instance.estimated_duration
	var payload = {
		"user_id": instance.player_id,
		"dungeon_id": instance.dungeon_id,
		"dungeon_name": instance.dungeon_name,
		"mode": "solo", # mode unknown here; can be extended
		"calculated_success": instance.success_rate_calculated,
		"actual_success": instance.actual_success,
		"rewards": instance.rewards,
		"loot_count": instance.loot.size(),
		"duration": duration,
		"hospitalized": instance.is_hospitalized
	}
	Telemetry.track_event("combat.dungeon", "completed", payload)
	dungeon_resolved.emit(instance)
	return {"success": true, "data": instance.to_dict()}

## 4. Başarısızlık hastanelik kararı - başarı oranına göre dinamik
func _should_hospitalize(instance: DungeonInstance) -> bool:
	# Hastanelik şansı başarı olasılığının tersine orantılı
	# Formül: hospitalize_chance = max(0.70, 1.0 - success_rate_calculated)
	# Yani %70 minimum (%30 başarı veya daha düşük = %70 hastanelik şansı)
	# %10 başarı = %90 hastanelik şansı
	# %80 başarı = %70 hastanelik şansı (minimum kap)
	
	var success_rate = instance.success_rate_calculated
	var hospitalize_chance = maxf(0.70, 1.0 - success_rate)
	
	var roll = randf()
	var should_hospitalize = roll < hospitalize_chance
	
	print("[DungeonManager] Hospitalize check: success_rate=%.2f%%, hospitalize_chance=%.2f%%, roll=%.2f -> %s" % [
		success_rate * 100, hospitalize_chance * 100, roll, "YES" if should_hospitalize else "NO"
	])
	
	return should_hospitalize

## 5. Hastanelik uygulanması
func _apply_hospitalization(instance: DungeonInstance, _player_data: Dictionary) -> void:
	# Zorluk seviyesine göre hastanelik süresi belirle
	var difficulty = instance.dungeon_name  # Dungeon definition 'difficulty' alanını kullan
	var duration_range = HOSPITAL_DURATION_RANGE.get(difficulty, [60, 120])
	var duration = randi_range(duration_range[0], duration_range[1])
	
	instance.is_hospitalized = true
	instance.hospitalized_reason = "Zindan başarısızlığı - Yapı hasarı"
	instance.hospital_duration_minutes = duration
	
	print("[DungeonManager] Hospitalized: %d minutes (difficulty: %s)" % [duration, difficulty])

## 6. Başarı ödülleri
func _calculate_success_rewards(instance: DungeonInstance, player_data: Dictionary) -> void:
	# Loot
	var loot_items = _generate_loot(instance.dungeon_id)

	# Compute min/max from player context using instance (if instance overrides exist)
	var reward_range = compute_reward_range_from_instance(instance, player_data)
	var min_gold = reward_range.get("min_gold", 10)
	var max_gold = reward_range.get("max_gold", 50)
	var multiplier = reward_range.get("multiplier", 1.0)

	# Sample reward in range
	var gold_reward = randi_range(min_gold, max_gold)
	var exp_reward = int(gold_reward * 0.5)

	# Critical success bonus (%50 extra) - 10% chance
	if randf() < 0.1:
		gold_reward = int(gold_reward * 1.5)
		print("[DungeonManager] CRITICAL SUCCESS! Gold x1.5")

	instance.rewards = {
		"gold": gold_reward,
		"exp": exp_reward
	}
	instance.loot = loot_items

	# Apply to player
	player_data["gold"] = player_data.get("gold", 0) + gold_reward
	player_data["exp"] = player_data.get("exp", 0) + exp_reward

	print("[DungeonManager] Success rewards: %d gold, %d exp, %d items (sampled range: %d-%d, mult=%s)" % [
		gold_reward, exp_reward, loot_items.size(), min_gold, max_gold, str(multiplier)
	])

## 7. Başarısızlık ödülleri - Hastanelik riski
func _calculate_failure_rewards(instance: DungeonInstance, player_data: Dictionary) -> void:
	# Başarısızlıkta ödül YOK - sadece hastanelik riski
	instance.rewards = {
		"gold": 0,
		"exp": 0
	}
	instance.loot = []

	# Oyuncu ödül almaz
	print("[DungeonManager] Failure - NO rewards. Hospital risk: %s" % ("YES" if _should_hospitalize(instance) else "NO"))

## 8. Loot generation
func _generate_loot(dungeon_id: String) -> Array[String]:
	var loot: Array[String] = []
	var loot_table = LOOT_TABLES.get(dungeon_id, {})
	
	if loot_table.is_empty():
		return loot
	
	# Her loot item için %40 şans
	for item_id in loot_table.keys():
		if randf() < 0.4:
			loot.append(item_id)
	
	return loot

## 9. Loot table loader
func _load_loot_tables() -> void:
	# Basit loot tables - gerçek veri yapılandırma dosyasından gelir
	LOOT_TABLES = {
		"dungeon_dark_forest": {
			"steel_sword": 0.3,
			"iron_armor": 0.3,
			"major_energy_potion": 0.4
		},
		"dungeon_cursed_tomb": {
			"cursed_ring": 0.2,
			"ancient_scroll": 0.3,
			"elixir_of_wisdom": 0.4
		},
		"dungeon_dragon_lair": {
			"dragon_scale": 0.1,
			"legendary_sword": 0.15,
			"dragon_heart": 0.2
		}
	}
	print("[DungeonManager] Loot tables loaded: %d tables" % LOOT_TABLES.size())

# Accessor for loot tables
func get_loot_table(dungeon_id: String) -> Dictionary:
	return LOOT_TABLES.get(dungeon_id, {})

# Compute reward range from dungeon definition and player context
# Uses dungeon's explicit min/max gold and applies modifiers for danger, gear, level and season
const DANGER_REWARD_WEIGHT = 0.5
const GEAR_REWARD_WEIGHT = 0.2
const FAILURE_REWARD_FACTOR = 0.35

func compute_reward_range(dungeon_def: DungeonData.DungeonDefinition, player_data: Dictionary) -> Dictionary:
	# Base range from dungeon definition
	var base_min = int(dungeon_def.min_reward_gold)
	var base_max = int(dungeon_def.max_reward_gold)

	# Use preview to get gear/level/difficulty components
	var preview = preview_success_rate(dungeon_def, player_data)
	var gear_score = preview.get("gear_score", 0.0)
	var _level_penalty = preview.get("level_penalty", 0.0)
	var _difficulty_penalty = preview.get("difficulty_penalty", 0.0)

	# Modifiers
	var danger_mul = 1.0 + (dungeon_def.danger_level / 100.0) * DANGER_REWARD_WEIGHT
	var gear_mul = 1.0 + (gear_score * GEAR_REWARD_WEIGHT)
	var level_mul = max(0.5, 1.0 - _level_penalty) # don't drop below 50%

	# Season multiplier
	var season_mul = 1.0
	if Config and Config.has_key("season"):
		var active = Config.get_nested("season.active_events", {})
		if typeof(active) == TYPE_DICTIONARY and active.has("loot_multiplier"):
			season_mul = float(active.get("loot_multiplier", 1.0))

	var final_mul = danger_mul * gear_mul * level_mul * season_mul

	var min_gold = int(base_min * final_mul)
	var max_gold = int(base_max * final_mul)
	var expected = int(float(min_gold + max_gold) / 2.0)

	return {
		"min_gold": min_gold,
		"max_gold": max_gold,
		"expected": expected,
		"multiplier": final_mul,
		"components": {
			"danger_mul": danger_mul,
			"gear_mul": gear_mul,
			"level_mul": level_mul,
			"season_mul": season_mul
		}
	}

# Compute reward range from a DungeonInstance (uses instance min/max if available)
func compute_reward_range_from_instance(instance: DungeonInstance, player_data: Dictionary) -> Dictionary:
	var fake_def = DungeonData.DungeonDefinition.new(instance.dungeon_id, instance.dungeon_name, "DUNGEON")
	# Override base min/max with instance values (DungeonInstance exposes fields, not a Dictionary)
	if instance:
		# Only override if instance fields look valid (>0)
		if typeof(instance.min_reward_gold) != TYPE_NIL and int(instance.min_reward_gold) > 0:
			fake_def.min_reward_gold = int(instance.min_reward_gold)
		if typeof(instance.max_reward_gold) != TYPE_NIL and int(instance.max_reward_gold) > 0:
			fake_def.max_reward_gold = int(instance.max_reward_gold)
	# Keep danger_level from dungeon definition (no instance override by duration for now)
	return compute_reward_range(fake_def, player_data)

# Estimate reward range using current State if available
func estimate_reward_range(dungeon_def: DungeonData.DungeonDefinition) -> Dictionary:
	var player_data = {}
	if State and State.has_method("get_player_data"):
		player_data = State.get_player_data()
	if player_data.is_empty():
		# Use defaults
		player_data = {"level": 1, "equipped_weapon": {}, "equipped_armor": {}}
	return compute_reward_range(dungeon_def, player_data)

## Helper: aktif dungeon bul
func _find_active_dungeon(instance_id: String) -> DungeonInstance:
	for player_id in active_dungeons.keys():
		var inst = active_dungeons[player_id]
		if inst.id == instance_id:
			return inst
	return null

## Test metodu
func test_dungeon_flow() -> void:
	print("\n=== Dungeon Manager Test ===")
	
	# Test dungeon definition
	var dungeon = DungeonData.DungeonDefinition.new(
		"test_dungeon",
		"Test Zindanı",
		"DUNGEON"
	)
	dungeon.required_level = 1
	dungeon.energy_cost = 20
	dungeon.danger_level = 50
	dungeon.base_success_rate = 0.5
	
	# Test player
	var player = {
		"id": "player_test_1",
		"level": 10,
		"energy": 100,
		"gold": 5000,
		"exp": 0,
		"equipped_weapon": {"power": 20, "rarity": "rare"},
		"equipped_armor": {"defense": 15, "rarity": "common"}
	}
	
	# Start dungeon
	var start_result = start_dungeon(dungeon, player)
	if not start_result.get("success", false):
		print("ERROR: %s" % start_result.get("error", "Unknown"))
		return
	
	var instance_data = start_result.get("data", {})
	var instance = DungeonInstance.from_dict(instance_data)
	
	# Resolve dungeon
	var resolve_result = resolve_dungeon(instance.id, player)
	if resolve_result.get("success", false):
		var resolved_data = resolve_result.get("data", {})
		print("\nResult:")
		print("  Success: %s" % resolved_data.get("actual_success"))
		print("  Rewards: %s" % resolved_data.get("rewards"))
		print("  Hospitalized: %s" % resolved_data.get("is_hospitalized"))
		print("  Player gold: %d" % player.get("gold", 0))
