extends RefCounted
# Lista das fases do jogo, na ordem do mapa do Piauí.
# Uma fase "pronta" tem cena; senão o jogo mostra a tela "Em breve".
# Uma fase fica liberada quando a anterior foi concluída (Progresso).
const LISTA: Array = [
	{"id": "fase1_corrente", "num": 1, "nome": "Corrente",
	 "cena": "res://scenes/Fase1_Corrente.tscn", "historia": "corrente",
	 "frase": "Rios, gente boa e a ExpoCorrente"},
	{"id": "fase2_cristalandia", "num": 2, "nome": "Cristalândia",
	 "cena": "res://scenes/Fase2_Cristalandia.tscn", "historia": "cristalandia",
	 "frase": "A terra dos cristais, bem aqui do lado de Corrente",
	 "imagem": "res://historia/cristalandia/card2.jpg"},
	{"id": "fase3_riacho_frio", "num": 3, "nome": "Riacho Frio e Parnaguá",
	 "cena": "res://scenes/Fase3_RiachoFrioParnagua.tscn", "historia": "riacho_parnagua",
	 "frase": "Do riacho à lagoa, uma viagem pelo extremo sul do Piauí",
	 "imagem": "res://sprites/fase3/riacho_frio_bg.png"},
]

static func info(id: String) -> Dictionary:
	for f in LISTA:
		if f.id == id:
			return f
	return {}

static func indice(id: String) -> int:
	for i in LISTA.size():
		if LISTA[i].id == id:
			return i
	return -1

static func proxima(id: String) -> Dictionary:
	var i := indice(id)
	if i < 0 or i + 1 >= LISTA.size():
		return {}
	return LISTA[i + 1]

static func pronta(id: String) -> bool:
	var f := info(id)
	return not f.is_empty() and String(f.cena) != "" and ResourceLoader.exists(String(f.cena))

static func desbloqueada(id: String) -> bool:
	var i := indice(id)
	if i <= 0:
		return i == 0
	return bool(Progresso.fase(LISTA[i - 1].id).concluida)

# Começa a fase (historinha -> fase) ou mostra a tela "Em breve"
static func jogar(tree: SceneTree, id: String) -> void:
	tree.paused = false
	AudioManager.set_ambiente("passaros", 0.0)
	AudioManager.set_ambiente("rio", 0.0)
	GameManager.reset_game()
	if not pronta(id):
		EmBreve.fase_id = id
		tree.change_scene_to_file("res://scenes/EmBreve.tscn")
		return
	Progresso.set_opcao("fase_menu", id)
	var f := info(id)
	AudioManager.start_music()
	Historia.iniciar(tree, String(f.historia), String(f.cena))
