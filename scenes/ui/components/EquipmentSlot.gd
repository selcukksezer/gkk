extends Control
class_name EquipmentSlot

## Equipment Slot UI Component
## Represents a single equipment slot that can hold one item

signal item_equipped(slot_type: String, item: ItemData)
signal item_unequipped(slot_type: String)
signal slot_clicked(slot_type: String)
signal item_dragged(item: ItemData, from_slot: Control)
signal item_dropped(item: ItemData, to_slot: Control)

@export var slot_type: String = "WEAPON"  ## WEAPON, HEAD, CHEST, HANDS, LEGS, FEET, ACCESSORY_1, ACCESSORY_2
@export var show_slot_name: bool = true

@onready var panel: Panel = $Panel
@onready var icon: TextureRect = $Panel/Icon
@onready var empty_label: Label = $Panel/EmptyLabel
@onready var enhancement_label: Label = $Panel/EnhancementLabel
@onready var slot_name_label: Label = $SlotNameLabel

var current_item: ItemData = null
var is_dragging: bool = false
var last_click_time: float = 0.0
const DOUBLE_CLICK_TIME: float = 0.5

func _ready():
	# Enable dragging - both on self and panel
	mouse_filter = Control.MOUSE_FILTER_STOP
	if panel:
		panel.mouse_filter = Control.MOUSE_FILTER_PASS  # Let events pass to parent
	
	# Setup UI
	if show_slot_name:
		slot_name_label.text = _get_slot_display_name()
		slot_name_label.visible = true
	else:
		slot_name_label.visible = false
	
	# Connect to equipment manager
	var equipment_manager = get_node_or_null("/root/Equipment")
	if equipment_manager:
		equipment_manager.equipment_changed.connect(_on_equipment_changed)
	
	# Initial update
	_update_visual()

func _get_slot_display_name() -> String:
	match slot_type:
		"WEAPON": return "Silah"
		"HEAD": return "Baş"
		"CHEST": return "Gövde"
		"HANDS": return "Eller"
		"LEGS": return "Bacaklar"
		"FEET": return "Ayaklar"
		"ACCESSORY_1", "ACCESSORY_2": return "Aksesuar"
		_: return slot_type

func _on_equipment_changed(slot: String, item: ItemData):
	if slot == slot_type:
		current_item = item
		_update_visual()

func _update_visual():
	if current_item:
		# Show item icon
		if current_item.icon != "":
			icon.texture = load(current_item.icon)
			icon.visible = true
		else:
			icon.visible = false
		
		empty_label.visible = false
		
		# Show enhancement level if > 0
		if current_item.enhancement_level > 0:
			enhancement_label.text = "+%d" % current_item.enhancement_level
			enhancement_label.visible = true
		else:
			enhancement_label.visible = false
		
		# Color border by rarity
		_set_border_color(current_item.rarity)
	else:
		# Empty slot
		icon.visible = false
		empty_label.visible = true
		enhancement_label.visible = false
		_set_border_color(ItemData.ItemRarity.COMMON)

func _set_border_color(rarity: ItemData.ItemRarity):
	var color: Color
	match rarity:
		ItemData.ItemRarity.COMMON:
			color = Color(0.5, 0.5, 0.5, 0.5)  # Gray
		ItemData.ItemRarity.UNCOMMON:
			color = Color(0.2, 0.8, 0.2, 0.8)  # Green
		ItemData.ItemRarity.RARE:
			color = Color(0.2, 0.5, 1.0, 0.8)  # Blue
		ItemData.ItemRarity.EPIC:
			color = Color(0.7, 0.2, 1.0, 0.8)  # Purple
		ItemData.ItemRarity.LEGENDARY:
			color = Color(1.0, 0.7, 0.0, 0.8)  # Gold
		_:
			color = Color(0.5, 0.5, 0.5, 0.5)
	
	# Apply to panel border (assuming panel has StyleBox)
	var stylebox = panel.get_theme_stylebox("panel")
	if stylebox is StyleBoxFlat:
		stylebox.border_color = color

## Custom drag system (like ItemSlot)
var drag_preview: Control = null

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				# Check for double-click
				var current_time = Time.get_ticks_msec() / 1000.0
				if current_time - last_click_time < DOUBLE_CLICK_TIME and current_item:
					# Double-click detected - BUT user wants only drag-drop
					# Do nothing or maybe print a message "Drag to unequip"
					print("[EquipmentSlot] Double-click detected (Ignored - Drag to unequip)")
					last_click_time = 0.0
				else:
					last_click_time = current_time
					if current_item:
						# Start custom drag with visual preview
						is_dragging = true
						_create_drag_preview()
						item_dragged.emit(current_item, self)
						print("[EquipmentSlot] Drag started: ", current_item.name)
					else:
						# Single click on empty
						slot_clicked.emit(slot_type)
			else:
				# Mouse released
				if is_dragging and current_item:
					is_dragging = false
					# Find what we're hovering over
					var mouse_pos = get_global_mouse_position()
					var target = _find_control_at_position(mouse_pos)
					if target:
						item_dropped.emit(current_item, target)
						print("[EquipmentSlot] Dropped on: ", target.name)
					_destroy_drag_preview()

func _process(delta):
	# Update drag preview position
	if is_dragging and drag_preview:
		drag_preview.global_position = get_global_mouse_position() - Vector2(35, 35)

