extends Node

# Signals
signal facilities_updated
signal production_started
signal production_collected(result)
signal bribe_completed(new_suspicion)

# Cache
var my_facilities: Array = []
var active_recipes: Dictionary = {} # facility_type -> [recipes]

# UI Selection State
var selected_facility_type: String = ""
var selected_facility_data = null

const API_RPC = "/rest/v1/rpc/"

# 1. Fetch My Facilities
# Returns dictionary {success: bool, data: Array}
func fetch_my_facilities() -> Dictionary:
	# 'facilities.user_id' references 'auth.users.id' (auth_id), NOT 'game.users.id'.
	var user_id = State.player.get("auth_id")
	if not user_id:
		# Fallback: try to get from State.user (Auth session)
		if State.user and State.user.id:
			user_id = State.user.id
		else:
			return {"success": false, "error": "No auth ID found"}
	
	# We query the facilities table directly
	var result = await Network.http_get("/rest/v1/facilities?user_id=eq." + str(user_id) + "&select=*,facility_queue(*)")
	
	if result.success:
		var data = result.data
		if typeof(data) == TYPE_DICTIONARY and data.has("data"): data = data.data
		
		my_facilities = data
		facilities_updated.emit()
		print("FacilityManager: Fetched ", my_facilities.size(), " facilities.")
		return {"success": true, "data": my_facilities}
	else:
		printerr("FacilityManager: Failed to fetch facilities: ", result.get("error"))
		return {"success": false, "error": result.get("error")}

# 2. Get Facility by Type (Helper)
func get_facility_by_type(type: String) -> Dictionary:
	for f in my_facilities:
		if f.type == type:
			return f
	return {}

# 3. Unlock Facility
func unlock_facility(type: String) -> Dictionary:
	var payload = { "p_type": type }
	var result = await Network.http_post(API_RPC + "unlock_facility", payload)
	
	if result.success:
		await fetch_my_facilities() # Refresh
		return {"success": true}
	
	return {"success": false, "error": result.get("error", "Unknown Error")}

# 4. Fetch Recipes
func fetch_recipes() -> Dictionary:
	# Get all recipes
	var result = await Network.http_get("/rest/v1/facility_recipes?select=*")
	if result.success:
		var data = result.data
		if typeof(data) == TYPE_DICTIONARY and data.has("data"): data = data.data
		
		# Organize by type
		active_recipes.clear()
		for r in data:
			var type = r.facility_type
			if not active_recipes.has(type): active_recipes[type] = []
			active_recipes[type].append(r)
			
		print("FacilityManager: Fetched recipes for ", active_recipes.size(), " types.")
		return {"success": true, "data": data}
	else:
		return {"success": false, "error": result.get("error")}

# 5. Start Production
func start_production(facility_id: String, recipe_id: String, quantity: int) -> Dictionary:
	var payload = {
		"p_facility_id": facility_id,
		"p_recipe_id": recipe_id,
		"p_quantity": quantity
	}
	
	print("[FacilityManager] Starting production: facility=", facility_id, " recipe=", recipe_id, " qty=", quantity)
	var result = await Network.http_post(API_RPC + "start_facility_production", payload)
	
	print("[FacilityManager] Start production result: ", result)
	
	if result.success:
		# Parse nested data (some RPCs return success: false in the payload)
		var data = result.data
		if typeof(data) == TYPE_DICTIONARY and data.has("data"):
			data = data.data

		# If payload is a stringified JSON, parse it
		if typeof(data) == TYPE_STRING:
			var j = JSON.new()
			if j.parse(data) == OK:
				data = j.data

		# Determine logical success
		var rpc_success = false
		var rpc_error = null
		if typeof(data) == TYPE_DICTIONARY:
			rpc_success = data.get("success", false) == true
			rpc_error = data.get("error", null)
		else:
			rpc_success = true # no inner object, assume ok

		if rpc_success:
			production_started.emit()
			print("[FacilityManager] Refreshing facilities to update queue...")
			await fetch_my_facilities() # Refresh queue
			print("[FacilityManager] Queue refreshed")
			return {"success": true, "data": data}
		else:
			print("[FacilityManager] Start production RPC reported failure: ", rpc_error)
			return {"success": false, "error": rpc_error if rpc_error != null else "Unknown RPC error"}

	print("[FacilityManager] Start production failed (network): ", result.get("error"))
	return {"success": false, "error": result.get("error")}

# 6. Collect Production
func collect_production(facility_id: String) -> Dictionary:
	var payload = { "p_facility_id": facility_id }
	
	print("[FacilityManager] Collecting production for facility: ", facility_id)
	var result = await Network.http_post(API_RPC + "collect_facility_production", payload)
	
	print("[FacilityManager] Collect result: ", result)
	
	if result.success:
		var data = result.data
		# Parse nested data if needed
		if typeof(data) == TYPE_STRING:
			var json = JSON.new()
			if json.parse(data) == OK: 
				data = json.data
				print("[FacilityManager] Parsed JSON data: ", data)
		
		print("[FacilityManager] Data type: ", typeof(data), " value: ", data)
		
		# Check various success patterns
		var is_successful = false
		if data is Dictionary:
			is_successful = data.get("success", false) == true or result.success
		else:
			is_successful = result.success
		
		if is_successful:
			print("[FacilityManager] Production collected successfully!")
			production_collected.emit(data if data is Dictionary else {})
			
			# Refresh facilities
			await fetch_my_facilities()
			
			# CRITICAL: Refresh inventory
			var inv = get_node_or_null("/root/Inventory")
			if not inv: 
				inv = get_node_or_null("/root/InventoryManager")
			
			if inv: 
				print("[FacilityManager] Triggering inventory refresh...")
				await inv.fetch_inventory()
				print("[FacilityManager] Inventory refresh completed")
			else:
				printerr("[FacilityManager] Could not find Inventory autoload!")
			
			# Refresh user state for gold/prison
			await State.refresh_data()
			print("[FacilityManager] State refresh completed")
			
			return {"success": true, "data": data}
		else:
			var error = data.get("error", "Unknown error") if data is Dictionary else "Invalid response"
			print("[FacilityManager] Collection failed: ", error)
			return {"success": false, "error": error}
	
	print("[FacilityManager] Network request failed: ", result.get("error"))
	return {"success": false, "error": result.get("error")}

# 7. Bribe
func bribe(facility_id: String, amount_gems: int) -> Dictionary:
	var payload = {
		"p_facility_id": facility_id,
		"p_amount_gems": amount_gems
	}
	
	var result = await Network.http_post(API_RPC + "bribe_officials", payload)
	
	if result.success:
		var data = result.data
		if typeof(data) == TYPE_STRING:
			var json = JSON.new()
			if json.parse(data) == OK: data = json.data
			 
		if data.get("success"):
			bribe_completed.emit(data.get("new_suspicion"))
			await fetch_my_facilities()
			
			# Refresh Gems locally
			State.refresh_data()
			
			return {"success": true}
			
	return {"success": false, "error": result.get("error")}
