# Tesouros do Nordeste: Correção 2 (animação do Zeca e pendências)

Leia tudo antes de começar. Trabalhe na ordem e rode o jogo pelo Godot MCP depois de cada etapa. Não mude o estilo das artes, não crie pixel art e não desenhe sprites novos por conta própria: use só os arquivos da pasta zeca-v2/.

## 1. Por que o Zeca anda "olhando para trás"

1. O arquivo sprites/player/zeca_walk_3.png é uma cópia espelhada do zeca_walk_1.png. Nesse quadro o Zeca vira para a esquerda (a mochila troca de lado), por isso a cada passo ele parece olhar para trás.
2. O zeca_walk_4.png é uma pose parada de frente, quase igual ao idle, e o walk_1 e o walk_2 são quase a mesma pose. As pernas não alternam.
3. Os quadros antigos têm tamanhos diferentes (de 204x459 a 352x390) e AnimatedSprite2D centraliza cada um, então o boneco treme e muda de altura ao trocar de quadro. Alguns ainda têm uma sombra bege desenhada embaixo dos pés.

## 2. Trocar os sprites do Zeca

1. A pasta zeca-v2/ (na raiz do projeto) tem os quadros novos, todos virados para a DIREITA, em PNG transparente 512x512, com os pés exatamente na linha y=500 e o corpo centralizado em x=256:
   - zeca_idle.png
   - zeca_walk_1.png, zeca_walk_2.png, zeca_walk_3.png, zeca_walk_4.png (passada, passagem, passada com a outra perna, passagem com o joelho levantado)
   - zeca_jump.png
   - zeca_fall.png
   - preview_walk.gif é só para conferir a animação, não importe no jogo.
2. Copie esses 7 PNG para res://sprites/player/, substituindo os arquivos antigos com o mesmo nome. Não deixe nenhum outro zeca_walk_*.png sobrando nessa pasta.
3. No painel Import, deixe os 7 arquivos com Filter ligado (Linear) e Mipmaps desligado, e clique em Reimport.

## 3. Refazer o SpriteFrames (sprites/player_frames.tres)

1. Animação "walk": exatamente 4 quadros na ordem zeca_walk_1, zeca_walk_2, zeca_walk_3, zeca_walk_4, duração 1.0 cada, loop ligado, speed 12 fps.
2. Animação "idle": só zeca_idle.png, loop ligado.
3. Animação "jump": só zeca_jump.png, sem loop.
4. Animação "fall": só zeca_fall.png, sem loop.
5. Não mexa nas animações mounted_idle, mounted_walk, mounted_jump e coice.

## 4. Posição do sprite (Player.tscn e Player.gd)

1. Os quadros novos têm o pé 244 px abaixo do centro do PNG. Com escala 0.45 isso dá 110 px. Então, a pé, o AnimatedSprite2D fica em position = Vector2(0, -110) com scale = Vector2(0.45, 0.45). Assim os pés ficam exatamente na base do CollisionShape2D (que vai de y=-180 até y=0).
2. Atualize isso em dois lugares: no nó AnimatedSprite2D de scenes/Player.tscn e no bloco "else" (a pé) de apply_character_scale() em scripts/Player.gd (hoje está Vector2(0, -103)).
3. O bloco montado (escala 0.63, posição (0, -134)) continua igual.
4. Confira no Godot MCP: com o Zeca parado no chão, a sola do tênis precisa encostar na grama, sem flutuar nem afundar, em idle e em todos os quadros do walk.

## 5. Virar para o lado certo (Player.gd)

1. Os sprites olham para a direita, então flip_h = true só quando ele anda para a esquerda.
2. Troque o trecho que hoje vira o sprite pela entrada (input_x) por esta regra, chamada depois de calcular velocity.x:
   - se abs(velocity.x) > 10: facing_direction = sign(velocity.x)
   - animated_sprite.flip_h = facing_direction < 0
   - quando ele está parado, NÃO mude facing_direction: ele continua olhando para o último lado em que andou.
3. Durante o empurrão de dano (hit_by_enemy) e durante o coice, não vire o sprite: guarde uma variável lock_facing_timer de 0.25 s e só atualize facing_direction quando ela for zero.
4. A mesma regra de flip vale montado no Faísca (os sprites do Faísca também olham para a direita). Mantenha kick_area.position.x = -70 * facing_direction, porque o coice é para trás.

## 6. Velocidade da animação de andar

1. Em update_animation(), quando tocar "walk": animated_sprite.speed_scale = clamp(abs(velocity.x) / WALK_SPEED, 0.6, 1.4).
2. Para qualquer outra animação (idle, jump, fall e as montadas), volte speed_scale para 1.0.
3. Para "mounted_walk" use clamp(abs(velocity.x) / MOUNTED_SPEED, 0.6, 1.4).
4. Use play() só quando a animação mudar (compare com animated_sprite.animation), para não reiniciar o quadro 1 a cada frame.

