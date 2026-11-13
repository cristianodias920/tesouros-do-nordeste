# Correção 3: jogo sempre na horizontal e sem área vazia no celular

Contexto: no celular Android (Chrome), o link do GitHub abre em pé. O cenário fica só no topo, o chão no meio e o resto da tela fica cinza. O jogo precisa ser SEMPRE horizontal, desde a tela de título, sem pedir para o jogador girar o celular.

1. Horizontal obrigatório na versão web:
   1. No primeiro toque (tela de título, botão COMEÇAR ou qualquer toque), chame no JavaScript da página: document.documentElement.requestFullscreen() e, em seguida, screen.orientation.lock("landscape"). No Android isso gira o jogo para horizontal em tela cheia. Faça isso pelo JavaScriptBridge do Godot ou por um script no HTML de exportação (Custom HTML Shell ou head_include no preset Web).
   2. Plano B, para quando o lock não funcionar (iPhone ou navegador que bloqueia): se a janela estiver em pé (altura maior que a largura), gire o canvas 90 graus por CSS (transform: rotate(90deg), com largura e altura trocadas para ocupar a tela toda) e converta as coordenadas de toque para o sistema girado, para os botões continuarem funcionando no lugar certo. Nunca mostre uma tela pedindo para girar.
   3. No project.godot mantenha display/window/handheld/orientation em landscape para o APK.
2. Nada de área cinza: o jogo deve sempre preencher a tela inteira. Defina rendering/environment/defaults/default_clear_color com a cor do céu (#F6B04A) e garanta que as camadas de céu, morros, mata, chão e água cubram toda a área visível em qualquer proporção (16:9, 20:9 e em pé girado). A câmera deve enquadrar o chão no terço de baixo da tela.
3. A tela de título também tem que abrir na horizontal, com a imagem titulo_fundo.jpg cobrindo a tela inteira.
4. Teste com o Godot MCP em 2400x1080 e também simulando uma janela em pé 1080x2400 (deve aparecer girado e ocupando tudo). Depois exporte para docs/ e avise para fazer commit e push.
