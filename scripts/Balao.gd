extends Control
class_name Balao
# Balão de história: "fala" (arredondado com rabinho) ou "grito" (estrela de
# pontas, para a onomatopeia do Faísca).

var tipo: String = "fala"
var alvo: Vector2 = Vector2.ZERO   # em coordenadas do pai
var texto: String = ""
var fs: int = 46
var larg: float = 100.0
var pad: Vector2 = Vector2(36, 22)
var fonte: Font
var t: float = 0.0
const PAD := Vector2(36, 22)

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

const QUEBRA := TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND

func configurar(novo_texto: String, novo_tipo: String, centro: Vector2, alvo_px: Vector2, tela: Vector2) -> void:
	# o texto é desenhado no _draw (quebra de linha calculada aqui, sem Label)
	tipo = novo_tipo
	alvo = alvo_px
	texto = novo_texto
	fonte = get_theme_default_font()
	fs = 46 if tipo == "fala" else 76
	var tw: float = fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 4.0
	var max_w: float = tela.x * (0.44 if tipo == "fala" else 0.36)
	larg = min(tw, max_w)
	var lh: float = fonte.get_multiline_string_size(texto, HORIZONTAL_ALIGNMENT_CENTER, larg, fs, -1, QUEBRA).y
	pad = Vector2(36, 24) if tipo == "fala" else Vector2(70, 60)
	size = Vector2(larg, lh) + pad * 2.0
	position = centro - size * 0.5
	position.x = clamp(position.x, 24.0, tela.x - size.x - 24.0)
	position.y = clamp(position.y, 110.0, tela.y - size.y - 120.0)
	pivot_offset = size * 0.5
	queue_redraw()

func _process(delta: float) -> void:
	t += delta
	if tipo == "grito":
		rotation = sin(t * 30.0) * 0.025
		queue_redraw()

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var c := size * 0.5
	var borda := Color(0.42, 0.26, 0.12)
	if tipo == "fala":
		var fundo := Color(1.0, 0.98, 0.92)
		# rabinho apontando para quem fala
		var a: Vector2 = alvo - position
		var dir: Vector2 = (a - c).normalized()
		var hw: float = size.x * 0.5 - 30.0
		var hh: float = size.y * 0.5 - 4.0
		var tb: float = min(hw / max(abs(dir.x), 0.001), hh / max(abs(dir.y), 0.001))
		var base: Vector2 = c + dir * tb * 0.85
		var borda_pt: Vector2 = c + dir * tb
		var ponta: Vector2 = borda_pt + dir * clamp(((a - c).length() - tb) * 0.7, 40.0, 120.0)
		var perp: Vector2 = Vector2(-dir.y, dir.x) * 26.0
		var tri := PackedVector2Array([base - perp, base + perp, ponta])
		draw_colored_polygon(tri, borda)
		var sb := StyleBoxFlat.new()
		sb.bg_color = fundo
		sb.border_color = borda
		sb.set_border_width_all(5)
		sb.set_corner_radius_all(34)
		sb.shadow_color = Color(0, 0, 0, 0.25)
		sb.shadow_size = 8
		draw_style_box(sb, r)
		var tri2 := PackedVector2Array([base - perp * 0.62, base + perp * 0.62, base + (ponta - base) * 0.86])
		draw_colored_polygon(tri2, fundo)
	else:
		# estrela de pontas (onomatopeia)
		var pts := PackedVector2Array()
		var n := 22
		for i in n * 2:
			var ang: float = TAU * float(i) / float(n * 2)
			var rr: float = 1.0 if i % 2 == 0 else 0.78
			rr += 0.05 * sin(float(i) * 1.7)
			pts.append(c + Vector2(cos(ang) * size.x * 0.5, sin(ang) * size.y * 0.5) * rr)
		var sombra := PackedVector2Array()
		for p in pts: sombra.append(p + Vector2(6, 8))
		draw_colored_polygon(sombra, Color(0, 0, 0, 0.25))
		draw_colored_polygon(pts, Color(1.0, 0.86, 0.3))
		var fecha := pts.duplicate(); fecha.append(pts[0])
		draw_polyline(fecha, borda, 5.0, true)
	# texto
	var asc: float = fonte.get_ascent(fs)
	var pos := Vector2(pad.x, pad.y + asc)
	if tipo == "fala":
		draw_multiline_string(fonte, pos, texto, HORIZONTAL_ALIGNMENT_CENTER, larg, fs, -1, Color(0.22, 0.11, 0.03), QUEBRA)
	else:
		draw_multiline_string_outline(fonte, pos, texto, HORIZONTAL_ALIGNMENT_CENTER, larg, fs, -1, 14, Color(1, 0.97, 0.85), QUEBRA)
		draw_multiline_string(fonte, pos, texto, HORIZONTAL_ALIGNMENT_CENTER, larg, fs, -1, Color(0.75, 0.2, 0.05), QUEBRA)
