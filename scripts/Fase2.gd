extends Node2D

# Fase 2 — Cristalândia do Piauí. Mesmo padrão da Fase 1: diz ao GameManager qual fase é,
# usa as músicas próprias da fase (baião festivo no chão; faixa cristalina nos veios de cristal,
# troca só por volume), controla os sons de ambiente, os textos de celular/teclado e as falas.
const TXT_TUTORIAL_TOQUE := "Toque nas setas para andar e no botão da direita para pular. Monte no Faísca!"
const TXT_TUTORIAL_TECLADO := "Setas (ou A e D) para andar, Espaço ou W para pular. Monte no Faísca!"
const CRISTAIS_X0 := 10400.0   # trecho dos veios de cristal (música cristalina)
const CRISTAIS_X1 := 13500.0
const FOLGA := 150.0
const CHAPEU_X := 4990.0       # estande do chapéu (depois daqui o Zeca sempre tem o chapéu)

var rios: Array = []
var musica_cristais: bool = false
var falou_chapeu: bool = false

func _ready() -> void:
	GameManager.FASE_ID = "fase2_cristalandia"
	AudioManager.usar_conjunto("cristalandia", "cris_festa")
	_textos_da_fase()
	if GameManager.celular:
		_textos_maiores()
	for sp in get_node("RioVisual").get_children():
		if sp is Sprite2D and sp.texture:
			rios.append([sp.global_position.x, sp.global_position.x + sp.texture.get_width() * sp.global_scale.x])
	# doce de buriti: o Zeca comenta (no máximo a cada 40 s)
	for g in get_node("Tesouros").get_children():
		if String(g.name).begins_with("DoceBuriti"):
			g.body_entered.connect(func(b): if b is Player: VoiceLines.say("cris_buriti_doce"))
	PowerUps.mudou.connect(_on_poderes)

func _textos_da_fase() -> void:
	var hud = get_node_or_null("HUD")
	if hud and hud.intro:
		var vb = hud.intro.get_child(1).get_child(0)
		vb.get_child(0).text = "FASE 2 • CRISTALÂNDIA, PIAUÍ"
		hud._center_intro()
	var titulo = get_node_or_null("HUD/TopCenter/PhaseTitleLabel")
	if titulo:
		titulo.text = "FASE 2 • CRISTALÂNDIA, PIAUÍ"
	var dica: Label = get_node_or_null("Placas/DicaTutorial")
	if dica:
		dica.text = TXT_TUTORIAL_TOQUE if GameManager.celular else TXT_TUTORIAL_TECLADO
	var p1 = get_node_or_null("Placas/PlacaPrimeiroCristal")
	if p1:
		p1.get_node("Label").text = ("Cristal! Use o botão do chapéu" if GameManager.celular else "Cristal! Aperte C")
	var p2 = get_node_or_null("Placas/PlacaParede")
	if p2:
		p2.get_node("Label").text = "Cristais! Use o botão do chapéu" if GameManager.celular else "Cristais! Arremesse o chapéu (C)"

func _textos_maiores() -> void:
	# Celular: placas, dicas e balões maiores (igual à Fase 1)
	for n in find_children("*", "Node2D", true, false):
		var sc = n.get_script()
		if sc == null:
			continue
		var caminho := String(sc.resource_path)
		if caminho.ends_with("PlacaInfo.gd"):
			n.scale *= 1.3
		elif caminho.ends_with("PlacaGrande.gd"):
			n.scale *= 1.15
	var lb: Label = get_node_or_null("Placas/DicaTutorial")
	if lb:
		lb.add_theme_font_size_override("font_size", 44)
		lb.offset_right = lb.offset_left + 1100
		lb.offset_bottom = lb.offset_top + 160

func _on_poderes(ativo: String, _reserva: String) -> void:
	if ativo == "chapeu" and not falou_chapeu:
		var p = get_tree().get_first_node_in_group("player")
		if p and abs(p.global_position.x - CHAPEU_X) < 400:
			falou_chapeu = true
			VoiceLines.say("cris_chapeu_pega", true)

# Trecho da fase (para a tela final dizer onde ainda há tesouros)
func area_de(pos: Vector2) -> String:
	if pos.x < 2600:
		return "Caminho de Corrente"
	if pos.x < 5600:
		return "Centro e festejo de Sant'Ana"
	if pos.x < 8700:
		return "Rio Palmeira e nascente"
	if pos.x < CRISTAIS_X0:
		return "Comunidade Esperança"
	if pos.x < CRISTAIS_X1:
		return "Veios de cristal"
	return "Chapada da Limpeza"

func _process(_delta: float) -> void:
	var p = get_tree().get_first_node_in_group("player")
	if p == null:
		return
	var pos: Vector2 = p.global_position
	# segurança: depois do estande, o Zeca sempre tem o chapéu (as paredes de cristal pedem o chapéu)
	if pos.x > CHAPEU_X + 120 and not PowerUps.tem("chapeu"):
		PowerUps.pegar("chapeu")
	# música: faixa cristalina nos veios de cristal (com folga para não ficar trocando na fronteira)
	if musica_cristais:
		if pos.x < CRISTAIS_X0 - FOLGA or pos.x > CRISTAIS_X1 + FOLGA:
			musica_cristais = false
	elif pos.x > CRISTAIS_X0 and pos.x < CRISTAIS_X1:
		musica_cristais = true
	if GameManager.is_level_ended:
		musica_cristais = false
	AudioManager.tocar_musica("cris_cristais" if musica_cristais else "cris_festa")
	# ambiente: passarinhos no cerrado, rio perto da água (e na nascente)
	var rio: float = 0.0
	var dmin: float = 99999.0
	for r in rios:
		var d: float = 0.0 if (pos.x >= r[0] and pos.x <= r[1]) else min(abs(pos.x - r[0]), abs(pos.x - r[1]))
		dmin = min(dmin, d)
	dmin = min(dmin, abs(pos.x - 8230.0) * 1.4)   # olho d'água
	rio = clamp(1.0 - dmin / 900.0, 0.0, 1.0)
	AudioManager.set_ambiente("passaros", 0.25 if musica_cristais else 0.6)
	AudioManager.set_ambiente("rio", rio)
