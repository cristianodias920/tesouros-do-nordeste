extends Area2D
class_name Chapeu

# Chapéu de couro encantado (power-up): o Zeca arremessa (C / botão do chapéu), ele vai girando
# em arco leve, derruba inimigos e quebra cristais na ida E na volta, e volta para a cabeça dele.
# Bate numa parede sólida → volta na hora. Se o Zeca cair no rio/buraco, passar por um portal
# ou ficar longe demais, o chapéu "se perde", cai girando e reaparece na cabeça em ~2 s.
enum { IDA, VOLTA, PERDIDO }

const VEL_IDA: float = 1650.0       # px/s no começo da ida (vai freando)
const ALCANCE: float = 540.0        # ~4,5 passos do Zeca
const VEL_VOLTA_MAX: float = 1750.0
const ACEL_VOLTA: float = 4800.0
const ARCO: float = 46.0            # sobe um pouco no meio da ida
const PEGA_DIST: float = 70.0
const TEMPO_MAX: float = 3.2        # passou disso no ar: considera perdido
const DIST_MAX: float = 1500.0
const RAIO: float = 50.0
const CAIXA: Vector2 = Vector2(110, 170)   # área de acerto (mais alta que o desenho: pega o tatu no chão)

var estado: int = IDA
var dono: Player
var dir: float = 1.0
var k: float = 1.0
var origem: Vector2
var percorrido: float = 0.0
var vel: float = 0.0
var vel_volta: float = 0.0
var tempo: float = 0.0
var vy_perdido: float = 0.0
var acertados: Dictionary = {}      # instance_id -> perna (0 ida, 1 volta) para não acertar 2x na mesma perna
var anim: AnimatedSprite2D
var brilho: Sprite2D
var som_giro: AudioStreamPlayer2D
var acertos: int = 0                # inimigos + cristais acertados neste voo (para testes/estatística)
var espera: float = 0.0             # gesto do Zeca: o chapéu ainda está na mão dele (invisível, sem acertar);
                                    # o Zeca chama soltar() no 2º quadro do gesto (espera é só o limite de segurança)
var desvio: Vector2 = Vector2.ZERO  # o desenho sai da mão do Zeca e converge para a linha de voo
var voo_t: float = 0.0

func iniciar(p: Player, direcao: float) -> void:
	dono = p
	dir = 1.0 if direcao >= 0.0 else -1.0
	k = p.k
	origem = p.ponto_de_arremesso()
	vel = VEL_IDA * k
	global_position = origem

func _ready() -> void:
	add_to_group("chapeu_voando")
	z_index = 15
	collision_layer = 0
	collision_mask = 1 | 4            # mundo (cristais/paredes) + inimigos
	monitoring = true
	monitorable = false
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = CAIXA * k
	cs.shape = sh
	add_child(cs)
	brilho = Sprite2D.new()
	var gt := GradientTexture2D.new()
	gt.width = 128; gt.height = 128
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5); gt.fill_to = Vector2(0.5, 0.0)
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.85, 0.4, 0.55))
	g.set_color(1, Color(1.0, 0.7, 0.2, 0.0))
	gt.gradient = g
	brilho.texture = gt
	brilho.scale = Vector2.ONE * 1.4 * k
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	brilho.material = m
	add_child(brilho)
	anim = AnimatedSprite2D.new()
	var sf := SpriteFrames.new()
	sf.add_animation("giro")
	sf.set_animation_speed("giro", 20.0)
	sf.set_animation_loop("giro", true)
	for i in 6:
		sf.add_frame("giro", load("res://sprites/powerups/chapeu_giro_%d.png" % i))
	anim.sprite_frames = sf
	anim.scale = Vector2.ONE * 0.34 * k   # do tamanho do chapéu na cabeça (um pouco maior, para ver bem girando)
	anim.flip_h = dir < 0
	add_child(anim)
	anim.play("giro")
	som_giro = AudioStreamPlayer2D.new()
	som_giro.bus = AudioManager.BUS_EFEITOS
	var st = load("res://audio/chapeu_giro.wav")
	if st is AudioStreamWAV:
		st = st.duplicate()
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_begin = 0
		st.loop_end = int(st.get_length() * st.mix_rate)
	som_giro.stream = st
	som_giro.volume_db = -6.0
	som_giro.max_distance = 3000.0
	add_child(som_giro)
	if AudioManager.sound_enabled and espera <= 0.0:
		som_giro.play()
	if espera > 0.0:
		visible = false
	body_entered.connect(_acertou)

