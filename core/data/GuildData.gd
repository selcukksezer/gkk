class_name GuildData
extends Resource
## Guild Data Model
## Represents guild (lonca) information

enum GuildRole {
	LORD,       # Lonca lideri
	COMMANDER,  # Komutan
	OFFICER,    # Subay
	MEMBER,     # Üye
	APPRENTICE  # Çırak
}

@export var guild_id: String = ""
@export var name: String = ""
@export var tag: String = ""  # [TAG] format
@export var description: String = ""
@export var icon: String = ""
@export var banner: String = ""

## Stats
@export var level: int = 1
@export var experience: int = 0
@export var member_count: int = 0
@export var max_members: int = 30

## Economy
@export var treasury: int = 0  # Lonca hazinesi
@export var tax_rate: float = 0.05  # 5% üye kazançlarından

## Combat
@export var power: int = 0  # Toplam lonca gücü
@export var war_wins: int = 0
@export var war_losses: int = 0

## Settings
@export var is_recruiting: bool = true
@export var min_level_requirement: int = 1
@export var is_invite_only: bool = false

## Meta
@export var created_at: int = 0
@export var created_by: String = ""
@export var region: String = "central"

## Create from dictionary
static func from_dict(data: Dictionary) -> GuildData:
	var guild = GuildData.new()
	
	guild.guild_id = data.get("id", "")
	guild.name = data.get("name", "")
	guild.tag = data.get("tag", "")
	guild.description = data.get("description", "")
	guild.icon = data.get("icon", "")
	guild.banner = data.get("banner", "")
	
	guild.level = data.get("level", 1)
	guild.experience = data.get("experience", 0)
	guild.member_count = data.get("member_count", 0)
	guild.max_members = data.get("max_members", 30)
	
	guild.treasury = data.get("treasury", 0)
	guild.tax_rate = data.get("tax_rate", 0.05)
	
	guild.power = data.get("power", 0)
	guild.war_wins = data.get("war_wins", 0)
	guild.war_losses = data.get("war_losses", 0)
	
	guild.is_recruiting = data.get("is_recruiting", true)
	guild.min_level_requirement = data.get("min_level_requirement", 1)
	guild.is_invite_only = data.get("is_invite_only", false)
	
	guild.created_at = data.get("created_at", 0)
	guild.created_by = data.get("created_by", "")
	guild.region = data.get("region", "central")
	
	return guild

func to_dict() -> Dictionary:
	return {
		"id": guild_id,
		"name": name,
		"tag": tag,
		"description": description,
		"icon": icon,
		"banner": banner,
		"level": level,
		"experience": experience,
		"member_count": member_count,
		"max_members": max_members,
		"treasury": treasury,
		"tax_rate": tax_rate,
		"power": power,
		"war_wins": war_wins,
		"war_losses": war_losses,
		"is_recruiting": is_recruiting,
		"min_level_requirement": min_level_requirement,
		"is_invite_only": is_invite_only,
		"created_at": created_at,
		"created_by": created_by,
		"region": region
	}

## Check if guild is full
func is_full() -> bool:
	return member_count >= max_members

## Get role permissions
static func get_role_permissions(role: GuildRole) -> Dictionary:
	match role:
		GuildRole.LORD:
			return {
				"can_invite": true,
				"can_kick": true,
				"can_promote": true,
				"can_demote": true,
				"can_edit_info": true,
				"can_access_treasury": true,
				"can_start_war": true,
				"can_disband": true
			}
		GuildRole.COMMANDER:
			return {
				"can_invite": true,
				"can_kick": true,
				"can_promote": false,
				"can_demote": false,
				"can_edit_info": true,
				"can_access_treasury": true,
				"can_start_war": true,
				"can_disband": false
			}
		GuildRole.OFFICER:
			return {
				"can_invite": true,
				"can_kick": false,
				"can_promote": false,
				"can_demote": false,
				"can_edit_info": false,
				"can_access_treasury": false,
				"can_start_war": false,
				"can_disband": false
			}
		_:  # MEMBER and APPRENTICE
			return {
				"can_invite": false,
				"can_kick": false,
				"can_promote": false,
				"can_demote": false,
				"can_edit_info": false,
				"can_access_treasury": false,
				"can_start_war": false,
				"can_disband": false
			}

## Guild Member data
class GuildMember:
	var player_id: String = ""
	var username: String = ""
	var level: int = 1
	var power: int = 0
	var role: GuildRole = GuildRole.MEMBER
	var contribution: int = 0  # Lonca katkısı
	var joined_at: int = 0
	var last_active: int = 0
	
	static func from_dict(data: Dictionary) -> GuildMember:
		var member = GuildMember.new()
		
		member.player_id = data.get("player_id", "")
		member.username = data.get("username", "")
		member.level = data.get("level", 1)
		member.power = data.get("power", 0)
		
		var role_str = data.get("role", "MEMBER")
		member.role = GuildRole.get(role_str) if GuildRole.has(role_str) else GuildRole.MEMBER
		
		member.contribution = data.get("contribution", 0)
		member.joined_at = data.get("joined_at", 0)
		member.last_active = data.get("last_active", 0)
		
		return member
	
	func to_dict() -> Dictionary:
		return {
			"player_id": player_id,
			"username": username,
			"level": level,
			"power": power,
			"role": GuildRole.keys()[role],
			"contribution": contribution,
			"joined_at": joined_at,
			"last_active": last_active
		}
	
	func get_role_name() -> String:
		return GuildRole.keys()[role]
	
	func is_online() -> bool:
		var current_time = Time.get_unix_time_from_system()
		return (current_time - last_active) < 300  # 5 dakika
