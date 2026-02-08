extends Control
## FacilitiesScreen.gd - 15 Facility Management Screen
## Grid-based display of all 15 facilities with detail modals

# References
@onready var facility_grid = $Layout/VBox/ScrollContainer/GridContainer
@onready var scroll_container = $Layout/VBox/ScrollContainer
@onready var status_label = $Layout/VBox/Header/StatusPill/Margin/StatusLabel
@onready var main_vbox = $Layout/VBox
@onready var empty_label = $Layout/VBox/EmptyState
# detail_modal will be created dynamically when needed
var detail_modal = null

# Scene references
const FACILITY_CARD_SCENE = preload("res://scenes/components/FacilityCard.tscn")
var DETAIL_MODAL_SCENE: PackedScene = null

# Data
var facilities_data: Dictionary = {}  # facility_id -> facility_dict
var selected_facility: Dictionary = {}

# UI state
var is_loading: bool = false
var detail_modal_visible: bool = false
var global_risk_panel: Control = null

func _ready() -> void:
	# Connect to FacilityManager signals
	FacilityManager.facilities_updated.connect(_on_facilities_updated)
	FacilityManager.facility_unlocked.connect(_on_facility_unlocked)
	FacilityManager.production_started.connect(_on_production_started)
	FacilityManager.production_completed.connect(_on_production_completed)
	FacilityManager.suspicion_changed.connect(_on_suspicion_changed)
	FacilityManager.bribe_completed.connect(_on_bribe_completed)
	FacilityManager.facility_upgraded.connect(_on_facility_upgraded)
	FacilityManager.sent_to_prison.connect(_on_sent_to_prison)
	
	# Connect to State signals
	State.state_changed.connect(_on_state_changed)
	
	# Connect to PrisonManager signals
	if PrisonManager:
		PrisonManager.prison_released.connect(_on_prison_released)
	
	# Add test reset button
	_add_reset_button()
	
	# Initial load
	_refresh_facilities()

## Add reset all production button to header
func _add_reset_button() -> void:
	var reset_btn = Button.new()
	reset_btn.text = "🔧 TEST: TÜM ÜRETİMLERİ SIRFIRLA"
	reset_btn.custom_minimum_size = Vector2(300, 40)
	reset_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	reset_btn.add_theme_color_override("font_color", Color(1, 0.4, 0.4))  # Red for testing
	reset_btn.pressed.connect(_on_reset_all_production_pressed)
	
	# Insert at top of main_vbox, right after we set it up
	main_vbox.add_child(reset_btn)
	main_vbox.move_child(reset_btn, 0)  # Move to top

# ==================== DATA LOADING ====================

func _refresh_facilities() -> void:
	if is_loading:
		return
	
	is_loading = true
	status_label.text = "Tesisler yükleniyor..."
	
	var result = await FacilityManager.fetch_my_facilities()
	# print("[FacilitiesScreen] Fetch result: %s" % result)
	
	if result.get("success", false):
		facilities_data = {}
		var data = result.get("data", [])
		# print("[FacilitiesScreen] Data array: %s" % [data])
		for facility in data:
			facilities_data[facility.id] = facility
		print("[FacilitiesScreen] Facilities loaded: %d" % facilities_data.size())
		_render_facility_grid()
	else:
		status_label.text = "Hata: %s" % result.get("error", "Bilinmeyen hata")
		print("[FacilitiesScreen] Error: %s" % result.get("error", "Unknown"))
	
	is_loading = false

func _on_facilities_updated() -> void:
	# Signal received, just re-render with current cache
	# Don't fetch again to avoid infinite loops
	await get_tree().process_frame
	await get_tree().process_frame
	_render_facility_grid()
	_update_global_risk_ui()



# ==================== UI RENDERING ====================

