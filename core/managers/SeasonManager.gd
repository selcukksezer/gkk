extends Node
## Season Manager
## Handles competitive seasons, leaderboards, battle pass, and rewards

signal season_started(season_id: String, end_date: int)
signal season_ended(season_id: String, results: Dictionary)
signal leaderboard_updated(category: String, rankings: Array)
signal battle_pass_level_up(new_level: int, rewards: Array)
signal reward_claimed(tier: int, reward: Dictionary)

# Leaderboard categories
enum LeaderboardCategory {
	LEVEL,
	POWER,
	PVP_RATING,
	GOLD,
	GUILD_POWER
}

const CATEGORY_NAMES = {
	LeaderboardCategory.LEVEL: "level",
	LeaderboardCategory.POWER: "power",
	LeaderboardCategory.PVP_RATING: "pvp_rating",
	LeaderboardCategory.GOLD: "gold",
	LeaderboardCategory.GUILD_POWER: "guild_power"
}

# Battle pass tiers and rewards
const BATTLE_PASS_TIERS = 100
const XP_PER_TIER = 1000

# Current season data
var current_season: Dictionary = {}
var leaderboards: Dictionary = {}
var battle_pass_progress: Dictionary = {}
var claimed_rewards: Array = []

func _ready() -> void:
	# Connect to state updates
	State.connect("player_updated", _on_player_updated)
	
	# Load season data
	load_current_season()

func load_current_season() -> void:
	"""Load current season information"""
	var response = await Network.http_get("/season/current")
	
	if response.success:
		current_season = response.data.get("season", {})
		battle_pass_progress = response.data.get("battle_pass", {})
		claimed_rewards = response.data.get("claimed_rewards", [])
		
		var season_id = current_season.get("id", "")
		var end_date = current_season.get("end_date", 0)
		season_started.emit(season_id, end_date)

func get_season_info() -> Dictionary:
	"""Get current season information"""
	return {
		"id": current_season.get("id", ""),
		"name": current_season.get("name", "Season 1"),
		"start_date": current_season.get("start_date", 0),
		"end_date": current_season.get("end_date", 0),
		"days_remaining": _calculate_days_remaining(),
		"is_active": _is_season_active()
	}

func get_leaderboard(category: String, limit: int = 100, offset: int = 0) -> void:
	"""Load leaderboard for a category"""
	var response = await Network.http_get("/season/leaderboard")
	
	if response.success:
		var rankings = response.data.get("rankings", [])
		leaderboards[category] = rankings
		leaderboard_updated.emit(category, rankings)

func get_player_rank(category: String) -> Dictionary:
	"""Get player's rank in a leaderboard category"""
	var response = await Network.http_get("/season/rank")
	
	if response.success:
		return response.data.get("rank_info", {})
	
	return {"rank": 0, "value": 0}

func get_top_players(category: String, count: int = 10) -> Array:
	"""Get top players from leaderboard"""
	if leaderboards.has(category):
		var rankings = leaderboards[category]
		return rankings.slice(0, min(count, rankings.size()))
	
	return []

func get_battle_pass_info() -> Dictionary:
	"""Get battle pass progression information"""
	var current_level = battle_pass_progress.get("level", 0)
	var current_xp = battle_pass_progress.get("xp", 0)
	var is_premium = battle_pass_progress.get("is_premium", false)
	
	var xp_for_next = XP_PER_TIER
	var progress = (current_xp % XP_PER_TIER) / float(XP_PER_TIER)
	
	return {
		"level": current_level,
		"xp": current_xp,
		"xp_for_next": xp_for_next,
		"progress": progress,
		"is_premium": is_premium,
		"max_level": BATTLE_PASS_TIERS,
		"rewards_available": _count_unclaimed_rewards(current_level)
	}

func add_battle_pass_xp(amount: int) -> void:
	"""Add XP to battle pass"""
	var current_xp = battle_pass_progress.get("xp", 0)
	var current_level = battle_pass_progress.get("level", 0)
	
	var new_xp = current_xp + amount
	var new_level = int(new_xp / XP_PER_TIER)
	
	if new_level > current_level:
		# Level up
		battle_pass_progress["level"] = new_level
		battle_pass_progress["xp"] = new_xp
		
		var rewards = _get_tier_rewards(new_level)
		battle_pass_level_up.emit(new_level, rewards)
	else:
		battle_pass_progress["xp"] = new_xp

func claim_battle_pass_reward(tier: int) -> Dictionary:
	"""Claim a battle pass reward"""
	# Check if already claimed
	if tier in claimed_rewards:
		return {"success": false, "error": "Reward already claimed"}
	
	# Check if tier is unlocked
	var current_level = battle_pass_progress.get("level", 0)
	if tier > current_level:
		return {"success": false, "error": "Tier not unlocked"}
	
	# Send to backend
	var response = await Network.http_post("/season/claim_reward", {
		"tier": tier
	})
	
	if response.success:
		var reward = response.data.get("reward", {})
		claimed_rewards.append(tier)
		
		# Add items to inventory
		_process_reward(reward)
		
		reward_claimed.emit(tier, reward)
	
	return response

