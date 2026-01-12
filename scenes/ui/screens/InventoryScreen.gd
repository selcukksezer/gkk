extends Control
## InventoryScreen.gd - Unified Inventory & Equipment Screen (Knight Online Style)

signal item_selected(item: ItemData)
signal item_equipped(item: ItemData, slot: String)
signal item_unequipped(slot: String)
signal item_used(item: ItemData)

const InventoryManager = preload("res://autoload/InventoryManager.gd")
const SLOT_SCENE = preload("res://scenes/prefabs/ItemSlot.tscn")
const GRID_COLUMNS = 5
const MAX_INVENTORY_SLOTS = 20  # Maximum inventory slots

# Node references
@onready var paperdoll = %Paperdoll
@onready var inventory_grid: GridContainer = %InventoryGrid
@onready var equipment_grid: GridContainer = %EquipmentGrid
@onready var filter_bar: HBoxContainer = %FilterBar
@onready var sort_button: Button = %SortButton

# Details Panel
@onready var item_details_panel: PanelContainer = %ItemDetailsPanel
@onready var item_name_label: Label = %ItemNameLabel
@onready var item_description_label: Label = %ItemDescriptionLabel
@onready var item_stats_label: Label = %ItemStatsLabel
@onready var use_button: Button = %UseButton
@onready var equip_button: Button = %EquipButton
@onready var sell_button: Button = %SellButton
@onready var close_details_button: Button = $ItemDetailsPanel/DetailsVBox/Header/CloseDetailsButton

var inventory_manager: InventoryManager
var selected_item: ItemData = null
var current_filter: String = "All"
var current_sort: String = "name"
var sort_ascending: bool = true
var trash_slot: Control = null
var current_drag_source: Control = null  # Track where drag started from

# Double-click detection
var last_click_item: ItemData = null
var last_click_time: float = 0.0
const DOUBLE_CLICK_TIME: float = 0.5

func _ready() -> void:
	print("[InventoryScreen] Ready (Unified Layout)")
	inventory_manager = InventoryManager.new()
	
	# Setup grid columns
	if inventory_grid:
		inventory_grid.columns = GRID_COLUMNS
	
	# Connect to inventory_updated signal for shop and other screen updates
	if State.has_user_signal("inventory_updated"):
		if not State.inventory_updated.is_connected(_on_inventory_updated):
			if State.inventory_updated.connect(_on_inventory_updated) == OK:
				print("[InventoryScreen] ✅ Connected to inventory_updated signal")
			else:
				print("[InventoryScreen] ❌ Failed to connect to inventory_updated")
	else:
		print("[InventoryScreen] ⚠️ inventory_updated signal not found in State")
	
	# Connect to EquipmentManager
	var equipment_manager = get_node_or_null("/root/Equipment")
	if equipment_manager:
		equipment_manager.equipment_changed.connect(_on_equipment_changed)
		# Load equipped items from server on startup
		equipment_manager.fetch_equipped_items()
		print("[InventoryScreen] Fetching equipped items from server...")
	
	# Setup filter buttons
	for btn in filter_bar.get_children():
		if btn is Button:
			if btn.name == "AllButton":
				btn.pressed.connect(_on_filter_button_pressed.bind("All"))
			elif btn.name == "WeaponButton":
				btn.pressed.connect(_on_filter_button_pressed.bind("Weapons"))
			elif btn.name == "ArmorButton":
				btn.pressed.connect(_on_filter_button_pressed.bind("Armor"))
			elif btn.name == "PotionButton":
				btn.pressed.connect(_on_filter_button_pressed.bind("Consumables"))
			elif btn.name == "MaterialButton":
				btn.pressed.connect(_on_filter_button_pressed.bind("Materials"))
	
	# Detail buttons
	use_button.pressed.connect(_on_use_button_pressed)
	equip_button.pressed.connect(_on_equip_button_pressed)
	sell_button.pressed.connect(_on_sell_button_pressed)
	close_details_button.pressed.connect(_hide_item_details)
	
	# Sort button
	if sort_button:
		sort_button.pressed.connect(_on_sort_button_pressed)
	
	# Create trash slot
	_create_trash_slot()
	
	# Connect equipment slots
	_connect_equipment_slots()
	
	_refresh_inventory()
	_update_equipment_slots()