func _render_facility_grid() -> void:
	# Ensure grid is visible
	facility_grid.visible = true
	scroll_container.visible = true
	
	await get_tree().process_frame
	
	# Get all facility types
	var config = FacilityManager.FACILITIES_CONFIG
	
	# Map existing cards by type for reuse
	var existing_cards = {}
	for child in facility_grid.get_children():
		if child.get("facility_type"):
			existing_cards[child.facility_type] = child
	
	# Render ALL 15 facilities (unlocked + locked)
	var _card_count = 0
	for facility_type in config.keys():
		var owned_facility = FacilityManager.get_facility_by_type(facility_type)
		
		if existing_cards.has(facility_type):
			# Update existing card
			var card = existing_cards[facility_type]
			card.level = owned_facility.get("level", 1) if not owned_facility.is_empty() else 1
			# Use update helper if available or set manually
			if card.has_method("update_from_facility_data"):
				card.update_from_facility_data(owned_facility)
			else:
				# Fallback
				card.is_unlocked = not owned_facility.is_empty()
				if card.is_unlocked:
					card.level = owned_facility.get("level", 1)
					card.suspicion = owned_facility.get("suspicion_level", 0)
				card._update_status_display()
				
		else:
			# Create new card
			var card = _create_facility_card(facility_type)
			facility_grid.add_child(card)
			existing_cards[facility_type] = card # Cache it
		
		_card_count += 1
	
	_update_global_risk_ui()
	
	# Update status to show total and unlocked count
	var unlocked_count = facilities_data.size()
	var total_count = config.size()
	status_label.text = "%d / %d tesis açık" % [unlocked_count, total_count]
	# print("[FacilitiesScreen] Status: %d / %d" % [unlocked_count, total_count])

	# Empty state (kept hidden when cards exist)
	if empty_label:
		empty_label.visible = total_count == 0

func _create_facility_card(facility_type: String) -> Control:
	var card = FACILITY_CARD_SCENE.instantiate()
	
	var config = FacilityManager.FACILITIES_CONFIG.get(facility_type, {})
	var owned_facility = FacilityManager.get_facility_by_type(facility_type)
	
	# Card data
	card.facility_type = facility_type
	card.facility_name = config.get("name", facility_type)
	card.facility_description = config.get("name", facility_type)
	card.is_unlocked = not owned_facility.is_empty()
	
	# Facility data (if owned)
	if card.is_unlocked:
		card.level = owned_facility.get("level", 1)
		card.suspicion = owned_facility.get("suspicion_level", 0)
		card.production_queue_count = _get_facility_queue_count(owned_facility.get("id", ""))
	else:
		# Cost from config
		card.unlock_cost = config.get("unlock_cost", 5000)
	
	# Ensure card is visible
	card.visible = true
	card.modulate = Color.WHITE
	
	# Connect card signals
	card.detail_pressed.connect(_on_facility_card_detail_pressed.bindv([facility_type]))
	card.unlock_pressed.connect(_on_facility_unlock_pressed.bindv([facility_type]))
	
	# print("[FacilitiesScreen] Created card for %s, unlocked=%s" % [card.facility_name, card.is_unlocked])
	
	return card

func _get_facility_queue_count(facility_id: String) -> int:
	if not facilities_data.has(facility_id):
		return 0
	
	var facility = facilities_data[facility_id]
	# Support both 'facility_queue' (from RPC) and 'facility_production_queue' (from old API)
	var queue = facility.get("facility_queue", [])
	if queue.is_empty():
		queue = facility.get("facility_production_queue", [])
	
	# Count incomplete items
	var count = 0
	for item in queue:
		if item.get("completed_at") == null:
			count += 1
	
	return count

# ==================== CARD INTERACTIONS ====================

func _on_facility_card_detail_pressed(facility_type: String) -> void:
	# Debug: log current prison flags
	print("[FacilitiesScreen] _on_facility_card_detail_pressed - State.in_prison=%s, State.player.in_prison=%s" % [str(State.in_prison), str(State.player.get("in_prison", null))])
	# Check if player is in prison — allow brief re-check to avoid race with bail
	if State.in_prison:
		# small debounce to allow state propagation (e.g., bail completed just now)
		await get_tree().create_timer(0.1).timeout
		print("[FacilitiesScreen] Re-check after debounce: State.in_prison=%s" % str(State.in_prison))
		if State.in_prison:
			_show_error("Hapse düştünüz! Tesislere erişemezsiniz.")
			return
	
	selected_facility = FacilityManager.get_facility_by_type(facility_type)
	if selected_facility.is_empty():
		_show_unlock_dialog(facility_type)
	else:
		_show_detail_modal(facility_type)

