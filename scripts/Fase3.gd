extends Node2D

const FASE_ID := "fase3_riacho_frio"
const CHAO_Y := 800.0
const PORTAL_ESTRADA_X := 5000.0
const PARNAGUA_INICIO_X := 6500.0
const PARNAGUA_FIM_X := 11100.0
const ESTRADA_DISTANCIA_MUNDO := 1500.0

const GEMA_SCENE := preload("res://scenes/Gema.tscn")
const PLACA_GRANDE_SCENE := preload("res://scenes/PlacaGrande.tscn")
const FAISCA_SCENE := preload("res://scenes/Faisca.tscn")
const CHEGADA_SCENE := preload("res://scenes/Chegada.tscn")
const ROAD_SCENE := preload("res://scripts/RoadRunnerPI411.gd")
const PORTAL_TEXTURE := preload("res://sprites/corrente/portal.png")
const RIACHO_BG := preload("res://sprites/fase3/riacho_frio_bg.png")
const PARNAGUA_BG := preload("res://sprites/fase3/parnagua_lagoa_bg.png")

var player: Player
var hud: CanvasLayer
var road_runner: RoadRunnerPI411
var road_active := false
var road_started := false
var _falou_riacho := false
var _falou_parnagua := false

func _enter_tree() -> void:
	GameManager.FASE_ID = FASE_ID

func _ready() -> void:
	player = $Player
	hud = $HUD
	_build_world()
	_configurar_tela()
	_configurar_intro()
	AudioManager.tocar_musica("forro", true)
	AudioManager.set_ambiente("passaros", 0.7)
	AudioManager.set_ambiente("rio", 0.25)
	VoiceLines.say("inicio")

func _build_world() -> void:
	_criar_fundo(RIACHO_BG, 0.0, 3)
	_criar_fundo(PARNAGUA_BG, PARNAGUA_INICIO_X, 3)
	_criar_chao(0.0, PORTAL_ESTRADA_X)
	_criar_chao(PARNAGUA_INICIO_X, PARNAGUA_FIM_X)
	_criar_faisca()
	_criar_tesouros_cidade()
	_criar_placas()
	_criar_portal_de_partida()
	_criar_chegada()
	_criar_marcadores_estrada()

func _configurar_tela() -> void:
	player.position = Vector2(260.0, CHAO_Y)
	player.camera.limit_left = 0
	player.camera.limit_right = int(PARNAGUA_FIM_X + 900.0)
	player.camera.limit_top = -200
	player.camera.limit_bottom = 1050
	player.camera.limit_smoothed = true
	player.camera.position_smoothing_enabled = true
	var titulo: Label = hud.get_node_or_null("TopCenter/PhaseTitleLabel")
	if titulo:
		titulo.text = "FASE 3 • RIACHO FRIO E PARNAGUÁ"

func _configurar_intro() -> void:
	if hud.intro == null:
		return
	var vb: VBoxContainer = hud.intro.get_child(1).get_child(0)
	if vb.get_child_count() > 0:
		vb.get_child(0).text = "FASE 3 • RIACHO FRIO E PARNAGUÁ"
		vb.get_child(0).add_theme_font_size_override("font_size", 44)
	if vb.get_child_count() > 1:
		vb.get_child(1).get_child(1).text = "Explore as duas cidades e atravesse a PI-411."
		vb.get_child(1).get_child(1).add_theme_font_size_override("font_size", 32)
	hud._center_intro()

func _criar_fundo(textura: Texture2D, inicio_x: float, quantidade: int) -> void:
	for i in quantidade:
		var fundo := Sprite2D.new()
		fundo.texture = textura
		fundo.centered = false
		fundo.position = Vector2(inicio_x + i * 1810.0, -145.0)
		fundo.scale = Vector2(1.02, 1.02)
		fundo.z_index = -20
		add_child(fundo)
		move_child(fundo, 0)

