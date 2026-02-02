extends Control
## DetailModal.gd - Facility Detail and Interaction Modal
## Shows production queue, recipes, upgrades, and suspicion management

# UI references
@onready var modal_panel = $PanelContainer
@onready var title_label = $PanelContainer/VBoxContainer/TitleLabel
@onready var tabs = $PanelContainer/VBoxContainer/TabContainer
@onready var close_btn = $PanelContainer/VBoxContainer/CloseButton

# Tab containers
@onready var queue_tab = $PanelContainer/VBoxContainer/TabContainer/QueueTab/QueueTabContent
@onready var recipes_tab = $PanelContainer/VBoxContainer/TabContainer/RecipesTab/RecipesTabContent
@onready var suspicion_tab = $PanelContainer/VBoxContainer/TabContainer/SuspicionTab/SuspicionTabContent
@onready var upgrade_tab = $PanelContainer/VBoxContainer/TabContainer/UpgradeTab/UpgradeTabContent

# Data
var current_facility_type: String = ""
var current_facility_data: Dictionary = {}
var current_config: Dictionary = {}
var risk_panel_header: Control = null

# Real-time update timer for production display
var queue_update_timer: Timer = null

func _ready() -> void:
	close_btn.pressed.connect(_on_close_pressed)
	# Connect to production signals to refresh queue when production starts
	FacilityManager.production_started.connect(_on_production_started)
	FacilityManager.facilities_updated.connect(_on_facilities_updated)
	
	if State.has_signal("energy_updated"):
		State.energy_updated.connect(_on_energy_updated)
	
	# Rename tabs
	tabs.set_tab_title(0, "Üretim")
	tabs.set_tab_title(1, "Kaynaklar") # Rename Recipes tab
	
	# Hide Suspicion Tab (merged into Resources)
	if tabs.get_tab_count() > 2:
		tabs.set_tab_hidden(2, true)
	
	hide()

func _on_facilities_updated() -> void:
	if visible and not current_facility_type.is_empty():
		print("[DetailModal] Facilities updated, refreshing current view...")
		var updated_data = FacilityManager.get_facility_by_type(current_facility_type)
		if not updated_data.is_empty():
			# Keep references but update data
			current_facility_data = updated_data
			# Refresh all tabs that rely on dynamic data
			_populate_queue_tab()
			_populate_suspicion_tab()
			_populate_upgrade_tab()
			# Recipes (Resources) usually static but visually we might want to refresh unlock status if level changed
			_populate_recipes_tab()
	# Recipes (Resources) usually static but visually we might want to refresh unlock status if level changed
			_populate_recipes_tab()
			# _update_risk_header() # Removed

# ... (omitted code) ...

# ==================== RESOURCE INFO TAB (Formerly Recipes) ====================

