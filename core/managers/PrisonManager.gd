extends Node

## Prison Manager
## Handles prison-related RPC calls and logic.

signal prison_released(success: bool, message: String)

func _ready() -> void:
	print("[PrisonManager] Initialized")

## Request release from prison via Bail (Gems)
func pay_bail() -> void:
	if not Network:
		print("[PrisonManager] Network not available")
		return
		
	print("[PrisonManager] Requesting Bail Payment...")
	
	# RPC: release_from_prison(p_use_bail: bool)
	var response = await Network.rpc_post("release_from_prison", {
		"p_use_bail": true
	})
	
	if response and response.get("success", false):
		print("[PrisonManager] Bail successful: ", response)
		# Update State immediately if possible, or wait for next sync
		State.set_prison_status(false, 0, "")
		
		# Refresh full player data to update Gems
		run_refresh_profile()
		
		prison_released.emit(true, response.get("message", "Released from prison"))
	else:
		var error = response.get("error", "Unknown error")
		print("[PrisonManager] Bail failed: ", error)
		prison_released.emit(false, error)

## Force refresh of player profile
func run_refresh_profile() -> void:
	if Network and Session.is_authenticated:
		var profile_result = await Network.http_get(APIEndpoints.PLAYER_PROFILE)
		if profile_result and profile_result.get("success", false):
			State.load_player_data(profile_result.get("data", {}))
