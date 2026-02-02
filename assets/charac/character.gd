extends Node2D

class BoneData:
	var bone: Bone2D
	var base_pos: Vector2
	var base_rot: float
	var phase: Vector3
	var speed: Vector3
	var secondary: bool
	var sec_pos: Vector2
	var sec_rot: float

class SpriteData:
	var sprite: Sprite2D
	var base_modulate: Color

## --- Genel Ayarlar ---
@export var skeleton_path: NodePath = NodePath("Skeleton2D")
@export var enable_idle_variation := true
@export var enable_secondary_motion := true
@export var enable_glow := true
@export var enable_fake_lighting := true
@export var enable_camera_breath := true

## --- Micro Motion (tüm Bone2D) ---
@export_range(0.0, 3.0, 0.01) var micro_pos_x_amp := 0.6
@export_range(0.0, 3.0, 0.01) var micro_pos_y_amp := 0.8
@export_range(0.0, 0.2, 0.001) var micro_rot_amp := 0.03
@export_range(0.1, 5.0, 0.01) var micro_speed_min := 0.6
@export_range(0.1, 5.0, 0.01) var micro_speed_max := 1.3

## --- Secondary Motion (kanat/pelerin/saç) ---
@export var secondary_bone_keywords: PackedStringArray = [
	"kanat", "pelerin", "saç", "sac", "wing", "cape", "hair"
]
@export_range(0.01, 1.0, 0.01) var secondary_lag := 0.18

## --- Random Idle Variation ---
@export var idle_profile_pos_muls: Array[Vector2] = [
	Vector2(1.0, 1.0),
	Vector2(0.9, 1.05),
	Vector2(1.1, 0.95)
]
@export var idle_profile_rot_muls: Array[float] = [1.0, 0.85, 1.15]
@export var idle_profile_speed_muls: Array[float] = [1.0, 0.9, 1.1]
@export_range(1.0, 30.0, 0.1) var idle_switch_min := 6.0
@export_range(1.0, 30.0, 0.1) var idle_switch_max := 12.0
@export_range(0.1, 5.0, 0.05) var idle_blend_time := 1.6

## --- Glow / Aura ---
@export_range(0.0, 0.5, 0.001) var glow_strength := 0.08
@export_range(0.1, 5.0, 0.01) var glow_speed := 1.2

## --- Fake Lighting ---
@export_range(0.0, 0.5, 0.001) var top_light_strength := 0.12
@export_range(0.0, 0.5, 0.001) var side_light_strength := 0.06
@export_range(0.0, 0.8, 0.001) var light_dir_wobble := 0.18
@export_range(0.1, 3.0, 0.01) var light_dir_speed := 0.6

## --- Camera Breath ---
@export_range(0.0, 0.05, 0.0001) var cam_zoom_amount := 0.008
@export_range(0.1, 5.0, 0.01) var cam_zoom_speed := 0.8
@export_range(0.0, 5.0, 0.01) var cam_breath_y := 1.2
@export_range(0.1, 5.0, 0.01) var cam_breath_speed := 0.7

var _time := 0.0
var _bones: Array[BoneData] = []
var _sprites: Array[SpriteData] = []
var _min_y := 0.0
var _max_y := 1.0
var _min_x := 0.0
var _max_x := 1.0
var _camera: Camera2D
var _cam_base_pos := Vector2.ZERO
var _cam_base_zoom := Vector2.ONE

var _current_profile := 0
var _target_profile := 0
var _profile_blend := 1.0
var _profile_timer := 0.0
var _next_switch := 8.0

func _ready() -> void:
	randomize()
	_cache_nodes()
	_schedule_next_profile()

func _process(delta: float) -> void:
	_time += delta
	_update_profile(delta)
	_update_bones(delta)
	_update_visuals()
	_update_camera()

func _cache_nodes() -> void:
	_bones.clear()
	_sprites.clear()

	var skeleton: Node = get_node_or_null(skeleton_path) as Node
	if skeleton != null:
		_gather_bones_and_sprites(skeleton)

	_cache_sprite_bounds()

	var cameras: Array[Node] = find_children("", "Camera2D", true, false)
	if cameras.size() > 0:
		_camera = cameras[0] as Camera2D
		if _camera != null:
			_cam_base_pos = _camera.position
			_cam_base_zoom = _camera.zoom

func _gather_bones_and_sprites(root: Node) -> void:
	var queue: Array[Node] = [root]
	while queue.size() > 0:
		var node: Node = queue.pop_front() as Node
		if node is Bone2D:
			_register_bone(node)
		elif node is Sprite2D:
			_register_sprite(node)
		for child: Node in node.get_children():
			if child != null:
				queue.append(child)

func _register_bone(bone: Bone2D) -> void:
	var data: BoneData = BoneData.new()
	data.bone = bone
	data.base_pos = bone.position
	data.base_rot = bone.rotation
	data.phase = Vector3(randf_range(0.0, TAU), randf_range(0.0, TAU), randf_range(0.0, TAU))
	data.speed = Vector3(
		randf_range(micro_speed_min, micro_speed_max),
		randf_range(micro_speed_min, micro_speed_max),
		randf_range(micro_speed_min, micro_speed_max)
	)
	data.secondary = _is_secondary_bone(bone.name)
	data.sec_pos = bone.position
	data.sec_rot = bone.rotation
	_bones.append(data)

func _register_sprite(sprite: Sprite2D) -> void:
	var data: SpriteData = SpriteData.new()
	data.sprite = sprite
	data.base_modulate = sprite.modulate
	_sprites.append(data)

