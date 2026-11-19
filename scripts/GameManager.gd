extends Node

# Gerenciador global do jogo (Vidas, Tesouros, Checkpoint, Estado)
signal lives_changed(current_lives: int)
signal gems_changed(current_gems: int, total_gems: int)
signal checkpoint_activated(pos: Vector2)
signal level_completed
signal game_over
signal player_respawned
signal mundo_mudou(fundo: bool)
signal continuou_do_checkpoint

# Total de tesouros é contado na fase (gemas + comidas + caixotes com gema)
var TOTAL_GEMS: int = 0
const MAX_LIVES: int = 3

var current_lives: int = 3
var collected_gems: int = 0
var checkpoint_pos: Vector2 = Vector2.ZERO
var has_checkpoint: bool = false
var checkpoint_fundo: bool = false # checkpoint no caminho do fundo (Serra)
var is_mounted: bool = false
var is_level_ended: bool = false
var is_game_over: bool = false
var tempo: float = 0.0            # tempo de jogo da fase (s), sem pausa nem cartões
var cronometro_ativo: bool = false
var celular: bool = false         # aparelho de toque (textos maiores)
var resultado: Dictionary = {}    # preenchido na vitória (estrelas, recordes...)
var FASE_ID: String = "fase1_corrente"   # a cena da fase define no _ready (Fase1/Fase2)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	celular = OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
	for a in OS.get_cmdline_user_args():
		if a == "celular=1":
			celular = true
	reset_game()

func _process(delta: float) -> void:
	if cronometro_ativo and not is_level_ended and not get_tree().paused:
		tempo += delta

func reset_game() -> void:
	current_lives = MAX_LIVES
	collected_gems = 0
	checkpoint_pos = Vector2.ZERO
	has_checkpoint = false
	checkpoint_fundo = false
	is_mounted = false
	is_level_ended = false
	is_game_over = false
	tempo = 0.0
	cronometro_ativo = false
	resultado = {}
	lives_changed.emit(current_lives)
	gems_changed.emit(collected_gems, TOTAL_GEMS)

func refill_lives() -> void:
	current_lives = MAX_LIVES
	lives_changed.emit(current_lives)

func add_gem() -> void:
	collected_gems += 1
	AudioManager.play_sfx("gem")
	gems_changed.emit(collected_gems, TOTAL_GEMS)

func heal() -> void:
	if current_lives < MAX_LIVES:
		current_lives += 1
		lives_changed.emit(current_lives)
	AudioManager.play_sfx("powerup")

func take_damage() -> bool:
	if is_level_ended:
		return current_lives > 0
	current_lives = max(current_lives - 1, 0)
	AudioManager.play_sfx("hurt")
	lives_changed.emit(current_lives)
	if current_lives <= 0:
		is_level_ended = true
		is_game_over = true
		game_over.emit()
		return false
	return true

func recount_total(tree: SceneTree) -> void:
	# Conta os tesouros que existem na fase: gemas/comidas soltas + caixotes que soltam gema
	var total: int = tree.get_nodes_in_group("gemas").size()
	for c in tree.get_nodes_in_group("caixotes"):
		if c.get("content_type") in ["gema", "ferradura"]:
			total += 1
	TOTAL_GEMS = total
	gems_changed.emit(collected_gems, TOTAL_GEMS)

func set_checkpoint(pos: Vector2, fundo: bool = false) -> void:
	if not has_checkpoint or checkpoint_pos != pos:
		checkpoint_pos = pos
		has_checkpoint = true
		checkpoint_fundo = fundo
		AudioManager.play_sfx("checkpoint")
		checkpoint_activated.emit(pos)

func complete_level() -> void:
	if not is_level_ended:
		is_level_ended = true
		AudioManager.play_sfx("victory")
		var est: int = estrelas_para(collected_gems, TOTAL_GEMS)
		var rec: Dictionary = Progresso.registrar_fase(FASE_ID, est, collected_gems, TOTAL_GEMS, tempo)
		resultado = {"estrelas": est, "tesouros": collected_gems, "total": TOTAL_GEMS, "tempo": tempo, "recordes": rec}
		level_completed.emit()

# 1 estrela por terminar, 2 com 70% dos tesouros, 3 com todos
static func estrelas_para(c: int, total: int) -> int:
	if total > 0 and c >= total:
		return 3
	if total > 0 and float(c) >= 0.7 * float(total):
		return 2
	return 1

# FIM DA AVENTURA -> continua do último checkpoint com os corações cheios
# (os tesouros já pegos continuam pegos e o tempo continua contando)
func continuar_do_checkpoint() -> void:
	current_lives = MAX_LIVES
	is_level_ended = false
	is_game_over = false
	lives_changed.emit(current_lives)
	continuou_do_checkpoint.emit()

# Trechos da fase (para dizer onde ainda há tesouros), na ordem do percurso
func areas_da_fase() -> Array:
	var cena_atual := get_tree().current_scene
	if cena_atual and cena_atual.has_method("areas_da_fase"):
		return cena_atual.areas_da_fase()
	if FASE_ID == "fase2_cristalandia":
		return ["Caminho de Corrente", "Centro e festejo de Sant'Ana", "Rio Palmeira e nascente", "Comunidade Esperança", "Veios de cristal", "Chapada da Limpeza"]
	return ["Começo e Rio Corrente", "Centro de Corrente", "Torre e nuvens", "Vereda de buritis", "Rio Paraim", "Serra Dois Irmãos", "Rio Corrente e ExpoCorrente"]

func area_de(pos: Vector2) -> String:
	var cena_atual := get_tree().current_scene
	if cena_atual and cena_atual.has_method("area_de"):
		return cena_atual.area_de(pos)
	if FASE_ID == "fase2_cristalandia":
		return "Cristalândia"
	if pos.x > 30000:
		return "Serra Dois Irmãos"
	if pos.x < 6200:
		return "Começo e Rio Corrente"
	if pos.x < 9800:
		return "Centro de Corrente"
	if pos.x < 17780:
		return "Torre e nuvens" if pos.y < 300 else "Vereda de buritis"
	if pos.x < 20400:
		return "Rio Paraim"
	return "Rio Corrente e ExpoCorrente"

func tesouros_restantes_por_area(tree: SceneTree) -> Dictionary:
	var res: Dictionary = {}
	var add := func(pos: Vector2):
		var a: String = area_de(pos)
		res[a] = int(res.get(a, 0)) + 1
	for g in tree.get_nodes_in_group("gemas"):
		if is_instance_valid(g) and not g.get("collected"):
			add.call(g.global_position)
	for c in tree.get_nodes_in_group("caixotes"):
		if c.get("content_type") == "gema" and not c.is_opened:
			add.call(c.global_position)
		elif c.get("content_type") == "ferradura" and not c.gave_foot_gem:
			add.call(c.global_position)
	for it in tree.get_nodes_in_group("itens_caixote"):
		if is_instance_valid(it) and it.item_type == "gema" and not it.collected:
			add.call(it.global_position)
	return res
