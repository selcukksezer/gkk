extends Control

## Facility Detail Screen
## Manage a specific facility: Unlock, Produce, Bribe.

@onready var title_label: Label = $MarginContainer/VBoxContainer/Header/TitleLabel
@onready var content_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ContentContainer
@onready var back_button: Button = $MarginContainer/VBoxContainer/Header/BackButton
@onready var message_label: Label = $MarginContainer/VBoxContainer/MessageLabel

var type: String
var data
var queue_timer: Timer

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	type = FacilityManager.selected_facility_type
	data = FacilityManager.selected_facility_data
	
	title_label.text = type.to_upper()
	
	# Create Timer for Queue updates
	queue_timer = Timer.new()
	queue_timer.wait_time = 1.0
	queue_timer.timeout.connect(_update_queue_ui)
	add_child(queue_timer)
	queue_timer.start()
	
	setup_ui()

func _on_back_pressed() -> void:
	# Use Main scene navigation to preserve HUD
	var main = get_tree().current_scene
	if main and main.has_method("show_screen"):
		main.show_screen("facilities")
	else:
		# Fallback if somehow not in Main
		Scenes.change_scene("facilities")

func setup_ui() -> void:
	# Clear old content
	for c in content_container.get_children():
		c.queue_free()
		
	if data == null:
		# Not Owned - Show Unlock Option
		var label = Label.new()
		label.text = "Bu tesis kilitli.\nAçmak için Altın gerekir."
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content_container.add_child(label)
		
		var btn = Button.new()
		btn.text = "Kilidi Aç (1000 Altın)"
		btn.pressed.connect(_on_unlock_pressed)
		content_container.add_child(btn)
	else:
		# Owned - Show Dashboard
		render_dashboard()

func render_dashboard() -> void:
	# 1. Status Section (Suspicion & Bribe)
	var status_panel = PanelContainer.new()
	var vbox = VBoxContainer.new()
	status_panel.add_child(vbox)
	
	var sus_label = Label.new()
	sus_label.text = "Şüphe Seviyesi: %" + str(data.get("suspicion", 0))
	if data.get("suspicion", 0) > 80:
		sus_label.modulate = Color.RED
	vbox.add_child(sus_label)
	
	var bribe_btn = Button.new()
	bribe_btn.text = "Rüşvet Ver (5 Elmas -> -10 Şüphe)"
	bribe_btn.pressed.connect(_on_bribe_pressed)
	vbox.add_child(bribe_btn)
	
	content_container.add_child(status_panel)
	
	# 2. Production Queue Section
	var queue_label = Label.new()
	queue_label.text = "\nAKTİF ÜRETİM:"
	content_container.add_child(queue_label)
	
	var queue_container = VBoxContainer.new()
	queue_container.name = "QueueContainer"
	content_container.add_child(queue_container)
	
	render_queue_items(queue_container)
	
	# 3. Recipes / Production List
	var recipe_label = Label.new()
	recipe_label.text = "\nÜRETİM SEÇENEKLERİ:"
	content_container.add_child(recipe_label)
	
	fetch_and_render_recipes()

func render_queue_items(container: VBoxContainer) -> void:
	var queue = data.get("facility_queue", [])
	if queue.size() == 0:
		var empty_label = Label.new()
		empty_label.text = "(Üretim boş)"
		empty_label.modulate = Color(0.6, 0.6, 0.6)
		empty_label.add_theme_font_size_override("font_size", 16)
		container.add_child(empty_label)
		return
		
	for job in queue:
		var job_panel = PanelContainer.new()
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.25, 0.3, 1)
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_color = Color(0.5, 0.8, 1.0)
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		job_panel.add_theme_stylebox_override("panel", style)
		
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_bottom", 8)
		job_panel.add_child(margin)
		
		var job_hbox = HBoxContainer.new()
		job_hbox.add_theme_constant_override("separation", 10)
		margin.add_child(job_hbox)
		
		# Icon
		var icon_label = Label.new()
		icon_label.text = _get_recipe_icon(job.get("recipe_id", ""))
		icon_label.add_theme_font_size_override("font_size", 32)
		job_hbox.add_child(icon_label)
		
		var info_vbox = VBoxContainer.new()
		job_hbox.add_child(info_vbox)
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 4)
		
		var name_label = Label.new()
		name_label.text = "📦 " + job.get("recipe_id", "???")
		name_label.add_theme_font_size_override("font_size", 18)
		info_vbox.add_child(name_label)
		
		# Time Label (updated by timer)
		var time_label = Label.new()
		time_label.name = "TimeLabel_" + str(job.get("id"))
		time_label.set_meta("completed_at", job.get("completed_at"))
		time_label.add_theme_font_size_override("font_size", 16)
		info_vbox.add_child(time_label)
		
		# Action Button
		var action_btn = Button.new()
		action_btn.name = "Btn_" + str(job.get("id"))
		action_btn.text = "Üretiliyor..."
		action_btn.custom_minimum_size = Vector2(120, 60)
		action_btn.add_theme_font_size_override("font_size", 18)
		action_btn.disabled = true
		action_btn.pressed.connect(func(): _on_collect_pressed(job))
		job_hbox.add_child(action_btn)
		
		container.add_child(job_panel)
	
	# Run immediate update
	_update_queue_ui()