func _create_trash_slot() -> void:
	var trash_container = equipment_grid.get_node_or_null("TrashSlot")
	if not trash_container:
		print("[InventoryScreen] Warning: TrashSlot container not found in equipment grid!")
		return
		
	trash_slot = SLOT_SCENE.instantiate()
	trash_container.add_child(trash_slot)
	trash_slot.set_trash_slot()
	trash_slot.custom_minimum_size = Vector2(80, 80)  # Same size as equipment slots
	trash_slot.name = "TrashSlot"
	
	print("[InventoryScreen] Trash slot created in equipment grid")

func _connect_equipment_slots() -> void:
	for child in equipment_grid.get_children():
		if child.has_signal("slot_clicked"):
			child.slot_clicked.connect(_on_equipment_slot_clicked_signal)
		if child.has_signal("item_equipped"):
			child.item_equipped.connect(_on_equipment_item_equipped)
		# Connect drag signals (same as inventory)
		if child.has_signal("item_dragged"):
			child.item_dragged.connect(_on_item_dragged)
		if child.has_signal("item_dropped"):
			child.item_dropped.connect(_on_item_dropped)

func _on_equipment_slot_clicked_signal(slot_type: String) -> void:
	var equipment_manager = get_node_or_null("/root/Equipment")
	if equipment_manager:
		var item = equipment_manager.get_equipped_item(slot_type)
		if item:
			_on_equipment_slot_clicked(item)

func _on_equipment_item_equipped(slot_type: String, item: ItemData) -> void:
	print("[InventoryScreen] Equipment slot received item: ", item.name, " for ", slot_type)
	var equipment_manager = get_node_or_null("/root/Equipment")
	if equipment_manager:
		var result = await equipment_manager.equip_item(item)
		if result.success:
			_refresh_inventory()
			_update_equipment_slots()

func _refresh_inventory(filter_type: String = "") -> void:
	# Clean up
	_clear_container(inventory_grid)
	
	# Use stored filter
	if filter_type == "":
		filter_type = current_filter
	else:
		current_filter = filter_type
	
	# Get all inventory items (not equipped) - using get_all_items_data for proper ItemData objects
	# Filter out items with null slot_position (newly added from shop)
	var all_items = State.get_all_items_data().filter(func(item):
		return not item.is_equipped and item.quantity > 0 and item.slot_position >= 0
	)
	
	# Apply filter
	var filtered_items = []
	for item in all_items:
		if _should_show_item(item, filter_type):
			filtered_items.append(item)
	
	# Create fixed 20 slots (0-19)
	const EMPTY_SLOT_SCRIPT = preload("res://scenes/ui/components/EmptyInventorySlot.gd")
	
	for slot_pos in range(20):
		# Find item with this slot_position
		var item_in_slot: ItemData = null
		for item in filtered_items:
			if item.slot_position == slot_pos:
				item_in_slot = item
				break
		
		if item_in_slot:
			# Create filled slot
			var slot = SLOT_SCENE.instantiate()
			slot.custom_minimum_size = Vector2(90, 90)
			slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			slot.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			slot.slot_position = slot_pos  # Track position
			inventory_grid.add_child(slot)
			slot.set_item(item_in_slot)
			slot.slot_clicked.connect(_on_slot_clicked)
			slot.item_dragged.connect(_on_item_dragged)
			slot.item_dropped.connect(_on_item_dropped)
		else:
			# Create empty slot
			var empty_slot = Panel.new()
			empty_slot.set_script(EMPTY_SLOT_SCRIPT)
			empty_slot.custom_minimum_size = Vector2(90, 90)
			empty_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			empty_slot.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			empty_slot.mouse_filter = Control.MOUSE_FILTER_STOP # Key fix for receiving drops
			empty_slot.slot_position = slot_pos
			
			# Create dark panel with gray border
			var stylebox = StyleBoxFlat.new()
			stylebox.bg_color = Color(0.12, 0.12, 0.12, 0.7)
			stylebox.border_color = Color(0.35, 0.35, 0.35, 0.7)
			stylebox.border_width_left = 2
			stylebox.border_width_right = 2
			stylebox.border_width_top = 2
			stylebox.border_width_bottom = 2
			empty_slot.add_theme_stylebox_override("panel", stylebox)
			
			# Connect signal and add to grid
			empty_slot.item_placed.connect(_on_empty_slot_drop)
			inventory_grid.add_child(empty_slot)

