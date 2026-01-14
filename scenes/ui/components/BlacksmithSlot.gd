extends Control
class_name BlacksmithSlot

## BlacksmithSlot.gd
## A specialized slot for the Blacksmith Anvil area (Input, Output, Components)

signal item_dropped(item: ItemData)
signal slot_clicked(item: ItemData, slot_index: int)
signal item_removed(item: ItemData)

enum SlotType {
	INPUT,
	COMPONENT,
	OUTPUT
}

@export var slot_type: SlotType = SlotType.INPUT
@export var slot_index: int = -1 # specific index for component grid (0-8)

var item: ItemData = null

# Child nodes
var icon_rect: TextureRect
var quantity_label: Label
var enhancement_label: Label
var background: Panel
var flame_particles: CPUParticles2D

func _ready() -> void:
	custom_minimum_size = Vector2(90, 90)
	
	# Setup UI
	_setup_ui()
	
	# Connect signals
	gui_input.connect(_on_gui_input)

func _setup_ui() -> void:
	# Background Panel
	background = Panel.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_color = Color(0.3, 0.3, 0.3)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	background.add_theme_stylebox_override("panel", style)
	add_child(background)
	
	# Icon
	icon_rect = TextureRect.new()
	icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# Add some padding (margin 5px)
	icon_rect.offset_left = 5
	icon_rect.offset_top = 5
	icon_rect.offset_right = -5
	icon_rect.offset_bottom = -5
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon_rect)
	
	# Quantity Label
	quantity_label = Label.new()
	quantity_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	quantity_label.add_theme_color_override("font_outline_color", Color.BLACK)
	quantity_label.add_theme_constant_override("outline_size", 4)
	quantity_label.position = Vector2(-5, -5) # Margin
	quantity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(quantity_label)
	
	# Enhancement Label (Top Right)
	enhancement_label = Label.new()
	enhancement_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	enhancement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	enhancement_label.add_theme_color_override("font_color", Color(1, 0.8, 0)) # Gold
	enhancement_label.add_theme_color_override("font_outline_color", Color.BLACK)
	enhancement_label.add_theme_constant_override("outline_size", 4)
	enhancement_label.position = Vector2(-5, 5) # Margin
	enhancement_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(enhancement_label)
	
	# Flame Particles
	flame_particles = CPUParticles2D.new()
	flame_particles.position = Vector2(45, 90) # Bottom center
	flame_particles.amount = 32
	flame_particles.lifetime = 1.0
	flame_particles.speed_scale = 1.0
	flame_particles.explosiveness = 0.0
	flame_particles.randomness = 0.2
	flame_particles.lifetime_randomness = 0.3
	flame_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	flame_particles.emission_rect_extents = Vector2(40, 5)
	flame_particles.direction = Vector2(0, -1)
	flame_particles.spread = 20.0
	flame_particles.gravity = Vector2(0, 0)
	flame_particles.initial_velocity_min = 40.0
	flame_particles.initial_velocity_max = 80.0
	flame_particles.scale_amount_min = 4.0
	flame_particles.scale_amount_max = 8.0
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	flame_particles.color_ramp = gradient
	flame_particles.emitting = false
	add_child(flame_particles)
	move_child(flame_particles, 1) # Behind icon
	
	_update_visuals()

func set_item(new_item: ItemData) -> void:
	item = new_item
	_update_visuals()

func get_item() -> ItemData:
	return item

func clear() -> void:
	item = null
	_update_visuals()

func show_flame(color: Color) -> void:
	if flame_particles:
		flame_particles.color = color
		flame_particles.emitting = true

func stop_flame() -> void:
	if flame_particles:
		flame_particles.emitting = false

func set_border_color(color: Color) -> void:
	var style = background.get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		style.border_color = color

func _update_visuals() -> void:
	if not is_instance_valid(icon_rect): return
	
	if item:
		if item.icon and ResourceLoader.exists(item.icon):
			icon_rect.texture = load(item.icon)
		else:
			icon_rect.texture = null # Should have a fallback
			
		if item.quantity > 1:
			quantity_label.text = str(item.quantity)
			quantity_label.visible = true
		else:
			quantity_label.visible = false
			
		# Enhancement Level
		if item.enhancement_level > 0:
			enhancement_label.text = "+%d" % item.enhancement_level
			enhancement_label.visible = true
		else:
			enhancement_label.visible = false
			
		# Rarity Border Color
		var style = background.get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			style.border_color = item.get_rarity_color()
			
	else:
		icon_rect.texture = null
		quantity_label.visible = false
		enhancement_label.visible = false
		
		# Reset Border Color
		var style = background.get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			if slot_type == SlotType.INPUT:
				style.border_color = Color(0.6, 0.5, 0.1) # Gold-ish for Input
			elif slot_type == SlotType.OUTPUT:
				style.border_color = Color.RED # Red-ish for Output
			else:
				style.border_color = Color(0.3, 0.3, 0.3) # Layout gray for Components

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if slot_type == SlotType.OUTPUT:
		return false # Cannot drop into output
		
	if data == null: return false
	
	# Check if data is an ItemData (dragged from Inventory)
	# InventoryScreen sends item in "item" key or directly?
	# ItemSlot.gd sends: item_dragged signal. But standard Godot _get_drag_data return value is what matters.
	# Wait, ItemSlot emits signal, it might handle drag differently.
	# Let's assume standard Godot drag data is a Dictionary with "item": ItemData
	
	var dragged_item = null
	if typeof(data) == TYPE_DICTIONARY and data.has("item"):
		dragged_item = data["item"]
	elif data is ItemData:
		dragged_item = data
		
	if not dragged_item: return false
	
	# Type Validation
	if slot_type == SlotType.INPUT:
		# Only Weapons/Armor
		return dragged_item.is_equipment()
		
	if slot_type == SlotType.COMPONENT:
		# Only Scrolls or Trina (Materials)
		# For now, simplistic check. Better validation in parent.
		return dragged_item.is_material() or dragged_item.item_type == ItemData.ItemType.SCROLL
		
	return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var dragged_item = null
	if typeof(data) == TYPE_DICTIONARY and data.has("item"):
		dragged_item = data["item"]
	elif data is ItemData:
		dragged_item = data
		
	if dragged_item:
		item_dropped.emit(dragged_item)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if item:
				# Click to remove/return to inventory
				item_removed.emit(item)
			elif slot_type == SlotType.INPUT:
				# Open Inventory? (Not needed if drag/drop)
				pass
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Right click to remove
			if item:
				item_removed.emit(item)
