extends Control
## Shop Screen
## Monetization - Gem packages, special offers, and Battle Pass

# Import required classes
const InventoryManager = preload("res://autoload/InventoryManager.gd")
const ItemDatabase = preload("res://core/data/ItemDatabase.gd")

@onready var shop_tabs = $TabContainer
@onready var gems_panel = $TabContainer/Gems
@onready var offers_panel = $TabContainer/Offers
@onready var battle_pass_panel = $TabContainer/BattlePass
@onready var items_panel = $TabContainer/Items

@onready var gem_packages_grid = $TabContainer/Gems/ScrollContainer/Content/GemGrid
@onready var gold_packages_grid = $TabContainer/Gems/ScrollContainer/Content/GoldGrid
@onready var offers_list = $TabContainer/Offers/ScrollContainer/VBoxContainer
@onready var battle_pass_info = $TabContainer/BattlePass/PassInfo
@onready var battle_pass_rewards = $TabContainer/BattlePass/RewardsScroll/GridContainer
@onready var items_grid = $TabContainer/Items/ScrollContainer/GridContainer

@onready var back_button = $BackButton

var _package_card_scene = preload("res://scenes/prefabs/GemPackageCard.tscn")
var _offer_card_scene = preload("res://scenes/prefabs/OfferCard.tscn")
var _reward_card_scene = preload("res://scenes/prefabs/RewardCard.tscn")
var _item_card_scene = preload("res://scenes/ui/components/ItemCard.tscn")

var inventory_manager: InventoryManager

# Gem packages (prices in Gold)
const GEM_PACKAGES = [
	{"id": "gems_100", "gems": 100, "price": 1000, "bonus": 0},
	{"id": "gems_500", "gems": 500, "price": 4500, "bonus": 50},
	{"id": "gems_1000", "gems": 1000, "price": 9000, "bonus": 150},
	{"id": "gems_2500", "gems": 2500, "price": 22000, "bonus": 500},
	{"id": "gems_5000", "gems": 5000, "price": 42000, "bonus": 1200},
	{"id": "gems_10000", "gems": 10000, "price": 80000, "bonus": 3000},
]

# Gold packages (prices in Gems)
const GOLD_PACKAGES = [
	{"id": "gold_1000", "gold": 1000, "price": 10, "bonus": 0},
	{"id": "gold_5000", "gold": 5000, "price": 45, "bonus": 500},
	{"id": "gold_10000", "gold": 10000, "price": 85, "bonus": 1500},
	{"id": "gold_50000", "gold": 50000, "price": 400, "bonus": 10000},
	{"id": "gold_100000", "gold": 100000, "price": 750, "bonus": 25000},
]

func _ready() -> void:
	# Initialize managers
	inventory_manager = InventoryManager.new()
	
	# Connect signals
	back_button.pressed.connect(_on_back_pressed)
	
	# Track screen
	Telemetry.track_screen("shop")
	
	print("[Shop] ShopScreen ready, loading shop data...")
	
	# Load shop data
	_load_shop()

func _load_shop() -> void:
	# Populate gem packages
	_populate_gem_packages()
	_populate_gold_packages()
	
	# Populate shop items
	_populate_shop_items()
	
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
	
	print("[Shop] Populating gem packages, count: ", GEM_PACKAGES.size())
	
	# Create package cards
	for package in GEM_PACKAGES:
		var card = _package_card_scene.instantiate()
		gem_packages_grid.add_child(card)
		card.set_package(package)
		card.purchase_clicked.connect(_on_package_purchase)
	
	print("[Shop] Gem packages grid children: ", gem_packages_grid.get_child_count())

func _populate_gold_packages() -> void:
	# Clear grid
	for child in gold_packages_grid.get_children():
		child.queue_free()
	
	# Create package cards
	for package in GOLD_PACKAGES:
		var card = _package_card_scene.instantiate()
		gold_packages_grid.add_child(card)
		card.set_package(package)
		card.purchase_clicked.connect(_on_gold_purchase)


