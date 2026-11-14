extends Node2D

# Fase 1 — Corrente. Troca o cenário de fundo quando o Zeca vai para a Serra (caminho do fundo)
# e anima a cavalgada da ExpoCorrente lá atrás.
@onready var mata: Node = get_node_or_null("ParallaxMata")
@onready var morros: Node = get_node_or_null("ParallaxMorros")
@onready var serra: Node = get_node_or_null("ParallaxSerra")
@onready var cavalgada: Node2D = get_node_or_null("Decoracao/Expo/Cavalgada")
var cav_x0: float = 0.0
var t: float = 0.0

func _ready() -> void:
	GameManager.mundo_mudou.connect(_on_mundo_mudou)
	_on_mundo_mudou(false)
	if cavalgada:
		cav_x0 = cavalgada.position.x

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