func _update_equipment_slots() -> void:
	var equipment_manager = get_node_or_null("/root/Equipment")
	if not equipment_manager:
		return
	
	for child in equipment_grid.get_children():
		if child.has_method("set_item"):
			var slot_type = child.slot_type if "slot_type" in child else ""
			var equipped_item = equipment_manager.get_equipped_item(slot_type)
			if equipped_item:
				child.set_item(equipped_item)
			else:
				child.set_equipment_slot(slot_type)

func _clear_container(container: Node) -> void:
	if not container: return
	for child in container.get_children():
		child.queue_free()

func _should_show_item(item: ItemData, filter: String) -> bool:
	if filter == "All" or filter == "":
		return true
	
	match filter:
		"Weapons":
			return item.is_weapon()
		"Armor":
			return item.is_armor()
		"Consumables", "Potion":
			return item.is_consumable()
		"Materials":
			return item.is_material()
	
	return true

func _sort_items(items: Array[ItemData]) -> void:
	match current_sort:
		"name":
			items.sort_custom(func(a, b): return _compare_strings(a.name, b.name))
		"type":
			items.sort_custom(func(a, b): return _compare_strings(ItemData.ItemType.keys()[a.item_type], ItemData.ItemType.keys()[b.item_type]))
		"rarity":
			items.sort_custom(func(a, b): return a.rarity < b.rarity if sort_ascending else a.rarity > b.rarity)
		"level":
			items.sort_custom(func(a, b): return a.required_level < b.required_level if sort_ascending else a.required_level > b.required_level)
	
	if not sort_ascending and current_sort in ["name", "type"]:
		items.reverse()

func _compare_strings(a: String, b: String) -> bool:
	return a < b if sort_ascending else a > b

func _on_slot_clicked(item: ItemData) -> void:
	if not item: return
	
	# Double-click detection - use row_id for comparison
	var current_time = Time.get_ticks_msec() / 1000.0
	print("[InventoryScreen] Slot clicked - Item: ", item.name, " (row_id: ", item.row_id, ")")
	
	if last_click_item and last_click_item.row_id == item.row_id and (current_time - last_click_time) < DOUBLE_CLICK_TIME:
		print("[InventoryScreen] ✅ DOUBLE-CLICK detected on: ", item.name)
		_on_item_double_clicked(item)
		return
	
	last_click_item = item
	last_click_time = current_time
	
	selected_item = item
	print("[InventoryScreen] selected_item set to: ", item.name, " (row_id: ", item.row_id, ")")
	_update_item_details(item)

func _on_equipment_slot_clicked(item: ItemData) -> void:
	if item:
		selected_item = item
		_update_item_details(item)