func _create_drag_preview():
	if not current_item or drag_preview:
		return
	
	# Create a Panel container (like ItemSlot)
	var preview_panel = Panel.new()
	preview_panel.custom_minimum_size = Vector2(70, 70)
	
	# Style the panel with rarity border (like ItemSlot)
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.15, 0.15, 0.15, 0.8)
	
	# Get rarity color for border
	var border_color = Color(0.5, 0.5, 0.5, 0.8)  # Default gray
	if current_item.rarity == ItemData.ItemRarity.COMMON:
		border_color = Color(0.5, 0.5, 0.5, 0.8)  # Gray
	elif current_item.rarity == ItemData.ItemRarity.UNCOMMON:
		border_color = Color(0.2, 0.8, 0.2, 0.8)  # Green
	elif current_item.rarity == ItemData.ItemRarity.RARE:
		border_color = Color(0.2, 0.5, 1.0, 0.8)  # Blue
	elif current_item.rarity == ItemData.ItemRarity.EPIC:
		border_color = Color(0.7, 0.2, 1.0, 0.8)  # Purple/Magenta
	elif current_item.rarity == ItemData.ItemRarity.LEGENDARY:
		border_color = Color(1.0, 0.7, 0.0, 0.8)  # Gold
	
	stylebox.border_color = border_color
	stylebox.border_width_left = 3
	stylebox.border_width_right = 3
	stylebox.border_width_top = 3
	stylebox.border_width_bottom = 3
	stylebox.corner_radius_top_left = 4
	stylebox.corner_radius_top_right = 4
	stylebox.corner_radius_bottom_left = 4
	stylebox.corner_radius_bottom_right = 4
	preview_panel.add_theme_stylebox_override("panel", stylebox)
	
	# Add icon inside panel
	var preview_icon = TextureRect.new()
	preview_icon.texture = icon.texture
	preview_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_icon.custom_minimum_size = Vector2(64, 64)
	preview_icon.anchors_preset = Control.PRESET_FULL_RECT
	preview_panel.add_child(preview_icon)
	
	preview_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_panel.z_index = 100
	
	drag_preview = preview_panel
	get_tree().root.add_child(drag_preview)
	drag_preview.global_position = get_global_mouse_position() - Vector2(35, 35)

func _destroy_drag_preview():
	if drag_preview:
		drag_preview.queue_free()
		drag_preview = null

func _find_control_at_position(pos: Vector2) -> Control:
	# Better approach: Search from the current scene root
	var current_scene = get_tree().current_scene
	if not current_scene:
		# Fallback for when running scene directly or edge cases
		current_scene = get_tree().root.get_child(get_tree().root.get_child_count() - 1)
		
	return _find_control_recursive(current_scene, pos)

func _find_control_recursive(node: Node, pos: Vector2) -> Control:
	# Skip the drag preview itself
	if node == drag_preview:
		return null
		
	if node is Control:
		var control = node as Control
		if control.visible and control.get_global_rect().has_point(pos):
			# Check children first (depth-first, reverse order for Z-index)
			var m_children = control.get_children()
			var child_count = m_children.size()
			for i in range(child_count - 1, -1, -1):
				var result = _find_control_recursive(m_children[i], pos)
				if result:
					return result
			return control
	else:
		# Iterate children in reverse order (top to bottom)
		var m_children = node.get_children()
		var child_count = m_children.size()
		for i in range(child_count - 1, -1, -1):
			var result = _find_control_recursive(m_children[i], pos)
			if result:
				return result
	return null

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if data is Dictionary:
		# From inventory
		if data.has("type") and data.type == "inventory_item":
			var item: ItemData = data.item
			return _can_accept_item(item)
		# From another equipment slot (swap)
		elif data.has("type") and data.type == "equipment_slot":
			var item: ItemData = data.item
			return _can_accept_item(item)
	return false

func _drop_data(at_position: Vector2, data: Variant):
	var item: ItemData = data.item
	
	if _can_accept_item(item):
		# Equip item  
		item_equipped.emit(slot_type, item)

## Public interface for setting item directly (used by InventoryScreen)
func set_item(item: ItemData) -> void:
	current_item = item
	_update_visual()

## Public interface for getting slot type
func get_slot_type() -> String:
	return slot_type

## Public interface to check if can equip item from outside
func can_equip_item(item: ItemData) -> bool:
	return _can_accept_item(item)

## Set as empty equipment slot with label
func set_equipment_slot(slot_name: String) -> void:
	current_item = null
	slot_type = slot_name
	_update_visual()

func _can_accept_item(item: ItemData) -> bool:
	print("[EquipmentSlot] _can_accept_item called for: ", item.name if item else "null")
	print("[EquipmentSlot] This slot type: ", slot_type)
	
	if not item:
		print("[EquipmentSlot] ❌ Item is null")
		return false
	
	var equipment_manager = get_node_or_null("/root/Equipment")
	if not equipment_manager:
		print("[EquipmentSlot] ❌ Equipment manager not found")
		return false
	
	# Check if item slot matches this slot
	var item_slot_key = equipment_manager.get_slot_key_for_item(item)
	print("[EquipmentSlot] Item slot key from EquipmentManager: ", item_slot_key)
	print("[EquipmentSlot] Comparing: '", item_slot_key, "' == '", slot_type, "' ?")
	
	# For accessories, accept any accessory
	if slot_type.begins_with("ACCESSORY") and item_slot_key.begins_with("ACCESSORY"):
		print("[EquipmentSlot] ✅ Accessory match!")
		return true
	
	var matches = item_slot_key == slot_type
	print("[EquipmentSlot] Match result: ", matches)
	return matches

func _unequip_item() -> void:
	if not current_item:
		return
		
	print("[EquipmentSlot] Unequipping from slot: ", slot_type)
	var equipment_manager = get_node_or_null("/root/Equipment")
	if equipment_manager:
		item_unequipped.emit(slot_type)
		var result = await equipment_manager.unequip_item(slot_type)
		if result.success:
			print("[EquipmentSlot] ✅ Unequip successful")
		else:
			print("[EquipmentSlot] ❌ Unequip failed: ", result.get("error", "Unknown"))
