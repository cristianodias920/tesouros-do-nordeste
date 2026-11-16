extends Node2D
class_name FaiscaEsperando
# Faísca deixado pelo Zeca (desceu de propósito com S / seta para baixo, ou o botão de descer no celular).
# Fica parado onde foi deixado, respirando e balançando o rabo de leve; não foge e não some.
# O Zeca monta de novo como sempre: encostando nele ou caindo de um pulo em cima.
# Só some se o Zeca voltar ao checkpoint (aí vale o Faísca do estábulo, como antes).
const ALCANCE_X: float = 110.0
const ALCANCE_Y: float = 170.0
const ESC: float = 0.56
var zeca: Node2D
var k: float = 1.0
var t: float = 0.0
var armado: bool = false
var sprite: Sprite2D
var aviso: Label

func iniciar(p: Node2D) -> void:
	zeca = p
	k = p.k
	z_index = p.z_index - 1
	add_to_group("faisca_esperando")
	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.texture = load("res://sprites/faisca/faisca_solo.png")
	sprite.offset = Vector2(-141.5, -364.0)
	sprite.scale = Vector2(ESC, ESC) * k
	sprite.flip_h = p.facing_direction < 0
	add_child(sprite)
	aviso = Label.new()
	aviso.text = "O Faísca espera aqui!"
	aviso.add_theme_font_size_override("font_size", 24)
	aviso.add_theme_color_override("font_color", Color(0.98, 0.92, 0.75))
	aviso.add_theme_color_override("font_outline_color", Color(0.25, 0.15, 0.05))
	aviso.add_theme_constant_override("outline_size", 6)
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.size = Vector2(320, 34)
	aviso.position = Vector2(-160, -250) * k
	aviso.scale = Vector2.ONE * k
	add_child(aviso)
	p.get_parent().add_child(self)
	global_position = p.global_position
	GameManager.player_respawned.connect(_sumir)
	if GameManager.has_signal("continuou_do_checkpoint"):
		GameManager.continuou_do_checkpoint.connect(_sumir)

func _sumir() -> void:
	queue_free()

func _process(delta: float) -> void:
	t += delta
	# respirando: estica e encolhe de leve; de vez em quando bate a pata (pulinho curto)
	var arf: float = 1.0 + 0.018 * sin(t * 3.2)
	sprite.scale = Vector2(ESC * (2.0 - arf), ESC * arf) * k
	sprite.rotation = 0.015 * sin(t * 1.3)
	var a: float = clamp(3.5 - t, 0.0, 1.0)
	aviso.modulate.a = a
	aviso.position.y = (-250.0 + sin(t * 3.0) * 5.0) * k
	if not is_instance_valid(zeca):
		return
	if zeca.is_mounted or GameManager.is_level_ended or not zeca.visible or zeca.get("afogando") == true or zeca.get("viajando") == true:
		return
	var d: Vector2 = zeca.global_position - global_position
	var perto: bool = abs(d.x) < ALCANCE_X * k and abs(d.y) < ALCANCE_Y * k
	# arma depois que o Zeca sai de perto ou pula (assim não monta de novo na hora em que desce)
	if not armado:
		if t > 0.35 and (not perto or not zeca.is_on_floor()):
			armado = true
		return
	if perto:
		zeca.global_position.x = global_position.x
		zeca.mount_faisca()
		queue_free()