func _update_item_details(item: ItemData) -> void:
	item_details_panel.visible = true
	item_name_label.text = item.name
	item_name_label.add_theme_color_override("font_color", item.get_rarity_color())
	
	item_description_label.text = item.description if item.description else "Açıklama yok"
	
	# Build stats text
	var stats_text = ""
	var rarity_name = ItemData.ItemRarity.keys()[item.rarity]
	var type_name = ItemData.ItemType.keys()[item.item_type]
	stats_text += "Nadirlik: %s\n" % rarity_name
	stats_text += "Tip: %s\n" % type_name
	stats_text += "Miktar: %d\n" % item.quantity
	
	if item.is_equipment():
		stats_text += "\n[Savaş İstatistikleri]\n"
		if item.attack > 0:
			stats_text += "Saldırı: %d\n" % item.attack
		if item.defense > 0:
			stats_text += "Savunma: %d\n" % item.defense
		if item.health > 0:
			stats_text += "Can: +%d\n" % item.health
		if item.power > 0:
			stats_text += "Güç: +%d\n" % item.power
		if item.required_level > 0:
			stats_text += "Gerekli Seviye: %d\n" % item.required_level
	
	item_stats_label.text = stats_text
	
	# Button visibility
	use_button.visible = item.is_consumable()
	equip_button.visible = item.is_equipment()
	sell_button.visible = item.is_tradeable

func _hide_item_details() -> void:
	item_details_panel.visible = false
	selected_item = null

func _on_filter_button_pressed(filter_type: String) -> void:
	print("[InventoryScreen] Filter: ", filter_type)
	current_filter = filter_type
	
	# Update button states
	for btn in filter_bar.get_children():
		if btn is Button:
			btn.button_pressed = (
				(filter_type == "All" and btn.name == "AllButton") or
				(filter_type == "Weapons" and btn.name == "WeaponButton") or
				(filter_type == "Armor" and btn.name == "ArmorButton") or
				(filter_type == "Consumables" and btn.name == "PotionButton") or
				(filter_type == "Materials" and btn.name == "MaterialButton")
			)
	
	_refresh_inventory(filter_type)

func _on_use_button_pressed() -> void:
	if selected_item:
		await inventory_manager.use_item(selected_item)
		_refresh_inventory()

func _on_equip_button_pressed() -> void:
	if selected_item:
		var equipment_manager = get_node_or_null("/root/Equipment")
		if equipment_manager:
			var result = await equipment_manager.equip_item(selected_item)
			if result.success:
				_refresh_inventory()
				_update_equipment_slots()
				# Close dialog
				item_details_panel.visible = false
				selected_item = null

func _on_sell_button_pressed() -> void:
	if selected_item:
		# For stackable items with quantity > 1, ask how many to sell
		if selected_item.is_stackable and selected_item.quantity > 1:
			var quantity_dialog = AcceptDialog.new()
			quantity_dialog.title = "Miktar Seç"
			var vbox = VBoxContainer.new()
			var label = Label.new()
			label.text = "Kaç adet satmak istiyorsunuz? (Maks: %d, Toplam: %d altın)" % [selected_item.quantity, selected_item.vendor_sell_price * selected_item.quantity]
			vbox.add_child(label)
			var spinbox = SpinBox.new()
			spinbox.min_value = 1
			spinbox.max_value = selected_item.quantity
			spinbox.value = 1
			spinbox.step = 1
			spinbox.allow_greater = false
			spinbox.allow_lesser = false
			# Force clamp when text changes or focus lost
			spinbox.get_line_edit().text_changed.connect(func(new_text):
				var val = int(new_text)
				if val > selected_item.quantity:
					spinbox.value = selected_item.quantity
					spinbox.get_line_edit().text = str(selected_item.quantity)
			)
			
			vbox.add_child(spinbox)
			quantity_dialog.add_child(vbox)
			add_child(quantity_dialog)
			quantity_dialog.confirmed.connect(func():
				var qty = int(spinbox.value)
				# Safety check: ensure we never exceed quantity
				if qty > selected_item.quantity:
					qty = selected_item.quantity
					
				var total_price = selected_item.vendor_sell_price * qty
				# Use row_id with quantity for precise removal of specific stack
				var result = await inventory_manager.remove_item_by_row_id(selected_item.row_id, qty)
				if result.success:
					State.update_gold(total_price, true)
					_hide_item_details()
					_refresh_inventory()
				quantity_dialog.queue_free()
			)
			quantity_dialog.canceled.connect(func(): quantity_dialog.queue_free())
			quantity_dialog.popup_centered()
		else:
			# Single or non-stackable item
			var confirm_dialog = AcceptDialog.new()
			confirm_dialog.title = "Eşya Sat"
			confirm_dialog.dialog_text = "%s'yi %d altın karşılığında satmak istediğinize emin misiniz?" % [selected_item.name, selected_item.vendor_sell_price]
			add_child(confirm_dialog)
			confirm_dialog.confirmed.connect(func():
				var result = await inventory_manager.remove_item_by_row_id(selected_item.row_id)
				if result.success:
					if selected_item.vendor_sell_price > 0:
						State.update_gold(selected_item.vendor_sell_price, true)
				_hide_item_details()
				_refresh_inventory()
				confirm_dialog.queue_free()
			)
			confirm_dialog.canceled.connect(func():
				confirm_dialog.queue_free()
			)
			confirm_dialog.popup_centered()

