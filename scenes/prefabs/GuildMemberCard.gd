extends PanelContainer
## Guild Member Card

signal kicked(member)
signal promoted(member)
signal demoted(member)

@onready var username_label = $HBox/Username
@onready var level_label = $HBox/Level
@onready var role_label = $HBox/Role
@onready var contribution_label = $HBox/Contribution
@onready var online_indicator = $HBox/OnlineIndicator

@onready var context_menu = $ContextMenu

var _member: GuildMemberData

func _ready() -> void:
	gui_input.connect(_on_gui_input)

func set_member(member: GuildMemberData) -> void:
	_member = member
	
	username_label.text = member.username
	level_label.text = "Lv. %d" % member.level
	role_label.text = member.get_role_display()
	contribution_label.text = "Contrib: %d" % member.contribution
	
	# Online status
	online_indicator.modulate = Color.GREEN if member.is_online else Color.GRAY

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			# Show context menu
			_show_context_menu()

func _show_context_menu() -> void:
	# TODO: Implement context menu
	pass
