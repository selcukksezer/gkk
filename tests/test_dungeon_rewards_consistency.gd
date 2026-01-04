extends Node

func _ready():
	print("[TEST] Running dungeon rewards consistency test")
	var dm = DungeonManager.new()
	add_child(dm)
	var player = {"id":"player_test","level":5, "equipped_weapon": {"power":40}, "equipped_armor": {"defense":30}, "gold": 0, "exp": 0}
	var inst = DungeonInstance.new(player.id, "dungeon_test", "Test Zindanı", 10, 0.5, 600)
	inst.min_reward_gold = 100
	inst.max_reward_gold = 300

	var ok = true
	for i in range(20):
		dm._calculate_success_rewards(inst, player)
		var g = inst.rewards.get("gold", 0)
		if g < inst.min_reward_gold or g > inst.max_reward_gold*2: # allow critical x1.5 maybe push above max, accept up to x2
			print("[TEST] Reward out of expected bounds: %d (min=%d, max=%d)" % [g, inst.min_reward_gold, inst.max_reward_gold])
			ok = false
			break

	assert(ok)
	print("[TEST] dungeon rewards consistency OK")
	get_tree().quit()