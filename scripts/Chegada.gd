extends Area2D

var triggered: bool = false
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if triggered:
		return
	if body is Player:
		triggered = true
		# Efeito comemorativo de balanço nas bandeirinhas
		var tween = create_tween()
		tween.tween_property(sprite, "rotation", 0.15, 0.1)
		tween.tween_property(sprite, "rotation", -0.15, 0.1)
		tween.tween_property(sprite, "rotation", 0.0, 0.1)
		
		GameManager.complete_level()
