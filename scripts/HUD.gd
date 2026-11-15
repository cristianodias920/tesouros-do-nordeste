extends CanvasLayer
const Fases = preload("res://scripts/Fases.gd")

@onready var heart_1: TextureRect = $TopLeft/HeartsContainer/Heart1
@onready var heart_2: TextureRect = $TopLeft/HeartsContainer/Heart2
@onready var heart_3: TextureRect = $TopLeft/HeartsContainer/Heart3
@onready var gems_label: Label = $TopLeft/GemsContainer/GemsLabel
@onready var sound_button: Button = $TopRight/ButtonsContainer/SoundButton
@onready var pause_button: Button = $TopRight/ButtonsContainer/PauseButton

# Controles de toque
@onready var touch_controls: Control = $TouchControls
@onready var btn_left: TouchScreenButton = $TouchControls/BtnLeft
@onready var btn_right: TouchScreenButton = $TouchControls/BtnRight
@onready var btn_jump: TouchScreenButton = $TouchControls/BtnJump
@onready var btn_action: TouchScreenButton = $TouchControls/BtnAction

# Telas de sobreposição
@onready var pause_menu: Control = $PauseMenu
@onready var victory_screen: Control = $VictoryScreen
@onready var game_over_screen: Control = $GameOverScreen
@onready var victory_gems_label: Label = $VictoryScreen/Panel/VBox/GemsCountLabel

var intro: Control
var voz_inicio: bool = true   # a cena de teste do chapéu desliga ("Corrente, aqui vou eu!")
var intro_time: float = 0.0
const INTRO_DUR: float = 3.0
var gems_panel: Panel
var tex_heart_full: Texture2D
var tex_heart_empty: Texture2D

func _ready() -> void:
	if ResourceLoader.exists("res://sprites/items/coracao_cheio.png"):
		tex_heart_full = load("res://sprites/items/coracao_cheio.png")
	if ResourceLoader.exists("res://sprites/items/coracao_vazio.png"):
		tex_heart_empty = load("res://sprites/items/coracao_vazio.png")

	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.gems_changed.connect(_on_gems_changed)
	GameManager.level_completed.connect(_on_level_completed)
	GameManager.game_over.connect(_on_game_over)

	update_lives_display(GameManager.current_lives)
	update_gems_display(GameManager.collected_gems, GameManager.TOTAL_GEMS)
	update_sound_button_label()
	# Conta o total de tesouros depois que a fase inteira entrou na árvore
	GameManager.call_deferred("recount_total", get_tree())
	VoiceLines.reset()
	_build_treasure_counter()

	pause_menu.visible = false
	victory_screen.visible = false
	game_over_screen.visible = false

	# Posiciona os botões de toque dinamicamente nas bordas da tela
	get_viewport().size_changed.connect(_update_touch_positions)
	_update_touch_positions()

	# Mobile / Touch inicial
	touch_controls.visible = DisplayServer.is_touchscreen_available()
	_build_intro()
	get_viewport().size_changed.connect(_center_intro)
	add_to_group("hud")
	_montar_pausa()
	_montar_fim_de_jogo()
	_montar_vitoria()
	_montar_dica_folha()
	_montar_poderes()
	if GameManager.celular:
		_hud_maior()
		get_viewport().size_changed.connect(_hud_maior)

func _update_touch_positions() -> void:
	var vp_size = get_viewport().get_visible_rect().size
	var btn_size = 150.0
	var margin_bottom = 40.0
	var margin_side = 40.0

	var y_pos = vp_size.y - btn_size - margin_bottom

	if btn_left:
		btn_left.position = Vector2(margin_side, y_pos)
	if btn_right:
		btn_right.position = Vector2(margin_side + btn_size + 30.0, y_pos)
	if btn_jump:
		btn_jump.position = Vector2(vp_size.x - btn_size - margin_side, y_pos)
	if btn_action:
		btn_action.position = Vector2(vp_size.x - (btn_size * 2.0) - margin_side - 30.0, y_pos)
	# Chapéu (usar power-up) logo acima do pulo; troca da reserva acima do coice
	if btn_poder:
		btn_poder.position = Vector2(vp_size.x - btn_size - margin_side, y_pos - btn_size - 24.0)
	if btn_trocar:
		btn_trocar.position = Vector2(vp_size.x - (btn_size * 2.0) - margin_side - 30.0 + 20.0, y_pos - btn_size - 4.0)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		# Teclado esconde os botões de toque
		touch_controls.visible = false
	elif event is InputEventScreenTouch or (event is InputEventMouseButton and event.pressed):
		# Toque na tela reexibe os botões de toque (menos nas telas de fim)
		touch_controls.visible = not GameManager.is_level_ended

	if intro and intro.visible:
		if (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
			_close_intro()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause"):
		toggle_pause()

func _process(_delta: float) -> void:
	if intro and intro.visible:
		intro_time += _delta
		if intro_time >= INTRO_DUR:
			_close_intro()
	# O botão de coice no toque só aparece montado no Faísca
	if btn_action:
		btn_action.visible = GameManager.is_mounted
	_update_rapadura_indicator()
	_update_dica_folha(_delta)
	_update_poderes(_delta)

func _on_lives_changed(lives: int) -> void:
	update_lives_display(lives)

func update_lives_display(lives: int) -> void:
	if heart_1:
		heart_1.texture = tex_heart_full if lives >= 1 else tex_heart_empty
	if heart_2:
		heart_2.texture = tex_heart_full if lives >= 2 else tex_heart_empty
	if heart_3:
		heart_3.texture = tex_heart_full if lives >= 3 else tex_heart_empty

func _on_gems_changed(gems: int, total: int) -> void:
	update_gems_display(gems, total)

func update_gems_display(gems: int, total: int) -> void:
	if gems_label:
		var old: String = gems_label.text
		gems_label.text = "Tesouros " + str(gems) + "/" + str(total)
		if old != gems_label.text and gems > 0 and gems_panel:
			gems_panel.pivot_offset = gems_panel.size * 0.5
			var t := create_tween()
			t.tween_property(gems_panel, "scale", Vector2(1.12, 1.12), 0.07)
			t.tween_property(gems_panel, "scale", Vector2.ONE, 0.12)

func _build_treasure_counter() -> void:
	# Contador de tesouros em destaque: placa de madeira com ícone e "Tesouros X/Y"
	var gc: Control = $TopLeft/GemsContainer
	gems_panel = Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.36, 0.2, 0.08, 0.88)
	sb.border_color = Color(0.96, 0.78, 0.36)
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(18)
	gems_panel.add_theme_stylebox_override("panel", sb)
	gems_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$TopLeft.add_child(gems_panel)
	$TopLeft.move_child(gems_panel, gc.get_index())
	gems_panel.position = Vector2(-8, 74)
	gems_panel.size = Vector2(380, 74)
	gc.position = Vector2(8, 80)
	gc.size = Vector2(360, 62)
	var icon: TextureRect = $TopLeft/GemsContainer/GemIcon
	icon.custom_minimum_size = Vector2(60, 60)
	if gems_label.label_settings:
		var ls: LabelSettings = gems_label.label_settings.duplicate()
		ls.font_size = 42
		ls.font_color = Color(1.0, 0.93, 0.62)
		ls.outline_size = 8
		ls.outline_color = Color(0.2, 0.1, 0.03)
		gems_label.label_settings = ls
	update_gems_display(GameManager.collected_gems, GameManager.TOTAL_GEMS)
	_build_rapadura_indicator()

