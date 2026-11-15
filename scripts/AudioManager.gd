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
}
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
		pos_faixa[id] = 0.0
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
	_aplicar_volumes_musica()
	var mp: AudioStreamPlayer = faixas.get(faixa_atual)
	if mp and mp.stream:
		mp.play(_pos_valida(faixa_atual))

# ---- Música: uma faixa por player, troca com cruzamento de potência igual ----
# Cada faixa continua de onde parou (a posição fica guardada enquanto ela está calada).
# Se a troca for desfeita no meio, o cruzamento só volta, sem pular.
const MUSIC_DB: float = -10.0
const CROSSFADE_S: float = 3.0
var faixas: Dictionary = {}       # id -> AudioStreamPlayer
var ganho: Dictionary = {}        # id -> 0..1 (posição no cruzamento, linear)
var pos_faixa: Dictionary = {}    # id -> segundos (onde a faixa parou / está)
var duck_db: float = 0.0          # o VoiceLines abaixa a música enquanto o Zeca fala
var fade_in_db: float = 0.0       # (compatibilidade) não é mais usado
var trocas: int = 0               # quantas trocas de faixa já começaram (para testes)
var cruzando: bool = false

func get_music_extra_db() -> float:
	return 0.0

func tocar_musica(id: String, imediato: bool = false) -> void:
	if not faixas.has(id):
		return
	if imediato:
		for k in faixas:
			ganho[k] = 1.0 if k == id else 0.0
			if k != id:
				_calar(k)
		if id != faixa_atual:
			trocas += 1
		faixa_atual = id
		music_player = faixas[id]
		if music_started and not music_player.playing and music_player.stream:
			music_player.play(_pos_valida(id))
		_aplicar_volumes_musica()
		return
	if id == faixa_atual:
		return
	faixa_atual = id
	music_player = faixas[id]
	trocas += 1
	cruzando = true
	if music_started and not music_player.playing and music_player.stream:
		music_player.play(_pos_valida(id))

func _pos_valida(id: String) -> float:
	var mp: AudioStreamPlayer = faixas[id]
	var p: float = float(pos_faixa.get(id, 0.0))
	if mp.stream:
		var dur: float = mp.stream.get_length()
		if dur > 0.5:
			p = fmod(p, dur)
	return p

func _calar(id: String) -> void:
	var mp: AudioStreamPlayer = faixas[id]
	if mp.playing:
		mp.stop()
	mp.volume_db = -80.0

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
		var mp: AudioStreamPlayer = faixas[k]
		if mp.playing:
			pos_faixa[k] = float(pos_faixa[k]) + delta
		if float(ganho[k]) <= 0.0 and mp.playing:
			_calar(k)   # guarda a posição (pos_faixa) para continuar depois
		elif float(ganho[k]) > 0.0 and music_started and not mp.playing and mp.stream:
			mp.play(_pos_valida(k))
	_aplicar_volumes_musica()

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
