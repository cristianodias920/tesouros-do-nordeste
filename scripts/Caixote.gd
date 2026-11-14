extends StaticBody2D

@export_enum("gema", "cajuina", "rapadura", "ferradura") var content_type: String = "gema"

var is_opened: bool = false
var gave_foot_gem: bool = false # caixote da Ferradura: a pé solta uma gema (uma vez só)
var bump_cooldown: float = 0.0
@onready var sprite: Sprite2D = $Sprite2D

func _process(delta: float) -> void:
	if bump_cooldown > 0.0:
		bump_cooldown -= delta

# Chamado pelo Player quando a cabeça bate por baixo (ver Player._check_slide_collisions)
func hit_from_below(player: Player) -> void:
	if is_opened or bump_cooldown > 0.0:
		return
	bump_cooldown = 0.3
	if content_type == "ferradura" and not player.is_mounted:
		# A pé: solta uma gema e continua fechado esperando o Zeca montado
		_bump()
		AudioManager.play_sfx("crate")
		if not gave_foot_gem:
			gave_foot_gem = true
			spawn_item("gema", player)
		return
	open_crate(player)

func _bump() -> void:
	var tween = create_tween()
	tween.tween_property(sprite, "position:y", -14.0, 0.08)
	tween.tween_property(sprite, "position:y", 0.0, 0.08)

func open_crate(player: Player) -> void:
	is_opened = true
	AudioManager.play_sfx("crate")
	
	# Mostra a tampa aberta por código
	if sprite and sprite.texture:
		var lid = Sprite2D.new()
		lid.texture = sprite.texture
		lid.region_enabled = true
		var w = sprite.texture.get_width()
		var h = sprite.texture.get_height()
		var lid_h = h * 0.30
		lid.region_rect = Rect2(0, 0, w, lid_h)
		lid.scale = sprite.scale
		var top_y = -h * sprite.scale.y * 0.5 + (lid_h * sprite.scale.y * 0.5)
		lid.position = Vector2(0, top_y)
		add_child(lid)

		var lid_tween = create_tween()
		lid_tween.parallel().tween_property(lid, "position", lid.position + Vector2(12, -40), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		lid_tween.parallel().tween_property(lid, "rotation_degrees", 25.0, 0.25)

	# Animação de solavanco (só o desenho; a colisão fica parada)
	_bump()
	sprite.modulate = Color(0.8, 0.72, 0.62) # caixote vazio fica mais escuro
	spawn_item(content_type, player)

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
