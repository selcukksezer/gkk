extends Control
## Guild War Screen - Weekly Tournaments & Territory Control
## Lonca savaşları, haftalık turnuvalar, bölge hakimiyeti

@onready var tournament_list: VBoxContainer = %TournamentList
@onready var territory_list: VBoxContainer = %TerritoryList
@onready var ranking_list: VBoxContainer = %RankingList
@onready var season_label: Label = %SeasonLabel
@onready var timer_label: Label = %TimerLabel
@onready var back_button: Button = $MarginContainer/VBox/Header/BackButton
@onready var tab_container: TabContainer = $MarginContainer/VBox/TabContainer

var current_season: Dictionary = {}

func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
	tab_container.tab_changed.connect(_on_tab_changed)
	
	_load_season_info()
	_load_tournaments()
	
	print("[GuildWarScreen] Ready")

func _load_season_info() -> void:
	var result = await Network.http_get("/v1/guild_war/season")
	if result.success:
		current_season = result.data
		_update_season_display()

func _update_season_display() -> void:
	var season_num = current_season.get("season_number", 1)
	var week = current_season.get("week", 1)
	season_label.text = "Sezon %d - Hafta %d" % [season_num, week]
	
	var remaining = current_season.get("time_remaining", 0)
	timer_label.text = "Kalan Süre: %s" % _format_time(remaining)

func _load_tournaments() -> void:
	var result = await Network.http_get("/v1/guild_war/tournaments")
	if result.success:
		_populate_tournaments(result.data.get("tournaments", []))

func _populate_tournaments(tournaments: Array) -> void:
	for child in tournament_list.get_children():
		child.queue_free()
	
	if tournaments.is_empty():
		var label = Label.new()
		label.text = "Aktif turnuva yok"
		label.theme_override_font_sizes["font_size"] = 24
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tournament_list.add_child(label)
		return
	
	for tournament in tournaments:
		var panel = PanelContainer.new()
		var vbox = VBoxContainer.new()
		panel.add_child(vbox)
		
		# Tournament Header
		var header = HBoxContainer.new()
		vbox.add_child(header)
		
		var name_label = Label.new()
		name_label.text = tournament.get("name", "Turnuva")
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.theme_override_font_sizes["font_size"] = 32
		name_label.theme_override_colors["font_color"] = Color(1, 0.8, 0.3)
		header.add_child(name_label)
		
		var status_label = Label.new()
		var status = tournament.get("status", "upcoming")
		status_label.text = _get_status_text(status)
		status_label.theme_override_font_sizes["font_size"] = 24
		header.add_child(status_label)
		
		# Details
		var details_label = Label.new()
		details_label.text = "Katılımcı: %d Lonca | Ödül Havuzu: %s 💰" % [
			tournament.get("guild_count", 0),
			StringUtils.format_number(tournament.get("prize_pool", 0))
		]
		details_label.theme_override_font_sizes["font_size"] = 20
		vbox.add_child(details_label)
		
		# Time
		var time_label = Label.new()
		if status == "active":
			var remaining = tournament.get("time_remaining", 0)
			time_label.text = "Kalan Süre: %s" % _format_time(remaining)
		else:
			time_label.text = "Başlangıç: %s" % tournament.get("start_time", "")
		time_label.theme_override_font_sizes["font_size"] = 18
		vbox.add_child(time_label)
		
		# Actions
		if status == "upcoming":
			var join_btn = Button.new()
			join_btn.text = "KATIL"
			join_btn.theme_override_font_sizes["font_size"] = 24
			join_btn.pressed.connect(func(): _join_tournament(tournament.get("id")))
			vbox.add_child(join_btn)
		elif status == "active":
			var view_btn = Button.new()
			view_btn.text = "DETAYLAR"
			view_btn.theme_override_font_sizes["font_size"] = 24
			view_btn.pressed.connect(func(): _view_tournament_details(tournament.get("id")))
			vbox.add_child(view_btn)
		
		tournament_list.add_child(panel)

func _load_territories() -> void:
	var result = await Network.http_get("/v1/guild_war/territories")
	if result.success:
		_populate_territories(result.data.get("territories", []))

