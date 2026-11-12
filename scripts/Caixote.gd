extends StaticBody2D

@export_enum("gema", "cajuina", "rapadura", "ferradura") var content_type: String = "gema"

var is_opened: bool = false
@onready var sprite: Sprite2D = $Sprite2D
@onready var bottom_area: Area2D = $BottomArea

func _ready() -> void:
	bottom_area.body_entered.connect(_on_bottom_entered)

func _on_bottom_entered(body: Node2D) -> void:
	if is_opened:
		return
	if body is Player:
		var p = body as Player
		if p.velocity.y < 0: # pulando de baixo para cima
			open_crate(p)

func open_crate(player: Player) -> void:
	is_opened = true
	AudioManager.play_sfx("crate")
	
	# Muda visual para caixote aberto
	if ResourceLoader.exists("res://sprites/items/caixote_aberto.png"):
		sprite.texture = load("res://sprites/items/caixote_aberto.png")

	# Animação de solavanco
	var tween = create_tween()
	var orig_y = position.y
	tween.tween_property(self, "position:y", orig_y - 14.0, 0.08)
	tween.tween_property(self, "position:y", orig_y, 0.08)

	# Se for ferradura, só sai ferradura se estiver montado; a pé sai gema!
	var actual_type = content_type
	if actual_type == "ferradura" and not player.is_mounted:
		actual_type = "gema"

	spawn_item(actual_type, player)

func spawn_item(type: String, player: Player) -> void:
	var item_sprite = Sprite2D.new()
	var tex_path = ""
	match type:
		"cajuina":
			tex_path = "res://sprites/items/cajuina.png"
		"rapadura":
			tex_path = "res://sprites/items/rapadura.png"
		"ferradura":
			tex_path = "res://sprites/items/ferradura.png"
		_:
			tex_path = "res://sprites/items/gema.png"
			
	if ResourceLoader.exists(tex_path):
		item_sprite.texture = load(tex_path)
	item_sprite.scale = Vector2(0.35, 0.35)
	item_sprite.position = Vector2(0, -30)
	add_child(item_sprite)

	var tween = create_tween()
	tween.tween_property(item_sprite, "position:y", -90.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(item_sprite, "scale", Vector2(0.5, 0.5), 0.3)
	tween.tween_interval(0.1)
	tween.tween_property(item_sprite, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		item_sprite.queue_free()
		match type:
			"cajuina":
				player.apply_cajuina()
			"rapadura":
				player.apply_rapadura()
			"ferradura":
				player.apply_ferradura()
			_:
				GameManager.add_gem()
	)