func soltar() -> void:
	# o Zeca esticou o braço: o chapéu sai da mão agora
	if espera > 0.0:
		espera = 0.0
		origem = dono.ponto_de_arremesso() if is_instance_valid(dono) else origem
		global_position = origem
		if is_instance_valid(dono):
			desvio = dono.ponto_da_mao() - origem
		visible = true
		if AudioManager.sound_enabled and som_giro and not som_giro.playing:
			som_giro.play()

func perna() -> int:
	return 0 if estado == IDA else 1

func _physics_process(delta: float) -> void:
	tempo += delta
	if estado == PERDIDO:
		vy_perdido += 2600.0 * k * delta
		global_position += Vector2(dir * 120.0 * k, vy_perdido) * delta
		anim.speed_scale = 0.6
		modulate.a = max(0.0, modulate.a - delta * 1.6)
		if modulate.a <= 0.0:
			queue_free()
		return
	if not is_instance_valid(dono) or dono.is_queued_for_deletion():
		_perder()
		return
	if dono.afogando or dono.viajando or (dono.global_position.distance_to(global_position) > DIST_MAX * k) or tempo > TEMPO_MAX:
		_perder()
		return
	if espera > 0.0:
		# ainda na mão do Zeca (ele está tirando o chapéu da cabeça): acompanha e só depois solta
		espera -= delta * 0.5
		origem = dono.ponto_de_arremesso()
		global_position = origem
		desvio = dono.ponto_da_mao() - origem
		if espera <= 0.0:
			visible = true
			if AudioManager.sound_enabled and som_giro and not som_giro.playing:
				som_giro.play()
		else:
			return
	voo_t += delta
	var dv: Vector2 = desvio * max(0.0, 1.0 - voo_t / 0.14)
	if estado == IDA:
		var antes := global_position
		var passo: float = vel * delta
		vel = max(0.0, vel - (VEL_IDA * VEL_IDA * k) / (2.0 * ALCANCE) * delta)
		percorrido += passo
		var f: float = clamp(percorrido / (ALCANCE * k), 0.0, 1.0)
		var alvo := Vector2(origem.x + dir * percorrido, origem.y)
		anim.position = Vector2(dv.x, -sin(f * PI) * ARCO * k + dv.y)   # arco só no desenho; a área de acerto segue reta
		brilho.position = anim.position
		if _parede_entre(antes, alvo):
			_voltar()
			return
		global_position = alvo
		if vel <= 60.0 * k or f >= 1.0:
			_voltar()
	else:
		# volta mirando a cabeça do Zeca (atravessa paredes: é encantado, não fica preso)
		var alvo := dono.ponto_do_chapeu()
		var d := alvo - global_position
		vel_volta = min(VEL_VOLTA_MAX * k, vel_volta + ACEL_VOLTA * k * delta)
		if d.length() <= max(PEGA_DIST * k, vel_volta * delta):
			dono.chapeu_voltou(self)
			queue_free()
			return
		global_position += d.normalized() * vel_volta * delta
		anim.flip_h = d.x < 0
		anim.position = anim.position.lerp(Vector2.ZERO, 0.2)
		brilho.position = anim.position
	# Acerta também o que já está encostado (ex.: o geodo, que leva o 2º golpe na volta)
	# (consulta de forma: o Area2D não enxerga corpos estáticos como os cristais)
	if monitoring:
		for b in _corpos_tocando():
			_acertou(b)
	# Linha do rio/abismo: caiu no buraco
	if global_position.y > dono.linha_de_queda():
		_perder()

