extends CharacterBody2D
class_name Player

# Constantes de movimentação e física ajustadas (Seção 6)
const WALK_SPEED: float = 450.0
const MOUNTED_SPEED: float = 560.0
const RAPADURA_SPEED_BOOST: float = 120.0
const ACCEL_GROUND: float = 3000.0
const DECEL_GROUND: float = 3600.0
const ACCEL_AIR: float = 2400.0
const DECEL_AIR: float = 2880.0

const JUMP_VELOCITY: float = -1240.0
const DOUBLE_JUMP_VELOCITY: float = -1054.0 # 85% do primeiro
const BOUNCE_VELOCITY: float = -950.0
const GRAVITY_UP: float = 2950.0
const GRAVITY_DOWN: float = 4700.0 # 1.6x da gravidade de subida
const MAX_FALL_SPEED: float = 1800.0

const COYOTE_TIME_MAX: float = 0.1
const JUMP_BUFFER_MAX: float = 0.12

# Limites da câmera definidos por fase (no Inspector da instância do Player)
@export var cam_limit_left: int = 0
@export var cam_limit_right: int = 10000000

# Estados
var is_mounted: bool = false
var is_coice: bool = false
var can_double_jump: bool = false
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var invincibility_timer: float = 0.0
var lock_facing_timer: float = 0.0
var rapadura_timer: float = 0.0
var ferradura_timer: float = 0.0
var facing_direction: float = 1.0
var spawn_position: Vector2 = Vector2.ZERO
var target_cam_offset_x: float = 0.0
var falling_handled: bool = false
var floor_friction: float = 1.0 # 1.0 = chão normal; menor = escorregadio

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var kick_area: Area2D = $KickArea
@onready var kick_collision: CollisionShape2D = $KickArea/CollisionShape2D
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	spawn_position = global_position
	kick_collision.disabled = true
	animated_sprite.animation_finished.connect(_on_animation_finished)
	GameManager.checkpoint_activated.connect(_on_checkpoint_activated)
	apply_character_scale()
	camera.limit_left = cam_limit_left
	camera.limit_right = cam_limit_right

func apply_character_scale() -> void:
	if is_mounted:
		# Montado: escala 0.63 (~1.3x da altura do Zeca a pé)
		animated_sprite.scale = Vector2(0.63, 0.63)
		animated_sprite.position = Vector2(0, -134)
		if collision_shape and collision_shape.shape:
			collision_shape.shape.size = Vector2(75, 210)
			collision_shape.position = Vector2(0, -105)
		if kick_area:
			kick_area.position = Vector2(-70 * facing_direction, -70)
	else:
		# A pé: escala 0.45 (~205 px de altura)
		animated_sprite.scale = Vector2(0.45, 0.45)
		animated_sprite.position = Vector2(0, -110)
		if collision_shape and collision_shape.shape:
			collision_shape.shape.size = Vector2(55, 180)
			collision_shape.position = Vector2(0, -90)