var rap_panel: Panel
var rap_label: Label
var rap_bar: ProgressBar

func _build_rapadura_indicator() -> void:
	# Indicador da rapadura: ícone + "Invencível 5s" + barra que esvazia
	rap_panel = Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.45, 0.25, 0.04, 0.9)
	sb.border_color = Color(1.0, 0.85, 0.3)
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(16)
	rap_panel.add_theme_stylebox_override("panel", sb)
	rap_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rap_panel.position = Vector2(-8, 158)
	rap_panel.size = Vector2(380, 70)
	rap_panel.visible = false
	$TopLeft.add_child(rap_panel)
	var ic := TextureRect.new()
	ic.texture = load("res://sprites/items/rapadura.png")
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.position = Vector2(10, 7); ic.size = Vector2(56, 56)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rap_panel.add_child(ic)
	rap_label = Label.new()
	rap_label.position = Vector2(74, 2); rap_label.size = Vector2(296, 40)
	rap_label.add_theme_font_size_override("font_size", 30)
	rap_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.6))
	rap_label.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.02))
	rap_label.add_theme_constant_override("outline_size", 7)
	rap_panel.add_child(rap_label)
	rap_bar = ProgressBar.new()
	rap_bar.show_percentage = false
	rap_bar.position = Vector2(76, 44); rap_bar.size = Vector2(286, 14)
	var bg := StyleBoxFlat.new(); bg.bg_color = Color(0.2, 0.1, 0.02, 0.8); bg.set_corner_radius_all(7)
	var fg := StyleBoxFlat.new(); fg.bg_color = Color(1.0, 0.8, 0.2); fg.set_corner_radius_all(7)
	rap_bar.add_theme_stylebox_override("background", bg)
	rap_bar.add_theme_stylebox_override("fill", fg)
	rap_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rap_panel.add_child(rap_bar)

func _update_rapadura_indicator() -> void:
	if rap_panel == null:
		return
	var p = get_tree().get_first_node_in_group("player")
	var t: float = p.rapadura_timer if p else 0.0
	rap_panel.visible = t > 0.0
	if t <= 0.0:
		return
	rap_label.text = "Invencível %ds" % int(ceil(t))
	rap_bar.max_value = p.RAPADURA_DUR
	rap_bar.value = t
	# pisca rápido nos últimos segundos
	rap_panel.modulate.a = (0.35 if fmod(t * 6.0, 1.0) < 0.4 else 1.0) if t < 1.8 else 1.0

func _build_intro() -> void:
	# Cartão de abertura da fase com o objetivo (some sozinho em 3 s ou com um toque)
	intro = Control.new()
	intro.set_anchors_preset(Control.PRESET_FULL_RECT)
	intro.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(intro)
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.07, 0.02, 0.55)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro.add_child(bg)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.4, 0.23, 0.09, 0.97)
	sb.border_color = Color(0.96, 0.78, 0.36)
	sb.set_border_width_all(6)
	sb.set_corner_radius_all(26)
	sb.content_margin_left = 60; sb.content_margin_right = 60
	sb.content_margin_top = 34; sb.content_margin_bottom = 34
	panel.add_theme_stylebox_override("panel", sb)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)
	var t1 := Label.new()
	t1.text = "FASE 1 • CORRENTE, PIAUÍ"
	t1.add_theme_font_size_override("font_size", 64)
	t1.add_theme_color_override("font_color", Color(1.0, 0.92, 0.6))
	t1.add_theme_color_override("font_outline_color", Color(0.18, 0.09, 0.02))
	t1.add_theme_constant_override("outline_size", 10)
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t1)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 14)
	vb.add_child(hb)
	var ic := TextureRect.new()
	ic.texture = $TopLeft/GemsContainer/GemIcon.texture
	ic.custom_minimum_size = Vector2(64, 64)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hb.add_child(ic)
	var t2 := Label.new()
	t2.text = "Objetivo: colete todos os tesouros!"
	t2.add_theme_font_size_override("font_size", 46)
	t2.add_theme_color_override("font_color", Color(1, 0.98, 0.9))
	t2.add_theme_color_override("font_outline_color", Color(0.18, 0.09, 0.02))
	t2.add_theme_constant_override("outline_size", 8)
	hb.add_child(t2)
	var t3 := Label.new()
	t3.text = "Toque para começar"
	t3.add_theme_font_size_override("font_size", 28)
	t3.add_theme_color_override("font_color", Color(0.95, 0.85, 0.65))
	t3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t3)
	_center_intro()
	touch_controls.visible = false
	get_tree().paused = true
	intro_time = 0.0

