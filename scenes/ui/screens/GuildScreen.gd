extends Control
## Guild screen showing guild info and member list
## Displays guild details, members, and guild management options

@onready var guild_name_label: Label = %GuildNameLabel
@onready var guild_level_label: Label = %GuildLevelLabel
@onready var guild_description_label: Label = %GuildDescriptionLabel
@onready var member_count_label: Label = %MemberCountLabel
@onready var member_list: VBoxContainer = %MemberList
@onready var guild_stats_container: VBoxContainer = %GuildStatsContainer
@onready var leave_button: Button = %LeaveButton
@onready var invite_button: Button = %InviteButton
@onready var manage_button: Button = %ManageButton
@onready var no_guild_panel: Control = %NoGuildPanel
@onready var guild_info_panel: Control = %GuildInfoPanel
@onready var search_guild_input: LineEdit = %SearchGuildInput
var join_guild_button: Button = null

var guild_manager: Node
var current_guild: Dictionary = {}
var player_role: String = ""

enum MemberRole {
	LEADER,
	OFFICER,
	MEMBER
}

func _ready() -> void:
	guild_manager = get_node("/root/GuildManager") if has_node("/root/GuildManager") else null
	
	if guild_manager:
		# Connect guild signals
		if guild_manager.has_signal("guild_joined"):
			guild_manager.guild_joined.connect(_on_guild_joined)
		if guild_manager.has_signal("guild_left"):
			guild_manager.guild_left.connect(_on_guild_left)
		if guild_manager.has_signal("guild_updated"):
			guild_manager.guild_updated.connect(_on_guild_updated)
		if guild_manager.has_signal("member_joined"):
			guild_manager.member_joined.connect(_on_member_changed)
		if guild_manager.has_signal("member_left"):
			guild_manager.member_left.connect(_on_member_changed)
	
	if leave_button:
		leave_button.pressed.connect(_on_leave_pressed)
	if invite_button:
		invite_button.pressed.connect(_on_invite_pressed)
	if manage_button:
		manage_button.pressed.connect(_on_manage_pressed)
	# Connect join button only if present in scene
	var jb = find_child("JoinGuildButton", true, false)
	if jb and jb is Button:
		join_guild_button = jb
		join_guild_button.pressed.connect(_on_join_guild_pressed)
	else:
		# If there's no dedicated Join button in the scene, allow Enter on the search input to trigger join
		if search_guild_input:
			var sig = ""
			if search_guild_input.has_signal("text_submitted"):
				sig = "text_submitted"
			elif search_guild_input.has_signal("text_entered"):
				sig = "text_entered"
			if sig != "":
				# Connect with a short lambda to ignore the text argument and call our handler
				search_guild_input.connect(sig, Callable(func(_t): _on_join_guild_pressed()))
	
	_load_guild_info()

func _load_guild_info() -> void:
	if not guild_manager or not guild_manager.has_method("get_player_guild"):
		_show_no_guild()
		return
	
	current_guild = guild_manager.get_player_guild()
	
	if current_guild.is_empty():
		_show_no_guild()
		return
	
	_show_guild_info()

func _show_no_guild() -> void:
	no_guild_panel.visible = true
	guild_info_panel.visible = false

func _show_guild_info() -> void:
	no_guild_panel.visible = false
	guild_info_panel.visible = true
	
	# Update guild info
	guild_name_label.text = current_guild.get("name", "Lonca")
	guild_level_label.text = "Seviye %d" % current_guild.get("level", 1)
	guild_description_label.text = current_guild.get("description", "")
	
	var members = current_guild.get("members", [])
	var max_members = current_guild.get("max_members", 50)
	member_count_label.text = "Üyeler: %d/%d" % [members.size(), max_members]
	
	# Update guild stats
	_update_guild_stats()
	
	# Load members
	_load_members()
	
	# Update buttons based on player role
	player_role = _get_player_role()
	manage_button.visible = player_role == "leader" or player_role == "officer"
	invite_button.visible = player_role == "leader" or player_role == "officer"

