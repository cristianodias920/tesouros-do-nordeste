extends CharacterBody2D
class_name EnemyBase

@export var move_speed: float = 80.0
@export var patrol_distance: float = 200.0
@export var can_be_stomped: bool = true

var direction: float = -1.0
var start_x: float = 0.0
var is_dead: bool = false
var gravity: float = 980.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var stomp_area: Area2D = $StompArea
@onready var hit_area: Area2D = $HitArea

func _ready() -> void:
	start_x = global_position.x
	if stomp_area:
		stomp_area.body_entered.connect(_on_stomp_entered)
	if hit_area:
		hit_area.body_entered.connect(_on_hit_entered)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	patrol_movement(delta)
	move_and_slide()

func patrol_movement(_delta: float) -> void:
	if abs(global_position.x - start_x) > patrol_distance or is_on_wall():
		direction *= -1.0
		start_x = global_position.x

	velocity.x = direction * move_speed
	if sprite:
		sprite.flip_h = (direction > 0)

func _on_stomp_entered(body: Node2D) -> void:
	if is_dead or not can_be_stomped:
		return
	if body is Player:
		var p = body as Player
		if p.velocity.y > 0:
			p.bounce()
			die()

func _on_hit_entered(body: Node2D) -> void:
	if is_dead:
		return
	if body is Player:
		var p = body as Player
		p.hit_by_enemy(global_position)

func die() -> void:
	if is_dead:
		return
	is_dead = true
	AudioManager.play_sfx("hurt")
	collision_layer = 0
	collision_mask = 0
	if stomp_area:
		stomp_area.monitoring = false
	if hit_area:
		hit_area.monitoring = false

	# Efeito de derrota (achata e desaparece)
	var tween = create_tween()
	tween.tween_property(sprite, "scale:y", 0.05, 0.15)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)

func die_by_coice() -> void:
	if is_dead:
		return
	is_dead = true
	AudioManager.play_sfx("kick")
	collision_layer = 0
	collision_mask = 0
	if stomp_area:
		stomp_area.monitoring = false
	if hit_area:
		hit_area.monitoring = false

	# Lançado para o alto rodopiando
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y - 120.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "rotation", 4.0, 0.5)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
