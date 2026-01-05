extends Node
## Main Game Scene
## Ana oyun container - tüm ekranları yönetir

@onready var screen_container: Control = $ScreenContainer
@onready var hud_container: CanvasLayer = $HUDContainer
@onready var dialog_container: CanvasLayer = $DialogContainer
@onready var top_bar: Control = $HUDContainer/TopBar
@onready var bottom_nav: Control = $HUDContainer/BottomNav
@onready var loading_overlay: Control = $HUDContainer/LoadingOverlay
@onready var loading_spinner: TextureRect = $HUDContainer/LoadingOverlay/VBox/Spinner

# Timer used to avoid stuck loading overlay when session check hangs
const SESSION_CHECK_TIMEOUT: float = 10.0  # seconds

var current_screen: Control = Control.new()
var screen_stack: Array[String] = []

# UI scaling reference (for responsive/mobile)
const UI_SCALING_ENABLED: bool = false
const REFERENCE_WIDTH: int = 1080
const REFERENCE_HEIGHT: int = 1920
const MIN_UI_SCALE: float = 0.6
const MAX_UI_SCALE: float = 1.6

## Screen paths
const SCREENS = {
	"login": "res://scenes/ui/screens/LoginScreen.tscn",
	"home": "res://scenes/ui/screens/HomeScreen.tscn",
	"inventory": "res://scenes/ui/screens/InventoryScreen.tscn",
	"market": "res://scenes/ui/screens/MarketScreen.tscn",
	"season": "res://scenes/ui/screens/SeasonScreen.tscn",
	"quest": "res://scenes/ui/screens/QuestScreen.tscn",
	"pvp": "res://scenes/ui/screens/PvPScreen.tscn",
	"guild": "res://scenes/ui/screens/GuildScreen.tscn",
	"character": "res://scenes/ui/screens/CharacterScreen.tscn",
	"shop": "res://scenes/ui/screens/ShopScreen.tscn",
	"settings": "res://scenes/ui/screens/SettingsScreen.tscn",
	"hospital": "res://scenes/ui/screens/HospitalScreen.tscn",
	"anvil": "res://scenes/ui/screens/AnvilScreen.tscn",
	"crafting": "res://scenes/ui/screens/CraftingScreen.tscn",
	"leaderboard": "res://scenes/ui/screens/LeaderboardScreen.tscn",
	"bank": "res://scenes/ui/screens/BankScreen.tscn",
	"dungeon": "res://scenes/ui/screens/DungeonScreen.tscn",
	"dungeon_battle": "res://scenes/ui/screens/DungeonBattleScreen.tscn",
	"achievement": "res://scenes/ui/screens/AchievementScreen.tscn",
	"map": "res://scenes/ui/screens/MapScreen.tscn",
	"trade": "res://scenes/ui/screens/TradeScreen.tscn",
	"building": "res://scenes/ui/screens/BuildingScreen.tscn",
	"mining": "res://scenes/ui/screens/MiningScreen.tscn",
	"production": "res://scenes/ui/screens/ProductionScreen.tscn",
	"guild_war": "res://scenes/ui/screens/GuildWarScreen.tscn",
	"profile": "res://scenes/ui/screens/ProfileScreen.tscn",
	"event": "res://scenes/ui/screens/EventScreen.tscn",
	"warehouse": "res://scenes/ui/screens/WarehouseScreen.tscn",
	"reputation": "res://scenes/ui/screens/ReputationScreen.tscn"
}