func _on_facility_unlock_pressed(facility_type: String) -> void:
	print("[FacilitiesScreen] _on_facility_unlock_pressed called for: %s" % facility_type)
	# Check if player is in prison
	if State.in_prison:
		_show_error("⚠️ HAPİSTESİNİZ! İşlem yapamazsınız.")
		return
	
	if not FacilityManager.FACILITIES_CONFIG.has(facility_type):
		_show_error("Unknown facility type: %s" % facility_type)
		return
	
	var config = FacilityManager.FACILITIES_CONFIG[facility_type]
	var cost = 5000  # Default unlock cost
	print("[FacilitiesScreen] Showing confirmation dialog for unlock, cost=%d" % cost)
	
	# Show confirmation dialog
	var result = await _show_confirmation_dialog(
		"Tesisi Aç",
		"'%s' tesisini %d altınla açmak istiyor musunuz?" % [config.get("name"), cost],
		"Aç", "İptal"
	)
	
	print("[FacilitiesScreen] Confirmation dialog result: %s" % result)
	
	if result:
		print("[FacilitiesScreen] User confirmed, calling _unlock_facility...")
		_unlock_facility(facility_type)
	else:
		print("[FacilitiesScreen] User cancelled unlock")

func _on_facility_production_pressed(facility_type: String) -> void:
	var facility = FacilityManager.get_facility_by_type(facility_type)
	if facility.is_empty():
		_show_error("Tesiyi açmanız gerekir")
		return
	
	_show_production_modal(facility_type)

# ==================== DETAIL MODAL ====================

func _ensure_detail_modal() -> void:
	if detail_modal != null:
		return
	
	print("[FacilitiesScreen] Loading DetailModal.tscn...")
	DETAIL_MODAL_SCENE = load("res://scenes/components/DetailModal.tscn")
	
	if DETAIL_MODAL_SCENE == null:
		push_error("[FacilitiesScreen] Failed to load DetailModal.tscn")
		return
	
	print("[FacilitiesScreen] Instantiating DetailModal...")
	detail_modal = DETAIL_MODAL_SCENE.instantiate()
	
	if detail_modal == null:
		push_error("[FacilitiesScreen] Failed to instantiate DetailModal")
		return
	
	add_child(detail_modal)
	detail_modal.hide()
	print("[FacilitiesScreen] DetailModal created successfully")

func _show_detail_modal(facility_type: String) -> void:
	_ensure_detail_modal()
	
	if detail_modal == null:
		push_error("[FacilitiesScreen] detail_modal is still null after _ensure_detail_modal")
		return
	
	selected_facility = FacilityManager.get_facility_by_type(facility_type)
	if selected_facility.is_empty():
		return
	
	var config = FacilityManager.FACILITIES_CONFIG.get(facility_type, {})
	
	# Update modal with facility data
	detail_modal.set_facility_data(
		facility_type,
		config,
		selected_facility
	)
	
	# If imprisoned, disable all action buttons in the modal
	if State.in_prison:
		print("[FacilitiesScreen] Player is in prison - disabling modal buttons")
		detail_modal.disable_all_buttons()
	
	detail_modal.show()
	detail_modal_visible = true

func _show_unlock_dialog(facility_type: String) -> void:
	var config = FacilityManager.FACILITIES_CONFIG.get(facility_type, {})
	var cost = 5000  # Default unlock cost
	
	var result = await _show_confirmation_dialog(
		"Tesisi Aç",
		"'%s' tesisini %d altınla açmak istiyor musunuz?" % [config.get("name"), cost],
		"Aç", "İptal"
	)
	
	if result:
		_unlock_facility(facility_type)

# ==================== FACILITY OPERATIONS ====================

func _unlock_facility(facility_type: String) -> void:
	print("[FacilitiesScreen] _unlock_facility called for: %s" % facility_type)
	var result = await FacilityManager.unlock_facility(facility_type)
	print("[FacilitiesScreen] unlock_facility result: %s" % result)
	
	if result.get("success", false):
		_show_success("'%s' tesisi açıldı!" % FacilityManager.FACILITIES_CONFIG[facility_type].get("name"))
		await get_tree().create_timer(0.5).timeout
		_refresh_facilities()
	else:
		_show_error("Hata: %s" % result.get("error", "Bilinmeyen hata"))

