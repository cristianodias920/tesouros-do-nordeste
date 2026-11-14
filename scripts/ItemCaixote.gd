extends Node2D
class_name ItemCaixote

# Item que sai do caixote: dá um pulinho, cai com gravidade, para em cima do
# chão/plataforma (camada World) e fica esperando o Zeca pegar.
# Também pode ser pego no ar, enquanto cai.

const GRAVITY: float = 1900.0
const MAX_FALL: float = 1400.0
const POP_VELOCITY: float = -520.0
const SLIDE_SPEED: float = 150.0
const PICKUP_DELAY: float = 0.18   # deixa o pulinho aparecer antes de poder pegar
const LOST_Y: float = 900.0        # abaixo disso caiu no rio: volta e cai reto

var item_type: String = "gema"
var velocity: Vector2 = Vector2.ZERO
var landed: bool = false
var collected: bool = false
var age: float = 0.0
var half_h: float = 30.0
var start_pos: Vector2 = Vector2.ZERO
var exclude_rids: Array[RID] = []
var bob_time: float = 0.0
var rest_y: float = 0.0

var sprite: Sprite2D
var area: Area2D

# Cria o item. slide_dir: -1 esquerda, 1 direita.
static func create(type: String, from_global: Vector2, slide_dir: float, exclude: Array[RID]) -> ItemCaixote:
	var it := ItemCaixote.new()
	it.item_type = type
	it.start_pos = from_global
	it.velocity = Vector2(slide_dir * SLIDE_SPEED, POP_VELOCITY)
	it.exclude_rids = exclude
	return it

func _ready() -> void:
	global_position = start_pos
	z_index = 6
	sprite = Sprite2D.new()
	var tex_path := "res://sprites/items/gema.png"
	match item_type:
		"cajuina": tex_path = "res://sprites/items/cajuina.png"
		"rapadura": tex_path = "res://sprites/items/rapadura.png"
		"ferradura": tex_path = "res://sprites/items/ferradura.png"
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)
	var target_h: float = 62.0 # altura do item na tela, em px
	if sprite.texture:
		var s: float = target_h / float(sprite.texture.get_height())
		sprite.scale = Vector2(s, s)
		half_h = target_h * 0.5
	add_child(sprite)

	area = Area2D.new()
	area.collision_layer = 8   # Collectibles
	area.collision_mask = 2    # Player
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 40.0
	shape.shape = circle
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if collected:
		return
	age += delta
	if not landed:
		velocity.y = min(velocity.y + GRAVITY * delta, MAX_FALL)
		velocity.x = move_toward(velocity.x, 0.0, 120.0 * delta)
		var from := global_position
		var to := from + velocity * delta
		if velocity.y > 0.0:
			# procura chão logo abaixo (camada World), ignorando o próprio caixote
			var space := get_world_2d().direct_space_state
			var q := PhysicsRayQueryParameters2D.create(from, to + Vector2(0, half_h), 1, exclude_rids)
			q.collide_with_areas = false
			var hit := space.intersect_ray(q)
			if hit and hit.normal.y < -0.5:
				global_position = Vector2(to.x, hit.position.y - half_h)
				_land()
			else:
				global_position = to
		else:
			global_position = to
		if global_position.y > LOST_Y:
			# caiu no rio: volta para o caixote e cai reto até o chão embaixo dele
			global_position = start_pos
			velocity = Vector2(0, 0)
	else:
		# flutua de leve para chamar atenção
		bob_time += delta
		sprite.position.y = sin(bob_time * 4.0) * 5.0
	if age >= PICKUP_DELAY:
		for b in area.get_overlapping_bodies():
			if b is Player:
				_collect(b as Player)
				return

func _land() -> void:
	landed = true
	velocity = Vector2.ZERO
	rest_y = global_position.y
	# quiquezinho ao tocar o chão
	var t := create_tween()
	t.tween_property(sprite, "scale", sprite.scale * Vector2(1.15, 0.85), 0.06)
	t.tween_property(sprite, "scale", sprite.scale, 0.1)

func _on_body_entered(body: Node2D) -> void:
	if body is Player and age >= PICKUP_DELAY:
		_collect(body as Player)

func _collect(p: Player) -> void:
	if collected:
		return
	collected = true
	match item_type:
		"cajuina": p.apply_cajuina()
		"rapadura": p.apply_rapadura()
		"ferradura": p.apply_ferradura()
		_: GameManager.add_gem()
	area.set_deferred("monitoring", false)
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(1.5, 1.5), 0.15)
	t.parallel().tween_property(self, "modulate:a", 0.0, 0.15)
	t.tween_callback(queue_free)
