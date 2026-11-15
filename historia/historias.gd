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
		 "texto": "Rios, serras, festas, comidas, gente boa... eu vou juntar tudo isso pra mostrar pro mundo o quanto a nossa terra é rica!",
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
}