func _update_guild_stats() -> void:
	_clear_container(guild_stats_container)
	
	var stats = current_guild.get("stats", {})
	
	# Total power
	var power_label = _create_stat_label("Güç", str(stats.get("total_power", 0)))
	guild_stats_container.add_child(power_label)
	
	# Weekly activity
	var activity_label = _create_stat_label("Haftalık Aktivite", str(stats.get("weekly_activity", 0)))
	guild_stats_container.add_child(activity_label)
	
	# Guild rank
	var rank_label = _create_stat_label("Sıralama", "#%d" % stats.get("rank", 0))
	guild_stats_container.add_child(rank_label)

func _create_stat_label(title: String, value: String) -> Control:
	var hbox = HBoxContainer.new()
	
	var title_label = Label.new()
	title_label.text = title + ":"
	title_label.custom_minimum_size.x = 150
	hbox.add_child(title_label)
	
	var value_label = Label.new()
	value_label.text = value
	value_label.modulate = Color.YELLOW
	hbox.add_child(value_label)
	
	return hbox

func _load_members() -> void:
	_clear_container(member_list)
	
	var members = current_guild.get("members", [])
	
	if members.is_empty():
		var empty_label = Label.new()
		empty_label.text = "Üye bulunamadı"
		empty_label.modulate = Color(0.6, 0.6, 0.6)
		member_list.add_child(empty_label)
		return
	
	# Sort members by role and level
	members.sort_custom(_sort_members)
	
	for member in members:
		var member_item = _create_member_item(member)
		member_list.add_child(member_item)

func _sort_members(a: Dictionary, b: Dictionary) -> bool:
	# Sort by role first
	var role_order = {"leader": 0, "officer": 1, "member": 2}
	var a_order = role_order.get(a.get("role", "member"), 2)
	var b_order = role_order.get(b.get("role", "member"), 2)
	
	if a_order != b_order:
		return a_order < b_order
	
	# Then by level
	return a.get("level", 0) > b.get("level", 0)

func _create_member_item(member: Dictionary) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size.y = 60
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	panel.add_child(margin)
	
	var hbox = HBoxContainer.new()
	margin.add_child(hbox)
	
	# Member info
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)
	
	# Name and level
	var name_label = Label.new()
	name_label.text = "%s (Seviye %d)" % [member.get("name", "Unknown"), member.get("level", 1)]
	name_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(name_label)
	
	# Role
	var role_label = Label.new()
	var role = member.get("role", "member")
	var role_text = ""
	var role_color = Color.WHITE
	
	match role:
		"leader":
			role_text = "👑 Lider"
			role_color = Color.GOLD
		"officer":
			role_text = "⭐ Subay"
			role_color = Color.ORANGE
		_:
			role_text = "Üye"
			role_color = Color(0.8, 0.8, 0.8)
	
	role_label.text = role_text
	role_label.modulate = role_color
	role_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(role_label)
	
	# Online status
	var status_label = Label.new()
	var is_online = member.get("is_online", false)
	status_label.text = "● Çevrimiçi" if is_online else "○ Çevrimdışı"
	status_label.modulate = Color.GREEN if is_online else Color.GRAY
	status_label.custom_minimum_size.x = 100
	hbox.add_child(status_label)
	
	# Contribution
	var contribution = member.get("contribution", 0)
	var contrib_label = Label.new()
	contrib_label.text = "Katkı: %d" % contribution
	contrib_label.custom_minimum_size.x = 100
	contrib_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(contrib_label)
	
	# Actions for leaders/officers
	if player_role == "leader" or (player_role == "officer" and role == "member"):
		var actions_button = MenuButton.new()
		actions_button.text = "⋮"
		actions_button.custom_minimum_size.x = 40
		
		var popup = actions_button.get_popup()
		popup.add_item("Profil Görüntüle", 0)
		popup.add_item("Mesaj Gönder", 1)
		
		if player_role == "leader":
			popup.add_separator()
			if role == "member":
				popup.add_item("Subay Yap", 2)
			elif role == "officer":
				popup.add_item("Subaylıktan Al", 3)
			popup.add_item("Loncadan At", 4)
		
		popup.index_pressed.connect(_on_member_action.bind(member))
		hbox.add_child(actions_button)
	
	return panel

