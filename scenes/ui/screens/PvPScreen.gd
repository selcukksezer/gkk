extends Control
## PvP screen showing attack/defense history and battle interface
## Displays combat logs, rankings, and allows initiating attacks

@onready var attack_history_list: VBoxContainer = %AttackHistoryList
@onready var defense_history_list: VBoxContainer = %DefenseHistoryList
@onready var player_search_input: LineEdit = %PlayerSearchInput
@onready var search_button: Button = %SearchButton
@onready var attack_button: Button = %AttackButton
@onready var stats_panel: PanelContainer = %StatsPanel
@onready var wins_label: Label = %WinsLabel
@onready var losses_label: Label = %LossesLabel
@onready var rating_label: Label = %RatingLabel
@onready var rank_label: Label = %RankLabel

var pvp_manager: Node
var selected_target: Dictionary = {}

enum BattleResult {
	WIN,
	LOSS,
	DRAW
}

func _ready() -> void:
	pvp_manager = get_node("/root/PvPManager") if has_node("/root/PvPManager") else null
	
	if pvp_manager:
		# Connect PvP signals
		if pvp_manager.has_signal("battle_completed"):
			pvp_manager.battle_completed.connect(_on_battle_completed)
		if pvp_manager.has_signal("stats_updated"):
			pvp_manager.stats_updated.connect(_on_stats_updated)
	
	search_button.pressed.connect(_on_search_pressed)
	attack_button.pressed.connect(_on_attack_pressed)
	
	_load_pvp_stats()
	_load_attack_history()
	_load_defense_history()

func _load_pvp_stats() -> void:
	if not pvp_manager or not pvp_manager.has_method("get_player_stats"):
		return
	
	var stats = pvp_manager.get_player_stats()
	
	wins_label.text = "Kazanılan: %d" % stats.get("wins", 0)
	losses_label.text = "Kaybedilen: %d" % stats.get("losses", 0)
	rating_label.text = "Puan: %d" % stats.get("rating", 1000)
	rank_label.text = "Sıralama: #%d" % stats.get("rank", 0)

func _load_attack_history() -> void:
	_clear_list(attack_history_list)
	
	if not pvp_manager or not pvp_manager.has_method("get_attack_history"):
		return
	
	var history = pvp_manager.get_attack_history()
	
	if history.is_empty():
		var empty_label = Label.new()
		empty_label.text = "Henüz saldırı geçmişi yok"
		empty_label.modulate = Color(0.6, 0.6, 0.6)
		attack_history_list.add_child(empty_label)
		return
	
	for battle in history:
		var battle_item = _create_battle_item(battle, true)
		attack_history_list.add_child(battle_item)

func _load_defense_history() -> void:
	_clear_list(defense_history_list)
	
	if not pvp_manager or not pvp_manager.has_method("get_defense_history"):
		return
	
	var history = pvp_manager.get_defense_history()
	
	if history.is_empty():
		var empty_label = Label.new()
		empty_label.text = "Henüz savunma geçmişi yok"
		empty_label.modulate = Color(0.6, 0.6, 0.6)
		defense_history_list.add_child(empty_label)
		return
	
	for battle in history:
		var battle_item = _create_battle_item(battle, false)
		defense_history_list.add_child(battle_item)

func _create_battle_item(battle: Dictionary, is_attack: bool) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size.y = 80
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	
	var hbox = HBoxContainer.new()
	margin.add_child(hbox)
	
	# Battle info
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)
	
	# Opponent name
	var opponent_name = battle.get("defender_name", "Unknown") if is_attack else battle.get("attacker_name", "Unknown")
	var opponent_label = Label.new()
	opponent_label.text = "vs %s" % opponent_name
	opponent_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(opponent_label)
	
	# Battle result
	var result_label = Label.new()
	var result = battle.get("result", "")
	var won = (is_attack and result == "attacker_win") or (not is_attack and result == "defender_win")
	
	result_label.text = "Kazanıldı ✓" if won else "Kaybedildi ✗"
	result_label.modulate = Color.GREEN if won else Color.RED
	vbox.add_child(result_label)
	
	# Timestamp
	var time_label = Label.new()
	time_label.text = _format_time(battle.get("timestamp", 0))
	time_label.add_theme_font_size_override("font_size", 11)
	time_label.modulate = Color(0.7, 0.7, 0.7)
	vbox.add_child(time_label)
	
	# Rating change
	var rating_change = battle.get("rating_change", 0)
	if rating_change != 0:
		var rating_label = Label.new()
		rating_label.text = "%+d puan" % rating_change
		rating_label.modulate = Color.YELLOW
		rating_label.custom_minimum_size.x = 100
		rating_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hbox.add_child(rating_label)
	
	# View details button
	var details_button = Button.new()
	details_button.text = "Detaylar"
	details_button.custom_minimum_size.x = 100
	details_button.pressed.connect(_on_view_battle_details.bind(battle))
	hbox.add_child(details_button)
	
	return panel