func _populate_recipes_tab() -> void:
	# "Recipes" is now "Resources" / "Management" tab
	
	# Clear existing children
	for child in recipes_tab.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	var current_level = current_facility_data.get("level", 1)
	
	# ==================== 1. RISK / SUSPICION SECTION MOVED TO HEADER ====================
	
	# ==================== 2. RESOURCE LIST ====================

	# ==================== 2. RESOURCE LIST ====================
	
	# Get configured resources for this facility
	# Use FACILITY_RESOURCES_FULL to ensure we get all 5 resources with proper rarities
	var resources_list = FacilityManager.FACILITY_RESOURCES_FULL.get(current_facility_type, [])
	
	if resources_list.is_empty():
		resources_list = FacilityManager.FACILITIES_CONFIG.get(current_facility_type, {}).get("resources", [])
	
	if resources_list.is_empty():
		var empty_label = Label.new()
		empty_label.text = "❓ Bu tesis için kaynak tanımlanmamış"
		recipes_tab.add_child(empty_label)
		return
	
	var level_header = Label.new()
	level_header.text = "Mevcut Seviye Verimliliği: Lvl %d" % current_level
	level_header.add_theme_color_override("font_color", Color.GREEN)
	level_header.add_theme_font_size_override("font_size", 16)
	recipes_tab.add_child(level_header)
	
	recipes_tab.add_child(HSeparator.new())
	
	# Table Header
	var header_hbox = HBoxContainer.new()
	_create_table_header(header_hbox, "Sev.", 0.15)
	_create_table_header(header_hbox, "Kaynak", 0.45)
	_create_table_header(header_hbox, "Şans", 0.20)
	_create_table_header(header_hbox, "Durum", 0.20)
	recipes_tab.add_child(header_hbox)
	
	recipes_tab.add_child(HSeparator.new())

	# Create detailed resource list
	# Pre-calculate chances for current level
	var rarity_data = FacilityManager.get_rarity_chances_at_level(current_level)
	var chances = rarity_data.chances
	
	for index in range(resources_list.size()):
		var item_id = resources_list[index]
		var card = _create_resource_detail_row(item_id, index, current_level, chances)
		recipes_tab.add_child(card)

	# --- LEVEL 1-20 DROP RATE TABLE ---
	recipes_tab.add_child(HSeparator.new())
	
	var table_title = Label.new()
	table_title.text = "📊 Seviye Başına Düşme Oranları (1-20)"
	table_title.add_theme_color_override("font_color", Color(0.7, 0.7, 1.0))
	table_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	recipes_tab.add_child(table_title)
	
	var grid = GridContainer.new()
	grid.columns = 6 # Lvl, C, U, R, E, L
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 4)
	recipes_tab.add_child(grid)
	
	# Table Headers
	var headers = ["Sv", "Com.", "Unc.", "Rare", "Epic", "Leg."]
	for h in headers:
		var lbl = Label.new()
		lbl.text = h
		lbl.add_theme_color_override("font_color", Color.ORANGE)
		lbl.add_theme_font_size_override("font_size", 12)
		grid.add_child(lbl)
		
	# Rows 1-20
	for lvl in range(1, 21):
		# Calculate dynamic rates (Same math as FacilityManager)
		var w = {"C": 700.0, "U": 200.0, "R": 80.0, "E": 15.0, "L": 5.0}
		if lvl > 1:
			w["U"] += (lvl - 1) * 15.0
			w["R"] += (lvl - 1) * 8.0
			w["E"] += (lvl - 1) * 3.0
			w["L"] += (lvl - 1) * 1.5
			
		var total = w["C"] + w["U"] + w["R"] + w["E"] + w["L"]
		
		# Columns
		var cols = [
			str(lvl),
			"%.0f" % ((w["C"] / total) * 100), # Round to int for space
			"%.0f" % ((w["U"] / total) * 100),
			"%.0f" % ((w["R"] / total) * 100),
			"%.1f" % ((w["E"] / total) * 100), # Detailed for rare
			"%.1f" % ((w["L"] / total) * 100)
		]
		
		var is_current = (lvl == current_level)
		var is_past = (lvl < current_level)
		var color = Color.WHITE
		
		if is_current: color = Color.GREEN
		elif is_past: color = Color(0.4, 0.4, 0.4)
		
		for col_idx in range(cols.size()):
			var txt = cols[col_idx]
			if col_idx > 0: txt += "%" # Add % sign
			
			var l = Label.new()
			l.text = txt
			l.add_theme_color_override("font_color", color)
			l.add_theme_font_size_override("font_size", 12)
			grid.add_child(l)


func _create_table_header(parent: Control, text: String, ratio: float) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.size_flags_stretch_ratio = ratio
	lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	lbl.add_theme_font_size_override("font_size", 12)
	parent.add_child(lbl)