func _populate_shop_items() -> void:
	# Clear grid
	for child in items_grid.get_children():
		child.queue_free()
	
	# Get all items from database
	var all_items = ItemDatabase.get_all_items()
	print("[Shop] Populating shop items, count: ", all_items.size())
	
	# Create item cards
	for item_data in all_items:
		print("[Shop] Adding item: ", item_data.name)
		var card = _item_card_scene.instantiate()
		items_grid.add_child(card)
		card.setup(item_data, true)  # shop_mode = true
		# Connect purchase signal
		if card.has_signal("item_selected"):
			card.item_selected.connect(_on_item_purchase)
	
	print("[Shop] Items grid children: ", items_grid.get_child_count())

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
	var gems_amount = package.get("gems", 0)
	var bonus = package.get("bonus", 0)
	var total_gems = gems_amount + bonus
	
	# Track purchase initiation
	Telemetry.track_purchase_initiated(package_id, price)
	
	print("[Shop] Purchasing gem package: %s for %d Gold" % [package_id, price])
	
	if State.gold < price:
		print("[Shop] Yetersiz altın! Gerekli: %d, Mewcut: %d" % [price, State.gold])
		# TODO: Show error message
		return

	# Optimistic update
	var old_gold = State.gold
	var old_gems = State.gems
	
	State.gold -= price
	State.gems += total_gems
	State.player.gold = State.gold
	State.player.gems = State.gems
	
	# Persist to Supabase
	var user_id = State.player.get("id")
	if not user_id:
		print("[Shop] Error: User ID missing")
		return
		
	var patch_body = {
		"gold": State.gold,
		"gems": State.gems
	}
	
	# We use http_patch to await the result
	var result = await Network.http_patch("/rest/v1/users?id=eq." + user_id, patch_body)
	
	if result.success:
		print("[Shop] Purchase synced with server. Gems added: ", total_gems)
		Telemetry.track_purchase_completed(package_id, price, false)
		
		# Update UI globally
		State.player_updated.emit()
	else:
		print("[Shop] Failed to sync purchase! Reverting...")
		State.gold = old_gold
		State.gems = old_gems
		State.player.gold = old_gold
		State.player.gems = old_gems
		print("[Shop] Error: ", result.get("error"))

# Deprecated/Removed simulation methods
# func _simulate_purchase...
# func _on_purchase_completed...

func _on_offer_purchase(offer: Dictionary) -> void:
	var offer_id = offer.get("id", "")
	var price = offer.get("price", 0)
	
	# Track purchase
	Telemetry.track_purchase_initiated(offer_id, price)
	
	print("[Shop] Offer purchase not fully implemented for Gold system yet.")
	# TODO: Implement Gold purchase for Offers similar to Gem Packages

	# Formerly:
	# var body = {
	# 	"offer_id": offer_id,
	# 	"platform": "test",
	# 	"transaction_id": "test_%d" % Time.get_ticks_msec()
	# }
	# var result = await Network.http_post("/shop/purchase_offer", body)
	# _on_purchase_completed(result, offer_id, price)

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

func _on_gold_purchase(package: Dictionary) -> void:
	var package_id = package.get("id", "")
	var price_gems = package.get("price", 0)
	var gold_amount = package.get("gold", 0)
	var bonus = package.get("bonus", 0)
	var total_gold = gold_amount + bonus
	
	print("[Shop] Purchasing gold package: %s for %d Gems" % [package_id, price_gems])
	
	if State.gems < price_gems:
		print("[Shop] Yetersiz elmas! Gerekli: %d, Mevcut: %d" % [price_gems, State.gems])
		return

	# Optimistic update
	var old_gold = State.gold
	var old_gems = State.gems
	
	State.gold += total_gold
	State.gems -= price_gems
	State.player.gold = State.gold
	State.player.gems = State.gems
	
	# Persist to Supabase
	var user_id = State.player.get("id")
	if not user_id: return
		
	var patch_body = {
		"gold": State.gold,
		"gems": State.gems
	}
	
	var result = await Network.http_patch("/rest/v1/users?id=eq." + user_id, patch_body)
	
	if result.success:
		print("[Shop] Gold purchase synced. Gold added: ", total_gold)
		State.player_updated.emit()
	else:
		print("[Shop] Failed to sync gold purchase! Reverting...")
		State.gold = old_gold
		State.gems = old_gems
		State.player.gold = old_gold
		State.player.gems = old_gems
		State.player_updated.emit() # Revert UI

func _on_item_purchase(item_data: ItemData) -> void:
	var item_id = item_data.item_id
	var price = item_data.base_price
	
	print("[Shop] Purchasing item: %s for %d Gold" % [item_data.name, price])

	# Check if player has enough gold
	if State.gold < price:
		print("[Shop] Not enough gold for item: ", item_id)
		# TODO: Show error message
		return
	
	# Optimistic update
	var old_gold = State.gold
	State.gold -= price
	State.player.gold = State.gold
	
	# 1. Update Gold on Server
	var user_id = State.player.get("id")
	if user_id:
		var result = await Network.http_patch("/rest/v1/users?id=eq." + user_id, {"gold": State.gold})
		if not result.success:
			print("[Shop] Failed to sync gold reduction. Reverting.")
			State.gold = old_gold
			State.player.gold = old_gold
			return
	
	# 2. Add item to inventory
	var inventory_result = await inventory_manager.add_item_by_id(item_id, 1)
	if inventory_result.success:
		print("[Shop] Item added to inventory successfully")
		
		# Track purchase
		Telemetry.track_event("shop", "item_purchased", {
			"item_id": item_id,
			"price": price
		})
		
		# Update UI globally
		State.player_updated.emit()
		
		# TODO: Show success message
	else:
		print("[Shop] Failed to add item to inventory: ", inventory_result.error)
		# Refund gold if item add failed (though gold sync already happened, so we try to revert it)
		State.gold += price
		State.player.gold = State.gold
		if user_id:
			await Network.http_patch("/rest/v1/users?id=eq." + user_id, {"gold": State.gold})

func _on_back_pressed() -> void:
	Scenes.change_scene("res://scenes/ui/MainMenu.tscn")
