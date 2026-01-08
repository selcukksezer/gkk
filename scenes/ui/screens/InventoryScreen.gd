extends Control
## InventoryScreen.gd - Player inventory management UI
## Shows equipped items, inventory grid, item details, and actions

signal item_selected(item: ItemData)
signal item_equipped(item: ItemData, slot: String)
signal item_unequipped(slot: String)
signal item_used(item: ItemData)

# Import required classes
const InventoryManager = preload("res://autoload/InventoryManager.gd")

# Safe node lookups to handle scene variants
@onready var equipped_container: GridContainer = get_node_or_null("VBoxContainer/EquippedContainerHolder/EquippedContainer")
@onready var inventory_grid: GridContainer = get_node_or_null("VBoxContainer/ScrollContainer/InventoryGrid")
@onready var item_details_panel: PanelContainer = get_node_or_null("VBoxContainer/ItemDetailsPanel")
@onready var item_name_label: Label = get_node_or_null("VBoxContainer/ItemDetailsPanel/VBoxContainer/ItemNameLabel")
@onready var item_description_label: Label = get_node_or_null("VBoxContainer/ItemDetailsPanel/VBoxContainer/ItemDescriptionLabel")
@onready var item_stats_label: Label = get_node_or_null("VBoxContainer/ItemDetailsPanel/VBoxContainer/ItemStatsLabel")
@onready var use_button: Button = get_node_or_null("VBoxContainer/ItemDetailsPanel/VBoxContainer/ActionButtons/UseButton")
@onready var equip_button: Button = get_node_or_null("VBoxContainer/ItemDetailsPanel/VBoxContainer/ActionButtons/EquipButton")
@onready var sell_button: Button = get_node_or_null("VBoxContainer/ItemDetailsPanel/VBoxContainer/ActionButtons/SellButton")
@onready var filter_bar: HBoxContainer = get_node_or_null("FilterBar")
# Backwards-compatible TabContainer support (if present)
@onready var filter_tabs: TabContainer = get_node_or_null("FilterTabs")

var inventory_manager: InventoryManager
var selected_item: ItemData = null
var equipped_items: Dictionary = {}

const SLOT_SCENE = preload("res://scenes/prefabs/ItemSlot.tscn")

func _ready() -> void:
	print("[InventoryScreen] Ready")

	inventory_manager = InventoryManager.new()

	# Connect signals
	State.connect("inventory_updated", Callable(self, "_on_inventory_updated"))
	# InventoryManager emits equipment signals; listen to those instead of a non-existent State signal
	# Listen to autoload singleton 'Inventory' for equipment changes
	var inventory_singleton = get_node_or_null("/root/Inventory")
	if inventory_singleton:
		inventory_singleton.connect("item_equipped", Callable(self, "_on_equipment_updated"))
		inventory_singleton.connect("item_unequipped", Callable(self, "_on_equipment_updated"))
	else:
		print("[InventoryScreen] Warning: Inventory singleton not found; equipment updates may be missed")

	# Setup filters (supports both TabContainer and HBox FilterBar)
	_setup_filter_tabs()

	# Responsive behaviour: update grid columns when viewport size changes
	if get_viewport():
		get_viewport().size_changed.connect(Callable(self, "_on_viewport_size_changed"))

	# Load initial inventory
	_refresh_inventory()

	# Initial layout adjustment
	_update_grid_columns()

func _setup_filter_tabs() -> void:
	if filter_tabs:
		# Existing TabContainer-based UI
		filter_tabs.clear()
		var tabs = ["All", "Weapons", "Armor", "Consumables", "Materials"]
		for t in tabs:
			filter_tabs.add_tab(t)
		filter_tabs.connect("tab_changed", Callable(self, "_on_filter_changed"))
		return

	if filter_bar:
		# HBox button-based filter bar
		var mapping = {
			"AllButton": "All",
			"WeaponButton": "Weapons",
			"ArmorButton": "Armor",
			"PotionButton": "Consumables",
			"MaterialButton": "Materials"
		}
		for child in filter_bar.get_children():
			if child.name in mapping:
				child.pressed.connect(Callable(self, "_on_filter_button_pressed").bind(mapping[child.name]))
		return

	# No filter UI found, log warning
	print("[InventoryScreen] Warning: No filter UI found; filtering disabled")

