extends Control
## Reputation Screen - Bandit/Hero Status System
## İtibar sistemi, haydut/kahraman durumu, etkileri

@onready var content_vbox: VBoxContainer = %ContentVBox
@onready var back_button: Button = $MarginContainer/VBox/Header/BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
	_load_reputation()
	
	print("[ReputationScreen] Ready")

func _load_reputation() -> void:
	var result = await Network.http_get("/v1/player/reputation")
	if result.success:
		_populate_reputation(result.data)

func _populate_reputation(data: Dictionary) -> void:
	for child in content_vbox.get_children():
		child.queue_free()
	
	# Status Panel
	var status_panel = PanelContainer.new()
	var status_vbox = VBoxContainer.new()
	status_panel.add_child(status_vbox)
	
	var reputation_value = data.get("value", 0)
	var status_info = _get_reputation_info(reputation_value)
	
	var status_label = Label.new()
	status_label.text = "%s %s" % [status_info.get("icon", ""), status_info.get("name", "")]
	status_label.theme_override_font_sizes["font_size"] = 48
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_vbox.add_child(status_label)
	
	var value_label = Label.new()
	value_label.text = "İtibar Puanı: %d" % reputation_value
	value_label.theme_override_font_sizes["font_size"] = 32
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_vbox.add_child(value_label)
	
	# Progress to next tier
	var next_tier = _get_next_tier(reputation_value)
	if next_tier:
		var progress_bar = ProgressBar.new()
		progress_bar.min_value = next_tier.get("min_value", 0)
		progress_bar.max_value = next_tier.get("threshold", 1000)
		progress_bar.value = reputation_value
		status_vbox.add_child(progress_bar)
		
		var progress_label = Label.new()
		progress_label.text = "Sonraki Seviye: %s (%d / %d)" % [
			next_tier.get("name", ""),
			reputation_value,
			next_tier.get("threshold", 0)
		]
		progress_label.theme_override_font_sizes["font_size"] = 20
		progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_vbox.add_child(progress_label)
	
	content_vbox.add_child(status_panel)
	
	# Effects Panel
	var effects_panel = _create_section("💫 Aktif Etkiler")
	var effects = status_info.get("effects", [])
	for effect in effects:
		var effect_label = Label.new()
		effect_label.text = "• %s" % effect
		effect_label.theme_override_font_sizes["font_size"] = 22
		effects_panel.get_child(0).add_child(effect_label)
	
	content_vbox.add_child(effects_panel)
	
	# Statistics Panel
	var stats_panel = _create_section("📊 İstatistikler")
	var stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_panel.get_child(0).add_child(stats_grid)
	
	_add_stat_row(stats_grid, "Kahraman Eylemleri:", str(data.get("hero_actions", 0)))
	_add_stat_row(stats_grid, "Haydut Eylemleri:", str(data.get("bandit_actions", 0)))
	_add_stat_row(stats_grid, "Yardım Edilen Kişi:", str(data.get("people_helped", 0)))
	_add_stat_row(stats_grid, "Soyulan Kişi:", str(data.get("people_robbed", 0)))
	_add_stat_row(stats_grid, "Tamamlanan Görevler:", str(data.get("quests_completed", 0)))
	
	content_vbox.add_child(stats_panel)
	
	# History Panel
	var history_panel = _create_section("📜 Son Olaylar")
	var history = data.get("recent_history", [])
	if history.is_empty():
		var label = Label.new()
		label.text = "Henüz kayıt yok"
		label.theme_override_font_sizes["font_size"] = 20
		history_panel.get_child(0).add_child(label)
	else:
		for entry in history.slice(0, 10):
			var hbox = HBoxContainer.new()
			
			var icon = "➕" if entry.get("change", 0) > 0 else "➖"
			var icon_label = Label.new()
			icon_label.text = icon
			icon_label.theme_override_font_sizes["font_size"] = 24
			hbox.add_child(icon_label)
			
			var info_vbox = VBoxContainer.new()
			info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_child(info_vbox)
			
			var action_label = Label.new()
			action_label.text = entry.get("action", "Eylem")
			action_label.theme_override_font_sizes["font_size"] = 20
			info_vbox.add_child(action_label)
			
			var time_label = Label.new()
			time_label.text = entry.get("timestamp", "")
			time_label.theme_override_font_sizes["font_size"] = 16
			info_vbox.add_child(time_label)
			
			var change_label = Label.new()
			var change = entry.get("change", 0)
			change_label.text = "%+d" % change
			change_label.theme_override_font_sizes["font_size"] = 24
			change_label.theme_override_colors["font_color"] = Color(0.5, 1, 0.5) if change > 0 else Color(1, 0.5, 0.5)
			hbox.add_child(change_label)
			
			history_panel.get_child(0).add_child(hbox)
	
	content_vbox.add_child(history_panel)
	
	# Tiers Info Panel
	var tiers_panel = _create_section("🎖️ İtibar Seviyeleri")
	var tiers = _get_all_tiers()
	for tier in tiers:
		var tier_hbox = HBoxContainer.new()
		
		var tier_icon = Label.new()
		tier_icon.text = tier.get("icon", "")
		tier_icon.theme_override_font_sizes["font_size"] = 32
		tier_hbox.add_child(tier_icon)
		
		var tier_info = VBoxContainer.new()
		tier_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tier_hbox.add_child(tier_info)
		
		var tier_name = Label.new()
		tier_name.text = tier.get("name", "")
		tier_name.theme_override_font_sizes["font_size"] = 24
		tier_info.add_child(tier_name)
		
		var tier_req = Label.new()
		tier_req.text = "Gerekli: %d puan" % tier.get("threshold", 0)
		tier_req.theme_override_font_sizes["font_size"] = 18
		tier_info.add_child(tier_req)
		
		tiers_panel.get_child(0).add_child(tier_hbox)
	
	content_vbox.add_child(tiers_panel)

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