func _update_queue_ui() -> void:
	var queue_container = content_container.get_node_or_null("QueueContainer")
	if not queue_container:
		return
		
	var current_time = Time.get_unix_time_from_system()
	
	for panel in queue_container.get_children():
		if panel is Label: continue # Skip "Empty" label
		
		var margin = panel.get_child(0)
		if not margin:
			continue
		var hbox = margin.get_child(0)
		if not hbox:
			continue
			
		# Skip icon, get info_vbox
		var info_vbox = null
		var btn = null
		for child in hbox.get_children():
			if child is VBoxContainer:
				info_vbox = child
			elif child is Button:
				btn = child
		
		if not info_vbox or not btn:
			continue
		
		# Find TimeLabel
		for child in info_vbox.get_children():
			if child.name.begins_with("TimeLabel_"):
				var completed_at = child.get_meta("completed_at", 0)
				var remaining = completed_at - current_time
				
				if remaining > 0:
					var mins = int(remaining / 60)
					var secs = int(remaining) % 60
					child.text = "⏱️ Kalan: %02d:%02d" % [mins, secs]
					child.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
					btn.text = "Üretiliyor..."
					btn.disabled = true
					btn.modulate = Color(0.7, 0.7, 0.7)
				else:
					child.text = "✅ Tamamlandı!"
					child.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
					btn.text = "🎁 TOPLA"
					btn.disabled = false
					btn.modulate = Color(0.5, 1, 0.5)
					
					# Make button more visible
					var btn_style = StyleBoxFlat.new()
					btn_style.bg_color = Color(0.2, 0.8, 0.3)
					btn_style.corner_radius_bottom_left = 8
					btn_style.corner_radius_bottom_right = 8
					btn_style.corner_radius_top_left = 8
					btn_style.corner_radius_top_right = 8
					btn.add_theme_stylebox_override("normal", btn_style)

func fetch_and_render_recipes() -> void:
	var result = await FacilityManager.fetch_recipes()
	if result.get("success", false):
		for r in result.get("data", []):
			if r.facility_type == type:
				create_recipe_card(r)

func create_recipe_card(recipe) -> void:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 1)
	style.border_width_left = 5
	style.border_width_right = 5
	style.border_color = _get_recipe_color(recipe)
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	margin.add_child(hbox)
	
	# Icon panel
	var icon_panel = PanelContainer.new()
	var icon_style = StyleBoxFlat.new()
	icon_style.bg_color = _get_recipe_color(recipe)
	icon_style.bg_color.a = 0.3
	icon_style.corner_radius_bottom_left = 6
	icon_style.corner_radius_bottom_right = 6
	icon_style.corner_radius_top_left = 6
	icon_style.corner_radius_top_right = 6
	icon_panel.add_theme_stylebox_override("panel", icon_style)
	icon_panel.custom_minimum_size = Vector2(60, 60)
	hbox.add_child(icon_panel)
	
	var icon_center = CenterContainer.new()
	icon_panel.add_child(icon_center)
	
	var icon_label = Label.new()
	icon_label.text = _get_recipe_icon(recipe.output_item_id)
	icon_label.add_theme_font_size_override("font_size", 32)
	icon_center.add_child(icon_label)
	
	# Info
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(info_vbox)
	
	var name_label = Label.new()
	name_label.text = recipe.output_item_id
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", _get_recipe_color(recipe))
	info_vbox.add_child(name_label)
	
	var time_label = Label.new()
	time_label.text = "⏱️ %ds | 💰 %dG | ⚠️ +%d%% | ✅ %d%%" % [recipe.duration_seconds, recipe.gold_cost, recipe.base_suspicion_increase, recipe.success_rate]
	time_label.add_theme_font_size_override("font_size", 16)
	if recipe.base_suspicion_increase > 50:
		time_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	else:
		time_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	info_vbox.add_child(time_label)
	
	# Produce button
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(120, 60)
	btn.text = "BAŞLAT"
	btn.add_theme_font_size_override("font_size", 18)
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = _get_recipe_color(recipe)
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn.add_theme_stylebox_override("normal", btn_style)
	
	btn.pressed.connect(func(): _on_produce_pressed_enhanced(recipe, btn))
	hbox.add_child(btn)
	
	content_container.add_child(panel)

