extends CharacterBody2D

@export var fly_speed: float = 90.0
@export var wave_frequency: float = 3.0
@export var wave_amplitude: float = 40.0
@export var patrol_range: float = 240.0

var start_pos: Vector2 = Vector2.ZERO
var time_passed: float = 0.0
var direction: float = -1.0
var is_dead: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var hit_area: Area2D = $HitArea
@onready var stomp_area: Area2D = $StompArea

func _ready() -> void:
	start_pos = global_position
	hit_area.body_entered.connect(_on_hit_entered)
	stomp_area.body_entered.connect(_on_stomp_entered)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	time_passed += delta
	# Movimento horizontal de patrulha
	if abs(global_position.x - start_pos.x) > patrol_range:
		direction *= -1.0
		start_pos.x = global_position.x

	velocity.x = direction * fly_speed
	# Ondulação senoidal vertical no voo
	velocity.y = cos(time_passed * wave_frequency) * (wave_amplitude * wave_frequency)
	
	if sprite:
		sprite.flip_h = (direction > 0)
		# Leve oscilação no ângulo da vespa
		sprite.rotation = sin(time_passed * 6.0) * 0.1

	move_and_slide()

func _on_hit_entered(body: Node2D) -> void:
	if is_dead:
		return
	if body is Player:
		(body as Player).hit_by_enemy(global_position)

func _on_stomp_entered(body: Node2D) -> void:
	if is_dead:
		return
	if body is Player:
		var p = body as Player
		if p.velocity.y > 0:
			p.bounce()
			die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	AudioManager.play_sfx("hurt")
	collision_layer = 0
	collision_mask = 0
	hit_area.monitoring = false
	stomp_area.monitoring = false

	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y + 80.0, 0.3)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

func die_by_coice() -> void:
	if is_dead:
		return
	is_dead = true
	AudioManager.play_sfx("kick")
	collision_layer = 0
	collision_mask = 0
	hit_area.monitoring = false
	stomp_area.monitoring = false

	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y - 100.0, 0.3)
	tween.parallel().tween_property(self, "rotation", 6.0, 0.4)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)
