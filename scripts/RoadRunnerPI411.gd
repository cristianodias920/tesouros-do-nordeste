extends Control
class_name RoadRunnerPI411

signal chegou_ao_portal

const DISTANCIA_FINAL := 2700.0
const VELOCIDADE := 155.0
const ALCANCE_VISIVEL := 1900.0
const POSICAO_JOGADOR := 710.0

const ITENS_ESTRADA: Array[Dictionary] = [
	{"distancia": 260.0, "faixa": 0, "tipo": "tesouro"},
	{"distancia": 480.0, "faixa": 2, "tipo": "pedra"},
	{"distancia": 760.0, "faixa": 1, "tipo": "tesouro"},
	{"distancia": 1010.0, "faixa": 0, "tipo": "galho"},
	{"distancia": 1260.0, "faixa": 2, "tipo": "tesouro"},
	{"distancia": 1510.0, "faixa": 1, "tipo": "pedra"},
	{"distancia": 1780.0, "faixa": 0, "tipo": "tesouro"},
	{"distancia": 2040.0, "faixa": 2, "tipo": "galho"},
	{"distancia": 2320.0, "faixa": 1, "tipo": "tesouro"},
]

var progresso: float = 0.0
var faixa: int = 1
var pulando: float = 0.0
var freio_tempo: float = 0.0
var tempo_no_trecho: float = 0.0
var tesouros: Array[Area2D] = []
var itens: Array[Dictionary] = []
var marcou_chegada := false
var voltar_tocado := false
var aviso: Label
var controles: Label
var botao_voltar: Button
var texture_rider: Texture2D
var texture_gema: Texture2D
var hud: Node

func configurar(marcadores: Array[Area2D], pai_hud: Node) -> void:
	tesouros = marcadores
	hud = pai_hud

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_rider = load("res://sprites/fase3/zeca_faisca_costas.png")
	texture_gema = load("res://sprites/items/gema.png")
	var indice_gema := 0
	for i in ITENS_ESTRADA.size():
		var item: Dictionary = ITENS_ESTRADA[i].duplicate()
		item["resolvido"] = false
		if item.tipo == "tesouro":
			item["marcador"] = tesouros[indice_gema] if indice_gema < tesouros.size() else null
			indice_gema += 1
		else:
			item["marcador"] = null
		itens.append(item)
	aviso = Label.new()
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.add_theme_font_size_override("font_size", 42)
	aviso.add_theme_color_override("font_color", Color(1.0, 0.96, 0.78))
	aviso.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.04))
	aviso.add_theme_constant_override("outline_size", 8)
	aviso.position = Vector2(260, 90)
	aviso.size = Vector2(1400, 74)
	aviso.text = "PI-411 • Riacho Frio → Parnaguá"
	add_child(aviso)
	controles = Label.new()
	controles.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controles.add_theme_font_size_override("font_size", 28)
	controles.add_theme_color_override("font_color", Color(1.0, 0.98, 0.88))
	controles.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.04))
	controles.add_theme_constant_override("outline_size", 6)
	controles.position = Vector2(260, 164)
	controles.size = Vector2(1400, 48)
	controles.text = "← → trocar de faixa   •   Espaço / botão de pulo   •   ↓ / S ou VOLTAR para buscar tesouros"
	add_child(controles)
	if GameManager.celular:
		botao_voltar = Button.new()
		botao_voltar.text = "VOLTAR"
		botao_voltar.focus_mode = Control.FOCUS_NONE
		botao_voltar.add_theme_font_size_override("font_size", 26)
		botao_voltar.position = Vector2(440, size.y - 130)
		botao_voltar.size = Vector2(210, 76)
		botao_voltar.button_down.connect(_comecar_a_voltar)
		botao_voltar.button_up.connect(_parar_de_voltar)
		add_child(botao_voltar)
		get_viewport().size_changed.connect(_reposicionar_botao)
	if hud != null:
		var btn_descer = hud.get("btn_descer")
		if btn_descer:
			btn_descer.visible = false
	queue_redraw()