func _physics_process(delta: float) -> void:
	if GameManager.is_level_ended:
		if GameManager.is_game_over:
			# Game over: Zeca fica parado atrás da tela de FIM DA AVENTURA
			velocity = Vector2.ZERO
			return
		# Fase concluída: continua com gravidade para não sair voando
		velocity.x = move_toward(velocity.x, 0, DECEL_GROUND * delta)
		if not is_on_floor():
			velocity.y = move_toward(velocity.y, MAX_FALL_SPEED, GRAVITY_DOWN * delta)
		else:
			velocity.y = 0.0
		update_animation()
		move_and_slide()
		return

	# Atualiza timers
	if coyote_timer > 0:
		coyote_timer -= delta
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	if invincibility_timer > 0:
		invincibility_timer -= delta
		animated_sprite.visible = fmod(invincibility_timer * 12.0, 1.0) > 0.35
	else:
		animated_sprite.visible = true
	if lock_facing_timer > 0:
		lock_facing_timer -= delta

	# Power-ups
	if rapadura_timer > 0:
		rapadura_timer -= delta
		animated_sprite.modulate = Color(1.35, 1.2, 0.5)
	elif ferradura_timer > 0:
		ferradura_timer -= delta
		animated_sprite.modulate = Color(1.1, 1.2, 1.35)
	else:
		animated_sprite.modulate = Color(1, 1, 1)

	# Gravidade assimétrica (queda 1.6x mais rápida)
	if not is_on_floor():
		var current_gravity = GRAVITY_UP if velocity.y < 0 else GRAVITY_DOWN
		velocity.y = move_toward(velocity.y, MAX_FALL_SPEED, current_gravity * delta)
	else:
		coyote_timer = COYOTE_TIME_MAX
		if is_mounted:
			can_double_jump = true

	# Buffer de pulo
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_MAX

	# Execução de pulo no chão ou coyote time
	if jump_buffer_timer > 0 and (is_on_floor() or coyote_timer > 0):
		execute_jump(JUMP_VELOCITY)
	# Pulo duplo quando montado
	elif jump_buffer_timer > 0 and is_mounted and can_double_jump and not is_on_floor():
		can_double_jump = false
		execute_jump(DOUBLE_JUMP_VELOCITY)

	# Pulo variável: soltar o botão corta subida (velocity.y * 0.45)
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.45

	# Ação de coice (montado)
	if Input.is_action_just_pressed("action") and is_mounted and not is_coice:
		execute_coice()

	# Movimento horizontal
	var input_x: float = Input.get_axis("move_left", "move_right")

	var target_speed: float = MOUNTED_SPEED if is_mounted else WALK_SPEED
	if rapadura_timer > 0:
		target_speed += RAPADURA_SPEED_BOOST

	var current_accel: float = ACCEL_GROUND if is_on_floor() else ACCEL_AIR
	var current_decel: float = DECEL_GROUND if is_on_floor() else DECEL_AIR
	if is_on_floor() and floor_friction < 1.0:
		# Pedra molhada: acelera e freia bem menos (escorrega)
		current_accel *= floor_friction
		current_decel *= floor_friction

	if input_x != 0:
		velocity.x = move_toward(velocity.x, input_x * target_speed, current_accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, current_decel * delta)

	# Atualiza direção para onde o personagem está virado (Seção 5)
	if lock_facing_timer <= 0:
		if abs(velocity.x) > 10.0:
			facing_direction = sign(velocity.x)
		animated_sprite.flip_h = (facing_direction < 0)
		if is_mounted:
			kick_area.position.x = -70 * facing_direction

	# Câmera com olhar à frente (look-ahead ~180 px)
	target_cam_offset_x = facing_direction * 180.0 if abs(velocity.x) > 20 else 0.0
	camera.offset.x = lerp(camera.offset.x, target_cam_offset_x, 4.0 * delta)

	update_animation()

	floor_snap_length = 16.0
	var vy_before: float = velocity.y
	move_and_slide()
	_check_slide_collisions(vy_before)

	# Queda no rio ou abismo
	if global_position.y > 960:
		respawn_fall()

func _check_slide_collisions(vy_before: float) -> void:
	# Cabeçada em caixote (por baixo) e atrito do chão atual
	var new_friction: float = 1.0
	for i in get_slide_collision_count():
		var c: KinematicCollision2D = get_slide_collision(i)
		var col = c.get_collider()
		if col == null:
			continue
		var n: Vector2 = c.get_normal()
		if n.y > 0.5 and vy_before < 0.0 and col.has_method("hit_from_below"):
			col.hit_from_below(self)
		elif n.y < -0.5 and col is Node and (col as Node).has_meta("atrito"):
			new_friction = float((col as Node).get_meta("atrito"))
	if is_on_floor():
		floor_friction = new_friction

func execute_jump(vel: float) -> void:
	velocity.y = vel
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	AudioManager.play_sfx("jump")

func bounce() -> void:
	velocity.y = BOUNCE_VELOCITY
	AudioManager.play_sfx("jump")

func execute_coice() -> void:
	is_coice = true
	lock_facing_timer = 0.25
	animated_sprite.speed_scale = 1.0
	animated_sprite.play("coice")
	AudioManager.play_sfx("kick")
	kick_collision.disabled = false
	get_tree().create_timer(0.28).timeout.connect(func(): kick_collision.disabled = true)