func _refresh_inventory() -> void:
	# Clear existing slots
	if inventory_grid:
		for child in inventory_grid.get_children():
			child.queue_free()
	else:
		print("[InventoryScreen] Warning: inventory_grid not found")

	if equipped_container:
		for child in equipped_container.get_children():
			child.queue_free()

	# Get all items
	var all_items = State.get_all_items_data()

	# Create equipped item slots
	if equipped_container:
		_create_equipped_slots()

	# Create inventory slots
	for item in all_items:
		if item.quantity > 0:  # Only show items with quantity > 0
			var slot = SLOT_SCENE.instantiate()
			slot.set_item(item)
			slot.connect("slot_clicked", Callable(self, "_on_slot_clicked"))
			if inventory_grid:
				inventory_grid.add_child(slot)

	# Adjust grid to current viewport size
	_update_grid_columns()

func _create_equipped_slots() -> void:
	# Equipment slots in order: Weapon, Helmet, Chest, Legs, Boots, Gloves, Ring, Amulet, Belt
	var equipment_slots = ["weapon", "helmet", "chest", "legs", "boots", "gloves", "ring", "amulet", "belt"]

	if not equipped_container:
		return

	for slot_name in equipment_slots:
		var slot = SLOT_SCENE.instantiate()
		slot.set_equipment_slot(slot_name)
		# Connect with a small wrapper so we get both slot_name and the emitted item
		slot.connect("slot_clicked", func(emitted_item):
			_on_equipment_slot_clicked(slot_name, emitted_item)
		)
		equipped_container.add_child(slot)

const SMALL_SCREEN_WIDTH:int = 600

func _on_slot_clicked(item: ItemData) -> void:
	# On small screens show a popup rather than the side details panel
	if get_viewport_rect().size.x <= SMALL_SCREEN_WIDTH:
		_show_item_popup(item)
		return

	selected_item = item
	_update_item_details(item)

func _on_equipment_slot_clicked(slot_name: String, clicked_item: ItemData = null) -> void:
	# On small screens show a popup
	if clicked_item and get_viewport_rect().size.x <= SMALL_SCREEN_WIDTH:
		_show_item_popup(clicked_item)
		return
	
	# If slot emitted an item (clicked on an equipped slot with an item), show it
	if clicked_item:
		selected_item = clicked_item
		_update_item_details(clicked_item)
		return

	# Otherwise, handle by slot name
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
	if not filter_tabs:
		return
	var filter_type = filter_tabs.get_tab_title(tab_index)
	_refresh_inventory_with_filter(filter_type)

func _on_filter_button_pressed(filter_type: String) -> void:
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

# Responsive helpers
func _on_viewport_size_changed() -> void:
	_update_grid_columns()

func _update_grid_columns() -> void:
	if not inventory_grid:
		return

	# Estimate slot width (including spacing). Tune this to match `ItemSlot` widget size.
	var slot_width = 180
	var padding = 60
	var width = get_viewport_rect().size.x - padding
	var cols = int(floor(width / slot_width))
	cols = clamp(cols, 1, 8)
	inventory_grid.columns = cols

	# Hide side details on small screens to avoid half-screen being obscured
	if item_details_panel:
		if width < SMALL_SCREEN_WIDTH:
			item_details_panel.visible = false
		else:
			# Only show item details panel when an item is selected
			item_details_panel.visible = selected_item != null

	# Force redraw if there are items
	if inventory_grid.get_child_count() > 0:
		inventory_grid.queue_sort()

func _show_item_popup(item: ItemData) -> void:
	# Simple popup for small screens
	var popup = AcceptDialog.new()
	popup.title = item.get_enhancement_display() + " " + item.name
	popup.dialog_text = item.description
	popup.get_ok().text = "Close"
	add_child(popup)
	popup.popup_centered_minsize(Vector2(300, 200))
