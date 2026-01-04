extends PanelContainer
## Battle Pass Reward Card

signal claim_clicked(reward)

@onready var tier_label = $VBox/TierLabel
@onready var reward_icon = $VBox/RewardIcon
@onready var reward_name = $VBox/RewardName
@onready var claim_button = $VBox/ClaimButton
@onready var locked_label = $VBox/LockedLabel

var _reward: Dictionary

func _ready() -> void:
	claim_button.pressed.connect(_on_claim_pressed)

func set_reward(reward: Dictionary) -> void:
	_reward = reward
	
	tier_label.text = "Tier %d" % reward.get("tier", 0)
	reward_name.text = reward.get("name", "Reward")
	
	var is_claimed = reward.get("is_claimed", false)
	var is_unlocked = reward.get("is_unlocked", false)
	var is_premium = reward.get("is_premium", false)
	
	if is_claimed:
		claim_button.visible = false
		locked_label.visible = true
		locked_label.text = "Claimed"
		modulate = Color(0.7, 0.7, 0.7)
	elif is_unlocked:
		claim_button.visible = true
		locked_label.visible = false
	else:
		claim_button.visible = false
		locked_label.visible = true
		if is_premium:
			locked_label.text = "Premium Only"
		else:
			locked_label.text = "Locked"

func _on_claim_pressed() -> void:
	claim_clicked.emit(_reward)