## 7. Pendências da Correção 1

Já está feito e não precisa mexer: docs/ exportado pelo Godot, stretch canvas_items + expand, paisagem, cenário scenery_v2 com parallax, chão e plataformas com colisão na linha da grama, placa.png + Label, sprites_fix de inimigos e itens, tela de título nova, valores de física do Player.gd, empurrão e invencibilidade, botões de toque e HUD, AudioManager com bgm_forro.ogg.

Falta corrigir:

1. Caixote aberto com texto: scripts/Caixote.gd (linhas 25 e 26) ainda carrega sprites/items/caixote_aberto.png, que tem o nome escrito embaixo. Pare de usar esse arquivo e apague-o. Ao quebrar, mantenha caixote_buriti.png e mostre a tampa aberta por código: um Sprite2D com a parte de cima do caixote (region do topo, cerca de 30% da altura) deslocado 40 px para cima e girado 25 graus, com um tween curto.
2. Artes antigas sobrando: apague sprites/scenery/sky_bg.png, hills_bg.png, cerrado_midground.png, ground_main.png, rio_agua.png e plataforma_flutuante.png (e os .import). Nenhuma cena usa mais. Mantenha espinhos.png e pedra_rio.png, que ainda são usados.
3. Placa: em scenes/PlacaInfo.tscn o font_size do Label está 28. Suba para 34 e confira que "Bem-vindo ao Piauí" cabe na tábua em no máximo 2 linhas.
4. Música: em audio/bgm_forro.ogg.import está loop=false. Na aba Import marque Loop e reimporte (o código já liga o loop, mas assim fica garantido no Web).
5. Exportação pesada: o docs/index.pck tem 29 MB porque leva junto as pastas artes/, cenario-v2/, docs/ e tools/. Faça assim:
   - crie um arquivo vazio docs/.gdignore (e também em artes/, cenario-v2/, zeca-v2/ e tools/), para o Godot não importar essas pastas;
   - apague docs/favicon.png.import;
   - no preset Web do export_presets.cfg coloque exclude_filter="artes/*, cenario-v2/*, zeca-v2/*, docs/*, tools/*, *.md".

## 8. Teste e exportação

1. Rode a Fase 1 pelo Godot MCP com a janela em 2400x1080. Ande para a direita e para a esquerda, pare e pule. Confira e tire capturas:
   - andando para a direita o Zeca olha para a direita em todos os quadros, e para a esquerda olha para a esquerda;
   - as pernas alternam e ele não treme nem muda de altura ao trocar de quadro;
   - ao parar ele continua virado para o último lado;
   - idle, jump e fall não dão salto de posição ao trocar.
2. Teste também montado no Faísca (andar, pulo duplo e coice).
3. Exporte o preset Web para docs/index.html. Confira se docs/.nojekyll continua lá e se o index.pck ficou bem menor que 29 MB.
4. Avise o Cristiano para fazer commit e push no GitHub e testar o link no celular.

## Extra: problemas vistos no teste do link (13/11)

1. Fundo com buracos cinza e emendas: ao andar, aparecem retângulos cinza (sem cenário) e cortes duros entre as camadas. Causa provável: motion_mirroring diferente da largura real da textura vezes a escala (ex.: morros_longe 2160 x 0.75 = 1620, mata_meio 1880 x 0.72 = 1354), e camadas que não cobrem a tela inteira quando o aspect é expand (celular 20:9 mostra mais de 1920 px de largura).
   Correção: troque os ParallaxLayer pelo nó Parallax2D (Godot 4.3+), um por camada, com scroll_scale (céu 0.1, morros 0.3, mata 0.6), repeat_size igual à largura da textura vezes a escala do Sprite2D, repeat_times 3, e Sprite2D com centered = false. Garanta que cada camada cubra toda a altura visível (céu do topo até atrás do chão, morros e mata encostando no chão sem faixa vazia). Pinte o fundo padrão do projeto com a cor do céu (rendering/environment/defaults/default_clear_color = #F6B04A) para nunca aparecer cinza.
   O chão (chao_tile) e a água devem ser contínuos até o fim da fase, sem vãos fora dos buracos de rio planejados.
2. Zeca está pequeno (cerca de 10% da altura da tela). Ajuste a escala para ficar entre 18% e 20% da altura de 1080 (cerca de 200 px de altura em pé) e ajuste a colisão junto. Faísca montado cerca de 1,3 vezes isso.
3. Zeca fica escondido atrás das placas e da mata: coloque o Player com z_index maior que placas, caixotes e cenário (ex.: player 10, inimigos e itens 5, placas 0).
4. Texto das placas está pequeno e com aspas: remova as aspas, use fonte 34 ou maior, cor escura com contorno claro, centralizado na tábua.
5. Teste com o Godot MCP em 2400x1080 e 1920x1080 andando a fase inteira até o fim, tirando screenshots no começo, no meio e no fim, e só exporte quando não houver nenhuma área cinza ou emenda.
