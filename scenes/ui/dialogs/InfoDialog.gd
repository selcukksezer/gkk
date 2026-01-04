extends "res://scenes/ui/dialogs/BaseDialog.gd"
## Info Dialog
## Shows information message with OK button

@onready var message_label: Label = $Panel/MarginContainer/VBoxContainer/MessageLabel
@onready var ok_button: Button = $Panel/MarginContainer/VBoxContainer/OKButton

var on_confirm: Callable

func _ready() -> void:
	super._ready()
	
	if ok_button:
		ok_button.pressed.connect(_on_ok_pressed)

func setup(data: Dictionary) -> void:
	if data.has("title"):
		set_title(data.title)
	
	if data.has("message") and message_label:
		message_label.text = data.message
	
	if data.has("on_confirm"):
		on_confirm = data.on_confirm

func _on_ok_pressed() -> void:
	if on_confirm.is_valid():
		on_confirm.call()
	
	close_dialog(true)
