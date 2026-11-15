extends Node

# Falas do Zeca: toca res://audio/voz/<id>.ogg (ou .wav, quando existir) e mostra uma
# legenda em balão sobre o Zeca, sem bloquear o jogo. Cada fala toca uma vez
# por partida (agua_cai pode repetir, no máximo a cada 30 s).
const LINES: Dictionary = {
	"inicio": "Corrente, aqui vou eu!",
	"faisca_encontro": "Opa! Oi, Faísca!",
	"faisca_monta": "Vamos lá, Faísca!",
	"faisca_foge": "Volta aqui, Faísca!",   # (só balão, ainda sem áudio)
	"checkpoint_primeiro": "Ufa, checkpoint!",
	"rio_corrente": "Olha o Rio Corrente!",
	"igreja_matriz": "A Igreja Matriz de Corrente, que beleza!",
	"nuvens": "Tô andando nas nuvens!",
	"portal": "Um portal? Vamos ver aonde dá!",
	"serra": "A Serra Dois Irmãos! Olha as gravuras!",
	"agua_cai": "Eita, molhei!",
	"expo": "Chegou a ExpoCorrente!",
	"vitoria": "Conseguimos, Faísca!",
	"rapadura": "Rapadura! Agora ninguém me segura!",
	"rio_paraim": "O Rio Paraim, cheio de buritis!",
	"faltam_dez": "Só faltam dez tesouros!",
}
const REPEAT_COOLDOWN: Dictionary = {"agua_cai": 30.0, "rapadura": 25.0, "faisca_foge": 15.0}

var played: Dictionary = {}      # id -> tempo (s) da última vez
var history: Array = []          # ids na ordem em que tocaram (usado nos testes)
var queue: Array = []
var queued_at: Dictionary = {}
const QUEUE_MAX_AGE: float = 3.5  # fala que esperou demais na fila é descartada (fora de contexto)
var current_id: String = ""
var show_time: float = 0.0
var clock: float = 0.0
var fs: int = 34
var no_rodape: bool = false   # na tela de vitória o balão vai para baixo, sem cobrir o painel

