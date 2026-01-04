class_name GuildManager
extends RefCounted
## Guild Management System
## Handles guild operations: create, join, leave, manage members

signal guild_joined(guild: GuildData)
signal guild_left()
signal guild_updated(guild: GuildData)
signal member_joined(member: GuildData.GuildMember)
signal member_left(member_id: String)

const GUILD_ENDPOINT = "/api/v1/guild"

## Fetch guild list
func fetch_guild_list(filters: Dictionary = {}) -> Dictionary:
	var endpoint = APIEndpoints.with_params(GUILD_ENDPOINT + "/list", filters)
	var result = await Network.http_get(endpoint)
	
	if result.success and result.data.has("guilds"):
		var guilds: Array[GuildData] = []
		for guild_dict in result.data.guilds:
			guilds.append(GuildData.from_dict(guild_dict))
		
		return {"success": true, "guilds": guilds}
	
	return {"success": false, "error": result.get("error", "Failed to fetch guilds")}

## Get guild info
func get_guild_info(guild_id: String) -> Dictionary:
	var result = await Network.http_get(GUILD_ENDPOINT + "/info?guild_id=" + guild_id)
	
	if result.success and result.data.has("guild"):
		var guild = GuildData.from_dict(result.data.guild)
		return {"success": true, "guild": guild}
	
	return {"success": false, "error": result.get("error", "Guild not found")}

## Get player's guild
func get_my_guild() -> Dictionary:
	if State.player.guild_id.is_empty():
		return {"success": false, "error": "Not in a guild"}
	
	return await get_guild_info(State.player.guild_id)

## Create guild
func create_guild(guild_name: String, tag: String, description: String = "") -> Dictionary:
	# Validate
	var name_validation = ValidationUtils.validate_guild_name(guild_name)
	if not name_validation.is_valid:
		return {"success": false, "error": name_validation.error_message}
	
	var tag_validation = ValidationUtils.validate_guild_tag(tag)
	if not tag_validation.is_valid:
		return {"success": false, "error": tag_validation.error_message}
	
	# Check cost
	var creation_cost = GameConfig.get_config("guild", "creation_cost", 10000)
	if State.gold < creation_cost:
		return {"success": false, "error": "Not enough gold", "code": "INSUFFICIENT_GOLD"}
	
	# Create on server
	var result = await Network.http_post(GUILD_ENDPOINT + "/create", {
		"name": guild_name,
		"tag": tag,
		"description": description
	})
	
	if result.success:
		State.gold -= creation_cost
		
		var guild = GuildData.from_dict(result.data.guild)
		State.guild_info = guild.to_dict()
		State.player.guild_id = guild.guild_id
		State.player.guild_role = "LORD"
		
		guild_joined.emit(guild)
		Audio.play_guild_created()
		
		Telemetry.track_event("guild_created", {
			"guild_id": guild.guild_id,
			"name": guild_name,
			"cost": creation_cost
		})
		
		return {"success": true, "guild": guild}
	
	return {"success": false, "error": result.get("error", "Failed to create guild")}

## Join guild
func join_guild(guild_id: String) -> Dictionary:
	var result = await Network.http_post(GUILD_ENDPOINT + "/join", {"guild_id": guild_id})
	
	if result.success:
		var guild = GuildData.from_dict(result.data.guild)
		State.guild_info = guild.to_dict()
		State.player.guild_id = guild.guild_id
		State.player.guild_role = "APPRENTICE"
		
		guild_joined.emit(guild)
		Audio.play_guild_joined()
		
		Telemetry.track_event("guild_joined", {"guild_id": guild_id})
		
		return {"success": true, "guild": guild}
	
	return {"success": false, "error": result.get("error", "Failed to join guild")}

## Leave guild
func leave_guild() -> Dictionary:
	if State.player.guild_id.is_empty():
		return {"success": false, "error": "Not in a guild"}
	
	# Check if lord (can't leave, must transfer or disband)
	if State.player.guild_role == "LORD":
		return {"success": false, "error": "Guild lord must transfer leadership or disband guild"}
	
	var result = await Network.http_post(GUILD_ENDPOINT + "/leave", {})
	
	if result.success:
		State.player.guild_id = ""
		State.player.guild_role = ""
		State.guild_info = {}
		State.guild_members = []
		
		guild_left.emit()
		
		Telemetry.track_event("guild_left", {})
		
		return {"success": true}
	
	return {"success": false, "error": result.get("error", "Failed to leave guild")}

