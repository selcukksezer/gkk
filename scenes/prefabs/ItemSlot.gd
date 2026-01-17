extends Button

## ItemSlot.gd - Grid Style Item Slot with Drag & Drop
signal slot_clicked(item: ItemData)
signal item_dragged(item: ItemData, from_slot: Control)
signal item_dropped(item: ItemData, to_slot: Control)

@onready var icon_rect: TextureRect = %Icon
@onready var quantity_label: Label = %QuantityLabel
@onready var enhancement_label: Label = %EnhancementLabel
@onready var rarity_border: ReferenceRect = %RarityBorder
@onready var background: ColorRect = $Background
@onready var trash_icon: Label = %TrashIcon if has_node("%TrashIcon") else null

var _item: ItemData
var _slot_name: String = ""
var _is_trash_slot: bool = false
var _is_equipment_slot: bool = false
var _drag_preview: Control = null
var _is_dragging: bool = false
var _drag_start_pos: Vector2 = Vector2.ZERO
var slot_position: int = -1  # Inventory slot position (0-19), -1 = unassigned

func _ready() -> void:
	pressed.connect(_on_pressed)
	custom_minimum_size = Vector2(90, 90)
	
	# Enable drag and drop for non-trash slots
	gui_input.connect(_on_gui_input)

func _input(event: InputEvent) -> void:
	# Global mouse release - cleanup drag preview if it exists
	if event is InputEventMouseButton:
		var mb_event = event as InputEventMouseButton
		if mb_event.button_index == MOUSE_BUTTON_LEFT and not mb_event.pressed:
			if _drag_preview:
				_end_drag()
				_is_dragging = false

func _on_gui_input(event: InputEvent) -> void:
	if _is_trash_slot or not _item:
		return
		
	if event is InputEventMouseButton:
		var mb_event = event as InputEventMouseButton
		if mb_event.button_index == MOUSE_BUTTON_LEFT:
			if mb_event.pressed:
				# Store start position
				_drag_start_pos = mb_event.global_position
				_is_dragging = false
			else:
				# End drag on release
				if _drag_preview:
					_end_drag()
					_is_dragging = false
	
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var motion_event = event as InputEventMouseMotion
		# Start dragging if moved enough
		if not _is_dragging and _drag_start_pos.distance_to(motion_event.global_position) > 10:
			_start_drag()
			_is_dragging = true

func _start_drag() -> void:
	if not _item:
		return
		
	# Create drag preview with panel
	_drag_preview = PanelContainer.new()
	_drag_preview.modulate = Color(1, 1, 1, 0.85)
	
	# Add glow/shadow effect
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.2, 0.2, 0.3, 0.9)
	stylebox.border_color = _item.get_rarity_color()
	stylebox.border_width_left = 3
	stylebox.border_width_right = 3
	stylebox.border_width_top = 3
	stylebox.border_width_bottom = 3
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_left = 8
	stylebox.corner_radius_bottom_right = 8
	stylebox.shadow_size = 10
	stylebox.shadow_color = Color(0, 0, 0, 0.5)
	_drag_preview.add_theme_stylebox_override("panel", stylebox)
	
	# Add icon
	var preview_texture = TextureRect.new()
	preview_texture.texture = icon_rect.texture
	preview_texture.custom_minimum_size = Vector2(70, 70)
	preview_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	preview_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_drag_preview.add_child(preview_texture)
	
	# Add quantity label if needed
	if _item.quantity > 1:
		var qty_label = Label.new()
		qty_label.text = "x%d" % _item.quantity
		qty_label.add_theme_color_override("font_color", Color.WHITE)
		qty_label.add_theme_color_override("font_outline_color", Color.BLACK)
		qty_label.add_theme_constant_override("outline_size", 2)
		qty_label.position = Vector2(50, 50)
		_drag_preview.add_child(qty_label)
	
	_drag_preview.z_index = 100
	get_tree().root.add_child(_drag_preview)
	item_dragged.emit(_item, self)
	
	# Dim the original slot
	modulate = Color(0.5, 0.5, 0.5, 0.5)
	
	set_process(true)

func _process(delta: float) -> void:
	if _drag_preview:
		_drag_preview.global_position = get_global_mouse_position() - Vector2(30, 30)

func _end_drag() -> void:
	if not _drag_preview:
		return
		
	# Find drop target
	var mouse_pos = get_global_mouse_position()
	var drop_target = _find_slot_at_position(mouse_pos)
	
	if drop_target and drop_target != self:
		item_dropped.emit(_item, drop_target)
		print("[ItemSlot] Item dropped on target: ", drop_target.name if drop_target.name else "unknown")
	else:
		# If no specific target found, emit to self (or let InventoryScreen handle the 'no target' case)
		# Always emit signal - let InventoryScreen handle the logic
		item_dropped.emit(_item, self)
		print("[ItemSlot] Item dropped on target: ", name)
	
	# Cleanup
	_drag_preview.queue_free()
	_drag_preview = null
	
	# Restore original slot appearance
	modulate = Color(1, 1, 1, 1)
	
	set_process(false)

