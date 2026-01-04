extends Control
## Season Screen
## Leaderboards and Battle Pass progress

@onready var tabs = $TabContainer
@onready var leaderboard_list = $TabContainer/Leaderboards/ScrollContainer/VBoxContainer
@onready var battle_pass_panel = $TabContainer/BattlePass

# Leaderboard category buttons
@onready var level_button = $TabContainer/Leaderboards/Categories/LevelButton
@onready var power_button = $TabContainer/Leaderboards/Categories/PowerButton
@onready var pvp_button = $TabContainer/Leaderboards/Categories/PvPButton
@onready var gold_button = $TabContainer/Leaderboards/Categories/GoldButton
@onready var guild_button = $TabContainer/Leaderboards/Categories/GuildButton

@onready var my_rank_label = $TabContainer/Leaderboards/MyRank
@onready var season_end_label = $TopPanel/SeasonEnd

@onready var back_button = $BackButton

var _current_category: String = "level"
var _leaderboard_row_scene = preload("res://scenes/prefabs/LeaderboardRow.tscn")

func _ready() -> void:
	# Connect signals
	back_button.pressed.connect(_on_back_pressed)
	level_button.pressed.connect(func(): _set_category("level"))
	power_button.pressed.connect(func(): _set_category("power"))
	pvp_button.pressed.connect(func(): _set_category("pvp_rating"))
	gold_button.pressed.connect(func(): _set_category("gold"))
	guild_button.pressed.connect(func(): _set_category("guild_power"))
	
	# Track screen
	Telemetry.track_screen("season")
	
	# Load leaderboards
	_load_leaderboard()
	
	# Load season info
	_load_season_info()

func _load_season_info() -> void:
	var result = await Network.http_get("/season/info")
	_on_season_info_loaded(result)

func _on_season_info_loaded(result: Dictionary) -> void:
	if not result.success:
		print("[Season] Failed to load season info")
		return
	
	var data = result.data
	var season_end = data.get("season_end", "")
	
	season_end_label.text = "Season ends: %s" % season_end

func _set_category(category: String) -> void:
	_current_category = category
	_load_leaderboard()
	
	# Update button states
	level_button.button_pressed = (category == "level")
	power_button.button_pressed = (category == "power")
	pvp_button.button_pressed = (category == "pvp_rating")
	gold_button.button_pressed = (category == "gold")
	guild_button.button_pressed = (category == "guild_power")

func _load_leaderboard() -> void:
	var result = await Network.http_get("/season/leaderboard?category=" + _current_category)
	_on_leaderboard_loaded(result)

func _on_leaderboard_loaded(result: Dictionary) -> void:
	if not result.success:
		print("[Season] Failed to load leaderboard")
		return
	
	var data = result.data
	
	# Clear list
	for child in leaderboard_list.get_children():
		child.queue_free()
	
	# Populate leaderboard (top 100)
	var entries = data.get("entries", [])
	for entry in entries:
		var row = _leaderboard_row_scene.instantiate()
		leaderboard_list.add_child(row)
		row.set_entry(entry, _current_category)
	
	# Show my rank
	var my_rank = data.get("my_rank", -1)
	if my_rank > 0:
		my_rank_label.text = "Your Rank: #%d" % my_rank
	else:
		my_rank_label.text = "Your Rank: Unranked"

func _on_back_pressed() -> void:
	Scenes.change_scene("res://scenes/ui/MainMenu.tscn")
