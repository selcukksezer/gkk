extends Control
## Production Screen
## Building and resource production

@onready var building_tabs = $BuildingTabs
@onready var production_queue = $ProductionQueue/ScrollContainer/VBoxContainer
@onready var building_info = $BuildingInfo

@onready var start_button = $StartProductionButton
@onready var collect_button = $CollectButton
@onready var upgrade_button = $UpgradeButton
@onready var back_button = $BackButton

var _current_building: String = "farm"
var _queue_item_scene = preload("res://scenes/prefabs/ProductionQueueItem.tscn")

# Building types
const BUILDINGS = ["farm", "mine", "workshop", "alchemy_lab", "enchanting_tower"]

func _ready() -> void:
	# Connect signals
	start_button.pressed.connect(_on_start_production)
	collect_button.pressed.connect(_on_collect)
	upgrade_button.pressed.connect(_on_upgrade)
	back_button.pressed.connect(_on_back_pressed)
	
	# Track screen
	Telemetry.track_screen("production")
	
	# Load production data
	_load_production()

func _load_production() -> void:
	var result = await Network.http_get("/production")
	_on_production_loaded(result)

func _on_production_loaded(result: Dictionary) -> void:
	if not result.success:
		print("[Production] Failed to load production")
		return
	
	var data = result.data
	
	# Update building info
	_update_building_info(data.get("buildings", {}))
	
	# Update queue
	_update_production_queue(data.get("queue", []))

func _update_building_info(buildings: Dictionary) -> void:
	var building = buildings.get(_current_building, {})
	
	var level = building.get("level", 1)
	var production_speed = building.get("production_speed", 1.0)
	var capacity = building.get("capacity", 10)
	
	building_info.text = "%s\nLevel: %d\nSpeed: %.1fx\nCapacity: %d" % [
		StringUtils.capitalize_first(_current_building.to_lower()),
		level,
		production_speed,
		capacity
	]

func _update_production_queue(queue: Array) -> void:
	# Clear queue
	for child in production_queue.get_children():
		child.queue_free()
	
	# Show queue items
	for queue_item in queue:
		var item = _queue_item_scene.instantiate()
		production_queue.add_child(item)
		item.set_data(queue_item)

func _on_start_production() -> void:
	# TODO: Show recipe selection dialog
	var recipe_id = "iron_sword_recipe"
	
	var body = {
		"building_type": _current_building,
		"recipe_id": recipe_id
	}
	
	var result = await Network.http_post("/production/start", body)
	_on_production_started(result)

func _on_production_started(result: Dictionary) -> void:
	if result.success:
		print("[Production] Production started")
		_load_production()  # Refresh
	else:
		print("[Production] Failed to start production: ", result.get("error", ""))

func _on_collect() -> void:
	var body = {
		"building_type": _current_building
	}
	
	var result = await Network.http_post("/production/collect", body)
	_on_collected(result)

func _on_collected(result: Dictionary) -> void:
	if result.success:
		print("[Production] Items collected")
		_load_production()  # Refresh
	else:
		print("[Production] Failed to collect: ", result.get("error", ""))

func _on_upgrade() -> void:
	var body = {
		"building_type": _current_building
	}
	
	var result = await Network.http_post("/production/upgrade", body)
	_on_upgraded(result)

func _on_upgraded(result: Dictionary) -> void:
	if result.success:
		print("[Production] Building upgraded")
		_load_production()  # Refresh
	else:
		print("[Production] Failed to upgrade: ", result.get("error", ""))

func _on_back_pressed() -> void:
	Scenes.change_scene("res://scenes/ui/MainMenu.tscn")