func _center_intro() -> void:
	if intro == null:
		return
	var panel: Control = intro.get_child(1)
	panel.reset_size()
	var vp := get_viewport().get_visible_rect().size
	panel.position = (vp - panel.size) * 0.5

func _close_intro() -> void:
	if intro == null or not intro.visible:
		return
	intro.visible = false
	get_tree().paused = false
	GameManager.cronometro_ativo = true
	touch_controls.visible = DisplayServer.is_touchscreen_available()
	if voz_inicio:
		VoiceLines.say("inicio")

func _on_sound_button_pressed() -> void:
	AudioManager.toggle_sound()
	update_sound_button_label()

func update_sound_button_label() -> void:
	if sound_button:
		sound_button.text = "SOM: LIGADO" if AudioManager.sound_enabled else "SOM: MUDO"

func _on_pause_button_pressed() -> void:
	toggle_pause()

func toggle_pause() -> void:
	if GameManager.is_level_ended:
		return # não pausa por cima da vitória ou do FIM DA AVENTURA
	var tree = get_tree()
	tree.paused = not tree.paused
	pause_menu.visible = tree.paused

func _on_continue_button_pressed() -> void:
	get_tree().paused = false
	pause_menu.visible = false

func _on_menu_button_pressed() -> void:
	get_tree().paused = false
	AudioManager.set_ambiente("passaros", 0.0)
	AudioManager.set_ambiente("rio", 0.0)
	AudioManager.reiniciar_musica()   # menu/recomeçar: música volta limpa, do começo
	GameManager.reset_game()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	AudioManager.reiniciar_musica()   # menu/recomeçar: música volta limpa, do começo
	GameManager.reset_game()
	get_tree().reload_current_scene()

func _on_level_completed() -> void:
	victory_screen.visible = true
	touch_controls.visible = false
	dica_folha_mini.visible = false
	var r: Dictionary = GameManager.resultado
	var c: int = GameManager.collected_gems
	var total: int = GameManager.TOTAL_GEMS
	var faltam: int = total - c
	var est: int = int(r.get("estrelas", GameManager.estrelas_para(c, total)))
	var rec: Dictionary = r.get("recordes", {})
	if victory_gems_label:
		var res: String = "Todos os tesouros!" if faltam <= 0 else ("Faltou 1 tesouro" if faltam == 1 else "Faltaram %d tesouros" % faltam)
		var pct: int = int(round(100.0 * c / max(total, 1)))
		victory_gems_label.text = "Tesouros coletados: %d/%d (%d%%)\n%s" % [c, total, pct, res]
		victory_gems_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var tempo_txt: String = "Tempo: " + Progresso.formatar_tempo(float(r.get("tempo", GameManager.tempo)))
	var novos: Array = []
	if rec.get("tempo", false) and not rec.get("primeira_vez", false):
		novos.append("tempo")
	if rec.get("tesouros", false) and not rec.get("primeira_vez", false):
		novos.append("tesouros")
	if rec.get("estrelas", false) and not rec.get("primeira_vez", false):
		novos.append("estrelas")
	if novos.size() > 0:
		var nomes: Dictionary = {"tempo": "melhor tempo", "tesouros": "mais tesouros", "estrelas": "mais estrelas"}
		var lista: Array = []
		for n in novos:
			lista.append(nomes[n])
		tempo_txt += "   •   Novo recorde: " + " e ".join(lista) + "!"
	else:
		var melhor: Dictionary = Progresso.fase(GameManager.FASE_ID)
		if not rec.get("primeira_vez", false) and melhor.melhor_tempo > 0.0:
			tempo_txt += "   •   Melhor: " + Progresso.formatar_tempo(melhor.melhor_tempo)
	vit_tempo.text = tempo_txt
	# onde ainda há tesouros
	if faltam > 0:
		var areas: Dictionary = GameManager.tesouros_restantes_por_area(get_tree())
		var partes: Array = []
		for a in GameManager.areas_da_fase():
			if areas.has(a):
				partes.append("%s (%d)" % [a, areas[a]])
		vit_areas.text = "Ainda há tesouros em: " + ", ".join(partes) if partes.size() > 0 else ""
	else:
		vit_areas.text = "Você achou todos os tesouros de %s!" % String(Fases.info(GameManager.FASE_ID).get("nome", "Corrente"))
	vit_frase.text = ["Conseguimos, Faísca! Bora achar mais tesouros na próxima!", "Conseguimos, Faísca! Quase todos os tesouros!", "Conseguimos, Faísca! Achamos TODOS os tesouros!"][est - 1]
	_atualizar_proxima_fase()
	_animar_vitoria(est)

