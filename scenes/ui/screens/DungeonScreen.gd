extends Control
## DungeonScreen.gd - Zindan seçim ve başlatma UI
## Zindan listesi, filtreler, başarı olasılığı gösterimi, risk/ödül dengesi

class_name DungeonScreen

@onready var dungeon_list: VBoxContainer = %DungeonList
@onready var solo_button: Button = $MarginContainer/VBox/TabButtons/SoloButton
@onready var group_button: Button = $MarginContainer/VBox/TabButtons/GroupButton
@onready var back_button: Button = $MarginContainer/VBox/Header/BackButton

## Manager referansları (autoloads are globally available)
var dungeon_manager: Node  # DungeonManager

## Data
var current_mode: String = "solo"  # "solo" | "group"
var dungeons: Array[DungeonData.DungeonDefinition] = []

func _ready() -> void:
	print("[DungeonScreen] Ready")
	
	# State, Network, Session are autoloads - globally accessible
	
	if not dungeon_manager:
		dungeon_manager = DungeonManager.new()
		add_child(dungeon_manager)
		set_meta("dungeon_manager", dungeon_manager)
	
	# UI bağlantıları
	solo_button.pressed.connect(func(): _change_mode("solo"))
	group_button.pressed.connect(func(): _change_mode("group"))
	back_button.pressed.connect(_on_back_button_pressed)
	
	_load_dungeons()

func _change_mode(mode: String) -> void:
	current_mode = mode
	solo_button.disabled = mode == "solo"
	group_button.disabled = mode == "group"
	print("[DungeonScreen] Mode changed: %s" % mode)
	_load_dungeons()

func _load_dungeons() -> void:
	print("[DungeonScreen] Loading dungeons for mode: %s" % current_mode)
	
	# MOCK DATA - Backend hazır olmadığı için test datası
	var mock_dungeons = [
		{
			"id": "dungeon_tutorial_grotto",
			"name": "Başlangıç Mağarası",
			"description": "Yeni kahramanlar için basit düşmanlar ve küçük ödüller.",
			"difficulty": "EASY",
			"required_level": 1,
			"energy_cost": 5,
			"danger_level": 10,
			"min_reward_gold": 10,
			"max_reward_gold": 50,
			"base_success_rate": 0.90,
			"estimated_duration_seconds": 300
		},
		{
			"id": "dungeon_dark_forest",
			"name": "Karanlık Orman Zindanı",
			"description": "Karanlık Orman'ın derinliklerini keşfet ve bos'u yen.",
			"difficulty": "DUNGEON",
			"required_level": 10,
			"energy_cost": 25,
			"danger_level": 50,
			"min_reward_gold": 500,
			"max_reward_gold": 2000,
			"base_success_rate": 0.45,
			"estimated_duration_seconds": 1800
		},
		{
			"id": "dungeon_cursed_tomb",
			"name": "Lanetli Mezar",
			"description": "Lanetli Mezar'ın sırlarını keşfet.",
			"difficulty": "DUNGEON",
			"required_level": 15,
			"energy_cost": 30,
			"danger_level": 70,
			"min_reward_gold": 1000,
			"max_reward_gold": 5000,
			"base_success_rate": 0.40,
			"estimated_duration_seconds": 2400
		},
		{
			"id": "dungeon_dragon_lair",
			"name": "Ejderha Yuvası",
			"description": "Ejderha Yuvası'na gir ve hazinesini al.",
			"difficulty": "DUNGEON",
			"required_level": 25,
			"energy_cost": 40,
			"danger_level": 90,
			"min_reward_gold": 3000,
			"max_reward_gold": 10000,
			"base_success_rate": 0.35,
			"estimated_duration_seconds": 3000
		}
	]
	
	# Eğer group mode ise kristal mağarası ekle
	if current_mode == "group":
		mock_dungeons.append({
			"id": "dungeon_group_crystal_cavern",
			"name": "Kristal Mağarası (Grup)",
			"description": "Kristal Mağarası'nda grup halinde hazire avla.",
			"difficulty": "DUNGEON",
			"required_level": 12,
			"energy_cost": 35,
			"danger_level": 55,
			"min_reward_gold": 1500,
			"max_reward_gold": 6000,
			"base_success_rate": 0.60,
			"estimated_duration_seconds": 2400,
			"is_group": true
		})
	
	_process_dungeon_data(mock_dungeons)