func _reposicionar_botao() -> void:
	if botao_voltar:
		botao_voltar.position = Vector2(440, get_viewport_rect().size.y - 130)

func _comecar_a_voltar() -> void:
	voltar_tocado = true

func _parar_de_voltar() -> void:
	voltar_tocado = false

func _process(delta: float) -> void:
	tempo_no_trecho += delta
	if Input.is_action_just_pressed("move_left"):
		faixa = max(0, faixa - 1)
	if Input.is_action_just_pressed("move_right"):
		faixa = min(2, faixa + 1)
	if Input.is_action_just_pressed("jump"):
		pulando = 0.85
	if pulando > 0.0:
		pulando = maxf(0.0, pulando - delta)
	if freio_tempo > 0.0:
		freio_tempo = maxf(0.0, freio_tempo - delta)
	var voltar := voltar_tocado or Input.is_action_pressed("descer")
	if voltar:
		progresso = maxf(0.0, progresso - VELOCIDADE * 1.35 * delta)
	elif progresso < DISTANCIA_FINAL:
		var fator := 0.48 if freio_tempo > 0.0 else 1.0
		progresso = minf(DISTANCIA_FINAL, progresso + VELOCIDADE * fator * delta)
	if progresso >= DISTANCIA_FINAL:
		marcou_chegada = true
		aviso.text = "Chegamos a Parnaguá! Atravesse o portal com o pulo."
		controles.text = "Se faltou algum tesouro, segure VOLTAR ou ↓ / S para retornar."
		if Input.is_action_just_pressed("jump"):
			chegou_ao_portal.emit()
			set_process(false)
	else:
		marcou_chegada = false
		aviso.text = "PI-411 • Riacho Frio → Parnaguá"
		var obstaculo_proximo := _obstaculo_na_faixa()
		if obstaculo_proximo >= 0.0 and obstaculo_proximo < 420.0:
			controles.text = "Pule agora! Obstáculo à frente na sua faixa."
		elif tempo_no_trecho < 8.0:
			controles.text = "Setas/← → trocam de faixa • Pulo desvia de obstáculos • Dá para voltar."
		else:
			controles.text = "A estrada é curta e tranquila. Observe as faixas e os avisos."
	_resolver_encontros(voltar)
	queue_redraw()

func _obstaculo_na_faixa() -> float:
	var proximo := 99999.0
	for item in itens:
		if item.tipo == "tesouro" or item.resolvido or int(item.faixa) != faixa:
			continue
		var distancia: float = float(item.distancia) - progresso
		if distancia >= 0.0:
			proximo = minf(proximo, distancia)
	return -1.0 if proximo == 99999.0 else proximo

func _resolver_encontros(voltando: bool) -> void:
	for i in itens.size():
		var item: Dictionary = itens[i]
		if item.resolvido or int(item.faixa) != faixa:
			continue
		if absf(float(item.distancia) - progresso) > 44.0:
			continue
		if voltando and item.tipo != "tesouro":
			continue
		item.resolvido = true
		itens[i] = item
		if item.tipo == "tesouro":
			var marcador: Area2D = item.marcador
			if is_instance_valid(marcador) and not bool(marcador.get("collected")):
				marcador.set("collected", true)
				marcador.remove_from_group("gemas")
				marcador.queue_free()
				GameManager.add_gem()
		else:
			if pulando <= 0.0:
				freio_tempo = 1.0
			controles.text = "Boa! Vamos devagar e com atenção."