func _on_sort_button_pressed() -> void:
	var sort_options = ["name", "type", "rarity", "level"]
	var current_index = sort_options.find(current_sort)
	
	if current_index == -1:
		current_index = 0
	
	if current_index == sort_options.size() - 1:
		sort_ascending = not sort_ascending
		current_index = 0
	else:
		current_index += 1
	
	current_sort = sort_options[current_index]
	
	var sort_text = ""
	match current_sort:
		"name":
			sort_text = "İsim %s" % ("↑" if sort_ascending else "↓")
		"type":
			sort_text = "Tip %s" % ("↑" if sort_ascending else "↓")
		"rarity":
			sort_text = "Nadirlik %s" % ("↑" if sort_ascending else "↓")
		"level":
			sort_text = "Seviye %s" % ("↑" if sort_ascending else "↓")
	
	if sort_button:
		sort_button.text = sort_text
	
	_refresh_inventory()

func _on_inventory_updated() -> void:
	print("[InventoryScreen] 🔄 Inventory updated signal received - refreshing display")
	_refresh_inventory()
	_update_equipment_slots()

func _on_equipment_changed(slot: String, item: ItemData) -> void:
	print("[InventoryScreen] Equipment changed: ", slot)
	# Refresh inventory display when equipment changes (especially on unequip)
	if item == null:
		print("[InventoryScreen] Item unequipped from slot, refreshing inventory...")
		_refresh_inventory()
	_update_equipment_slots()



func _on_item_dragged(item: ItemData, from_slot: Control) -> void:
	print("[InventoryScreen] Item dragged: ", item.name)
	# Store the drag source to check later in _on_item_dropped
	current_drag_source = from_slot

