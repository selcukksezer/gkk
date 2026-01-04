extends Control
## Base Dialog
## Base class for all dialogs

signal closed(result: Variant)

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
var close_button: Button = null

var can_close: bool = true

func _ready() -> void:
	close_button = get_node_or_null("Panel/MarginContainer/VBoxContainer/TopBar/CloseButton") as Button
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	
	# Center dialog
	_center_dialog()

func _center_dialog() -> void:
	if panel:
		panel.position = (get_viewport_rect().size - panel.size) / 2

func set_title(title: String) -> void:
	if title_label:
		title_label.text = title

func close_dialog(result: Variant = null) -> void:
	if can_close:
		closed.emit(result)
		queue_free()

func _on_close_pressed() -> void:
	close_dialog(null)

## Override in child classes
func setup(_data: Dictionary) -> void:
	pass
