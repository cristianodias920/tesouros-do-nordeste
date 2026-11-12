extends CharacterBody2D
class_name Player

# Constantes de movimentação e física
const WALK_SPEED: float = 290.0
const MOUNTED_SPEED: float = 380.0
const RAPADURA_SPEED_BOOST: float = 110.0
const ACCELERATION: float = 1500.0
const FRICTION: float = 1600.0
const GRAVITY: float = 1150.0
const JUMP_VELOCITY: float = -510.0
const BOUNCE_VELOCITY: float = -440.0
const COYOTE_TIME_MAX: float = 0.12
const JUMP_BUFFER_MAX: float = 0.12

# Estados
var is_mounted: bool = false
var is_coice: bool = false
var can_double_jump: bool = false
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var invincibility_timer: float = 0.0
var rapadura_timer: float = 0.0
var ferradura_timer: float = 0.0
var facing_direction: float = 1.0
var spawn_position: Vector2 = Vector2.ZERO

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var kick_area: Area2D = $KickArea
@onready var kick_collision: CollisionShape2D = $KickArea/CollisionShape2D

func _ready() -> void:
	spawn_position = global_position
	kick_collision.disabled = true
	animated_sprite.animation_finished.connect(_on_animation_finished)
	GameManager.checkpoint_activated.connect(_on_checkpoint_activated)
	apply_character_scale()

func apply_character_scale() -> void:
	if is_mounted:
		# Montado: altura ~ 1.3x do Zeca a pé
		animated_sprite.scale = Vector2(0.48, 0.48)
		collision_shape.shape.size = Vector2(64, 150)
		collision_shape.position = Vector2(0, -75)
		kick_area.position = Vector2(-45 * facing_direction, -50)
	else:
		animated_sprite.scale = Vector2(0.36, 0.36)
		collision_shape.shape.size = Vector2(46, 130)
		collision_shape.position = Vector2(0, -65)

func _physics_process(delta: float) -> void:
	if GameManager.is_level_ended:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		move_and_slide()
		return

	# Atualiza timers
	if coyote_timer > 0:
		coyote_timer -= delta
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	if invincibility_timer > 0:
		invincibility_timer -= delta
		# Piscar sprite durante invencibilidade
		animated_sprite.visible = fmod(invincibility_timer * 10.0, 1.0) > 0.3
	else:
		animated_sprite.visible = true

	# Power-ups timers
	if rapadura_timer > 0:
		rapadura_timer -= delta
		# Brilho dourado
		animated_sprite.modulate = Color(1.3, 1.15, 0.6)
	elif ferradura_timer > 0:
		ferradura_timer -= delta
		# Brilho prateado / ferro
		animated_sprite.modulate = Color(1.1, 1.2, 1.3)
	else:
		animated_sprite.modulate = Color(1, 1, 1)

	# Gravidade
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		coyote_timer = COYOTE_TIME_MAX
		if is_mounted:
			can_double_jump = true

	# Buffer de pulo
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_MAX

	# Execução de pulo (chão ou coyote time)
	if jump_buffer_timer > 0 and (is_on_floor() or coyote_timer > 0):
		execute_jump()
	# Pulo duplo quando montado
	elif jump_buffer_timer > 0 and is_mounted and can_double_jump and not is_on_floor():
		can_double_jump = false
		execute_jump()

	# Pulo de altura variável: soltar o botão corta subida
	if Input.is_action_just_released("jump") and velocity.y < -150.0:
		velocity.y = -150.0

	# Ação de coice (montado)
	if Input.is_action_just_pressed("action") and is_mounted and not is_coice:
		execute_coice()

	# Movimento horizontal
	var input_x: float = Input.get_axis("move_left", "move_right")
	
	if input_x != 0:
		facing_direction = sign(input_x)
		animated_sprite.flip_h = (facing_direction < 0)
		kick_area.position.x = -45 * facing_direction

	var target_speed: float = MOUNTED_SPEED if is_mounted else WALK_SPEED
	if rapadura_timer > 0:
		target_speed += RAPADURA_SPEED_BOOST

	if input_x != 0:
		velocity.x = move_toward(velocity.x, input_x * target_speed, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

	# Atualiza animação
	update_animation()

	# Executa movimento com Floor Snap para física estável
	floor_snap_length = 12.0
	move_and_slide()

	# Queda no rio ou abismo
	if global_position.y > 980:
		respawn_fall()

func execute_jump() -> void:
	velocity.y = JUMP_VELOCITY
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	AudioManager.play_sfx("jump")

func bounce() -> void:
	velocity.y = BOUNCE_VELOCITY
	AudioManager.play_sfx("jump")

func execute_coice() -> void:
	is_coice = true
	animated_sprite.play("coice")
	AudioManager.play_sfx("kick")
	kick_collision.disabled = false
	# Desativa hitbox após 0.25s
	get_tree().create_timer(0.25).timeout.connect(func(): kick_collision.disabled = true)

func _on_animation_finished() -> void:
	if is_coice:
		is_coice = false
		kick_collision.disabled = true

func update_animation() -> void:
	if is_coice:
		return

	if is_mounted:
		if not is_on_floor():
			animated_sprite.play("mounted_jump")
		elif abs(velocity.x) > 15.0:
			animated_sprite.play("mounted_walk")
		else:
			animated_sprite.play("mounted_idle")
	else:
		if not is_on_floor():
			if velocity.y < 0:
				animated_sprite.play("jump")
			else:
				animated_sprite.play("fall")
		elif abs(velocity.x) > 15.0:
			animated_sprite.play("walk")
		else:
			animated_sprite.play("idle")

func mount_faisca() -> void:
	is_mounted = true
	GameManager.is_mounted = true
	apply_character_scale()
	AudioManager.play_sfx("mount")

func hit_by_enemy(from_pos: Vector2) -> void:
	if rapadura_timer > 0:
		return
	if invincibility_timer > 0:
		return

	if is_mounted:
		# Faísca foge assustado, Zeca continua a pé sem perder coração nesse golpe
		is_mounted = false
		GameManager.is_mounted = false
		apply_character_scale()
		invincibility_timer = 1.2
		AudioManager.play_sfx("mount") # som de desmonte / susto
		velocity = Vector2((global_position.x - from_pos.x) * 2.0, -250)
	else:
		var alive = GameManager.take_damage()
		if alive:
			invincibility_timer = 1.2
			var knock_dir = sign(global_position.x - from_pos.x)
			if knock_dir == 0:
				knock_dir = -facing_direction
			velocity = Vector2(knock_dir * 250.0, -280.0)

func hit_by_spikes() -> void:
	if ferradura_timer > 0 and is_mounted:
		return # Ferradura de ferro protege contra espinhos!
	if rapadura_timer > 0:
		return
	if invincibility_timer > 0:
		return

	var alive = GameManager.take_damage()
	if alive:
		invincibility_timer = 1.2
		velocity.y = -350.0

func respawn_fall() -> void:
	AudioManager.play_sfx("splash")
	var alive = GameManager.take_damage()
	if alive:
		if GameManager.has_checkpoint:
			global_position = GameManager.checkpoint_pos
		else:
			global_position = spawn_position
		velocity = Vector2.ZERO
		invincibility_timer = 1.0

func _on_checkpoint_activated(pos: Vector2) -> void:
	spawn_position = pos

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
