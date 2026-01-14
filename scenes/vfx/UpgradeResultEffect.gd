extends Node2D

# Colors
const COLOR_SUCCESS = Color("#FFD84A") # Gold
const COLOR_FAIL = Color("#FF3A3A") # Red
const COLOR_BLESSED = Color("#7FD6FF") # Blue

@onready var frame_glow: Sprite2D = $FrameGlow
@onready var flash_light: PointLight2D = $FlashLight
@onready var ring_particles: CPUParticles2D = $RingParticles
@onready var item_icon: TextureRect = $ItemIcon

func _ready() -> void:
	# Initial state
	if frame_glow:
		frame_glow.modulate.a = 0
		frame_glow.scale = Vector2(0.9, 0.9)
	
	if flash_light:
		flash_light.energy = 0

func setup(icon_texture: Texture2D) -> void:
	if item_icon:
		item_icon.texture = icon_texture

func play_effect(is_success: bool) -> void:
	var target_color = COLOR_SUCCESS if is_success else COLOR_FAIL
	
	# Apply colors
	if frame_glow:
		frame_glow.modulate = target_color
		frame_glow.modulate.a = 0.1 # Start very faint
		
	if flash_light:
		flash_light.color = target_color
		flash_light.energy = 0.0 # Start dark
		
	# Ring particles (Explosion) removed as per request
	# if ring_particles:
	# 	ring_particles.color = target_color
	# 	ring_particles.emitting = true
		
	# Animation Sequence using Tween
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Ramp up effect over 7 seconds
	# Start soft, intensify until end
	
	# Glow: Ramp alpha from 0.1 to 1.0
	tween.tween_property(frame_glow, "modulate:a", 1.0, 6.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	
	# Glow: Scale UP over time (Make it bigger as requested)
	tween.tween_property(frame_glow, "scale", Vector2(1.3, 1.3), 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	
	# Light: Ramp intensity
	tween.tween_property(flash_light, "energy", 3.0, 7.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	
	# Cleanup after 7 seconds
	await get_tree().create_timer(7.0).timeout # Small buffer
	queue_free()