func _criar_chao(inicio_x: float, fim_x: float) -> void:
	var largura := fim_x - inicio_x
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(inicio_x, CHAO_Y), Vector2(fim_x, CHAO_Y),
		Vector2(fim_x, 1300.0), Vector2(inicio_x, 1300.0)
	])
	visual.color = Color("c49a62")
	visual.z_index = -5
	add_child(visual)
	var faixa := Polygon2D.new()
	faixa.polygon = PackedVector2Array([
		Vector2(inicio_x, CHAO_Y), Vector2(fim_x, CHAO_Y),
		Vector2(fim_x, CHAO_Y + 24.0), Vector2(inicio_x, CHAO_Y + 24.0)
	])
	faixa.color = Color("70894e")
	faixa.z_index = -4
	add_child(faixa)
	var corpo := StaticBody2D.new()
	corpo.position = Vector2((inicio_x + fim_x) * 0.5, CHAO_Y + 35.0)
	corpo.collision_layer = 1
	corpo.collision_mask = 0
	var forma := CollisionShape2D.new()
	var retangulo := RectangleShape2D.new()
	retangulo.size = Vector2(largura, 70.0)
	forma.shape = retangulo
	corpo.add_child(forma)
	add_child(corpo)

func _criar_faisca() -> void:
	var faisca: Area2D = FAISCA_SCENE.instantiate()
	faisca.position = Vector2(1750.0, CHAO_Y)
	add_child(faisca)

func _criar_tesouros_cidade() -> void:
	for x in [720.0, 1400.0, 2650.0, 4050.0, 6900.0, 7900.0, 9100.0, 10400.0]:
		var gema: Area2D = GEMA_SCENE.instantiate()
		gema.position = Vector2(x, CHAO_Y - 125.0)
		add_child(gema)
	for x in [1950.0, 3280.0, 7460.0, 9650.0]:
		var gema: Area2D = GEMA_SCENE.instantiate()
		gema.position = Vector2(x, CHAO_Y - 220.0)
		add_child(gema)

func _criar_placas() -> void:
	_adicionar_placa(Vector2(1050.0, CHAO_Y), "RIACHO FRIO", "No extremo sul do Piauí, Riacho Frio está entre os destinos de cachoeiras do estado.")
	_adicionar_placa(Vector2(7600.0, CHAO_Y), "PARNAGUÁ", "O município foi instalado em 1762, junto à Lagoa de Parnaguá.")

func _adicionar_placa(posicao: Vector2, titulo: String, texto: String) -> void:
	var placa: Node2D = PLACA_GRANDE_SCENE.instantiate()
	placa.position = posicao
	placa.titulo = titulo
	placa.texto = texto
	placa.largura = 720.0
	placa.altura = 230.0
	add_child(placa)

func _criar_portal_de_partida() -> void:
	var portal := Area2D.new()
	portal.name = "PortalParaEstrada"
	portal.position = Vector2(PORTAL_ESTRADA_X, CHAO_Y)
	portal.collision_layer = 0
	portal.collision_mask = 2
	var sprite := Sprite2D.new()
	sprite.texture = PORTAL_TEXTURE
	sprite.position = Vector2(0, -300)
	sprite.scale = Vector2(1.05, 1.05)
	portal.add_child(sprite)
	var label := Label.new()
	label.text = "ESTRADA PI-411"
	label.position = Vector2(-210, -530)
	label.size = Vector2(420, 70)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", Color("fff0b0"))
	label.add_theme_color_override("font_outline_color", Color("44200d"))
	label.add_theme_constant_override("outline_size", 7)
	portal.add_child(label)
	var forma := CollisionShape2D.new()
	var retangulo := RectangleShape2D.new()
	retangulo.size = Vector2(150, 650)
	forma.shape = retangulo
	forma.position = Vector2(0, -325)
	portal.add_child(forma)
	portal.body_entered.connect(_on_entrar_portal)
	add_child(portal)

