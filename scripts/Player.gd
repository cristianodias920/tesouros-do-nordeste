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
@export var cam_limit_top: int = -1600
@export var cam_limit_bottom: int = 1000
# Caminho do fundo (2.5D): área desenhada em escala menor, longe à direita
@export var fundo_cam_left: int = 40000
@export var fundo_cam_right: int = 60000
@export var fundo_cam_top: int = -900
@export var fundo_cam_bottom: int = 640
@export var fundo_queda_y: float = 700.0
const FUNDO_ESCALA: float = 0.6
const MAIN_QUEDA_Y: float = 850.0  # linha da água dos rios (superfície ~808)

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
var k: float = 1.0          # escala do mundo atual (1 = trilha principal, 0.6 = fundo)
var no_fundo: bool = false
var viajando: bool = false  # atravessando portal
var portal_cooldown: float = 0.0
var trot_phase: float = 0.0
var fade_rect: ColorRect
var afogando: bool = false   # animação de queda na água
const RAPADURA_DUR: float = 6.0
var brilho: Sprite2D            # aura dourada da rapadura
var faiscas: CPUParticles2D     # estrelinhas da rapadura
var rapadura_t: float = 0.0

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
	_apply_camera_limits()
	# Cortina para a transição dos portais
	var cl := CanvasLayer.new()
	cl.layer = 40
	add_child(cl)
	_criar_efeito_rapadura()
	fade_rect = ColorRect.new()
	fade_rect.color = Color(1.0, 0.95, 0.82, 0.0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	cl.add_child(fade_rect)

func _apply_camera_limits() -> void:
	if no_fundo:
		camera.limit_left = fundo_cam_left
		camera.limit_right = fundo_cam_right
		camera.limit_top = fundo_cam_top
		camera.limit_bottom = fundo_cam_bottom
	else:
		camera.limit_left = cam_limit_left
		camera.limit_right = cam_limit_right
		camera.limit_top = cam_limit_top
		camera.limit_bottom = cam_limit_bottom
	camera.position = Vector2(0, -120 * k)

func set_fundo(valor: bool) -> void:
	no_fundo = valor
	k = FUNDO_ESCALA if valor else 1.0
	apply_character_scale()
	_apply_camera_limits()
	# Névoa leve no Zeca quando está longe, na serra
	modulate = Color(0.9, 0.93, 1.0) if valor else Color(1, 1, 1)
	GameManager.mundo_mudou.emit(valor)

func apply_character_scale() -> void:
	if is_mounted:
		# Montado: escala 0.63 (~1.3x da altura do Zeca a pé)
		animated_sprite.scale = Vector2(0.63, 0.63) * k
		animated_sprite.position = Vector2(0, -134) * k
		if collision_shape and collision_shape.shape:
			collision_shape.shape.size = Vector2(75, 210) * k
			collision_shape.position = Vector2(0, -105) * k
		if kick_area:
			kick_area.position = Vector2(-70 * facing_direction, -70) * k
			kick_area.scale = Vector2(k, k)
	else:
		# A pé: escala 0.45 (~205 px de altura)
		animated_sprite.scale = Vector2(0.45, 0.45) * k
		animated_sprite.position = Vector2(0, -110) * k
		if collision_shape and collision_shape.shape:
			collision_shape.shape.size = Vector2(55, 180) * k
			collision_shape.position = Vector2(0, -90) * k

func _physics_process(delta: float) -> void:
	if viajando or afogando:
		velocity = Vector2.ZERO
		return
	if portal_cooldown > 0:
		portal_cooldown -= delta
	if GameManager.is_level_ended:
		if GameManager.is_game_over:
			# Game over: Zeca fica parado atrás da tela de FIM DA AVENTURA
			velocity = Vector2.ZERO
			return
		# Fase concluída: continua com gravidade para não sair voando
		velocity.x = move_toward(velocity.x, 0, DECEL_GROUND * k * delta)
		if not is_on_floor():
			velocity.y = move_toward(velocity.y, MAX_FALL_SPEED * k, GRAVITY_DOWN * k * delta)
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
		_efeito_rapadura(delta)
	elif ferradura_timer > 0:
		ferradura_timer -= delta
		animated_sprite.modulate = Color(1.1, 1.2, 1.35)
	else:
		animated_sprite.modulate = Color(1, 1, 1)
	if rapadura_timer <= 0 and brilho.visible:
		brilho.visible = false
		faiscas.emitting = false

	# Gravidade assimétrica (queda 1.6x mais rápida)
	if not is_on_floor():
		var current_gravity = GRAVITY_UP if velocity.y < 0 else GRAVITY_DOWN
		velocity.y = move_toward(velocity.y, MAX_FALL_SPEED * k, current_gravity * k * delta)
	else:
		coyote_timer = COYOTE_TIME_MAX
		if is_mounted:
			can_double_jump = true

	# Buffer de pulo
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_MAX

	# Execução de pulo no chão ou coyote time
	if jump_buffer_timer > 0 and (is_on_floor() or coyote_timer > 0):
		execute_jump(JUMP_VELOCITY * k)
	# Pulo duplo quando montado
	elif jump_buffer_timer > 0 and is_mounted and can_double_jump and not is_on_floor():
		can_double_jump = false
		execute_jump(DOUBLE_JUMP_VELOCITY * k)

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
	target_speed *= k

	var current_accel: float = (ACCEL_GROUND if is_on_floor() else ACCEL_AIR) * k
	var current_decel: float = (DECEL_GROUND if is_on_floor() else DECEL_AIR) * k
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
		if abs(velocity.x) > 10.0 * k:
			facing_direction = sign(velocity.x)
		animated_sprite.flip_h = (facing_direction < 0)
		if is_mounted:
			kick_area.position.x = -70 * facing_direction * k

	# Câmera com olhar à frente (look-ahead ~180 px)
	target_cam_offset_x = facing_direction * 180.0 * k if abs(velocity.x) > 20 * k else 0.0
	camera.offset.x = lerp(camera.offset.x, target_cam_offset_x, 4.0 * delta)

	update_animation()

	floor_snap_length = 16.0 * k
	var vy_before: float = velocity.y
	move_and_slide()
	_check_slide_collisions(vy_before)

	# Queda no rio ou abismo
	if global_position.y > (fundo_queda_y if no_fundo else MAIN_QUEDA_Y):
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
	velocity.y = BOUNCE_VELOCITY * k
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
		elif abs(velocity.x) > 20.0 * k:
			target_anim = "mounted_walk"
			target_speed_scale = clamp(abs(velocity.x) / (MOUNTED_SPEED * k), 0.6, 1.4)
		else:
			target_anim = "mounted_idle"
	else:
		if not is_on_floor():
			if velocity.y < 0:
				target_anim = "jump"
			else:
				target_anim = "fall"
		elif abs(velocity.x) > 20.0 * k:
			target_anim = "walk"
			target_speed_scale = clamp(abs(velocity.x) / (WALK_SPEED * k), 0.6, 1.4)
		else:
			target_anim = "idle"

	animated_sprite.speed_scale = target_speed_scale
	if animated_sprite.animation != target_anim:
		animated_sprite.play(target_anim)
	_trot_bob(target_anim == "mounted_walk" or target_anim == "walk", target_speed_scale)

func _trot_bob(ativo: bool, vel: float) -> void:
	# Trote do Faísca: sobe e desce a cada passada e balança de leve (em px da textura)
	if ativo:
		var montado: bool = animated_sprite.animation == "mounted_walk"
		# 2 passadas por ciclo de animação (6 quadros)
		var fps: float = 12.0 if montado else 13.0
		trot_phase += get_physics_process_delta_time() * (fps / 6.0) * vel * TAU
		var b: float = abs(sin(trot_phase))
		animated_sprite.offset = Vector2(0, -b * (12.0 if montado else 7.0))
		animated_sprite.rotation = sin(trot_phase) * (0.022 if montado else 0.012) * (-1.0 if animated_sprite.flip_h else 1.0)
	else:
		animated_sprite.offset = animated_sprite.offset.lerp(Vector2.ZERO, 0.3)
		animated_sprite.rotation = lerp(animated_sprite.rotation, 0.0, 0.3)

func mount_faisca() -> void:
	is_mounted = true
	GameManager.is_mounted = true
	apply_character_scale()
	AudioManager.play_sfx("mount")
	AudioManager.play_sfx("zurro")
	VoiceLines.say("faisca_monta", true)
	# pulinho para a sela + poeira
	_poeira(global_position, 1.0)
	var s0: Vector2 = animated_sprite.scale
	var t := create_tween()
	animated_sprite.offset = Vector2(0, -90)
	animated_sprite.scale = s0 * Vector2(0.92, 1.08)
	t.tween_property(animated_sprite, "offset", Vector2.ZERO, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(animated_sprite, "scale", s0 * Vector2(1.08, 0.92), 0.06)
	t.tween_property(animated_sprite, "scale", s0, 0.1)

func _poeira(pos: Vector2, forca: float) -> void:
	var pp := CPUParticles2D.new()
	pp.one_shot = true
	pp.amount = int(18 * forca)
	pp.lifetime = 0.6
	pp.explosiveness = 0.95
	pp.direction = Vector2(0, -1)
	pp.spread = 80.0
	pp.initial_velocity_min = 80.0 * k
	pp.initial_velocity_max = 220.0 * k
	pp.gravity = Vector2(0, 260.0 * k)
	pp.scale_amount_min = 6.0 * k
	pp.scale_amount_max = 14.0 * k
	pp.color = Color(0.78, 0.64, 0.45, 0.8)
	var g := Gradient.new()
	g.set_color(0, Color(0.85, 0.72, 0.52, 0.85))
	g.set_color(1, Color(0.85, 0.72, 0.52, 0.0))
	pp.color_ramp = g
	pp.z_index = 12
	get_parent().add_child(pp)
	pp.global_position = pos
	pp.emitting = true
	get_tree().create_timer(1.2).timeout.connect(pp.queue_free)

func _respingo(pos: Vector2, forca: float) -> void:
	# gotas de água subindo e caindo + anel de espuma
	for layer_i in 2:
		var pp := CPUParticles2D.new()
		pp.one_shot = true
		pp.amount = int((34 if layer_i == 0 else 16) * forca)
		pp.lifetime = 0.9 if layer_i == 0 else 0.5
		pp.explosiveness = 0.92
		pp.direction = Vector2(0, -1)
		pp.spread = 35.0 if layer_i == 0 else 85.0
		pp.initial_velocity_min = (420.0 if layer_i == 0 else 120.0) * k * forca
		pp.initial_velocity_max = (760.0 if layer_i == 0 else 260.0) * k * forca
		pp.gravity = Vector2(0, 1500.0 * k)
		pp.scale_amount_min = (5.0 if layer_i == 0 else 10.0) * k
		pp.scale_amount_max = (11.0 if layer_i == 0 else 20.0) * k
		var g := Gradient.new()
		g.set_color(0, Color(0.85, 0.96, 1.0, 0.95))
		g.set_color(1, Color(0.55, 0.85, 0.95, 0.0))
		pp.color_ramp = g
		pp.z_index = 12
		get_parent().add_child(pp)
		pp.global_position = pos
		pp.emitting = true
		get_tree().create_timer(1.5).timeout.connect(pp.queue_free)

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
	velocity = Vector2(knock_dir * 420.0, -600.0) * k
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

	velocity.y = -600.0 * k
	invincibility_timer = 1.2
	if is_mounted:
		# Igual ao dano de inimigo: o Faísca foge assustado e o Zeca não perde coração
		dismount_scared()
		return
	GameManager.take_damage()

func respawn_fall() -> void:
	# Cair no rio: respingo, o Zeca (e o Faísca) afundam se debatendo,
	# depois perde 1 coração e volta ao último checkpoint (ou ao início)
	if GameManager.is_level_ended or falling_handled:
		return
	falling_handled = true
	afogando = true
	velocity = Vector2.ZERO
	invincibility_timer = 3.0
	AudioManager.play_sfx("splash")
	if is_mounted:
		AudioManager.play_sfx("zurro")
	VoiceLines.say("agua_cai", true)
	var agua_y: float = (812.0 if not no_fundo else global_position.y)
	global_position.y = agua_y + 10.0 * k
	_respingo(Vector2(global_position.x, agua_y), 1.5 if is_mounted else 1.0)
	animated_sprite.visible = true
	animated_sprite.speed_scale = 1.0
	animated_sprite.play("mounted_jump" if is_mounted else "fall")
	var t := create_tween()
	# debate-se balançando e afunda sumindo
	t.tween_method(_afundar, 0.0, 1.0, 1.0)
	t.tween_property(fade_rect, "color:a", 1.0, 0.3)
	t.tween_callback(_fim_da_queda)

func _afundar(v: float) -> void:
	animated_sprite.rotation = sin(v * 26.0) * 0.18 * (1.0 - v)
	animated_sprite.offset = Vector2(0, v * 150.0)
	animated_sprite.modulate.a = 1.0 - v * 0.95

func _fim_da_queda() -> void:
	var alive: bool = GameManager.take_damage()
	animated_sprite.rotation = 0.0
	animated_sprite.offset = Vector2.ZERO
	animated_sprite.modulate.a = 1.0
	afogando = false
	falling_handled = false
	if alive:
		respawn_at_checkpoint()
		var t := create_tween()
		t.tween_property(fade_rect, "color:a", 0.0, 0.35)
	else:
		# Sem corações: some na água e o FIM DA AVENTURA aparece
		visible = false
		velocity = Vector2.ZERO
		fade_rect.color.a = 0.0

func respawn_at_checkpoint() -> void:
	if GameManager.has_checkpoint:
		if GameManager.checkpoint_fundo != no_fundo:
			set_fundo(GameManager.checkpoint_fundo)
		global_position = GameManager.checkpoint_pos
	else:
		if no_fundo:
			set_fundo(false)
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
	rapadura_timer = RAPADURA_DUR
	AudioManager.play_sfx("powerup")
	VoiceLines.say("rapadura", true)
	brilho.visible = true
	faiscas.emitting = true
	# estouro de estrelas ao pegar
	var pp: CPUParticles2D = faiscas.duplicate()
	pp.one_shot = true
	pp.explosiveness = 1.0
	pp.amount = 40
	pp.initial_velocity_min = 220.0 * k
	pp.initial_velocity_max = 420.0 * k
	get_parent().add_child(pp)
	pp.global_position = global_position + Vector2(0, -110 * k)
	pp.emitting = true
	get_tree().create_timer(1.5).timeout.connect(pp.queue_free)

# ---- Rapadura: aura dourada pulsante + estrelinhas; pisca rápido no fim ----
func _criar_efeito_rapadura() -> void:
	var gt := GradientTexture2D.new()
	gt.width = 256; gt.height = 256
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5); gt.fill_to = Vector2(0.5, 0.0)
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.86, 0.3, 0.85))
	g.set_color(1, Color(1.0, 0.7, 0.1, 0.0))
	gt.gradient = g
	brilho = Sprite2D.new()
	brilho.texture = gt
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	brilho.material = m
	brilho.z_index = -1
	brilho.visible = false
	add_child(brilho)
	faiscas = CPUParticles2D.new()
	faiscas.amount = 26
	faiscas.lifetime = 0.8
	faiscas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	faiscas.emission_rect_extents = Vector2(70, 100)
	faiscas.direction = Vector2(0, -1)
	faiscas.spread = 180.0
	faiscas.initial_velocity_min = 30.0
	faiscas.initial_velocity_max = 90.0
	faiscas.gravity = Vector2(0, -40)
	faiscas.scale_amount_min = 5.0
	faiscas.scale_amount_max = 11.0
	var gs := Gradient.new()
	gs.set_color(0, Color(1.0, 1.0, 0.75, 1.0))
	gs.add_point(0.4, Color(1.0, 0.85, 0.25, 1.0))
	gs.set_color(gs.get_point_count() - 1, Color(1.0, 0.6, 0.1, 0.0))
	faiscas.color_ramp = gs
	faiscas.z_index = 3
	faiscas.emitting = false
	add_child(faiscas)

