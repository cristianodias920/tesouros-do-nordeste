extends Control
class_name Historia
# Historinha em cartões antes da fase: ilustração + balão + voz.
# Toque/tecla avança, "Pular história" pula tudo. No fim, fade para a fase
# (que mostra o cartão de objetivo). Os cartões vêm de res://historia/historias.gd.

const DADOS = preload("res://historia/historias.gd")
const CENA := "res://scenes/Historia.tscn"

static var historia_id: String = "corrente"
static var proxima_cena: String = "res://scenes/Fase1_Corrente.tscn"

static func iniciar(tree: SceneTree, id: String, proxima: String) -> void:
	historia_id = id
	proxima_cena = proxima
	if not DADOS.HISTORIAS.has(id):
		tree.change_scene_to_file(proxima)
		return
	tree.change_scene_to_file(CENA)

var cards: Array = []
var idx: int = -1
var img: TextureRect
var balao: Balao
var fade: ColorRect
var btn_pular: Button
var dica: Label
var contador: Label
var ocupado: bool = false
var saindo: bool = false
var tempo_card: float = 0.0
var espera_auto: float = 999.0
var fim_audio: bool = false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # toques chegam ao _unhandled_input (o botão Pular continua clicável)
	get_tree().paused = false
	cards = DADOS.HISTORIAS.get(historia_id, [])
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.05, 0.02)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	img = TextureRect.new()
	img.set_anchors_preset(Control.PRESET_FULL_RECT)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(img)
	balao = Balao.new()
	add_child(balao)
	# rodapé: dica + contador
	dica = _rotulo("Toque para continuar  ▶", 34)
	add_child(dica)
	contador = _rotulo("", 30)
	add_child(contador)
	# botão sempre visível
	btn_pular = Button.new()
	btn_pular.text = "Pular história  ▶▶"
	btn_pular.focus_mode = Control.FOCUS_NONE
	btn_pular.add_theme_font_size_override("font_size", 34)
	for st in ["normal", "hover", "pressed"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.36, 0.2, 0.08, 0.92) if st != "pressed" else Color(0.5, 0.3, 0.1, 0.95)
		sb.border_color = Color(0.96, 0.78, 0.36)
		sb.set_border_width_all(4)
		sb.set_corner_radius_all(16)
		sb.content_margin_left = 26; sb.content_margin_right = 26
		sb.content_margin_top = 12; sb.content_margin_bottom = 12
		btn_pular.add_theme_stylebox_override(st, sb)
	btn_pular.add_theme_color_override("font_color", Color(1.0, 0.93, 0.62))
	btn_pular.pressed.connect(pular)
	add_child(btn_pular)
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 1)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	move_child(btn_pular, -1)   # botão acima do fade: sempre visível
	get_viewport().size_changed.connect(_layout)
	_layout()
	if cards.is_empty():
		_terminar()
		return
	_ir_para(0)

func _rotulo(texto: String, fs: int) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", Color(1, 0.97, 0.88))
	l.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.02))
	l.add_theme_constant_override("outline_size", 9)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _tela() -> Vector2:
	return get_viewport_rect().size

func _layout() -> void:
	var tl := _tela()
	btn_pular.reset_size()
	btn_pular.position = Vector2(tl.x - btn_pular.size.x - 28, 24)
	dica.reset_size()
	dica.position = Vector2(tl.x - dica.size.x - 36, tl.y - dica.size.y - 26)
	contador.reset_size()
	contador.position = Vector2(36, tl.y - contador.size.y - 28)
	img.pivot_offset = tl * 0.5
	if idx >= 0 and idx < cards.size():
		_posicionar_balao()

func _posicionar_balao() -> void:
	var c: Dictionary = cards[idx]
	var tl := _tela()
	# a imagem cobre a tela mantendo 16:9: converte 0..1 da imagem para a tela
	var esc: float = max(tl.x / 1280.0, tl.y / 720.0)
	var isz := Vector2(1280, 720) * esc
	var off := (tl - isz) * 0.5
	var centro: Vector2 = off + (c["balao"] as Vector2) * isz
	var alvo: Vector2 = off + (c["alvo"] as Vector2) * isz
	balao.configurar(c["texto"], "fala" if c["quem"] == "zeca" else "grito", centro, alvo, tl)

func _ir_para(n: int) -> void:
	ocupado = true
	var primeiro: bool = idx < 0
	var t := create_tween()
	if not primeiro:
		t.tween_property(fade, "color:a", 1.0, 0.3)
	t.tween_callback(func():
		idx = n
		_mostrar_card())
	t.tween_property(fade, "color:a", 0.0, 0.45 if primeiro else 0.3)
	t.tween_callback(func(): ocupado = false)

func _mostrar_card() -> void:
	var c: Dictionary = cards[idx]
	img.texture = load(c["imagem"])
	img.scale = Vector2.ONE
	var kb := create_tween()   # zoom lento ("Ken Burns")
	kb.tween_property(img, "scale", Vector2.ONE * 1.06, 9.0).set_trans(Tween.TRANS_SINE)
	_posicionar_balao()
	balao.scale = Vector2.ONE * 0.6
	balao.modulate.a = 0.0
	var bt := create_tween()
	bt.tween_interval(0.25)
	bt.tween_property(balao, "modulate:a", 1.0, 0.15)
	bt.parallel().tween_property(balao, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	contador.text = "%d / %d" % [idx + 1, cards.size()]
	contador.reset_size()
	tempo_card = 0.0
	fim_audio = false
	var vp: AudioStreamPlayer = VoiceLines.player_audio   # usa o player das falas: a música abaixa sozinha
	vp.stop()
	var dur: float = 1.5 + 0.06 * String(c["texto"]).length()
	var a: String = c["audio"]
	if a == "zurro":
		AudioManager.play_sfx("zurro")
		dur = 2.4
	elif a != "" and ResourceLoader.exists(a):
		var st: AudioStream = load(a)
		vp.stream = st
		if AudioManager.sound_enabled:
			vp.play()
		dur = st.get_length()
	espera_auto = dur + 3.0   # avança sozinho um pouco depois da fala

func _process(delta: float) -> void:
	if idx < 0 or saindo:
		return
	tempo_card += delta
	dica.modulate.a = 0.55 + 0.45 * sin(tempo_card * 4.0)
	if not ocupado and tempo_card >= espera_auto:
		avancar()

func _unhandled_input(event: InputEvent) -> void:
	var tocar: bool = false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tocar = true
	elif event is InputEventScreenTouch and event.pressed:
		tocar = true
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"):
		tocar = true
	if tocar:
		get_viewport().set_input_as_handled()
		avancar()

func avancar() -> void:
	if ocupado or saindo or tempo_card < 0.35:
		return
	if idx + 1 < cards.size():
		_ir_para(idx + 1)
	else:
		_terminar()

func pular() -> void:
	_terminar()

func _terminar() -> void:
	if saindo:
		return
	saindo = true
	VoiceLines.player_audio.stop()
	var t := create_tween()
	t.tween_property(fade, "color:a", 1.0, 0.45)
	t.tween_callback(func(): get_tree().change_scene_to_file(proxima_cena))
