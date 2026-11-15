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
# Folha de buriti: depois de pegar no alto da torre, segurar PULAR caindo plana (só na área das nuvens)
# Agora a folha é um power-up do sistema de reserva (PowerUps): tem_folha = folha ativa
var tem_folha: bool:
	get:
		return PowerUps.esta_ativo("folha")
	set(v):
		if v:
			PowerUps.pegar("folha")
		else:
			PowerUps.remover("folha")
var planando: bool = false
# Chapéu de couro (power-up): arremessa com C / botão do chapéu, volta para a cabeça
const CHAPEU_RECARGA: float = 0.4      # fôlego depois que ele volta
const CHAPEU_REAPARECE: float = 2.0    # se perdeu (buraco/rio/portal), volta à cabeça nesse tempo
var chapeu_voando: Chapeu = null
var chapeu_recarga: float = 0.0
var chapeu_perdido_t: float = 0.0
var chapeu_cabeca: Sprite2D
var chapeu_cabeca_t: float = 0.0
var chapeu_arremessos: int = 0
var folha_sprite: Sprite2D
const PLANAR_QUEDA: float = 230.0      # velocidade máxima de queda planando
const NUVENS_X0: float = 9800.0
const NUVENS_X1: float = 17000.0
const FUNDO_ZOOM: float = 1.2          # câmera mais perto no caminho do fundo (Zeca maior na tela)

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
	_criar_folha()
	_criar_chapeu_cabeca()
	GameManager.continuou_do_checkpoint.connect(_continuar_do_checkpoint)

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
	camera.zoom = Vector2.ONE * (FUNDO_ZOOM if no_fundo else 1.0)

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
	_tempo_do_chapeu(delta)   # conta mesmo afogando/no portal: o chapéu perdido volta em ~2 s
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
		_atualizar_chapeu_cabeca(delta)
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
		_planar(delta)
	else:
		_parar_planar()
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

	# Power-ups: usar (C) e trocar com a reserva (V)
	_processar_poderes(delta)

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
	_limitar_olhar_a_frente()

	update_animation()
	_atualizar_chapeu_cabeca(delta)

	floor_snap_length = 16.0 * k
	var vy_before: float = velocity.y
	move_and_slide()
	_check_slide_collisions(vy_before)

	# Queda no rio ou abismo
	if global_position.y > (fundo_queda_y if no_fundo else MAIN_QUEDA_Y):
		respawn_fall()

func _limitar_olhar_a_frente() -> void:
	# O "olhar à frente" (offset) não respeita os limites da câmera: sem isto, no fim da
	# fase a tela mostrava um bloco vazio depois do último chão.
	var meia: float = get_viewport_rect().size.x * 0.5 / camera.zoom.x
	var cx: float = global_position.x + camera.position.x
	var centro: float = clamp(cx, camera.limit_left + meia, camera.limit_right - meia)
	var off_min: float = (camera.limit_left + meia) - centro
	var off_max: float = (camera.limit_right - meia) - centro
	if off_min <= off_max:
		camera.offset.x = clamp(camera.offset.x, off_min, off_max)

func na_area_das_nuvens() -> bool:
	# A fase pode dizer onde dá para planar (ex.: cena de teste do chapéu); senão, as nuvens de Corrente
	var cena := get_tree().current_scene
	if cena and cena.has_method("pode_planar"):
		return cena.pode_planar(self)
	return not no_fundo and global_position.x > NUVENS_X0 and global_position.x < NUVENS_X1

