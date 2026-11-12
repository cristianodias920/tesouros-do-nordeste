extends EnemyBase

var is_ball: bool = false
var ball_timer: float = 0.0
var walk_timer: float = 3.0

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_ball:
		walk_timer -= delta
		if walk_timer <= 0:
			enter_ball_mode()
	else:
		ball_timer -= delta
		if ball_timer <= 0:
			exit_ball_mode()

	super._physics_process(delta)

func enter_ball_mode() -> void:
	is_ball = true
	ball_timer = 2.5
	move_speed = 170.0
	can_be_stomped = false # Em bola, carapaça dura!
	if ResourceLoader.exists("res://sprites/enemies/tatu_ball.png"):
		sprite.texture = load("res://sprites/enemies/tatu_ball.png")

func exit_ball_mode() -> void:
	is_ball = false
	walk_timer = 4.0
	move_speed = 80.0
	can_be_stomped = true
	if ResourceLoader.exists("res://sprites/enemies/tatu_walk_1.png"):
		sprite.texture = load("res://sprites/enemies/tatu_walk_1.png")