func _ready() -> void:
	print("[Main] Game starting...")
	
	# Initialize systems
	_initialize_systems()
	
	# Connect signals
	_connect_signals()
	
	# Decide initial screen based on current session state (no server validation)
	print("[Main] Checking session state")
	if Session and Session.is_logged_in():
		print("[Main] Session found; showing home")
		show_screen("home", false)
		
		# If player data is empty, fetch it from API with timeout protection
		if State.get_player_data().is_empty() and Network:
			print("[Main] Player data empty, fetching from API...")
			_show_loading_overlay(true)
			
			# Start a timeout in case profile fetch stalls (15 seconds timeout)
			var timeout_timer = get_tree().create_timer(15.0)
			timeout_timer.timeout.connect(func():
				print("[Main] Startup profile fetch timed out; hiding overlay")
				_show_loading_overlay(false)
			)
			
			var result = await Network.http_get(APIEndpoints.PLAYER_PROFILE)
			
			if result and result.success and result.data:
				State.load_player_data(result.data)
				print("[Main] Player profile loaded at startup")
			else:
				print("[Main] Failed to load player profile at startup (non-fatal)")
			# Hide overlay regardless
			_show_loading_overlay(false)
		else:
			print("[Main] Player data available, no API fetch needed")

	else:
		print("[Main] No session; showing login")
		show_screen("login", false)
	# Note: we will NOT perform forced validation here; session remains valid until user logs out explicitly.
	
	print("[Main] Game ready")
	
	# Apply initial UI scale after one frame (ensures @onready nodes are ready)
	if UI_SCALING_ENABLED:
		call_deferred("_apply_ui_scale")

	# Listen to viewport size changes for responsive scaling
	var vp = get_viewport()
	if vp and UI_SCALING_ENABLED:
		if not vp.size_changed.is_connected(_on_viewport_size_changed):
			vp.size_changed.connect(_on_viewport_size_changed)

func _on_session_status_checked(is_authenticated: bool) -> void:
	print("[Main] Session status checked: ", is_authenticated)
	# Do not change screen automatically here; background validation should not switch UI abruptly.
	# If session invalid and user is on home, SessionManager will emit session_expired() or logout() to handle it.

func _on_session_check_timeout() -> void:
	print("[Main] WARNING: session check timed out after %ss" % SESSION_CHECK_TIMEOUT)
	# Hide overlay and ensure login is visible to avoid stuck UI
	_show_loading_overlay(false)
	show_screen("login", false)
	# Defensive: emit that session check failed so other systems can react
	if Session and Session.has_signal("session_status_checked"):
		# Use callable only if signal is connected; this avoids re-entrancy
		# We cannot emit Session's signal here from Main, but ensure UI shows login
		pass

func _initialize_systems() -> void:
	# Load game config
	GameConfig.load_all()
	
	# Initialize network
	if Network:
		Network.initialize()
	
	# Start background processes
	_start_energy_regen()
	_start_tolerance_decay()

func _connect_signals() -> void:
	# Session signals
	if Session:
		Session.logged_in.connect(_on_logged_in)
		Session.logged_out.connect(_on_logged_out)
		Session.session_expired.connect(_on_session_expired)
		# Listen for initial auth check (emitted by SessionManager)
		if Session.has_signal("session_status_checked"):
			Session.session_status_checked.connect(_on_session_status_checked)
		# If Session has no saved tokens at startup, ensure login is shown
		if Session.access_token.is_empty() and Session.refresh_token.is_empty():
			show_screen("login", false)
	# Additional safety: if not logged in at this point, ensure login is visible (covers race conditions)
	if Session and not Session.is_logged_in():
		show_screen("login", false)
	
	# State signals
	if State:
		State.energy_updated.connect(_on_energy_updated)
		State.player_updated.connect(_on_player_updated)
	
	# Bottom nav signals
	if bottom_nav:
		bottom_nav.navigation_changed.connect(_on_navigation_changed)

func show_screen(screen_name: String, push_to_stack: bool = true, data: Dictionary = {}) -> void:
	if not SCREENS.has(screen_name):
		push_error("[Main] Unknown screen: %s" % screen_name)
		return
	
	# Remove current screen properly
	if current_screen and current_screen != Control.new():
		current_screen.queue_free()
	
	# Defer loading and instantiation to avoid blocking on resource parsing
	print("[Main] Scheduling deferred load+instantiate for: %s" % SCREENS[screen_name])
	call_deferred("_deferred_instantiate_screen_by_path", SCREENS[screen_name], screen_name, push_to_stack, data)