func _on_facility_unlocked(_facility_id: String, facility_name: String) -> void:
	print("[FacilitiesScreen] Facility unlocked: %s" % facility_name)
	# Refresh is already done in _unlock_facility, no need to do it again

# ==================== PRODUCTION OPERATIONS ====================

func _show_production_modal(facility_type: String) -> void:
	# Use detail modal to show production options
	_ensure_detail_modal()
	
	if detail_modal == null:
		push_error("[FacilitiesScreen] detail_modal is still null after _ensure_detail_modal")
		return
	
	selected_facility = FacilityManager.get_facility_by_type(facility_type)
	if selected_facility.is_empty():
		print("[FacilitiesScreen] No facility data for: %s" % facility_type)
		return
	
	var config = FacilityManager.FACILITIES_CONFIG.get(facility_type, {})
	
	detail_modal.set_facility_data(
		facility_type,
		config,
		selected_facility
	)
	
	detail_modal.show()
	detail_modal_visible = true

func _on_production_started(facility_id: String, recipe_name: String, quantity: int, rarity: String) -> void:
	print("[FacilitiesScreen] Production started: facility %s, recipe %s (qty: %d, rarity: %s)" % [facility_id, recipe_name, quantity, rarity])
	_show_success("Üretim başladı: %s" % recipe_name)
	await get_tree().create_timer(1.0).timeout
	_refresh_facilities()

func _on_production_completed(_facility_id: String, item_name: String, rarity: String) -> void:
	print("[FacilitiesScreen] Production completed: %s (%s)" % [item_name, rarity])
	_refresh_facilities()

# ==================== SUSPICION & BRIBE ====================

func _on_suspicion_changed(facility_id: String, new_suspicion: int) -> void:
	print("[FacilitiesScreen] Suspicion changed: facility %s, level %d" % [facility_id, new_suspicion])
	_refresh_facilities()

func _on_bribe_completed(facility_id: String, cost: int) -> void:
	print("[FacilitiesScreen] Bribe completed: facility %s, cost: %d" % [facility_id, cost])
	_show_success("Memurlar rüşvet aldı! Maliyeti: %d gem" % cost)
	_refresh_facilities()

func _on_facility_bribe_pressed(facility_type: String) -> void:
	print("[FacilitiesScreen] _on_facility_bribe_pressed called for: %s" % facility_type)
	var facility = FacilityManager.get_facility_by_type(facility_type)
	if facility.is_empty():
		_show_error("Tesis bulunamadı")
		return
	
	var gems_cost = 5  # Default bribe cost
	
	# Check if player has enough gems
	if State.gems < gems_cost:
		_show_error("Yeterli gem yok! Gerekli: %d, Mevcut: %d" % [gems_cost, State.gems])
		return
	
	var result = await _show_confirmation_dialog(
		"Rüşvet Ver",
		"Memurları rüşvet vermek için %d gem harcamak istiyor musunuz?" % gems_cost,
		"Rüşvet Ver", "İptal"
	)
	
	if result:
		var bribe_result = await FacilityManager.bribe_officials(facility_type, gems_cost)
		if bribe_result.get("success", false):
			State.update_gems(bribe_result.get("gems_remaining", State.gems - gems_cost))
			_show_success("Rüşvet verildi! Yeni şüphe seviyesi: %d" % bribe_result.get("new_suspicion", 0))
			await get_tree().create_timer(0.5).timeout
			_refresh_facilities()
		else:
			_show_error("Rüşvet başarısız: %s" % bribe_result.get("error", "Bilinmeyen hata"))

# ==================== UPGRADE OPERATIONS ====================

func _on_facility_upgraded(facility_id: String, new_level: int) -> void:
	print("[FacilitiesScreen] Facility upgraded: %s to level %d" % [facility_id, new_level])
	_show_success("Tesis seviye %d'e yükseltildi!" % new_level)
	_refresh_facilities()

# ==================== PRISON ====================

