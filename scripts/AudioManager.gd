extends Node

# Gerenciador global de áudio: música (com troca suave de faixa), efeitos,
# sons de ambiente e volumes separados (Música / Vozes / Efeitos), salvos no aparelho.
var sound_enabled: bool = true
var music_player: AudioStreamPlayer   # faixa atual (o VoiceLines abaixa o volume dela)
var music_fade: AudioStreamPlayer     # faixa que está saindo na troca
var sfx_players: Dictionary = {}
var music_started: bool = false
var faixa_atual: String = "forro"
var amb_players: Dictionary = {}      # id -> AudioStreamPlayer em loop
var amb_alvo: Dictionary = {}         # id -> volume alvo (0..1)

const BUS_MUSICA := "Musica"
const BUS_VOZ := "Vozes"
const BUS_EFEITOS := "Efeitos"
var volumes: Dictionary = {"musica": 0.8, "vozes": 1.0, "efeitos": 0.9}

const MUSICAS: Dictionary = {
	"forro": "res://audio/bgm_forro.ogg",
	"nuvens": "res://audio/bgm_nuvens.ogg",
	"cris_festa": "res://audio/bgm_cris_festa.ogg",       # Cristalândia: baião festivo (festejo de Sant'Ana)
	"cris_cristais": "res://audio/bgm_cris_cristais.ogg", # Cristalândia: veios de cristal (mesma levada, mais brilhante)
}
# Cada fase tem o seu conjunto de faixas; só as do conjunto atual tocam (juntas, desde o começo).
const CONJUNTOS: Dictionary = {
	"corrente": ["forro", "nuvens"],
	"cristalandia": ["cris_festa", "cris_cristais"],
}
var conjunto: String = "corrente"
const AMBIENTES: Dictionary = {
	"passaros": "res://audio/amb_passaros.ogg",
	"rio": "res://audio/amb_rio.ogg",
}

var sound_paths = {
	"jump": "res://audio/jump.wav",
	"gem": "res://audio/gem.wav",
	"crate": "res://audio/crate_hit.wav",
	"powerup": "res://audio/powerup.wav",
	"mount": "res://audio/mount.wav",
	"kick": "res://audio/kick.wav",
	"hurt": "res://audio/hurt.wav",
	"checkpoint": "res://audio/checkpoint.wav",
	"splash": "res://audio/splash.wav",
	"victory": "res://audio/victory.wav",
	"zurro": "res://audio/zurro.wav",
	"derrota": "res://audio/derrota.wav",
	"planar": "res://audio/planar.wav",
	"chapeu_lanca": "res://audio/chapeu_lanca.wav",
	"chapeu_volta": "res://audio/chapeu_volta.wav",
	"cristal_trinca": "res://audio/cristal_trinca.wav",
	"cristal_quebra": "res://audio/cristal_quebra.wav",
	"poder_troca": "res://audio/poder_troca.wav",
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_criar_buses()
	for id in MUSICAS:
		var mp := AudioStreamPlayer.new()
		mp.name = "Musica_" + id
		mp.bus = BUS_MUSICA
		mp.volume_db = -80.0
		mp.stream = _carregar_musica(id)
		add_child(mp)
		faixas[id] = mp
		ganho[id] = 1.0 if id == faixa_atual else 0.0
	music_player = faixas[faixa_atual]
	music_fade = null

	for sfx_name in sound_paths:
		var p = AudioStreamPlayer.new()
		p.bus = BUS_EFEITOS
		p.volume_db = -3.0
		add_child(p)
		if ResourceLoader.exists(sound_paths[sfx_name]):
			p.stream = load(sound_paths[sfx_name])
		sfx_players[sfx_name] = p
	for id in AMBIENTES:
		var a := AudioStreamPlayer.new()
		a.bus = BUS_EFEITOS
		a.volume_db = -80.0
		add_child(a)
		if ResourceLoader.exists(AMBIENTES[id]):
			var st: AudioStream = load(AMBIENTES[id])
			if st is AudioStreamOggVorbis:
				(st as AudioStreamOggVorbis).loop = true
			a.stream = st
		amb_players[id] = a
		amb_alvo[id] = 0.0
	# volumes salvos
	for k in volumes.keys():
		var salvo = Progresso.get_opcao("vol_" + k, volumes[k])
		var v: float = volumes[k]
		if typeof(salvo) == TYPE_FLOAT or typeof(salvo) == TYPE_INT:
			v = float(salvo)
		if is_nan(v) or is_inf(v):
			v = volumes[k]
		set_volume(k, v, false)
	var som_salvo = Progresso.get_opcao("som", true)
	sound_enabled = som_salvo if typeof(som_salvo) == TYPE_BOOL else true
	AudioServer.set_bus_mute(0, not sound_enabled)

# Os buses vêm de res://default_bus_layout.tres (precisa existir desde o início:
# no navegador o Godot toca os sons pelo Web Audio e um bus criado só por código
# não chega lá, e aí tudo fica mudo). Isto aqui é só reserva.
func _criar_buses() -> void:
	for nome in [BUS_MUSICA, BUS_VOZ, BUS_EFEITOS]:
		if AudioServer.get_bus_index(nome) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, nome)
			AudioServer.set_bus_send(i, "Master")

