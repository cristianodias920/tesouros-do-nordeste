extends Node2D

# Cena de TESTE do chapéu bumerangue e da reserva de power-ups (acesso temporário pelo menu).
# Não é fase: não conta estrelas nem recorde. Dá para planar com a folha em qualquer lugar aqui.
var botoes: CanvasLayer

func _ready() -> void:
	AudioManager.tocar_musica("forro", true)
	var hud = get_node_or_null("HUD")
	if hud:
		hud.voz_inicio = false
	if hud and hud.intro:
		var vb = hud.intro.get_child(1).get_child(0)
		vb.get_child(0).text = "TESTE • CHAPÉU DE COURO"
		var hb = vb.get_child(1)
		hb.get_child(1).text = ("Pegue o chapéu e toque no botão do chapéu!" if GameManager.celular else "Pegue o chapéu e aperte C para arremessar!")
		hud._center_intro()
	var titulo = get_node_or_null("HUD/TopCenter/PhaseTitleLabel")
	if titulo:
		titulo.text = "Teste do Chapéu"
	_montar_botoes()

func pode_planar(_p) -> bool:
	return true   # aqui a folha plana em qualquer lugar (para testar a troca com a reserva)

func _montar_botoes() -> void:
	botoes = CanvasLayer.new()
	botoes.layer = 5
	add_child(botoes)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	botoes.add_child(hb)
	for par in [["ZERAR POWER-UPS", _zerar], ["VOLTAR AO MENU", _menu]]:
		var b := Button.new()
		b.text = par[0]
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(250, 56)
		b.add_theme_font_size_override("font_size", 22)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.24, 0.14, 0.06, 0.85)
		sb.border_color = Color(0.94, 0.82, 0.46)
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(12)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_stylebox_override("pressed", sb)
		b.pressed.connect(par[1])
		hb.add_child(b)
	hb.reset_size()
	get_viewport().size_changed.connect(func(): _posicionar(hb))
	_posicionar(hb)

func _posicionar(hb: Control) -> void:
	var vp := get_viewport().get_visible_rect().size
	hb.reset_size()
	var esc: float = 1.3 if GameManager.celular else 1.0
	hb.scale = Vector2.ONE * esc
	hb.position = Vector2((vp.x - hb.size.x * esc) * 0.5, 120.0 * esc)

func _zerar() -> void:
	var p = get_tree().get_first_node_in_group("player")
	if p and p.chapeu_voando:
		return
	PowerUps.limpar()

func _menu() -> void:
	get_tree().paused = false
	AudioManager.reiniciar_musica()
	GameManager.reset_game()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
