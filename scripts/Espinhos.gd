extends Area2D

# Espinhos: machucam ao entrar E enquanto o Zeca continuar em cima
# (o Player já ignora o dano durante a invencibilidade ou com a Ferradura montado)

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		(body as Player).hit_by_spikes()

func _physics_process(_delta: float) -> void:
	for b in get_overlapping_bodies():
		if b is Player:
			(b as Player).hit_by_spikes()
