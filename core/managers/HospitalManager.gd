class_name HospitalManager
extends RefCounted
## Hospital System Manager
## Handles hospitalization, release methods, and status checking

signal hospital_admitted(reason: String, release_time: int)
signal hospital_released(method: String)

# Use Supabase RPC functions instead of HTTP endpoints
const RPC_GET_STATUS = "get_hospital_status"
const RPC_ADMIT = "admit_to_hospital"
const RPC_RELEASE = "release_from_hospital"

## Admission reasons
enum AdmissionReason {
	OVERDOSE,
	PVP_DEFEAT,
	QUEST_FAILURE
}

## Get hospital status from server via Supabase RPC (always fetch fresh data)
func fetch_hospital_status() -> Dictionary:
	if not State or not State.player.has("auth_id"):
		print("[HospitalManager] No auth_id available")
		return {"success": false, "error": "No auth_id available"}
	
	var auth_id = State.player.get("auth_id", "")
	if auth_id.is_empty():
		print("[HospitalManager] auth_id is empty")
		return {"success": false, "error": "auth_id is empty"}
	
	# Call Supabase RPC function with POST + JSON body
	var url = "/rest/v1/rpc/%s" % RPC_GET_STATUS
	var params = {"p_auth_id": auth_id}
	print("[HospitalManager] Calling RPC at: %s with params: %s" % [url, params])
	
	var result = await Network.http_post(url, params)
	
	print("[HospitalManager] Fetch hospital status - raw result: %s" % result)
	
	if result.success and result.code == 200:
		var data = result.data
		if data is Array and data.size() > 0:
			var row = data[0]
			var in_hospital = row.get("in_hospital", false)
			var release_time = row.get("release_time", 0)
			if release_time == null:
				release_time = 0
			release_time = release_time as int
			
			print("[HospitalManager] Hospital status: in_hospital=%s, release_time=%d" % [in_hospital, release_time])
			
			# Only update State if data actually changed - server is source of truth
			if in_hospital != State.in_hospital or release_time != State.hospital_release_time:
				State.set_hospital_status(in_hospital, release_time)
				if row.has("hospital_reason"):
					State.hospital_reason = row.get("hospital_reason", "")
			
			return {
				"success": true,
				"in_hospital": in_hospital,
				"release_time": release_time,
				"reason": row.get("hospital_reason", "")
			}
		else:
			print("[HospitalManager] Empty response from RPC")
			return {"success": false, "error": "Empty response from RPC"}
	
	print("[HospitalManager] Fetch failed: %s" % result)
	return {"success": false, "error": result.get("error", "Failed to fetch status")}

## Admit player to hospital (server-side via Supabase RPC)
func admit_player(duration_minutes: int, reason: String = "Zindan başarısızlığı") -> Dictionary:
	if not State or not State.player.has("auth_id"):
		return {"success": false, "error": "No auth_id available"}
	
	var auth_id = State.player.get("auth_id", "")
	
	# Call Supabase RPC function with POST + JSON body
	var url = "/rest/v1/rpc/%s" % RPC_ADMIT
	var params = {
		"p_auth_id": auth_id,
		"p_duration_minutes": duration_minutes,
		"p_reason": reason
	}
	var result = await Network.http_post(url, params)
	
	print("[HospitalManager] Admit result: %s" % result)
	
	if result.success and result.code == 200:
		var data = result.data
		if data is Array and data.size() > 0:
			var row = data[0]
			var release_time = row.get("release_time", 0)
			if release_time == null:
				release_time = 0
			release_time = release_time as int
			
			State.set_hospital_status(true, release_time)
			State.hospital_reason = reason
			hospital_admitted.emit(reason, release_time)
			
			Telemetry.track_event("hospital_admit", {
				"reason": reason,
				"duration_minutes": duration_minutes
			})
			
			return {"success": true, "release_time": release_time}
	
	print("[HospitalManager] Admit failed: %s" % result)
	return {"success": false, "error": result.get("error", "Failed to admit player")}

