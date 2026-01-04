## DungeonBattleScreen.gd - Zindan savaş ekranı
## Savaş animasyonu, sonuç gösterme, hastane yönetimi, ödüllendirme

extends Control

class_name DungeonBattleScreen

## UI Referansları
@onready var dungeon_name_label: Label = %DungeonNameLabel
@onready var battle_info_label: Label = %BattleInfoLabel
@onready var spinner: Control = %Spinner
@onready var success_label: Label = %SuccessLabel
@onready var result_panel: PanelContainer = %ResultPanel
@onready var rewards_vbox: VBoxContainer = %RewardsVBox
@onready var back_button: Button = %BackButton
@onready var claim_button: Button = %ClaimButton

## Manager referansları (autoloads are globally available)

## Data
var dungeon_instance: DungeonInstance
var dungeon_manager: Node  # DungeonManager
var is_resolved: bool = false

func _ready() -> void:
	print("[DungeonBattleScreen] Ready - start")
	
	# State, Network, Session are autoloads - globally accessible
	
	# Manager setup - try to reuse DungeonScreen's manager if available
	var dungeon_screen = get_tree().root.get_node_or_null("Main/ScreenContainer/DungeonScreen")
	if dungeon_screen and dungeon_screen.has_meta("dungeon_manager"):
		dungeon_manager = dungeon_screen.get_meta("dungeon_manager")
		print("[DungeonBattleScreen] Reusing DungeonManager from DungeonScreen")
	elif not dungeon_manager:
		dungeon_manager = DungeonManager.new()
		add_child(dungeon_manager)
		print("[DungeonBattleScreen] Created new DungeonManager")
	
	# UI bağlantıları
	if back_button != null:
		back_button.pressed.connect(_on_back_button_pressed)
	if claim_button != null:
		claim_button.pressed.connect(_on_claim_rewards)
	
	print("[DungeonBattleScreen] Ready - before init. dungeon_instance exists=%s" % (dungeon_instance != null))
	# İlk dungeon instance'ını al
	# _initialize_battle will use an already-provided `dungeon_instance` if setup(data) was called by Main
	_initialize_battle()
	print("[DungeonBattleScreen] Ready - end")

## Battle initialize
func _initialize_battle() -> void:
	print("[DungeonBattleScreen] Initializing battle...")
	
	# If a dungeon_instance was provided via setup(), use it. Otherwise, try State or fallback to a mock.
	if dungeon_instance == null:
		var player_data = {}
		if State and State.has_method("get_player_data"):
			player_data = State.get_player_data()
		# Try to use a last_active_instance saved in State if present
		if player_data.has("last_dungeon_instance") and not player_data.last_dungeon_instance.is_empty():
			dungeon_instance = DungeonInstance.from_dict(player_data.last_dungeon_instance)
		else:
			# Fallback mock instance
			dungeon_instance = DungeonInstance.new(
				player_data.get("id", ""),
				"dungeon_dark_forest",
				"Karanlık Orman Zindanı",
				25,
				0.45,
				1800
			)
	
	print("[DungeonBattleScreen] Initializing battle - after instance selection. id=%s" % (dungeon_instance and dungeon_instance.id or "<none>"))

	# Update UI asap
	dungeon_name_label.text = dungeon_instance.dungeon_name
	battle_info_label.text = "Savaş başladı...\n\nBir an bekleniyor..."

	# Result panel gizle
	result_panel.visible = false

	# Spinner animasyonu
	_animate_spinner()

	# Battle çözme (delay ile)
	print("[DungeonBattleScreen] Waiting 3s before resolve...")
	await get_tree().create_timer(3.0).timeout
	print("[DungeonBattleScreen] Timer elapsed; resolving battle now")
	_resolve_battle()

## Spinner animasyonu (dönme)
func _animate_spinner() -> void:
	if not spinner:
		return
	
	var tween = create_tween().set_loops()
	tween.tween_property(spinner, "rotation", TAU, 1.5)