func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2.ZERO, size), Color("9ed5e7"))
	draw_rect(Rect2(0, 0, w, h * 0.28), Color("8cc9e0"))
	draw_colored_polygon(PackedVector2Array([Vector2(0, h * 0.48), Vector2(w * 0.27, h * 0.22), Vector2(w * 0.73, h * 0.22), Vector2(w, h * 0.48)]), Color("668c59"))
	# Faixa de cerrado em perspectiva, sem sugerir que o desenho seja um registro literal da rodovia.
	for i in range(7):
		var x := float(i) * w / 6.0
		draw_colored_polygon(PackedVector2Array([Vector2(x - 36, h * 0.60), Vector2(x, h * 0.33), Vector2(x + 42, h * 0.60)]), Color("748c4e"))
	var trilha := PackedVector2Array([Vector2(w * 0.34, h * 0.27), Vector2(w * 0.66, h * 0.27), Vector2(w * 0.88, h), Vector2(w * 0.12, h)])
	draw_colored_polygon(trilha, Color("6f5a46"))
	draw_line(Vector2(w * 0.34, h * 0.27), Vector2(w * 0.12, h), Color("d3b486"), 12.0)
	draw_line(Vector2(w * 0.66, h * 0.27), Vector2(w * 0.88, h), Color("d3b486"), 12.0)
	for divisor in [1, 2]:
		var t := float(divisor) / 3.0
		var x_top := lerpf(w * 0.34, w * 0.66, t)
		var x_bottom := lerpf(w * 0.12, w * 0.88, t)
		draw_line(Vector2(x_top, h * 0.28), Vector2(x_bottom, h), Color(0.94, 0.82, 0.58, 0.8), 6.0)
	# Travessas pontilhadas dão sensação de movimento sem acelerar demais a cena.
	for i in range(8):
		var phase := fmod(float(i) * 170.0 + progresso * 0.7, 1180.0) / 1180.0
		var y := h * 0.34 + phase * h * 0.55
		var half := lerpf(18.0, w * 0.32, phase)
		draw_line(Vector2(w * 0.5 - half, y), Vector2(w * 0.5 + half, y), Color(0.39, 0.30, 0.23, 0.42), 5.0 + phase * 7.0)
	# Objetos surgem no horizonte e crescem à medida que o Faísca se aproxima.
	for item in itens:
		if item.resolvido:
			continue
		var diferenca: float = float(item.distancia) - progresso
		if diferenca < -520.0 or diferenca > ALCANCE_VISIVEL:
			continue
		var profundidade := clampf(1.0 - diferenca / ALCANCE_VISIVEL, 0.10, 1.0)
		var y := POSICAO_JOGADOR - diferenca / ALCANCE_VISIVEL * h * 0.47
		var x := _centro_faixa(int(item.faixa), w)
		var escala := lerpf(0.24, 1.0, profundidade)
		if item.tipo == "tesouro":
			if texture_gema:
				draw_texture_rect(texture_gema, Rect2(Vector2(x - 28 * escala, y - 28 * escala), Vector2(56 * escala, 56 * escala)), false)
		else:
			var tam := 66.0 * escala
			var cor := Color("76624e") if item.tipo == "pedra" else Color("775b38")
			draw_rect(Rect2(x - tam * 0.5, y - tam * 0.34, tam, tam * 0.68), cor, true)
			draw_rect(Rect2(x - tam * 0.38, y - tam * 0.2, tam * 0.76, tam * 0.18), Color("a78b67"), true)
	# Zeca e Faísca ficam visíveis na parte inferior e trocam de faixa ao toque.
	var centro := _centro_faixa(faixa, w)
	var subida := sin((0.85 - pulando) * PI / 0.85) * 64.0 if pulando > 0.0 else 0.0
	if texture_rider:
		draw_texture_rect(texture_rider, Rect2(Vector2(centro - 130, POSICAO_JOGADOR - 250 - subida), Vector2(260, 390)), false)
	if marcou_chegada:
		var gx := w * 0.5
		draw_arc(Vector2(gx, h * 0.40), 110.0, PI, TAU, 48, Color("ffe18a"), 15.0, true)
		draw_line(Vector2(gx - 110, h * 0.40), Vector2(gx - 110, h * 0.70), Color("9b5b27"), 18.0)
		draw_line(Vector2(gx + 110, h * 0.40), Vector2(gx + 110, h * 0.70), Color("9b5b27"), 18.0)

func _centro_faixa(indice: int, largura: float) -> float:
	var largura_estrada := largura * 0.76
	var inicio := (largura - largura_estrada) * 0.5
	return inicio + largura_estrada * (float(indice) + 0.5) / 3.0