func _deferred_instantiate_screen_by_path(scene_path: String, screen_name: String, push_to_stack: bool, data: Dictionary) -> void:
	print("[Main] Deferred: loading scene resource: %s" % scene_path)
	# Sanity check - ensure file exists on disk
	var exists = FileAccess.file_exists(scene_path)
	print("[Main] Deferred: file_exists=%s" % exists)
	if not exists:
		push_error("[Main] Deferred: scene file does not exist: %s" % scene_path)
		return
	# Read first line as quick sanity read
	var fa = FileAccess.open(scene_path, FileAccess.ModeFlags.READ)
	if fa:
		var first_line = fa.get_line()
		fa.close()
		print("[Main] Deferred: first line: %s" % first_line)
	else:
		print("[Main] Deferred: failed to open file for read: %s" % scene_path)

	print("[Main] Deferred: attempting load(scene_path)...")
	var screen_scene = load(scene_path)
	print("[Main] Deferred: load returned, screen_scene is_valid=%s" % (screen_scene != null))
	if not screen_scene:
		push_error("[Main] Deferred load failed for: %s" % scene_path)
		return

	print("[Main] Deferred: scheduling immediate instantiate for: %s" % screen_name)
	# Schedule actual instantiation in next idle to avoid any resource compilation stalls
	call_deferred("_deferred_instantiate_now", scene_path, screen_name, push_to_stack, data)
	# Watchdog timer to detect if instantiation doesn't complete
	var watchdog = Timer.new()
	watchdog.wait_time = 0.5
	watchdog.one_shot = true
	watchdog.timeout.connect(func():
		if not current_screen or current_screen.name != screen_name:
			print("[Main] Watchdog: instantiation not completed for %s; dumping diagnostics..." % screen_name)
			print("[Main] screen_container child_count=%d" % screen_container.get_child_count())
			for i in range(min(10, screen_container.get_child_count())):
				var c = screen_container.get_child(i)
				print("[Main] child %d: %s (visible=%s)" % [i, c.name, c.visible])
			# Quick resource preview
			var fa_preview = FileAccess.open(scene_path, FileAccess.ModeFlags.READ)
			if fa_preview:
				var preview = fa_preview.get_buffer(min(512, fa_preview.get_length()))
				fa_preview.close()
				print("[Main] Scene preview (first 512 bytes):\n%s" % str(preview))
			else:
				print("[Main] Watchdog: failed to open scene file for preview")
			# Fallback: do nothing to avoid showing error placeholder
			# var placeholder = PanelContainer.new()
			# placeholder.name = "ScreenLoadError"
			# placeholder.custom_minimum_size = Vector2(400, 300)
			# var lbl = Label.new()
			# lbl.text = "Ekran yüklenemedi: %s" % screen_name
			# lbl.add_theme_font_size_override("font_size", 20)
			# placeholder.add_child(lbl)
			# screen_container.add_child(placeholder)
			# current_screen = placeholder
		else:
			print("[Main] Watchdog: instantiation successful for %s" % screen_name)
	)
	add_child(watchdog)
	watchdog.start()

func _deferred_instantiate_now(scene_path: String, screen_name: String, push_to_stack: bool, data: Dictionary) -> void:
	print("[Main] Now: loading scene resource in instantiator: %s" % scene_path)
	var screen_scene = load(scene_path)
	if not screen_scene:
		push_error("[Main] Now: load failed for %s" % scene_path)
		return
	print("[Main] Now: instantiating scene: %s" % screen_name)
	var inst = null
	# Try to instantiate and log errors
	inst = screen_scene.instantiate()
	if not inst:
		push_error("[Main] instantiate() returned null for: %s" % screen_name)
		return
	print("[Main] Now: instantiated, has setup=%s" % inst.has_method("setup"))
	if data and inst.has_method("setup"):
		print("[Main] Now: calling setup(data) on %s" % screen_name)
		inst.setup(data)
	print("[Main] Now: adding instance to screen_container")
	screen_container.add_child(inst)
	inst.show()
	if inst.has_method("set_process"):
		inst.set_process(true)
	current_screen = inst
	print("[Main] Now: added, current_screen=%s" % current_screen.name)

	# Update stack
	if push_to_stack:
		screen_stack.append(screen_name)

	# Update HUD visibility
	_update_hud_visibility(screen_name)

	print("[Main] Screen changed to: %s" % screen_name)

	# Re-apply UI scale after screen change (keeps UI consistent)
	if UI_SCALING_ENABLED:
		call_deferred("_apply_ui_scale")

