extends Node
## Scene Manager - Scene transition with loading screens
## Singleton autoload: Scenes

signal scene_loading(scene_name: String)
signal scene_loaded(scene_name: String)
signal scene_transition_started()
signal scene_transition_finished()

## Scene paths
const SCENES = {
	"splash": "res://scenes/main/SplashScreen.tscn",
	"login": "res://scenes/main/LoginScreen.tscn",
	"home": "res://scenes/main/HomeScreen.tscn",
	"inventory": "res://scenes/ui/screens/InventoryScreen.tscn",
	"market": "res://scenes/ui/screens/MarketScreen.tscn",
	"quest": "res://scenes/ui/screens/QuestScreen.tscn",
	"dungeon": "res://scenes/gameplay/DungeonScene.tscn",
	"pvp": "res://scenes/ui/screens/PvPScreen.tscn",
	"guild": "res://scenes/ui/screens/GuildScreen.tscn",
	"profile": "res://scenes/ui/screens/ProfileScreen.tscn",
	"settings": "res://scenes/ui/screens/SettingsScreen.tscn",
	"hospital": "res://scenes/ui/screens/HospitalScreen.tscn"
}

var current_scene: Node = Node.new()
var current_scene_name: String = ""
var _loading: bool = false

func _ready() -> void:
	print("[Scenes] Initializing...")
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)

## Change scene with fade transition
func change_scene(scene_name: String, transition_duration: float = 0.3) -> void:
	if _loading:
		print("[Scenes] Already loading a scene")
		return
	
	if not SCENES.has(scene_name):
		print("[Scenes] Scene not found: %s" % scene_name)
		return
	
	_loading = true
	scene_transition_started.emit()
	scene_loading.emit(scene_name)
	
	print("[Scenes] Loading scene: %s" % scene_name)
	
	# Fade out
	await _fade_out(transition_duration)
	
	# Free current scene
	if current_scene:
		current_scene.queue_free()
		await current_scene.tree_exited
	
	# Load new scene
	var scene_path = SCENES[scene_name]
	var new_scene = load(scene_path).instantiate()
	
	# Add to tree
	get_tree().root.add_child(new_scene)
	get_tree().current_scene = new_scene
	current_scene = new_scene
	current_scene_name = scene_name
	
	# Fade in
	await _fade_in(transition_duration)
	
	_loading = false
	scene_loaded.emit(scene_name)
	scene_transition_finished.emit()
	
	print("[Scenes] Scene loaded: %s" % scene_name)
	
	# Track screen view
	Telemetry.track_screen(scene_name)

## Reload current scene
func reload_current_scene() -> void:
	if current_scene_name.is_empty():
		return
	change_scene(current_scene_name)

## Get scene node by name
func get_scene(scene_name: String):
	if scene_name == current_scene_name:
		return current_scene
	return null

## Check if scene is loading
func is_loading() -> bool:
	return _loading

## Fade out effect
func _fade_out(duration: float) -> void:
	var fade_layer = _create_fade_layer()
	var color_rect = fade_layer.get_node("ColorRect")
	
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 1.0, duration)
	await tween.finished

## Fade in effect
func _fade_in(duration: float) -> void:
	var fade_layer = get_tree().root.get_node_or_null("FadeLayer")
	if fade_layer:
		var color_rect = fade_layer.get_node("ColorRect")
		
		var tween = create_tween()
		tween.tween_property(color_rect, "modulate:a", 0.0, duration)
		await tween.finished
		
		fade_layer.queue_free()

## Create fade layer
func _create_fade_layer() -> CanvasLayer:
	var existing = get_tree().root.get_node_or_null("FadeLayer")
	if existing:
		return existing
	
	var layer = CanvasLayer.new()
	layer.name = "FadeLayer"
	layer.layer = 100
	
	var color_rect = ColorRect.new()
	color_rect.name = "ColorRect"
	color_rect.color = Color.BLACK
	color_rect.modulate.a = 0.0
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	layer.add_child(color_rect)
	get_tree().root.add_child(layer)
	
	return layer

## Preload scene (for faster loading)
func preload_scene(scene_name: String) -> void:
	if not SCENES.has(scene_name):
		return
	
	var scene_path = SCENES[scene_name]
	ResourceLoader.load_threaded_request(scene_path)

## Check if scene exists
func has_scene(scene_name: String) -> bool:
	return SCENES.has(scene_name)
