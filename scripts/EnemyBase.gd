extends CharacterBody2D
class_name EnemyBase

@export var move_speed: float = 80.0
@export var patrol_distance: float = 200.0
@export var can_be_stomped: bool = true

var direction: float = -1.0
var start_x: float = 0.0
var is_dead: bool = false
var gravity: float = 980.0
var walk_frames: Array[Texture2D] = []
var anim_time: float = 0.0
var anim_frame_time: float = 0.18
var anim_paused: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var stomp_area: Area2D = $StompArea
@onready var hit_area: Area2D = $HitArea

func _ready() -> void:
	start_x = global_position.x
	if stomp_area:
		stomp_area.body_entered.connect(_on_stomp_entered)
	if hit_area:
		hit_area.body_entered.connect(_on_hit_entered)
	_setup_walk_frames()

func _setup_walk_frames() -> void:
	# Usa os quadros *_1.png e *_2.png para animar a caminhada
	if sprite == null or sprite.texture == null:
		return
	var path: String = sprite.texture.resource_path
	if path.ends_with("_1.png"):
		var path2 := path.replace("_1.png", "_2.png")
		if ResourceLoader.exists(path2):
			walk_frames = [sprite.texture, load(path2)]

func _animate_walk(delta: float) -> void:
	if anim_paused or walk_frames.size() < 2 or sprite == null:
		return
	anim_time += delta
	if anim_time >= anim_frame_time:
		anim_time = 0.0
		sprite.texture = walk_frames[1] if sprite.texture == walk_frames[0] else walk_frames[0]

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	patrol_movement(delta)
	move_and_slide()
	_animate_walk(delta)
	_check_player_contact(delta)

func _check_player_contact(delta: float) -> void:
	# Verificação contínua (não depende só do body_entered): dano robusto
	if is_dead:
		return
	for area in [stomp_area, hit_area]:
		if area == null:
			continue
		for b in area.get_overlapping_bodies():
			if b is Player:
				_resolve_contact(b as Player, delta)
				return

func _resolve_contact(p: Player, delta: float) -> void:
	if is_dead:
		return
	# Pisão: o Zeca está caindo e os pés (no quadro anterior) estavam acima da linha da cabeça
	var stomp_y: float = stomp_area.global_position.y + 10.0 if stomp_area else global_position.y - 40.0
	var feet_prev: float = p.global_position.y - p.velocity.y * delta
	var from_above: bool = p.velocity.y > 0.0 and feet_prev <= stomp_y + 4.0
	if from_above and can_be_stomped:
		p.bounce()
		die()
	else:
		# contato lateral, por baixo, ou pisão no tatu-bola: dano
		p.hit_by_enemy(global_position)

func patrol_movement(_delta: float) -> void:
	if abs(global_position.x - start_x) > patrol_distance or is_on_wall():
		direction *= -1.0
		start_x = global_position.x

	velocity.x = direction * move_speed
	if sprite:
		sprite.flip_h = (direction < 0) # as artes olham para a direita

func _on_stomp_entered(body: Node2D) -> void:
	if is_dead or not can_be_stomped:
		return
	if body is Player:
		_resolve_contact(body as Player, get_physics_process_delta_time())

func _on_hit_entered(body: Node2D) -> void:
	if is_dead:
		return
	if body is Player:
		_resolve_contact(body as Player, get_physics_process_delta_time())

func die() -> void:
	if is_dead:
		return
	is_dead = true
	AudioManager.play_sfx("hurt")
	collision_layer = 0
	collision_mask = 0
	if stomp_area:
		stomp_area.set_deferred("monitoring", false)
	if hit_area:
		hit_area.set_deferred("monitoring", false)

	# Efeito de derrota (achata e desaparece)
	var tween = create_tween()
	tween.tween_property(sprite, "scale:y", 0.05, 0.15)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)

func die_by_coice() -> void:
	if is_dead:
		return
	is_dead = true
	AudioManager.play_sfx("kick")
	collision_layer = 0
	collision_mask = 0
	if stomp_area:
		stomp_area.set_deferred("monitoring", false)
	if hit_area:
		hit_area.set_deferred("monitoring", false)

	# Lançado para o alto rodopiando
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y - 120.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "rotation", 4.0, 0.5)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
