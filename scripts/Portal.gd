extends Area2D
class_name Portal

# Portal entre a trilha principal e o caminho do fundo (Serra Dois Irmãos).
# Ao entrar, o Zeca vai para o portal de destino e sai ao lado dele (saida_dx).
@export var destino: NodePath
@export var saida_dx: float = 220.0     # para que lado o Zeca aparece quando chega aqui
@export var no_fundo: bool = false      # este portal fica no caminho do fundo
@export var rotulo: String = ""

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label
var t: float = 0.0

func _ready() -> void:
	label.text = rotulo
	label.visible = rotulo != ""

func _process(delta: float) -> void:
	t += delta
	# brilho pulsando de leve
	sprite.modulate = Color(1, 1, 1).lerp(Color(1.15, 1.12, 0.95), 0.5 + 0.5 * sin(t * 3.0))
	label.position.y = -330 + sin(t * 2.5) * 6.0

func _physics_process(_delta: float) -> void:
	for b in get_overlapping_bodies():
		if b is Player:
			var p := b as Player
			if p.viajando or p.portal_cooldown > 0:
				return
			var d := get_node_or_null(destino) as Portal
			if d == null:
				return
			var chegada: Vector2 = d.global_position + Vector2(d.saida_dx * d.global_scale.x, -60.0 * d.global_scale.y)
			p.entrar_portal(chegada, d.no_fundo)
			return
