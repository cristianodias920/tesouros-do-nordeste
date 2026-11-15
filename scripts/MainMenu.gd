extends Control

@onready var btn_start: Button = $VBoxContainer/BtnStart
@onready var btn_sound: Button = $VBoxContainer/BtnSound
const Estrela = preload("res://scripts/HUD.gd").Estrela
const Fases = preload("res://scripts/Fases.gd")

func _ready() -> void:
	btn_start.pressed.connect(_on_start_pressed)
	btn_sound.pressed.connect(_on_sound_pressed)
	update_sound_button()
	btn_start.grab_focus()
	_mostrar_progresso()
	_botao_teste_chapeu()
	# música já na tela de título (no navegador o toque da tela "Toque para começar" liberou o som)
	AudioManager.start_music()

# ---- Escolha de fase: um cartão por fase (Corrente, Cristalândia, ...) ----
# A fase seguinte só libera depois de vencer a anterior (salvo no aparelho).
var fase_escolhida: String = "fase1_corrente"
var cartoes: Dictionary = {}   # id -> Button
var aviso: Label
var caixa_fases: HBoxContainer

func _mostrar_progresso() -> void:
	var salvo = Progresso.get_opcao("fase_menu", "fase1_corrente")
	fase_escolhida = String(salvo) if typeof(salvo) == TYPE_STRING else "fase1_corrente"
	if Fases.indice(fase_escolhida) < 0 or not Fases.desbloqueada(fase_escolhida):
		fase_escolhida = "fase1_corrente"
	caixa_fases = HBoxContainer.new()
	caixa_fases.name = "Fases"
	caixa_fases.alignment = BoxContainer.ALIGNMENT_CENTER
	caixa_fases.add_theme_constant_override("separation", 26)
	caixa_fases.anchor_left = 0.5; caixa_fases.anchor_right = 0.5
	caixa_fases.anchor_top = 0.5; caixa_fases.anchor_bottom = 0.5
	caixa_fases.offset_left = -700; caixa_fases.offset_right = 700
	caixa_fases.offset_top = -168; caixa_fases.offset_bottom = 92
	caixa_fases.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(caixa_fases)
	for f in Fases.LISTA:
		var b := _cartao_fase(f)
		caixa_fases.add_child(b)
		cartoes[f.id] = b
	aviso = Label.new()
	aviso.name = "AvisoFase"
	aviso.add_theme_font_size_override("font_size", 30)
	aviso.add_theme_color_override("font_color", Color(1, 0.95, 0.75))
	aviso.add_theme_color_override("font_outline_color", Color(0.2, 0.08, 0.02))
	aviso.add_theme_constant_override("outline_size", 9)
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.anchor_left = 0.5; aviso.anchor_right = 0.5
	aviso.anchor_top = 0.5; aviso.anchor_bottom = 0.5
	aviso.offset_left = -700; aviso.offset_right = 700
	aviso.offset_top = 100; aviso.offset_bottom = 150
	aviso.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(aviso)
	# a coluna de botões desce um pouco para caber os cartões
	$VBoxContainer.offset_top = 170.0
	$VBoxContainer.offset_bottom = 380.0
	_escolher(fase_escolhida, false)

func _estilo_cartao(cor: Color, borda: Color, larg: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = cor
	sb.border_color = borda
	sb.set_border_width_all(larg)
	sb.set_corner_radius_all(20)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 4)
	return sb

func _cartao_fase(f: Dictionary) -> Button:
	var id: String = f.id
	var livre: bool = Fases.desbloqueada(id)
	var pronta: bool = Fases.pronta(id)
	var b := Button.new()
	b.name = "Fase_" + id
	b.custom_minimum_size = Vector2(400, 250)
	b.focus_mode = Control.FOCUS_ALL
	b.clip_contents = true
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 4)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(vb)
	var l0 := _rot("FASE %d" % int(f.num), 26, Color(0.98, 0.84, 0.45))
	vb.add_child(l0)
	var l1 := _rot(String(f.nome), 46, Color(1, 0.97, 0.86))
	vb.add_child(l1)
	var info := Progresso.fase(id)
	if not livre:
		vb.add_child(_rot("BLOQUEADA", 30, Color(0.95, 0.75, 0.6)))
		var ant: Dictionary = Fases.LISTA[max(Fases.indice(id) - 1, 0)]
		vb.add_child(_rot("Vença %s para liberar" % ant.nome, 22, Color(0.95, 0.9, 0.8)))
	elif not pronta:
		vb.add_child(_rot("EM BREVE!", 32, Color(1, 0.82, 0.3)))
		vb.add_child(_rot("em construção", 22, Color(0.95, 0.9, 0.8)))
	else:
		var hb := HBoxContainer.new()
		hb.alignment = BoxContainer.ALIGNMENT_CENTER
		hb.add_theme_constant_override("separation", 8)
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for i in 3:
			var e = Estrela.new()
			e.cheia = i < int(info.estrelas)
			e.custom_minimum_size = Vector2(46, 46)
			e.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hb.add_child(e)
		vb.add_child(hb)
		if info.concluida:
			vb.add_child(_rot("Tesouros %d/%d  •  %s" % [info.melhor_tesouros, int(info.total), Progresso.formatar_tempo(info.melhor_tempo)], 22, Color(0.92, 0.97, 0.86)))
		else:
			vb.add_child(_rot("Nova!" if Fases.indice(id) > 0 else "Comece por aqui", 24, Color(0.92, 0.97, 0.86)))
	b.set_meta("livre", livre)
	b.pressed.connect(_on_cartao.bind(id))
	return b

