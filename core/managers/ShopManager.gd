extends Node
## Shop Manager
## Handles monetization, gem packages, special offers, and IAP

signal purchase_initiated(product_id: String)
signal purchase_completed(product_id: String, receipt: Dictionary)
signal purchase_failed(product_id: String, error: String)
signal offers_updated(offers: Array)
signal gems_added(amount: int)

# Gem packages
const GEM_PACKAGES = {
	"gems_100": {
		"id": "gems_100",
		"name": "Starter Pack",
		"gems": 100,
		"bonus": 0,
		"price_usd": 0.99,
		"icon": "💎"
	},
	"gems_500": {
		"id": "gems_500",
		"name": "Bronze Pack",
		"gems": 500,
		"bonus": 50,
		"price_usd": 4.99,
		"icon": "💎"
	},
	"gems_1200": {
		"id": "gems_1200",
		"name": "Silver Pack",
		"gems": 1200,
		"bonus": 150,
		"price_usd": 9.99,
		"icon": "💎"
	},
	"gems_2500": {
		"id": "gems_2500",
		"name": "Gold Pack",
		"gems": 2500,
		"bonus": 400,
		"price_usd": 19.99,
		"icon": "💎"
	},
	"gems_6500": {
		"id": "gems_6500",
		"name": "Diamond Pack",
		"gems": 6500,
		"bonus": 1300,
		"price_usd": 49.99,
		"icon": "💎"
	},
	"gems_14000": {
		"id": "gems_14000",
		"name": "Legendary Pack",
		"gems": 14000,
		"bonus": 3500,
		"price_usd": 99.99,
		"icon": "💎"
	}
}

# Special offers
var active_offers: Array = []
var purchased_offers: Array = []

# IAP provider (would be platform-specific in production)
var iap_provider = Object.new()

func _ready() -> void:
	# Connect to state updates
	State.connect("player_updated", _on_player_updated)
	
	# Load offers
	load_active_offers()
	
	# Initialize IAP (platform-specific)
	_initialize_iap()

func _initialize_iap() -> void:
	"""Initialize in-app purchase system"""
	# In production, this would initialize platform-specific IAP
	# For now, we'll use backend validation only
	print("[ShopManager] IAP system initialized")

func load_active_offers() -> void:
	"""Load currently active special offers"""
	var response = await Network.http_get("/shop/offers")
	
	if response.success:
		active_offers = response.data.get("offers", [])
		offers_updated.emit(active_offers)

func get_gem_packages() -> Array:
	"""Get all gem packages"""
	var packages = []
	
	for package_id in GEM_PACKAGES:
		var package = GEM_PACKAGES[package_id].duplicate()
		package["total_gems"] = package.gems + package.bonus
		packages.append(package)
	
	return packages

func get_active_offers() -> Array:
	"""Get active special offers"""
	# Filter expired offers
	var current_time = Time.get_unix_time_from_system()
	
	return active_offers.filter(func(offer):
		var expires_at = offer.get("expires_at", 0)
		return expires_at > current_time and offer.get("id") not in purchased_offers
	)

func purchase_gems_package(package_id: String) -> Dictionary:
	"""Purchase a gem package"""
	if not GEM_PACKAGES.has(package_id):
		return {"success": false, "error": "Invalid package"}
	
	var package = GEM_PACKAGES[package_id]
	
	# Initiate purchase
	purchase_initiated.emit(package_id)
	
	# In production, this would trigger platform IAP flow
	# For now, simulate or use backend testing
	var receipt = await _process_iap_purchase(package_id, package.price_usd)
	
	if receipt.success:
		# Validate receipt with backend
		var validation = await _validate_purchase(package_id, receipt.data)
		
		if validation.success:
			var gems_earned = package.gems + package.bonus
			State.add_gems(gems_earned)
			
			gems_added.emit(gems_earned)
			purchase_completed.emit(package_id, receipt.data)
			
			return {"success": true, "gems": gems_earned}
		else:
			purchase_failed.emit(package_id, "Validation failed")
			return {"success": false, "error": "Purchase validation failed"}
	else:
		purchase_failed.emit(package_id, receipt.error)
		return receipt

func purchase_offer(offer_id: String) -> Dictionary:
	"""Purchase a special offer"""
	# Find offer
	var offer = {}
	for o in active_offers:
		if o.get("id") == offer_id:
			offer = o
			break
	
	if not offer:
		return {"success": false, "error": "Offer not found"}
	
	# Check if already purchased
	if offer_id in purchased_offers:
		return {"success": false, "error": "Offer already purchased"}
	
	# Check expiry
	var expires_at = offer.get("expires_at", 0)
	if expires_at <= Time.get_unix_time_from_system():
		return {"success": false, "error": "Offer expired"}
	
	# Initiate purchase
	purchase_initiated.emit(offer_id)
	
	# Process payment
	var price = offer.get("price_usd", 0)
	var receipt = await _process_iap_purchase(offer_id, price)
	
	if receipt.success:
		# Validate with backend
		var validation = await _validate_purchase(offer_id, receipt.data)
		
		if validation.success:
			# Add offer rewards
			_process_offer_rewards(offer)
			
			# Mark as purchased
			purchased_offers.append(offer_id)
			
			purchase_completed.emit(offer_id, receipt.data)
			return {"success": true}
		else:
			purchase_failed.emit(offer_id, "Validation failed")
			return {"success": false, "error": "Purchase validation failed"}
	else:
		purchase_failed.emit(offer_id, receipt.error)
		return receipt