func _on_sent_to_prison(prison_hours: int, suspicion_was: int) -> void:
	print("[FacilitiesScreen] Sent to prison: hours: %d, previous suspicion: %d" % [prison_hours, suspicion_was])
	_show_warning("⚠️ HAPİS\n\nSüre: %d saat" % prison_hours)

func _on_state_changed(key: String, value: Variant) -> void:
	if key == "prison":
		print("[FacilitiesScreen] Prison state changed: %s" % value)
		_update_global_risk_ui()  # Refresh risk UI to show/hide prison warning
		# Also refresh facility grid/cards so buttons reflect new state
		_render_facility_grid()

# ==================== DIALOG HELPERS ====================

func _show_confirmation_dialog(title: String, message: String, yes_text: String = "Evet", no_text: String = "Hayır") -> bool:
	print("[FacilitiesScreen] _show_confirmation_dialog: %s" % title)
	var dialog = ConfirmationDialog.new()
	dialog.title = title
	dialog.dialog_text = message
	dialog.ok_button_text = yes_text
	dialog.cancel_button_text = no_text
	
	add_child(dialog)
	dialog.popup_centered_ratio(0.4)
	
	# Use array/dict for reference capture in lambdas
	var state = {"confirmed": false, "closed": false}
	
	dialog.confirmed.connect(func():
		print("[FacilitiesScreen] Dialog CONFIRMED signal received")
		state.confirmed = true
		state.closed = true
	)
	dialog.canceled.connect(func():
		print("[FacilitiesScreen] Dialog CANCELED signal received")
		state.confirmed = false
		state.closed = true
	)
	
	# Wait until dialog is closed
	while not state.closed:
		await get_tree().process_frame
	
	print("[FacilitiesScreen] Dialog result: confirmed=%s" % state.confirmed)
	dialog.queue_free()
	return state.confirmed

func _show_success(message: String) -> void:
	print("[FacilitiesScreen] SUCCESS: %s" % message)
	_show_toast(message, Color.GREEN)

func _show_error(message: String) -> void:
	print("[FacilitiesScreen] ERROR: %s" % message)
	_show_toast(message, Color.RED)

func _show_warning(message: String) -> void:
	print("[FacilitiesScreen] WARNING: %s" % message)
	_show_toast(message, Color.YELLOW)

