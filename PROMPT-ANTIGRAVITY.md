# Tesouros do Nordeste: O Game
# Prompt inicial para o Antigravity + Godot 4.7.2

Leia este arquivo por completo e execute. O diretório atual é o projeto:
c:\\Users\\crist\\Documents\\Projetos Hero SD\\TesourosDoNordeste

Ainda não existe project.godot. Crie e inicialize um projeto Godot 4.7.2.stable neste diretório, sem apagar a pasta artes/ nem este arquivo.

Objetivo desta primeira entrega: uma Fase 1 jogável, polida e detalhada, pronta para testar no editor (F5). Não exporte APK ainda. Não crie a Fase 2 agora.

## 1. O que é o jogo

Plataforma 2D de aventura pelo Nordeste brasileiro, com ênfase no Piauí. O herói é Zeca, um jovem explorador, e o companheiro é o jumentinho Faísca (montaria).

Título: Tesouros do Nordeste: O Game
Subtítulo da tela inicial: Uma aventura pelo Nordeste
Fase 1: Corrente, Piauí (tutorial)
Idioma da interface: português do Brasil
Público: mobile (paisagem) e também jogável no computador com teclado
Dificuldade: média, justa, com checkpoint

O jogo vai ter 8 fases no Piauí no futuro (Corrente; São Gonçalo do Gurguéia + Barreiras do Piauí; Gilbués + Santa Filomena + Monte Alegre; Bom Jesus; Serra das Confusões + Serra da Capivara; Parnaíba; Luís Correia + Barra Grande; Teresina com chefão). Agora implemente SOMENTE a Fase 1. Ao terminar a fase, mostre a tela "FASE CONCLUÍDA!" com tesouros coletados (ex.: 15/19), a mensagem "Fase 2 em breve: São Gonçalo do Gurguéia e Barreiras do Piauí" e os botões "Jogar novamente" e "Menu".

## 2. Estilo visual (obrigatório)

Estilo ILUSTRADO e PINTADO, com traço de tinta suave e pintura tipo aquarela/giz, plantas ornamentais com espirais, cores saturadas e calorosas, céu dourado, textura de papel. As referências oficiais estão em artes/. Recorte os sprites dessas pranchas, remova o fundo creme (deixe transparente) e use-as como verdade visual.

NÃO use pixel art. NÃO use bloco de tijolo, cano, cactus de deserto, "sertão" seco, pobreza ou clichês de seca. NÃO copie personagens, HUD, blocos de interrogação, moedas, bandeiras ou inimigos da Nintendo. Os caixotes de item são de madeira de buriti, com um ponto de interrogação entalhado, como em artes/06-itens.jpg.

Cenário da Fase 1 (seguir artes/01-cenario-corrente.jpg): cerrado verde e vivo, buritis, ipês amarelos floridos, cipós e plantas ornamentais em espiral, rio azul com pedras, colinas ao fundo, plataformas de terra com grama e uma plataforma flutuante com a placa "Bem-vindo a Corrente". Placas de madeira: "Bem-vindo ao Piauí", "Bem-vindo a Corrente" e, mais à frente, "Rios Corrente e Paraim". Flores coloridas na margem. Parallax com pelo menos 3 camadas (céu, colinas, vegetação frontal).

## 3. Personagens e proporções

Zeca (artes/02-zeca.jpg): jovem explorador brasileiro simpático, não caricato. Chapéu de palha com faixa verde, mochila verde, camiseta teal com detalhe amarelo em V, bermuda cáqui, tênis teal. Anime com os quadros da prancha: parado, andar (recrie 4 quadros de caminhada interpolando o passo), pulo e queda.

Faísca (artes/03-faisca-montado.jpg): jumentinho cinza, olho amigável, rédea e sela. Quadros: sozinho, Zeca montado parado, trote e pulo.

Coice (artes/04-coice.jpg): 3 quadros. O Faísca firma as patas da frente, joga as traseiras para trás e para cima, estrela de impacto nos cascos, o chapéu do Zeca dá um pulinho e volta. A área de dano fica atrás, na altura das patas, só no quadro do coice.

Proporção: o conjunto Zeca+Faísca montado deve ter cerca de 1,3 vez a altura do Zeca a pé (não o dobro). A caixa de colisão precisa caber com folga sob blocos e plataformas.

## 4. Mecânicas

- Movimento: aceleração suave, não escorregar como gelo.
- Pulo: altura variável (segurar o botão pula mais), coyote time (~100 ms) e jump buffer (~100 ms).
- Vidas: 3 corações. Cair no rio ou em buraco perde uma vida e respawna no último checkpoint (ou no início). Sem vidas, tela "FIM DA AVENTURA – NÃO DESISTA, ZECA!" com "Jogar novamente".
- Tesouros: gemas âmbar (artes/06-itens.jpg), contador no HUD (ex.: 0/19). Espalhe 19 gemas pela fase.
- Caixote de buriti: ao bater por baixo, solta item ou gema.
- Cajuína: +1 coração (até o máximo de 3, ou um coração temporário extra se já estiver cheio).
- Rapadura: invencibilidade + velocidade por uns 6 segundos, com brilho dourado.
- Faísca: aparece num caixote ou estábulo depois do checkpoint, com o aviso "Faísca! Pegue para montar!". Ao tocar, o Zeca monta. Montado: pulo duplo (um pulo extra no ar) e coice com X (ou botão de toque que só aparece montado). Se levar dano montado, o Faísca foge assustado e o Zeca continua a pé, sem perder coração nesse golpe.
- Ferradura de Ferro: power-up que SÓ sai do caixote quando o Zeca está montado (a pé o mesmo caixote solta gema). Com ela, por 10 segundos, o Faísca anda sobre espinhos sem dano e brilha. Coloque um trecho com espinhos depois do ponto do Faísca.
- Checkpoint: bandeira inspirada no Piauí (canton azul com estrela branca, listras verde e amarela), texto "Checkpoint ativado!".
- Chegada: varal de bandeirinhas de festa junina. Ao tocar, tela de fase concluída.
- Inimigos (artes/05-inimigos.jpg): tatu (anda e às vezes vira bola), capivara perto da água, vespa que voa em padrão, caranguejo nas margens, seriema que corre em linha. O Zeca derrota pulando na cabeça (exceto a vespa, que se desvia ou exige pulo preciso / coice). Contato lateral tira um coração, com invencibilidade curta de 1 segundo. Dificuldade média: não lotar a tela, dar tempo de leitura, mas exigir pulos certeiros nos vãos do rio.