func _carregar_musica(id: String) -> AudioStream:
	var path: String = MUSICAS.get(id, "")
	if path == "" or not ResourceLoader.exists(path):
		return null
	var st: AudioStream = load(path)
	if st is AudioStreamOggVorbis:
		(st as AudioStreamOggVorbis).loop = true
	return st

# 0..1 por canal ("musica", "vozes", "efeitos")
func set_volume(canal: String, v: float, salvar: bool = true) -> void:
	v = clamp(v, 0.0, 1.0)
	volumes[canal] = v
	var bus_nome: String = {"musica": BUS_MUSICA, "vozes": BUS_VOZ, "efeitos": BUS_EFEITOS}.get(canal, "")
	var i := AudioServer.get_bus_index(bus_nome)
	if i >= 0:
		AudioServer.set_bus_volume_db(i, linear_to_db(max(v, 0.0001)))
		AudioServer.set_bus_mute(i, v <= 0.001)
	if salvar:
		Progresso.set_opcao("vol_" + canal, v)

func _input(event: InputEvent) -> void:
	if not music_started:
		if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
			start_music()

func start_music() -> void:
	if music_started:
		return
	music_started = true
	_tocar_todas_do_inicio()

# ---- Música: as duas faixas tocam juntas o tempo todo, em loop, e a troca é só de volume ----
# (cruzamento de potência igual, ~3 s). Nunca se pula para o meio da faixa com play(posição):
# no navegador o Godot reinicia o loop a partir da posição do play(), e a música ficava
# presa tocando só o finalzinho. Assim cada faixa "continua de onde estava" naturalmente.
const MUSIC_DB: float = -10.0
const CROSSFADE_S: float = 3.0
var faixas: Dictionary = {}       # id -> AudioStreamPlayer
var ganho: Dictionary = {}        # id -> 0..1 (posição no cruzamento, linear)
var duck_db: float = 0.0          # o VoiceLines abaixa a música enquanto o Zeca fala
var fade_in_db: float = 0.0       # (compatibilidade) não é mais usado
var trocas: int = 0               # quantas trocas de faixa já começaram (para testes)
var plays: int = 0                # quantas vezes alguma faixa recebeu play() (para testes)
var cruzando: bool = false
var _vigia: float = 0.0

func get_music_extra_db() -> float:
	return 0.0

func _tocar_todas_do_inicio() -> void:
	var lista: Array = CONJUNTOS.get(conjunto, [])
	for k in faixas:
		var mp: AudioStreamPlayer = faixas[k]
		mp.stop()
		if mp.stream and k in lista:
			mp.play()      # sempre do começo (0 s)
			plays += 1
	_aplicar_volumes_musica()

