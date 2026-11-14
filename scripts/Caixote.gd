extends StaticBody2D

@export_enum("gema", "cajuina", "rapadura", "ferradura") var content_type: String = "gema"

var is_opened: bool = false
var gave_foot_gem: bool = false # caixote da Ferradura: a pé solta uma gema (uma vez só)
var bump_cooldown: float = 0.0
# Para onde o item escorrega ao sair: 0 = para longe do Zeca, -1 esquerda, 1 direita
@export var item_slide_dir: float = 0.0
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
	# O item sai pelo topo do caixote, dá um pulinho e cai até o chão (ItemCaixote.gd)
	var dir: float = item_slide_dir
	if dir == 0.0:
		dir = 1.0 if global_position.x >= player.global_position.x else -1.0
	var top := global_position + Vector2(0, -50)
	var item := ItemCaixote.create(type, top, dir, [get_rid()])
	get_parent().add_child(item)
