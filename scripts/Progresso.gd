extends Node

# Progresso salvo no aparelho (no navegador, user:// fica no IndexedDB).
# Guarda por fase: concluída, estrelas, melhor nº de tesouros e melhor tempo;
# e as preferências de volume (música, vozes, efeitos).
const ARQUIVO := "user://progresso.cfg"
var cfg := ConfigFile.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	cfg.load(ARQUIVO)

func salvar() -> void:
	cfg.save(ARQUIVO)

func fase(id: String) -> Dictionary:
	return {
		"concluida": bool(cfg.get_value(id, "concluida", false)),
		"estrelas": int(cfg.get_value(id, "estrelas", 0)),
		"melhor_tesouros": int(cfg.get_value(id, "melhor_tesouros", 0)),
		"total": int(cfg.get_value(id, "total", 0)),
		"melhor_tempo": float(cfg.get_value(id, "melhor_tempo", 0.0)),
	}

# Registra o resultado; devolve o que virou recorde
func registrar_fase(id: String, estrelas: int, tesouros: int, total: int, tempo: float) -> Dictionary:
	var antes := fase(id)
	var rec := {
		"primeira_vez": not antes.concluida,
		"estrelas": estrelas > antes.estrelas,
		"tesouros": tesouros > antes.melhor_tesouros,
		"tempo": antes.melhor_tempo <= 0.0 or tempo < antes.melhor_tempo,
	}
	cfg.set_value(id, "concluida", true)
	cfg.set_value(id, "estrelas", max(estrelas, antes.estrelas))
	cfg.set_value(id, "melhor_tesouros", max(tesouros, antes.melhor_tesouros))
	cfg.set_value(id, "total", total)
	if rec.tempo:
		cfg.set_value(id, "melhor_tempo", tempo)
	salvar()
	return rec

func get_opcao(chave: String, padrao):
	return cfg.get_value("opcoes", chave, padrao)

func set_opcao(chave: String, valor) -> void:
	cfg.set_value("opcoes", chave, valor)
	salvar()

static func formatar_tempo(seg: float) -> String:
	var s: int = int(round(seg))
	return "%d:%02d" % [s / 60, s % 60]