func _on_item_dropped(item: ItemData, dropped_on_control: Control) -> void:
	# Resolve the actual slot (in case dropped on a child TextureRect, etc)
	var to_slot = _get_slot_from_control(dropped_on_control)
	var source_slot_control = _get_slot_from_control(current_drag_source)
	
	print("[InventoryScreen] Item dropped: ", item.name if item else "null")
	print("[InventoryScreen] Raw drop target: ", dropped_on_control.name if dropped_on_control else "null")
	print("[InventoryScreen] Resolved to_slot: ", to_slot.name if to_slot else "null")
	
	# Check if equipment item dropped on inventory (unequip)
	# Check if source has get_slot_type method (EquipmentSlot)
	if source_slot_control and source_slot_control.has_method("get_slot_type"):
		print("[InventoryScreen] 🔄 Equipment item dragged - checking if on inventory area")
		
		# Check if mouse is within inventory grid area
		var mouse_pos = get_global_mouse_position()
		var is_on_inventory = false
		
		if inventory_grid and inventory_grid.get_global_rect().has_point(mouse_pos):
			is_on_inventory = true
			print("[InventoryScreen] ✅ Mouse is within inventory grid area")
		
		if is_on_inventory:
			print("[InventoryScreen] ✅ Dropped on inventory area - unequipping")
			
			# Determine target slot index if dropped on a specific slot
			var target_slot_index = -1
			if to_slot and to_slot.has_method("get_slot_position"):
				target_slot_index = to_slot.get_slot_position()
				print("[InventoryScreen] 🎯 Target slot identified: ", target_slot_index)
			elif to_slot and to_slot.get("slot_position") != null:
				# Fallback property check
				target_slot_index = to_slot.slot_position
				print("[InventoryScreen] 🎯 Target slot identified (prop): ", target_slot_index)
			
			# Get slot type from EquipmentSlot
			var source_slot = source_slot_control.get_slot_type()
			if source_slot != "":
				var equipment_manager = get_node_or_null("/root/Equipment")
				if equipment_manager:
					# Pass target_slot_index to manager
					var result = await equipment_manager.unequip_item(source_slot, target_slot_index)
					if result.success:
						print("[InventoryScreen] ✅ Unequip successful")
						_refresh_inventory()
						_update_equipment_slots()
					else:
						print("[InventoryScreen] ❌ Unequip failed: ", result.get("error", "Unknown"))
			current_drag_source = null  # Clear drag source
			return
	
	if not to_slot or not item:
		print("[InventoryScreen] ❌ Invalid drop - to_slot or item is null")
		current_drag_source = null
		return
	
	print("[InventoryScreen] Drop target has get_slot_type: ", to_slot.has_method("get_slot_type"))
	print("[InventoryScreen] Drop target has can_equip_item: ", to_slot.has_method("can_equip_item"))
	print("[InventoryScreen] Drop target has is_trash_slot: ", to_slot.has_method("is_trash_slot"))
	
	# Check if dropped on equipment slot - look for EquipmentSlot class
	if to_slot.has_method("get_slot_type"):
		var slot_type = to_slot.get_slot_type()
		print("[InventoryScreen] 🎯 Found equipment slot! Type: ", slot_type)
		if to_slot.has_method("can_equip_item") and to_slot.can_equip_item(item):
			print("[InventoryScreen] ✅ Can equip to this slot, calling _equip_item_to_slot...")
			_equip_item_to_slot(item, slot_type)
			current_drag_source = null
			return
		else:
			print("[InventoryScreen] ❌ Cannot equip to this slot")
			current_drag_source = null
			return
	
	
	# Check if dropped on trash slot
	if to_slot.has_method("is_trash_slot") and to_slot.is_trash_slot():
		print("[InventoryScreen] 🗑️ Dropped on trash slot - showing confirm dialog")
		# Show confirmation dialog with the dragged item's row_id
		_delete_item_confirm(item)
		current_drag_source = null
		return
	
	# Check if dropped on another ItemSlot (inventory slot swap/move)
	# Use resolved to_slot
	print("[InventoryScreen] Checking ItemSlot drop - has get_item: ", to_slot.has_method("get_item"), " has get_slot_position: ", to_slot.has_method("get_slot_position"))
	if to_slot.has_method("get_item") and to_slot.has_method("get_slot_position"):
		var target_position = to_slot.get_slot_position()
		print("[InventoryScreen] 🔄 Dropped on ItemSlot at position ", target_position)
		
		# Get target slot's item (if any)
		var target_item = to_slot.get_item()
		
		if target_item:
			# Swap positions between source and target items
			print("[InventoryScreen] Swapping items: ", item.name, " <-> ", target_item.name)
			var source_position = item.slot_position
			
			# Update both positions via batch update
			var updates = [
				{"row_id": item.row_id, "slot_position": target_position},
				{"row_id": target_item.row_id, "slot_position": source_position}
			]
			
			var payload = {"p_updates": updates}
			var result = await Network.http_post("/rest/v1/rpc/update_item_positions", payload)
			
			if result.success:
				print("[InventoryScreen] ✅ Items swapped successfully")
				# Update local state
				for inv_item in State.inventory:
					if inv_item.get("row_id") == item.row_id:
						inv_item["slot_position"] = target_position
					elif inv_item.get("row_id") == target_item.row_id:
						inv_item["slot_position"] = source_position
				_refresh_inventory()
			else:
				print("[InventoryScreen] ❌ Swap failed: ", result.get("error", "Unknown"))
		else:
			# Move to empty ItemSlot position
			var result = await inventory_manager.move_item_to_slot(item, target_position)
			if result.success:
				print("[InventoryScreen] ✅ Item moved to position ", target_position)
				_refresh_inventory()
		
		current_drag_source = null
		return
	
	current_drag_source = null
	print("[InventoryScreen] ⚠️ Dropped on unknown target")