func _show_toast(message: String, color: Color = Color.WHITE) -> void:
	# Create a simple toast notification
	var toast_container = Control.new()
	toast_container.name = "Toast"
	add_child(toast_container)
	toast_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	
	# Create background panel
	var panel = PanelContainer.new()
	toast_container.add_child(panel)
	
	var style = StyleBoxFlat.new()
	style.bg_color = color.lerp(Color.BLACK, 0.7)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	
	# Create text label
	var label = Label.new()
	label.text = message
	label.custom_minimum_size = Vector2(300, 0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", 14)
	panel.add_child(label)
	
	# Position at top center
	toast_container.position = Vector2(get_viewport_rect().size.x / 2 - 150, 20)
	
	# Auto-hide after 3 seconds
	await get_tree().create_timer(3.0).timeout
	toast_container.queue_free()

func _update_global_risk_ui() -> void:
	# Check if player is in prison first
	if State.in_prison:
		# Show prison warning instead of risk UI
		if global_risk_panel == null:
			global_risk_panel = PanelContainer.new()
			var prison_style = StyleBoxFlat.new()
			prison_style.bg_color = Color(0.2, 0.05, 0.05, 0.9)
			prison_style.border_width_bottom = 3
			prison_style.border_color = Color(0.9, 0.1, 0.1, 0.8)
			prison_style.content_margin_top = 15
			prison_style.content_margin_bottom = 15
			prison_style.content_margin_left = 20
			prison_style.content_margin_right = 20
			global_risk_panel.add_theme_stylebox_override("panel", prison_style)
			
			if main_vbox:
				main_vbox.add_child(global_risk_panel)
				main_vbox.move_child(global_risk_panel, 1)
		
		# Clear previous content
		for child in global_risk_panel.get_children():
			child.queue_free()
		
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 10)
		global_risk_panel.add_child(vbox)
		
		# Prison warning title
		var title_lbl = Label.new()
		title_lbl.text = "⛓️ HAPİSTESİNİZ!"
		title_lbl.add_theme_font_size_override("font_size", 20)
		title_lbl.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(title_lbl)
		
		# Prison reason
		var reason_lbl = Label.new()
		reason_lbl.text = "📄 Gerekçe: " + State.prison_reason
		reason_lbl.add_theme_font_size_override("font_size", 14)
		reason_lbl.add_theme_color_override("font_color", Color(1, 0.8, 0.8))
		reason_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(reason_lbl)
		
		# Remaining time and bail cost calculation
		var remaining_mins = State.get_prison_remaining_minutes()
		var bail_cost = max(1, remaining_mins)  # 1 gem per minute, minimum 1
		
		var time_lbl = Label.new()
		time_lbl.text = "⏱️ Kalan Süre: %d dakika" % remaining_mins
		time_lbl.add_theme_font_size_override("font_size", 16)
		time_lbl.add_theme_color_override("font_color", Color.WHITE)
		time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(time_lbl)
		
		# Cost display
		var cost_lbl = Label.new()
		cost_lbl.text = "💎 Kefalet Maliyeti: %d Gem" % bail_cost
		cost_lbl.add_theme_font_size_override("font_size", 14)
		cost_lbl.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
		cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(cost_lbl)
		
		# Bail button
		var bail_btn = Button.new()
		bail_btn.add_theme_font_size_override("font_size", 14)
		bail_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		bail_btn.pressed.connect(_on_prison_bail_pressed.bindv([bail_cost]))
		
		if State.gems >= bail_cost:
			bail_btn.text = "💎 Kefalet Öde (%d Gem)" % bail_cost
		else:
			bail_btn.disabled = true
			bail_btn.text = "❌ Yeterli Gem Yok (%d/%d)" % [State.gems, bail_cost]
		
		vbox.add_child(bail_btn)
		
		return
	
	# Get global suspicion from database (State), not from local calculation
	# This ensures we show the authoritative value from the server
	var suspicion = State.player.get("global_suspicion_level", 0)
	if suspicion is float:
		suspicion = int(suspicion)
	
	# Create or reuse panel
	if global_risk_panel == null:
		global_risk_panel = PanelContainer.new()
		var risk_style = StyleBoxFlat.new()
		risk_style.bg_color = Color(0.15, 0.05, 0.05, 0.8)
		risk_style.border_width_bottom = 2
		risk_style.border_color = Color(0.8, 0.2, 0.2, 0.5)
		risk_style.content_margin_top = 15
		risk_style.content_margin_bottom = 15
		risk_style.content_margin_left = 20
		risk_style.content_margin_right = 20
		global_risk_panel.add_theme_stylebox_override("panel", risk_style)
		
		# Insert into VBoxContainer at top (index 0 or 1)
		# Assuming Header is index 0. We want it BELOW header or ABOVE?
		# User said "tesis ana ekranının en üstünde". Let's put it at index 0 or 1.
		if main_vbox:
			main_vbox.add_child(global_risk_panel)
			main_vbox.move_child(global_risk_panel, 1) # Position 1 (after Header)
		
	# Clear previous content
	for child in global_risk_panel.get_children():
		child.queue_free()
		
	# Rebuild content - Vertical Stack
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	global_risk_panel.add_child(vbox)
	
	# Row 1: Title
	var title_lbl = Label.new()
	title_lbl.text = "⚠️ GLOBAL RİSK SEVİYESİ"
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)
	
	# Row 2: Progress Bar
	var progress_bar = ProgressBar.new()
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.value = suspicion
	progress_bar.custom_minimum_size.y = 24
	progress_bar.show_percentage = false
	
	# Color coding
	var bar_style = StyleBoxFlat.new()
	if suspicion < 30:
		bar_style.bg_color = Color.GREEN
	elif suspicion < 60:
		bar_style.bg_color = Color.YELLOW
	elif suspicion < 80:
		bar_style.bg_color = Color.ORANGE
	else:
		bar_style.bg_color = Color.RED
	progress_bar.add_theme_stylebox_override("fill", bar_style)
	vbox.add_child(progress_bar)
	
	# Row 3: Info & Actions (Level + Bribe Button)
	var action_row = HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 20)
	vbox.add_child(action_row)
	
	# Percentage Label
	var perc_lbl = Label.new()
	perc_lbl.text = "Risk: %%%d" % suspicion
	perc_lbl.add_theme_font_size_override("font_size", 18)
	perc_lbl.add_theme_color_override("font_color", Color.WHITE)
	action_row.add_child(perc_lbl)
	
	# Bribe Button
	var bribe_btn = Button.new()
	bribe_btn.text = "Rüşvet Ver (5💎)"
	bribe_btn.add_theme_font_size_override("font_size", 14)
	bribe_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	bribe_btn.pressed.connect(_on_global_bribe_pressed)
	# Disable if risk is 0 to avoid confusion, or keep enable to show message
	if suspicion == 0:
		bribe_btn.disabled = true
		bribe_btn.text = "Şüphe Yok"
	action_row.add_child(bribe_btn)
	
	# Row 4: Prison Warning Label
	var warning_lbl = Label.new()
	warning_lbl.text = "⚠️ DİKKAT: Hapse düşerseniz üretimdeki eşyalar kaybolur!"
	warning_lbl.add_theme_font_size_override("font_size", 12)
	warning_lbl.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	warning_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(warning_lbl)

