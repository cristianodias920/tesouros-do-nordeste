extends CharacterBody2D
class_name FaiscaFugindo
# Faísca assustado (estilo Yoshi): quando o Zeca leva um golpe montado, ele cai da sela
# e o Faísca sai correndo em pânico, longe do Zeca, piscando. Se o Zeca encostar nele
# (andando ou pulando em cima) monta de novo. Depois de ~5,5 s ele vai embora correndo
# e some; volta no estábulo/checkpoint como antes.
# Respeita o cenário: vira em paredes e beiradas, pula buracos pequenos e inimigos,
# e nunca fica caindo para sempre (se cair num buraco/rio, some numa nuvem de poeira).

const TEMPO_FUGA: float = 5.5        # depois disso ele vai embora
const TEMPO_SUMIR: float = 1.1       # indo embora: some aos poucos
const TEMPO_SEM_MONTAR: float = 0.45 # logo depois do golpe não dá para montar
const VEL_FUGA: float = 360.0        # Zeca a pé anda 450: dá para alcançar
const VEL_SUSTO: float = 560.0
const VEL_EMBORA: float = 720.0
const GRAVIDADE: float = 3600.0
const PULO: float = -1150.0
const ALCANCE_X: float = 120.0
const ALCANCE_Y: float = 170.0

var zeca: Node2D
var k: float = 1.0
var dir: float = 1.0
var t: float = 0.0
var t_virada: float = 0.0     # trava para não ficar virando sem parar
var t_olhar: float = 1.4      # de vez em quando para e olha para trás (dá chance de pegar)
var parado: float = 0.0
var estado: String = "fugindo"   # fugindo / embora / pego
var y_chao: float = 0.0
var t_no_ar: float = 0.0
var no_chao_antes: bool = false
var sprite: Sprite2D
var halo: Sprite2D
var aviso: Label
var suor: CPUParticles2D
var poeira: CPUParticles2D
var zurro: AudioStreamPlayer
var fase_galope: float = 0.0
var montou: bool = false
var foi_embora: bool = false
var motivo_saida: String = ""

func iniciar(p: Node2D, dir_fuga: float) -> void:
	zeca = p
	k = p.k
	dir = dir_fuga if dir_fuga != 0.0 else 1.0
	z_index = p.z_index
	collision_layer = 0
	collision_mask = 1
	floor_snap_length = 14.0 * k
	floor_max_angle = deg_to_rad(50)
	global_position = p.global_position
	y_chao = global_position.y
	velocity = Vector2(dir * VEL_SUSTO * k, -820.0 * k)   # pulo de susto
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(110, 150) * k
	cs.shape = sh
	cs.position = Vector2(0, -75) * k
	add_child(cs)
	sprite = Sprite2D.new()
	sprite.texture = load("res://sprites/faisca/faisca_solo.png")
	sprite.scale = Vector2(0.56, 0.56) * k
	sprite.offset = Vector2(0, -182)   # pés no chão
	# halo claro em volta para destacar o Faísca do cenário (bom no celular)
	halo = Sprite2D.new()
	halo.texture = sprite.texture
	halo.offset = sprite.offset
	halo.scale = Vector2(1.07, 1.05)
	halo.modulate = Color(3.0, 2.8, 2.0, 0.55)
	halo.show_behind_parent = true
	sprite.add_child(halo)
	add_child(sprite)
	_criar_efeitos()
	add_to_group("faisca_fugindo")
	GameManager.player_respawned.connect(_sumir_ja)

func _criar_efeitos() -> void:
	# "!" de susto em cima da cabeça, grande para ler no celular
	aviso = Label.new()
	aviso.text = "!"
	var ls := LabelSettings.new()
	ls.font_size = int((150 if GameManager.celular else 110) * k)
	ls.font_color = Color(1.0, 0.86, 0.2)
	ls.outline_size = int(16 * k)
	ls.outline_color = Color(0.35, 0.12, 0.02)
	aviso.label_settings = ls
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.size = Vector2(240, 190) * k
	aviso.position = Vector2(-120, -420) * k
	aviso.pivot_offset = Vector2(120, 150) * k
	add_child(aviso)
	# gotas de suor
	suor = CPUParticles2D.new()
	suor.amount = 10
	suor.lifetime = 0.6
	suor.position = Vector2(30, -200) * k
	suor.direction = Vector2(0, -1)
	suor.spread = 70.0
	suor.initial_velocity_min = 120.0 * k
	suor.initial_velocity_max = 220.0 * k
	suor.gravity = Vector2(0, 900.0 * k)
	suor.scale_amount_min = 6.0 * k
	suor.scale_amount_max = 11.0 * k
	var g := Gradient.new()
	g.set_color(0, Color(0.7, 0.92, 1.0, 1.0))
	g.set_color(1, Color(0.5, 0.8, 1.0, 0.0))
	suor.color_ramp = g
	add_child(suor)
	# poeirinha dos cascos
	poeira = CPUParticles2D.new()
	poeira.amount = 14
	poeira.lifetime = 0.45
	poeira.direction = Vector2(0, -1)
	poeira.spread = 60.0
	poeira.initial_velocity_min = 40.0 * k
	poeira.initial_velocity_max = 110.0 * k
	poeira.gravity = Vector2(0, 200.0 * k)
	poeira.scale_amount_min = 6.0 * k
	poeira.scale_amount_max = 13.0 * k
	var g2 := Gradient.new()
	g2.set_color(0, Color(0.85, 0.72, 0.52, 0.8))
	g2.set_color(1, Color(0.85, 0.72, 0.52, 0.0))
	poeira.color_ramp = g2
	add_child(poeira)
	# zurro assustado (mais agudo que o normal)
	zurro = AudioStreamPlayer.new()
	zurro.bus = "Efeitos"
	if ResourceLoader.exists("res://audio/zurro.wav"):
		zurro.stream = load("res://audio/zurro.wav")
	zurro.pitch_scale = 1.32
	zurro.volume_db = -1.0
	add_child(zurro)