## Battle'ı çöz (success/failure RNG)
func _resolve_battle() -> void:
	print("[DungeonBattleScreen] Resolving battle...")
	
	if not dungeon_instance:
		print("[DungeonBattleScreen] ERROR: dungeon_instance is null!")
		battle_info_label.text = "Hata: Zindan verisi bulunamadı"
		return
	
	# Başarı/başarısızlık roll
	dungeon_instance.success_roll = randf()
	dungeon_instance.actual_success = dungeon_instance.success_roll < dungeon_instance.success_rate_calculated
	
	print("[DungeonBattleScreen] Battle resolved: success=%s (roll=%.2f, rate=%.2f)" % [
		dungeon_instance.actual_success,
		dungeon_instance.success_roll,
		dungeon_instance.success_rate_calculated
	])
	
	# Ödülleri hesapla (DungeonManager ile uyumlu)
	var player_data = State.get_player_data()
	var rewards = {}
	var loot = []

	if dungeon_instance.actual_success:
		# Use DungeonManager's reward pipeline if available
		var reward_range = null
		if dungeon_manager and dungeon_manager.has_method("compute_reward_range_from_instance"):
			reward_range = dungeon_manager.compute_reward_range_from_instance(dungeon_instance, player_data)
		else:
			reward_range = {"min_gold": 100, "max_gold": 500, "multiplier": 1.0}

		var min_g = int(reward_range.get("min_gold", 100))
		var max_g = int(reward_range.get("max_gold", 500))
		var gold_reward = randi_range(min_g, max_g)
		if randf() < 0.1:
			gold_reward = int(gold_reward * 1.5)
			print("[DungeonBattleScreen] CRITICAL SUCCESS! Gold x1.5")
		var exp_reward = int(gold_reward * 0.5)
		
		# Loot via manager if available
		if dungeon_manager and dungeon_manager.has_method("_generate_loot"):
			loot = dungeon_manager._generate_loot(dungeon_instance.dungeon_id)
		else:
			loot = []
		
		rewards = {"gold": gold_reward, "exp": exp_reward}
	else:
		# Failure partial rewards
		var fail_range = {"min_gold": 10, "max_gold": 50}
		var min_g = int(fail_range.get("min_gold", 10))
		var max_g = int(fail_range.get("max_gold", 50))
		var gold_reward = randi_range(min_g, max_g)
		var exp_reward = randi_range(5, 20)
		rewards = {"gold": gold_reward, "exp": exp_reward}

	# Failure hospitalization via DungeonManager helper if available
	if not dungeon_instance.actual_success:
		if dungeon_manager and dungeon_manager.has_method("_should_hospitalize"):
			if dungeon_manager._should_hospitalize(dungeon_instance):
				dungeon_instance.is_hospitalized = true
				# 2-6 saat arası rastgele (120-360 dakika)
				dungeon_instance.hospital_duration_minutes = randi_range(120, 360)
				dungeon_instance.hospitalized_reason = "Zindan başarısızlığı"
				print("[DungeonBattleScreen] Player hospitalized: %d minutes" % dungeon_instance.hospital_duration_minutes)
				
				# Server-side hospitalization
				if State:
					var hospital_mgr = HospitalManager.new()
					var admit_result = await hospital_mgr.admit_player(
						dungeon_instance.hospital_duration_minutes,
						dungeon_instance.hospitalized_reason
					)
					if not admit_result.success:
						push_error("[DungeonBattleScreen] Failed to hospitalize: %s" % admit_result.get("error", "Unknown error"))
		else:
			var hospitalize_chance = 0.25  # %25 şans
			if randf() < hospitalize_chance:
				dungeon_instance.is_hospitalized = true
				# 2-6 saat arası rastgele
				dungeon_instance.hospital_duration_minutes = randi_range(120, 360)
				dungeon_instance.hospitalized_reason = "Zindan başarısızlığı"
				print("[DungeonBattleScreen] Player hospitalized: %d minutes" % dungeon_instance.hospital_duration_minutes)
				
				# Server-side hospitalization
				if State:
					var hospital_mgr = HospitalManager.new()
					var admit_result = await hospital_mgr.admit_player(
						dungeon_instance.hospital_duration_minutes,
						dungeon_instance.hospitalized_reason
					)
					if not admit_result.success:
						push_error("[DungeonBattleScreen] Failed to hospitalize: %s" % admit_result.get("error", "Unknown error"))

	# Apply to instance (handle both object and dict payloads)
	if dungeon_instance:
		var resolved_at_ts = int(Time.get_ticks_msec() / 1000.0)
		if typeof(dungeon_instance) == TYPE_OBJECT and dungeon_instance is DungeonInstance:
			dungeon_instance.rewards = rewards
			# Ensure loot is properly typed Array[String]
			var loot_items: Array[String] = []
			if typeof(loot) == TYPE_ARRAY:
				for item in loot:
					loot_items.append(str(item))
			dungeon_instance.loot = loot_items
			dungeon_instance.resolved_at = int(resolved_at_ts)
		else:
			# treat as Dictionary-like payload
			dungeon_instance["rewards"] = rewards
			dungeon_instance["loot"] = loot
			dungeon_instance["resolved_at"] = int(resolved_at_ts)

	# Telemetry: mirror DungeonManager (use safe reads)
	if dungeon_instance:
		var user_id = ""
		var dungeon_id = ""
		var dungeon_name = ""
		var calc_success = 0.0
		var actual_success = false
		# Get fields safely
		if typeof(dungeon_instance) == TYPE_DICTIONARY:
			if dungeon_instance.has("player_id"):
				user_id = str(dungeon_instance["player_id"])
			if dungeon_instance.has("dungeon_id"):
				dungeon_id = str(dungeon_instance["dungeon_id"])
			if dungeon_instance.has("dungeon_name"):
				dungeon_name = str(dungeon_instance["dungeon_name"])
			if dungeon_instance.has("success_rate_calculated"):
				calc_success = float(dungeon_instance["success_rate_calculated"])
			if dungeon_instance.has("actual_success"):
				actual_success = bool(dungeon_instance["actual_success"])
		else:
			user_id = dungeon_instance.player_id
			dungeon_id = dungeon_instance.dungeon_id
			dungeon_name = dungeon_instance.dungeon_name
			calc_success = dungeon_instance.success_rate_calculated
			actual_success = dungeon_instance.actual_success

		# Ensure rewards_for_telemetry is always a Dictionary
		var rewards_for_telemetry: Dictionary = {}
		if typeof(dungeon_instance) == TYPE_DICTIONARY:
			if dungeon_instance.has("rewards") and typeof(dungeon_instance["rewards"]) == TYPE_DICTIONARY:
				rewards_for_telemetry = dungeon_instance["rewards"]
		else:
			var r = dungeon_instance.rewards if typeof(dungeon_instance.rewards) != TYPE_NIL else {}
			if typeof(r) == TYPE_DICTIONARY:
				rewards_for_telemetry = r

		var loot_count = 0
		if typeof(dungeon_instance) == TYPE_DICTIONARY:
			if dungeon_instance.has("loot") and typeof(dungeon_instance["loot"]) == TYPE_ARRAY:
				loot_count = dungeon_instance["loot"].size()
		else:
			if typeof(dungeon_instance.loot) == TYPE_ARRAY:
				loot_count = dungeon_instance.loot.size()

		var duration = 0
		if typeof(dungeon_instance) == TYPE_DICTIONARY:
			var res_at = 0
			var start_at = 0
			if dungeon_instance.has("resolved_at"):
				res_at = dungeon_instance["resolved_at"]
			if dungeon_instance.has("started_at"):
				start_at = dungeon_instance["started_at"]
			duration = res_at - start_at
		else:
			if typeof(dungeon_instance.resolved_at) != TYPE_NIL and typeof(dungeon_instance.started_at) != TYPE_NIL:
				duration = dungeon_instance.resolved_at - dungeon_instance.started_at

		var hospitalized_flag = false
		if typeof(dungeon_instance) == TYPE_DICTIONARY:
			if dungeon_instance.has("is_hospitalized"):
				hospitalized_flag = bool(dungeon_instance["is_hospitalized"])
		else:
			hospitalized_flag = dungeon_instance.is_hospitalized

		Telemetry.track_event("combat.dungeon", "completed", {
			"user_id": user_id,
			"dungeon_id": dungeon_id,
			"dungeon_name": dungeon_name,
			"mode": "solo",
			"calculated_success": calc_success,
			"actual_success": actual_success,
			"rewards": rewards_for_telemetry,
			"loot_count": loot_count,
			"duration": duration,
			"hospitalized": hospitalized_flag
		})

	_show_result()

