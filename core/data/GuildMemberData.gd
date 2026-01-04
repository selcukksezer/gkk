class_name GuildMemberData
extends Resource
## Guild Member Data Model

@export var user_id: String = ""
@export var username: String = ""
@export var level: int = 1
@export var power: int = 0
@export var role: String = "squire"  # lord|commander|officer|member|squire
@export var contribution: int = 0
@export var joined_at: String = ""
@export var last_active: String = ""
@export var is_online: bool = false

## Parse from API response
static func from_dict(data: Dictionary) -> GuildMemberData:
	var member = GuildMemberData.new()
	
	member.user_id = data.get("user_id", "")
	member.username = data.get("username", "")
	member.level = data.get("level", 1)
	member.power = data.get("power", 0)
	member.role = data.get("role", "squire")
	member.contribution = data.get("contribution", 0)
	member.joined_at = data.get("joined_at", "")
	member.last_active = data.get("last_active", "")
	member.is_online = data.get("is_online", false)
	
	return member

## Get role display name
func get_role_display() -> String:
	match role:
		"lord": return "Lord (Lider)"
		"commander": return "Commander (Komutan)"
		"officer": return "Officer (Subay)"
		"member": return "Member (Üye)"
		"squire": return "Squire (Çırak)"
		_: return role

## Can kick members
func can_kick() -> bool:
	return role in ["lord", "commander", "officer"]

## Can withdraw from treasury
func can_withdraw() -> bool:
	return role in ["lord", "commander"]