func _process_dungeon_data(dungeon_data: Array) -> void:
	dungeons.clear()
	
	# Debug
	print("[DungeonScreen] Processing %d dungeons, dungeon_list exists: %s" % [dungeon_data.size(), dungeon_list != null])
	
	if not dungeon_list:
		print("[DungeonScreen] ERROR: dungeon_list node not found!")
		return
	
	# Get player data from State autoload (global variable)
	var player_data = {}
	if State and State.has_method("get_player_data"):
		player_data = State.get_player_data()
	
	if player_data.is_empty():
		print("[DungeonScreen] WARNING: Using default player data")
		player_data = {"level": 1, "energy": 100}
	
	var player_level = player_data.get("level", 1)
	var player_energy = player_data.get("energy", 0)
	
	print("[DungeonScreen] Player level: %d, energy: %d" % [player_level, player_energy])
	
	# Hastane durumunu kontrol et ve güncelle
	if State and State.has_method("check_hospital_status"):
		State.check_hospital_status()
	
	# Hastanelik uyarısı - süresi bitmiş mi kontrol et
	if State and State.in_hospital and State.get_hospital_remaining_seconds() > 0:
		var hospital_warn = Label.new()
		hospital_warn.text = "⚠️ Hastanelisiniz! Zindana giremezsiniz. Hastane sekmesine gidin."
		hospital_warn.add_theme_color_override("font_color", Color.RED)
		hospital_warn.add_theme_font_size_override("font_size", 14)
		dungeon_list.add_child(hospital_warn)
		print("[DungeonScreen] Hospital warning displayed")
		return  # Zindanları gösterme
	
	# Listeyi temizle
	for child in dungeon_list.get_children():
		child.queue_free()
	
	# Her dungeon'u card'a dönüştür
	for dungeon_dict in dungeon_data:
		var dungeon_def = DungeonData.DungeonDefinition.from_dict(dungeon_dict)
		dungeons.append(dungeon_def)
		
		# Card oluştur
		var card = _create_dungeon_card(dungeon_def, player_level, player_energy, player_data)
		dungeon_list.add_child(card)
		print("[DungeonScreen] Added card: %s" % dungeon_def.name)
	
	print("[DungeonScreen] Loaded %d dungeons" % dungeons.size())