## Sonuç göster
func _show_result() -> void:
	is_resolved = true
	
	# Spinner durdurmak (opsiyonel)
	if spinner:
		spinner.visible = false
	
	# Başarı/Başarısızlık yazısı
	if dungeon_instance.actual_success:
		success_label.text = "🎉 BAŞARI 🎉"
		success_label.add_theme_color_override("font_color", Color.LIGHT_GREEN)
		battle_info_label.text = "Zindanı başarıyla tamamladın!"
	else:
		success_label.text = "💀 BAŞARISIZ 💀"
		success_label.add_theme_color_override("font_color", Color.RED)
		battle_info_label.text = "Zindanı tamamlayamadın."
	
	# Ödülleri göster
	_display_rewards()
	
	# Result panel göster
	result_panel.visible = true
	
	# Otomatik ödülleri al
	_apply_rewards_automatically()

## Ödülleri otomatik olarak karakte ekle
func _apply_rewards_automatically() -> void:
	print("[DungeonBattleScreen] Applying rewards automatically...")
	
	var player_data = State.get_player_data()
	var updates = {}
	
	if not player_data.is_empty() and dungeon_instance.actual_success:
		# Read rewards/loot safely whether dungeon_instance is an object or dict
		var rewards = {}
		var loot_items: Array = []
		var is_hospital = false
		var hospital_minutes = 0
		if typeof(dungeon_instance) == TYPE_DICTIONARY:
			if dungeon_instance.has("rewards") and typeof(dungeon_instance["rewards"]) == TYPE_DICTIONARY:
				rewards = dungeon_instance["rewards"]
			else:
				rewards = {}
			if dungeon_instance.has("loot") and typeof(dungeon_instance["loot"]) == TYPE_ARRAY:
				loot_items = dungeon_instance["loot"]
			else:
				loot_items = []
			if dungeon_instance.has("is_hospitalized"):
				is_hospital = bool(dungeon_instance["is_hospitalized"])
			else:
				is_hospital = false
			hospital_minutes = int(dungeon_instance["hospital_duration_minutes"]) if dungeon_instance.has("hospital_duration_minutes") else 0
		else:
			rewards = dungeon_instance.rewards
			loot_items = dungeon_instance.loot
			is_hospital = dungeon_instance.is_hospitalized
			hospital_minutes = dungeon_instance.hospital_duration_minutes
		
		if typeof(rewards) == TYPE_DICTIONARY and rewards.has("gold"):
			var new_gold = player_data.get("gold", 0) + int(rewards.get("gold", 0))
			updates["gold"] = new_gold
			print("[DungeonBattleScreen] Added gold: %d (total: %d)" % [rewards.get("gold", 0), new_gold])
		
		if typeof(rewards) == TYPE_DICTIONARY and rewards.has("exp"):
			var new_exp = player_data.get("exp", 0) + int(rewards.get("exp", 0))
			updates["exp"] = new_exp
			print("[DungeonBattleScreen] Added exp: %d (total: %d)" % [rewards.get("exp", 0), new_exp])
		
		# Eşyaları inventory'e ekle
		if loot_items.size() > 0:
			if not player_data.has("inventory"):
				player_data["inventory"] = []
			for item_id in loot_items:
				player_data["inventory"].append(item_id)
			updates["inventory"] = player_data["inventory"]
			print("[DungeonBattleScreen] Added %d loot items" % loot_items.size())
		
		# Hastanelik durumunu güncelle
		if is_hospital:
			updates["hospitalized"] = true
			updates["hospital_end_time"] = Time.get_ticks_msec() + (hospital_minutes * 60 * 1000)
			print("[DungeonBattleScreen] Player hospitalized for %d minutes" % hospital_minutes)
		
		# State'i güncelle
		if not updates.is_empty():
			State.update_player_data(updates)
			print("[DungeonBattleScreen] Rewards applied to State")