func _ready() -> void:
	if AudioManager.sound_enabled and zurro.stream:
		zurro.play()
	VoiceLines.say("faisca_foge", true)

func _espaco() -> PhysicsDirectSpaceState2D:
	return get_world_2d().direct_space_state

func _raio(de: Vector2, ate: Vector2, mascara: int = 1) -> Dictionary:
	var q := PhysicsRayQueryParameters2D.create(de, ate, mascara)
	q.exclude = [get_rid()]
	q.hit_from_inside = false
	return _espaco().intersect_ray(q)

func _tem_chao(x: float) -> Dictionary:
	# procura chão na coluna x, perto da altura dos pés
	var y: float = global_position.y
	return _raio(Vector2(x, y - 90.0 * k), Vector2(x, y + 170.0 * k))

func _physics_process(delta: float) -> void:
	t += delta
	t_virada = max(0.0, t_virada - delta)
	if estado == "pego":
		return
	if GameManager.is_level_ended:
		velocity.x = move_toward(velocity.x, 0.0, 3000.0 * delta)
	var no_chao: bool = is_on_floor()
	if no_chao:
		y_chao = global_position.y
	# ---- montar de novo: encostar ou pular em cima
	if (estado == "fugindo" or estado == "embora") and t > TEMPO_SEM_MONTAR and is_instance_valid(zeca) and _zeca_pode_montar():
		var d: Vector2 = zeca.global_position - global_position
		if abs(d.x) < ALCANCE_X * k and d.y < 40.0 * k and d.y > -ALCANCE_Y * k - 140.0 * k:
			_ser_pego()
			return
	# ---- escolhe a direção e a velocidade
	var alvo_vx: float = 0.0
	if estado == "fugindo":
		if t > TEMPO_FUGA:
			estado = "embora"
			motivo_saida = "tempo"
			if AudioManager.sound_enabled and zurro.stream:
				zurro.pitch_scale = 1.15; zurro.volume_db = -6.0; zurro.play()
		if is_instance_valid(zeca) and t_virada <= 0.0 and t > 0.5:
			var dx: float = global_position.x - zeca.global_position.x
			if abs(dx) > 60.0 * k and sign(dx) != dir:
				dir = sign(dx)          # foge para o lado oposto ao Zeca
				t_virada = 0.6
		t_olhar -= delta
		if t_olhar <= 0.0 and no_chao:
			parado = 0.4                # para e olha para trás, ofegante
			t_olhar = 1.5
		if parado > 0.0:
			parado -= delta
			alvo_vx = 0.0
		else:
			alvo_vx = dir * (VEL_SUSTO if t < 0.5 else VEL_FUGA) * k
	elif estado == "embora":
		alvo_vx = dir * VEL_EMBORA * k
		var a: float = clamp(1.0 - (t - TEMPO_FUGA) / TEMPO_SUMIR, 0.0, 1.0)
		modulate.a = a
		if a <= 0.0:
			_ir_embora("saiu")
			return
	# ---- obstáculos (só no chão; no ar mantém o pulo)
	if no_chao and alvo_vx != 0.0:
		var frente: float = global_position.x + dir * 90.0 * k
		var inimigo := false
		for h in [20.0, 60.0, 110.0]:
			if not _raio(global_position + Vector2(0, -h * k), global_position + Vector2(dir * 240.0 * k, -h * k), 4).is_empty():
				inimigo = true
				break
		if inimigo:
			velocity.y = PULO * k     # pula por cima do inimigo
			alvo_vx = dir * max(abs(alvo_vx), 560.0 * k)
			parado = 0.0
		elif _tem_chao(frente).is_empty():
			# beirada: tem chão do outro lado perto? então pula; senão vira
			var outro_lado := false
			for passo in [180.0, 260.0, 340.0]:
				var h := _tem_chao(global_position.x + dir * passo * k)
				if not h.is_empty() and abs(h.position.y - global_position.y) < 140.0 * k:
					outro_lado = true
					break
			if outro_lado:
				velocity.y = PULO * k
				alvo_vx = dir * max(abs(alvo_vx), 560.0 * k)
			elif estado == "embora":
				_ir_embora("beirada")
				return
			else:
				_virar()
				alvo_vx = dir * VEL_FUGA * k
	velocity.x = move_toward(velocity.x, alvo_vx, (2600.0 if no_chao else 1400.0) * k * delta)
	velocity.y = min(velocity.y + GRAVIDADE * k * delta, 1800.0 * k)
	move_and_slide()
	if is_on_wall() and no_chao:
		if estado == "embora":
			_ir_embora("parede")
			return
		_virar()
	# nunca cai para sempre: caiu longe do último chão (buraco, rio) -> some
	t_no_ar = 0.0 if is_on_floor() else t_no_ar + delta
	if t_no_ar > 1.6 or global_position.y > _linha_agua():
		_ir_embora("caiu")
		return
	_animar(delta, no_chao)
	no_chao_antes = no_chao

