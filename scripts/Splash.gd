extends Control
# Tela "Toque/Clique para começar" (só no navegador).
# O navegador só deixa tocar som depois de um toque/clique; com este toque antes,
# a música já começa no instante em que a tela de título aparece.
# Fora do navegador (Windows, Android nativo...) pula direto para o título.

const TITULO := "res://scenes/MainMenu.tscn"
var saindo: bool = false
var aviso: Label
var t: float = 0.0
var pronto_em: float = 0.25   # ignora toques nos primeiros instantes

static func precisa_splash() -> bool:
	return OS.has_feature("web") or "splash=1" in OS.get_cmdline_user_args()

func _ready() -> void:
	if not precisa_splash():
		get_tree().change_scene_to_file.call_deferred(TITULO)
		return
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# fundo em aquarela: a mesma pintura do título, clareada como papel molhado
	var fundo := TextureRect.new()
	fundo.texture = load("res://sprites/scenery_v2/titulo_fundo.jpg")
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fundo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)
	var papel := ColorRect.new()
	papel.color = Color(0.99, 0.95, 0.84, 0.42)
	papel.set_anchors_preset(Control.PRESET_FULL_RECT)
	papel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(papel)
	var borda := TextureRect.new()
	borda.texture = _vinheta()
	borda.set_anchors_preset(Control.PRESET_FULL_RECT)
	borda.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	borda.stretch_mode = TextureRect.STRETCH_SCALE
	borda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(borda)
	# logo
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_CENTER_TOP)
	vb.offset_left = -800; vb.offset_right = 800
	vb.offset_top = 150; vb.offset_bottom = 560
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 6)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vb)
	vb.add_child(_texto("Tesouros do Nordeste", 118, Color(1, 0.95, 0.78), Color(0.18, 0.08, 0.02), 16))
	vb.add_child(_texto("Aventura no Piauí", 76, Color(1, 0.85, 0.3), Color(0.3, 0.12, 0.02), 14))
	# aviso piscando, numa pincelada
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.3, 0.17, 0.06, 0.86)
	sb.border_color = Color(0.96, 0.78, 0.36)
	sb.set_border_width_all(5)
	sb.set_corner_radius_all(40)
	sb.content_margin_left = 60; sb.content_margin_right = 60
	sb.content_margin_top = 18; sb.content_margin_bottom = 22
	sb.shadow_color = Color(0, 0, 0, 0.3); sb.shadow_size = 10; sb.shadow_offset = Vector2(0, 6)
	pc.add_theme_stylebox_override("panel", sb)
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	pc.grow_horizontal = Control.GROW_DIRECTION_BOTH
	pc.grow_vertical = Control.GROW_DIRECTION_BEGIN
	pc.offset_bottom = -170
	pc.name = "Aviso"
	add_child(pc)
	var celular: bool = GameManager.celular
	aviso = _texto(("Toque" if celular else "Clique") + " para começar", 58, Color(1, 0.97, 0.88), Color(0.2, 0.1, 0.02), 8)
	pc.add_child(aviso)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.4)

func _texto(s: String, tam: int, cor: Color, contorno: Color, borda: int) -> Label:
	var l := Label.new()
	l.text = s
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ls := LabelSettings.new()
	ls.font_size = tam
	ls.font_color = cor
	ls.outline_size = borda
	ls.outline_color = contorno
	ls.shadow_size = 8
	ls.shadow_color = Color(0, 0, 0, 0.45)
	ls.shadow_offset = Vector2(3, 4)
	l.label_settings = ls
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _vinheta() -> ImageTexture:
	var w := 192; var h := 108
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var d: float = Vector2((x - w * 0.5) / (w * 0.5), (y - h * 0.5) / (h * 0.5)).length()
			var a: float = clamp((d - 0.7) / 0.6, 0.0, 1.0)
			img.set_pixel(x, y, Color(0.45, 0.28, 0.1, a * 0.55))
	return ImageTexture.create_from_image(img)

func _process(delta: float) -> void:
	t += delta
	if aviso:
		aviso.modulate.a = 0.6 + 0.4 * (0.5 + 0.5 * sin(t * 4.0))

func _gui_input(event: InputEvent) -> void:
	_tentar(event)

func _unhandled_input(event: InputEvent) -> void:
	_tentar(event)

func _tentar(event: InputEvent) -> void:
	if saindo or t < pronto_em:
		return
	var solto: bool = (event is InputEventMouseButton and not event.pressed) \
		or (event is InputEventScreenTouch and not event.pressed) \
		or (event is InputEventKey and not event.pressed and not event.echo)
	if solto:
		comecar()

func comecar() -> void:
	if saindo:
		return
	saindo = true
	# o toque já liberou o som do navegador: música começa agora, junto com o título
	AudioManager.start_music()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func(): get_tree().change_scene_to_file(TITULO))
