extends Control
class_name CharacterPaperdoll

## Character Paperdoll - 3D Visual representation
## Shows character with equipped items using 3D models in a SubViewport

signal paperdoll_clicked()

# 3D Scene Components
var viewport_container: SubViewportContainer
var viewport: SubViewport
var world_3d: Node3D
var character_node: Node3D
var camera: Camera3D
var light: DirectionalLight3D
var animation_player: AnimationPlayer

# Asset Paths
# Asset Paths
const SKELETON_PATH = "res://assets/KayKit_Skeletons_1.1_FREE/characters/gltf/Skeleton_Minion.glb"
# Using the animation file that contains Idle/Walk
const ANIM_PATH = "res://assets/KayKit_Skeletons_1.1_FREE/Animations/gltf/Rig_Medium/Rig_Medium_General.glb"

func _ready():
	_setup_3d_scene()
	
	# Connect to equipment changes
	var equipment_manager = get_node_or_null("/root/Equipment")
	if equipment_manager:
		equipment_manager.equipment_changed.connect(_on_equipment_changed)
	
	# Initial load
	_update_all_visuals()

func _setup_3d_scene() -> void:
	# 1. Create SubViewportContainer (if not exists)
	var old_layers = get_node_or_null("Layers")
	if old_layers:
		old_layers.visible = false
	
	viewport_container = SubViewportContainer.new()
	viewport_container.name = "ModelViewportContainer"
	viewport_container.stretch = true
	viewport_container.layout_mode = 1
	viewport_container.anchors_preset = Control.PRESET_FULL_RECT
	viewport_container.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(viewport_container)
	
	# 2. Create SubViewport
	viewport = SubViewport.new()
	viewport.name = "ModelViewport"
	viewport.transparent_bg = true
	viewport.handle_input_locally = false
	viewport.gui_disable_input = true
	viewport.size = Vector2(512, 512)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport_container.add_child(viewport)
	
	# 3. Create 3D World Root
	world_3d = Node3D.new()
	world_3d.name = "World3D"
	viewport.add_child(world_3d)
	
	# 4. Create Camera - ZOOMED IN (Z reduced from 3.5 to 2.2)
	camera = Camera3D.new()
	camera.name = "PaperdollCamera"
	camera.position = Vector3(0, 1.3, 2.2) # Closer to camera = larger size
	camera.rotation_degrees.x = -10 # Slightly less tilted
	world_3d.add_child(camera)
	
	# 5. Create Light
	light = DirectionalLight3D.new()
	light.name = "Sun"
	light.rotation_degrees = Vector3(-45, 45, 0)
	light.light_energy = 1.5 # Brighter
	light.shadow_enabled = true
	world_3d.add_child(light)
	
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.3, 0.3, 0.3)
	camera.environment = env
	
	# 6. Instantiate Character
	_load_character_model()

func _load_character_model() -> void:
	if not FileAccess.file_exists(SKELETON_PATH):
		print("[CharacterPaperdoll] Error: Skeleton model not found at ", SKELETON_PATH)
		return
		
	var scene = load(SKELETON_PATH)
	if scene:
		character_node = scene.instantiate()
		character_node.name = "CharacterModel"
		world_3d.add_child(character_node)
		
		# Center the model - Moved UP (from -1.0 to -0.6)
		character_node.position = Vector3(0, -0.6, 0)
		character_node.rotation_degrees.y = 20
		
		_setup_animation()
	else:
		print("[CharacterPaperdoll] Failed to load character scene")

func _setup_animation() -> void:
	if not character_node: return
	
	# 1. Try internal animation player first
	animation_player = character_node.get_node_or_null("AnimationPlayer")
	
	# 2. If not found or empty, try loading external animations
	if not animation_player:
		print("[CharacterPaperdoll] No internal AnimationPlayer, creating one...")
		animation_player = AnimationPlayer.new()
		animation_player.name = "AnimationPlayer"
		character_node.add_child(animation_player)
	
	# Load external animation library
	if FileAccess.file_exists(ANIM_PATH):
		print("[CharacterPaperdoll] Loading external animations from: ", ANIM_PATH)
		var anim_scene = load(ANIM_PATH)
		if anim_scene:
			var anim_instance = anim_scene.instantiate()
			var ext_anim_player = anim_instance.get_node_or_null("AnimationPlayer")
			if ext_anim_player:
				var lib = ext_anim_player.get_animation_library("")
				# Add 'Dance' or 'Idle' from external lib to our player
				var found_anim = false
				
				# List to check priority
				var target_anims = ["Dance", "Dance_A", "Idle"]
				
				for target in target_anims:
					if lib.has_animation(target):
						var anim = lib.get_animation(target)
						anim.loop_mode = Animation.LOOP_LINEAR
						
						var library = AnimationLibrary.new()
						library.add_animation(target, anim)
						
						if not animation_player.has_animation_library(""):
							animation_player.add_animation_library("", library)
						else:
							animation_player.get_animation_library("").add_animation(target, anim)
							
						print("[CharacterPaperdoll] Added external animation: ", target)
						animation_player.play(target)
						found_anim = true
						break # Play the first one found (Priority: Dance -> Idle)
				
				if not found_anim:
					# Fallback to copy all just in case
					for anim_name in lib.get_animation_list():
						print("[CharacterPaperdoll] Found other animation: ", anim_name)
						# Could add logic here to grab whatever is available
				
			anim_instance.queue_free() # Cleanup
	
	# If nothing playing yet
	if not animation_player.is_playing():
		if animation_player.has_animation("Dance"):
			animation_player.play("Dance")
		elif animation_player.has_animation("Idle"):
			animation_player.play("Idle")
		else:
			print("[CharacterPaperdoll] No suitable animation found, falling back to tween")
			# Fallback tween
			var tween = create_tween()
			tween.set_loops()
			tween.tween_property(character_node, "rotation_degrees:y", 380.0, 2.0).as_relative()

func _on_equipment_changed(slot: String, item: ItemData):
	print("[CharacterPaperdoll] Equipment changed: ", slot, " -> ", item.name if item else "none")
	# TODO: Implement 3D Equipment Attachment
	# This requires 3D models for items or attaching sprites to bones.
	# For now, we just have the base skeleton.
	pass

func _update_all_visuals():
	# Refetch everything
	pass

func _gui_input(event: InputEvent):
	# Forward clicks to signal
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		paperdoll_clicked.emit()
	
	# Allow rotating the model with drag
	if event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_LEFT:
		if character_node:
			character_node.rotate_y(deg_to_rad(event.relative.x * 0.5))