var layer: CanvasLayer
var balloon: PanelContainer
var label: Label
var tail: Polygon2D
var player_audio: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	balloon = PanelContainer.new()
	balloon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 0.97, 0.88, 0.94)
	sb.border_color = Color(0.42, 0.26, 0.12)
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(22)
	sb.content_margin_left = 22; sb.content_margin_right = 22
	sb.content_margin_top = 10; sb.content_margin_bottom = 12
	balloon.add_theme_stylebox_override("panel", sb)
	label = Label.new()
	fs = 50 if GameManager.celular else 34   # celular: balão ~1,5x maior
	label.add_theme_font_size_override("font_size", fs)
	label.add_theme_color_override("font_color", Color(0.22, 0.11, 0.03))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(0, 0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	balloon.add_child(label)
	layer.add_child(balloon)
	tail = Polygon2D.new()
	tail.color = Color(1.0, 0.97, 0.88, 0.94)
	tail.polygon = PackedVector2Array([Vector2(-16, -2), Vector2(16, -2), Vector2(0, 24)])
	layer.add_child(tail)
	balloon.visible = false
	tail.visible = false
	player_audio = AudioStreamPlayer.new()
	player_audio.volume_db = 2.0
	player_audio.bus = "Vozes"
	add_child(player_audio)
	GameManager.checkpoint_activated.connect(func(_p): say("checkpoint_primeiro"))
	GameManager.gems_changed.connect(func(c, total):
		if total > 10 and total - c == 10:
			say("faltam_dez"))
	GameManager.level_completed.connect(func():
		no_rodape = true
		say("vitoria", true))

func reset() -> void:
	played.clear()
	history.clear()
	queue.clear()
	current_id = ""
	no_rodape = false
	balloon.visible = false
	tail.visible = false
	player_audio.stop()

func can_say(id: String) -> bool:
	if not LINES.has(id):
		return false
	if played.has(id):
		if REPEAT_COOLDOWN.has(id):
			return clock - float(played[id]) >= float(REPEAT_COOLDOWN[id])
		return false
	return true

# urgente: corta a fala atual (ex.: vitória)
func say(id: String, urgente: bool = false) -> void:
	if not can_say(id):
		return
	if urgente or current_id == "":
		_start(id)
	elif not queue.has(id) and id != current_id:
		# fila curta (2): se encher, sai a mais antiga; uma fala só conta como
		# "falada" quando realmente começa a tocar
		queue.append(id)
		queued_at[id] = clock
		if queue.size() > 2:
			queue.pop_front()

func _start(id: String) -> void:
	current_id = id
	played[id] = clock
	history.append(id)
	var text: String = LINES[id]
	label.text = text
	var dur: float = 1.6 + 0.055 * text.length()
	var path := "res://audio/voz/%s.ogg" % id
	if not ResourceLoader.exists(path):
		path = "res://audio/voz/%s.wav" % id
	player_audio.stop()
	if ResourceLoader.exists(path):
		var st: AudioStream = load(path)
		player_audio.stream = st
		if AudioManager.sound_enabled:
			player_audio.play()
		dur = max(dur, st.get_length() + 0.6)
	show_time = dur
	balloon.reset_size()
	balloon.visible = true
	tail.visible = true
	balloon.modulate.a = 1.0
	tail.modulate.a = 1.0

const MUSIC_DB: float = -10.0
const MUSIC_DUCK_DB: float = -19.0

func _process(delta: float) -> void:
	clock += delta
	# abaixa a música enquanto o Zeca fala
	var alvo: float = (MUSIC_DUCK_DB - MUSIC_DB) if player_audio.playing else 0.0
	AudioManager.duck_db = move_toward(AudioManager.duck_db, alvo, delta * (40.0 if alvo < AudioManager.duck_db else 15.0))
	if current_id == "":
		return
	show_time -= delta
	var a: float = clamp(show_time / 0.35, 0.0, 1.0)
	balloon.modulate.a = a
	tail.modulate.a = a
	_place()
	if show_time <= 0.0:
		current_id = ""
		balloon.visible = false
		tail.visible = false
		while queue.size() > 0 and clock - float(queued_at.get(queue[0], clock)) > QUEUE_MAX_AGE:
			queue.pop_front()
		if queue.size() > 0:
			_start(queue.pop_front())

func _place() -> void:
	var p = get_tree().get_first_node_in_group("player")
	var vp := get_viewport().get_visible_rect().size
	# largura medida pelo texto (com quebra automática, o Label sem largura
	# mínima quebraria letra por letra)
	var max_w: float = min(620.0 * fs / 34.0, vp.x * 0.5)
	var font: Font = label.get_theme_font("font")
	var tw: float = font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 4.0
	label.custom_minimum_size.x = min(tw, max_w - 44.0)
	balloon.size = Vector2.ZERO
	balloon.reset_size()
	var head := Vector2(vp.x * 0.5, vp.y * 0.35)
	if p and p.is_inside_tree():
		var h: float = 230.0 if p.is_mounted else 215.0
		head = p.get_global_transform_with_canvas().origin + Vector2(0, -h * p.k)
	var pos := head - Vector2(balloon.size.x * 0.5, balloon.size.y + 26)
	if no_rodape or GameManager.is_game_over or get_tree().paused:
		pos = Vector2((vp.x - balloon.size.x) * 0.5, vp.y - balloon.size.y - 40.0)
		head = Vector2(vp.x * 0.5, vp.y)
	# nunca cobre o HUD do topo nem sai da tela
	pos.x = clamp(pos.x, 20.0, vp.x - balloon.size.x - 20.0)
	pos.y = clamp(pos.y, 170.0 * (1.5 if GameManager.celular else 1.0), vp.y - balloon.size.y - 20.0)
	balloon.position = pos
	tail.visible = balloon.visible and not (no_rodape or GameManager.is_game_over or get_tree().paused)
	tail.position = Vector2(clamp(head.x, pos.x + 30, pos.x + balloon.size.x - 30), pos.y + balloon.size.y - 2)
