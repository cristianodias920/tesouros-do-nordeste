@tool
extends StaticBody2D
class_name Cristal

# Cristal quebrável (reutilizável nas fases): só o chapéu de couro quebra.
#  tipo "pequeno": bloco de quartzo (1 golpe) — fecha passagens, esconde tesouros
#  tipo "geodo":   pedra grande com cristais (2 golpes: ida e volta do chapéu, ou 2 arremessos)
#  tipo "pendurado": cacho de cristais no alto (1 golpe), cai e se parte
# Filhos que são tesouros (Gema etc.) ficam escondidos dentro e saltam para fora quando quebra.
# Bloqueia o Zeca (camada Mundo) até quebrar. Pulo, pisão e coice não quebram.
signal quebrou(cristal: Node)

@export_enum("pequeno", "geodo", "pendurado") var tipo: String = "pequeno":
	set(v):
		tipo = v
		if is_inside_tree():
			_montar()
@export var golpes: int = 0          # 0 = padrão do tipo
@export var escala: float = 1.0:
	set(v):
		escala = v
		if is_inside_tree():
			_montar()

const TEX := {
	"pequeno": "res://sprites/cristais/cristal_pequeno.png",
	"geodo": "res://sprites/cristais/geodo.png",
	"pendurado": "res://sprites/cristais/cristal_pendurado.png",
}
const TAM := {   # tamanho da colisão (px, escala 1) e altura do sprite
	"pequeno": Vector2(120, 120),
	"geodo": Vector2(170, 170),
	"pendurado": Vector2(130, 150),
}
var vida: int = 1
var quebrado: bool = false
var ultimo_golpe: float = -10.0
var sprite: Sprite2D
var col: CollisionShape2D
var escondidos: Array = []
var t: float = 0.0

func _ready() -> void:
	_montar()
	if Engine.is_editor_hint():
		return
	add_to_group("cristais")
	collision_layer = 1
	collision_mask = 0
	vida = golpes if golpes > 0 else (2 if tipo == "geodo" else 1)
	for c in get_children():
		if c is Area2D and c.is_in_group("gemas") or (c is Area2D and c.get_script() and String(c.get_script().resource_path).ends_with("Gema.gd")):
			escondidos.append(c)
			c.visible = false
			c.set_deferred("monitoring", false)
			c.set_process(false)

func _montar() -> void:
	if sprite == null:
		sprite = get_node_or_null("Sprite2D")
		if sprite == null:
			sprite = Sprite2D.new()
			sprite.name = "Sprite2D"
			add_child(sprite)
	if col == null:
		col = get_node_or_null("CollisionShape2D")
		if col == null:
			col = CollisionShape2D.new()
			col.name = "CollisionShape2D"
			add_child(col)
	var tex: Texture2D = load(TEX[tipo])
	sprite.texture = tex
	var tam: Vector2 = TAM[tipo] * escala
	# sprite com a base no chão (pendurado: topo no teto)
	var s: float = (tam.x * 1.25) / float(tex.get_width())
	sprite.scale = Vector2(s, s)
	var h: float = tex.get_height() * s
	var r := RectangleShape2D.new()
	r.size = tam
	col.shape = r
	if tipo == "pendurado":
		sprite.position = Vector2(0, h * 0.5)
		col.position = Vector2(0, tam.y * 0.5)
	else:
		sprite.position = Vector2(0, -h * 0.5 + 6.0 * escala)
		col.position = Vector2(0, -tam.y * 0.5)

func _process(delta: float) -> void:
	if Engine.is_editor_hint() or quebrado or sprite == null:
		return
	t += delta
	# brilho que pulsa (mostra que dá para interagir)
	var b: float = 1.0 + 0.12 * (0.5 + 0.5 * sin(t * 3.0 + position.x * 0.01))
	sprite.modulate = Color(b, b, b * 1.05, 1.0)

func centro() -> Vector2:
	return col.global_position if col else global_position

func pronto_para_golpe() -> bool:
	return not quebrado and (Time.get_ticks_msec() / 1000.0 - ultimo_golpe) >= 0.12