# Helper to find the actual slot control from a child (e.g. TextureRect)
func _get_slot_from_control(control: Control) -> Control:
	if not control: return null
	
	var current = control
	var depth = 0
	const MAX_DEPTH = 10 # Traverse up to 10 parents to be safe
	
	while current and depth < MAX_DEPTH:
		# Check if current control is the slot we want (duck typing)
		if current.has_method("get_slot_position") or current.has_method("get_slot_type") or current.has_method("is_trash_slot"):
			return current
		
		# Move up to parent
		var parent = current.get_parent()
		if not (parent is Control):
			break
			
		current = parent
		depth += 1
			
	# Default to original if no better parent found
	return control

func _on_item_double_clicked(item: ItemData) -> void:
	"""Handle double-click - auto-equip if equipment, use if consumable"""
	print("[InventoryScreen] 🎯 _on_item_double_clicked called for: ", item.name)
	print("[InventoryScreen] Item type check - is_equipment: ", item.is_equipment(), " is_consumable: ", item.is_consumable())
	
	if item.is_equipment():
		print("[InventoryScreen] Auto-equipping: ", item.name)
		var equipment_manager = get_node_or_null("/root/Equipment")
		if equipment_manager:
			print("[InventoryScreen] Equipment manager found, calling equip_item...")
			var result = await equipment_manager.equip_item(item)
			print("[InventoryScreen] Equip result: ", result)
			if result.success:
				print("[InventoryScreen] ✅ Equip successful!")
				_refresh_inventory()
				_update_equipment_slots()
				# Close item details dialog after successful equip
				if item_details_panel:
					item_details_panel.visible = false
			else:
				print("[InventoryScreen] ❌ Equip failed: ", result.get("error", "Unknown"))
		else:
			print("[InventoryScreen] ❌ ERROR: Equipment manager not found!")
	elif item.is_consumable():
		print("[InventoryScreen] Auto-using consumable: ", item.name)
		await inventory_manager.use_item(item)
		_refresh_inventory()

func _equip_item_to_slot(item: ItemData, slot_name: String) -> void:
	print("[InventoryScreen] 🎯 _equip_item_to_slot called - Item: ", item.name, " Slot: ", slot_name)
	
	if not item.is_equipment():
		print("[InventoryScreen] ❌ Item is not equipment")
		return
	
	print("[InventoryScreen] Getting Equipment manager...")
	var equipment_manager = get_node_or_null("/root/Equipment")
	if equipment_manager:
		print("[InventoryScreen] Equipment manager found, calling equip_item...")
		var result = await equipment_manager.equip_item(item)
		print("[InventoryScreen] Equip result received: ", result)
		if result.success:
			print("[InventoryScreen] ✅ Equip successful! Removing from inventory...")
			
			# Remove from inventory (server-side will handle this via is_equipped flag)
			# We just refresh UI to reflect the change
			_refresh_inventory()
			_update_equipment_slots()
			print("[InventoryScreen] UI refresh complete")
		else:
			print("[InventoryScreen] ❌ Equip failed: ", result.get("error", "Unknown"))
	else:
		print("[InventoryScreen] ❌ Equipment manager not found!")