func _get_reputation_info(value: int) -> Dictionary:
	if value >= 1000:
		return {
			"icon": "🦸",
			"name": "Efsane Kahraman",
			"threshold": 1000,
			"effects": [
				"Tüm şehirlerde %30 indirim",
				"PvP'de ödül %50 bonus",
				"Özel görevlere erişim",
				"NPC'ler ekstra yardımcı"
			]
		}
	elif value >= 500:
		return {
			"icon": "🛡️",
			"name": "Kahraman",
			"threshold": 500,
			"effects": [
				"Şehirlerde %20 indirim",
				"PvP'de ödül %25 bonus",
				"Muhafızlar yardımcı olur"
			]
		}
	elif value >= 100:
		return {
			"icon": "⚖️",
			"name": "İyi Vatandaş",
			"threshold": 100,
			"effects": [
				"Şehirlerde %10 indirim",
				"Güvenlik güçleri tarafsız"
			]
		}
	elif value >= -100:
		return {
			"icon": "😐",
			"name": "Tarafsız",
			"threshold": -100,
			"effects": [
				"Normal ticaret",
				"Standart güvenlik"
			]
		}
	elif value >= -500:
		return {
			"icon": "🗡️",
			"name": "Haydut",
			"threshold": -500,
			"effects": [
				"Muhafızlar düşman",
				"Şehirlerde %20 daha pahalı",
				"Yakalanırsa hapishane"
			]
		}
	else:
		return {
			"icon": "💀",
			"name": "Kara Liste",
			"threshold": -1000,
			"effects": [
				"Tüm şehirler kapalı",
				"Ödül avcıları takip eder",
				"%50 daha pahalı",
				"Sürekli tehdit altında"
			]
		}

func _get_next_tier(current_value: int) -> Dictionary:
	var tiers = [
		{"name": "İyi Vatandaş", "threshold": 100, "min_value": -100},
		{"name": "Kahraman", "threshold": 500, "min_value": 100},
		{"name": "Efsane Kahraman", "threshold": 1000, "min_value": 500}
	]
	
	for tier in tiers:
		if current_value < tier.get("threshold", 0):
			return tier
	
	return {}

func _get_all_tiers() -> Array:
	return [
		{"icon": "🦸", "name": "Efsane Kahraman", "threshold": 1000},
		{"icon": "🛡️", "name": "Kahraman", "threshold": 500},
		{"icon": "⚖️", "name": "İyi Vatandaş", "threshold": 100},
		{"icon": "😐", "name": "Tarafsız", "threshold": 0},
		{"icon": "🗡️", "name": "Haydut", "threshold": -500},
		{"icon": "💀", "name": "Kara Liste", "threshold": -1000}
	]

func _on_back_button_pressed() -> void:
	get_tree().root.get_node("Main").go_back()