## Get guild members
func get_guild_members(guild_id: String = "") -> Dictionary:
	var target_guild = guild_id if not guild_id.is_empty() else State.player.guild_id
	
	if target_guild.is_empty():
		return {"success": false, "error": "No guild specified"}
	
	var result = await Network.http_get(GUILD_ENDPOINT + "/members?guild_id=" + target_guild)
	
	if result.success and result.data.has("members"):
		var members: Array[GuildData.GuildMember] = []
		for member_dict in result.data.members:
			members.append(GuildData.GuildMember.from_dict(member_dict))
		
		if target_guild == State.player.guild_id:
			State.guild_members = members
		
		return {"success": true, "members": members}
	
	return {"success": false, "error": result.get("error", "Failed to fetch members")}

## Invite player to guild
func invite_player(player_id: String) -> Dictionary:
	var result = await Network.http_post(GUILD_ENDPOINT + "/invite", {"player_id": player_id})
	
	if result.success:
		Telemetry.track_event("guild_invite_sent", {"player_id": player_id})
		return {"success": true}
	
	return {"success": false, "error": result.get("error", "Failed to send invite")}

## Kick member from guild
func kick_member(player_id: String) -> Dictionary:
	var result = await Network.http_post(GUILD_ENDPOINT + "/kick", {"player_id": player_id})
	
	if result.success:
		member_left.emit(player_id)
		
		# Update local cache
		for i in State.guild_members.size():
			if State.guild_members[i].player_id == player_id:
				State.guild_members.remove_at(i)
				break
		
		Telemetry.track_event("guild_member_kicked", {"player_id": player_id})
		return {"success": true}
	
	return {"success": false, "error": result.get("error", "Failed to kick member")}

## Promote member
func promote_member(player_id: String) -> Dictionary:
	var result = await Network.http_post(GUILD_ENDPOINT + "/promote", {"player_id": player_id})
	
	if result.success:
		# Update local cache
		for member in State.guild_members:
			if member.player_id == player_id:
				var role_index = member.role as int
				if role_index > 0:
					member.role = (role_index - 1) as GuildData.GuildRole
				break
		
		Telemetry.track_event("guild_member_promoted", {"player_id": player_id})
		return {"success": true}
	
	return {"success": false, "error": result.get("error", "Failed to promote member")}

## Demote member
func demote_member(player_id: String) -> Dictionary:
	var result = await Network.http_post(GUILD_ENDPOINT + "/demote", {"player_id": player_id})
	
	if result.success:
		# Update local cache
		for member in State.guild_members:
			if member.player_id == player_id:
				var role_index = member.role as int
				if role_index < 4:  # Max is APPRENTICE
					member.role = (role_index + 1) as GuildData.GuildRole
				break
		
		Telemetry.track_event("guild_member_demoted", {"player_id": player_id})
		return {"success": true}
	
	return {"success": false, "error": result.get("error", "Failed to demote member")}

## Donate to guild treasury
func donate_to_treasury(amount: int) -> Dictionary:
	if amount <= 0:
		return {"success": false, "error": "Invalid amount"}
	
	if State.gold < amount:
		return {"success": false, "error": "Not enough gold"}
	
	var result = await Network.http_post(GUILD_ENDPOINT + "/donate", {"amount": amount})
	
	if result.success:
		State.gold -= amount
		
		if State.guild_info.has("treasury"):
			State.guild_info.treasury += amount
		
		Telemetry.track_event("guild_donation", {"amount": amount})
		
		return {"success": true, "amount": amount}
	
	return {"success": false, "error": result.get("error", "Failed to donate")}

## Update guild info
func update_guild_info(updates: Dictionary) -> Dictionary:
	var result = await Network.http_post(GUILD_ENDPOINT + "/update", updates)
	
	if result.success:
		var guild = GuildData.from_dict(result.data.guild)
		State.guild_info = guild.to_dict()
		guild_updated.emit(guild)
		
		return {"success": true, "guild": guild}
	
	return {"success": false, "error": result.get("error", "Failed to update guild")}

## Check if player has permission
func has_permission(permission: String) -> bool:
	if State.player.guild_role.is_empty():
		return false
	
	var role = GuildData.GuildRole.get(State.player.guild_role)
	if role == {}:
		return false
	
	var permissions = GuildData.get_role_permissions(role)
	return permissions.get(permission, false)
