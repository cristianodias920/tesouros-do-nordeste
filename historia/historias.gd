extends RefCounted
# Histórias (cutscenes) de cada fase/episódio. Para criar a de outra fase,
# acrescente uma entrada com a mesma estrutura e chame
# Historia.iniciar("<id>", "res://scenes/<Fase>.tscn").
#
# Cada cartão:
#   imagem  - ilustração 16:9 (cobre a tela)
#   quem    - "zeca" (balão de fala + voz) ou "faisca" (balão de onomatopeia + zurro)
#   texto   - texto do balão
#   audio   - voz (ogg) ou "" para só legenda; para o Faísca use "zurro"
#   balao   - centro do balão (0..1 da tela)
#   alvo    - para onde aponta o rabinho do balão (cabeça de quem fala, 0..1)
const HISTORIAS: Dictionary = {
	"corrente": [
		{"imagem": "res://historia/corrente/card1.jpg", "quem": "zeca",
		 "texto": "Ei! Meu nome é Zeca, e eu moro aqui no Piauí.",
		 "audio": "res://audio/historia/h1.ogg", "balao": Vector2(0.64, 0.17), "alvo": Vector2(0.37, 0.25)},
		{"imagem": "res://historia/corrente/card2.jpg", "quem": "zeca",
		 "texto": "Muita gente acha que aqui só tem seca, chão rachado e desertificação... mas o Piauí é cheio de tesouros!",
		 "audio": "res://audio/historia/h2.ogg", "balao": Vector2(0.23, 0.56), "alvo": Vector2(0.41, 0.42)},
		{"imagem": "res://historia/corrente/card3.jpg", "quem": "zeca",
		 "texto": "Rios, praias, serras, festas, comidas, gente boa... eu vou juntar tudo isso pra mostrar pro mundo o quanto a nossa terra é rica!",
		 "audio": "res://audio/historia/h3.ogg", "balao": Vector2(0.66, 0.15), "alvo": Vector2(0.34, 0.3)},
		{"imagem": "res://historia/corrente/card4.jpg", "quem": "zeca",
		 "texto": "Hã? Quem tá aí?",
		 "audio": "res://audio/historia/h4.ogg", "balao": Vector2(0.3, 0.2), "alvo": Vector2(0.37, 0.4)},
		{"imagem": "res://historia/corrente/card5.jpg", "quem": "faisca",
		 "texto": "Ióóó-ióóó!",
		 "audio": "zurro", "balao": Vector2(0.22, 0.2), "alvo": Vector2(0.48, 0.42)},
		{"imagem": "res://historia/corrente/card6.jpg", "quem": "zeca",
		 "texto": "Faísca! Tu quer vir comigo, é?",
		 "audio": "res://audio/historia/h6.ogg", "balao": Vector2(0.27, 0.18), "alvo": Vector2(0.49, 0.38)},
		{"imagem": "res://historia/corrente/card7.jpg", "quem": "faisca",
		 "texto": "Ióóó!",
		 "audio": "zurro", "balao": Vector2(0.18, 0.17), "alvo": Vector2(0.45, 0.3)},
		{"imagem": "res://historia/corrente/card8.jpg", "quem": "zeca",
		 "texto": "Então bora! Primeira parada: Corrente!",
		 "audio": "res://audio/historia/h8.ogg", "balao": Vector2(0.6, 0.15), "alvo": Vector2(0.3, 0.3)},
	],
	# Fase 2 — Cristalândia (textos aprovados pelo Cristiano). Voz: res://audio/historia/cris_h1..4.ogg
	# (gravar com a Puck; enquanto o arquivo não existir, o cartão mostra só o balão).
	"cristalandia": [
		{"imagem": "res://historia/cristalandia/card1.jpg", "quem": "zeca",
		 "texto": "Corrente foi demais, Faísca! Agora é Cristalândia, bem aqui do lado.",
		 "audio": "res://audio/historia/cris_h1.ogg", "balao": Vector2(0.66, 0.2), "alvo": Vector2(0.3, 0.33)},
		{"imagem": "res://historia/cristalandia/card2.jpg", "quem": "zeca",
		 "texto": "Olha esse brilho! Não é à toa que o nome da cidade é Cristalândia.",
		 "audio": "res://audio/historia/cris_h2.ogg", "balao": Vector2(0.62, 0.15), "alvo": Vector2(0.3, 0.3)},
		{"imagem": "res://historia/cristalandia/card3.jpg", "quem": "zeca",
		 "texto": "É tempo dos festejos de Sant'Ana! Forró, festa, e a padroeira da cidade.",
		 "audio": "res://audio/historia/cris_h3.ogg", "balao": Vector2(0.7, 0.16), "alvo": Vector2(0.27, 0.36)},
		{"imagem": "res://historia/cristalandia/card4.jpg", "quem": "zeca",
		 "texto": "Bora juntar os tesouros dessa terra de cristais. Vamos embora, Faísca!",
		 "audio": "res://audio/historia/cris_h4.ogg", "balao": Vector2(0.42, 0.14), "alvo": Vector2(0.3, 0.4)},
	],
	# Fase 3 — Riacho Frio e Parnaguá; textos educativos em legenda.
	"riacho_parnagua": [
		{"imagem": "res://sprites/fase3/riacho_frio_bg.png", "quem": "zeca",
		 "texto": "Depois de Cristalândia, seguimos para Riacho Frio, no extremo sul do Piauí.",
		 "audio": "", "balao": Vector2(0.66, 0.17), "alvo": Vector2(0.35, 0.35)},
		{"imagem": "res://sprites/fase3/riacho_frio_bg.png", "quem": "zeca",
		 "texto": "Riacho Frio aparece entre os destinos de cachoeiras divulgados pelo turismo do estado.",
		 "audio": "", "balao": Vector2(0.66, 0.17), "alvo": Vector2(0.35, 0.35)},
		{"imagem": "res://sprites/fase3/parnagua_lagoa_bg.png", "quem": "zeca",
		 "texto": "Agora vamos pela PI-411 até Parnaguá. A estrada liga os dois municípios.",
		 "audio": "", "balao": Vector2(0.28, 0.18), "alvo": Vector2(0.63, 0.4)},
		 {"imagem": "res://sprites/fase3/parnagua_lagoa_bg.png", "quem": "zeca",
		 "texto": "O município de Parnaguá foi instalado em 1762, junto à Lagoa de Parnaguá.",
		 "audio": "", "balao": Vector2(0.28, 0.18), "alvo": Vector2(0.63, 0.4)},
	],
}