func _on_global_bribe_pressed() -> void:
	# Find facility with highest suspicion
	var max_suspicion = -1
	var target_facility_type = ""
	
	for facility in FacilityManager.cached_facilities.values():
		var susp = facility.get("suspicion_level", 0)
		if susp > max_suspicion:
			max_suspicion = susp
			target_facility_type = facility.get("type", "")
			
	if target_facility_type == "":
		_show_error("Tesis bulunamadı!")
		return

	var confirmed = await _show_confirmation_dialog(
		"Rüşvet Ver",
		"Global risk seviyesi 0%%'e düşecek. 5 Gem harcamak istiyor musunuz?",
		"Ver", "İptal"
	)
	
	if confirmed:
		# Call manager directly to avoid double dialog
		var gems_cost = 5
		if State.gems < gems_cost:
			_show_error("Yeterli gem yok!")
			return
			
		var bribe_result = await FacilityManager.bribe_officials(target_facility_type, gems_cost)
		if bribe_result.get("success", false):
			State.update_gems(bribe_result.get("gems_remaining", State.gems - gems_cost))
			_show_success("Rüşvet verildi! Şüphe düştü.")
			await get_tree().create_timer(0.5).timeout
			_refresh_facilities()
		else:
			_show_error("Hata: %s" % bribe_result.get("error", "Bilinmeyen"))

func _on_reset_all_production_pressed() -> void:
	print("[FacilitiesScreen] Reset ALL production button pressed")
	_show_toast("🔧 TÜM ÜRETİMLER SIFIRLANIYOR...", Color.YELLOW)
	
	var result = await FacilityManager.reset_all_facility_production()
	if result.success:
		_show_toast("✅ %d tesis sıfırlandı! (%d queue item silindi)" % [
			result.get("facilities_reset", 0),
			result.get("queue_items_deleted", 0)
		], Color.GREEN)
		# Refresh UI
		_refresh_facilities()
	else:
		_show_toast("❌ Hata: %s" % result.error, Color.RED)

func _on_prison_bail_pressed(bail_cost: int = 0) -> void:
	if bail_cost <= 0:
		bail_cost = max(1, State.get_prison_remaining_minutes())
	
	var confirmed = await _show_confirmation_dialog(
		"Kefalet Öde",
		"Hapisten çıkmak için %d Gem harcayacak mısınız?" % bail_cost,
		"Öde", "İptal"
	)
	
	if confirmed:
		_show_toast("💎 Kefalet ödeniyor...", Color.YELLOW)
		PrisonManager.pay_bail()

func _on_prison_released(success: bool, message: String) -> void:
	if success:
		_show_success("✅ " + message)
		# Wait a moment for server state to be synced
		await get_tree().create_timer(0.5).timeout
		# Manually refresh to ensure UI updates from current state
		if State.in_prison:
			print("[FacilitiesScreen] Warning: State.in_prison still true after bail, refreshing...")
			_refresh_facilities()
	else:
		_show_error("❌ Kefalet başarısız: " + message)
