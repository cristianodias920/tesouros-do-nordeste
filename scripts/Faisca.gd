extends Area2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label
var time_passed: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	time_passed += delta
	# Efeito flutuante suave no texto e jumentinho
	label.position.y = -130 + sin(time_passed * 3.0) * 5.0

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var p = body as Player
		if not p.is_mounted:
			p.mount_faisca()
			queue_free()