func _exit_tree() -> void:
	if _drag_preview:
		_drag_preview.queue_free()
		_drag_preview = null

func _find_slot_at_position(pos: Vector2) -> Control:
	# Find the ItemSlot at the given position
	var viewport = get_viewport()
	if not viewport:
		return null
		
	# Search through inventory screen for slots
	var current_scene = get_tree().current_scene
	if not current_scene:
		current_scene = get_tree().root
		
	# Recursive search for ItemSlot nodes
	return _find_slot_recursive(current_scene, pos)

func _find_slot_recursive(node: Node, pos: Vector2) -> Control:
	# Check if this node is a valid slot (but not self)
	if node != self and node is Control and node.has_method("set_item"):
		var control = node as Control
		var rect = Rect2(control.global_position, control.size)
		if rect.has_point(pos):
			print("[ItemSlot] Found slot at position: ", node.name if node.name else "unnamed")
			return control
	
	# Check children
	for child in node.get_children():
		var result = _find_slot_recursive(child, pos)
		if result:
			return result
	
	return null

func set_item(item: ItemData) -> void:
	if not is_node_ready():
		await ready

	_item = item
	_slot_name = ""
	_is_equipment_slot = false
	
	if trash_icon:
		trash_icon.visible = false
	
	if not item:
		visible = false
		return
	
	visible = true
	
	# Icon
	if item.icon and ResourceLoader.exists(item.icon):
		icon_rect.texture = load(item.icon)
	elif item.icon and typeof(item.icon) == TYPE_STRING and item.icon.begins_with("http"):
		# TODO: support HTTP icons via HTTPRequest asynchronously in the future
		print("[ItemSlot] Icon is an external URL (not yet supported): ", item.icon)
		icon_rect.texture = null
	else:
		if item.icon and item.icon != null:
			print("[ItemSlot] Icon path not found: ", item.icon, " for item: ", item.item_id)
		icon_rect.texture = null
	
	# Enhancement
	if item.enhancement_level > 0:
		enhancement_label.visible = true
		enhancement_label.text = "+%d" % item.enhancement_level
	else:
		enhancement_label.visible = false
	
	# Quantity
	if item.quantity > 1:
		quantity_label.text = "x%d" % item.quantity
		quantity_label.visible = true
	else:
		quantity_label.visible = false
	
	# Rarity Border
	rarity_border.border_color = item.get_rarity_color()
	
	# Tooltip
	tooltip_text = "%s\n%s" % [item.name, _get_type_text(item)]

func _get_type_text(item: ItemData) -> String:
	var type_text = ""
	match item.item_type:
		ItemData.ItemType.WEAPON: type_text = "Silah"
		ItemData.ItemType.ARMOR: type_text = "Zırh"
		ItemData.ItemType.POTION: type_text = "İksir"
		ItemData.ItemType.MATERIAL: type_text = "Materyal"
		_: type_text = "Eşya"
		
	if item.is_equipment() and item.required_level > 1:
		type_text += " • Lvl %d" % item.required_level
	elif item.is_consumable() and item.energy_restore > 0:
		type_text += " • +%d Enerji" % item.energy_restore
	
	return type_text

func set_equipment_slot(slot_name: String) -> void:
	if not is_node_ready():
		await ready

	_slot_name = slot_name
	_item = null
	_is_equipment_slot = true
	
	if trash_icon:
		trash_icon.visible = false
	
	# Placeholder visuals based on slot name
	quantity_label.visible = false
	icon_rect.texture = null
	rarity_border.border_color = Color(0.3, 0.3, 0.3)
	enhancement_label.visible = false
	tooltip_text = slot_name.capitalize() + " (Boş)"

func set_trash_slot() -> void:
	if not is_node_ready():
		await ready
		
	_is_trash_slot = true
	_item = null
	_slot_name = "trash"
	
	# Show trash icon
	if trash_icon:
		trash_icon.visible = true
	
	icon_rect.visible = false
	quantity_label.visible = false
	enhancement_label.visible = false
	rarity_border.border_color = Color(0.8, 0.2, 0.2)
	background.color = Color(0.2, 0.1, 0.1, 0.8)
	tooltip_text = "Eşyaları silmek için buraya sürükleyin"

func is_trash_slot() -> bool:
	return _is_trash_slot

func get_slot_position() -> int:
	return slot_position

func get_item() -> ItemData:
	return _item

func _on_pressed() -> void:
	if _item:
		slot_clicked.emit(_item)
	elif not _slot_name.is_empty():
		# Special signal or handling for empty equipment slot click could go here
		# For now, just emit null
		slot_clicked.emit(null)