var _q: PhysicsShapeQueryParameters2D
func _corpos_tocando() -> Array:
	if _q == null:
		_q = PhysicsShapeQueryParameters2D.new()
		var r := RectangleShape2D.new()
		r.size = CAIXA * k
		_q.shape = r
		_q.collision_mask = 1 | 4
		_q.collide_with_areas = false
	_q.transform = Transform2D(0.0, global_position)
	var res := []
	for h in get_world_2d().direct_space_state.intersect_shape(_q, 16):
		if h.collider and not res.has(h.collider):
			res.append(h.collider)
	return res

func _parede_entre(a: Vector2, b: Vector2) -> bool:
	var q := PhysicsRayQueryParameters2D.create(a, b + (b - a).normalized() * RAIO * 0.6 * k, 1)
	q.collide_with_areas = false
	q.hit_from_inside = false
	var r := get_world_2d().direct_space_state.intersect_ray(q)
	if r.is_empty():
		return false
	var col = r.collider
	if col and col.has_method("hit_by_chapeu"):
		return false   # cristal: tratado em _acertou (quebra ou faz o chapéu voltar)
	var n: Vector2 = r.normal
	return abs(n.x) > 0.6   # só parede de verdade (chão/plataforma por baixo não conta)

func _acertou(body: Node) -> void:
	if estado == PERDIDO or body == null or espera > 0.0:
		return
	var id := body.get_instance_id()
	if acertados.get(id, -1) == perna():
		return
	if body.has_method("pronto_para_golpe") and not body.pronto_para_golpe():
		return   # acabou de levar um golpe: não gasta o acerto desta perna
	acertados[id] = perna()
	if body.has_method("hit_by_chapeu"):
		# Cristal: o chapéu encantado passa através. Cristal duro (geodo) trinca na ida e quebra na volta.
		acertos += 1
		body.hit_by_chapeu(self)
	elif body.has_method("die_by_chapeu"):
		acertos += 1
		body.die_by_chapeu(global_position)
		_estrelinhas()
	elif body.has_method("die_by_coice") and not body.get("is_dead"):
		acertos += 1
		body.die_by_coice()
		_estrelinhas()

func _voltar() -> void:
	if estado != IDA:
		return
	estado = VOLTA
	vel_volta = 250.0 * k
	# o que foi acertado na ida pode ser acertado de novo na volta

func _perder() -> void:
	if estado == PERDIDO:
		return
	estado = PERDIDO
	vy_perdido = -300.0 * k
	set_deferred("monitoring", false)
	if som_giro:
		som_giro.stop()
	if is_instance_valid(dono):
		dono.chapeu_perdido(self)

func _estrelinhas() -> void:
	var pp := CPUParticles2D.new()
	pp.one_shot = true
	pp.amount = 22
	pp.lifetime = 0.6
	pp.explosiveness = 1.0
	pp.spread = 180.0
	pp.initial_velocity_min = 160.0 * k
	pp.initial_velocity_max = 360.0 * k
	pp.gravity = Vector2(0, 600.0 * k)
	pp.scale_amount_min = 7.0 * k
	pp.scale_amount_max = 14.0 * k
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 1.0, 0.75, 1.0))
	g.add_point(0.5, Color(1.0, 0.82, 0.3, 1.0))
	g.set_color(g.get_point_count() - 1, Color(1.0, 0.6, 0.1, 0.0))
	pp.color_ramp = g
	pp.z_index = 16
	get_parent().add_child(pp)
	pp.global_position = global_position
	pp.emitting = true
	get_tree().create_timer(1.2).timeout.connect(pp.queue_free)