## Wait for natural release (timer expires)
func wait_for_release() -> Dictionary:
	if not State.in_hospital:
		return {"success": false, "error": "Not in hospital"}
	
	var remaining = State.get_hospital_remaining_minutes()
	
	if remaining > 0:
		return {
			"success": false,
			"error": "Release time not reached",
			"remaining_minutes": remaining
		}
	
	# Release player
	return await release_player("natural")

## Release with gems (instant) - always fetch fresh server status first
func release_with_gems() -> Dictionary:
	# Fetch fresh status from server to prevent time manipulation
	var status_result = await fetch_hospital_status()
	if not status_result.success or not status_result.in_hospital:
		return {"success": false, "error": "Not in hospital"}
	
	var remaining_seconds = State.get_hospital_remaining_seconds()
	var hours = int(remaining_seconds / 3600.0)
	var minutes = ceil(fmod(float(remaining_seconds), 3600.0) / 60.0)
	var gem_cost = hours + int(minutes)
	var remaining_minutes = State.get_hospital_remaining_minutes()
	
	# Check if player has enough gems before making request
	if State.gems < gem_cost:
		return {"success": false, "error": "Insufficient gems", "cost": gem_cost, "gems": State.gems}
	
	# Call RPC function to release
	if not State or not State.player.has("auth_id"):
		return {"success": false, "error": "No auth_id available"}
	
	var auth_id = State.player.get("auth_id", "")
	var url = "/rest/v1/rpc/%s" % RPC_RELEASE
	var params = {
		"p_auth_id": auth_id,
		"p_method": "gems",
		"p_cost": gem_cost
	}
	var result = await Network.http_post(url, params)
	
	if result.success and result.code == 200:
		var data = result.data
		if data is Array and data.size() > 0:
			var row = data[0]
			var success = row.get("success", false)
			
			if success:
				var new_gems = row.get("new_gems", State.gems - gem_cost)
				State.update_gems(new_gems, false)
				State.set_hospital_status(false, 0)
				hospital_released.emit("gems")
				if Audio:
					Audio.play_success()
				
				Telemetry.track_event("hospital_release", {
					"method": "gems",
					"cost": gem_cost,
					"remaining_minutes": remaining_minutes
				})
				
				return {"success": true, "method": "gems", "cost": gem_cost, "new_gems": new_gems}
	
	return {"success": false, "error": result.get("error", "Failed to release")}

## Release with guild help
func release_with_guild_help() -> Dictionary:
	# Fetch fresh status from server
	var status_result = await fetch_hospital_status()
	if not status_result.success or not status_result.in_hospital:
		return {"success": false, "error": "Not in hospital"}
	
	if State.guild_info.is_empty():
		return {"success": false, "error": "Not in a guild"}
	
	if not State or not State.player.has("auth_id"):
		return {"success": false, "error": "No auth_id available"}
	
	var auth_id = State.player.get("auth_id", "")
	var url = "/rest/v1/rpc/%s" % RPC_RELEASE
	var params = {
		"p_auth_id": auth_id,
		"p_method": "guild",
		"p_cost": 0
	}
	var result = await Network.http_post(url, params)
	
	if result.success and result.code == 200:
		var data = result.data
		if data is Array and data.size() > 0:
			var row = data[0]
			if row.get("success", false):
				State.set_hospital_status(false, 0)
				hospital_released.emit("guild")
				if Audio:
					Audio.play_success()
		
		Telemetry.track_event("hospital_release", {
			"method": "guild"
		})
		
		return {"success": true, "method": "guild"}
	
	return {"success": false, "error": result.get("error", "Guild help not available")}

