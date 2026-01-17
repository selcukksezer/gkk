extends Control

## Facilities Screen
## Lists all available facilities (Mine, Farm, Lumber Mill) and their status.

@onready var grid_container: GridContainer = $MarginContainer/VBoxContainer/ScrollContainer/GridContainer



# Preload the card scene (we will create this next)
# var facility_card_scene = preload("res://scenes/ui/components/FacilityCard.tscn")

# Hardcoded facility types for now, or fetch from DB config if available.
# But for Phase 1 we have specific types.
const FACILITY_TYPES = [
	{"type": "mine", "name": "Maden Ocağı", "icon": "⛏️", "desc": "Demir ve Kristal üretimi.", "color": Color(0.7, 0.7, 0.8)},
	{"type": "farm", "name": "Çiftlik", "icon": "🌾", "desc": "Buğday ve Mantar üretimi.", "color": Color(0.6, 0.8, 0.3)},
	{"type": "lumber_mill", "name": "Kereste Atölyesi", "icon": "🪵", "desc": "Meşe kütüğü üretimi.", "color": Color(0.6, 0.4, 0.2)}
]

func _ready() -> void:
	setup_ui()
	refresh_data()

func setup_ui() -> void:
	# Clear existing
	for child in grid_container.get_children():
		child.queue_free()

func refresh_data() -> void:
	# Fetch owned facilities to see status/levels
	var result = await FacilityManager.fetch_my_facilities()
	var owned_facilities = {}
	
	if result and result.get("success", false):
		for f in result.get("data", []):
			owned_facilities[f.type] = f
	
	# Create cards
	for f_def in FACILITY_TYPES:
		create_facility_card(f_def, owned_facilities.get(f_def.type))

func create_facility_card(def: Dictionary, server_data) -> void:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 1)
	style.border_width_left = 5
	style.border_width_right = 5
	style.border_color = def.get("color", Color.WHITE)
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 8
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(0, 100)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)
	
	# Icon and title HBox
	var header_hbox = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(header_hbox)
	
	# Icon
	var icon_label = Label.new()
	icon_label.text = def.get("icon", "⛏️")
	icon_label.add_theme_font_size_override("font_size", 32)
	header_hbox.add_child(icon_label)
	
	# Title VBox
	var title_vbox = VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title_vbox)
	
	var name_label = Label.new()
	name_label.text = def.name
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", def.get("color", Color.WHITE))
	title_vbox.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = def.desc
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.modulate = Color(0.8, 0.8, 0.8)
	title_vbox.add_child(desc_label)
	
	# Status Info
	if server_data:
		var info_hbox = HBoxContainer.new()
		info_hbox.add_theme_constant_override("separation", 15)
		vbox.add_child(info_hbox)
		
		var level_label = Label.new()
		level_label.text = "🎯 Lv.%d" % server_data.level
		level_label.add_theme_font_size_override("font_size", 16)
		info_hbox.add_child(level_label)
		
		var suspicion_label = Label.new()
		var suspicion = server_data.get("suspicion", 0)
		suspicion_label.text = "⚠️ %%%d" % suspicion
		suspicion_label.add_theme_font_size_override("font_size", 16)
		if suspicion > 80:
			suspicion_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		elif suspicion > 50:
			suspicion_label.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
		else:
			suspicion_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
		info_hbox.add_child(suspicion_label)
		
		if server_data.get("is_active", false):
			var active_label = Label.new()
			active_label.text = "✅"
			active_label.add_theme_font_size_override("font_size", 16)
			active_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
			info_hbox.add_child(active_label)
		
		# Button
		var button = Button.new()
		button.text = "YÖNET"
		button.custom_minimum_size = Vector2(100, 40)
		button.add_theme_font_size_override("font_size", 16)
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = def.get("color", Color.WHITE)
		btn_style.corner_radius_bottom_left = 8
		btn_style.corner_radius_bottom_right = 8
		btn_style.corner_radius_top_left = 8
		btn_style.corner_radius_top_right = 8
		button.add_theme_stylebox_override("normal", btn_style)
		button.pressed.connect(func(): _on_facility_selected(def, server_data))
		vbox.add_child(button)
	else:
		# Locked
		var locked_label = Label.new()
		locked_label.text = "🔒 KİLİTLİ"
		locked_label.add_theme_font_size_override("font_size", 16)
		locked_label.add_theme_color_override("font_color", Color(1, 0.6, 0.3))
		locked_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(locked_label)
		
		var button = Button.new()
		button.text = "KİLİDİ AÇ"
		button.custom_minimum_size = Vector2(100, 40)
		button.add_theme_font_size_override("font_size", 16)
		button.modulate = Color(0.7, 0.7, 0.7)
		button.pressed.connect(func(): _on_facility_selected(def, server_data))
		vbox.add_child(button)
	
	grid_container.add_child(panel)

func _on_facility_selected(def: Dictionary, server_data) -> void:
	# Open Detail View
	# We can pass data to the next scene via a global context or setter
	# For now, let's assume we have a way to pass props.
	# Or, we can instantiate the detail view explicitly.
	
	# Using SceneManager with a context is cleaner, but let's use a simple global param for now.
	FacilityManager.selected_facility_type = def.type
	FacilityManager.selected_facility_data = server_data
	# Use Main scene navigation to preserve HUD
	var main = get_tree().current_scene
	if main and main.has_method("show_screen"):
		main.show_screen("facility_detail")
	else:
		# Fallback
		Scenes.change_scene("facility_detail")
