extends Node2D

@export_multiline var texto: String = "Bem-vindo ao Piauí"
@onready var label: Label = $Label
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	if label:
		label.text = texto