func purchase_with_gems(item_id: String, gem_cost: int) -> Dictionary:
	"""Purchase an item using gems"""
	# Check gem balance
	if State.get_gems() < gem_cost:
		return {"success": false, "error": "Not enough gems"}
	
	# Send to backend
	var response = await Network.http_post("/shop/purchase_with_gems", {
		"item_id": item_id,
		"gem_cost": gem_cost
	})
	
	if response.success:
		# Deduct gems
		State.add_gems(-gem_cost)
		
		# Add item to inventory
		var item = response.data.get("item", {})
		State.add_to_inventory(item.get("id", ""), item.get("quantity", 1))
	
	return response

func restore_purchases() -> Dictionary:
	"""Restore previous purchases (iOS requirement)"""
	var response = await Network.http_post("/shop/restore_purchases", {})
	
	if response.success:
		var restored = response.data.get("purchases", [])
		
		# Process restored purchases
		for purchase in restored:
			var package_id = purchase.get("product_id", "")
			if GEM_PACKAGES.has(package_id):
				var gems = purchase.get("gems_granted", 0)
				State.add_gems(gems)
		
		return {"success": true, "restored_count": restored.size()}
	
	return response

func get_purchase_history() -> Array:
	"""Get player's purchase history"""
	var response = await Network.http_get("/shop/purchase_history")
	
	if response.success:
		return response.data.get("purchases", [])
	
	return []

func get_total_spent() -> Dictionary:
	"""Get total amount spent by player"""
	var response = await Network.http_get("/shop/spending_stats")
	
	if response.success:
		return response.data.get("stats", {})
	
	return {"total_usd": 0, "total_gems": 0, "purchase_count": 0}

func _process_iap_purchase(product_id: String, price: float) -> Dictionary:
	"""Process in-app purchase (platform-specific)"""
	# In production, this would trigger:
	# - Google Play Billing (Android)
	# - StoreKit (iOS)
	# - Steam (Steam)
	
	# For development/testing, simulate success
	await get_tree().create_timer(1.0).timeout
	
	return {
		"success": true,
		"data": {
			"product_id": product_id,
			"transaction_id": _generate_transaction_id(),
			"receipt": _generate_mock_receipt(product_id, price),
			"timestamp": Time.get_unix_time_from_system()
		}
	}

func _validate_purchase(product_id: String, receipt: Dictionary) -> Dictionary:
	"""Validate purchase receipt with backend"""
	var response = await Network.http_post("/shop/validate_purchase", {
		"product_id": product_id,
		"receipt": receipt
	})
	
	return response

func _process_offer_rewards(offer: Dictionary) -> void:
	"""Process rewards from special offer"""
	var rewards = offer.get("rewards", [])
	
	for reward in rewards:
		var reward_type = reward.get("type", "")
		var amount = reward.get("amount", 0)
		
		match reward_type:
			"gems":
				State.add_gems(amount)
			"gold":
				State.add_gold(amount)
			"item":
				State.add_to_inventory(reward.get("item_id", ""), amount)
			"xp":
				State.add_xp(amount)

func _generate_transaction_id() -> String:
	"""Generate unique transaction ID"""
	return "TXN_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

func _generate_mock_receipt(product_id: String, price: float) -> String:
	"""Generate mock receipt for testing"""
	var receipt_data = {
		"product_id": product_id,
		"price": price,
		"currency": "USD",
		"timestamp": Time.get_unix_time_from_system()
	}
	
	return JSON.stringify(receipt_data)

func _on_player_updated() -> void:
	"""Handle player data updates"""
	# Update purchased offers
	if State.player.has("purchased_offers"):
		purchased_offers = State.player.purchased_offers

## Purchase gems directly (for testing)
func purchase_gems(amount: int) -> Dictionary:
	if not Network:
		push_error("[ShopManager] Network not available")
		return {"success": false, "error": "Network not available"}
	
	var endpoint = "/rest/v1/users?id=eq.%s" % Session.player_id
	var update_data = {
		"gems": State.gems + amount
	}
	
	var result = await Network.http_patch(endpoint, update_data)
	
	if result and result.success:
		# Update State
		State.update_player_data({"gems": State.gems + amount})
		gems_added.emit(amount)
		print("[ShopManager] Purchased %d gems successfully" % amount)
		return {"success": true, "gems": State.gems}
	else:
		var error_msg = result.get("error", "Unknown error") if result else "Network error"
		push_error("[ShopManager] Failed to purchase gems: %s" % error_msg)
		return {"success": false, "error": error_msg}