# Anuncia a próxima fase na vitória e mostra o botão para ir direto para ela
func _atualizar_proxima_fase() -> void:
	var prox: Dictionary = Fases.proxima(GameManager.FASE_ID)
	var aviso: Label = get_node_or_null("VictoryScreen/Panel/VBox/NextPhaseNotice")
	if prox.is_empty():
		if aviso:
			aviso.text = "Mais aventuras pelo Piauí em breve!"
		vit_btn_proxima.visible = false
		return
	var pronta: bool = Fases.pronta(String(prox.id))
	if aviso:
		aviso.text = ("Próxima parada: %s! %s." % [prox.nome, prox.frase]) if pronta else ("Próxima parada: %s. %s!" % [prox.nome, prox.frase])
	vit_btn_proxima.text = ("Próxima fase: %s  ▶" % prox.nome) if pronta else ("Próxima fase: %s (em breve)" % prox.nome)
	vit_btn_proxima.visible = true
	vit_btn_proxima.grab_focus()

func _on_proxima_fase_pressed() -> void:
	var prox: Dictionary = Fases.proxima(GameManager.FASE_ID)
	if prox.is_empty():
		return
	VoiceLines.reset()
	AudioManager.reiniciar_musica()
	Fases.jogar(get_tree(), String(prox.id))

func _on_game_over() -> void:
	game_over_screen.visible = true
	touch_controls.visible = false
	var tem_ckp: bool = GameManager.has_checkpoint
	go_btn_ckp.text = "Continuar do checkpoint" if tem_ckp else "Tentar de novo"

func _on_continuar_checkpoint() -> void:
	game_over_screen.visible = false
	get_tree().paused = false
	GameManager.continuar_do_checkpoint()
	touch_controls.visible = DisplayServer.is_touchscreen_available()

# ---------------- Telas novas (montadas por código) ----------------
var go_btn_ckp: Button
var vit_tempo: Label
var vit_areas: Label
var vit_frase: Label
var vit_btn_proxima: Button
var vit_estrelas: Array = []
var vit_confete: CPUParticles2D
var vit_zeca: TextureRect
var vit_faisca: TextureRect
var vol_sliders: Dictionary = {}

class Estrela extends Control:
	var cheia: bool = false
	var brilho: float = 0.0
	func _draw() -> void:
		var c: Vector2 = size * 0.5
		var r1: float = min(size.x, size.y) * 0.5
		var r2: float = r1 * 0.45
		var pts := PackedVector2Array()
		for i in 10:
			var ang: float = -PI / 2.0 + i * PI / 5.0
			var rr: float = r1 if i % 2 == 0 else r2
			pts.append(c + Vector2(cos(ang), sin(ang)) * rr)
		var fill: Color = Color(1.0, 0.8, 0.2) if cheia else Color(0.32, 0.2, 0.1, 0.85)
		draw_colored_polygon(pts, fill)
		if cheia:
			# brilho interno
			var pts2 := PackedVector2Array()
			for p in pts:
				pts2.append(c + (p - c) * 0.55 + Vector2(0, -r1 * 0.08))
			draw_colored_polygon(pts2, Color(1.0, 0.93, 0.55, 0.9))
		var borda := pts.duplicate()
		borda.append(pts[0])
		draw_polyline(borda, Color(0.35, 0.18, 0.04) if cheia else Color(0.75, 0.6, 0.35, 0.8), 5.0, true)