func _efeito_rapadura(delta: float) -> void:
	rapadura_t += delta
	var fim: bool = rapadura_timer < 1.8
	var pulso: float = 0.5 + 0.5 * sin(rapadura_t * (22.0 if fim else 9.0))
	var dourado := Color(1.75, 1.45, 0.45).lerp(Color(2.1, 1.8, 0.8), pulso)
	if fim and fmod(rapadura_timer * 7.0, 1.0) < 0.45:
		dourado = Color(1, 1, 1)   # piscando normal/dourado perto do fim
	animated_sprite.modulate = dourado
	var h: float = (125.0 if is_mounted else 105.0) * k
	brilho.position = Vector2(0, -h)
	var tam: float = (1.8 if is_mounted else 1.5) * k
	brilho.scale = Vector2.ONE * tam * (0.92 + 0.16 * pulso)
	brilho.modulate.a = (0.55 + 0.45 * pulso) * (0.4 if dourado == Color(1, 1, 1) else 1.0)
	faiscas.position = Vector2(0, -h)
	faiscas.emission_rect_extents = Vector2(90 if is_mounted else 60, 100) * k
	faiscas.scale_amount_min = 5.0 * k
	faiscas.scale_amount_max = 11.0 * k

func apply_ferradura() -> void:
	# A Ferradura só protege montado (ver hit_by_spikes); sem gema extra
	ferradura_timer = 10.0
	AudioManager.play_sfx("powerup")

# ---- Portais (caminho do fundo na Serra) ----
func entrar_portal(destino: Vector2, fundo: bool) -> void:
	if viajando or portal_cooldown > 0 or GameManager.is_level_ended:
		return
	viajando = true
	AudioManager.play_sfx("powerup")
	var s0: Vector2 = animated_sprite.scale
	var t := create_tween()
	t.tween_property(fade_rect, "color:a", 1.0, 0.35)
	t.parallel().tween_property(animated_sprite, "scale", s0 * 0.5, 0.35)
	t.tween_callback(func():
		set_fundo(fundo)
		global_position = destino
		velocity = Vector2.ZERO
		camera.offset.x = 0.0
		invincibility_timer = max(invincibility_timer, 1.0)
		camera.reset_smoothing()
		var s1: Vector2 = animated_sprite.scale
		animated_sprite.scale = s1 * (1.6 if fundo else 0.6)
		var t2 := create_tween()
		t2.tween_property(fade_rect, "color:a", 0.0, 0.35)
		t2.parallel().tween_property(animated_sprite, "scale", s1, 0.35)
		t2.tween_callback(func():
			viajando = false
			portal_cooldown = 0.8))
