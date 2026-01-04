extends Control
## Shop Screen
## Monetization - Gem packages, special offers, and Battle Pass

@onready var shop_tabs = $TabContainer
@onready var gems_panel = $TabContainer/Gems
@onready var offers_panel = $TabContainer/Offers
@onready var battle_pass_panel = $TabContainer/BattlePass

@onready var gem_packages_grid = $TabContainer/Gems/ScrollContainer/GridContainer
@onready var offers_list = $TabContainer/Offers/ScrollContainer/VBoxContainer
@onready var battle_pass_info = $TabContainer/BattlePass/PassInfo
@onready var battle_pass_rewards = $TabContainer/BattlePass/RewardsScroll/GridContainer

@onready var back_button = $BackButton

var _package_card_scene = preload("res://scenes/prefabs/GemPackageCard.tscn")
var _offer_card_scene = preload("res://scenes/prefabs/OfferCard.tscn")
var _reward_card_scene = preload("res://scenes/prefabs/RewardCard.tscn")

# Gem package definitions (prices in USD cents)
const GEM_PACKAGES = [
	{"id": "gems_100", "gems": 100, "price": 99, "bonus": 0},
	{"id": "gems_500", "gems": 500, "price": 499, "bonus": 50},
	{"id": "gems_1000", "gems": 1000, "price": 999, "bonus": 150},
	{"id": "gems_2500", "gems": 2500, "price": 1999, "bonus": 500},
	{"id": "gems_5000", "gems": 5000, "price": 4999, "bonus": 1200},
	{"id": "gems_10000", "gems": 10000, "price": 9999, "bonus": 3000},
]

func _ready() -> void:
	# Connect signals
	back_button.pressed.connect(_on_back_pressed)
	
	# Track screen
	Telemetry.track_screen("shop")
	
	# Load shop data
	_load_shop()

func _load_shop() -> void:
	# Populate gem packages
	_populate_gem_packages()
	
	# Load special offers from API
	var offers_result = await Network.http_get("/shop/offers")
	_on_offers_loaded(offers_result)
	
	# Load battle pass info
	var bp_result = await Network.http_get("/shop/battle_pass")
	_on_battle_pass_loaded(bp_result)

func _populate_gem_packages() -> void:
	# Clear grid
	for child in gem_packages_grid.get_children():
		child.queue_free()
	
	# Create package cards
	for package in GEM_PACKAGES:
		var card = _package_card_scene.instantiate()
		gem_packages_grid.add_child(card)
		card.set_package(package)
		card.purchase_clicked.connect(_on_package_purchase.bind(package))

func _on_offers_loaded(result: Dictionary) -> void:
	if not result.success:
		print("[Shop] Failed to load offers")
		return
	
	# Clear list
	for child in offers_list.get_children():
		child.queue_free()
	
	# Populate offers
	var offers = result.data.get("offers", [])
	for offer_dict in offers:
		var card = _offer_card_scene.instantiate()
		offers_list.add_child(card)
		card.set_offer(offer_dict)
		card.purchase_clicked.connect(_on_offer_purchase.bind(offer_dict))

func _on_battle_pass_loaded(result: Dictionary) -> void:
	if not result.success:
		print("[Shop] Failed to load battle pass")
		return
	
	var data = result.data
	
	# Show battle pass info
	var is_premium = data.get("is_premium", false)
	var current_tier = data.get("current_tier", 0)
	var max_tier = data.get("max_tier", 50)
	var season_end = data.get("season_end", "")
	
	battle_pass_info.text = ""
	if is_premium:
		battle_pass_info.text += "Premium Battle Pass Active ✓\n"
	else:
		battle_pass_info.text += "Free Battle Pass\n"
	
	battle_pass_info.text += "Tier: %d/%d\n" % [current_tier, max_tier]
	battle_pass_info.text += "Season ends: %s\n" % season_end
	
	# Show rewards
	_populate_battle_pass_rewards(data.get("rewards", []))

func _populate_battle_pass_rewards(rewards: Array) -> void:
	# Clear grid
	for child in battle_pass_rewards.get_children():
		child.queue_free()
	
	# Create reward cards
	for reward_dict in rewards:
		var card = _reward_card_scene.instantiate()
		battle_pass_rewards.add_child(card)
		card.set_reward(reward_dict)
		card.claim_clicked.connect(_on_reward_claim.bind(reward_dict))

func _on_package_purchase(package: Dictionary) -> void:
	var package_id = package.get("id", "")
	var price = package.get("price", 0)
	
	# Track purchase initiation
	Telemetry.track_purchase_initiated(
		package_id,
		price
	)
	
	# TODO: Integrate with platform payment system (Google Play, App Store)
	# For now, simulate purchase
	_simulate_purchase(package)

func _simulate_purchase(package: Dictionary) -> void:
	var package_id = package.get("id", "")
	var price = package.get("price", 0)
	
	var body = {
		"package_id": package_id,
		"platform": "test",
		"transaction_id": "test_%d" % Time.get_ticks_msec()
	}
	
	var result = await Network.http_post("/shop/purchase", body)
	_on_purchase_completed(result, package_id, price)

func _on_purchase_completed(result: Dictionary, package_id: String, price: int) -> void:
	if result.success:
		print("[Shop] Purchase completed successfully")
		
		# Update gems
		State.gems = result.data.get("gems", State.gems)
		
		# Track completion
		Telemetry.track_purchase_completed(
			package_id,
			price,
			State.total_purchases == 1  # Was first purchase
		)
		
		# Show success message
		# TODO: Show confirmation popup
	else:
		print("[Shop] Purchase failed: ", result.get("error", ""))

func _on_offer_purchase(offer: Dictionary) -> void:
	var offer_id = offer.get("id", "")
	var price = offer.get("price", 0)
	
	# Track purchase
	Telemetry.track_purchase_initiated(offer_id, price)
	
	# Similar to package purchase
	var body = {
		"offer_id": offer_id,
		"platform": "test",
		"transaction_id": "test_%d" % Time.get_ticks_msec()
	}
	
	var result = await Network.http_post("/shop/purchase_offer", body)
	_on_purchase_completed(result, offer_id, price)

func _on_reward_claim(reward: Dictionary) -> void:
	var tier = reward.get("tier", 0)
	
	var body = {
		"tier": tier
	}
	
	var result = await Network.http_post("/shop/battle_pass/claim", body)
	_on_reward_claimed(result)

func _on_reward_claimed(result: Dictionary) -> void:
	if result.success:
		print("[Shop] Reward claimed")
		
		# Reload battle pass
		var bp_result = await Network.http_get("/shop/battle_pass")
		_on_battle_pass_loaded(bp_result)
	else:
		print("[Shop] Failed to claim reward: ", result.get("error", ""))

func _on_back_pressed() -> void:
	Scenes.change_scene("res://scenes/ui/MainMenu.tscn")
