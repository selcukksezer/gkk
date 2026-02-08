extends PanelContainer

# Signals
signal detail_pressed
signal unlock_pressed
# (production_pressed and bribe_pressed not used; removed to avoid warnings)

# UI Elements
@onready var icon_texture = $Margin/HBox/IconContainer/IconTexture
@onready var icon_label = $Margin/HBox/IconContainer/IconLabel
@onready var name_label = $Margin/HBox/InfoBox/TopStats/NameLabel
@onready var status_label = $Margin/HBox/InfoBox/TopStats/StatusLabel
@onready var desc_label = $Margin/HBox/InfoBox/DescriptionLabel

@onready var level_badge = $Margin/HBox/InfoBox/StatsRow/LevelBadge
@onready var level_label = $Margin/HBox/InfoBox/StatsRow/LevelBadge/Margin/LevelLabel
@onready var suspicion_badge = $Margin/HBox/InfoBox/StatsRow/SuspicionBadge
@onready var suspicion_label = $Margin/HBox/InfoBox/StatsRow/SuspicionBadge/Margin/SuspicionLabel

@onready var main_button = $Margin/HBox/ActionsBox/MainButton

# Data
var facility_type: String = ""
var facility_name: String = ""
var facility_description: String = ""
var is_unlocked: bool = false
var level: int = 1
var suspicion: int = 0
var production_queue_count: int = 0
var unlock_cost: int = 5000

func _ready() -> void:
	# Verify nodes exist
	if not name_label: push_error("FacilityCard: NameLabel not found!")
	if not icon_texture: push_error("FacilityCard: IconTexture not found!")
	if not main_button: push_error("FacilityCard: MainButton not found!")
	
	# Scale button on hover for juice
	if main_button:
		# Inline handler to avoid missing function reference
		main_button.pressed.connect(func():
			if is_unlocked:
				detail_pressed.emit()
			else:
				unlock_pressed.emit()
		)
	
	_apply_visuals()

func _apply_visuals() -> void:
	if not is_node_ready(): return

	# 1. Icon Handling
	var config = FacilityManager.FACILITIES_CONFIG.get(facility_type, {})
	var icon_path = config.get("icon", "🏭")
	
	if icon_texture and icon_label:
		if typeof(icon_path) == TYPE_STRING:
			# 1. First Attempt: Load exact path
			var texture = _try_load_icon(icon_path)
			
			# 2. Second Attempt: Try swapping 'facility_' prefix to 'icon_' (Self-healing for cache issues)
			if not texture and "facility_" in icon_path:
				var healing_path = icon_path.replace("facility_", "icon_")
				print("FacilityCard: Retrying with healed path: %s" % healing_path)
				texture = _try_load_icon(healing_path)

			if texture:
				icon_texture.texture = texture
				icon_texture.visible = true
				icon_label.visible = false
			else:
				print("FacilityCard: Failed to load icon for %s (type: %s)" % [facility_name, facility_type])
				icon_label.text = "❓"
				icon_label.visible = true
				icon_texture.visible = false
		else:
			icon_label.text = str(icon_path)
			icon_label.visible = true
			icon_texture.visible = false

	# 2. Labels
	if name_label:
		name_label.text = facility_name
	if desc_label:
		desc_label.text = facility_description if facility_description != "" else config.get("name", "Facility") + " managed here."
	
	# 3. Status & Badges
	if is_unlocked:
		if status_label:
			status_label.text = "AÇIK"
			status_label.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
		
		if level_badge: level_badge.visible = true
		if level_label: level_label.text = "SEV %d" % level
		
		# Re-purposing Suspicion Badge for Timer/Status
		if suspicion_badge: suspicion_badge.visible = true
		
		# Will update in _process() based on real facility data

		# Button State
		if main_button:
			main_button.text = "Yönet"
			main_button.modulate = Color(1, 1, 1)

	else:
		if status_label:
			status_label.text = "KİLİTLİ"
			status_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))

		if level_badge: level_badge.visible = false
		if suspicion_badge: suspicion_badge.visible = false
		
		# Button State
		if main_button:
			main_button.text = "Aç (%d G)" % unlock_cost
			main_button.modulate = Color(1, 0.8, 0.6)

func _try_load_icon(path: String) -> Texture2D:
	# Use ResourceLoader.load() directly - it's the most reliable for res:// paths
	# The editor uses this same method, so if it works there, it works here
	if ResourceLoader.exists(path):
		var texture = load(path)
		if texture is Texture2D:
			return texture
		else:
			print("FacilityCard: ResourceLoader returned non-Texture2D: %s (type: %s)" % [path, typeof(texture)])
	else:
		print("FacilityCard: ResourceLoader.exists() returned false for: %s" % path)
	
	return null

func update_from_facility_data(data: Dictionary) -> void:
	if data.is_empty():
		is_unlocked = false
	else:
		is_unlocked = true
		level = data.get("level", 1)
		suspicion = data.get("suspicion_level", 0)
	
	_apply_visuals()

func _update_status_display() -> void:
	_apply_visuals()

func _process(_delta: float) -> void:
	if not is_unlocked: return
	
	# Get real production status from FacilityManager
	var facility = FacilityManager.get_facility_by_type(facility_type)
	if facility.is_empty():
		return
	
	var resources_data = FacilityManager.calculate_idle_resources(facility)
	var status = resources_data.get("status", "stopped")
	var remaining_sec = resources_data.get("remaining_seconds", 0)
	var total_count = resources_data.get("total_count", 0)
	
	# Update label based on real status
	if status == "active":
		# Üretim devam ediyor - Timer göster
		var mins = int(remaining_sec / 60)
		var secs = int(remaining_sec) % 60
		if suspicion_label:
			suspicion_label.text = "⏳ %02d:%02d" % [mins, secs]
			_set_status_color(Color.GREEN)
	elif status == "expired" and total_count > 0:
		# Üretim bitti ama kaynak var - "Üretim Bitti" göster
		if suspicion_label:
			suspicion_label.text = "✅ BİTTİ"
			_set_status_color(Color.YELLOW)
	else:
		# Hiç üretim yok veya bitti ve kaynak yok - "Boşta" göster
		if suspicion_label:
			suspicion_label.text = "⚪ BOŞTA"
			_set_status_color(Color.GRAY)



func _set_status_color(color: Color) -> void:
	if suspicion_badge:
		var style = suspicion_badge.get_theme_stylebox("panel")
		if style: style.bg_color = color.darkened(0.5)
		if suspicion_label: suspicion_label.add_theme_color_override("font_color", color.lightened(0.2))

