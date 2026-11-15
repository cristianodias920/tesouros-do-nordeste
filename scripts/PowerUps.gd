extends Node

# Power-ups que ficam com o Zeca (estilo Super Mario World):
#  - "ativo": o power-up em uso agora (o chapéu arremessa com C; a folha plana segurando PULAR)
#  - "reserva": o power-up guardado. Pegar um power-up novo quando já tem um ativo manda o antigo
#    para a reserva; a tecla V (ou o botão de troca na tela) alterna os dois.
# Fica salvo no aparelho (Progresso.cfg, seção "powerups") e vale para todas as fases.
# Para criar um power-up novo, basta registrar em DADOS e tratar o uso no Player.
signal mudou(ativo: String, reserva: String)

const SECAO := "powerups"
const DADOS: Dictionary = {
	"chapeu": {
		"nome": "Chapéu de couro",
		"icone": "res://sprites/powerups/icone_chapeu.png",
		"usa_botao": true,      # tem botão de usar (C / botão do chapéu)
	},
	"folha": {
		"nome": "Folha de buriti",
		"icone": "res://sprites/items/folha_buriti.png",
		"usa_botao": false,     # plana segurando PULAR (só onde a fase deixa)
	},
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

# Lido sempre do Progresso: se o save for apagado/recarregado, o estado acompanha
func ativo() -> String:
	return String(Progresso.cfg.get_value(SECAO, "ativo", ""))

func reserva() -> String:
	return String(Progresso.cfg.get_value(SECAO, "reserva", ""))

func tem(id: String) -> bool:
	return ativo() == id or reserva() == id

func esta_ativo(id: String) -> bool:
	return ativo() == id

func _gravar(a: String, r: String) -> void:
	Progresso.cfg.set_value(SECAO, "ativo", a)
	Progresso.cfg.set_value(SECAO, "reserva", r)
	Progresso.salvar()
	mudou.emit(a, r)

# Pegou um power-up: vira o ativo; o ativo anterior (se diferente) vai para a reserva.
# Devolve true se mudou algo.
func pegar(id: String) -> bool:
	if not DADOS.has(id):
		push_warning("power-up desconhecido: " + id)
		return false
	var a := ativo()
	var r := reserva()
	if a == id:
		return false
	if a == "":
		_gravar(id, "" if r == id else r)
	elif r == id:
		_gravar(id, a)          # já estava na reserva: só troca
	else:
		_gravar(id, a)          # o antigo vai para a reserva (o que estava lá dá lugar)
	return true

# Alterna ativo <-> reserva. Devolve true se trocou.
func trocar() -> bool:
	var a := ativo()
	var r := reserva()
	if r == "":
		return false
	_gravar(r, a)
	return true

func remover(id: String) -> void:
	var a := ativo()
	var r := reserva()
	if a == id:
		_gravar(r, "")
	elif r == id:
		_gravar(a, "")

func limpar() -> void:
	_gravar("", "")

func icone(id: String) -> Texture2D:
	if DADOS.has(id) and ResourceLoader.exists(DADOS[id].icone):
		return load(DADOS[id].icone)
	return null

func nome(id: String) -> String:
	return String(DADOS[id].nome) if DADOS.has(id) else ""