func _format_time(timestamp: int) -> String:
	if timestamp == 0:
		return "Bilinmiyor"
	
	var datetime = Time.get_datetime_dict_from_unix_time(timestamp)
	return "%02d/%02d/%04d %02d:%02d" % [
		datetime.day,
		datetime.month,
		datetime.year,
		datetime.hour,
		datetime.minute
	]

func _on_search_pressed() -> void:
	var search_term = player_search_input.text.strip_edges()
	
	if search_term.is_empty():
		return
	
	if not pvp_manager or not pvp_manager.has_method("search_player"):
		return
	
	# Search for player
	var result = pvp_manager.search_player(search_term)
	
	if result.is_empty():
		_show_notification("Oyuncu bulunamadı")
		return
	
	selected_target = result
	attack_button.disabled = false
	attack_button.text = "%s'e Saldır" % result.get("name", "Oyuncu")

func _on_attack_pressed() -> void:
	if selected_target.is_empty():
		return
	
	if not pvp_manager or not pvp_manager.has_method("initiate_attack"):
		return
	
	var target_id = selected_target.get("id", "")
	pvp_manager.initiate_attack(target_id)
	
	# Disable button temporarily
	attack_button.disabled = true
	attack_button.text = "Saldırılıyor..."

func _on_view_battle_details(battle: Dictionary) -> void:
	# Open battle details dialog
	var details_text = _format_battle_details(battle)
	_show_battle_dialog(details_text)

func _format_battle_details(battle: Dictionary) -> String:
	var text = "=== SAVAŞ DETAYLARI ===\n\n"
	
	text += "Saldırgan: %s\n" % battle.get("attacker_name", "Unknown")
	text += "Savunucu: %s\n\n" % battle.get("defender_name", "Unknown")
	
	text += "Sonuç: %s\n" % battle.get("result", "Unknown")
	text += "Puan Değişimi: %+d\n\n" % battle.get("rating_change", 0)
	
	# Battle log
	var battle_log = battle.get("battle_log", [])
	if not battle_log.is_empty():
		text += "=== SAVAŞ KAYDI ===\n"
		for entry in battle_log:
			text += "• %s\n" % entry
	
	return text

func _show_battle_dialog(details: String) -> void:
	# Create a simple popup dialog
	var dialog = AcceptDialog.new()
	dialog.title = "Savaş Detayları"
	dialog.dialog_text = details
	dialog.size = Vector2(500, 400)
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())

func _show_notification(message: String) -> void:
	# Simple notification system
	var label = Label.new()
	label.text = message
	label.position = Vector2(20, 20)
	label.modulate = Color.YELLOW
	add_child(label)
	
	# Fade out and remove
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 0.0, 2.0).set_delay(1.0)
	tween.tween_callback(label.queue_free)

func _clear_list(list: VBoxContainer) -> void:
	for child in list.get_children():
		child.queue_free()

# Signal handlers
func _on_battle_completed(battle_data: Dictionary) -> void:
	attack_button.disabled = false
	attack_button.text = "Saldır"
	selected_target = {}
	
	_load_pvp_stats()
	_load_attack_history()
	
	# Show battle result
	var result = battle_data.get("result", "")
	if result == "attacker_win":
		_show_notification("Savaşı kazandınız!")
	else:
		_show_notification("Savaşı kaybettiniz!")

func _on_stats_updated() -> void:
	_load_pvp_stats()

func refresh() -> void:
	_load_pvp_stats()
	_load_attack_history()
	_load_defense_history()