## 5. Layout da Fase 1 (Corrente)

Fase horizontal, cerca de 2 a 3 minutos de jogo numa run boa, em seções claras:

1. Tutorial curto: placas de boas-vindas, chão seguro, 2 ou 3 gemas, um caixote com cajuína, um tatu lento. Dica sutil: "Toque ou use as setas para andar. Pule com o botão ou Espaço."
2. Primeiro vão do rio, com pedras que servem de apoio. Placa "Cuidado: pedras molhadas escorregam!" (um pedaço pode ter um pouco de atrito menor, não instável demais).
3. Área de ipês e plataformas flutuantes, vespa e gemas altas.
4. Checkpoint.
5. Caixote ou estábulo do Faísca, depois um vão que fica mais fácil com pulo duplo (ainda dá para atravessar a pé com habilidade).
6. Trecho de espinhos e caixote que solta a Ferradura se estiver montado.
7. Trecho final junto aos "Rios Corrente e Paraim", caranguejo e seriema, mais gemas, bandeirinhas de chegada.

Coloque o rótulo "FASE 1 • CORRENTE, PIAUÍ" no topo do HUD.

## 6. Controles

Teclado (o jogo deve ganhar foco ao abrir, sem precisar clicar):
- Setas ou A/D: andar
- Espaço, W, seta para cima ou Shift: pular
- X: coice (só montado)
- Enter ou Esc: pausar e despausar

Toque (mobile):
- Botões virtuais à esquerda (andar) e à direita (pulo), visíveis no celular.
- Botão de coice só aparece montado.
- Esconda os botões de toque quando o teclado estiver em uso; mostre de novo se houver toque na tela.

Tela de pausa: "PAUSADO" e botões Continuar, Som, Menu.

## 7. HUD e telas

HUD ilustrado, no espírito de artes/06-itens.jpg: corações, tesouros (n/19), nome da fase, botão SOM.
Tela inicial com o título, o subtítulo "Uma aventura pelo Nordeste", o Zeca e o Faísca, botão "COMEÇAR".
Tela de pausa, game over e fase concluída, todas em português, com o mesmo visual pintado (madeira, céu dourado, plantas).

## 8. Áudio

Música de fundo alegre em loop, estilo forró/baião em versão chiptune ou orquestração simples (sanfona, zabumba, triângulo), volume moderado (não alta demais). A música só começa depois do primeiro toque ou tecla, por restrição dos navegadores e do editor.

Efeitos: pular, pegar gema, bater no caixote, pegar power-up, montar no Faísca, coice, levar dano, checkpoint, bandeira final, cair na água. Botão SOM liga e desliga música e efeitos.

Se não puder gerar arquivos de áudio agora, deixe os players prontos com placeholders e um README em audio/ dizendo o que falta. Não trave o jogo por falta de som.

## 9. Configuração do projeto Godot

- Godot 4.7.2, renderer Forward Plus ou Compatibility (Compatibility é melhor para mobile depois).
- Janela base 1920x1080, modo paisagem, stretch mode canvas_items, aspect keep, scale 1.
- Input Map com as ações: move_left, move_right, jump, action, pause.
- Pastas: artes/ (já existe), scenes/, scripts/, audio/, ui/.
- Cenas principais: MainMenu.tscn, Fase1_Corrente.tscn, Player.tscn, Faisca.tscn, HUD.tscn, PauseMenu.tscn.
- Player com CharacterBody2D, animação em AnimatedSprite2D ou AnimationPlayer.
- Física estável (delta, chão com Floor Snap).
- Código em GDScript, organizado, comentado em português.
- Sem plugins pagos.

## 10. Ordem de trabalho

1. Criar project.godot e as pastas.
2. Importar as imagens de artes/, recortar sprites e remover fundo.
3. Fazer o Zeca andar, pular e animar, com câmera suave.
4. Montar o cenário da Fase 1 com parallax, colisões, placas e rio (cair na água mata).
5. HUD, vidas, gemas e caixotes (cajuína e rapadura).
6. Inimigos.
7. Checkpoint e bandeira de chegada, com as telas de fim e de vitória.
8. Faísca (montar, pulo duplo, coice animado, soltar ao levar dano).
9. Ferradura e espinhos.
10. Controles de toque + teclado e o som.
11. Testar a fase inteira, ajustar dificuldade e colisões. Só então avise que está pronto para eu apertar F5.

Trabalhe de forma incremental e mantenha o jogo jogável a cada etapa. Se algo da arte precisar ser fatiado melhor, fatie. Não invente um visual pixelado "provisório": use as pranchas desde o primeiro sprite.
