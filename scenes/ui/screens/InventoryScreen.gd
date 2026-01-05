extends Control
## InventoryScreen.gd - Player inventory management UI
## Shows equipped items, inventory grid, item details, and actions

signal item_selected(item: ItemData)
signal item_equipped(item: ItemData, slot: String)
signal item_unequipped(slot: String)
signal item_used(item: ItemData)

# Import required classes
const InventoryManager = preload("res://autoload/InventoryManager.gd")

@onready var equipped_container: GridContainer = $MarginContainer/VBoxContainer/HBoxContainer/EquippedContainer
@onready var inventory_grid: GridContainer = $MarginContainer/VBoxContainer/HBoxContainer/InventoryContainer/ScrollContainer/InventoryGrid
@onready var item_details_panel: PanelContainer = $MarginContainer/VBoxContainer/ItemDetailsPanel
@onready var item_name_label: Label = $MarginContainer/VBoxContainer/ItemDetailsPanel/VBoxContainer/ItemNameLabel
@onready var item_description_label: Label = $MarginContainer/VBoxContainer/ItemDetailsPanel/VBoxContainer/ItemDescriptionLabel
@onready var item_stats_label: Label = $MarginContainer/VBoxContainer/ItemDetailsPanel/VBoxContainer/ItemStatsLabel
@onready var use_button: Button = $MarginContainer/VBoxContainer/ItemDetailsPanel/VBoxContainer/ActionButtons/UseButton
@onready var equip_button: Button = $MarginContainer/VBoxContainer/ItemDetailsPanel/VBoxContainer/ActionButtons/EquipButton
@onready var sell_button: Button = $MarginContainer/VBoxContainer/ItemDetailsPanel/VBoxContainer/ActionButtons/SellButton
@onready var filter_tabs: TabContainer = $MarginContainer/VBoxContainer/FilterTabs

var inventory_manager: InventoryManager
var selected_item: ItemData = null
var equipped_items: Dictionary = {}

const SLOT_SCENE = preload("res://scenes/prefabs/ItemSlot.tscn")

func _ready() -> void:
	print("[InventoryScreen] Ready")

	inventory_manager = InventoryManager.new()

	# Connect signals
	State.connect("inventory_updated", _on_inventory_updated)
	State.connect("equipment_updated", _on_equipment_updated)

	# Setup filter tabs
	_setup_filter_tabs()

	# Load initial inventory
	_refresh_inventory()

func _setup_filter_tabs() -> void:
	# Add filter tabs for different item types
	var all_tab = TabContainer.new()
	all_tab.name = "All"
	filter_tabs.add_child(all_tab)

	var weapons_tab = TabContainer.new()
	weapons_tab.name = "Weapons"
	filter_tabs.add_child(weapons_tab)

	var armor_tab = TabContainer.new()
	armor_tab.name = "Armor"
	filter_tabs.add_child(armor_tab)

	var consumables_tab = TabContainer.new()
	consumables_tab.name = "Consumables"
	filter_tabs.add_child(consumables_tab)

	var materials_tab = TabContainer.new()
	materials_tab.name = "Materials"
	filter_tabs.add_child(materials_tab)

	filter_tabs.connect("tab_changed", _on_filter_changed)

func _refresh_inventory() -> void:
	# Clear existing slots
	for child in inventory_grid.get_children():
		child.queue_free()

	for child in equipped_container.get_children():
		child.queue_free()

	# Get all items
	var all_items = State.get_all_items_data()

	# Create equipped item slots
	_create_equipped_slots()

	# Create inventory slots
	for item in all_items:
		if item.quantity > 0:  # Only show items with quantity > 0
			var slot = SLOT_SCENE.instantiate()
			slot.set_item(item)
			slot.connect("slot_clicked", _on_slot_clicked)
			inventory_grid.add_child(slot)

func _create_equipped_slots() -> void:
	# Equipment slots in order: Weapon, Helmet, Chest, Legs, Boots, Gloves, Ring, Amulet, Belt
	var equipment_slots = ["weapon", "helmet", "chest", "legs", "boots", "gloves", "ring", "amulet", "belt"]

	for slot_name in equipment_slots:
		var slot = SLOT_SCENE.instantiate()
		slot.set_equipment_slot(slot_name)
		slot.connect("slot_clicked", _on_equipment_slot_clicked)
		equipped_container.add_child(slot)

func _on_slot_clicked(item: ItemData) -> void:
	selected_item = item
	_update_item_details(item)

