extends Node

func _ready():
	print("[TEST] Running dungeon telemetry test")
	# Clear telemetry queue
	Telemetry._event_queue.clear()

	var dm = DungeonManager.new()
	add_child(dm)

	# Player and dungeon
	var player = {"id":"player_test", "level":10, "equipped_weapon": {"power":30}, "equipped_armor": {"defense":20}, "gold":0, "exp":0}
	var def = DungeonData.DungeonDefinition.from_dict({
		"id":"dungeon_test",
		"name":"Test Zindanı",
		"difficulty":"DUNGEON",
		"required_level":5,
		"energy_cost":5,
		"danger_level":40,
		"base_success_rate":0.5,
		"estimated_duration_seconds":600
	})

	var res = dm.start_dungeon(def, player)
	assert(res.get("success", false))
	# There should be a started telemetry event
	assert(Telemetry._event_queue.size() >= 1)
	print("[TEST] started event queued: ", Telemetry._event_queue[0])

	# Resolve
	var inst_id = res.data.get("id")
	var r = dm.resolve_dungeon(inst_id, player)
	assert(r.get("success", false))
	# Completed event appended
	assert(Telemetry._event_queue.size() >= 2)
	print("[TEST] completed event queued: ", Telemetry._event_queue[-1])

	get_tree().quit()