## Ödülleri göster
func _display_rewards() -> void:
	# Rewards container'ı temizle
	for child in rewards_vbox.get_children():
		child.queue_free()
	
	# Başarı/Başarısızlık bilgisi
	var status_label = Label.new()
	status_label.text = "Sonuç: %s (Roll: %.2f%%)" % [
		"BAŞARI" if dungeon_instance.actual_success else "BAŞARISIZ",
		dungeon_instance.success_roll * 100
	]
	rewards_vbox.add_child(status_label)
	
	if dungeon_instance.actual_success:
		# Ödüller (safe reads for rewards/loot)
		var rewards = {}
		var loot_items: Array = []
		if typeof(dungeon_instance) == TYPE_DICTIONARY:
			if dungeon_instance.has("rewards") and typeof(dungeon_instance["rewards"]) == TYPE_DICTIONARY:
				rewards = dungeon_instance["rewards"]
			else:
				rewards = {}
			if dungeon_instance.has("loot") and typeof(dungeon_instance["loot"]) == TYPE_ARRAY:
				loot_items = dungeon_instance["loot"]
			else:
				loot_items = []
		else:
			rewards = dungeon_instance.rewards
			loot_items = dungeon_instance.loot

		if typeof(rewards) == TYPE_DICTIONARY and rewards.get("gold", 0) > 0:
			var gold_label = Label.new()
			gold_label.text = "💰 Altın: +%d" % rewards.get("gold", 0)
			gold_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
			rewards_vbox.add_child(gold_label)

		if typeof(rewards) == TYPE_DICTIONARY and rewards.get("exp", 0) > 0:
			var exp_label = Label.new()
			exp_label.text = "⭐ Tecrübe: +%d" % rewards.get("exp", 0)
			exp_label.add_theme_color_override("font_color", Color.LIGHT_CYAN)
			rewards_vbox.add_child(exp_label)
			
			# Level up kontrolü
			var old_level = State.level
			var old_xp = State.xp
			var new_xp = old_xp + rewards.get("exp", 0)
			var new_level = old_level
			var temp_xp = new_xp
			var temp_next = State.next_level_xp
			
			# Level up'ları simüle et
			while temp_xp >= temp_next:
				temp_xp -= temp_next
				new_level += 1
				temp_next = State.calculate_next_level_xp(new_level)
			
			if new_level > old_level:
				var levelup_label = Label.new()
				levelup_label.text = "⬆️ SEVİYE ATLA: %d → %d" % [old_level, new_level]
				levelup_label.add_theme_color_override("font_color", Color.YELLOW)
				levelup_label.add_theme_font_size_override("font_size", 18)
				rewards_vbox.add_child(levelup_label)

		# Loot items
		if loot_items.size() > 0:
			var loot_label = Label.new()
			loot_label.text = "📦 Loot:"
			loot_label.add_theme_font_size_override("font_size", 14)
			rewards_vbox.add_child(loot_label)
			
			for item_id in loot_items:
				var item_label = Label.new()
				item_label.text = "  • %s" % item_id
				item_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
				rewards_vbox.add_child(item_label)
	
	# Hastanelik
	if dungeon_instance.is_hospitalized:
		var hospital_label = Label.new()
		hospital_label.text = "\n🏥 HASTANELİKTE: %d dakika\n%s" % [
			dungeon_instance.hospital_duration_minutes,
			dungeon_instance.hospitalized_reason
		]
		hospital_label.add_theme_color_override("font_color", Color.ORANGE)
		hospital_label.add_theme_font_size_override("font_size", 12)
		rewards_vbox.add_child(hospital_label)

