extends Control

@onready var btn_start: Button = $VBoxContainer/BtnStart
@onready var btn_sound: Button = $VBoxContainer/BtnSound
const Estrela = preload("res://scripts/HUD.gd").Estrela

func _ready() -> void:
	btn_start.pressed.connect(_on_start_pressed)
	btn_sound.pressed.connect(_on_sound_pressed)
	update_sound_button()
	btn_start.grab_focus()
	_mostrar_progresso()

func _mostrar_progresso() -> void:
	# Progresso salvo no aparelho: estrelas, melhor nº de tesouros e melhor tempo
	var f: Dictionary = Progresso.fase(GameManager.FASE_ID)
	if not f.concluida:
		return
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.3, 0.17, 0.06, 0.88)
	sb.border_color = Color(0.96, 0.78, 0.36)
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(18)
	sb.content_margin_left = 22; sb.content_margin_right = 22
	sb.content_margin_top = 8; sb.content_margin_bottom = 8
	pc.add_theme_stylebox_override("panel", sb)
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 10)
	pc.add_child(hb)
	var l1 := Label.new()
	l1.text = "Corrente:"
	l1.add_theme_font_size_override("font_size", 30)
	l1.add_theme_color_override("font_color", Color(1, 0.93, 0.65))
	hb.add_child(l1)
	for i in 3:
		var e = Estrela.new()
		e.cheia = i < int(f.estrelas)
		e.custom_minimum_size = Vector2(44, 44)
		hb.add_child(e)
	var l2 := Label.new()
	var tot: int = int(f.total)
	l2.text = "  Tesouros %d/%d  •  Melhor tempo %s" % [f.melhor_tesouros, tot, Progresso.formatar_tempo(f.melhor_tempo)]
	l2.add_theme_font_size_override("font_size", 28)
	l2.add_theme_color_override("font_color", Color(1, 0.97, 0.88))
	hb.add_child(l2)
	$VBoxContainer.add_child(pc)

func _on_start_pressed() -> void:
	AudioManager.start_music()
	GameManager.reset_game()
	# historinha da fase antes do jogo (pode ser pulada)
	Historia.iniciar(get_tree(), "corrente", "res://scenes/Fase1_Corrente.tscn")

func _on_sound_pressed() -> void:
	AudioManager.toggle_sound()
	update_sound_button()

func update_sound_button() -> void:
	if btn_sound:
		btn_sound.text = "SOM: LIGADO" if AudioManager.sound_enabled else "SOM: MUDO"
