extends Area2D

# Item de power-up na fase (genérico): ao tocar, o Zeca pega o power-up "poder".
# Se já tinha outro ativo, o antigo vai para a reserva (HUD mostra os dois; V troca).
@export var poder: String = "chapeu"
@export var reaparece: bool = false   # cena de teste: volta depois de uns segundos

var t: float = 0.0
var base_y: float = 0.0
var pego: bool = false
var sprite: Sprite2D
var brilho: Sprite2D

func _ready() -> void:
	add_to_group("powerup_item")
	collision_layer = 8
	collision_mask = 2
	base_y = position.y
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 56.0
	cs.shape = sh
	add_child(cs)
	brilho = Sprite2D.new()
	var gt := GradientTexture2D.new()
	gt.width = 128; gt.height = 128
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5); gt.fill_to = Vector2(1.0, 0.5)
	var g := Gradient.new()
	g.set_color(0, Color(1, 0.92, 0.55, 0.9))
	g.set_color(1, Color(1, 0.85, 0.4, 0.0))
	gt.gradient = g
	brilho.texture = gt
	brilho.scale = Vector2(1.8, 1.8)
	add_child(brilho)
	sprite = Sprite2D.new()
	var tex: Texture2D = load("res://sprites/powerups/chapeu.png") if poder == "chapeu" else PowerUps.icone(poder)
	sprite.texture = tex
	if tex:
		var s: float = 120.0 / float(max(tex.get_width(), tex.get_height()))
		sprite.scale = Vector2(s, s)
	add_child(sprite)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if pego:
		return
	t += delta
	position.y = base_y + sin(t * 3.0) * 10.0
	sprite.rotation = sin(t * 2.0) * 0.1
	brilho.modulate.a = 0.45 + 0.25 * sin(t * 4.0)

func _on_body_entered(body: Node2D) -> void:
	if pego or not (body is Player):
		return
	pego = true
	(body as Player).pegar_poder(poder)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.6, 1.6), 0.18)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.25)
	if reaparece:
		tw.tween_interval(3.0)
		tw.tween_callback(func():
			scale = Vector2.ONE
			modulate.a = 1.0
			pego = false)
	else:
		tw.tween_callback(queue_free)
