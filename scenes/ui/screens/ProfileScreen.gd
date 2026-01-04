extends Control
## Profile Screen - Player Stats, Achievements, PvP History
## Oyuncu profili, istatistikler, başarımlar, PvP geçmişi

@onready var content_vbox: VBoxContainer = %ContentVBox
@onready var back_button: Button = $MarginContainer/VBox/Header/BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
	_load_profile()
	
	print("[ProfileScreen] Ready")

func _load_profile() -> void:
	var result = await Network.http_get("/v1/player/profile")
	if result.success:
		_populate_profile(result.data)

func _populate_profile(data: Dictionary) -> void:
	for child in content_vbox.get_children():
		child.queue_free()
	
	# Player Info Section
	var info_panel = _create_section("📋 Temel Bilgiler")
	var info_grid = GridContainer.new()
	info_grid.columns = 2
	info_panel.get_child(0).add_child(info_grid)
	
	_add_stat_row(info_grid, "Ad:", data.get("name", "Oyuncu"))
	_add_stat_row(info_grid, "Seviye:", str(data.get("level", 1)))
	_add_stat_row(info_grid, "Deneyim:", "%s / %s" % [
		StringUtils.format_number(data.get("exp", 0)),
		StringUtils.format_number(data.get("exp_required", 1000))
	])
	_add_stat_row(info_grid, "Lonca:", data.get("guild_name", "Yok"))
	_add_stat_row(info_grid, "Ünvan:", data.get("title", "Yolcu"))
	
	content_vbox.add_child(info_panel)
	
	# Stats Section
	var stats_panel = _create_section("📊 İstatistikler")
	var stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_panel.get_child(0).add_child(stats_grid)
	
	var stats = data.get("stats", {})
	_add_stat_row(stats_grid, "Güç:", str(stats.get("power", 0)))
	_add_stat_row(stats_grid, "Dayanıklılık:", str(stats.get("endurance", 0)))
	_add_stat_row(stats_grid, "Çeviklik:", str(stats.get("agility", 0)))
	_add_stat_row(stats_grid, "Zeka:", str(stats.get("intelligence", 0)))
	_add_stat_row(stats_grid, "Şans:", str(stats.get("luck", 0)))
	_add_stat_row(stats_grid, "Can:", "%d / %d" % [stats.get("hp", 100), stats.get("max_hp", 100)])
	_add_stat_row(stats_grid, "Enerji:", "%d / %d" % [stats.get("energy", 50), stats.get("max_energy", 100)])
	
	content_vbox.add_child(stats_panel)
	
	# Wealth Section
	var wealth_panel = _create_section("💰 Servet")
	var wealth_grid = GridContainer.new()
	wealth_grid.columns = 2
	wealth_panel.get_child(0).add_child(wealth_grid)
	
	_add_stat_row(wealth_grid, "Altın:", StringUtils.format_number(data.get("gold", 0)))
	_add_stat_row(wealth_grid, "Elmas:", StringUtils.format_number(data.get("gems", 0)))
	_add_stat_row(wealth_grid, "Market Değeri:", StringUtils.format_number(data.get("market_value", 0)))
	
	content_vbox.add_child(wealth_panel)
	
	# PvP Section
	var pvp_panel = _create_section("⚔️ PvP İstatistikleri")
	var pvp_grid = GridContainer.new()
	pvp_grid.columns = 2
	pvp_panel.get_child(0).add_child(pvp_grid)
	
	var pvp = data.get("pvp", {})
	_add_stat_row(pvp_grid, "Sıralama:", "#%d" % pvp.get("rank", 0))
	_add_stat_row(pvp_grid, "Galibiyet:", str(pvp.get("wins", 0)))
	_add_stat_row(pvp_grid, "Mağlubiyet:", str(pvp.get("losses", 0)))
	_add_stat_row(pvp_grid, "Kazanma Oranı:", "%.1f%%" % (pvp.get("win_rate", 0) * 100))
	_add_stat_row(pvp_grid, "Kill/Death:", "%.2f" % pvp.get("kd_ratio", 0))
	
	content_vbox.add_child(pvp_panel)
	
	# Achievements Section
	var achievement_panel = _create_section("🏆 Başarımlar")
	var achievement_label = Label.new()
	achievement_label.text = "Tamamlanan: %d / %d (%%%d)" % [
		data.get("achievements_completed", 0),
		data.get("achievements_total", 100),
		(data.get("achievements_completed", 0) * 100) / max(data.get("achievements_total", 1), 1)
	]
	achievement_label.theme_override_font_sizes["font_size"] = 24
	achievement_panel.get_child(0).add_child(achievement_label)
	
	content_vbox.add_child(achievement_panel)
	
	# Reputation Section
	var rep_panel = _create_section("⭐ İtibar")
	var rep_grid = GridContainer.new()
	rep_grid.columns = 2
	rep_panel.get_child(0).add_child(rep_grid)
	
	var reputation = data.get("reputation", {})
	var rep_value = reputation.get("value", 0)
	var rep_status = _get_reputation_status(rep_value)
	
	_add_stat_row(rep_grid, "Durum:", rep_status)
	_add_stat_row(rep_grid, "Puan:", str(rep_value))
	_add_stat_row(rep_grid, "Kahraman Eylemleri:", str(reputation.get("hero_actions", 0)))
	_add_stat_row(rep_grid, "Haydut Eylemleri:", str(reputation.get("bandit_actions", 0)))
	
	content_vbox.add_child(rep_panel)
	
	# Activity Section
	var activity_panel = _create_section("📅 Aktivite")
	var activity_grid = GridContainer.new()
	activity_grid.columns = 2
	activity_panel.get_child(0).add_child(activity_grid)
	
	_add_stat_row(activity_grid, "Kayıt Tarihi:", data.get("created_at", ""))
	_add_stat_row(activity_grid, "Son Giriş:", data.get("last_login", ""))
	_add_stat_row(activity_grid, "Toplam Oyun Süresi:", "%s saat" % str(data.get("playtime_hours", 0)))
	_add_stat_row(activity_grid, "Tamamlanan Görevler:", str(data.get("quests_completed", 0)))
	
	content_vbox.add_child(activity_panel)

func _create_section(title: String) -> PanelContainer:
	var panel = PanelContainer.new()
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var title_label = Label.new()
	title_label.text = title
	title_label.theme_override_font_sizes["font_size"] = 32
	title_label.theme_override_colors["font_color"] = Color(1, 0.8, 0.3)
	vbox.add_child(title_label)
	
	return panel

func _add_stat_row(grid: GridContainer, label_text: String, value_text: String) -> void:
	var label = Label.new()
	label.text = label_text
	label.theme_override_font_sizes["font_size"] = 22
	grid.add_child(label)
	
	var value = Label.new()
	value.text = value_text
	value.theme_override_font_sizes["font_size"] = 24
	value.theme_override_colors["font_color"] = Color(0.8, 0.9, 1)
	grid.add_child(value)

func _get_reputation_status(value: int) -> String:
	if value >= 1000:
		return "🦸 Efsane Kahraman"
	elif value >= 500:
		return "🛡️ Kahraman"
	elif value >= 100:
		return "⚖️ İyi Vatandaş"
	elif value >= -100:
		return "😐 Tarafsız"
	elif value >= -500:
		return "🗡️ Haydut"
	else:
		return "💀 Kara Liste"

func _on_back_button_pressed() -> void:
	get_tree().root.get_node("Main").go_back()