func _linha_agua() -> float:
	if zeca == null or not is_instance_valid(zeca):
		return 99999.0
	return zeca.fundo_queda_y if zeca.no_fundo else Player.MAIN_QUEDA_Y - 30.0

func _zeca_pode_montar() -> bool:
	if zeca.is_mounted or not zeca.visible or GameManager.is_level_ended:
		return false
	if zeca.get("afogando") == true or zeca.get("viajando") == true:
		return false
	return true

func _virar() -> void:
	if t_virada > 0.0:
		return
	dir = -dir
	t_virada = 0.8
	velocity.x = 0.0

func _animar(delta: float, no_chao: bool) -> void:
	sprite.flip_h = dir < 0.0
	var vel: float = abs(velocity.x) / (VEL_FUGA * k)
	fase_galope += delta * (10.0 + 6.0 * vel)
	if no_chao and vel > 0.2:
		sprite.position.y = -abs(sin(fase_galope)) * 14.0 * k
		sprite.rotation = sin(fase_galope * 2.0) * 0.07 * (1.0 if dir > 0 else -1.0)
		sprite.scale = Vector2(0.56 * (1.0 + 0.04 * sin(fase_galope * 2.0)), 0.56 * (1.0 - 0.04 * sin(fase_galope * 2.0))) * k
	elif not no_chao:
		sprite.position.y = lerp(sprite.position.y, 0.0, 0.2)
		sprite.rotation = lerp(sprite.rotation, (-0.15 if velocity.y < 0 else 0.1) * (1.0 if dir > 0 else -1.0), 0.2)
	else:
		# parado olhando para trás, ofegante
		sprite.position.y = sin(t * 16.0) * 3.0 * k
		sprite.rotation = lerp(sprite.rotation, 0.0, 0.3)
		sprite.flip_h = dir > 0.0
	poeira.emitting = no_chao and vel > 0.4
	poeira.position = Vector2(-dir * 40.0 * k, -6.0 * k)
	suor.position = Vector2(-dir * 10.0 * k + dir * 40.0 * k, -230.0 * k)
	suor.emitting = estado == "fugindo"
	aviso.visible = estado == "fugindo"
	aviso.position.y = (-440.0 + sin(t * 9.0) * 12.0) * k
	aviso.rotation = sin(t * 11.0) * 0.12
	# pisca, cada vez mais rápido perto de ir embora
	if estado == "fugindo":
		var freq: float = 6.0 if t < 3.0 else (11.0 if t < 4.5 else 18.0)
		sprite.modulate.a = 0.45 if fmod(t * freq, 1.0) < 0.35 else 1.0

func _ser_pego() -> void:
	estado = "pego"
	montou = true
	zeca.global_position.x = global_position.x
	zeca.mount_faisca()
	queue_free()

func _ir_embora(motivo: String) -> void:
	if foi_embora:
		return
	foi_embora = true
	estado = "pego"
	if motivo_saida == "" or motivo != "saiu":
		motivo_saida = motivo
	# nuvenzinha de poeira onde ele estava
	var pp: CPUParticles2D = poeira.duplicate()
	pp.one_shot = true
	pp.amount = 24
	pp.explosiveness = 0.9
	pp.lifetime = 0.7
	pp.spread = 180.0
	pp.initial_velocity_max = 260.0 * k
	get_parent().add_child(pp)
	pp.global_position = global_position + Vector2(0, -80.0 * k)
	pp.emitting = true
	get_tree().create_timer(1.2).timeout.connect(pp.queue_free)
	queue_free()

func _sumir_ja() -> void:
	# Zeca voltou ao checkpoint: o Faísca volta para o estábulo como antes
	if not foi_embora and estado != "pego":
		foi_embora = true
		motivo_saida = "checkpoint"
		queue_free()
