extends "res://scenes/ui/dialogs/BaseDialog.gd"
## Confirm Dialog
## Yes/No confirmation dialog

@onready var message_label: Label = $Panel/MarginContainer/VBoxContainer/MessageLabel
@onready var confirm_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/ConfirmButton
@onready var cancel_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/CancelButton

var on_confirm: Callable
var on_cancel: Callable

func _ready() -> void:
	super._ready()
	
	if confirm_button:
		confirm_button.pressed.connect(_on_confirm_pressed)
	
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel_pressed)

func setup(data: Dictionary) -> void:
	if data.has("title"):
		set_title(data.title)
	
	if data.has("message") and message_label:
		message_label.text = data.message
	
	if data.has("confirm_text") and confirm_button:
		confirm_button.text = data.confirm_text
	
	if data.has("cancel_text") and cancel_button:
		cancel_button.text = data.cancel_text
	
	if data.has("on_confirm"):
		on_confirm = data.on_confirm
	
	if data.has("on_cancel"):
		on_cancel = data.on_cancel

func _on_confirm_pressed() -> void:
	if on_confirm.is_valid():
		on_confirm.call()
	
	close_dialog(true)

func _on_cancel_pressed() -> void:
	if on_cancel.is_valid():
		on_cancel.call()
	
	close_dialog(false)
