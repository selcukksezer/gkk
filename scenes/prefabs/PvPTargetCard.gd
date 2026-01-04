extends PanelContainer
## PvP Target Card

signal clicked(target)

@onready var username_label = $VBox/Username
@onready var level_label = $VBox/Level
@onready var power_label = $VBox/Power
@onready var gold_label = $VBox/Gold

var _target: Dictionary

func _ready() -> void:
	gui_input.connect(_on_gui_input)

func set_target(target: Dictionary) -> void:
	_target = target
	
	username_label.text = target.get("username", "Unknown")
	level_label.text = "Lv. %d" % target.get("level", 1)
	power_label.text = "Power: %d" % target.get("power", 0)
	gold_label.text = "Gold: %d" % target.get("gold", 0)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit(_target)
