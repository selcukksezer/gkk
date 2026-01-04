extends Node

func _ready():
	print("[TEST] Running dungeon preview test")
	var dm = DungeonManager.new()
	add_child(dm)
	# Mock dungeon definition
	var def = DungeonData.DungeonDefinition.from_dict({
		"id":"dungeon_test",
		"name":"Test Zindanı",
		"difficulty":"DUNGEON",
		"required_level":10,
		"energy_cost":5,
		"danger_level":50,
		"base_success_rate":0.45,
		"estimated_duration_seconds":600
	})
	var player = {"level":5, "equipped_weapon": {"power":20}, "equipped_armor": {"defense":10}}
	var preview = dm.preview_success_rate(def, player)
	assert(preview.has("calculated_rate"))
	print("[TEST] preview_calculated_rate=", preview.get("calculated_rate"))
	get_tree().quit()