func go_back() -> bool:
	if screen_stack.size() <= 1:
		return false
	
	# Remove current
	screen_stack.pop_back()
	
	# Show previous
	var previous_screen = screen_stack.pop_back()
	show_screen(previous_screen, true)
	
	return true

func show_dialog(dialog_scene: PackedScene, data: Dictionary = {}) -> void:
	var dialog = dialog_scene.instantiate()
	dialog_container.add_child(dialog)
	
	# Pass data if dialog has setup method
	if dialog.has_method("setup"):
		dialog.setup(data)

func _update_hud_visibility(screen_name: String) -> void:
	# Hide HUD on login screen and expand ScreenContainer to full viewport for login
	var show_hud = screen_name != "login"

	if top_bar:
		top_bar.visible = show_hud

	if bottom_nav:
		bottom_nav.visible = show_hud

	# When showing login, make the ScreenContainer full screen so login uses entire viewport
	if screen_container:
		if not show_hud:
			# Full screen anchors
			screen_container.anchors_preset = 15
			screen_container.anchor_left = 0.0
			screen_container.anchor_top = 0.0
			screen_container.anchor_right = 1.0
			screen_container.anchor_bottom = 1.0
		else:
			# Restore default anchored area (keep space for TopBar and BottomNav)
			screen_container.anchor_top = 0.065
			screen_container.anchor_bottom = 0.925

func _start_energy_regen() -> void:
	var timer = Timer.new()
	timer.wait_time = 180.0  # 3 minutes
	timer.timeout.connect(_on_energy_regen_tick)
	add_child(timer)
	timer.start()

func _start_tolerance_decay() -> void:
	var timer = Timer.new()
	timer.wait_time = 300.0  # 5 minutes
	timer.timeout.connect(_on_tolerance_decay_tick)
	add_child(timer)
	timer.start()

## Signal handlers

func _on_logged_in(player_data: Dictionary) -> void:
	print("[Main] Player logged in signal received: ", player_data)
	# Show loading overlay briefly while we switch to home
	_show_loading_overlay(true)
	# Show home immediately (player data should already be present from login response)
	show_screen("home", false)
	print("[Main] show_screen('home') called")
	# Hide overlay after a short delay to let UI settle
	var t = Timer.new()
	t.wait_time = 0.5
	t.one_shot = true
	t.timeout.connect(func():
		_show_loading_overlay(false)
	)
	add_child(t)
	t.start()

func _on_logged_out() -> void:
	print("[Main] Player logged out")
	# Hide any global loading overlay
	_show_loading_overlay(false)
	show_screen("login", false)
	screen_stack.clear()

func _on_session_expired() -> void:
	print("[Main] Session expired")
	# Show dialog
	var dialog_scene = load("res://scenes/ui/dialogs/ErrorDialog.tscn")
	if dialog_scene:
		show_dialog(dialog_scene, {
			"title": "Oturum Süresi Doldu",
			"message": "Lütfen tekrar giriş yapın.",
			"on_confirm": Callable(self, "go_to_login")
		})
	# Ensure UI returns to login
	show_screen("login", false)

func _on_energy_updated() -> void:
	# Top bar will update itself via signals
	pass

func _on_player_updated() -> void:
	# Screens will update themselves via signals
	pass

func _on_navigation_changed(screen_name: String) -> void:
	show_screen(screen_name)

