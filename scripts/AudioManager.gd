extends Node

# Gerenciador global de áudio (SFX e BGM)
var sound_enabled: bool = true
var music_player: AudioStreamPlayer
var sfx_players: Dictionary = {}
var music_started: bool = false

var sound_paths = {
	"jump": "res://audio/jump.wav",
	"gem": "res://audio/gem.wav",
	"crate": "res://audio/crate_hit.wav",
	"powerup": "res://audio/powerup.wav",
	"mount": "res://audio/mount.wav",
	"kick": "res://audio/kick.wav",
	"hurt": "res://audio/hurt.wav",
	"checkpoint": "res://audio/checkpoint.wav",
	"splash": "res://audio/splash.wav",
	"victory": "res://audio/victory.wav"
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	music_player.volume_db = -10.0
	add_child(music_player)
	
	var music_stream: AudioStream = null
	if ResourceLoader.exists("res://audio/bgm_forro.ogg"):
		music_stream = load("res://audio/bgm_forro.ogg")
	elif ResourceLoader.exists("res://audio/bgm_forro.wav"):
		music_stream = load("res://audio/bgm_forro.wav")

	if music_stream:
		if music_stream is AudioStreamOggVorbis:
			(music_stream as AudioStreamOggVorbis).loop = true
		elif music_stream is AudioStreamWAV:
			(music_stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
		music_player.stream = music_stream

	for sfx_name in sound_paths:
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		p.volume_db = -3.0
		add_child(p)
		if ResourceLoader.exists(sound_paths[sfx_name]):
			p.stream = load(sound_paths[sfx_name])
		sfx_players[sfx_name] = p

func _input(event: InputEvent) -> void:
	if not music_started:
		if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
			start_music()

func start_music() -> void:
	if music_started:
		return
	music_started = true
	if sound_enabled and music_player and music_player.stream:
		music_player.play()

func play_sfx(sfx_name: String) -> void:
	if not sound_enabled:
		return
	if sfx_players.has(sfx_name) and sfx_players[sfx_name].stream:
		sfx_players[sfx_name].play()

func toggle_sound() -> bool:
	sound_enabled = not sound_enabled
	if sound_enabled:
		if music_player and not music_player.playing and music_started:
			music_player.play()
	else:
		if music_player:
			music_player.stop()
		for p in sfx_players.values():
			p.stop()
	return sound_enabled