func _get_recipe_color(recipe) -> Color:
	var risk = recipe.get("base_suspicion_increase", 0)
	if risk > 70:
		return Color(0.9, 0.2, 0.2)  # Yüksek risk - Kırmızı
	elif risk > 40:
		return Color(0.9, 0.6, 0.2)  # Orta risk - Turuncu
	else:
		return Color(0.3, 0.8, 0.4)  # Düşük risk - Yeşil

func _get_recipe_icon(output_id: String) -> String:
	var icon_map = {
		"iron_ore": "⛏️",
		"crystal": "💎",
		"wheat": "🌾",
		"mushroom": "🍄",
		"oak_log": "🪵",
		"lumber": "🪵",
		"leather": "🦌",
		"herb": "🌿",
		"stone": "🪨"
	}
	return icon_map.get(output_id.to_lower(), "📦")

# --- Actions ---

func _on_unlock_pressed() -> void:
	message_label.text = "Kilit açılıyor..."
	var res = await FacilityManager.unlock_facility(type)
	if res.get("success", false):
		message_label.text = "Tesis açıldı! Veri güncelleniyor..."
		await refresh_data_from_server()
		if data:
			setup_ui()
			message_label.text = "Hazır."
		else:
			message_label.text = "Hata: Veri güncellenemedi."
	else:
		message_label.text = "Hata: " + str(res.get("error"))

func _on_bribe_pressed() -> void:
	var res = await FacilityManager.bribe(data.id, 5) # 5 Gems
	if res.get("success", false):
		message_label.text = "Rüşvet verildi."
		await refresh_data_from_server()
		setup_ui()
	else:
		message_label.text = "Hata: " + str(res.get("error"))

func _on_produce_pressed_enhanced(recipe, btn: Button) -> void:
	# Double click protection
	if btn.disabled:
		return
	btn.disabled = true
	var original_text = btn.text
	btn.text = "İşleniyor..."
	
	message_label.text = "İşlem başlatılıyor..."
	
	var res = await FacilityManager.start_production(data.id, recipe.id, 1)
	
	if res.get("success", false):
		message_label.text = "✅ Üretim başladı! Tamamlanınca toplayabilirsiniz."
		# Immediately refresh to show in queue
		await refresh_data_from_server()
		if data:
			setup_ui()
		else:
			message_label.text = "⚠️ Üretim başladı ama liste güncellenemedi."
			btn.disabled = false
			btn.text = original_text
	else:
		message_label.text = "❌ Hata: " + str(res.get("error"))
		btn.disabled = false
		btn.text = original_text

func _on_produce_pressed(recipe, btn: Button) -> void:
	# Legacy function - redirect to enhanced version
	_on_produce_pressed_enhanced(recipe, btn)

func _on_collect_pressed(job) -> void:
	message_label.text = "Toplanıyor..."
	var res = await FacilityManager.collect_production(data.id) 
	
	if res.get("success", false):
		print("[FacilityDetail] Collect successful, response: ", res)
		
		# CRITICAL: Refresh inventory first to show collected items
		if Inventory:
			print("[FacilityDetail] Fetching inventory...")
			var inv_result = await Inventory.fetch_inventory()
			if inv_result:
				print("[FacilityDetail] Inventory refreshed: ", inv_result.get("items", []).size(), " items")
			else:
				print("[FacilityDetail] Inventory refresh failed")
		else:
			print("[FacilityDetail] Inventory manager not available")
		
		# Then refresh facility data
		await refresh_data_from_server()
		setup_ui()
		
		message_label.text = "✅ Toplandı! Envantere eklendi."
	else:
		print("[FacilityDetail] Collect failed: ", res)
		message_label.text = "❌ Hata: " + str(res.get("error"))

func refresh_data_from_server() -> void:
	print("[FacilityDetail] Refreshing facility data for type: ", type)
	var res = await FacilityManager.fetch_my_facilities()
	if res.get("success", false):
		var found = false
		for f in res.get("data", []):
			if f.type == type:
				data = f
				FacilityManager.selected_facility_data = f
				found = true
				print("[FacilityDetail] Data updated, queue size: ", f.get("facility_queue", []).size())
				break
		if not found:
			print("[FacilityDetail] WARNING: Facility type '", type, "' not found in response")
	else:
		print("[FacilityDetail] Failed to fetch facilities: ", res.get("error"))
