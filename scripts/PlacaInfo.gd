extends Node2D

@export_multiline var texto: String = "Bem-vindo ao Piauí"
@onready var label: Label = $Label
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	if label:
		var clean_text = texto.strip_edges()
		if (clean_text.begins_with("\"") and clean_text.ends_with("\"")) or (clean_text.begins_with("“") and clean_text.ends_with("”")) or (clean_text.begins_with("'") and clean_text.ends_with("'")):
			clean_text = clean_text.substr(1, clean_text.length() - 2).strip_edges()
		label.text = clean_text
		# Textos longos usam fonte um pouco menor para caber na tábua (máx. 3 linhas)
		if clean_text.length() > 24 and label.label_settings:
			var ls: LabelSettings = label.label_settings.duplicate()
			ls.font_size = 27
			label.label_settings = ls