func _criar_chegada() -> void:
	var chegada: Area2D = CHEGADA_SCENE.instantiate()
	chegada.position = Vector2(PARNAGUA_FIM_X - 260.0, CHAO_Y)
	add_child(chegada)

func _criar_marcadores_estrada() -> void:
	var marcadores: Array[Area2D] = []
	for item in RoadRunnerPI411.ITENS_ESTRADA:
		if item.tipo != "tesouro":
			continue
		var marcador: Area2D = GEMA_SCENE.instantiate()
		var fator: float = ESTRADA_DISTANCIA_MUNDO / RoadRunnerPI411.DISTANCIA_FINAL
		marcador.position = Vector2(PORTAL_ESTRADA_X + float(item.distancia) * fator, 0.0)
		marcador.visible = false
		add_child(marcador)
		marcadores.append(marcador)
	set_meta("marcadores_estrada", marcadores)

func _on_entrar_portal(body: Node2D) -> void:
	if body is Player:
		_iniciar_estrada()

func _iniciar_estrada() -> void:
	if road_started or GameManager.is_level_ended:
		return
	road_started = true
	road_active = true
	if not player.is_mounted:
		player.mount_faisca()
	player.velocity = Vector2.ZERO
	player.visible = false
	player.set_physics_process(false)
	road_runner = ROAD_SCENE.new()
	var marcadores: Array[Area2D] = get_meta("marcadores_estrada")
	road_runner.configurar(marcadores, hud)
	hud.add_child(road_runner)
	hud.move_child(road_runner, 0)
	AudioManager.set_ambiente("rio", 0.0)
	AudioManager.set_ambiente("passaros", 0.45)
	road_runner.chegou_ao_portal.connect(_chegou_a_parnagua)

func _chegou_a_parnagua() -> void:
	road_active = false
	if is_instance_valid(road_runner):
		road_runner.queue_free()
	player.visible = true
	player.set_physics_process(true)
	player.velocity = Vector2.ZERO
	player.global_position = Vector2(PARNAGUA_INICIO_X + 170.0, CHAO_Y)
	player.spawn_position = player.global_position
	player.camera.limit_left = int(PARNAGUA_INICIO_X)
	player.camera.limit_right = int(PARNAGUA_FIM_X + 900.0)
	GameManager.set_checkpoint(player.global_position)
	AudioManager.set_ambiente("rio", 0.15)
	AudioManager.set_ambiente("passaros", 0.65)

func area_de(pos: Vector2) -> String:
	if road_active:
		return "Estrada PI-411"
	if pos.x < PORTAL_ESTRADA_X:
		return "Riacho Frio: riacho e cachoeiras"
	if pos.x < PARNAGUA_INICIO_X:
		return "Estrada PI-411"
	return "Parnaguá: Lagoa e centro"

func areas_da_fase() -> Array:
	return ["Riacho Frio: riacho e cachoeiras", "Estrada PI-411", "Parnaguá: Lagoa e centro"]

func _process(_delta: float) -> void:
	if GameManager.is_level_ended:
		return
	var p := get_tree().get_first_node_in_group("player") as Player
	if p == null:
		return
	if not road_started and p.global_position.x >= PORTAL_ESTRADA_X - 90.0:
		_iniciar_estrada()
	if not _falou_riacho and p.global_position.x >= 850.0:
		_falou_riacho = true
		VoiceLines.say("fase3_riacho")
	if not _falou_parnagua and p.global_position.x >= PARNAGUA_INICIO_X + 500.0:
		_falou_parnagua = true
		VoiceLines.say("fase3_parnagua")
	if p.global_position.x < PORTAL_ESTRADA_X - 300.0:
		AudioManager.set_ambiente("rio", 0.45)
	elif p.global_position.x > PARNAGUA_INICIO_X:
		AudioManager.set_ambiente("rio", 0.15)
	AudioManager.tocar_musica("forro")
