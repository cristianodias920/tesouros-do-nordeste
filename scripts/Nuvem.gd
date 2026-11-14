extends AnimatableBody2D

# Nuvem pintada: plataforma de mão única; pode flutuar devagar.
@export var amplitude: Vector2 = Vector2.ZERO
@export var periodo: float = 4.0
var base: Vector2
var t: float = 0.0

func _ready() -> void:
	base = position
	t = fmod(position.x * 0.01, periodo)

func _physics_process(delta: float) -> void:
	if amplitude == Vector2.ZERO:
		return
	t += delta
	position = base + amplitude * sin(t * TAU / periodo)
