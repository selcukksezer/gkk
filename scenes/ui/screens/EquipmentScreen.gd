extends Control

## Equipment Screen
## Displays all equipment slots and character paperdoll

@onready var paperdoll: CharacterPaperdoll = $MarginContainer/VBoxContainer/HBoxContainer/PaperdollContainer/Paperdoll
@onready var weapon_slot: EquipmentSlot = $MarginContainer/VBoxContainer/HBoxContainer/SlotsContainer/GridContainer/WeaponSlot
@onready var helmet_slot: EquipmentSlot = $MarginContainer/VBoxContainer/HBoxContainer/SlotsContainer/GridContainer/HelmetSlot
@onready var chest_slot: EquipmentSlot = $MarginContainer/VBoxContainer/HBoxContainer/SlotsContainer/GridContainer/ChestSlot
@onready var gloves_slot: EquipmentSlot = $MarginContainer/VBoxContainer/HBoxContainer/SlotsContainer/GridContainer/GlovesSlot
@onready var pants_slot: EquipmentSlot = $MarginContainer/VBoxContainer/HBoxContainer/SlotsContainer/GridContainer/PantsSlot
@onready var boots_slot: EquipmentSlot = $MarginContainer/VBoxContainer/HBoxContainer/SlotsContainer/GridContainer/BootsSlot
@onready var accessory1_slot: EquipmentSlot = $MarginContainer/VBoxContainer/HBoxContainer/SlotsContainer/GridContainer/Accessory1Slot
@onready var accessory2_slot: EquipmentSlot = $MarginContainer/VBoxContainer/HBoxContainer/SlotsContainer/GridContainer/Accessory2Slot

@onready var attack_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/StatsContainer/AttackLabel
@onready var defense_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/StatsContainer/DefenseLabel
@onready var health_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/StatsContainer/HealthLabel
@onready var power_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/StatsContainer/PowerLabel
@onready var close_button: Button = $MarginContainer/VBoxContainer/CloseButton if has_node("MarginContainer/VBoxContainer/CloseButton") else null

func _ready():
	var equipment_manager = get_node_or_null("/root/Equipment")
	if not equipment_manager:
		print("[EquipmentScreen] ERROR: Equipment manager not found!")
		return
	
	# Connect to stats recalculation
	equipment_manager.stats_recalculated.connect(_on_stats_recalculated)
	
	# Connect slot signals
	weapon_slot.item_equipped.connect(_on_item_equipped)
	helmet_slot.item_equipped.connect(_on_item_equipped)
	chest_slot.item_equipped.connect(_on_item_equipped)
	gloves_slot.item_equipped.connect(_on_item_equipped)
	pants_slot.item_equipped.connect(_on_item_equipped)
	boots_slot.item_equipped.connect(_on_item_equipped)
	accessory1_slot.item_equipped.connect(_on_item_equipped)
	accessory2_slot.item_equipped.connect(_on_item_equipped)
	
	# Close button
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	
	# Initial stats update
	_on_stats_recalculated(equipment_manager.get_total_stats())

func _on_item_equipped(slot_type: String, item: ItemData):
	print("[EquipmentScreen] Equipping: ", item.name, " to ", slot_type)
	var equipment_manager = get_node_or_null("/root/Equipment")
	if equipment_manager:
		equipment_manager.equip_item(item)

func _on_stats_recalculated(stats: Dictionary):
	attack_label.text = "⚔️ ATK: %d" % (stats["attack"] if "attack" in stats else 0)
	defense_label.text = "🛡️ DEF: %d" % (stats["defense"] if "defense" in stats else 0)
	health_label.text = "❤️ HP: +%d" % (stats["health"] if "health" in stats else 0)
	power_label.text = "⚡ PWR: %d" % (stats["power"] if "power" in stats else 0)

func _on_close_pressed() -> void:
	print("[EquipmentScreen] Closing")
	queue_free()

func _input(event: InputEvent) -> void:
	# ESC to close
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