func _get_player_role() -> String:
	if not guild_manager or not guild_manager.has_method("get_player_role"):
		return "member"
	
	return guild_manager.get_player_role()

func _on_leave_pressed() -> void:
	# Show confirmation dialog
	var dialog = ConfirmationDialog.new()
	dialog.title = "Loncadan Ayrıl"
	dialog.dialog_text = "Loncadan ayrılmak istediğinizden emin misiniz?"
	add_child(dialog)
	dialog.confirmed.connect(_leave_guild)
	dialog.popup_centered()

func _leave_guild() -> void:
	if guild_manager and guild_manager.has_method("leave_guild"):
		guild_manager.leave_guild()

func _on_invite_pressed() -> void:
	# Show invite dialog
	var dialog = _create_invite_dialog()
	add_child(dialog)
	dialog.popup_centered()

func _create_invite_dialog() -> AcceptDialog:
	var dialog = AcceptDialog.new()
	dialog.title = "Oyuncu Davet Et"
	dialog.size = Vector2(400, 200)
	
	var vbox = VBoxContainer.new()
	
	var label = Label.new()
	label.text = "Davet edilecek oyuncunun adı:"
	vbox.add_child(label)
	
	var input = LineEdit.new()
	input.placeholder_text = "Oyuncu adı..."
	vbox.add_child(input)
	
	dialog.add_child(vbox)
	
	dialog.confirmed.connect(func():
		if guild_manager and guild_manager.has_method("invite_player"):
			guild_manager.invite_player(input.text.strip_edges())
	)
	
	return dialog

func _on_manage_pressed() -> void:
	# Open guild management screen
	if guild_manager and guild_manager.has_method("open_guild_management"):
		guild_manager.open_guild_management()

func _on_join_guild_pressed() -> void:
	var search_term = search_guild_input.text.strip_edges()
	
	if search_term.is_empty():
		return
	
	if guild_manager and guild_manager.has_method("search_and_join_guild"):
		guild_manager.search_and_join_guild(search_term)

func _on_member_action(index: int, member: Dictionary) -> void:
	match index:
		0: # View profile
			_view_member_profile(member)
		1: # Send message
			_send_message_to_member(member)
		2: # Promote to officer
			_promote_member(member)
		3: # Demote from officer
			_demote_member(member)
		4: # Kick
			_kick_member(member)

func _view_member_profile(member: Dictionary) -> void:
	# TODO: Open profile screen
	pass

func _send_message_to_member(member: Dictionary) -> void:
	# TODO: Open chat with member
	pass

func _promote_member(member: Dictionary) -> void:
	if guild_manager and guild_manager.has_method("promote_member"):
		guild_manager.promote_member(member.get("id", ""))

func _demote_member(member: Dictionary) -> void:
	if guild_manager and guild_manager.has_method("demote_member"):
		guild_manager.demote_member(member.get("id", ""))

func _kick_member(member: Dictionary) -> void:
	var dialog = ConfirmationDialog.new()
	dialog.title = "Üyeyi At"
	dialog.dialog_text = "%s adlı üyeyi loncadan atmak istediğinizden emin misiniz?" % member.get("name", "")
	add_child(dialog)
	dialog.confirmed.connect(func():
		if guild_manager and guild_manager.has_method("kick_member"):
			guild_manager.kick_member(member.get("id", ""))
	)
	dialog.popup_centered()

func _clear_container(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()

# Signal handlers
func _on_guild_joined(_guild_id: String) -> void:
	_load_guild_info()

func _on_guild_left() -> void:
	_load_guild_info()

func _on_guild_updated() -> void:
	_load_guild_info()

func _on_member_changed(_member_id: String) -> void:
	_load_members()

func refresh() -> void:
	_load_guild_info()
