extends Control
class_name CharacterPaperdoll

## Character Paperdoll - Visual representation of equipped items
## Shows character with equipped items as sprite layers

signal paperdoll_clicked()

@onready var base_character: Sprite2D = $Layers/BaseCharacter
@onready var weapon_layer: Sprite2D = $Layers/WeaponLayer
@onready var helmet_layer: Sprite2D = $Layers/HelmetLayer
@onready var chest_layer: Sprite2D = $Layers/ChestLayer
@onready var gloves_layer: Sprite2D = $Layers/GlovesLayer
@onready var pants_layer: Sprite2D = $Layers/PantsLayer
@onready var boots_layer: Sprite2D = $Layers/BootsLayer

func _ready():
	# Connect to equipment changes
	var equipment_manager = get_node_or_null("/root/Equipment")
	if equipment_manager:
		equipment_manager.equipment_changed.connect(_on_equipment_changed)
	
	# Initial load
	_update_all_visuals()

func _on_equipment_changed(slot: String, item: ItemData):
	print("[CharacterPaperdoll] Equipment changed: ", slot, " -> ", item.name if item else "none")
	match slot:
		"WEAPON":
			_update_weapon(item)
		"HEAD":
			_update_helmet(item)
		"CHEST":
			_update_chest(item)
		"HANDS":
			_update_gloves(item)
		"LEGS":
			_update_pants(item)
		"FEET":
			_update_boots(item)

func _update_all_visuals():
	var equipment_manager = get_node_or_null("/root/Equipment")
	if not equipment_manager:
		return
		
	for slot_key in equipment_manager.equipped_items:
		var item = equipment_manager.equipped_items[slot_key]
		_on_equipment_changed(slot_key, item)

func _update_weapon(item: ItemData):
	if item:
		# Placeholder: tint with rarity color
		weapon_layer.modulate = item.get_rarity_color()
		weapon_layer.visible = true
	else:
		weapon_layer.visible = false

func _update_helmet(item: ItemData):
	if item:
		helmet_layer.modulate = item.get_rarity_color()
		helmet_layer.visible = true
	else:
		helmet_layer.visible = false

func _update_chest(item: ItemData):
	if item:
		chest_layer.modulate = item.get_rarity_color()
		chest_layer.visible = true
	else:
		chest_layer.visible = false

func _update_gloves(item: ItemData):
	if item:
		gloves_layer.modulate = item.get_rarity_color()
		gloves_layer.visible = true
	else:
		gloves_layer.visible = false

func _update_pants(item: ItemData):
	if item:
		pants_layer.modulate = item.get_rarity_color()
		pants_layer.visible = true
	else:
		pants_layer.visible = false

func _update_boots(item: ItemData):
	if item:
		boots_layer.modulate = item.get_rarity_color()
		boots_layer.visible = true
	else:
		boots_layer.visible = false

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		paperdoll_clicked.emit()
