extends Control
## Season Screen
## Seasonal events, challenges, and rewards

@onready var season_title: Label = $MarginContainer/VBoxContainer/SeasonHeader/SeasonTitle
@onready var season_progress: ProgressBar = $MarginContainer/VBoxContainer/SeasonHeader/SeasonProgress
@onready var season_description: Label = $MarginContainer/VBoxContainer/SeasonHeader/SeasonDescription
@onready var challenges_container: VBoxContainer = $MarginContainer/VBoxContainer/ChallengesSection/VBoxContainer
@onready var rewards_container: GridContainer = $MarginContainer/VBoxContainer/RewardsSection/VBoxContainer/RewardsGrid
@onready var back_button: Button = $BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)

	# Load season data
	_load_season_data()

func _load_season_data() -> void:
	# TODO: Load from API or config
	var season_data = {
		"name": "Winter Wonderland 2026",
		"description": "Kış mevsimi etkinlikleri ve ödülleri",
		"progress": 0.65,
		"challenges": [
			{"name": "Zindan Avcısı", "description": "10 zindan tamamla", "progress": 7, "max": 10, "reward": "500 XP"},
			{"name": "Pazar Ustası", "description": "100 altın kazan", "progress": 75, "max": 100, "reward": "Sezon Rozeti"},
			{"name": "Lonca Savaşçısı", "description": "5 lonca savaşı kazan", "progress": 2, "max": 5, "reward": "Özel Başlık"}
		],
		"rewards": [
			{"name": "Kış Pelerini", "icon": "winter_cape", "claimed": false},
			{"name": "Kar Tanrısı Rozeti", "icon": "snow_god_badge", "claimed": true},
			{"name": "Buz Mavisi Silah", "icon": "ice_weapon", "claimed": false}
		]
	}

	_update_season_display(season_data)

func _update_season_display(data: Dictionary) -> void:
	season_title.text = data.name
	season_description.text = data.description
	season_progress.value = data.progress * 100
	season_progress.get_node("ProgressLabel").text = "%.0f%%" % (data.progress * 100)

	# Clear existing challenges
	for child in challenges_container.get_children():
		child.queue_free()

	# Add challenges
	for challenge in data.challenges:
		var challenge_panel = PanelContainer.new()
		challenge_panel.custom_minimum_size = Vector2(0, 80)

		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)

		var info_vbox = VBoxContainer.new()

		var name_label = Label.new()
		name_label.text = challenge.name
		name_label.add_theme_font_size_override("font_size", 16)
		info_vbox.add_child(name_label)

		var desc_label = Label.new()
		desc_label.text = challenge.description
		desc_label.add_theme_color_override("font_color", Color.GRAY)
		info_vbox.add_child(desc_label)

		var reward_label = Label.new()
		reward_label.text = "Ödül: " + challenge.reward
		reward_label.add_theme_color_override("font_color", Color.GOLD)
		info_vbox.add_child(reward_label)

		hbox.add_child(info_vbox)

		var progress_vbox = VBoxContainer.new()
		progress_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var progress_bar = ProgressBar.new()
		progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		progress_bar.min_value = 0
		progress_bar.max_value = challenge.max
		progress_bar.value = challenge.progress
		progress_vbox.add_child(progress_bar)

		var progress_label = Label.new()
		progress_label.text = "%d/%d" % [challenge.progress, challenge.max]
		progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		progress_vbox.add_child(progress_label)

		hbox.add_child(progress_vbox)

		challenge_panel.add_child(hbox)
		challenges_container.add_child(challenge_panel)

	# Clear existing rewards
	for child in rewards_container.get_children():
		child.queue_free()

	# Add rewards
	for reward in data.rewards:
		var reward_button = Button.new()
		reward_button.custom_minimum_size = Vector2(120, 120)
		reward_button.text = reward.name
		reward_button.disabled = reward.claimed

		if reward.claimed:
			reward_button.text += "\n(Alındı)"
			reward_button.add_theme_color_override("font_color", Color.GRAY)

		reward_button.pressed.connect(_on_reward_claimed.bind(reward))
		rewards_container.add_child(reward_button)

func _on_reward_claimed(reward: Dictionary) -> void:
	print("[Season] Claiming reward: ", reward.name)
	# TODO: Claim reward from server

func _on_back_pressed() -> void:
	get_tree().root.get_node("Main").show_screen("home")

## Setup called by Main.show_screen to pass data into the screen before it's added to tree
func setup(data: Dictionary = {}) -> void:
	pass