func _on_equipment_slot_clicked(slot_name: String) -> void:
	# Handle equipment slot clicks (unequip, etc.)
	if equipped_items.has(slot_name):
		var item = equipped_items[slot_name]
		selected_item = item
		_update_item_details(item)
	else:
		# Empty slot selected
		selected_item = null
		_clear_item_details()

func _update_item_details(item: ItemData) -> void:
	if not item:
		_clear_item_details()
		return

	item_details_panel.visible = true
	item_name_label.text = item.get_enhancement_display() + " " + item.name
	item_name_label.add_theme_color_override("font_color", item.get_rarity_color())

	item_description_label.text = item.description

	# Show item stats
	var stats_text = ""
	if item.is_equipment():
		stats_text += "Attack: %d\n" % item.get_total_attack()
		stats_text += "Defense: %d\n" % item.get_total_defense()
		stats_text += "Health: %d\n" % item.get_total_health()
		stats_text += "Power: %d\n" % item.get_total_power()
		stats_text += "Required Level: %d\n" % item.required_level

	if item.is_consumable():
		if item.energy_restore > 0:
			stats_text += "Energy Restore: +%d\n" % item.energy_restore
		if item.heal_amount > 0:
			stats_text += "Heal Amount: +%d\n" % item.heal_amount

	if item.is_material():
		stats_text += "Quantity: %d\n" % item.quantity

	item_stats_label.text = stats_text

	# Update action buttons
	use_button.visible = item.is_consumable()
	equip_button.visible = item.is_equipment() and not _is_item_equipped(item)
	sell_button.visible = item.is_tradeable

func _clear_item_details() -> void:
	item_details_panel.visible = false
	selected_item = null

func _is_item_equipped(item: ItemData) -> bool:
	return equipped_items.values().has(item)

func _on_use_button_pressed() -> void:
	if not selected_item:
		return

	var result = await inventory_manager.use_item(selected_item)
	if result.success:
		item_used.emit(selected_item)
		_refresh_inventory()
	else:
		_show_error(result.error)

func _on_equip_button_pressed() -> void:
	if not selected_item:
		return

	# Determine equipment slot
	var slot = _get_equipment_slot_for_item(selected_item)
	if slot.is_empty():
		return

	var result = await inventory_manager.equip_item(selected_item.item_id)
	if result.success:
		item_equipped.emit(selected_item, slot)
		_refresh_inventory()
	else:
		_show_error(result.error)

func _on_sell_button_pressed() -> void:
	if not selected_item:
		return

	# TODO: Implement sell functionality
	_show_error("Sell functionality not implemented yet")

func _get_equipment_slot_for_item(item: ItemData) -> String:
	match item.equip_slot:
		ItemData.EquipSlot.WEAPON:
			return "weapon"
		ItemData.EquipSlot.HELMET:
			return "helmet"
		ItemData.EquipSlot.CHEST:
			return "chest"
		ItemData.EquipSlot.LEGS:
			return "legs"
		ItemData.EquipSlot.BOOTS:
			return "boots"
		ItemData.EquipSlot.GLOVES:
			return "gloves"
		ItemData.EquipSlot.RING:
			return "ring"
		ItemData.EquipSlot.AMULET:
			return "amulet"
		ItemData.EquipSlot.BELT:
			return "belt"
		_:
			return ""

func _on_filter_changed(tab_index: int) -> void:
	var filter_type = filter_tabs.get_tab_title(tab_index)
	_refresh_inventory_with_filter(filter_type)

func _refresh_inventory_with_filter(filter_type: String) -> void:
	# Clear existing slots
	for child in inventory_grid.get_children():
		child.queue_free()

	# Get filtered items
	var all_items = State.get_all_items_data()
	var filtered_items = []

	for item in all_items:
		if item.quantity <= 0:
			continue

		var should_include = false
		match filter_type:
			"All":
				should_include = true
			"Weapons":
				should_include = item.is_weapon()
			"Armor":
				should_include = item.is_armor()
			"Consumables":
				should_include = item.is_consumable()
			"Materials":
				should_include = item.is_material()

		if should_include:
			filtered_items.append(item)

	# Create inventory slots
	for item in filtered_items:
		var slot = SLOT_SCENE.instantiate()
		slot.set_item(item)
		slot.connect("slot_clicked", _on_slot_clicked)
		inventory_grid.add_child(slot)

func _on_inventory_updated() -> void:
	_refresh_inventory()

func _on_equipment_updated() -> void:
	_refresh_inventory()

func _show_error(message: String) -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "Error"
	dialog.dialog_text = message
	add_child(dialog)
	dialog.popup_centered()
