extends Area2D

# Faísca esperando no estábulo. Ao tocar, o Zeca monta.
# Se o Faísca fugir (dano) e o Zeca voltar ao checkpoint, ele reaparece aqui.

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label
var time_passed: float = 0.0
var available: bool = true

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	GameManager.player_respawned.connect(_on_player_respawned)

func _process(delta: float) -> void:
	time_passed += delta
	# Efeito flutuante suave no texto
	label.position.y = -130 + sin(time_passed * 3.0) * 5.0
	if available:
		var p = get_tree().get_first_node_in_group("player")
		if p and not p.is_mounted and abs(p.global_position.x - global_position.x) < 420 and abs(p.global_position.y - global_position.y) < 300:
			VoiceLines.say("faisca_encontro")

func _on_body_entered(body: Node2D) -> void:
	if not available:
		return
	if body is Player:
		var p = body as Player
		if not p.is_mounted:
			p.mount_faisca()
			_set_available(false)

func _set_available(value: bool) -> void:
	available = value
	visible = value
	set_deferred("monitoring", value)

func _on_player_respawned() -> void:
	if available:
		return
	var p = get_tree().get_first_node_in_group("player")
	if p and not p.is_mounted:
		_set_available(true)