# Chamado pelo chapéu. Devolve true se quebrou.
func hit_by_chapeu(_chapeu: Node = null) -> bool:
	if quebrado:
		return true
	var agora: float = Time.get_ticks_msec() / 1000.0
	if agora - ultimo_golpe < 0.12:
		return false
	ultimo_golpe = agora
	vida -= 1
	if vida > 0:
		AudioManager.play_sfx("cristal_trinca")
		if tipo == "geodo":
			sprite.texture = load("res://sprites/cristais/geodo_trincado.png")
		_tremer()
		_estilhacos(6, 0.5)
		return false
	quebrar()
	return true

func quebrar() -> void:
	if quebrado:
		return
	quebrado = true
	AudioManager.play_sfx("cristal_quebra")
	collision_layer = 0
	col.set_deferred("disabled", true)
	_estilhacos(22, 1.0)
	_brilho_quebra()
	for g in escondidos:
		if not is_instance_valid(g):
			continue
		var gp: Vector2 = g.global_position
		var pai := get_parent()
		g.reparent(pai, false)
		g.global_position = gp
		g.visible = true
		g.set_process(true)
		g.set_deferred("monitoring", true)
		if g.get("base_y") != null:
			g.base_y = g.position.y
		# salta para fora
		var s0: Vector2 = g.scale
		g.scale = s0 * 0.3
		var tw: Tween = g.create_tween()
		tw.tween_property(g, "scale", s0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	quebrou.emit(self)
	var tw2 := create_tween()
	if tipo == "pendurado":
		tw2.tween_property(sprite, "position:y", sprite.position.y + 260.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw2.parallel().tween_property(sprite, "modulate:a", 0.0, 0.35)
	else:
		tw2.tween_property(sprite, "scale", sprite.scale * Vector2(1.15, 0.2), 0.16)
		tw2.parallel().tween_property(sprite, "modulate:a", 0.0, 0.18)
	tw2.tween_interval(0.9)
	tw2.tween_callback(queue_free)

func _tremer() -> void:
	var p0: Vector2 = sprite.position
	var tw := create_tween()
	for i in 4:
		tw.tween_property(sprite, "position", p0 + Vector2((6.0 if i % 2 == 0 else -6.0) * escala, 0), 0.03)
	tw.tween_property(sprite, "position", p0, 0.03)
	sprite.modulate = Color(1.8, 1.8, 2.0)

func _estilhacos(n: int, forca: float) -> void:
	for i in 4:
		var pp := CPUParticles2D.new()
		pp.texture = load("res://sprites/cristais/estilhaco_%d.png" % i)
		pp.one_shot = true
		pp.amount = max(2, n / 4)
		pp.lifetime = 0.9
		pp.explosiveness = 0.95
		pp.direction = Vector2(0, -1)
		pp.spread = 75.0
		pp.initial_velocity_min = 260.0 * forca
		pp.initial_velocity_max = 620.0 * forca
		pp.gravity = Vector2(0, 1500.0)
		pp.angular_velocity_min = -540.0
		pp.angular_velocity_max = 540.0
		pp.angle_min = 0.0
		pp.angle_max = 360.0
		pp.scale_amount_min = 0.35 * escala
		pp.scale_amount_max = 0.8 * escala
		pp.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		pp.emission_rect_extents = (TAM[tipo] * escala) * 0.35
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		pp.color_ramp = g
		pp.z_index = 14
		get_parent().add_child(pp)
		pp.global_position = centro()
		pp.emitting = true
		get_tree().create_timer(1.6).timeout.connect(pp.queue_free)

func _brilho_quebra() -> void:
	var sp := Sprite2D.new()
	var gt := GradientTexture2D.new()
	gt.width = 256; gt.height = 256
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5); gt.fill_to = Vector2(0.5, 0.0)
	var g := Gradient.new()
	g.set_color(0, Color(0.95, 0.9, 1.0, 0.9))
	g.set_color(1, Color(0.8, 0.7, 1.0, 0.0))
	gt.gradient = g
	sp.texture = gt
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sp.material = m
	sp.z_index = 13
	get_parent().add_child(sp)
	sp.global_position = centro()
	sp.scale = Vector2.ONE * 0.4 * escala
	var tw := sp.create_tween()
	tw.tween_property(sp, "scale", Vector2.ONE * 1.6 * escala, 0.3)
	tw.parallel().tween_property(sp, "modulate:a", 0.0, 0.35)
	tw.tween_callback(sp.queue_free)