## Ödülleri al ve home screen'e dön
func _on_claim_rewards() -> void:
	if not is_resolved:
		return
	
	print("[DungeonBattleScreen] User claimed rewards button - navigating to home...")
	
	# Telemetry: rewards claimed
	if dungeon_instance:
		Telemetry.track_event("combat.dungeon", "rewards_claimed", {
			"user_id": dungeon_instance.player_id,
			"dungeon_id": dungeon_instance.dungeon_id,
			"success": dungeon_instance.actual_success,
			"rewards": dungeon_instance.rewards
		})

	# Ödüller zaten _apply_rewards_automatically() tarafından uygulanmıştır
	# Home screen'e dön
	var main = get_tree().root.get_node("Main")
	if main:
		main.show_screen("home")
	else:
		print("[DungeonBattleScreen] ERROR: Main node not found")

## Geri dön (dungeon listesine)
func _on_back_button_pressed() -> void:
	get_tree().root.get_node("Main").show_screen("dungeon")

## Test metodu (sonuç göster)
func test_show_success() -> void:
	print("[DungeonBattleScreen] Test mode: showing success")
	dungeon_instance = DungeonInstance.new("test_player", "test_dungeon", "Test Zindanı", 20, 0.5, 600)
	dungeon_instance.actual_success = true
	dungeon_instance.success_roll = 0.4
	dungeon_instance.rewards = {"gold": 5000, "exp": 500}
	var test_loot: Array[String] = ["steel_sword", "iron_armor"]
	dungeon_instance.loot = test_loot
	_show_result()

func test_show_failure() -> void:
	print("[DungeonBattleScreen] Test mode: showing failure with hospitalization")
	dungeon_instance = DungeonInstance.new("test_player", "test_dungeon", "Test Zindanı", 20, 0.5, 600)
	dungeon_instance.actual_success = false
	dungeon_instance.success_roll = 0.8
	dungeon_instance.rewards = {"gold": 500, "exp": 50}
	dungeon_instance.is_hospitalized = true
	dungeon_instance.hospital_duration_minutes = 180
	dungeon_instance.hospitalized_reason = "Ağır yaralanma"
	_show_result()

## Setup called by Main.show_screen to pass data into the screen before it's added to tree
func setup(data: Dictionary) -> void:
	print("[DungeonBattleScreen] setup() called with data keys: %s" % data.keys())
	if data.has("dungeon_instance") and not data.get("dungeon_instance", {}).is_empty():
		dungeon_instance = DungeonInstance.from_dict(data.get("dungeon_instance"))
		print("[DungeonBattleScreen] setup(): dungeon_instance provided via data (id=%s)" % dungeon_instance.id)
	else:
		print("[DungeonBattleScreen] setup(): no dungeon_instance in data")
