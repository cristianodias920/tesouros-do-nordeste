extends Area2D

# Tesouro da fase: gema (padrão) ou comida típica (textura + nome).
# Tudo que está no grupo "gemas" entra na contagem total do HUD.
@export var textura: Texture2D
@export var nome: String = ""

var time_passed: float = 0.0
var base_y: float = 0.0
var collected: bool = false

func _ready() -> void:
	add_to_group("gemas")
	base_y = position.y
	time_passed = fmod(position.x * 0.013, 6.28)
	body_entered.connect(_on_body_entered)
	if textura:
		var sp: Sprite2D = $Sprite2D
		sp.texture = textura
		var s: float = 70.0 / float(max(textura.get_width(), textura.get_height()))
		sp.scale = Vector2(s, s)

func _process(delta: float) -> void:
	if not collected:
		time_passed += delta
		position.y = base_y + sin(time_passed * 4.0) * 8.0

func _on_body_entered(body: Node2D) -> void:
	if collected:
		return
	if body is Player:
		collected = true
		remove_from_group("gemas")
		GameManager.add_gem()
		if nome != "":
			_mostrar_nome()
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.15)
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.15)
		tween.tween_callback(queue_free)

func _mostrar_nome() -> void:
	# Nome da comida sobe e some (fica na fase, fora da gema que vai sumir)
	var lb := Label.new()
	lb.text = nome
	lb.add_theme_font_size_override("font_size", 30)
	lb.add_theme_color_override("font_color", Color(1, 0.95, 0.7))
	lb.add_theme_color_override("font_outline_color", Color(0.3, 0.15, 0.05))
	lb.add_theme_constant_override("outline_size", 8)
	lb.z_index = 20
	get_parent().add_child(lb)
	lb.global_position = global_position + Vector2(-120, -90) * global_scale
	lb.size = Vector2(240, 40)
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var t := lb.create_tween()
	t.tween_property(lb, "position:y", lb.position.y - 70, 1.2)
	t.parallel().tween_property(lb, "modulate:a", 0.0, 1.2).set_delay(0.5)
	t.tween_callback(lb.queue_free)
