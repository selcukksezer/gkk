extends Node
## Audio Manager - Music and sound effects management
## Singleton autoload: Audio

signal music_changed(track_name: String)
signal sfx_played(sfx_name: String)

## Audio buses
const BUS_MASTER = "Master"
const BUS_MUSIC = "Music"
const BUS_SFX = "SFX"

## Audio players pool
var _music_player: AudioStreamPlayer
var _music_tween: Tween
var _sfx_pool: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE = 10

## Current state
var current_music: String = ""
var _music_streams: Dictionary = {}
var _sfx_streams: Dictionary = {}

func _ready() -> void:
	print("[Audio] Initializing...")
	
	# Create music player
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = BUS_MUSIC
	add_child(_music_player)
	
	# Create SFX pool
	for i in range(SFX_POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = BUS_SFX
		add_child(player)
		_sfx_pool.append(player)
	
	# Load settings
	_load_audio_settings()
	
	# Preload common audio
	_preload_audio()

## Preload audio files
func _preload_audio() -> void:
	# Music tracks
	_register_music("menu", "res://assets/audio/music/menu_theme.ogg")
	_register_music("gameplay", "res://assets/audio/music/gameplay_ambient.ogg")
	_register_music("combat", "res://assets/audio/music/combat_theme.ogg")
	_register_music("town", "res://assets/audio/music/town_ambient.ogg")
	
	# SFX
	_register_sfx("button_click", "res://assets/audio/sfx/button_click.ogg")
	_register_sfx("success", "res://assets/audio/sfx/success.ogg")
	_register_sfx("error", "res://assets/audio/sfx/error.ogg")
	_register_sfx("coin", "res://assets/audio/sfx/coin.ogg")
	_register_sfx("item_pickup", "res://assets/audio/sfx/item_pickup.ogg")
	_register_sfx("potion_drink", "res://assets/audio/sfx/potion_drink.ogg")
	_register_sfx("notification", "res://assets/audio/sfx/notification.ogg")
	_register_sfx("sword_swing", "res://assets/audio/sfx/sword_swing.ogg")
	_register_sfx("hit", "res://assets/audio/sfx/hit.ogg")

## Register music
func _register_music(track_id: String, path: String) -> void:
	if ResourceLoader.exists(path):
		_music_streams[track_id] = load(path)

## Register SFX
func _register_sfx(sfx_id: String, path: String) -> void:
	if ResourceLoader.exists(path):
		_sfx_streams[sfx_id] = load(path)

## Play music with crossfade
func play_music(track_name: String, fade_duration: float = 1.0, _loop: bool = true) -> void:
	if track_name == current_music:
		return
	
	if not _music_streams.has(track_name):
		print("[Audio] Music not found: %s" % track_name)
		return
	
	var new_stream = _music_streams[track_name]
	
	# Fade out current music
	if _music_player.playing:
		if _music_tween:
			_music_tween.kill()
		
		_music_tween = create_tween()
		_music_tween.tween_property(_music_player, "volume_db", -80, fade_duration)
		await _music_tween.finished
	
	# Set new music
	_music_player.stream = new_stream
	_music_player.volume_db = -80
	_music_player.play()
	
	# Fade in
	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", 0, fade_duration)
	
	current_music = track_name
	music_changed.emit(track_name)
	print("[Audio] Playing music: %s" % track_name)

## Stop music
func stop_music(fade_duration: float = 1.0) -> void:
	if not _music_player.playing:
		return
	
	if _music_tween:
		_music_tween.kill()
	
	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", -80, fade_duration)
	await _music_tween.finished
	
	_music_player.stop()
	current_music = ""

## Play sound effect
func play_sfx(sfx_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if not _sfx_streams.has(sfx_name):
		print("[Audio] SFX not found: %s" % sfx_name)
		return
	
	# Find available player
	var player: AudioStreamPlayer
	for p in _sfx_pool:
		if not p.playing:
			player = p
			break
	
	# If all busy, use first one
	if not player:
		player = _sfx_pool[0]
		player.stop()
	
	player.stream = _sfx_streams[sfx_name]
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()
	
	sfx_played.emit(sfx_name)

## UI button click sound
func play_button_click() -> void:
	play_sfx("button_click")

## Success sound
func play_success() -> void:
	play_sfx("success")

## Error sound
func play_error() -> void:
	play_sfx("error", -5.0)

## Coin sound
func play_coin() -> void:
	play_sfx("coin")

## Item pickup sound
func play_item_pickup() -> void:
	play_sfx("item_pickup")

## Potion drink sound
func play_potion_drink() -> void:
	play_sfx("potion_drink")

## Notification sound
func play_notification() -> void:
	play_sfx("notification", -3.0)

## Combat sounds
func play_sword_swing() -> void:
	play_sfx("sword_swing", 0.0, randf_range(0.9, 1.1))

func play_hit() -> void:
	play_sfx("hit", 0.0, randf_range(0.95, 1.05))

## Set music volume
func set_music_volume(value: float) -> void:
	var db = linear_to_db(value)
	var idx = AudioServer.get_bus_index(BUS_MUSIC)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, db)
	else:
		print("[Audio] Warning: bus '%s' not found" % BUS_MUSIC)
	State.set_setting("music_volume", value)

## Set SFX volume
func set_sfx_volume(value: float) -> void:
	var db = linear_to_db(value)
	var idx = AudioServer.get_bus_index(BUS_SFX)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, db)
	else:
		print("[Audio] Warning: bus '%s' not found" % BUS_SFX)
	State.set_setting("sfx_volume", value)

## Get music volume
func get_music_volume() -> float:
	return State.get_setting("music_volume", 0.8)

## Get SFX volume
func get_sfx_volume() -> float:
	return State.get_setting("sfx_volume", 1.0)

## Load audio settings
func _load_audio_settings() -> void:
	set_music_volume(get_music_volume())
	set_sfx_volume(get_sfx_volume())