func _rotulo(txt: String, tam: int, cor: Color) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", cor)
	l.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.03))
	l.add_theme_constant_override("outline_size", 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _montar_vitoria() -> void:
	var panel: Panel = $VictoryScreen/Panel
	panel.offset_left = -560; panel.offset_right = 560
	panel.offset_top = -470; panel.offset_bottom = 470
	var vb: VBoxContainer = $VictoryScreen/Panel/VBox
	vb.add_theme_constant_override("separation", 12)
	var title: Label = $VictoryScreen/Panel/VBox/Title
	# estrelas
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 26)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(hb)
	vb.move_child(hb, title.get_index() + 1)
	for i in 3:
		var e := Estrela.new()
		e.custom_minimum_size = Vector2(118, 118) if i != 1 else Vector2(140, 140)
		e.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(e)
		vit_estrelas.append(e)
	var dica_est := _rotulo("1 estrela: terminar  •  2: 70% dos tesouros  •  3: todos", 22, Color(0.95, 0.85, 0.65))
	vb.add_child(dica_est)
	vb.move_child(dica_est, hb.get_index() + 1)
	vit_tempo = _rotulo("", 32, Color(1, 0.97, 0.85))
	vb.add_child(vit_tempo)
	vb.move_child(vit_tempo, victory_gems_label.get_index() + 1)
	vit_areas = _rotulo("", 26, Color(0.85, 0.95, 0.8))
	vit_areas.custom_minimum_size = Vector2(980, 0)
	vb.add_child(vit_areas)
	vb.move_child(vit_areas, vit_tempo.get_index() + 1)
	vit_frase = _rotulo("", 30, Color(1, 0.9, 0.55))
	vb.add_child(vit_frase)
	vb.move_child(vit_frase, vit_areas.get_index() + 1)
	# botão da próxima fase (em destaque, antes de "Jogar novamente")
	vit_btn_proxima = Button.new()
	vit_btn_proxima.name = "BtnProxima"
	vit_btn_proxima.text = "Próxima fase"
	vit_btn_proxima.custom_minimum_size = Vector2(0, 84)
	vit_btn_proxima.add_theme_font_size_override("font_size", 34)
	for st in ["normal", "hover", "pressed", "focus"]:
		var sbp := StyleBoxFlat.new()
		sbp.bg_color = Color(0.2, 0.45, 0.22, 0.97) if st != "pressed" else Color(0.15, 0.36, 0.17, 1.0)
		if st == "hover":
			sbp.bg_color = Color(0.26, 0.54, 0.28, 0.98)
		sbp.border_color = Color(1.0, 0.86, 0.42) if st != "focus" else Color(1, 1, 0.8)
		sbp.set_border_width_all(5)
		sbp.set_corner_radius_all(18)
		if st == "focus":
			sbp.draw_center = false
		vit_btn_proxima.add_theme_stylebox_override(st, sbp)
	vit_btn_proxima.add_theme_color_override("font_color", Color(1, 0.97, 0.85))
	vit_btn_proxima.add_theme_color_override("font_hover_color", Color(1, 1, 0.9))
	vit_btn_proxima.add_theme_color_override("font_focus_color", Color(1, 1, 0.9))
	vit_btn_proxima.pressed.connect(_on_proxima_fase_pressed)
	vb.add_child(vit_btn_proxima)
	vb.move_child(vit_btn_proxima, $VictoryScreen/Panel/VBox/BtnReplay.get_index())
	# Zeca e Faísca comemorando dos lados do painel
	vit_zeca = TextureRect.new()
	vit_zeca.texture = load("res://sprites/player/zeca_jump.png")
	vit_faisca = TextureRect.new()
	vit_faisca.texture = load("res://sprites/faisca/faisca_solo.png")
	for tr in [vit_zeca, vit_faisca]:
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.size = Vector2(300, 380)
		$VictoryScreen.add_child(tr)
	vit_faisca.flip_h = true
	# confete
	vit_confete = CPUParticles2D.new()
	vit_confete.amount = 160
	vit_confete.lifetime = 4.0
	vit_confete.emitting = false
	vit_confete.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	vit_confete.direction = Vector2(0, 1)
	vit_confete.spread = 25.0
	vit_confete.gravity = Vector2(0, 260)
	vit_confete.initial_velocity_min = 80.0
	vit_confete.initial_velocity_max = 260.0
	vit_confete.angular_velocity_min = -360.0
	vit_confete.angular_velocity_max = 360.0
	vit_confete.scale_amount_min = 8.0
	vit_confete.scale_amount_max = 16.0
	var cores := Gradient.new()
	cores.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
	cores.colors = PackedColorArray([Color(0.9, 0.25, 0.2), Color(0.98, 0.8, 0.2), Color(0.25, 0.6, 0.3), Color(0.2, 0.45, 0.85), Color(0.95, 0.5, 0.75)])
	vit_confete.color_initial_ramp = cores
	$VictoryScreen.add_child(vit_confete)
	$VictoryScreen.move_child(vit_confete, 1)   # atrás do painel, na frente do fundo escuro
	_posicionar_vitoria()
	get_viewport().size_changed.connect(_posicionar_vitoria)

func _posicionar_vitoria() -> void:
	var vp := get_viewport().get_visible_rect().size
	if vit_confete:
		vit_confete.position = Vector2(vp.x * 0.5, -30)
		vit_confete.emission_rect_extents = Vector2(vp.x * 0.5, 10)
	var meio: float = vp.x * 0.5
	# só mostra os personagens se couberem do lado do painel
	var cabe: bool = meio - 560 > 230
	vit_zeca.visible = cabe
	vit_faisca.visible = cabe
	var w: float = min(300.0, meio - 580.0)
	vit_zeca.size = Vector2(w, 380); vit_faisca.size = Vector2(w, 380)
	vit_zeca.position = Vector2(meio - 570 - w, vp.y * 0.5 - 60)
	vit_faisca.position = Vector2(meio + 570, vp.y * 0.5 - 40)