func _create_resource_detail_row(item_id: String, index: int, current_level: int, chances: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	
	# Determine rarity & props
	var rarity = FacilityManager.RESOURCE_RARITY_TIERS.get(index, "COMMON")
	var unlock_level = FacilityManager.RARITY_UNLOCK_LEVELS.get(rarity, 1)
	var is_unlocked = current_level >= unlock_level
	
	# Use dynamic chance calculated for this level
	# Round to 1 decimal place for cleaner display
	var chance_val = chances.get(rarity, 0.0)
	
	# If locked, chance is effectively 0 (though theoretically it has a weight, it's gated)
	# But user wants to see what the chance WILL be, or maybe just 0?
	# Better to show the chance but mark as locked.
	
	# Style
	var style = StyleBoxFlat.new()
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	
	if is_unlocked:
		style.bg_color = Color(0.1, 0.1, 0.1, 0.3)
		style.border_width_bottom = 1
		style.border_color = Color(0.2, 0.2, 0.2)
	else:
		style.bg_color = Color(0.05, 0.05, 0.05, 0.3)
		
	panel.add_theme_stylebox_override("panel", style)
	panel.add_child(hbox)
	
	# 1. Unlock Level Column
	var level_lbl = Label.new()
	level_lbl.text = "Lvl %d+" % unlock_level
	level_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level_lbl.size_flags_stretch_ratio = 0.15
	if is_unlocked:
		level_lbl.add_theme_color_override("font_color", Color.WHITE)
	else:
		level_lbl.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	hbox.add_child(level_lbl)
	
	# 2. Resource Icon & Name Column
	var resource_hbox = HBoxContainer.new()
	resource_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resource_hbox.size_flags_stretch_ratio = 0.45
	
	# Icon
	var icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(24, 24)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var item = ItemDatabase.get_item(item_id)
	var item_name = item.name if item else _format_item_name(item_id)
	
	if item and item.icon:
		if item is Dictionary and item.get("icon") is String:
			icon_rect.texture = load(item.get("icon"))
		elif item.get("icon") is Texture2D:
			icon_rect.texture = item.icon
	
	if not icon_rect.texture:
		var txt_icon = Label.new()
		txt_icon.text = "📦"
		resource_hbox.add_child(txt_icon)
	else:
		resource_hbox.add_child(icon_rect)
		
	if not is_unlocked:
		icon_rect.modulate = Color(0.5, 0.5, 0.5)
		
	var name_lbl = Label.new()
	name_lbl.text = item_name
	name_lbl.clip_text = true
	if is_unlocked:
		name_lbl.add_theme_color_override("font_color", _get_rarity_color(rarity))
	else:
		name_lbl.add_theme_color_override("font_color", Color.GRAY)
	resource_hbox.add_child(name_lbl)
	
	hbox.add_child(resource_hbox)
	
	# 3. Chance Column
	var chance_lbl = Label.new()
	chance_lbl.text = "%%%0.1f" % chance_val
	chance_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chance_lbl.size_flags_stretch_ratio = 0.20
	if is_unlocked:
		chance_lbl.add_theme_color_override("font_color", Color.GREEN)
	else:
		chance_lbl.add_theme_color_override("font_color", Color.GRAY)
	hbox.add_child(chance_lbl)
	
	# 4. Status Column
	var status_lbl = Label.new()
	status_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_lbl.size_flags_stretch_ratio = 0.20
	if is_unlocked:
		status_lbl.text = "✅ Açık"
		status_lbl.add_theme_color_override("font_color", Color.GREEN)
	else:
		status_lbl.text = "🔒 Kilitli"
		status_lbl.add_theme_color_override("font_color", Color.RED)
	hbox.add_child(status_lbl)
	
	return panel

func _process(_delta: float) -> void:
	if visible and not current_facility_data.is_empty():
		# Check every 1 second for status/resources changes AND timer update
		if not has_meta("last_check_time"):
			set_meta("last_check_time", Time.get_ticks_msec())
		
		var current_time = Time.get_ticks_msec()
		var last_check = get_meta("last_check_time", 0)
		
		# Check every 1 second
		if current_time - last_check >= 1000:
			set_meta("last_check_time", current_time)
			
			# Only check if status/resources CHANGED
			var resources_data = FacilityManager.calculate_idle_resources(current_facility_data)
			var total_count = resources_data.get("total_count", 0)
			var status = resources_data.get("status", "stopped")
			
			var old_total = get_meta("old_total_count", 0)
			var old_status = get_meta("old_status", "stopped")
			
			# Refresh ONLY if something actually changed
			if total_count != old_total or status != old_status:
				set_meta("old_total_count", total_count)
				set_meta("old_status", status)
				_populate_queue_tab()  # Full refresh
			else:
				# Nothing changed - just update timer text if active
				_update_timer_label_only()

func _on_production_started(facility_id: String, recipe_name: String, quantity: int, rarity: String) -> void:
	# If this modal is showing the facility that just started production, refresh the queue
	if current_facility_data.get("id", "") == facility_id:
		print("[DetailModal] Production started for current facility, refreshing queue")
		_populate_queue_tab()

func _update_timer_label_only() -> void:
	"""Updates ONLY the timer label text without touching buttons or other UI."""
	if queue_tab == null:
		return
	
	var resources_data = FacilityManager.calculate_idle_resources(current_facility_data)
	var remaining_sec = resources_data.get("remaining_seconds", 0)
	
	if remaining_sec <= 0:
		return
	
	var children = queue_tab.get_children()
	if children.is_empty():
		return
	
	# Find the status label in first panel
	var status_panel = children[0]
	if not status_panel is PanelContainer:
		return
	
	var status_lbl = null
	for child in status_panel.get_children():
		if child is Label:
			status_lbl = child
			break
	
	if status_lbl == null:
		return
	
	var mins = int(remaining_sec / 60)
	var secs = int(remaining_sec) % 60
	var new_text = "🟢 Üretim Sürüyor: %02d:%02d" % [mins, secs]
	
	if status_lbl.text != new_text:
		status_lbl.text = new_text

func set_facility_data(facility_type: String, config: Dictionary, facility_data: Dictionary) -> void:
	current_facility_type = facility_type
	current_facility_data = facility_data
	current_config = config
	
	print("[DetailModal] set_facility_data called: type=%s, has_facility_queue=%s, facility_id=%s" % [facility_type, facility_data.has("facility_queue"), facility_data.get("id", "N/A")])
	
	# Update title
	title_label.text = "%s (Level %d)" % [config.get("name", facility_type), facility_data.get("level", 1)]
	
	# Populate tabs
	_populate_queue_tab()
	_populate_recipes_tab()
	_populate_suspicion_tab()
	_populate_upgrade_tab()
	# _update_risk_header()
	
	# Start real-time update with _process()

	
# func _update_risk_header() -> void: # Removed per user request

# ==================== QUEUE TAB ====================

# ==================== QUEUE / PRODUCTION TAB ====================

func _populate_queue_tab() -> void:
	# Clear existing children immediately (no await - prevents flashing)
	for child in queue_tab.get_children():
		queue_tab.remove_child(child)
		child.queue_free()
	
	var facility_id = current_facility_data.get("id", "")
	if facility_id.is_empty():
		var empty_label = Label.new()
		empty_label.text = "⭕ Tesis verisi yüklenemedi"
		queue_tab.add_child(empty_label)
		return
	
	# Calculate state & resources
	var resources_data = FacilityManager.calculate_idle_resources(current_facility_data)
	var total_count = resources_data.get("total_count", 0)
	var resources = resources_data.get("resources", [])
	
	# Fix: Sort resources to prevent UI jumping
	resources.sort_custom(func(a, b): return a.get("item_id", "") < b.get("item_id", ""))
	
	var status = resources_data.get("status", "stopped") # active, stopped, expired, not_started
	var remaining_sec = resources_data.get("remaining_seconds", 0)
	
	# 1. STATUS HEADER
	var status_panel = PanelContainer.new()
	var status_style = StyleBoxFlat.new()
	status_style.corner_radius_top_left = 6
	status_style.corner_radius_top_right = 6
	status_style.corner_radius_bottom_left = 6
	status_style.corner_radius_bottom_right = 6
	status_style.content_margin_top = 8
	status_style.content_margin_bottom = 8
	status_style.content_margin_left = 8
	status_style.content_margin_right = 8
	
	var status_text = ""
	
	match status:
		"active":
			status_style.bg_color = Color(0.1, 0.4, 0.1, 0.8) # Greenish
			var mins = int(remaining_sec / 60)
			var secs = int(remaining_sec) % 60
			status_text = "🟢 Üretim Sürüyor: %02d:%02d" % [mins, secs]
		"expired":
			status_style.bg_color = Color(0.5, 0.4, 0.1, 0.8) # Yellowish
			status_text = "🟡 Süre Doldu! (Yeniden Başlat)"
		_: # stopped, not_started
			status_style.bg_color = Color(0.4, 0.1, 0.1, 0.8) # Reddish
			status_text = "🔴 Üretim Durdu"
			
	status_panel.add_theme_stylebox_override("panel", status_style)
	var status_lbl = Label.new()
	status_lbl.text = status_text
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.add_theme_font_size_override("font_size", 16)
	status_panel.add_child(status_lbl)
	
	queue_tab.add_child(status_panel)
	
	# Spacing
	queue_tab.add_child(HSeparator.new())
	
	# 2. RESOURCES DISPLAY
	var r_header = Label.new()
	r_header.text = "📦 Toplam Kaynak: %d" % total_count
	queue_tab.add_child(r_header)
	
	if total_count > 0:
		for resource in resources:
			var item_id = resource.get("item_id", "")
			var quantity = resource.get("quantity", 0)
			var rarity = resource.get("rarity", "COMMON")
			
			# UI Row for Resource
			var card = _create_resource_queue_card(item_id, quantity, rarity)
			queue_tab.add_child(card)
	else:
		if status == "active":
			var work_lbl = Label.new()
			work_lbl.text = "🔨 İşçiler çalışıyor..."
			work_lbl.add_theme_color_override("font_color", Color.GRAY)
			work_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			queue_tab.add_child(work_lbl)
		else:
			var empty_lbl = Label.new()
			empty_lbl.text = "Depo boş. Üretimi başlatın."
			empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			queue_tab.add_child(empty_lbl)
			
	# Spacing
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	queue_tab.add_child(spacer)
	
	# 3. ACTION BUTTONS
	
	# CASE A: Resources exist AND duration elapsed -> Can Collect
	# remaining_seconds <= 0 means 2 minutes (120s) have passed
	if total_count > 0 and remaining_sec <= 0:
		var collect_btn = Button.new()
		collect_btn.text = "✅ Kaynakları Topla (%d)" % total_count
		collect_btn.custom_minimum_size = Vector2(0, 50)
		collect_btn.add_theme_color_override("font_color", Color.GREEN)
		collect_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		collect_btn.pressed.connect(_on_collect_resources_pressed)
		queue_tab.add_child(collect_btn)
		
		var tip = Label.new()
		tip.text = "(Yeni üretime başlamak için depoyu boşaltın)"
		tip.add_theme_font_size_override("font_size", 10)
		tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tip.add_theme_color_override("font_color", Color.GRAY)
		queue_tab.add_child(tip)
	
	# CASE B: Resources exist BUT duration NOT elapsed -> Disabled Collect (show timer)
	elif total_count > 0 and remaining_sec > 0:
		var mins = int(remaining_sec / 60)
		var secs = int(remaining_sec) % 60
		
		var collect_btn = Button.new()
		collect_btn.text = "⏳ Bekleyin: %02d:%02d" % [mins, secs]
		collect_btn.custom_minimum_size = Vector2(0, 50)
		collect_btn.disabled = true
		collect_btn.add_theme_color_override("font_color", Color.GRAY)
		queue_tab.add_child(collect_btn)
		
		var tip = Label.new()
		tip.text = "(Kaynakları toplamak için süresi dolmasını bekleyin)"
		tip.add_theme_font_size_override("font_size", 10)
		tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tip.add_theme_color_override("font_color", Color.GRAY)
		queue_tab.add_child(tip)
		
	# CASE C: No resources & Active -> Cannot do much (Stop?)
	elif status == "active":
		# Optional: Wait message
		pass
		
	# CASE D: Stopped/Expired & Empty -> Can Start
	else:
		var energy_cost = 50
		var player_energy = State.current_energy
		var can_afford = player_energy >= energy_cost
		
		var start_btn = Button.new()
		start_btn.text = "⚡ Üretimi Başlat (1 Saat)"
		start_btn.custom_minimum_size = Vector2(0, 50)
		start_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		
		if can_afford:
			start_btn.add_theme_color_override("font_color", Color(1, 0.9, 0.4)) # Energy Gold/Yellow
		else:
			start_btn.disabled = true
			start_btn.text += " (Yetersiz Enerji)"
			
		start_btn.pressed.connect(_on_start_production_pressed)
		queue_tab.add_child(start_btn)
		
		var cost_lbl = Label.new()
		cost_lbl.text = "Maliyet: %d Enerji (Mevcut: %d)" % [energy_cost, player_energy]
		if not can_afford:
			cost_lbl.add_theme_color_override("font_color", Color.RED)
		else:
			cost_lbl.add_theme_color_override("font_color", Color.GRAY)
		cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		queue_tab.add_child(cost_lbl)

func _create_resource_queue_card(item_id: String, quantity: int, rarity: String) -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = _get_rarity_color(rarity).darkened(0.7)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	panel.add_child(hbox)
	
	var item_data = ItemDatabase.get_item(item_id)
	var item_name = item_data.name if item_data else _format_item_name(item_id)
	
	var lbl = Label.new()
	lbl.text = "%s" % item_name
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_color_override("font_color", _get_rarity_color(rarity))
	hbox.add_child(lbl)
	
	var qty = Label.new()
	qty.text = "x%d" % quantity
	hbox.add_child(qty)
	
	return panel

func _on_collect_resources_pressed() -> void:
	var facility_id = current_facility_data.get("id", "")
	if facility_id.is_empty(): return
	
	var result = await FacilityManager.collect_facility_resources(facility_id)
	if result.get("success", false):
		_show_toast("✅ Toplandı: %d kaynak" % result.get("total_count", 0))
		_populate_queue_tab() # Refresh UI
	else:
		if result.get("error", "") == "Inventory is full":
			_show_toast("❌ Envanterde Dolu")
		else:
			_show_toast("❌ Hata: %s" % result.get("error", "Unknown"))

func _on_start_production_pressed() -> void:
	var facility_id = current_facility_data.get("id", "")
	if facility_id.is_empty(): return
	
	# Optimistic UI update
	_show_toast("⚡ Üretim başlatılıyor...")
	
	var result = await FacilityManager.start_facility_production(facility_id)
	if result.success:
		_show_toast("✅ Üretim Başladı!")
		# Refresh UI immediately to show correct timer
		_populate_queue_tab()
		# Also update energy display
		if result.has("new_energy"):
			State.current_energy = result.new_energy
			State.energy_updated.emit()
	else:
		_show_toast("❌ Başlatılamadı: %s" % result.error)

func _on_energy_updated() -> void:
	# Refresh UI to check button state
	if visible:
		_populate_queue_tab()

func _show_toast(message: String) -> void:
	print("[DetailModal] %s" % message)
	# Future: Real toast UI



func _create_queue_item_display(item: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	var vbox = VBoxContainer.new()
	
	var style = StyleBoxFlat.new()
	var now = Time.get_unix_time_from_system()
	var completed_at = item.get("completed_at", 0)
	var is_completed = now >= completed_at
	
	# Color based on status
	if item.get("collected", false):
		style.bg_color = Color.GRAY
	elif is_completed:
		style.bg_color = Color.GREEN
	else:
		style.bg_color = Color.BLUE
	
	panel.set_meta("completed_at", completed_at)
	panel.add_theme_stylebox_override("panel", style)
	panel.add_child(vbox)
	
	# Item info
	var item_label = Label.new()
	
	# Debug: Print all available fields in the item
	print("[DetailModal] Queue item fields: ", item.keys())
	
	# Try multiple possible field names for the item
	var item_id = ""
	if item.has("output_item_id"):
		item_id = item.get("output_item_id", "")
	elif item.has("item_id"):
		item_id = item.get("item_id", "")
	elif item.has("recipe_id"):
		# Fallback: use recipe_id and try to extract item name from it
		var recipe_id = item.get("recipe_id", "")
		# Recipe IDs are often like "recipe_forge_iron_sword" -> extract "iron_sword"
		item_id = recipe_id.replace("recipe_", "").replace("forge_", "").replace("craft_", "")
	else:
		item_id = "unknown"
	
	var item_name = _format_item_name(item_id)
	var rarity = item.get("rarity", item.get("rarity_outcome", "common"))
	var rarity_display = _format_rarity(rarity)
	item_label.text = "📦 %s (%s)" % [item_name, rarity_display]
	item_label.add_theme_color_override("font_color", _get_rarity_color(rarity))
	vbox.add_child(item_label)
	
	# Time info
	var time_label = Label.new()
	if is_completed:
		time_label.text = "✅ Tamamlandı"
	else:
		var remaining = completed_at - now
		var minutes = int(remaining / 60)
		var seconds = int(remaining) % 60
		time_label.text = "⏱️ %02d:%02d kaldı" % [minutes, seconds]
	
	vbox.add_child(time_label)
	
	# Quantity
	var qty_label = Label.new()
	qty_label.text = "Miktar: %d" % item.get("quantity", 1)
	vbox.add_child(qty_label)
	
	return panel

func _on_collect_production_pressed() -> void:
	var facility_id = current_facility_data.get("id", "")
	var result = await FacilityManager.collect_production(facility_id)
	
	if result.success:
		print("[DetailModal] Production collected!")
		_populate_queue_tab()
	else:
		print("[DetailModal] Error: %s" % result.error)

# ==================== RESOURCE INFO TAB (Formerly Recipes) ====================




# ==================== SUSPICION TAB ====================

func _populate_suspicion_tab() -> void:
	# Clear existing
	for child in suspicion_tab.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	var suspicion = current_facility_data.get("suspicion_level", 0)
	var level = current_facility_data.get("level", 1)
	
	# Suspicion bar
	var progress_label = Label.new()
	progress_label.text = "Şüphe Seviyesi: %d%%" % suspicion
	suspicion_tab.add_child(progress_label)
	
	var progress_bar = ProgressBar.new()
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.value = suspicion
	progress_bar.custom_minimum_size.y = 30
	
	# Color coding
	if suspicion < 30:
		progress_bar.modulate = Color.GREEN
	elif suspicion < 60:
		progress_bar.modulate = Color.YELLOW
	elif suspicion < 80:
		progress_bar.modulate = Color.ORANGE
	else:
		progress_bar.modulate = Color.RED
	
	suspicion_tab.add_child(progress_bar)
	
	# Info text
	var info_label = Label.new()
	info_label.text = "ℹ️ Tesisin seviyesi: %d\nŞüphe azalması: %d%% / saat\n(Pasif olarak azalıyor)" % [
		level,
		level * 2  # From reduce_facility_suspicion function
	]
	suspicion_tab.add_child(info_label)
	
	# Bribe button (if has gems)
	var player_gems = 0
	if State and State.get("gems") != null:
		player_gems = int(State.gems)
		
	if player_gems >= 5:
		var bribe_btn = Button.new()
		bribe_btn.text = "💎 Memurları Rüşvet Ver (5 Gem)"
		bribe_btn.pressed.connect(_on_bribe_pressed)
		suspicion_tab.add_child(bribe_btn)
	else:
		var no_gems_label = Label.new()
		no_gems_label.text = "❌ Yeterli mücevher yok (5 gerekli, %d var)" % player_gems
		suspicion_tab.add_child(no_gems_label)
	
	# Prison risk info
	var risk_label = Label.new()
	if suspicion >= 80:
		risk_label.text = "⚠️ ÇOK YÜKSEK RİSK!\n%d%% hapishane şansı" % (50 + suspicion)
		risk_label.add_theme_color_override("font_color", Color.RED)
	elif suspicion >= 60:
		risk_label.text = "⚠️ Yüksek Risk - Şüpheyi azalt!"
		risk_label.add_theme_color_override("font_color", Color.ORANGE)
	else:
		risk_label.text = "✅ Güvenli bölgede"
		risk_label.add_theme_color_override("font_color", Color.GREEN)
	
	suspicion_tab.add_child(risk_label)

func _on_bribe_pressed() -> void:
	var result = await FacilityManager.bribe_officials(current_facility_type, 5)
	
	if result.success:
		print("[DetailModal] Bribe successful!")
		# Refresh data
		var updated = FacilityManager.get_facility_by_type(current_facility_type)
		if not updated.is_empty():
			current_facility_data = updated
		
		# Refresh relevant tab (now Resources logic)
		_populate_recipes_tab()
	else:
		print("[DetailModal] Bribe failed: %s" % result.error)
		_show_toast("Rüşvet başarısız: %s" % result.error)


func _populate_upgrade_tab() -> void:
	# Clear existing
	for child in upgrade_tab.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	var level_raw = current_facility_data.get("level", 1)
	var level = int(level_raw) if level_raw != null else 1
	var max_level = 20
	
	if level >= max_level:
		var max_label = Label.new()
		max_label.text = "🏆 Maksimum seviye (%d) ulaştı!" % max_level
		upgrade_tab.add_child(max_label)
		return
	
	# Current level info
	var level_label = Label.new()
	level_label.text = "📊 Mevcut Seviye: %d / %d" % [level, max_level]
	upgrade_tab.add_child(level_label)
	
	# Calculate upgrade cost
	var config = FacilityManager.FACILITIES_CONFIG.get(current_facility_type, {})
	
	# Fix: Handle missing config
	if config.is_empty():
		config = {"base_upgrade_cost": 1000, "upgrade_multiplier": 1.5, "workers_per_level": 1, "offline_cap_per_level": 50}
		
	var base_cost = config.get("base_upgrade_cost", 1000)
	var multiplier = config.get("upgrade_multiplier", 1.5)
	var upgrade_cost = int(base_cost * pow(multiplier, level))
	
	var cost_label = Label.new()
	cost_label.text = "💰 Seviye %d Maliyeti: %d altın" % [level + 1, upgrade_cost]
	upgrade_tab.add_child(cost_label)
	
	upgrade_tab.add_child(HSeparator.new())
	
	# Benefits info
	var benefits_header = Label.new()
	benefits_header.text = "📈 Seviye %d Avantajları:" % (level + 1)
	benefits_header.add_theme_color_override("font_color", Color.GREEN)
	upgrade_tab.add_child(benefits_header)
	
	var workers_gain = config.get("workers_per_level", 1)
	var cap_gain = config.get("offline_cap_per_level", 50)
	
	var benefits_text = "• İşçi: +%d\n• Depo Kapasitesi: +%d" % [workers_gain, cap_gain]
	
	# CHECK FOR NEW RESOURCE UNLOCKS
	var new_unlocks = []
	var next_level = level + 1
	
	# Check rarity unlocks
	for rarity in FacilityManager.RARITY_UNLOCK_LEVELS:
		if FacilityManager.RARITY_UNLOCK_LEVELS[rarity] == next_level:
			new_unlocks.append(rarity)
			
	if not new_unlocks.is_empty():
		benefits_text += "\n\n🔓 YENİ KİLİT AÇILIYOR:"
		for rarity in new_unlocks:
			var rarity_name = _format_rarity(rarity)
			benefits_text += "\n• %s Kalite Kaynaklar!" % rarity_name
	
	# Check production rate increase
	var base_rate = config.get("base_rate", 10.0)
	var current_rate = base_rate * level
	var next_rate = base_rate * next_level
	benefits_text += "\n\n⚡ Üretim Hızı: %.1f -> %.1f / saat" % [current_rate, next_rate]
	
	var benefits_label = Label.new()
	benefits_label.text = benefits_text
	upgrade_tab.add_child(benefits_label)
	
	upgrade_tab.add_child(HSeparator.new())
	
	# NEW: FORECAST SECTION (Drop Chances)
	var forecast_panel = PanelContainer.new()
	var f_style = StyleBoxFlat.new()
	f_style.bg_color = Color(0.1, 0.1, 0.15, 0.5)
	f_style.border_width_top = 1
	f_style.border_color = Color(0.3, 0.3, 0.5)
	f_style.content_margin_left = 10
	f_style.content_margin_right = 10
	f_style.content_margin_top = 10
	f_style.content_margin_bottom = 10
	forecast_panel.add_theme_stylebox_override("panel", f_style)
	
	var f_vbox = VBoxContainer.new()
	forecast_panel.add_child(f_vbox)
	
	var f_header = Label.new()
	f_header.text = "🔮 Sonraki Seviye (Lvl %d) Şans Tahmini" % next_level
	f_header.add_theme_color_override("font_color", Color(0.6, 0.6, 1.0))
	f_header.add_theme_font_size_override("font_size", 14)
	f_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	f_vbox.add_child(f_header)
	f_vbox.add_child(HSeparator.new())
	
	# Current vs Next Chances
	var cur_data = FacilityManager.get_rarity_chances_at_level(level)
	var next_data = FacilityManager.get_rarity_chances_at_level(next_level)
	
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 20)
	f_vbox.add_child(grid)
	
	# Headers
	var h1 = Label.new()
	h1.text = "KALİTE"
	h1.add_theme_color_override("font_color", Color.GRAY)
	grid.add_child(h1)
	var h2 = Label.new()
	h2.text = "ŞU AN"
	h2.add_theme_color_override("font_color", Color.GRAY)
	grid.add_child(h2)
	var h3 = Label.new()
	h3.text = "SONRAKİ"
	h3.add_theme_color_override("font_color", Color.GRAY)
	grid.add_child(h3)
	
	for rarity in ["COMMON", "UNCOMMON", "RARE", "EPIC", "LEGENDARY"]:
		var name_l = Label.new()
		name_l.text = _format_rarity(rarity)
		name_l.add_theme_color_override("font_color", _get_rarity_color(rarity))
		grid.add_child(name_l)
		
		var cur_c = cur_data.chances.get(rarity, 0.0)
		var next_c = next_data.chances.get(rarity, 0.0)
		
		var cur_l = Label.new()
		cur_l.text = "%%%0.1f" % cur_c
		grid.add_child(cur_l)
		
		var next_l = Label.new()
		next_l.text = "%%%0.1f" % next_c
		
		if next_c > cur_c:
			next_l.add_theme_color_override("font_color", Color.GREEN)
			next_l.text += " (▲)"
		elif next_c < cur_c:
			next_l.add_theme_color_override("font_color", Color(1, 0.5, 0.5)) # Reddish
			next_l.text += " (▼)"
		else:
			next_l.add_theme_color_override("font_color", Color.GRAY)
			
		grid.add_child(next_l)
		
	upgrade_tab.add_child(forecast_panel)
	upgrade_tab.add_child(HSeparator.new())
	
	# Upgrade button
	var player_gold = 0
	if State and State.get("gold") != null:
		player_gold = int(State.gold)
		
	if player_gold >= upgrade_cost:
		var upgrade_btn = Button.new()
		upgrade_btn.text = "⬆️ YÜKSELT (Seviye %d)" % (level + 1)
		upgrade_btn.custom_minimum_size = Vector2(0, 50)
		upgrade_btn.add_theme_color_override("font_color", Color.GREEN)
		upgrade_btn.pressed.connect(_on_upgrade_pressed)
		upgrade_tab.add_child(upgrade_btn)
	else:
		var insufficient_label = Label.new()
		insufficient_label.text = "❌ Yeterli altın yok\n(Gerekli: %d, Var: %d)" % [upgrade_cost, player_gold]
		insufficient_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		insufficient_label.add_theme_color_override("font_color", Color.RED)
		upgrade_tab.add_child(insufficient_label)

func _on_upgrade_pressed() -> void:
	var result = await FacilityManager.upgrade_facility(current_facility_type)
	
	if result.success:
		print("[DetailModal] Upgrade successful!")
		await FacilityManager.fetch_my_facilities()
		set_facility_data(current_facility_type, current_config, 
			FacilityManager.get_facility_by_type(current_facility_type))
	else:
		print("[DetailModal] Upgrade failed: %s" % result.error)

# ==================== HELPER FUNCTIONS ====================

func _format_item_name(item_id: String) -> String:
	"""Convert snake_case item_id to Title Case display name"""
	if item_id.is_empty() or item_id == "unknown":
		return "Unknown Item"
	
	# Remove common prefixes
	var clean_id = item_id.replace("item_", "").replace("ore_", "").replace("gem_", "")
	
	# Convert snake_case to Title Case
	var words = clean_id.split("_")
	var formatted_words = []
	for word in words:
		if word.length() > 0:
			formatted_words.append(word.capitalize())
	
	return " ".join(formatted_words)

func _format_rarity(rarity: String) -> String:
	"""Format rarity for display"""
	match rarity.to_lower():
		"common": return "Yaygın"
		"uncommon": return "Nadir"
		"rare": return "Ender"
		"epic": return "Epik"
		"legendary": return "Efsanevi"
		_: return rarity.capitalize()

func _get_rarity_color(rarity: String) -> Color:
	"""Get color for rarity tier"""
	match rarity.to_lower():
		"common": return Color(0.8, 0.8, 0.8)  # Gray
		"uncommon": return Color(0.3, 1.0, 0.3)  # Green
		"rare": return Color(0.3, 0.6, 1.0)  # Blue
		"epic": return Color(0.8, 0.3, 1.0)  # Purple
		"legendary": return Color(1.0, 0.6, 0.0)  # Orange/Gold
		_: return Color(1.0, 1.0, 1.0)  # White

# ==================== CLOSE ====================


func _on_close_pressed() -> void:
	if queue_update_timer:
		queue_update_timer.stop()
		queue_update_timer.queue_free()
		queue_update_timer = null
	hide()
