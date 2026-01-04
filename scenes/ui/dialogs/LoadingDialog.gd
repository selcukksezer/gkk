extends "res://scenes/ui/dialogs/BaseDialog.gd"
## Loading Dialog
## Shows loading spinner with message

@onready var message_label: Label = $Panel/MarginContainer/VBoxContainer/MessageLabel
@onready var spinner: Control = $Panel/MarginContainer/VBoxContainer/Spinner

var loading_message: String = "Yükleniyor..."

func _ready() -> void:
	super._ready()
	can_close = false  # Can't close loading dialog manually
	
	if close_button:
		close_button.visible = false
	
	# Start spinner animation
	_start_spinner()

func setup(data: Dictionary) -> void:
	if data.has("message"):
		loading_message = data.message
	
	if message_label:
		message_label.text = loading_message

func _start_spinner() -> void:
	if spinner:
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(spinner, "rotation", TAU, 1.0)

func update_message(message: String) -> void:
	loading_message = message
	if message_label:
		message_label.text = message

## Call this when loading is complete
func finish_loading() -> void:
	can_close = true
	close_dialog(true)
