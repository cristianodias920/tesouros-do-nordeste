extends Area2D

# Folha de buriti no alto da torre: depois de pegar, segurar PULAR enquanto cai
# faz o Zeca planar (só na área das nuvens). Mostra a dica no HUD.
var t: float = 0.0
var base_y: float = 0.0
var pego: bool = false
@onready var sprite: Sprite2D = $Sprite2D
@onready var brilho: Sprite2D = $Brilho

func _ready() -> void:
	add_to_group("folha_buriti")
	base_y = position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if pego:
		return
	t += delta
	position.y = base_y + sin(t * 3.0) * 10.0
	sprite.rotation = sin(t * 2.0) * 0.08
	brilho.modulate.a = 0.45 + 0.25 * sin(t * 4.0)

func _on_body_entered(body: Node2D) -> void:
	if pego or not (body is Player):
		return
	pego = true
	(body as Player).pegar_folha()
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("mostrar_dica_folha"):
		hud.mostrar_dica_folha()
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.6, 1.6), 0.18)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(queue_free)
