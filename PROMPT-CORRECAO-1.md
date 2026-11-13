# Tesouros do Nordeste: Correção 1 (tela, cenário, mecânica, controles e web)

Leia tudo antes de começar. Trabalhe em etapas e rode o jogo pelo Godot MCP depois de cada uma. Não mude o estilo das artes, não crie pixel art e não copie nada da Nintendo.

## 1. Contexto

1. O único jogo de verdade é o projeto Godot 4 da raiz (project.godot, scenes/, scripts/, sprites/).
2. A pasta docs/ hoje roda uma versão separada em JavaScript (docs/game.js). Ela não é o jogo do Godot e deve ser apagada.
3. As artes novas estão na pasta cenario-v2/ na raiz do projeto. Copie os arquivos para estes destinos:
   - cenario-v2/ceu.png, morros_longe.png, mata_meio.png, chao_tile.png, agua_tile.png, plataforma.png, placa.png e titulo_fundo.jpg para res://sprites/scenery_v2/
   - cenario-v2/sprites_fix/enemies/*.png para res://sprites/enemies/ (substituir)
   - cenario-v2/sprites_fix/items/*.png para res://sprites/items/ (substituir)
   - cenario-v2/preview_stack.png é só referência visual da montagem, não use no jogo.

## 2. Tela cheia no celular (project.godot)

1. display/window/size/viewport_width=1920 e viewport_height=1080 (manter).
2. display/window/stretch/mode="canvas_items" e display/window/stretch/aspect="expand". Assim um celular 19,5:9 ou 20:9 preenche a tela toda, sem faixas pretas.
3. display/window/handheld/orientation em paisagem (landscape).
4. Todo o HUD usa âncoras nos cantos da tela, nada de posição fixa calculada para 1920.

## 3. Cenário novo da Fase 1 (Fase1_Corrente.tscn)

O cenário atual empilha recortes que repetem placas e elementos. Remova do uso: sky_bg.png, hills_bg.png, cerrado_midground.png, ground_main.png, rio_agua.png e plataforma_flutuante.png. Não use artes/01-cenario-corrente.jpg em nenhuma tela, porque ela já tem placas com texto desenhadas.

1. ParallaxBackground com 3 ParallaxLayer, cada uma com um Sprite2D (centered=false) e motion_mirroring.x igual à largura do sprite já escalado:
   - Ceu: ceu.png (2560x1440), escala 0.75, motion_scale (0.1, 0). Cobre a tela inteira.
   - Morros: morros_longe.png (2160x730), escala 0.75, motion_scale (0.3, 0.02). A base dos morros deve ficar abaixo do topo da mata (sem céu aparecendo entre as camadas).
   - Mata: mata_meio.png (1880x926), escala 0.72, motion_scale (0.6, 0.04). A base da mata deve ficar escondida atrás do chão.
2. Chão (ChaoTerra.tscn): use chao_tile.png com escala 0.5 (cada peça fica 1080x485). A linha da grama está em y=84 px do arquivo, ou seja 42 px abaixo do topo do sprite escalado. O topo do CollisionShape2D do chão precisa ficar exatamente nessa linha, para o Zeca pisar na grama e não flutuar nem afundar.
3. Rio: nos buracos entre os chãos use agua_tile.png (1080x360, contínua na horizontal), com a superfície cerca de 28 px abaixo da linha da grama. A ZonaAgua continua sendo a área de dano ou respawn.
4. Plataformas flutuantes (PlataformaFlutuante.tscn): plataforma.png com escala 0.4 (333x102). Colisão one_way_collision=true com o topo alinhado à grama da plataforma (cerca de 9 px abaixo do topo do sprite escalado) e largura de uns 300 px.
5. Placas (PlacaInfo.tscn): troque placa_madeira.png por placa.png com escala 0.42. O texto vem só do Label, em português, centralizado na tábua (a tábua ocupa do topo até uns 65% da altura da placa). Fonte grande e legível (32 px ou mais, contorno claro). Use "Bem-vindo ao Piauí" uma única vez no começo da fase e "Bem-vindo a Corrente" uma única vez mais adiante. Nenhuma outra placa repetida.
6. Compare o resultado com cenario-v2/preview_stack.png.

## 4. Bug dos objetos "SOM" no chão

1. A causa é sprites/scenery/placa_madeira.png: esse arquivo é o recorte do botão SOM da folha artes/06-itens.jpg, e ele é usado em PlacaInfo.tscn. Por isso aparecem objetos escritos "SOM" no chão. Pare de usar esse arquivo (passo 3.5) e apague-o.
2. Os recortes dos inimigos estavam deslocados: capivara_walk_1/2.png mostravam o tatu enrolado, vespa_fly_1/2.png mostravam a capivara, caranguejo_walk_1/2.png tinham vespa e caranguejo juntos e tatu_ball.png mostrava o tatu andando. Os arquivos corrigidos estão em cenario-v2/sprites_fix/enemies/ com os mesmos nomes.
3. Os itens tinham o nome escrito embaixo (Caixote, Gemas, Vidas, Festa Junina, Bandeira). As versões limpas estão em cenario-v2/sprites_fix/items/. coracao_cheio.png e coracao_vazio.png agora são um coração só, para o HUD mostrar 3 corações e não 9. caixote_aberto.png ainda tem texto: desenhe a tampa aberta por código ou use o caixote_buriti.png com a tampa deslocada.

## 5. Tela de título (MainMenu.tscn)

1. Fundo: sprites/scenery_v2/titulo_fundo.jpg em TextureRect tela cheia (anchors full rect, stretch_mode keep_aspect_covered).
2. Título "Tesouros do Nordeste" grande no topo central (cerca de 110 px, contorno escuro e sombra) e o subtítulo "Fase 1: Corrente, Piauí" logo abaixo.
3. Botões COMEÇAR e SOM centralizados, grandes, com no mínimo 64 px de altura (de preferência 90 px) e 420 px de largura, estilo madeira com texto claro.
4. O Zeca e o Faísca já estão na arte do fundo. Não coloque personagens flutuando por cima.

## 6. Sensação de controle (Player.gd)

Os valores atuais (gravidade 1150, pulo -510, velocidade 290) dão um pulo de só uns 113 px. As plataformas ficam até 210 px acima do chão, então o jogo parece travado. Ajuste:

1. Zeca maior: sprite com escala 0.45 (cerca de 205 px, uns 19% da altura da tela). Montado no Faísca: escala 0.63 (cerca de 1,3 vez o Zeca a pé). Ajuste as colisões para o novo tamanho.
2. Velocidade a pé 450 px/s, montado 560 px/s. Aceleração no chão 3000 px/s², desaceleração 3600 px/s², no ar 80% disso.
3. Pulo de cerca de 260 px de altura: velocidade de pulo -1240 e gravidade de subida 2950. Gravidade de queda 1,6 vez maior (cerca de 4700) e velocidade máxima de queda 1800.
4. Coyote time 0.1 s e buffer de pulo 0.12 s. Pulo variável: ao soltar o botão enquanto sobe, multiplique velocity.y por 0.45.
5. Pulo duplo montado com 85% da força do primeiro.
6. Câmera: position_smoothing_speed 10, olhar à frente uns 180 px na direção do movimento (com lerp suave) e limites para não mostrar abaixo do rio.
7. Ao encostar em inimigo: empurrão para trás (cerca de 420 px/s para o lado e -600 para cima), 1.2 s de invencibilidade piscando, e perde 1 coração. Ao cair na água ou perder todos os corações, volta para o último checkpoint com os corações cheios, como já foi definido.

## 7. Controles de toque e HUD

1. Use TouchScreenButton com ícones visíveis e de alto contraste (fundo escuro semitransparente e seta branca), cada um com uns 150 px.
2. Esquerda e direita no canto inferior esquerdo. Pulo e Ação (coice) no canto inferior direito. Como TouchScreenButton não usa âncoras, posicione os botões por código no _ready e no sinal get_viewport().size_changed, sempre colados nas bordas reais da tela.
3. Multitoque: precisa dar para segurar a direita e tocar no pulo ao mesmo tempo. Cada botão usa sua própria action (move_left, move_right, jump, action) e solta a action quando o próprio dedo sai.
4. Os botões aparecem quando há toque na tela e somem quando o jogador usa o teclado.
5. HUD maior e legível no celular: 3 corações (64 px cada) no canto superior esquerdo, contador de gemas logo abaixo ou ao lado, botões PAUSA e SOM no canto superior direito com no mínimo 72 px de altura.

## 8. Música

1. O bgm_forro.wav é provisório. A música oficial (o forró aprovado) já está em res://audio/bgm_forro.ogg; use ela.
2. No AudioManager.gd, carregue res://audio/bgm_forro.ogg se existir (senão o .wav), com loop ligado, volume_db -10, e só comece a tocar depois do primeiro toque ou tecla (regra do navegador).

## 9. Teste e exportação Web

1. Rode o jogo pelo Godot MCP e tire capturas com a janela em 2400x1080 e em 1920x1080. Corrija até não ter faixas pretas, nem cenário repetido ou duplicado, e até os controles responderem bem.
2. Apague docs/game.js e todo o resto da versão JavaScript dentro de docs/.
3. No export_presets.cfg, no preset Web (já existe, com thread_support=false e renderizador compatibility), troque export_path para docs/index.html. Exporte para docs/.
4. Adicione um favicon (docs/favicon.png feito a partir do rosto do Zeca) e um arquivo vazio docs/.nojekyll.
5. Confira o docs/index.html exportado e avise o Cristiano para fazer commit e push no GitHub.
