extends Area2D

var activated: bool = false
@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	label.modulate.a = 0.0

func _on_body_entered(body: Node2D) -> void:
	if activated:
		return
	if body is Player:
		activated = true
		GameManager.set_checkpoint(global_position + Vector2(0, -20))
		
		# Animação da bandeira e texto "Checkpoint ativado!"
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(0.45, 0.45), 0.15)
		tween.parallel().tween_property(label, "modulate:a", 1.0, 0.2)
		tween.parallel().tween_property(label, "position:y", -140.0, 0.3)
		tween.tween_property(sprite, "scale", Vector2(0.38, 0.38), 0.15)
		tween.tween_interval(1.5)
		tween.tween_property(label, "modulate:a", 0.0, 0.5)
