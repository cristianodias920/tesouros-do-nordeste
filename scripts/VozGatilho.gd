extends Area2D

# Gatilho de fala do Zeca: quando o Zeca entra na área, toca a fala <fala>.
@export var fala: String = ""
@export var so_a_pe: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	body_entered.connect(_on_body)

func _on_body(body: Node2D) -> void:
	if body is Player and fala != "":
		if so_a_pe and (body as Player).is_mounted:
			return
		VoiceLines.say(fala)
