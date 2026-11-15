extends CanvasLayer

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
	touch_controls.visible = DisplayServer.is_touchscreen_available()
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
	GameManager.reset_game()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	GameManager.reset_game()
	get_tree().reload_current_scene()

func _on_level_completed() -> void:
	victory_screen.visible = true
	touch_controls.visible = false
	if victory_gems_label:
		var faltam: int = GameManager.TOTAL_GEMS - GameManager.collected_gems
		var res: String = "Todos os tesouros! ★" if faltam <= 0 else ("Faltou 1 tesouro" if faltam == 1 else "Faltaram %d tesouros" % faltam)
		victory_gems_label.text = "Tesouros coletados: " + str(GameManager.collected_gems) + "/" + str(GameManager.TOTAL_GEMS) + "\n" + res
		victory_gems_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _on_game_over() -> void:
	game_over_screen.visible = true
	touch_controls.visible = false