func _animar_vitoria(est: int) -> void:
	_posicionar_vitoria()
	vit_confete.emitting = true
	for i in 3:
		var e: Estrela = vit_estrelas[i]
		e.cheia = false
		e.queue_redraw()
		e.pivot_offset = e.custom_minimum_size * 0.5
		e.scale = Vector2.ONE
	var t := create_tween()
	t.tween_interval(0.5)
	for i in est:
		var e: Estrela = vit_estrelas[i]
		t.tween_callback(func():
			e.cheia = true
			e.queue_redraw()
			e.scale = Vector2.ONE * 0.2
			AudioManager.play_sfx("gem"))
		t.tween_property(e, "scale", Vector2.ONE * 1.18, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(e, "scale", Vector2.ONE, 0.12)
	# Zeca e Faísca pulando de alegria
	for tr in [vit_zeca, vit_faisca]:
		var y0: float = tr.position.y
		var j := create_tween().set_loops()
		j.tween_property(tr, "position:y", y0 - 46, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		j.tween_property(tr, "position:y", y0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		j.tween_interval(0.25 if tr == vit_zeca else 0.4)

func _montar_fim_de_jogo() -> void:
	var vb: VBoxContainer = $GameOverScreen/Panel/VBox
	var panel: Panel = $GameOverScreen/Panel
	panel.offset_top = -260; panel.offset_bottom = 260
	go_btn_ckp = $GameOverScreen/Panel/VBox/BtnRetry
	go_btn_ckp.text = "Continuar do checkpoint"
	go_btn_ckp.pressed.disconnect(_on_restart_button_pressed)
	go_btn_ckp.pressed.connect(_on_continuar_checkpoint)
	var b := Button.new()
	b.text = "Recomeçar a fase"
	b.custom_minimum_size = Vector2(0, 72)
	b.pressed.connect(_on_restart_button_pressed)
	vb.add_child(b)
	vb.move_child(b, go_btn_ckp.get_index() + 1)

func _montar_pausa() -> void:
	var panel: Panel = $PauseMenu/Panel
	panel.offset_left = -360; panel.offset_right = 360
	panel.offset_top = -370; panel.offset_bottom = 370
	var vb: VBoxContainer = $PauseMenu/Panel/VBox
	vb.add_theme_constant_override("separation", 16)
	$PauseMenu/Panel/VBox/BtnSound.visible = false
	var idx: int = $PauseMenu/Panel/VBox/BtnContinue.get_index() + 1
	var rot := _rotulo("Volume", 34, Color(1, 0.92, 0.65))
	vb.add_child(rot); vb.move_child(rot, idx); idx += 1
	for par in [["musica", "Música"], ["vozes", "Vozes"], ["efeitos", "Efeitos"]]:
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 16)
		var l := _rotulo(par[1], 30, Color(1, 0.97, 0.88))
		l.custom_minimum_size = Vector2(150, 0)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		hb.add_child(l)
		var sl := HSlider.new()
		sl.min_value = 0.0; sl.max_value = 1.0; sl.step = 0.05
		sl.value = float(AudioManager.volumes.get(par[0], 1.0))
		sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sl.custom_minimum_size = Vector2(0, 60)
		sl.focus_mode = Control.FOCUS_NONE
		var trilho := StyleBoxFlat.new(); trilho.bg_color = Color(0.2, 0.1, 0.03, 0.9); trilho.set_corner_radius_all(8)
		trilho.content_margin_top = 7; trilho.content_margin_bottom = 7
		var cheio := StyleBoxFlat.new(); cheio.bg_color = Color(1.0, 0.8, 0.25); cheio.set_corner_radius_all(8)
		cheio.content_margin_top = 7; cheio.content_margin_bottom = 7
		sl.add_theme_stylebox_override("slider", trilho)
		sl.add_theme_stylebox_override("grabber_area", cheio)
		sl.add_theme_stylebox_override("grabber_area_highlight", cheio)
		sl.add_theme_icon_override("grabber", _bolinha(40))
		sl.add_theme_icon_override("grabber_highlight", _bolinha(44))
		var pct := _rotulo("%d%%" % int(round(sl.value * 100)), 28, Color(1, 0.97, 0.88))
		pct.custom_minimum_size = Vector2(90, 0)
		var canal: String = par[0]
		sl.value_changed.connect(func(v):
			AudioManager.set_volume(canal, v)
			pct.text = "%d%%" % int(round(v * 100))
			if canal == "vozes" and not VoiceLines.player_audio.playing and VoiceLines.player_audio.stream:
				VoiceLines.player_audio.play()
			elif canal == "efeitos":
				AudioManager.play_sfx("gem"))
		hb.add_child(sl)
		hb.add_child(pct)
		vb.add_child(hb); vb.move_child(hb, idx); idx += 1
		vol_sliders[canal] = sl
	var br := Button.new()
	br.text = "Recomeçar a fase"
	br.custom_minimum_size = Vector2(0, 72)
	br.pressed.connect(_on_restart_button_pressed)
	vb.add_child(br); vb.move_child(br, idx)
	_botao_fechar_pausa(panel)

# Botão X no canto de cima à direita do painel: despausa (igual a "Continuar")
var btn_fechar_pausa: Button
func _botao_fechar_pausa(panel: Panel) -> void:
	var t := 116.0
	var b := Button.new()
	b.name = "BtnFechar"
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = "Fechar e continuar"
	b.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	b.offset_left = -t + 34; b.offset_right = 34
	b.offset_top = -34; b.offset_bottom = t - 34
	for estado in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.78, 0.2, 0.12) if estado != "pressed" else Color(0.6, 0.14, 0.08)
		if estado == "hover":
			sb.bg_color = Color(0.88, 0.28, 0.16)
		sb.set_corner_radius_all(int(t / 2))
		sb.border_color = Color(1.0, 0.92, 0.65)
		sb.set_border_width_all(6)
		sb.shadow_color = Color(0, 0, 0, 0.35); sb.shadow_size = 6; sb.shadow_offset = Vector2(0, 4)
		b.add_theme_stylebox_override(estado, sb)
	var x := XDesenho.new()
	x.mouse_filter = Control.MOUSE_FILTER_IGNORE
	x.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.add_child(x)
	b.pressed.connect(_on_continue_button_pressed)
	panel.add_child(b)
	btn_fechar_pausa = b

class XDesenho extends Control:
	func _draw() -> void:
		var c := size * 0.5
		var r := size.x * 0.22
		var w := size.x * 0.11
		var cor := Color(1, 0.97, 0.88)
		for d in [Vector2(1, 1), Vector2(1, -1)]:
			draw_line(c - d * r, c + d * r, cor, w, true)
			draw_circle(c - d * r, w * 0.5, cor)
			draw_circle(c + d * r, w * 0.5, cor)

func _bolinha(d: int) -> ImageTexture:
	var img := Image.create(d, d, false, Image.FORMAT_RGBA8)
	var c := Vector2(d, d) * 0.5
	for y in d:
		for x in d:
			var r: float = Vector2(x + 0.5, y + 0.5).distance_to(c)
			if r <= d * 0.5 - 1:
				img.set_pixel(x, y, Color(0.35, 0.18, 0.04) if r > d * 0.5 - 5 else Color(1.0, 0.92, 0.6))
	return ImageTexture.create_from_image(img)

# ---- dica da folha de buriti (planar) ----
var dica_folha: PanelContainer
var dica_folha_t: float = 0.0
var dica_folha_mini: PanelContainer

func _painel_dica(txt: String, tam: int) -> PanelContainer:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.22, 0.38, 0.12, 0.92)
	sb.border_color = Color(0.96, 0.85, 0.45)
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(18)
	sb.content_margin_left = 18; sb.content_margin_right = 22
	sb.content_margin_top = 8; sb.content_margin_bottom = 8
	pc.add_theme_stylebox_override("panel", sb)
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(hb)
	var ic := TextureRect.new()
	ic.texture = load("res://sprites/items/folha_buriti.png")
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.custom_minimum_size = Vector2(tam * 1.9, tam * 1.6)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(ic)
	var l := _rotulo(txt, tam, Color(1, 0.97, 0.85))
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(l)
	pc.visible = false
	add_child(pc)
	return pc