func _on_animation_finished() -> void:
	if is_coice:
		is_coice = false
		kick_collision.disabled = true

func update_animation() -> void:
	if is_coice:
		return

	var target_anim: String = ""
	var target_speed_scale: float = 1.0

	if is_mounted:
		if not is_on_floor():
			target_anim = "mounted_jump"
		elif abs(velocity.x) > 20.0:
			target_anim = "mounted_walk"
			target_speed_scale = clamp(abs(velocity.x) / MOUNTED_SPEED, 0.6, 1.4)
		else:
			target_anim = "mounted_idle"
	else:
		if not is_on_floor():
			if velocity.y < 0:
				target_anim = "jump"
			else:
				target_anim = "fall"
		elif abs(velocity.x) > 20.0:
			target_anim = "walk"
			target_speed_scale = clamp(abs(velocity.x) / WALK_SPEED, 0.6, 1.4)
		else:
			target_anim = "idle"

	animated_sprite.speed_scale = target_speed_scale
	if animated_sprite.animation != target_anim:
		animated_sprite.play(target_anim)

func mount_faisca() -> void:
	is_mounted = true
	GameManager.is_mounted = true
	apply_character_scale()
	AudioManager.play_sfx("mount")

func hit_by_enemy(from_pos: Vector2) -> void:
	if GameManager.is_level_ended:
		return
	if rapadura_timer > 0 or invincibility_timer > 0:
		return

	var knock_dir = sign(global_position.x - from_pos.x)
	if knock_dir == 0:
		knock_dir = -facing_direction

	lock_facing_timer = 0.25

	invincibility_timer = 1.2
	velocity = Vector2(knock_dir * 420.0, -600.0)
	if is_mounted:
		# Faísca foge assustado, Zeca continua a pé sem perder coração
		dismount_scared()
	else:
		GameManager.take_damage() # com 0 corações o GameManager mostra o FIM DA AVENTURA

func dismount_scared() -> void:
	is_mounted = false
	GameManager.is_mounted = false
	is_coice = false
	kick_collision.set_deferred("disabled", true)
	apply_character_scale()
	AudioManager.play_sfx("mount")

func hit_by_spikes() -> void:
	if GameManager.is_level_ended:
		return
	if ferradura_timer > 0 and is_mounted:
		return # Ferradura de ferro protege nos espinhos
	if rapadura_timer > 0 or invincibility_timer > 0:
		return

	velocity.y = -600.0
	invincibility_timer = 1.2
	if is_mounted:
		# Igual ao dano de inimigo: o Faísca foge assustado e o Zeca não perde coração
		dismount_scared()
		return
	GameManager.take_damage()

func respawn_fall() -> void:
	# Cair no rio: perde 1 coração e volta ao último checkpoint (ou ao início)
	if GameManager.is_level_ended or falling_handled:
		return
	falling_handled = true
	AudioManager.play_sfx("splash")
	var alive: bool = GameManager.take_damage()
	if alive:
		respawn_at_checkpoint()
	else:
		# Sem corações: some na água e o FIM DA AVENTURA aparece
		visible = false
		velocity = Vector2.ZERO
	falling_handled = false

func respawn_at_checkpoint() -> void:
	if GameManager.has_checkpoint:
		global_position = GameManager.checkpoint_pos
	else:
		global_position = spawn_position
	velocity = Vector2.ZERO
	invincibility_timer = 1.2
	camera.reset_smoothing()
	GameManager.player_respawned.emit()

func _on_checkpoint_activated(_pos: Vector2) -> void:
	pass # a posição fica guardada no GameManager.checkpoint_pos

func _on_kick_area_body_entered(body: Node2D) -> void:
	if body.has_method("die_by_coice"):
		body.die_by_coice()

func apply_cajuina() -> void:
	GameManager.heal()

func apply_rapadura() -> void:
	rapadura_timer = 6.0
	AudioManager.play_sfx("powerup")

func apply_ferradura() -> void:
	if is_mounted:
		ferradura_timer = 10.0
		AudioManager.play_sfx("powerup")
	else:
		GameManager.add_gem()
