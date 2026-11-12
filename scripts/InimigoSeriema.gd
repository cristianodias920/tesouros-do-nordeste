extends EnemyBase

var is_sprinting: bool = false
var alert_distance: float = 380.0

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Checa proximidade do Player
	var player = get_tree().get_first_node_in_group("player")
	if player and not is_sprinting:
		var dist = global_position.distance_to(player.global_position)
		if dist < alert_distance:
			start_sprint(player)

	super._physics_process(delta)

func start_sprint(player: Node2D) -> void:
	is_sprinting = true
	move_speed = 220.0 # corrida rápida em linha
	direction = sign(player.global_position.x - global_position.x)
	if direction == 0:
		direction = -1.0
	patrol_distance = 600.0
	start_x = global_position.x
	if ResourceLoader.exists("res://sprites/enemies/seriema_run_2.png"):
		sprite.texture = load("res://sprites/enemies/seriema_run_2.png")