func _montar_dica_folha() -> void:
	var botao: String = "o botão de pular" if GameManager.celular else "PULAR (Espaço)"
	dica_folha = _painel_dica("Folha de buriti! Nas nuvens, segure %s\nenquanto cai para planar devagar." % botao, 34)
	dica_folha_mini = _painel_dica("Segure %s: planar" % ("PULAR" if not GameManager.celular else "pular"), 26)

func mostrar_dica_folha() -> void:
	dica_folha_t = 6.0
	dica_folha.visible = true
	dica_folha.modulate.a = 1.0

func _update_dica_folha(delta: float) -> void:
	if dica_folha == null:
		return
	var vp := get_viewport().get_visible_rect().size
	var esc: float = $TopLeft.scale.x
	if dica_folha_t > 0.0:
		dica_folha_t -= delta
		dica_folha.reset_size()
		dica_folha.scale = Vector2.ONE * esc
		dica_folha.position = Vector2((vp.x - dica_folha.size.x * esc) * 0.5, vp.y - dica_folha.size.y * esc - 60.0)
		dica_folha.modulate.a = clamp(dica_folha_t / 0.5, 0.0, 1.0)
		if dica_folha_t <= 0.0:
			dica_folha.visible = false
	var p = get_tree().get_first_node_in_group("player")
	var mostrar: bool = p != null and p.tem_folha and p.na_area_das_nuvens() and not GameManager.is_level_ended and dica_folha_t <= 0.0
	dica_folha_mini.visible = mostrar
	if mostrar:
		dica_folha_mini.reset_size()
		dica_folha_mini.scale = Vector2.ONE * esc
		var y0: float = 24.0 + (240.0 if rap_panel and rap_panel.visible else 166.0) * esc
		dica_folha_mini.position = Vector2(22, y0)
		dica_folha_mini.modulate.a = 1.0 if p.planando else 0.8

func _hud_maior() -> void:
	# Celular: HUD ~1,5x maior (1,3x em telas 16:9, para o título não encostar nos botões)
	var vp := get_viewport().get_visible_rect().size
	var f: float = 1.5 if vp.x / max(vp.y, 1.0) >= 1.9 else 1.3
	$TopLeft.scale = Vector2.ONE * f
	var tr: Control = $TopRight
	tr.pivot_offset = Vector2(tr.size.x, 0)
	tr.scale = Vector2.ONE * f
	var tc: Control = $TopCenter
	tc.pivot_offset = Vector2(tc.size.x * 0.5, 0)
	tc.scale = Vector2.ONE * f

# ---- Power-ups com reserva (estilo Super Mario World) ----
# Painel no canto de cima à direita: caixa grande = power-up ativo (C usa), caixa pequena = reserva (V troca).
# No celular: botão do chapéu acima do pulo e botão de troca acima do coice.
var btn_poder: TouchScreenButton
var btn_trocar: TouchScreenButton
var poderes_panel: Control
var caixa_ativo: Panel
var caixa_reserva: Panel
var ic_ativo: TextureRect
var ic_reserva: TextureRect
var tecla_ativo: Label
var tecla_reserva: Label
var dica_chapeu: PanelContainer
var dica_chapeu_t: float = 0.0
var dica_reserva: PanelContainer
var dica_reserva_t: float = 0.0
var poderes_pulso: float = 0.0

func _caixa_poder(tam: float, borda: Color) -> Panel:
	var pn := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.3, 0.17, 0.06, 0.88)
	sb.border_color = borda
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(18)
	pn.add_theme_stylebox_override("panel", sb)
	pn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pn.size = Vector2(tam, tam)
	return pn

func _icone_poder(pai: Control, tam: float) -> TextureRect:
	var ic := TextureRect.new()
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.position = Vector2(10, 10)
	ic.size = Vector2(tam - 20, tam - 20)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pai.add_child(ic)
	return ic

func _tecla(pai: Control, txt: String) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", 24)
	l.add_theme_color_override("font_color", Color(1, 0.95, 0.7))
	l.add_theme_color_override("font_outline_color", Color(0.15, 0.07, 0.02))
	l.add_theme_constant_override("outline_size", 7)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.position = Vector2(0, pai.size.y - 4)
	l.size = Vector2(pai.size.x, 30)
	pai.add_child(l)
	return l