func _create_dungeon_card(dungeon: DungeonData.DungeonDefinition, player_level: int, player_energy: int, player_data: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _get_card_style())
	panel.custom_minimum_size = Vector2(0, 160)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	
	# Başlık satırı
	var title_hbox = HBoxContainer.new()
	vbox.add_child(title_hbox)
	
	var name_label = Label.new()
	name_label.text = dungeon.name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	title_hbox.add_child(name_label)
	
	var difficulty_label = Label.new()
	difficulty_label.text = _get_difficulty_emoji(dungeon.difficulty) + " " + dungeon.difficulty
	difficulty_label.add_theme_color_override("font_color", _get_difficulty_color(dungeon.difficulty))
	title_hbox.add_child(difficulty_label)
	
	title_hbox.add_spacer(true)
	
	# Açıklama
	var desc_label = Label.new()
	desc_label.text = dungeon.description
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	desc_label.custom_minimum_size.x = 300
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_label)
	
	# İstatistikler satırı
	var stats_hbox = HBoxContainer.new()
	stats_hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(stats_hbox)
	
	# Seviye
	var level_ok = player_level >= dungeon.required_level
	var level_label = Label.new()
	level_label.text = "Sev: %d" % dungeon.required_level
	level_label.add_theme_color_override("font_color", Color.LIGHT_GREEN if level_ok else Color.LIGHT_CORAL)
	stats_hbox.add_child(level_label)
	
	# Enerji
	var energy_ok = player_energy >= dungeon.energy_cost
	var energy_label = Label.new()
	energy_label.text = "⚡ %d" % dungeon.energy_cost
	energy_label.add_theme_color_override("font_color", Color.YELLOW if energy_ok else Color.ORANGE)
	stats_hbox.add_child(energy_label)
	
	# Ödül (Tahmini hesaplanan band)
	var reward_label = Label.new()
	var estimated = {"min_gold": dungeon.min_reward_gold, "max_gold": dungeon.max_reward_gold, "multiplier": 1.0}
	if dungeon_manager and dungeon_manager.has_method("estimate_reward_range"):
		estimated = dungeon_manager.estimate_reward_range(dungeon)
	reward_label.text = "💰 %d-%d altın (x%s)" % [estimated.get("min_gold"), estimated.get("max_gold"), estimated.get("multiplier")]
	reward_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	stats_hbox.add_child(reward_label)
	
	# Başarı şansı (preview breakdown)
	var preview = dungeon_manager.preview_success_rate(dungeon, player_data)
	var success_label = Label.new()
	success_label.text = "Başarı: %.0f%%" % (preview.get("calculated_rate", 0.0) * 100)
	success_label.add_theme_color_override("font_color", Color.LIGHT_GREEN)
	stats_hbox.add_child(success_label)

	# Compact breakdown label (gear/level/difficulty/penalty)
	var breakdown_parts: Array = []
	var base_pct = preview.get("base_rate", 0.0) * 100
	var gear_pct = (preview.get("gear_effect", 0.0)) * 100
	var level_pct = (preview.get("level_effect", 0.0)) * 100
	var diff_pct = (preview.get("difficulty_effect", 0.0)) * 100
	var penalty_pct = preview.get("level_penalty", 0.0) * 100

	breakdown_parts.append("Base %d%%" % int(base_pct))
	if abs(gear_pct) > 0.5:
		breakdown_parts.append("Gear %+d%%" % int(gear_pct))
	if abs(level_pct) > 0.5:
		breakdown_parts.append("Level %+d%%" % int(level_pct))
	if abs(diff_pct) > 0.5:
		breakdown_parts.append("Diff -%d%%" % int(diff_pct))
	if abs(penalty_pct) > 0.5:
		breakdown_parts.append("Penalty -%d%%" % int(penalty_pct))

	var breakdown_label = Label.new()
	breakdown_label.text = "(" + ", ".join(breakdown_parts) + ")"
	breakdown_label.add_theme_font_size_override("font_size", 10)
	breakdown_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	stats_hbox.add_child(breakdown_label)
	
	stats_hbox.add_spacer(true)
	
	# Info button - shows loot preview & season modifiers
	var info_button = Button.new()
	info_button.text = "Bilgi"
	info_button.custom_minimum_size = Vector2(80, 32)
	info_button.pressed.connect(_on_show_dungeon_info.bindv([dungeon]))
	stats_hbox.add_child(info_button)

	# Giriş butonu
	var enter_button = Button.new()
	enter_button.text = "GİR"
	enter_button.custom_minimum_size = Vector2(100, 40)
	enter_button.pressed.connect(_on_enter_dungeon.bindv([dungeon]))
	
	# Buton kontrolü - sadece enerji kontrolü (seviye kontrolü kaldırıldı)
	var can_enter = energy_ok
	if not can_enter:
		enter_button.disabled = true
		if not energy_ok:
			enter_button.text = "ENERJİ YETERSİZ"
	
	stats_hbox.add_child(enter_button)
	
	return panel

