extends Control
## Event Screen - Active Events, Seasonal Content
## Etkinlikler, sezonluk içerik, özel ödüller

@onready var active_list: VBoxContainer = %ActiveList
@onready var upcoming_list: VBoxContainer = %UpcomingList
@onready var history_list: VBoxContainer = %HistoryList
@onready var back_button: Button = $MarginContainer/VBox/Header/BackButton
@onready var tab_container: TabContainer = $MarginContainer/VBox/TabContainer

func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
	tab_container.tab_changed.connect(_on_tab_changed)
	
	_load_active_events()
	
	print("[EventScreen] Ready")

func _load_active_events() -> void:
	var result = await Network.http_get("/v1/events/active")
	if result.success:
		_populate_events(active_list, result.data.get("events", []), true)

func _load_upcoming_events() -> void:
	var result = await Network.http_get("/v1/events/upcoming")
	if result.success:
		_populate_events(upcoming_list, result.data.get("events", []), false)

func _load_event_history() -> void:
	var result = await Network.http_get("/v1/events/history?limit=20")
	if result.success:
		_populate_history(result.data.get("events", []))

func _populate_events(list: VBoxContainer, events: Array, is_active: bool) -> void:
	for child in list.get_children():
		child.queue_free()
	
	if events.is_empty():
		var label = Label.new()
		label.text = "Etkinlik yok"
		label.theme_override_font_sizes["font_size"] = 24
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list.add_child(label)
		return
	
	for event in events:
		var panel = PanelContainer.new()
		var vbox = VBoxContainer.new()
		panel.add_child(vbox)
		
		# Event Header
		var header = HBoxContainer.new()
		vbox.add_child(header)
		
		var icon_label = Label.new()
		icon_label.text = event.get("icon", "🎪")
		icon_label.theme_override_font_sizes["font_size"] = 48
		header.add_child(icon_label)
		
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(info_vbox)
		
		var name_label = Label.new()
		name_label.text = event.get("name", "Etkinlik")
		name_label.theme_override_font_sizes["font_size"] = 32
		name_label.theme_override_colors["font_color"] = Color(1, 0.8, 0.3)
		info_vbox.add_child(name_label)
		
		var type_label = Label.new()
		type_label.text = _get_event_type_text(event.get("type", ""))
		type_label.theme_override_font_sizes["font_size"] = 20
		info_vbox.add_child(type_label)
		
		# Description
		var desc_label = Label.new()
		desc_label.text = event.get("description", "")
		desc_label.theme_override_font_sizes["font_size"] = 18
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(desc_label)
		
		# Time
		var time_hbox = HBoxContainer.new()
		vbox.add_child(time_hbox)
		
		var time_label = Label.new()
		if is_active:
			var remaining = event.get("time_remaining", 0)
			time_label.text = "⏰ Kalan Süre: %s" % _format_time(remaining)
			time_label.theme_override_colors["font_color"] = Color(1, 0.5, 0.5)
		else:
			time_label.text = "📅 Başlangıç: %s" % event.get("start_time", "")
		time_label.theme_override_font_sizes["font_size"] = 20
		time_hbox.add_child(time_label)
		
		# Progress (if active)
		if is_active and event.has("progress"):
			var progress = event.get("progress", 0)
			var progress_bar = ProgressBar.new()
			progress_bar.max_value = 100
			progress_bar.value = progress
			vbox.add_child(progress_bar)
			
			var progress_label = Label.new()
			progress_label.text = "İlerleme: %%%d" % progress
			progress_label.theme_override_font_sizes["font_size"] = 18
			vbox.add_child(progress_label)
		
		# Rewards
		var rewards_label = Label.new()
		rewards_label.text = "🎁 Ödüller: %s" % event.get("rewards_text", "Çeşitli ödüller")
		rewards_label.theme_override_font_sizes["font_size"] = 20
		rewards_label.theme_override_colors["font_color"] = Color(0.5, 1, 0.5)
		vbox.add_child(rewards_label)
		
		# Buttons
		if is_active:
			var button_box = HBoxContainer.new()
			vbox.add_child(button_box)
			
			var participate_btn = Button.new()
			participate_btn.text = "KATIL"
			participate_btn.theme_override_font_sizes["font_size"] = 24
			participate_btn.pressed.connect(func(): _participate_event(event.get("id")))
			button_box.add_child(participate_btn)
			
			var details_btn = Button.new()
			details_btn.text = "DETAYLAR"
			details_btn.theme_override_font_sizes["font_size"] = 24
			details_btn.pressed.connect(func(): _show_event_details(event))
			button_box.add_child(details_btn)
			
			if event.get("can_claim_reward", false):
				var claim_btn = Button.new()
				claim_btn.text = "ÖDÜL AL"
				claim_btn.theme_override_font_sizes["font_size"] = 24
				claim_btn.pressed.connect(func(): _claim_event_reward(event.get("id")))
				button_box.add_child(claim_btn)
		
		list.add_child(panel)

