extends Node

# Gerenciador global do jogo (Vidas, Tesouros, Checkpoint, Estado)
signal lives_changed(current_lives: int)
signal gems_changed(current_gems: int, total_gems: int)
signal checkpoint_activated(pos: Vector2)
signal level_completed
signal game_over
signal player_respawned

const TOTAL_GEMS: int = 19
const MAX_LIVES: int = 3

var current_lives: int = 3
var collected_gems: int = 0
var checkpoint_pos: Vector2 = Vector2.ZERO
var has_checkpoint: bool = false
var is_mounted: bool = false
var is_level_ended: bool = false
var is_game_over: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	reset_game()

func reset_game() -> void:
	current_lives = MAX_LIVES
	collected_gems = 0
	checkpoint_pos = Vector2.ZERO
	has_checkpoint = false
	is_mounted = false
	is_level_ended = false
	is_game_over = false
	lives_changed.emit(current_lives)
	gems_changed.emit(collected_gems, TOTAL_GEMS)

func refill_lives() -> void:
	current_lives = MAX_LIVES
	lives_changed.emit(current_lives)

func add_gem() -> void:
	collected_gems += 1
	AudioManager.play_sfx("gem")
	gems_changed.emit(collected_gems, TOTAL_GEMS)

func heal() -> void:
	if current_lives < MAX_LIVES:
		current_lives += 1
		lives_changed.emit(current_lives)
	AudioManager.play_sfx("powerup")

func take_damage() -> bool:
	if is_level_ended:
		return current_lives > 0
	current_lives = max(current_lives - 1, 0)
	AudioManager.play_sfx("hurt")
	lives_changed.emit(current_lives)
	if current_lives <= 0:
		is_level_ended = true
		is_game_over = true
		game_over.emit()
		return false
	return true

func set_checkpoint(pos: Vector2) -> void:
	if not has_checkpoint or checkpoint_pos != pos:
		checkpoint_pos = pos
		has_checkpoint = true
		AudioManager.play_sfx("checkpoint")
		checkpoint_activated.emit(pos)

func complete_level() -> void:
	if not is_level_ended:
		is_level_ended = true
		AudioManager.play_sfx("victory")
		level_completed.emit()
