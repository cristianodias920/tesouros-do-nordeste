@tool
extends Node2D
# Placa grande de madeira (dois postes) para textos mais longos (história/cultura do lugar).
# A base dos postes fica em (0, 0); a tábua fica acima.
@export var titulo: String = "":
	set(v): titulo = v; _atualizar()
@export_multiline var texto: String = "":
	set(v): texto = v; _atualizar()
@export var largura: float = 620.0:
	set(v): largura = v; _atualizar()
@export var altura: float = 250.0:
	set(v): altura = v; _atualizar()
@export var altura_postes: float = 150.0:
	set(v): altura_postes = v; _atualizar()

var lb_titulo: Label
var lb_texto: Label
var _tam_texto := Vector2.ZERO
var _ajuste_pendente := false

# A Label com quebra de linha calcula a altura antes de saber a largura: reaplica o tamanho
func _ajustar_texto() -> void:
	if is_inside_tree():
		await get_tree().process_frame
	_ajuste_pendente = false
	if lb_texto:
		lb_texto.size = Vector2(_tam_texto.x, 0)
		lb_texto.size = _tam_texto

func _ready() -> void:
	_atualizar()

func _atualizar() -> void:
	if not is_inside_tree():
		return
	if lb_titulo == null:
		lb_titulo = get_node_or_null("Titulo")
		lb_texto = get_node_or_null("Label")
	if lb_titulo == null:
		lb_titulo = Label.new()
		lb_titulo.name = "Titulo"
		add_child(lb_titulo)
		lb_texto = Label.new()
		lb_texto.name = "Label"
		add_child(lb_texto)
	var topo: float = -altura_postes - altura
	lb_titulo.text = titulo
	lb_titulo.position = Vector2(-largura * 0.5 + 24, topo + 14)
	lb_titulo.size = Vector2(largura - 48, 50)
	lb_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lb_titulo.add_theme_font_size_override("font_size", 42)
	lb_titulo.add_theme_color_override("font_color", Color(0.2, 0.09, 0.02))
	lb_titulo.add_theme_color_override("font_outline_color", Color(1, 0.93, 0.75))
	lb_titulo.add_theme_constant_override("outline_size", 6)
	lb_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lb_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lb_texto.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	lb_texto.clip_text = false
	var y_txt: float = topo + (64 if titulo != "" else 18)
	lb_texto.custom_minimum_size = Vector2(largura - 52, 0)
	lb_texto.text = texto
	lb_texto.position = Vector2(-largura * 0.5 + 26, y_txt)
	lb_texto.size = Vector2(largura - 52, altura - (y_txt - topo) - 14)
	_tam_texto = lb_texto.size
	if not _ajuste_pendente:
		_ajuste_pendente = true
		_ajustar_texto.call_deferred()
	lb_texto.add_theme_font_size_override("font_size", 33)
	lb_texto.add_theme_color_override("font_color", Color(0.18, 0.08, 0.02))
	lb_texto.add_theme_color_override("font_outline_color", Color(1, 0.95, 0.82))
	lb_texto.add_theme_constant_override("outline_size", 4)
	queue_redraw()

func _draw() -> void:
	var topo: float = -altura_postes - altura
	var madeira := Color(0.55, 0.34, 0.15)
	var escura := Color(0.32, 0.18, 0.07)
	for x in [-largura * 0.32, largura * 0.32]:
		draw_rect(Rect2(x - 11, topo + altura - 10, 22, altura_postes + 10), escura)
		draw_rect(Rect2(x - 7, topo + altura - 10, 14, altura_postes + 10), madeira)
	var r := Rect2(-largura * 0.5, topo, largura, altura)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.86, 0.68, 0.42)
	sb.border_color = escura
	sb.set_border_width_all(7)
	sb.set_corner_radius_all(16)
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(4, 5)
	draw_style_box(sb, r)
	# veios da madeira
	for i in 4:
		var y: float = topo + altura * (0.22 + 0.2 * i)
		draw_line(Vector2(-largura * 0.46, y), Vector2(largura * 0.46, y + 3), Color(0.72, 0.52, 0.28, 0.45), 2.0)
