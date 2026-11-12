extends Area2D

var time_passed: float = 0.0
var base_y: float = 0.0
var collected: bool = false

func _ready() -> void:
	base_y = position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if not collected:
		time_passed += delta
		position.y = base_y + sin(time_passed * 4.0) * 8.0

func _on_body_entered(body: Node2D) -> void:
	if collected:
		return
	if body is Player:
		collected = true
		GameManager.add_gem()
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.15)
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.15)
		tween.tween_callback(queue_free)