func _on_energy_regen_tick() -> void:
	# Sync energy with server
	if Session.is_authenticated and Network:
		var result = await Network.http_post("/api/v1/energy/sync", {})
		if result.success and result.data.has("current_energy"):
			State.update_energy(result.data.current_energy)

func _show_loading_overlay(show: bool) -> void:
	if loading_overlay:
		loading_overlay.visible = show
		if show and loading_spinner:
			# Start rotating spinner with code
			var tween = create_tween().set_loops()
			tween.tween_property(loading_spinner, "rotation", TAU, 1.0).from(0)
		elif not show and loading_spinner:
			# Stop rotation
			loading_spinner.rotation = 0

func _on_profile_check_timeout() -> void:
	print("[Main] Profile check timeout - verifying profile presence and session")
	# If the user is expected to be logged in but we have no player data, try fetching profile once, otherwise do nothing (do not force logout)
	if Session and Session.is_logged_in() and State.get_player_data().is_empty() and Network:
		var result = await Network.http_get(APIEndpoints.PLAYER_PROFILE)
		if result.success and result.data:
			State.load_player_data(result.data)
			print("[Main] Profile loaded during background check")
		else:
			print("[Main] Background profile fetch failed; no action taken per policy")
	else:
		print("[Main] No background action needed during profile check")
func _on_tolerance_decay_tick() -> void:
	# Sync tolerance with server
	if Session.is_authenticated and Network:
		var result = await Network.http_post("/api/v1/potion/tolerance-sync", {})
		if result.success and result.data.has("tolerance"):
			State.tolerance = result.data.tolerance

func _on_viewport_size_changed() -> void:
	call_deferred("_apply_ui_scale")

func _apply_ui_scale() -> void:
	# Disabled via flag
	if not UI_SCALING_ENABLED:
		return
	# Safety check: ensure scene tree and UI nodes are available
	if not is_inside_tree() or not screen_container:
		return
	
	# Compute scale relative to reference resolution
	var vp = get_viewport()
	if not vp:
		return
	var vp_size = vp.get_visible_rect().size
	if not vp_size or vp_size.x == 0 or vp_size.y == 0:
		return
	var sx = float(vp_size.x) / float(REFERENCE_WIDTH)
	var sy = float(vp_size.y) / float(REFERENCE_HEIGHT)
	var ui_scale = clamp(min(sx, sy), MIN_UI_SCALE, MAX_UI_SCALE)

	# Apply scale to screen container (Control node)
	if screen_container:
		screen_container.scale = Vector2(ui_scale, ui_scale)
	
	# Apply scale to HUD and dialog containers (CanvasLayer - scale children)
	if hud_container and hud_container.get_child_count() > 0:
		for child in hud_container.get_children():
			if child is Control:
				child.scale = Vector2(ui_scale, ui_scale)
	
	if dialog_container and dialog_container.get_child_count() > 0:
		for child in dialog_container.get_children():
			if child is Control:
				child.scale = Vector2(ui_scale, ui_scale)

	# Debug
	print("[Main] Applied UI scale:", ui_scale, "viewport:", vp_size)

## Input handling
func _input(event: InputEvent) -> void:
	# Android back button
	if event.is_action_pressed("ui_cancel"):
		if not go_back():
			# Ask to exit
			var dialog_scene = load("res://scenes/ui/dialogs/ConfirmDialog.tscn")
			if dialog_scene:
				show_dialog(dialog_scene, {
					"title": "Çıkış",
					"message": "Oyundan çıkmak istiyor musunuz?",
					"on_confirm": Callable(self, "quit_game")
				})

func go_to_login() -> void:
	show_screen("login", false)

func logout() -> void:
	print("[Main] Logging out...")
	
	# Session.logout() çağırırsa State.logout() da çağrılır
	if Session:
		Session.logout()
	else:
		# Session yoksa State'i manuel temizle
		if State:
			State.logout()
	
	# Go to login
	show_screen("login", false)
	print("[Main] Logged out successfully")

func quit_game() -> void:
	get_tree().quit()