func purchase_battle_pass() -> Dictionary:
	"""Purchase premium battle pass"""
	var response = await Network.http_post("/season/purchase_battle_pass", {})
	
	if response.success:
		battle_pass_progress["is_premium"] = true
		
		# Deduct gems
		var cost = response.data.get("cost", 0)
		State.add_gems(-cost)
	
	return response

func get_tier_rewards(tier: int) -> Dictionary:
	"""Get rewards for a specific tier"""
	var response = await Network.http_get("/season/tier_rewards")
	
	if response.success:
		return response.data.get("rewards", {})
	
	return {}

func get_season_rewards(rank: int, category: String) -> Array:
	"""Get end-of-season rewards based on rank"""
	var rewards = []
	
	# Top 1
	if rank == 1:
		rewards = [
			{"type": "gems", "amount": 5000},
			{"type": "gold", "amount": 100000},
			{"type": "item", "id": "legendary_chest", "quantity": 5},
			{"type": "title", "id": "season_champion"}
		]
	# Top 10
	elif rank <= 10:
		rewards = [
			{"type": "gems", "amount": 2000},
			{"type": "gold", "amount": 50000},
			{"type": "item", "id": "epic_chest", "quantity": 3}
		]
	# Top 100
	elif rank <= 100:
		rewards = [
			{"type": "gems", "amount": 500},
			{"type": "gold", "amount": 20000},
			{"type": "item", "id": "rare_chest", "quantity": 2}
		]
	# Top 1000
	elif rank <= 1000:
		rewards = [
			{"type": "gems", "amount": 100},
			{"type": "gold", "amount": 5000},
			{"type": "item", "id": "common_chest", "quantity": 1}
		]
	
	return rewards

func get_player_season_stats() -> Dictionary:
	"""Get player's season statistics"""
	var stats = State.player_data.get("season_stats", {})
	
	return {
		"highest_rank": stats.get("highest_rank", 0),
		"current_rank": stats.get("current_rank", 0),
		"pvp_wins": stats.get("pvp_wins", 0),
		"pvp_losses": stats.get("pvp_losses", 0),
		"quests_completed": stats.get("quests_completed", 0),
		"gold_earned": stats.get("gold_earned", 0),
		"level_gained": stats.get("level_gained", 0)
	}

func _calculate_days_remaining() -> int:
	"""Calculate days remaining in season"""
	var end_date = current_season.get("end_date", 0)
	var current_time = Time.get_unix_time_from_system()
	
	if end_date <= current_time:
		return 0
	
	var seconds_remaining = end_date - current_time
	return int(seconds_remaining / 86400) # 86400 seconds in a day

func _is_season_active() -> bool:
	"""Check if season is currently active"""
	return _calculate_days_remaining() > 0

func _get_tier_rewards(tier: int) -> Array:
	"""Get rewards for a battle pass tier"""
	# This would normally come from backend
	# For now, return placeholder
	var rewards = []
	
	# Free rewards every tier
	rewards.append({"type": "gold", "amount": 100 * tier})
	
	# Premium rewards every 5 tiers
	if tier % 5 == 0 and battle_pass_progress.get("is_premium", false):
		rewards.append({"type": "gems", "amount": 50})
	
	# Special rewards at milestones
	if tier == 25:
		rewards.append({"type": "item", "id": "rare_chest", "quantity": 1})
	elif tier == 50:
		rewards.append({"type": "item", "id": "epic_chest", "quantity": 1})
	elif tier == 75:
		rewards.append({"type": "item", "id": "legendary_chest", "quantity": 1})
	elif tier == 100:
		rewards.append({"type": "item", "id": "mythic_chest", "quantity": 1})
		rewards.append({"type": "title", "id": "season_master"})
	
	return rewards

func _count_unclaimed_rewards(current_level: int) -> int:
	"""Count unclaimed rewards up to current level"""
	var count = 0
	
	for tier in range(1, current_level + 1):
		if tier not in claimed_rewards:
			count += 1
	
	return count

func _process_reward(reward: Dictionary) -> void:
	"""Process and add reward to player inventory/currency"""
	var reward_type = reward.get("type", "")
	
	match reward_type:
		"gold":
			State.add_gold(reward.get("amount", 0))
		"gems":
			State.add_gems(reward.get("amount", 0))
		"item":
			State.add_to_inventory(reward.get("id", ""), reward.get("quantity", 1))
		"xp":
			State.add_xp(reward.get("amount", 0))
		"title":
			# Add title to player
			if not State.player_data.has("titles"):
				State.player_data["titles"] = []
			var title_id = reward.get("id", "")
			if title_id not in State.player_data.titles:
				State.player_data.titles.append(title_id)

func _on_player_updated() -> void:
	"""Handle player data updates"""
	# Update battle pass progress if changed
	if State.player_data.has("battle_pass"):
		battle_pass_progress = State.player_data.battle_pass