func _populate_history(events: Array) -> void:
	for child in history_list.get_children():
		child.queue_free()
	
	for event in events:
		var panel = PanelContainer.new()
		var hbox = HBoxContainer.new()
		panel.add_child(hbox)
		
		var icon_label = Label.new()
		icon_label.text = event.get("icon", "🎪")
		icon_label.theme_override_font_sizes["font_size"] = 32
		hbox.add_child(icon_label)
		
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info_vbox)
		
		var name_label = Label.new()
		name_label.text = event.get("name", "Etkinlik")
		name_label.theme_override_font_sizes["font_size"] = 24
		info_vbox.add_child(name_label)
		
		var date_label = Label.new()
		date_label.text = "%s - %s" % [
			event.get("start_date", ""),
			event.get("end_date", "")
		]
		date_label.theme_override_font_sizes["font_size"] = 18
		info_vbox.add_child(date_label)
		
		var status_label = Label.new()
		status_label.text = "✅ Tamamlandı" if event.get("participated", false) else "❌ Katılmadınız"
		status_label.theme_override_font_sizes["font_size"] = 18
		hbox.add_child(status_label)
		
		history_list.add_child(panel)

func _participate_event(event_id: int) -> void:
	var result = await Network.http_post("/v1/events/participate", {"event_id": event_id})
	if result.success:
		_show_success("Etkinliğe katıldınız!")
		_load_active_events()
	else:
		_show_error(result.get("error", "Katılım başarısız"))

func _claim_event_reward(event_id: int) -> void:
	var result = await Network.http_post("/v1/events/claim_reward", {"event_id": event_id})
	if result.success:
		_show_success("Ödül alındı!")
		_load_active_events()
	else:
		_show_error(result.get("error", "Ödül alma başarısız"))

func _show_event_details(event: Dictionary) -> void:
	var message = "%s\n\n%s\n\nTür: %s\nSüre: %s" % [
		event.get("name", ""),
		event.get("description", ""),
		_get_event_type_text(event.get("type", "")),
		_format_time(event.get("time_remaining", 0))
	]
	
	var dialog_scene = load("res://scenes/ui/dialogs/InfoDialog.tscn")
	if dialog_scene:
		get_tree().root.get_node("Main").show_dialog(dialog_scene, {
			"title": "Etkinlik Detayları",
			"message": message
		})

func _get_event_type_text(type: String) -> String:
	match type:
		"daily": return "📅 Günlük Etkinlik"
		"weekly": return "🗓️ Haftalık Etkinlik"
		"seasonal": return "🎄 Sezonluk Etkinlik"
		"special": return "⭐ Özel Etkinlik"
		"limited": return "⏳ Sınırlı Etkinlik"
		_: return "🎪 Etkinlik"

func _format_time(seconds: int) -> String:
	var days = seconds / 86400
	var hours = (seconds % 86400) / 3600
	var minutes = (seconds % 3600) / 60
	
	if days > 0:
		return "%d gün %d saat" % [days, hours]
	elif hours > 0:
		return "%d saat %d dakika" % [hours, minutes]
	else:
		return "%d dakika" % minutes

func _on_tab_changed(tab: int) -> void:
	match tab:
		1:  # Upcoming
			_load_upcoming_events()
		2:  # History
			_load_event_history()

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