func _montar_poderes() -> void:
	poderes_panel = Control.new()
	poderes_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$TopRight.add_child(poderes_panel)
	poderes_panel.position = Vector2(410 - 250, 100)
	poderes_panel.size = Vector2(250, 160)
	caixa_reserva = _caixa_poder(92, Color(0.8, 0.7, 0.5))
	caixa_reserva.position = Vector2(0, 14)
	poderes_panel.add_child(caixa_reserva)
	ic_reserva = _icone_poder(caixa_reserva, 92)
	tecla_reserva = _tecla(caixa_reserva, "V troca")
	caixa_ativo = _caixa_poder(120, Color(1.0, 0.82, 0.32))
	caixa_ativo.position = Vector2(110, 0)
	poderes_panel.add_child(caixa_ativo)
	ic_ativo = _icone_poder(caixa_ativo, 120)
	tecla_ativo = _tecla(caixa_ativo, "C usa")
	# Botões de toque
	btn_poder = TouchScreenButton.new()
	btn_poder.name = "BtnPoder"
	btn_poder.texture_normal = load("res://sprites/ui/btn_chapeu.png")
	btn_poder.action = "poder"
	btn_poder.visibility_mode = TouchScreenButton.VISIBILITY_TOUCHSCREEN_ONLY
	touch_controls.add_child(btn_poder)
	btn_trocar = TouchScreenButton.new()
	btn_trocar.name = "BtnTrocar"
	btn_trocar.texture_normal = load("res://sprites/ui/btn_trocar.png")
	btn_trocar.action = "trocar_poder"
	btn_trocar.scale = Vector2.ONE * 0.75
	btn_trocar.visibility_mode = TouchScreenButton.VISIBILITY_TOUCHSCREEN_ONLY
	touch_controls.add_child(btn_trocar)
	_update_touch_positions()
	var cel: bool = GameManager.celular
	dica_chapeu = _painel_dica(("Chapéu de couro! Toque no botão do chapéu para arremessar." if cel else "Chapéu de couro! Aperte C para arremessar.") + "\nEle gira, derruba bichos, quebra cristais e volta.", 34)
	dica_reserva = _painel_dica("O outro power-up ficou guardado na reserva.\n" + ("Toque no botão de troca para alternar." if cel else "Aperte V para trocar."), 30)
	PowerUps.mudou.connect(_on_poderes_mudou)
	_on_poderes_mudou(PowerUps.ativo(), PowerUps.reserva())

var _reserva_antes: String = "?"
func _on_poderes_mudou(ativo: String, reserva: String) -> void:
	poderes_panel.visible = ativo != "" or reserva != ""
	caixa_ativo.visible = ativo != ""
	caixa_reserva.visible = reserva != ""
	ic_ativo.texture = PowerUps.icone(ativo)
	ic_reserva.texture = PowerUps.icone(reserva)
	var usa: bool = ativo != "" and bool(PowerUps.DADOS[ativo].usa_botao)
	tecla_ativo.text = ("C usa" if usa else "ativo") if not GameManager.celular else ""
	tecla_reserva.text = "V troca" if not GameManager.celular else ""
	if _reserva_antes == "" and reserva != "":
		dica_reserva_t = 5.0
		dica_reserva.visible = true
	_reserva_antes = reserva
	poderes_pulso = 0.35

func mostrar_dica_chapeu() -> void:
	dica_chapeu_t = 6.0
	dica_chapeu.visible = true
	dica_chapeu.modulate.a = 1.0

func _mostrar_dica_tempo(d: PanelContainer, t: float, dy: float) -> float:
	if d == null:
		return t
	if t > 0.0:
		t -= get_process_delta_time()
		var vp := get_viewport().get_visible_rect().size
		var esc: float = $TopLeft.scale.x
		d.reset_size()
		d.scale = Vector2.ONE * esc
		d.position = Vector2((vp.x - d.size.x * esc) * 0.5, vp.y - d.size.y * esc - 60.0 - dy * esc)
		d.modulate.a = clamp(t / 0.5, 0.0, 1.0)
		if t <= 0.0:
			d.visible = false
	return t

func _update_poderes(_delta: float) -> void:
	if poderes_panel == null:
		return
	dica_chapeu_t = _mostrar_dica_tempo(dica_chapeu, dica_chapeu_t, 0.0)
	var acima: bool = dica_chapeu_t > 0.0 or (dica_folha != null and dica_folha.visible)
	dica_reserva_t = _mostrar_dica_tempo(dica_reserva, dica_reserva_t, 150.0 if acima else 0.0)
	var p = get_tree().get_first_node_in_group("player")
	var ativo := PowerUps.ativo()
	var usa: bool = ativo != "" and bool(PowerUps.DADOS[ativo].usa_botao)
	btn_poder.visible = usa
	btn_trocar.visible = PowerUps.reserva() != ""
	# caixa do ativo apagada enquanto o chapéu está no ar / recarregando
	var pronto: bool = true
	if p and ativo == "chapeu":
		pronto = p.chapeu_pronto()
	ic_ativo.modulate = Color(1, 1, 1, 1.0 if pronto else 0.35)
	btn_poder.modulate = Color(1, 1, 1, 1.0 if pronto else 0.45)
	if poderes_pulso > 0.0:
		poderes_pulso -= _delta
		var f: float = 1.0 + 0.18 * sin(clamp(poderes_pulso / 0.35, 0.0, 1.0) * PI)
		caixa_ativo.pivot_offset = caixa_ativo.size * 0.5
		caixa_ativo.scale = Vector2.ONE * f