## Release by completing special quest
func release_with_quest(quest_id: String) -> Dictionary:
	# Fetch fresh status from server
	var status_result = await fetch_hospital_status()
	if not status_result.success or not status_result.in_hospital:
		return {"success": false, "error": "Not in hospital"}
	
	if not State or not State.player.has("auth_id"):
		return {"success": false, "error": "No auth_id available"}
	
	var auth_id = State.player.get("auth_id", "")
	var url = "/rest/v1/rpc/%s" % RPC_RELEASE
	var params = {
		"p_auth_id": auth_id,
		"p_method": "quest",
		"p_cost": 0
	}
	var result = await Network.http_post(url, params)
	
	if result.success and result.code == 200:
		var data = result.data
		if data is Array and data.size() > 0:
			var row = data[0]
			if row.get("success", false):
				State.set_hospital_status(false, 0)
				hospital_released.emit("quest")
				if Audio:
					Audio.play_success()
				
				Telemetry.track_event("hospital_release", {
					"method": "quest",
					"quest_id": quest_id
				})
				
				return {"success": true, "method": "quest"}
	
	return {"success": false, "error": result.get("error", "Quest release failed")}

## Generic release function
func release_player(method: String) -> Dictionary:
	# Fetch fresh status from server
	var status_result = await fetch_hospital_status()
	if not status_result.success or not status_result.in_hospital:
		return {"success": false, "error": "Not in hospital"}
	
	if not State or not State.player.has("auth_id"):
		return {"success": false, "error": "No auth_id available"}
	
	var auth_id = State.player.get("auth_id", "")
	var url = "/rest/v1/rpc/%s" % RPC_RELEASE
	var params = {
		"p_auth_id": auth_id,
		"p_method": method,
		"p_cost": 0
	}
	var result = await Network.http_post(url, params)
	
	if result.success and result.code == 200:
		var data = result.data
		if data is Array and data.size() > 0:
			var row = data[0]
			if row.get("success", false):
				State.set_hospital_status(false, 0)
				hospital_released.emit(method)
				return {"success": true, "method": method}
	
	return {"success": false, "error": result.get("error", "Release failed")}

## Get hospital duration from admission reason
func get_duration_for_reason(reason: AdmissionReason, severity: int = 1) -> int:
	var base_duration = Config.get_potion_config().get("hospital_base_duration", 60)  # minutes
	
	match reason:
		AdmissionReason.OVERDOSE:
			return base_duration * severity  # 60-180 minutes
		AdmissionReason.PVP_DEFEAT:
			return int(base_duration * 0.5 * severity)  # 30-90 minutes
		AdmissionReason.QUEST_FAILURE:
			return int(base_duration * 0.3 * severity)  # 20-60 minutes
		_:
			return base_duration

## Get admission reason text
func get_reason_text(reason: String) -> String:
	match reason:
		"overdose":
			return "Potion Overdose"
		"pvp_defeat":
			return "Severe Combat Wounds"
		"quest_failure":
			return "Quest-Related Injuries"
		_:
			return "Medical Emergency"

## Get release method description
func get_release_method_description(method: String) -> String:
	match method:
		"natural":
			return "Wait for recovery"
		"gems":
			return "Instant release with gems"
		"guild":
			return "Guild member assistance"
		"quest":
			return "Complete special quest"
		_:
			return "Unknown method"

## Calculate gem cost for instant release
func calculate_gem_cost() -> int:
	var remaining_seconds = State.get_hospital_remaining_seconds()
	var hours = int(remaining_seconds / 3600.0)
	var minutes = ceil(fmod(float(remaining_seconds), 3600.0) / 60.0)
	return hours + int(minutes)

## Get formatted time remaining
func get_release_time_formatted() -> String:
	var minutes = State.get_hospital_remaining_minutes()
	
	if minutes >= 60:
		var hours = int(minutes / 60)
		var mins = minutes % 60
		return "%dh %dm" % [hours, mins]
	else:
		return "%dm" % minutes

## Check if player is hospitalized
func is_hospitalized() -> bool:
	return State.in_hospital
