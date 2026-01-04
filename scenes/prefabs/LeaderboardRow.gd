extends PanelContainer
## Leaderboard Row

@onready var rank_label = $HBox/Rank
@onready var username_label = $HBox/Username
@onready var value_label = $HBox/Value
@onready var level_label = $HBox/Level

func set_entry(entry: Dictionary, category: String) -> void:
	rank_label.text = "#%d" % entry.get("rank", 0)
	username_label.text = entry.get("username", "Unknown")
	level_label.text = "Lv. %d" % entry.get("level", 1)
	
	# Show appropriate value based on category
	match category:
		"level":
			value_label.text = "Lv. %d" % entry.get("level", 1)
		"power":
			value_label.text = "%d Power" % entry.get("power", 0)
		"pvp_rating":
			value_label.text = "%d Rating" % entry.get("pvp_rating", 0)
		"gold":
			value_label.text = "%d Gold" % entry.get("gold", 0)
		"guild_power":
			value_label.text = "%d Power" % entry.get("guild_power", 0)
	
	# Highlight top 3
	var rank = entry.get("rank", 0)
	if rank == 1:
		modulate = Color.GOLD
	elif rank == 2:
		modulate = Color.SILVER
	elif rank == 3:
		modulate = Color(0.8, 0.5, 0.2)  # Bronze