func _get_card_style() -> StyleBox:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.8)
	style.border_color = Color(0.3, 0.3, 0.4, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius(CORNER_TOP_LEFT, 4)
	style.set_corner_radius(CORNER_TOP_RIGHT, 4)
	style.set_corner_radius(CORNER_BOTTOM_LEFT, 4)
	style.set_corner_radius(CORNER_BOTTOM_RIGHT, 4)
	return style

func _get_difficulty_emoji(difficulty: String) -> String:
	match difficulty:
		"EASY": return "✓"
		"MEDIUM": return "⚔️"
		"HARD": return "⚠️"
		"DUNGEON": return "☠️"
		_: return "?"

func _get_difficulty_color(difficulty: String) -> Color:
	match difficulty:
		"EASY": return Color.LIGHT_GREEN
		"MEDIUM": return Color.YELLOW
		"HARD": return Color.ORANGE
		"DUNGEON": return Color.RED
		_: return Color.WHITE

func _on_enter_dungeon(dungeon: DungeonData.DungeonDefinition) -> void:
	print("[DungeonScreen] Entering dungeon: %s" % dungeon.name)
	
	if not Network or not State:
		print("[DungeonScreen] Network/State not ready")
		return
	
	# Hastane durumunu kontrol et ve güncelle
	if State and State.has_method("check_hospital_status"):
		State.check_hospital_status()
	
	# Hastanelik kontrolü - süresi bitmiş mi kontrol et
	if State.in_hospital and State.get_hospital_remaining_seconds() > 0:
		print("[DungeonScreen] Player is hospitalized, cannot enter dungeon!")
		var main = get_tree().root.get_node("Main")
		if main:
			main.show_screen("hospital", true)
		return
	
	var player_data = State.get_player_data()
	
	# DungeonManager ile başlat
	var start_result = dungeon_manager.start_dungeon(dungeon, player_data)

	if start_result.get("success", false):
		# Enerji değişimini State'e yaz
		State.update_player_data({"energy": player_data.get("energy", 0)})
		
		# Battle screen'e git ve instance verisini geçir
		print("[DungeonScreen] Started dungeon, navigating to battle...")
		var main = get_tree().root.get_node("Main")
		if main:
			var instance_data = start_result.get("data", {})
			main.show_screen("dungeon_battle", true, {"dungeon_instance": instance_data})
	else:
		_show_error(start_result.get("error", "Bilinmeyen hata"))

func _on_back_button_pressed() -> void:
	get_tree().root.get_node("Main").go_back()

func _on_show_dungeon_info(dungeon: DungeonData.DungeonDefinition) -> void:
	# Build an info dialog dynamically showing top loot and season modifiers
	var dialog = AcceptDialog.new()
	dialog.title = "%s - Bilgi" % dungeon.name
	dialog.size = Vector2(420, 300)

	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(400, 240)

	# Loot table preview
	var loot_table = {}
	if dungeon_manager and dungeon_manager.has_method("get_loot_table"):
		loot_table = dungeon_manager.get_loot_table(dungeon.id)
	else:
		# Fallback: try to access LOOT_TABLES via a temporary manager instance
		var dm = DungeonManager.new()
		loot_table = dm.get_loot_table(dungeon.id)
	if loot_table.is_empty():
		var l = Label.new()
		l.text = "Muhtemel loot bilgisi bulunamadı"
		vbox.add_child(l)
	else:
		var heading = Label.new()
		heading.text = "Muhtemel Loot (üst 3):"
		heading.add_theme_font_size_override("font_size", 14)
		vbox.add_child(heading)

		# Normalize weights
		var total_w = 0.0
		for k in loot_table.keys():
			total_w += float(loot_table[k])

		var items = []
		for k in loot_table.keys():
			items.append({"id": k, "weight": loot_table[k]})
		items.sort_custom(func(a, b): return int(b["weight"] - a["weight"]))
		for i in range(min(3, items.size())):
			var it = items[i]
			var pct = int((float(it["weight"]) / max(0.0001, total_w)) * 100)
			var row = Label.new()
			row.text = "  • %s (%d%%)" % [it["id"], pct]
			vbox.add_child(row)

	# Estimated gold (calculated using runtime formula)
	var est = Label.new()
	var reward_range = {"min_gold": dungeon.min_reward_gold, "max_gold": dungeon.max_reward_gold, "multiplier": 1.0}
	if dungeon_manager and dungeon_manager.has_method("estimate_reward_range"):
		reward_range = dungeon_manager.estimate_reward_range(dungeon)
	est.text = "Tahmini Altın: %d - %d (x%s)" % [reward_range.get("min_gold"), reward_range.get("max_gold"), reward_range.get("multiplier")]
	vbox.add_child(est)

	# Season modifier
	var season_info = Config.get_nested("season.active_events", {}) if Config else {}
	if typeof(season_info) == TYPE_DICTIONARY and season_info.has("loot_multiplier"):
		var s_lbl = Label.new()
		s_lbl.text = "Etkinlik: Loot x%s" % season_info.get("loot_multiplier", 1.0)
		vbox.add_child(s_lbl)

	dialog.add_child(vbox)
	add_child(dialog)
	dialog.popup_centered()

func _show_error(message: String) -> void:
	var dialog_scene = load("res://scenes/ui/dialogs/ErrorDialog.tscn")
	if dialog_scene:
		get_tree().root.get_node("Main").show_dialog(dialog_scene, {
			"title": "Hata",
			"message": message
		})
