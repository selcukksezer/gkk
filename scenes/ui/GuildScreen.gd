extends Control
## Guild Screen
## Guild management and social features

@onready var guild_tabs = $TabContainer
@onready var members_list = $TabContainer/Members/ScrollContainer/VBoxContainer
@onready var treasury_panel = $TabContainer/Treasury
@onready var wars_panel = $TabContainer/Wars
@onready var chat_panel = $TabContainer/Chat

@onready var guild_name_label = $TopPanel/GuildName
@onready var guild_level_label = $TopPanel/Level
@onready var guild_members_label = $TopPanel/Members
@onready var guild_power_label = $TopPanel/Power

@onready var treasury_gold_label = $TabContainer/Treasury/GoldAmount
@onready var donate_amount_spin = $TabContainer/Treasury/DonateAmountSpinBox
@onready var donate_button = $TabContainer/Treasury/DonateButton
@onready var withdraw_button = $TabContainer/Treasury/WithdrawButton

@onready var leave_button = $BottomPanel/LeaveButton
@onready var back_button = $BottomPanel/BackButton

var _guild_data: Dictionary = {}
var _member_card_scene = preload("res://scenes/prefabs/GuildMemberCard.tscn")

func _ready() -> void:
	# Connect signals
	donate_button.pressed.connect(_on_donate_pressed)
	withdraw_button.pressed.connect(_on_withdraw_pressed)
	leave_button.pressed.connect(_on_leave_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Track screen
	Telemetry.track_screen("guild")
	
	# Load guild data
	_load_guild()

func _load_guild() -> void:
	var result = await Network.http_get("/guild")
	_on_guild_loaded(result)

func _on_guild_loaded(result: Dictionary) -> void:
	if not result.success:
		print("[Guild] Failed to load guild")
		return
	
	_guild_data = result.data
	
	# Update header
	guild_name_label.text = _guild_data.get("name", "No Guild")
	guild_level_label.text = "Lv. %d" % _guild_data.get("level", 1)
	guild_members_label.text = "%d/%d Members" % [
		_guild_data.get("member_count", 0),
		_guild_data.get("max_members", 50)
	]
	guild_power_label.text = "Power: %d" % _guild_data.get("total_power", 0)
	
	# Update treasury
	treasury_gold_label.text = "%d Gold" % _guild_data.get("treasury_gold", 0)
	
	# Update members list
	_refresh_members()
	
	# Show/hide withdraw button based on role
	var my_role = _guild_data.get("my_role", "member")
	withdraw_button.visible = (my_role in ["lord", "commander"])

func _refresh_members() -> void:
	# Clear list
	for child in members_list.get_children():
		child.queue_free()
	
	# Populate members
	var members = _guild_data.get("members", [])
	for member_dict in members:
		var member = GuildMemberData.from_dict(member_dict)
		var card = _member_card_scene.instantiate()
		members_list.add_child(card)
		card.set_member(member)
		card.kicked.connect(_on_member_kick.bind(member))
		card.promoted.connect(_on_member_promote.bind(member))
		card.demoted.connect(_on_member_demote.bind(member))

func _on_donate_pressed() -> void:
	var amount = int(donate_amount_spin.value)
	
	if amount <= 0:
		print("[Guild] Invalid donation amount")
		return
	
	if State.gold < amount:
		print("[Guild] Insufficient gold")
		return
	
	var body = {
		"amount": amount
	}
	
	var result = await Network.http_post("/guild/donate", body)
	_on_donated(result)
	
	Telemetry.track_event("guild", "donate", {"amount": amount})

func _on_donated(result: Dictionary) -> void:
	if result.success:
		print("[Guild] Donation successful")
		
		# Update state
		State.gold -= int(donate_amount_spin.value)
		
		# Reload guild
		_load_guild()
		
		# Reset spin box
		donate_amount_spin.value = 0
	else:
		print("[Guild] Donation failed: ", result.get("error", ""))

func _on_withdraw_pressed() -> void:
	var amount = int(donate_amount_spin.value)
	
	if amount <= 0:
		print("[Guild] Invalid withdrawal amount")
		return
	
	var body = {
		"amount": amount
	}
	
	var result = await Network.http_post("/guild/withdraw", body)
	_on_withdrawn(result)

func _on_withdrawn(result: Dictionary) -> void:
	if result.success:
		print("[Guild] Withdrawal successful")
		
		# Update state
		State.gold += int(donate_amount_spin.value)
		
		# Reload guild
		_load_guild()
		
		# Reset spin box
		donate_amount_spin.value = 0
	else:
		print("[Guild] Withdrawal failed: ", result.get("error", ""))

func _on_member_kick(member: GuildMemberData) -> void:
	var body = {
		"user_id": member.user_id
	}
	
	var result = await Network.http_post("/guild/kick", body)
	_on_member_kicked(result)

func _on_member_kicked(result: Dictionary) -> void:
	if result.success:
		print("[Guild] Member kicked")
		_load_guild()
	else:
		print("[Guild] Failed to kick member: ", result.get("error", ""))

func _on_member_promote(member: GuildMemberData) -> void:
	var body = {
		"user_id": member.user_id,
		"action": "promote"
	}
	var result = await Network.http_post("/guild/change_role", body)
	_on_role_changed(result)

func _on_member_demote(member: GuildMemberData) -> void:
	var body = {
		"user_id": member.user_id,
		"action": "demote"
	}
	
	var result = await Network.http_post("/guild/change_role", body)
	_on_role_changed(result)

func _on_role_changed(result: Dictionary) -> void:
	if result.success:
		print("[Guild] Role changed")
		_load_guild()
	else:
		print("[Guild] Failed to change role: ", result.get("error", ""))

func _on_leave_pressed() -> void:
	# TODO: Show confirmation dialog
	var result = await Network.http_post("/guild/leave", {})
	_on_left(result)

func _on_left(result: Dictionary) -> void:
	if result.success:
		print("[Guild] Left guild")
		Telemetry.track_event("guild", "leave", {})
		Scenes.change_scene("res://scenes/ui/MainMenu.tscn")
	else:
		print("[Guild] Failed to leave guild: ", result.get("error", ""))

func _on_back_pressed() -> void:
	Scenes.change_scene("res://scenes/ui/MainMenu.tscn")