func _planar(_delta: float) -> void:
	if tem_folha and velocity.y > 0.0 and Input.is_action_pressed("jump") and na_area_das_nuvens() and not GameManager.is_level_ended:
		if not planando:
			planando = true
			AudioManager.play_sfx("planar")
			folha_sprite.visible = true
			folha_sprite.scale = Vector2.ONE * 0.12
			var t := create_tween()
			t.tween_property(folha_sprite, "scale", Vector2.ONE * 0.6 * k, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		velocity.y = min(velocity.y, PLANAR_QUEDA * k)
		folha_sprite.rotation = sin(Time.get_ticks_msec() * 0.006) * 0.08 + velocity.x * 0.0002
		folha_sprite.position = Vector2(0, (-290.0 if is_mounted else -225.0) * k)
	else:
		_parar_planar()

func _parar_planar() -> void:
	if planando:
		planando = false
		var t := create_tween()
		t.tween_property(folha_sprite, "scale", Vector2.ONE * 0.05, 0.12)
		t.tween_callback(func(): if not planando: folha_sprite.visible = false)

func _criar_folha() -> void:
	folha_sprite = Sprite2D.new()
	if ResourceLoader.exists("res://sprites/items/folha_buriti.png"):
		folha_sprite.texture = load("res://sprites/items/folha_buriti.png")
	folha_sprite.offset = Vector2(0, 60)   # segura pelo cabo, acima da cabeça
	folha_sprite.visible = false
	folha_sprite.z_index = 1
	add_child(folha_sprite)

func pegar_folha() -> void:
	PowerUps.pegar("folha")
	AudioManager.play_sfx("powerup")

# ---- Power-ups com reserva (estilo Super Mario World) ----
func pegar_poder(id: String) -> void:
	PowerUps.pegar(id)
	AudioManager.play_sfx("powerup")
	var hud = get_tree().get_first_node_in_group("hud")
	if id == "folha":
		if hud and hud.has_method("mostrar_dica_folha"):
			hud.mostrar_dica_folha()
	elif id == "chapeu":
		chapeu_cabeca_t = 0.0
		if hud and hud.has_method("mostrar_dica_chapeu"):
			hud.mostrar_dica_chapeu()

func _tempo_do_chapeu(delta: float) -> void:
	if chapeu_recarga > 0.0:
		chapeu_recarga -= delta
	if chapeu_perdido_t > 0.0:
		chapeu_perdido_t -= delta
		if chapeu_perdido_t <= 0.0:
			_chapeu_reaparece()

func _processar_poderes(_delta: float) -> void:
	if Input.is_action_just_pressed("trocar_poder"):
		trocar_poder()
	if Input.is_action_just_pressed("poder"):
		usar_poder()

func trocar_poder() -> bool:
	# Com o chapéu no ar não troca (ele precisa voltar para a cabeça primeiro)
	if chapeu_voando != null or chapeu_perdido_t > 0.0:
		return false
	if PowerUps.trocar():
		AudioManager.play_sfx("poder_troca")
		_parar_planar()
		chapeu_cabeca_t = 0.0
		return true
	return false

func usar_poder() -> bool:
	if GameManager.is_level_ended or viajando or afogando:
		return false
	if PowerUps.esta_ativo("chapeu"):
		return lancar_chapeu()
	return false

func chapeu_pronto() -> bool:
	return PowerUps.esta_ativo("chapeu") and chapeu_voando == null and chapeu_recarga <= 0.0 and chapeu_perdido_t <= 0.0

func lancar_chapeu() -> bool:
	if not chapeu_pronto():
		return false
	var c := Chapeu.new()
	c.iniciar(self, facing_direction)
	get_parent().add_child(c)
	chapeu_voando = c
	chapeu_arremessos += 1
	AudioManager.play_sfx("chapeu_lanca")
	# gesto de arremesso: Zeca dá um tranco para a frente
	var s0: Vector2 = animated_sprite.scale
	var t := create_tween()
	t.tween_property(animated_sprite, "scale", s0 * Vector2(1.08, 0.94), 0.06)
	t.tween_property(animated_sprite, "scale", s0, 0.1)
	return true

func ponto_do_chapeu() -> Vector2:
	# onde o chapéu encantado flutua: logo acima do chapéu de palha do Zeca
	return global_position + Vector2(facing_direction * 6.0, -318.0 if is_mounted else -262.0) * k

func ponto_de_arremesso() -> Vector2:
	# sai da mão do Zeca, na altura da cintura (montado: da altura do lombo), na direção em que ele olha
	return global_position + Vector2(facing_direction * 50.0, -125.0 if is_mounted else -110.0) * k

func linha_de_queda() -> float:
	return fundo_queda_y if no_fundo else MAIN_QUEDA_Y

func chapeu_voltou(c: Node) -> void:
	if c == chapeu_voando:
		chapeu_voando = null
	chapeu_recarga = CHAPEU_RECARGA
	chapeu_cabeca_t = 0.0
	AudioManager.play_sfx("chapeu_volta")

func chapeu_perdido(c: Node) -> void:
	if c == chapeu_voando:
		chapeu_voando = null
	chapeu_perdido_t = CHAPEU_REAPARECE

func _chapeu_reaparece() -> void:
	chapeu_perdido_t = 0.0
	chapeu_recarga = 0.0
	chapeu_cabeca_t = 0.0
	if PowerUps.esta_ativo("chapeu"):
		AudioManager.play_sfx("chapeu_volta")
		_poeira_dourada(ponto_do_chapeu())

func _criar_chapeu_cabeca() -> void:
	chapeu_cabeca = Sprite2D.new()
	chapeu_cabeca.texture = load("res://sprites/powerups/chapeu.png")
	chapeu_cabeca.z_index = 2
	chapeu_cabeca.visible = false
	add_child(chapeu_cabeca)

func chapeu_na_cabeca() -> bool:
	return chapeu_cabeca != null and chapeu_cabeca.visible

func _atualizar_chapeu_cabeca(delta: float) -> void:
	var mostrar: bool = PowerUps.esta_ativo("chapeu") and chapeu_voando == null and chapeu_perdido_t <= 0.0 and not afogando
	chapeu_cabeca.visible = mostrar and visible
	if not mostrar:
		return
	chapeu_cabeca_t += delta
	# pousa com um quique e depois flutua de leve, brilhando
	var pouso: float = clamp(chapeu_cabeca_t / 0.25, 0.0, 1.0)
	var quique: float = (1.0 - pouso) * -26.0
	var flut: float = sin(chapeu_cabeca_t * 3.2) * 4.0
	chapeu_cabeca.position = (ponto_do_chapeu() - global_position) + Vector2(0, quique + flut) * k + animated_sprite.offset * animated_sprite.scale
	chapeu_cabeca.flip_h = facing_direction < 0
	chapeu_cabeca.rotation = sin(chapeu_cabeca_t * 2.1) * 0.05 + animated_sprite.rotation
	var base: float = 0.3 * k
	chapeu_cabeca.scale = Vector2.ONE * base * (1.0 + (1.0 - pouso) * 0.25)
	var b: float = 1.0 + 0.1 * (0.5 + 0.5 * sin(chapeu_cabeca_t * 5.0))
	chapeu_cabeca.modulate = Color(b, b, b, 0.75 if invincibility_timer > 0.0 and not animated_sprite.visible else 1.0)

func _poeira_dourada(pos: Vector2) -> void:
	var pp: CPUParticles2D = faiscas.duplicate()
	pp.one_shot = true
	pp.explosiveness = 1.0
	pp.amount = 24
	pp.initial_velocity_min = 120.0 * k
	pp.initial_velocity_max = 260.0 * k
	get_parent().add_child(pp)
	pp.global_position = pos
	pp.emitting = true
	get_tree().create_timer(1.2).timeout.connect(pp.queue_free)

func _continuar_do_checkpoint() -> void:
	# depois do FIM DA AVENTURA: volta ao último checkpoint com os corações cheios
	visible = true
	afogando = false
	falling_handled = false
	viajando = false
	animated_sprite.rotation = 0.0
	animated_sprite.offset = Vector2.ZERO
	animated_sprite.modulate = Color(1, 1, 1, 1)
	fade_rect.color.a = 0.0
	respawn_at_checkpoint()
	invincibility_timer = 2.0

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
		# Faísca foge assustado (estilo Yoshi), para longe do perigo: o Zeca cai da sela
		# sem perder coração e pode montar de novo se alcançar o Faísca em uns 4 a 8 s
		dismount_scared(knock_dir, true)
	else:
		GameManager.take_damage() # com 0 corações o GameManager mostra o FIM DA AVENTURA

# fugir=true (golpe de inimigo/espinhos): o Faísca sai correndo assustado e dá para montar de novo
func dismount_scared(dir_fuga: float = 0.0, fugir: bool = false) -> void:
	is_mounted = false
	GameManager.is_mounted = false
	is_coice = false
	kick_collision.set_deferred("disabled", true)
	apply_character_scale()
	AudioManager.play_sfx("mount")
	if not fugir:
		return
	if dir_fuga == 0.0:
		dir_fuga = float(facing_direction)
	_soltar_faisca(dir_fuga)

func _soltar_faisca(dir_fuga: float) -> void:
	for f in get_tree().get_nodes_in_group("faisca_fugindo"):
		f.queue_free()
	var f := FaiscaFugindo.new()
	f.iniciar(self, dir_fuga)
	get_parent().add_child.call_deferred(f)   # pode vir de um sinal de física (golpe do inimigo)

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
		dismount_scared(float(facing_direction), true)
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

# Inimigo derrotado pela rapadura: nuvem de "puf" + estrelas douradas
var derrotados_rapadura: int = 0
func efeito_derrota(pos: Vector2) -> void:
	derrotados_rapadura += 1
	var nuvem := CPUParticles2D.new()
	nuvem.one_shot = true
	nuvem.amount = 30
	nuvem.lifetime = 0.55
	nuvem.explosiveness = 1.0
	nuvem.spread = 180.0
	nuvem.initial_velocity_min = 160.0
	nuvem.initial_velocity_max = 340.0
	nuvem.damping_min = 200.0; nuvem.damping_max = 300.0
	nuvem.scale_amount_min = 30.0; nuvem.scale_amount_max = 58.0
	var gn := Gradient.new()
	gn.set_color(0, Color(1, 1, 1, 0.95))
	gn.set_color(1, Color(0.95, 0.9, 0.8, 0.0))
	nuvem.color_ramp = gn
	nuvem.z_index = 14
	var est: CPUParticles2D = faiscas.duplicate()
	est.one_shot = true
	est.explosiveness = 1.0
	est.amount = 34
	est.emission_rect_extents = Vector2(20, 20)
	est.initial_velocity_min = 180.0
	est.initial_velocity_max = 380.0
	est.gravity = Vector2(0, 500)
	est.scale_amount_min = 10.0; est.scale_amount_max = 20.0
	est.z_index = 15
	for pp in [nuvem, est]:
		get_parent().add_child(pp)
		pp.global_position = pos + Vector2(0, -40)
		pp.emitting = true
		get_tree().create_timer(1.4).timeout.connect(pp.queue_free)

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
