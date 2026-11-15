extends Control
class_name EmBreve
# Tela "Em breve" para uma fase que ainda está sendo construída.
# Mostra a ilustração da cidade, o nome da fase e volta para o menu.
const Fases = preload("res://scripts/Fases.gd")
static var fase_id: String = "fase2_cristalandia"

var painel: PanelContainer
var brilhos: CPUParticles2D
var zeca: TextureRect
var faisca: TextureRect
var t: float = 0.0
var btn_menu: Button
var btn_volta: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = load("res://ui/tema_madeira.tres")
	get_tree().paused = false
	var f: Dictionary = Fases.info(fase_id)
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.06, 0.02)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var img := TextureRect.new()
	img.name = "Imagem"
	img.set_anchors_preset(Control.PRESET_FULL_RECT)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var caminho: String = String(f.get("imagem", "res://sprites/scenery_v2/titulo_fundo.jpg"))
	if ResourceLoader.exists(caminho):
		img.texture = load(caminho)
	img.modulate = Color(0.78, 0.74, 0.7)
	add_child(img)
	var kb := create_tween().set_loops()
	img.pivot_offset = Vector2(960, 540)
	kb.tween_property(img, "scale", Vector2.ONE * 1.06, 10.0).set_trans(Tween.TRANS_SINE)
	kb.tween_property(img, "scale", Vector2.ONE, 10.0).set_trans(Tween.TRANS_SINE)
	# brilhos de cristal subindo
	brilhos = CPUParticles2D.new()
	brilhos.amount = 60
	brilhos.lifetime = 5.0
	brilhos.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	brilhos.direction = Vector2(0, -1)
	brilhos.spread = 30.0
	brilhos.gravity = Vector2(0, -12)
	brilhos.initial_velocity_min = 20.0
	brilhos.initial_velocity_max = 60.0
	brilhos.scale_amount_min = 3.0
	brilhos.scale_amount_max = 8.0
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 0.97, 0.85, 0.95), Color(0.85, 0.9, 1, 0)])
	brilhos.color_ramp = g
	add_child(brilhos)
	# painel central
	painel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.27, 0.15, 0.06, 0.9)
	sb.border_color = Color(0.96, 0.78, 0.36)
	sb.set_border_width_all(6)
	sb.set_corner_radius_all(28)
	sb.content_margin_left = 60; sb.content_margin_right = 60
	sb.content_margin_top = 34; sb.content_margin_bottom = 34
	sb.shadow_size = 18
	sb.shadow_color = Color(0, 0, 0, 0.45)
	painel.add_theme_stylebox_override("panel", sb)
	add_child(painel)
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 16)
	painel.add_child(vb)
	vb.add_child(_rotulo("Fase %d" % int(f.get("num", 2)), 40, Color(0.98, 0.86, 0.5)))
	var nome := _rotulo(String(f.get("nome", "")), 92, Color(1, 0.96, 0.82))
	nome.name = "Nome"
	vb.add_child(nome)
	var eb := _rotulo("EM BREVE!", 64, Color(1, 0.82, 0.3))
	eb.name = "EmBreveLabel"
	vb.add_child(eb)
	var fr := _rotulo(String(f.get("frase", "")), 32, Color(0.92, 0.97, 0.88))
	vb.add_child(fr)
	vb.add_child(_rotulo("Zeca e o Faísca já estão arrumando as coisas pra viagem.\nVolte logo pra conferir!", 30, Color(1, 0.95, 0.85)))
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 30)
	vb.add_child(hb)
	btn_menu = _botao("Menu Principal")
	btn_menu.name = "BtnMenu"
	btn_menu.pressed.connect(_menu)
	hb.add_child(btn_menu)
	# jogar de novo a fase anterior
	var i: int = Fases.indice(fase_id)
	if i > 0:
		var ant: Dictionary = Fases.LISTA[i - 1]
		btn_volta = _botao("Jogar %s de novo" % ant.nome)
		btn_volta.name = "BtnJogarAnterior"
		btn_volta.pressed.connect(func(): Fases.jogar(get_tree(), String(ant.id)))
		hb.add_child(btn_volta)
	btn_menu.grab_focus()
	# Zeca e Faísca nos cantos
	zeca = _sprite("res://sprites/player/zeca_jump.png")
	faisca = _sprite("res://sprites/faisca/faisca_solo.png")
	faisca.flip_h = true
	get_viewport().size_changed.connect(_layout)
	_layout()
	painel.modulate.a = 0.0
	painel.scale = Vector2.ONE * 0.85
	var tw := create_tween()
	tw.tween_property(painel, "modulate:a", 1.0, 0.4)
	tw.parallel().tween_property(painel, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	AudioManager.start_music()

func _rotulo(txt: String, tam: int, cor: Color) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", cor)
	l.add_theme_color_override("font_outline_color", Color(0.18, 0.08, 0.02))
	l.add_theme_constant_override("outline_size", 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(980, 0)
	return l

func _botao(txt: String) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(380, 86)
	b.add_theme_font_size_override("font_size", 32)
	return b

func _sprite(p: String) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = load(p)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tr)
	return tr

func _layout() -> void:
	var vp := get_viewport_rect().size
	painel.reset_size()
	painel.pivot_offset = painel.size * 0.5
	painel.position = (vp - painel.size) * 0.5
	brilhos.position = Vector2(vp.x * 0.5, vp.y + 10)
	brilhos.emission_rect_extents = Vector2(vp.x * 0.5, 10)
	var lado: float = (vp.x - painel.size.x) * 0.5
	var cabe: bool = lado > 220
	zeca.visible = cabe; faisca.visible = cabe
	var w: float = min(300.0, lado - 30.0)
	zeca.size = Vector2(w, w * 1.25); faisca.size = Vector2(w, w * 1.25)
	zeca.position = Vector2(lado * 0.5 - w * 0.5, vp.y - zeca.size.y - 40)
	faisca.position = Vector2(vp.x - lado * 0.5 - w * 0.5, vp.y - faisca.size.y - 30)

func _process(delta: float) -> void:
	t += delta
	if zeca.visible:
		var vp := get_viewport_rect().size
		zeca.position.y = vp.y - zeca.size.y - 40 - abs(sin(t * 3.0)) * 30.0
		faisca.position.y = vp.y - faisca.size.y - 30 - abs(sin(t * 3.0 + 1.2)) * 18.0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_menu()

func _menu() -> void:
	AudioManager.reiniciar_musica()
	GameManager.reset_game()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
