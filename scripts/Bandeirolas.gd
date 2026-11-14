extends Node2D

# Cordão de bandeirolas desenhado por código (de (0,0) até (largura,0), com barriga)
@export var largura: float = 800.0
@export var barriga: float = 60.0
@export var cores: PackedColorArray = PackedColorArray([Color(0.2, 0.45, 0.85), Color(0.97, 0.97, 0.95)])
@export var espaco: float = 46.0

func _draw() -> void:
	var pts := PackedVector2Array()
	var n: int = 24
	for i in range(n + 1):
		var x: float = largura * i / n
		var u: float = float(i) / n
		pts.append(Vector2(x, 4.0 * barriga * u * (1.0 - u)))
	draw_polyline(pts, Color(0.35, 0.22, 0.1), 3.0, true)
	var count: int = int(largura / espaco)
	for j in range(count):
		var x: float = (j + 0.5) * espaco
		var u: float = x / largura
		var y: float = 4.0 * barriga * u * (1.0 - u)
		var c: Color = cores[j % cores.size()]
		var tri := PackedVector2Array([Vector2(x - 15, y), Vector2(x + 15, y), Vector2(x, y + 34)])
		draw_colored_polygon(tri, c)
		draw_polyline(PackedVector2Array([tri[0], tri[2], tri[1]]), c.darkened(0.35), 1.5, true)