func _populate_territories(territories: Array) -> void:
	for child in territory_list.get_children():
		child.queue_free()
	
	for territory in territories:
		var panel = PanelContainer.new()
		var vbox = VBoxContainer.new()
		panel.add_child(vbox)
		
		var hbox = HBoxContainer.new()
		vbox.add_child(hbox)
		
		# Territory info
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info_vbox)
		
		var name_label = Label.new()
		name_label.text = territory.get("name", "Bölge")
		name_label.theme_override_font_sizes["font_size"] = 28
		info_vbox.add_child(name_label)
		
		var owner_label = Label.new()
		var guild_owner = territory.get("owner_guild", "Sahipsiz")
		owner_label.text = "Sahibi: %s" % guild_owner
		owner_label.theme_override_font_sizes["font_size"] = 20
		info_vbox.add_child(owner_label)
		
		var bonus_label = Label.new()
		bonus_label.text = "Bonus: %s" % territory.get("bonus_description", "")
		bonus_label.theme_override_font_sizes["font_size"] = 18
		info_vbox.add_child(bonus_label)
		
		# Attack button
		if territory.get("can_attack", false):
			var attack_btn = Button.new()
			attack_btn.custom_minimum_size = Vector2(180, 80)
			attack_btn.text = "SALDIRI"
			attack_btn.theme_override_font_sizes["font_size"] = 24
			attack_btn.pressed.connect(func(): _attack_territory(territory.get("id")))
			hbox.add_child(attack_btn)
		
		territory_list.add_child(panel)

func _load_rankings() -> void:
	var result = await Network.http_get("/v1/guild_war/rankings")
	if result.success:
		_populate_rankings(result.data.get("rankings", []))

func _populate_rankings(rankings: Array) -> void:
	for child in ranking_list.get_children():
		child.queue_free()
	
	var rank = 1
	for guild in rankings:
		var panel = PanelContainer.new()
		var hbox = HBoxContainer.new()
		panel.add_child(hbox)
		
		# Rank
		var rank_label = Label.new()
		rank_label.text = _get_rank_emoji(rank)
		rank_label.theme_override_font_sizes["font_size"] = 32
		rank_label.custom_minimum_size = Vector2(80, 0)
		hbox.add_child(rank_label)
		
		# Guild info
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info_vbox)
		
		var name_label = Label.new()
		name_label.text = guild.get("guild_name", "Lonca")
		name_label.theme_override_font_sizes["font_size"] = 26
		info_vbox.add_child(name_label)
		
		var score_label = Label.new()
		score_label.text = "Savaş Puanı: %s | Bölge: %d" % [
			StringUtils.format_number(guild.get("war_points", 0)),
			guild.get("territory_count", 0)
		]
		score_label.theme_override_font_sizes["font_size"] = 18
		info_vbox.add_child(score_label)
		
		ranking_list.add_child(panel)
		rank += 1

func _join_tournament(tournament_id: int) -> void:
	var result = await Network.http_post("/v1/guild_war/join", {"tournament_id": tournament_id})
	if result.success:
		_show_success("Turnuvaya katıldınız!")
		_load_tournaments()
	else:
		_show_error(result.get("error", "Katılım başarısız"))

func _view_tournament_details(tournament_id: int) -> void:
	_show_success("Turnuva detayları (geliştirme aşamasında)")

func _attack_territory(territory_id: int) -> void:
	var result = await Network.http_post("/v1/guild_war/attack", {"territory_id": territory_id})
	if result.success:
		_show_success("Saldırı başlatıldı!")
		_load_territories()
	else:
		_show_error(result.get("error", "Saldırı başarısız"))

func _get_status_text(status: String) -> String:
	match status:
		"upcoming": return "🔜 Yakında"
		"active": return "🔥 Aktif"
		"completed": return "✅ Tamamlandı"
		_: return status

func _get_rank_emoji(rank: int) -> String:
	match rank:
		1: return "🥇"
		2: return "🥈"
		3: return "🥉"
		_: return "#%d" % rank

func _format_time(seconds: int) -> String:
	var days = seconds / 86400
	var hours = (seconds % 86400) / 3600
	var minutes = (seconds % 3600) / 60
	
	if days > 0:
		return "%dg %ds %dd" % [days, hours, minutes]
	elif hours > 0:
		return "%ds %dd" % [hours, minutes]
	else:
		return "%dd" % minutes

func _on_tab_changed(tab: int) -> void:
	match tab:
		1:  # Territories
			_load_territories()
		2:  # Rankings
			_load_rankings()

func _on_back_button_pressed() -> void:
	get_tree().root.get_node("Main").go_back()

func _show_error(message: String) -> void:
	var dialog_scene = load("res://scenes/ui/dialogs/ErrorDialog.tscn")
	if dialog_scene:
		get_tree().root.get_node("Main").show_dialog(dialog_scene, {
			"title": "Hata",
			"message": message
		})

func _show_success(message: String) -> void:
	var dialog_scene = load("res://scenes/ui/dialogs/InfoDialog.tscn")
	if dialog_scene:
		get_tree().root.get_node("Main").show_dialog(dialog_scene, {
			"title": "Başarılı",
			"message": message
		})
