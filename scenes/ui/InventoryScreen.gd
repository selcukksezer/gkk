extends Control
## Inventory Screen
## Displays player inventory and equipment

@onready var equipment_panel = $EquipmentPanel
@onready var inventory_grid = $InventoryPanel/ScrollContainer/GridContainer
@onready var item_details = $ItemDetailsPanel

# Equipment slots
@onready var weapon_slot = $EquipmentPanel/WeaponSlot
@onready var helmet_slot = $EquipmentPanel/HelmetSlot
@onready var chest_slot = $EquipmentPanel/ChestSlot
@onready var legs_slot = $EquipmentPanel/LegsSlot
@onready var boots_slot = $EquipmentPanel/BootsSlot

# Filter buttons
@onready var filter_all = $FilterPanel/AllButton
@onready var filter_weapon = $FilterPanel/WeaponButton
@onready var filter_armor = $FilterPanel/ArmorButton
@onready var filter_consumable = $FilterPanel/ConsumableButton
@onready var filter_material = $FilterPanel/MaterialButton

# Stats display
@onready var total_power_label = $StatsPanel/Power/Value
@onready var total_defense_label = $StatsPanel/Defense/Value

@onready var back_button = $BackButton

var _current_filter: String = "all"
var _selected_item: InventoryItemData = InventoryItemData.new()
var _item_slot_scene = preload("res://scenes/prefabs/ItemSlot.tscn")

func _ready() -> void:
	# Connect buttons
	back_button.pressed.connect(_on_back_pressed)
	filter_all.pressed.connect(func(): _set_filter("all"))
	filter_weapon.pressed.connect(func(): _set_filter("weapon"))
	filter_armor.pressed.connect(func(): _set_filter("armor"))
	filter_consumable.pressed.connect(func(): _set_filter("consumable"))
	filter_material.pressed.connect(func(): _set_filter("material"))
	
	# Connect state updates
	State.inventory_updated.connect(_refresh_inventory)
	
	# Track screen
	Telemetry.track_screen("inventory")
	
	# Load inventory
	_load_inventory()

func _load_inventory() -> void:
	# Request inventory from API
	var result = await Network.http_get("/inventory")
	_on_inventory_loaded(result)

func _on_inventory_loaded(result: Dictionary) -> void:
	if not result.success:
		print("[Inventory] Failed to load inventory")
		return
	
	# Parse inventory items
	var items_data = result.data.get("items", [])
	State.inventory.clear()
	
	for item_dict in items_data:
		var inv_item = InventoryItemData.from_dict(item_dict)
		State.inventory.append(inv_item)
	
	_refresh_inventory()
	_update_stats()

func _refresh_inventory() -> void:
	# Clear grid
	for child in inventory_grid.get_children():
		child.queue_free()
	
	# Filter items
	var filtered_items = _filter_items(State.inventory)
	
	# Create item slots
	for inv_item in filtered_items:
		var slot = _item_slot_scene.instantiate()
		inventory_grid.add_child(slot)
		slot.set_item(inv_item)
		slot.clicked.connect(_on_item_clicked.bind(inv_item))

func _filter_items(items: Array) -> Array:
	if _current_filter == "all":
		return items
	
	return items.filter(func(item): 
		# TODO: Get ItemData and check category
		return true
	)

func _set_filter(filter: String) -> void:
	_current_filter = filter
	_refresh_inventory()
	
	# Update button states
	filter_all.button_pressed = (filter == "all")
	filter_weapon.button_pressed = (filter == "weapon")
	filter_armor.button_pressed = (filter == "armor")
	filter_consumable.button_pressed = (filter == "consumable")
	filter_material.button_pressed = (filter == "material")

func _on_item_clicked(inv_item: InventoryItemData) -> void:
	_selected_item = inv_item
	_show_item_details(inv_item)

func _show_item_details(inv_item: InventoryItemData) -> void:
	# TODO: Implement item details panel
	print("[Inventory] Selected item: ", inv_item.item_id)
	
	# Show context menu (equip/unequip/use/sell)
	_show_context_menu(inv_item)

func _show_context_menu(inv_item: InventoryItemData) -> void:
	# TODO: Implement context menu
	pass

func _equip_item(inv_item: InventoryItemData) -> void:
	var slot = inv_item.equipped_slot
	if slot.is_empty():
		# Determine slot from item type
		# TODO: Get ItemData and determine slot
		slot = "weapon"
	
	# API call
	var result = await Network.http_post("/inventory/equip", {
		"inventory_item_id": inv_item.instance_id,
		"slot": slot
	})
	_on_equip_response(result)
	
	Telemetry.track_event("inventory", "equip", {
		"item_id": inv_item.item_id,
		"slot": slot
	})

func _on_equip_response(result: Dictionary) -> void:
	if result.success:
		print("[Inventory] Item equipped successfully")
		_load_inventory()  # Refresh
		_update_stats()
	else:
		print("[Inventory] Failed to equip item")

func _update_stats() -> void:
	# Calculate total power and defense from equipped items
	var total_power = 0
	var total_defense = 0
	
	for inv_item in State.inventory:
		if not inv_item.equipped_slot.is_empty():
			# TODO: Get ItemData and calculate with enhancement
			total_power += 100 + (inv_item.enhancement_level * 30)
			total_defense += 50 + (inv_item.enhancement_level * 20)
	
	total_power_label.text = str(total_power)
	total_defense_label.text = str(total_defense)

func _on_back_pressed() -> void:
	Scenes.change_scene("res://scenes/ui/MainMenu.tscn")
