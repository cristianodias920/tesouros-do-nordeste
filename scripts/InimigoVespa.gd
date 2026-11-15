extends CharacterBody2D

@export var fly_speed: float = 90.0
@export var wave_frequency: float = 3.0
@export var wave_amplitude: float = 40.0
@export var patrol_range: float = 240.0

var start_pos: Vector2 = Vector2.ZERO
var time_passed: float = 0.0
var direction: float = -1.0
var is_dead: bool = false
var fly_frames: Array[Texture2D] = []
var anim_time: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var hit_area: Area2D = $HitArea
@onready var stomp_area: Area2D = $StompArea

func _ready() -> void:
	start_pos = global_position
	hit_area.body_entered.connect(_on_hit_entered)
	stomp_area.body_entered.connect(_on_stomp_entered)
	# Asas batendo: alterna vespa_fly_1 e vespa_fly_2
	if ResourceLoader.exists("res://sprites/enemies/vespa_fly_2.png"):
		fly_frames = [sprite.texture, load("res://sprites/enemies/vespa_fly_2.png")]

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
		sprite.flip_h = (direction < 0) # a arte olha para a direita
		# Leve oscilação no ângulo da vespa
		sprite.rotation = sin(time_passed * 6.0) * 0.1

	move_and_slide()

	if fly_frames.size() == 2:
		anim_time += delta
		if anim_time >= 0.07:
			anim_time = 0.0
			sprite.texture = fly_frames[1] if sprite.texture == fly_frames[0] else fly_frames[0]

	# Verificação contínua de contato (dano robusto)
	for area in [stomp_area, hit_area]:
		for b in area.get_overlapping_bodies():
			if b is Player:
				_resolve_contact(b as Player, delta)
				return

func _resolve_contact(p: Player, delta: float) -> void:
	if is_dead:
		return
	if p.rapadura_timer > 0.0:
		die_by_rapadura(p)
		return
	var feet_prev: float = p.global_position.y - p.velocity.y * delta
	if p.velocity.y > 0.0 and feet_prev <= stomp_area.global_position.y + 8.0:
		p.bounce()
		die()
	else:
		p.hit_by_enemy(global_position)

func _on_hit_entered(body: Node2D) -> void:
	if is_dead:
		return
	if body is Player:
		_resolve_contact(body as Player, get_physics_process_delta_time())

func _on_stomp_entered(body: Node2D) -> void:
	if is_dead:
		return
	if body is Player:
		_resolve_contact(body as Player, get_physics_process_delta_time())

func die() -> void:
	if is_dead:
		return
	is_dead = true
	AudioManager.play_sfx("hurt")
	collision_layer = 0
	collision_mask = 0
	hit_area.set_deferred("monitoring", false)
	stomp_area.set_deferred("monitoring", false)

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
	hit_area.set_deferred("monitoring", false)
	stomp_area.set_deferred("monitoring", false)

	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y - 100.0, 0.3)
	tween.parallel().tween_property(self, "rotation", 6.0, 0.4)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)

func die_by_rapadura(p: Player) -> void:
	if is_dead:
		return
	is_dead = true
	AudioManager.play_sfx("derrota")
	collision_layer = 0
	collision_mask = 0
	hit_area.set_deferred("monitoring", false)
	stomp_area.set_deferred("monitoring", false)
	p.efeito_derrota(sprite.global_position)
	var tween = create_tween()
	tween.tween_property(self, "rotation", 5.0, 0.3)
	tween.parallel().tween_property(self, "scale", scale * 0.2, 0.3)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
