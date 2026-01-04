class_name PlayerData
extends Resource
## Player Data Model
## Represents player information and stats

@export var player_id: String = ""
@export var username: String = ""
@export var display_name: String = ""
@export var level: int = 1
@export var experience: int = 0
@export var experience_to_next_level: int = 100

## Currencies
@export var gold: int = 0
@export var gems: int = 0
@export var season_points: int = 0

## Energy system
@export var current_energy: int = 100
@export var max_energy: int = 100
@export var last_energy_regen: int = 0  # Unix timestamp

## Addiction system
@export var tolerance: int = 0  # 0-100
@export var last_tolerance_decay: int = 0  # Unix timestamp

## Combat stats
@export var power: int = 100  # Combat power
@export var defense: int = 50
@export var attack: int = 50
@export var health: int = 100
@export var max_health: int = 100

## PvP
@export var reputation: int = 0  # -100 to +100
@export var pvp_wins: int = 0
@export var pvp_losses: int = 0
@export var pvp_rank: int = 0

## Hospital
@export var in_hospital: bool = false
@export var hospital_release_time: int = 0  # Unix timestamp

## Guild
@export var guild_id: String = ""
@export var guild_role: String = ""  # lord, commander, member, apprentice

## Stats
@export var total_quests_completed: int = 0
@export var total_pvp_battles: int = 0
@export var total_gold_earned: int = 0
@export var total_items_crafted: int = 0

## Meta
@export var created_at: int = 0
@export var last_login: int = 0
@export var last_save: int = 0

## Titles/Achievements
@export var titles: Array[String] = []
@export var active_title: String = ""

## Cosmetics
@export var avatar_url: String = ""
@export var frame: String = ""
@export var badge: String = ""

## Create from dictionary
static func from_dict(data: Dictionary) -> PlayerData:
	var player = PlayerData.new()
	
	player.player_id = data.get("id", "")
	player.username = data.get("username", "")
	player.display_name = data.get("display_name", data.get("username", ""))
	player.level = data.get("level", 1)
	player.experience = data.get("experience", 0)
	player.experience_to_next_level = data.get("experience_to_next_level", 100)
	
	player.gold = data.get("gold", 0)
	player.gems = data.get("gems", 0)
	player.season_points = data.get("season_points", 0)
	
	player.current_energy = data.get("current_energy", 100)
	player.max_energy = data.get("max_energy", 100)
	player.last_energy_regen = data.get("last_energy_regen", 0)
	
	player.tolerance = data.get("tolerance", 0)
	player.last_tolerance_decay = data.get("last_tolerance_decay", 0)
	
	player.power = data.get("power", 100)
	player.defense = data.get("defense", 50)
	player.attack = data.get("attack", 50)
	player.health = data.get("health", 100)
	player.max_health = data.get("max_health", 100)
	
	player.reputation = data.get("reputation", 0)
	player.pvp_wins = data.get("pvp_wins", 0)
	player.pvp_losses = data.get("pvp_losses", 0)
	player.pvp_rank = data.get("pvp_rank", 0)
	
	player.in_hospital = data.get("in_hospital", false)
	player.hospital_release_time = data.get("hospital_release_time", 0)
	
	player.guild_id = data.get("guild_id", "")
	player.guild_role = data.get("guild_role", "")
	
	player.total_quests_completed = data.get("total_quests_completed", 0)
	player.total_pvp_battles = data.get("total_pvp_battles", 0)
	player.total_gold_earned = data.get("total_gold_earned", 0)
	player.total_items_crafted = data.get("total_items_crafted", 0)
	
	player.created_at = data.get("created_at", 0)
	player.last_login = data.get("last_login", 0)
	player.last_save = data.get("last_save", 0)
	
	if data.has("titles"):
		player.titles.assign(data.titles)
	player.active_title = data.get("active_title", "")
	
	player.avatar_url = data.get("avatar_url", "")
	player.frame = data.get("frame", "")
	player.badge = data.get("badge", "")
	
	return player

## Convert to dictionary
func to_dict() -> Dictionary:
	return {
		"id": player_id,
		"username": username,
		"display_name": display_name,
		"level": level,
		"experience": experience,
		"experience_to_next_level": experience_to_next_level,
		"gold": gold,
		"gems": gems,
		"season_points": season_points,
		"current_energy": current_energy,
		"max_energy": max_energy,
		"last_energy_regen": last_energy_regen,
		"tolerance": tolerance,
		"last_tolerance_decay": last_tolerance_decay,
		"power": power,
		"defense": defense,
		"attack": attack,
		"health": health,
		"max_health": max_health,
		"reputation": reputation,
		"pvp_wins": pvp_wins,
		"pvp_losses": pvp_losses,
		"pvp_rank": pvp_rank,
		"in_hospital": in_hospital,
		"hospital_release_time": hospital_release_time,
		"guild_id": guild_id,
		"guild_role": guild_role,
		"total_quests_completed": total_quests_completed,
		"total_pvp_battles": total_pvp_battles,
		"total_gold_earned": total_gold_earned,
		"total_items_crafted": total_items_crafted,
		"created_at": created_at,
		"last_login": last_login,
		"last_save": last_save,
		"titles": titles,
		"active_title": active_title,
		"avatar_url": avatar_url,
		"frame": frame,
		"badge": badge
	}

## Calculate experience required for next level
func calculate_exp_for_level(lvl: int) -> int:
	return int(100 * pow(1.15, lvl - 1))

## Check if player can level up
func can_level_up() -> bool:
	return experience >= experience_to_next_level

## Level up player
func level_up() -> void:
	if not can_level_up():
		return
	
	level += 1
	experience -= experience_to_next_level
	experience_to_next_level = calculate_exp_for_level(level)
	
	# Stat increases
	max_health += 10
	health = max_health
	attack += 5
	defense += 5
	power += 10

## Get reputation status
func get_reputation_status() -> String:
	if reputation >= 80:
		return "Legendary Hero"
	elif reputation >= 50:
		return "Hero"
	elif reputation >= 20:
		return "Noble"
	elif reputation >= -20:
		return "Citizen"
	elif reputation >= -50:
		return "Scoundrel"
	elif reputation >= -80:
		return "Bandit"
	else:
		return "Outlaw"

## Check if player is bandit (target for all)
func is_bandit() -> bool:
	return reputation <= -50