func _cache_sprite_bounds() -> void:
	_min_y = INF
	_max_y = -INF
	_min_x = INF
	_max_x = -INF
	for data: SpriteData in _sprites:
		var sprite: Sprite2D = data.sprite
		var pos: Vector2 = sprite.global_position
		_min_y = min(_min_y, pos.y)
		_max_y = max(_max_y, pos.y)
		_min_x = min(_min_x, pos.x)
		_max_x = max(_max_x, pos.x)
	if _min_y == INF:
		_min_y = 0.0
		_max_y = 1.0
		_min_x = 0.0
		_max_x = 1.0

func _is_secondary_bone(name_text: String) -> bool:
	var lower: String = name_text.to_lower()
	for key: String in secondary_bone_keywords:
		if lower.find(key) != -1:
			return true
	return false

func _schedule_next_profile() -> void:
	_next_switch = randf_range(idle_switch_min, idle_switch_max)

func _update_profile(delta: float) -> void:
	if not enable_idle_variation:
		_current_profile = 0
		_target_profile = 0
		_profile_blend = 1.0
		return

	_profile_timer += delta
	if _profile_timer >= _next_switch:
		_profile_timer = 0.0
		_schedule_next_profile()
		_target_profile = randi_range(0, _profile_count() - 1)
		if _target_profile == _current_profile:
			_target_profile = (_current_profile + 1) % _profile_count()
		_profile_blend = 0.0

	if _profile_blend < 1.0:
		_profile_blend = min(1.0, _profile_blend + delta / max(idle_blend_time, 0.001))
		if _profile_blend >= 1.0:
			_current_profile = _target_profile

func _profile_count() -> int:
	return int(max(1, min(
		min(idle_profile_pos_muls.size(), idle_profile_rot_muls.size()),
		idle_profile_speed_muls.size()
	)))

func _profile_pos_mul() -> Vector2:
	var count: int = _profile_count()
	var a: Vector2 = idle_profile_pos_muls[min(_current_profile, count - 1)]
	var b: Vector2 = idle_profile_pos_muls[min(_target_profile, count - 1)]
	return a.lerp(b, _profile_blend)

func _profile_rot_mul() -> float:
	var count: int = _profile_count()
	var a: float = idle_profile_rot_muls[min(_current_profile, count - 1)]
	var b: float = idle_profile_rot_muls[min(_target_profile, count - 1)]
	return lerpf(a, b, _profile_blend)

func _profile_speed_mul() -> float:
	var count: int = _profile_count()
	var a: float = idle_profile_speed_muls[min(_current_profile, count - 1)]
	var b: float = idle_profile_speed_muls[min(_target_profile, count - 1)]
	return lerpf(a, b, _profile_blend)

func _update_bones(delta: float) -> void:
	var pos_amp: Vector2 = Vector2(micro_pos_x_amp, micro_pos_y_amp) * _profile_pos_mul()
	var rot_amp: float = micro_rot_amp * _profile_rot_mul()
	var speed_mul: float = _profile_speed_mul()

	var lag: float = max(secondary_lag, 0.001)
	var sec_blend: float = 1.0 - exp(-delta / lag)

	for data: BoneData in _bones:
		var bone: Bone2D = data.bone
		var phase: Vector3 = data.phase
		var speed: Vector3 = data.speed * speed_mul

		var offset: Vector2 = Vector2(
			sin(_time * speed.x + phase.x) * pos_amp.x,
			sin(_time * speed.y + phase.y) * pos_amp.y
		)
		var rot: float = sin(_time * speed.z + phase.z) * rot_amp

		var base_pos: Vector2 = data.base_pos
		var base_rot: float = data.base_rot
		var target_pos: Vector2 = base_pos + offset
		var target_rot: float = base_rot + rot

		if enable_secondary_motion and data.secondary:
			data.sec_pos = data.sec_pos.lerp(target_pos, sec_blend)
			data.sec_rot = lerp_angle(data.sec_rot, target_rot, sec_blend)
			bone.position = data.sec_pos
			bone.rotation = data.sec_rot
		else:
			bone.position = target_pos
			bone.rotation = target_rot

func _update_visuals() -> void:
	var glow_mult: float = 1.0
	if enable_glow:
		glow_mult = 1.0 + sin(_time * glow_speed) * glow_strength

	var x_range: float = max(_max_x - _min_x, 0.001)
	var y_range: float = max(_max_y - _min_y, 0.001)
	var center_x: float = (_min_x + _max_x) * 0.5

	var light_dir: Vector2 = Vector2(0.0, -1.0)
	if enable_fake_lighting:
		light_dir = light_dir.rotated(sin(_time * light_dir_speed) * light_dir_wobble)

	for data: SpriteData in _sprites:
		var sprite: Sprite2D = data.sprite
		var base: Color = data.base_modulate

		var lighting_mult: float = 1.0
		if enable_fake_lighting:
			var pos: Vector2 = sprite.global_position
			var y_norm: float = clamp(((_max_y - pos.y) / y_range), 0.0, 1.0)
			var x_norm: float = clamp((pos.x - center_x) / x_range, -1.0, 1.0)
			lighting_mult += y_norm * top_light_strength
			lighting_mult += x_norm * light_dir.x * side_light_strength

		var color: Color = base * (glow_mult * lighting_mult)
		color.a = base.a
		sprite.modulate = color

func _update_camera() -> void:
	if not enable_camera_breath:
		return
	if _camera == null:
		return

	var zoom_mul: float = 1.0 + sin(_time * cam_zoom_speed) * cam_zoom_amount
	_camera.zoom = _cam_base_zoom * zoom_mul
	_camera.position = _cam_base_pos + Vector2(0.0, sin(_time * cam_breath_speed) * cam_breath_y)