func _rot(txt: String, tam: int, cor: Color) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", cor)
	l.add_theme_color_override("font_outline_color", Color(0.18, 0.08, 0.02))
	l.add_theme_constant_override("outline_size", 7)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _on_cartao(id: String) -> void:
	if not Fases.desbloqueada(id):
		var ant: Dictionary = Fases.LISTA[max(Fases.indice(id) - 1, 0)]
		aviso.text = "Vença %s para liberar %s!" % [ant.nome, Fases.info(id).nome]
		var b: Button = cartoes[id]
		var x0: float = b.position.x
		var t := create_tween()
		for i in 3:
			t.tween_property(b, "position:x", x0 + 12, 0.04)
			t.tween_property(b, "position:x", x0 - 12, 0.04)
		t.tween_property(b, "position:x", x0, 0.04)
		return
	if id == fase_escolhida:
		_on_start_pressed()   # tocar de novo no cartão escolhido já começa
		return
	_escolher(id, true)

func _escolher(id: String, salvar: bool) -> void:
	fase_escolhida = id
	var f := Fases.info(id)
	for k in cartoes:
		var b: Button = cartoes[k]
		var livre: bool = b.get_meta("livre")
		var sel: bool = k == id
		var cor := Color(0.24, 0.14, 0.06, 0.92) if livre else Color(0.2, 0.16, 0.13, 0.82)
		if sel:
			cor = Color(0.34, 0.2, 0.07, 0.96)
		var borda := Color(1.0, 0.85, 0.35) if sel else (Color(0.94, 0.82, 0.46, 0.8) if livre else Color(0.55, 0.5, 0.45, 0.7))
		var sbn := _estilo_cartao(cor, borda, 8 if sel else 4)
		for st in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(st, sbn if st != "focus" else _estilo_foco())
		b.modulate = Color(1, 1, 1) if livre else Color(0.8, 0.8, 0.8)
		b.scale = Vector2.ONE
	var cb: Button = cartoes[id]
	cb.pivot_offset = cb.custom_minimum_size * 0.5
	var lbl: Label = get_node_or_null("TitleBox/Fase")
	if lbl:
		lbl.text = "Fase %d: %s" % [int(f.num), f.nome]
		lbl.modulate.a = 0.0   # os cartões já mostram a fase
	btn_start.text = "JOGAR: " + String(f.nome).to_upper() if Fases.pronta(id) else "VER " + String(f.nome).to_upper()
	aviso.text = String(f.get("frase", ""))
	if salvar:
		Progresso.set_opcao("fase_menu", id)

func _estilo_foco() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.border_color = Color(1, 1, 0.85)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(20)
	sb.expand_margin_left = 4; sb.expand_margin_right = 4
	sb.expand_margin_top = 4; sb.expand_margin_bottom = 4
	return sb

# Acesso TEMPORÁRIO à cena de teste do chapéu (Fase 2 em construção). Remover quando Cristalândia estiver pronta.
var btn_teste: Button
func _botao_teste_chapeu() -> void:
	btn_teste = Button.new()
	btn_teste.name = "BtnTesteChapeu"
	btn_teste.text = "TESTAR CHAPÉU"
	btn_teste.focus_mode = Control.FOCUS_ALL
	btn_teste.custom_minimum_size = Vector2(320, 74)
	btn_teste.add_theme_font_size_override("font_size", 26)
	var sb: StyleBox = btn_start.get_theme_stylebox("normal")
	if sb:
		btn_teste.add_theme_stylebox_override("normal", sb)
	btn_teste.anchor_left = 1.0; btn_teste.anchor_right = 1.0
	btn_teste.anchor_top = 1.0; btn_teste.anchor_bottom = 1.0
	btn_teste.offset_left = -360.0; btn_teste.offset_right = -40.0
	btn_teste.offset_top = -114.0; btn_teste.offset_bottom = -40.0
	add_child(btn_teste)
	btn_teste.pressed.connect(_on_teste_chapeu)

func _on_teste_chapeu() -> void:
	AudioManager.start_music()
	GameManager.reset_game()
	get_tree().change_scene_to_file("res://scenes/TesteChapeu.tscn")

func _on_start_pressed() -> void:
	AudioManager.start_music()
	GameManager.reset_game()
	# historinha da fase escolhida antes do jogo (pode ser pulada); fase sem cena -> "Em breve"
	Fases.jogar(get_tree(), fase_escolhida)

func _on_sound_pressed() -> void:
	AudioManager.toggle_sound()
	update_sound_button()

func update_sound_button() -> void:
	if btn_sound:
		btn_sound.text = "SOM: LIGADO" if AudioManager.sound_enabled else "SOM: MUDO"