func _delete_item_confirm(item: ItemData) -> void:
	# For stackable items with quantity > 1, ask how many to delete
	if item.is_stackable and item.quantity > 1:
		var quantity_dialog = AcceptDialog.new()
		quantity_dialog.title = "Miktar Seç"
		var vbox = VBoxContainer.new()
		var label = Label.new()
		label.text = "Kaç adet silmek istiyorsunuz? (Maks: %d)" % item.quantity
		vbox.add_child(label)
		var spinbox = SpinBox.new()
		spinbox.min_value = 1
		spinbox.max_value = item.quantity
		spinbox.value = 1
		spinbox.step = 1
		spinbox.allow_greater = false
		spinbox.allow_lesser = false
		# Force clamp when text changes
		spinbox.get_line_edit().text_changed.connect(func(new_text):
			var val = int(new_text)
			if val > item.quantity:
				spinbox.value = item.quantity
				spinbox.get_line_edit().text = str(item.quantity)
		)
		
		vbox.add_child(spinbox)
		quantity_dialog.add_child(vbox)
		add_child(quantity_dialog)
		quantity_dialog.confirmed.connect(func():
			var qty = int(spinbox.value)
			# Safety check
			if qty > item.quantity:
				qty = item.quantity
				
			# Use row_id with quantity for precise removal of specific stack/row
			var result = await inventory_manager.remove_item_by_row_id(item.row_id, qty)
			if result.success:
				_refresh_inventory()
			quantity_dialog.queue_free()
		)
		quantity_dialog.canceled.connect(func(): quantity_dialog.queue_free())
		quantity_dialog.popup_centered()
	else:
		# Single item or non-stackable - delete entire stack
		var confirm_dialog = ConfirmationDialog.new()
		confirm_dialog.title = "Eşya Sil"
		confirm_dialog.dialog_text = "%s'yi silmek istediğinize emin misiniz?" % item.name
		confirm_dialog.ok_button_text = "Sil"
		confirm_dialog.cancel_button_text = "İptal"
		
		add_child(confirm_dialog)
		
		confirm_dialog.confirmed.connect(func():
			print("[InventoryScreen] Delete confirmed for row_id: ", item.row_id)
			var result = await inventory_manager.remove_item_by_row_id(item.row_id)
			if result.success:
				print("[InventoryScreen] Item deleted")
				_refresh_inventory()
			confirm_dialog.queue_free()
		)
		
		confirm_dialog.canceled.connect(func():
			confirm_dialog.queue_free()
		)
		
		confirm_dialog.popup_centered()

## Check if inventory has space
func has_inventory_space() -> bool:
	var current_count = State.inventory.size()
	return current_count < 100  # Max 100 inventory slots

## Handler for items dropped on empty inventory slots
func _on_empty_slot_drop(item: ItemData, target_position: int) -> void:
	print("[InventoryScreen] Item dropped on empty slot: ", item.name, " -> position ", target_position)
	
	# If item is equipped, we must UNEQUIP it to this slot
	if item.is_equipped:
		print("[InventoryScreen] 🔄 Unequiping to specific slot: ", target_position)
		var equipment_manager = get_node_or_null("/root/Equipment")
		if equipment_manager:
			# Get the slot key (e.g. "CHEST")
			var slot_key = equipment_manager.get_slot_key_for_item(item)
			if slot_key != "":
				var result = await equipment_manager.unequip_item(slot_key, target_position)
				if result.success:
					print("[InventoryScreen] ✅ Unequip to slot successful")
					_refresh_inventory()
					_update_equipment_slots()
				else:
					print("[InventoryScreen] ❌ Unequip to slot failed: ", result.get("error", "Unknown"))
			else:
				print("[InventoryScreen] ❌ Could not determine equip slot key for item")
		return

	# Normal move for non-equipped items
	# Move item to target position via InventoryManager
	var result = await inventory_manager.move_item_to_slot(item, target_position)
	
	if result.success:
		print("[InventoryScreen] ✅ Item moved to position ", target_position)
		_refresh_inventory()
	else:
		print("[InventoryScreen] ❌ Failed to move item: ", result.get("error", "Unknown"))
## Get remaining inventory slots
func get_remaining_slots() -> int:
	var item_count = State.get_all_items_data().size()
	return max(0, MAX_INVENTORY_SLOTS - item_count)
