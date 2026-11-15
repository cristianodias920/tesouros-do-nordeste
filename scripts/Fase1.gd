extends Node2D

# Fase 1 — Corrente. Troca o cenário de fundo quando o Zeca vai para a Serra (caminho do fundo),
# anima a cavalgada da ExpoCorrente, troca a música nas nuvens, controla os sons de ambiente
# (passarinhos e rio) e deixa textos maiores no celular.
@onready var mata: Node = get_node_or_null("ParallaxMata")
@onready var morros: Node = get_node_or_null("ParallaxMorros")
@onready var serra: Node = get_node_or_null("ParallaxSerra")
@onready var cavalgada: Node2D = get_node_or_null("Decoracao/Expo/Cavalgada")
var cav_x0: float = 0.0
var t: float = 0.0
var rios: Array = []   # [x0, x1] dos trechos de água (para o som do rio)

const TXT_TUTORIAL_TOQUE := "Toque nas setas para andar e no botão da direita para pular."
const TXT_TUTORIAL_TECLADO := "Use as setas (ou A e D) para andar. Pule com Espaço."

func _ready() -> void:
	GameManager.mundo_mudou.connect(_on_mundo_mudou)
	_on_mundo_mudou(false)
	if cavalgada:
		cav_x0 = cavalgada.position.x
	_ajustar_tutorial()
	_placas_do_fundo()
	if GameManager.celular:
		_textos_maiores()
	for pai in ["RioVisual", "RioNovo"]:
		var n := get_node_or_null(pai)
		if n == null:
			continue
		for sp in n.get_children():
			if sp is Sprite2D and sp.texture:
				var w: float = sp.texture.get_width() * sp.global_scale.x
				rios.append([sp.global_position.x, sp.global_position.x + w])
	AudioManager.tocar_musica("forro")

func _ajustar_tutorial() -> void:
	var dica: Label = get_node_or_null("Placas/DicaTutorial")
	if dica:
		dica.text = TXT_TUTORIAL_TOQUE if GameManager.celular else TXT_TUTORIAL_TECLADO

func _placas_do_fundo() -> void:
	# No caminho do fundo tudo é desenhado a 60%: as placas ficavam ilegíveis
	var f := get_node_or_null("CaminhoDistante")
	if f == null:
		return
	for n in f.get_children():
		if n.get_script() and String(n.get_script().resource_path).ends_with("PlacaInfo.gd"):
			n.scale = Vector2.ONE * 1.45

func _textos_maiores() -> void:
	# Celular: placas, dicas e balões ~1,5x maiores
	for n in find_children("*", "Node2D", true, false):
		if n.get_script() and String(n.get_script().resource_path).ends_with("PlacaInfo.gd"):
			n.scale *= 1.3
			var lb: Label = n.get_node_or_null("Label")
			if lb and lb.label_settings:
				var ls: LabelSettings = lb.label_settings.duplicate()
				ls.font_size = int(ls.font_size * 1.15)
				lb.label_settings = ls
	for path in ["Placas/DicaTutorial", "PlacasNovas/DicaSubida", "PlacasNovas/DicaParaim", "PlacasNovas/DicaPortal"]:
		var lb: Label = get_node_or_null(path)
		if lb == null:
			continue
		var fs: int = lb.get_theme_font_size("font_size")
		lb.add_theme_font_size_override("font_size", int(fs * 1.5))
		var cx: float = (lb.offset_left + lb.offset_right) * 0.5
		var w: float = (lb.offset_right - lb.offset_left) * 1.5
		lb.offset_left = cx - w * 0.5
		lb.offset_right = cx + w * 0.5
		lb.offset_bottom = lb.offset_top + (lb.offset_bottom - lb.offset_top) * 1.7

func _on_mundo_mudou(fundo: bool) -> void:
	if mata:
		mata.visible = not fundo
	if morros:
		morros.visible = not fundo
	if serra:
		serra.visible = fundo

func _process(delta: float) -> void:
	t += delta
	if cavalgada:
		# desfile devagar para a direita, voltando ao início (atrás do arco)
		var d: float = fmod(t * 70.0, 1500.0)
		cavalgada.position.x = cav_x0 + d
		cavalgada.modulate.a = clamp(min(d, 1500.0 - d) / 220.0, 0.0, 1.0)
		cavalgada.position.y = -abs(sin(t * 5.0)) * 4.0 + cavalgada.get_meta("base_y", 0.0)
	_som_do_lugar()

func _som_do_lugar() -> void:
	var p = get_tree().get_first_node_in_group("player")
	if p == null:
		return
	var pos: Vector2 = p.global_position
	# música: faixa das nuvens lá em cima; forró no resto (e na vitória)
	var nas_nuvens: bool = (not p.no_fundo) and pos.x > 9900 and pos.x < 16900 and pos.y < 150
	if GameManager.is_level_ended:
		nas_nuvens = false
	AudioManager.tocar_musica("nuvens" if nas_nuvens else "forro")
	# ambiente: passarinhos no chão (mais na Serra), rio perto da água
	var passaros: float = 0.0 if nas_nuvens else (0.9 if p.no_fundo else 0.6)
	var rio: float = 0.0
	if not p.no_fundo and pos.y > 300:
		var dmin: float = 99999.0
		for r in rios:
			var d: float = 0.0 if (pos.x >= r[0] and pos.x <= r[1]) else min(abs(pos.x - r[0]), abs(pos.x - r[1]))
			dmin = min(dmin, d)
		rio = clamp(1.0 - dmin / 900.0, 0.0, 1.0)
	AudioManager.set_ambiente("passaros", passaros)
	AudioManager.set_ambiente("rio", rio)