# Troca o conjunto de músicas da fase (ex.: Cristalândia). As faixas do conjunto novo
# começam do início, juntas; as do conjunto antigo param. Mesmo conjunto: só garante a faixa.
func usar_conjunto(nome: String, faixa: String) -> void:
	if not CONJUNTOS.has(nome) or not faixas.has(faixa):
		return
	if nome == conjunto:
		tocar_musica(faixa, true)
		return
	conjunto = nome
	for k in faixas:
		ganho[k] = 1.0 if k == faixa else 0.0
	trocas += 1
	faixa_atual = faixa
	music_player = faixas[faixa]
	cruzando = false
	if music_started:
		_tocar_todas_do_inicio()
	else:
		_aplicar_volumes_musica()

# Volta a música ao estado inicial (forró do começo). Usado ao ir para o menu
# ou recomeçar a fase, para nunca levar um estado estranho de uma cena para outra.
func reiniciar_musica() -> void:
	conjunto = "corrente"
	for k in faixas:
		ganho[k] = 1.0 if k == "forro" else 0.0
	if faixa_atual != "forro":
		trocas += 1
	faixa_atual = "forro"
	music_player = faixas["forro"]
	duck_db = 0.0
	cruzando = false
	if music_started:
		_tocar_todas_do_inicio()

func tocar_musica(id: String, imediato: bool = false) -> void:
	if not faixas.has(id):
		return
	if not (id in CONJUNTOS.get(conjunto, [])):
		for nome in CONJUNTOS:
			if id in CONJUNTOS[nome]:
				usar_conjunto(nome, id)
				return
	if imediato:
		for k in faixas:
			ganho[k] = 1.0 if k == id else 0.0
	if id != faixa_atual:
		trocas += 1
		cruzando = not imediato
	faixa_atual = id
	music_player = faixas[id]
	_aplicar_volumes_musica()

func _aplicar_volumes_musica() -> void:
	for k in faixas:
		var g: float = clamp(float(ganho[k]), 0.0, 1.0)
		# potência igual: sin/cos do cruzamento (soma das potências sempre = 1)
		var lin: float = sin(g * PI * 0.5)
		var mp: AudioStreamPlayer = faixas[k]
		mp.volume_db = -80.0 if lin < 0.001 else MUSIC_DB + duck_db + linear_to_db(lin)

func _processar_musica(delta: float) -> void:
	var passo: float = delta / CROSSFADE_S
	cruzando = false
	for k in faixas:
		var alvo: float = 1.0 if k == faixa_atual else 0.0
		ganho[k] = move_toward(float(ganho[k]), alvo, passo)
		if not is_equal_approx(float(ganho[k]), alvo):
			cruzando = true
	_aplicar_volumes_musica()
	# vigia: se alguma faixa parou sozinha, volta a tocar DO COMEÇO (no máximo a cada 2 s)
	_vigia -= delta
	if music_started and _vigia <= 0.0:
		_vigia = 2.0
		for k in CONJUNTOS.get(conjunto, []):
			var mp: AudioStreamPlayer = faixas[k]
			if mp.stream and not mp.playing:
				mp.play()
				plays += 1

func set_ambiente(id: String, v: float) -> void:
	amb_alvo[id] = clamp(v, 0.0, 1.0)

func _process(delta: float) -> void:
	_processar_musica(delta)
	for id in amb_players:
		var a: AudioStreamPlayer = amb_players[id]
		if a.stream == null:
			continue
		var alvo: float = float(amb_alvo[id])
		var db_alvo: float = -80.0 if alvo <= 0.01 else linear_to_db(alvo) - 14.0
		a.volume_db = move_toward(a.volume_db, db_alvo, delta * 30.0)
		if alvo > 0.01 and not a.playing and music_started:
			a.play()
		elif alvo <= 0.01 and a.playing and a.volume_db <= -79.0:
			a.stop()

func play_sfx(sfx_name: String) -> void:
	if not sound_enabled:
		return
	if sfx_players.has(sfx_name) and sfx_players[sfx_name].stream:
		sfx_players[sfx_name].play()

func toggle_sound() -> bool:
	sound_enabled = not sound_enabled
	AudioServer.set_bus_mute(0, not sound_enabled)
	if not sound_enabled:
		for p in sfx_players.values():
			p.stop()
	Progresso.set_opcao("som", sound_enabled)
	return sound_enabled
