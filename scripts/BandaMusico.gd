extends Sprite2D
# Músico da banda de forró (Fase 2): 4 quadros pintados em loop, no ritmo da música da fase.
# O compasso vem da posição da faixa que está tocando (124 BPM, igual às duas faixas da Cristalândia);
# sem música, usa o relógio. Pés na origem do nó.
@export var nome: String = "sanfoneiro"          # sanfoneiro / zabumbeiro / triangulo
@export var batidas_por_ciclo: float = 2.0       # quantas batidas dura o ciclo de 4 quadros
@export var deslocamento: float = 0.0            # fase (em batidas) para o golpe cair na batida
const BPM: float = 124.0
var quadros: Array = []
var t: float = 0.0
var quadro: int = -1

func _ready() -> void:
	centered = false
	for i in 4:
		quadros.append(load("res://sprites/cristalandia/banda/%s_%d.png" % [nome, i]))
	_por(0)

func _por(i: int) -> void:
	if i == quadro:
		return
	quadro = i
	texture = quadros[i]
	offset = Vector2(-texture.get_width() * 0.5, -(texture.get_height() - 8))

func batida() -> float:
	var mp: AudioStreamPlayer = AudioManager.music_player
	if mp and mp.playing and mp.stream:
		return mp.get_playback_position() * BPM / 60.0
	return t * BPM / 60.0

func _process(delta: float) -> void:
	t += delta
	var b: float = batida() + deslocamento
	var ciclo: float = fposmod(b / batidas_por_ciclo, 1.0)
	_por(int(ciclo * 4.0) % 4)
	# balanço leve do corpo a cada batida
	position.y = -abs(sin(b * PI)) * 3.0
