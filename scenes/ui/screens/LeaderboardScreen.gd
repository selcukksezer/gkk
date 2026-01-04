extends Control
## Leaderboard Screen - Season Rankings
## Sezon sıralaması ve ödüller

@onready var leaderboard_list: VBoxContainer = %LeaderboardList
@onready var season_label: Label = %SeasonLabel
@onready var time_label: Label = %TimeLabel
@onready var my_rank_label: Label = %RankLabel
@onready var reward_text: Label = %RewardText
@onready var back_button: Button = $MarginContainer/VBox/Header/BackButton

# Category buttons
@onready var wealth_button: Button = $MarginContainer/VBox/CategoryTabs/WealthButton
@onready var pvp_button: Button = $MarginContainer/VBox/CategoryTabs/PvPButton
@onready var quest_button: Button = $MarginContainer/VBox/CategoryTabs/QuestButton
@onready var economy_button: Button = $MarginContainer/VBox/CategoryTabs/EconomyButton
@onready var guild_button: Button = $MarginContainer/VBox/CategoryTabs/GuildButton

var current_category: String = "wealth"
var leaderboard_data: Array[Dictionary] = []
var is_loading: bool = false

func _ready() -> void:
	# Connect buttons
	wealth_button.pressed.connect(func(): _change_category("wealth"))
	pvp_button.pressed.connect(func(): _change_category("pvp"))
	quest_button.pressed.connect(func(): _change_category("quest"))
	economy_button.pressed.connect(func(): _change_category("economy"))
	guild_button.pressed.connect(func(): _change_category("guild"))
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Load data
	_load_season_info()
	_load_leaderboard()
	
	print("[LeaderboardScreen] Ready")

func _change_category(category: String) -> void:
	if current_category == category:
		return
	
	current_category = category
	_update_category_buttons()
	_load_leaderboard()

func _update_category_buttons() -> void:
	wealth_button.disabled = current_category == "wealth"
	pvp_button.disabled = current_category == "pvp"
	quest_button.disabled = current_category == "quest"
	economy_button.disabled = current_category == "economy"
	guild_button.disabled = current_category == "guild"

func _load_season_info() -> void:
	var result = await Network.http_get("/v1/season/current")
	if result.success:
		var season_data = result.data
		season_label.text = "Sezon %d - %s" % [
			season_data.get("number", 1),
			season_data.get("name", "Gölge Çağı")
		]
		
		var days_remaining = season_data.get("days_remaining", 0)
		time_label.text = "Kalan Süre: %d gün" % days_remaining

func _load_leaderboard() -> void:
	if is_loading:
		return
	
	is_loading = true
	_clear_leaderboard()
	
	var result = await Network.http_get("/v1/leaderboard/%s" % current_category)
	is_loading = false
	
	if result.success:
		leaderboard_data = result.data.get("rankings", [])
		var my_rank = result.data.get("my_rank", 0)
		
		my_rank_label.text = "#%d" % my_rank if my_rank > 0 else "Sıralama dışı"
		
		_populate_leaderboard()
		_update_rewards()
	else:
		_show_error("Sıralama yüklenemedi")

func _clear_leaderboard() -> void:
	for child in leaderboard_list.get_children():
		child.queue_free()

func _populate_leaderboard() -> void:
	for i in range(leaderboard_data.size()):
		var entry = leaderboard_data[i]
		var rank = i + 1
		
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(0, 80)
		
		# Top 3 special styling
		if rank <= 3:
			var style = StyleBoxFlat.new()
			match rank:
				1:
					style.bg_color = Color(1, 0.85, 0.3, 0.3)
				2:
					style.bg_color = Color(0.75, 0.75, 0.75, 0.3)
				3:
					style.bg_color = Color(0.8, 0.5, 0.2, 0.3)
			panel.add_theme_stylebox_override("panel", style)
		
		var hbox = HBoxContainer.new()
		panel.add_child(hbox)
		
		# Rank
		var rank_label = Label.new()
		rank_label.custom_minimum_size = Vector2(100, 0)
		rank_label.text = _get_rank_emoji(rank)
		rank_label.theme_override_font_sizes["font_size"] = 32
		rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hbox.add_child(rank_label)
		
		# Player name
		var name_label = Label.new()
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.text = entry.get("name", "Unknown")
		name_label.theme_override_font_sizes["font_size"] = 24
		hbox.add_child(name_label)
		
		# Score
		var score_label = Label.new()
		score_label.text = _format_score(entry)
		score_label.theme_override_font_sizes["font_size"] = 24
		score_label.theme_override_colors["font_color"] = Color(1, 0.85, 0.3, 1)
		hbox.add_child(score_label)
		
		leaderboard_list.add_child(panel)

func _get_rank_emoji(rank: int) -> String:
	match rank:
		1: return "🥇 #1"
		2: return "🥈 #2"
		3: return "🥉 #3"
		_: return "#%d" % rank

func _format_score(entry: Dictionary) -> String:
	match current_category:
		"wealth":
			return StringUtils.format_number(entry.get("gold", 0)) + " 💰"
		"pvp":
			return "%d zafer ⚔️" % entry.get("wins", 0)
		"quest":
			return "%d görev ✓" % entry.get("completed", 0)
		"economy":
			return StringUtils.format_number(entry.get("trades", 0)) + " işlem 📊"
		"guild":
			return "%d puan 🏰" % entry.get("points", 0)
		_:
			return str(entry.get("score", 0))

func _update_rewards() -> void:
	match current_category:
		"wealth":
			reward_text.text = """1. 🏆 5000 Gem + Efsanevi Unvan
2-3. 💎 2500 Gem + Epik Unvan
4-10. 💰 1000 Gem + Nadir Unvan
11-50. 💰 500 Gem
51-100. 💰 250 Gem"""
		
		"pvp":
			reward_text.text = """1. 🏆 4000 Gem + Savaşçı Unvanı
2-3. 💎 2000 Gem + Gladyatör
4-10. 💰 800 Gem + Şövalye
11-50. 💰 400 Gem
51-100. 💰 200 Gem"""
		
		"quest":
			reward_text.text = """1. 🏆 3000 Gem + Kahraman Unvanı
2-3. 💎 1500 Gem + Maceracı
4-10. 💰 600 Gem + Görevli
11-50. 💰 300 Gem
51-100. 💰 150 Gem"""
		
		"economy":
			reward_text.text = """1. 🏆 4000 Gem + Tüccar Prensi
2-3. 💎 2000 Gem + Zengin Tüccar
4-10. 💰 800 Gem + Usta Tüccar
11-50. 💰 400 Gem
51-100. 💰 200 Gem"""
		
		"guild":
			reward_text.text = """1. 🏆 10000 Gem (Lonca paylaşımlı)
2-3. 💎 5000 Gem (Lonca paylaşımlı)
4-10. 💰 2000 Gem (Lonca paylaşımlı)
11-20. 💰 1000 Gem (Lonca paylaşımlı)"""

func _on_back_button_pressed() -> void:
	get_tree().root.get_node("Main").go_back()

func _show_error(message: String) -> void:
	var dialog_scene = load("res://scenes/ui/dialogs/ErrorDialog.tscn")
	if dialog_scene:
		get_tree().root.get_node("Main").show_dialog(dialog_scene, {
			"title": "Hata",
			"message": message
		})
