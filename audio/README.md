# Áudio - Tesouros do Nordeste: Aventura no Piauí

Este diretório contém as faixas e efeitos sonoros do jogo (efeitos em WAV PCM 16-bit; músicas, vozes e ambientes em OGG Vorbis).

## Arquivos Gerados:
- `bgm_forro.ogg`: Música de fundo instrumental com ritmo baião (triângulo sincopado, zabumba e linha melódica estilo sanfona). A cópia antiga em WAV foi removida do projeto (só o OGG vai para o jogo).
- `jump.wav`: Efeito sonoro de pulo do Zeca e salto do Faísca.
- `gem.wav`: Toque cristalino ao coletar gemas âmbar.
- `crate_hit.wav`: Impacto oco de madeira ao acertar o caixote de buriti.
- `powerup.wav`: Fanfarra melódica ao pegar Cajuína, Rapadura ou Ferradura.
- `mount.wav`: Relincho / salto amistoso ao montar no Faísca.
- `kick.wav`: Impacto sonoro estelar do coice das patas traseiras.
- `hurt.wav`: Dano e recuo do personagem.
- `checkpoint.wav`: Ativação da bandeira de checkpoint.
- `splash.wav`: Queda na água do rio.
- `victory.wav`: Fanfarra festiva de fase concluída nas bandeirinhas juninas.

> Nota: O `AudioManager.gd` gerencia tanto o loop suave da música quanto os efeitos sonoros, respeitando o botão SOM (Ligar/Desligar) e as políticas de inicialização de áudio de navegadores e do editor.

## Zurro do Faísca (`zurro.wav`)
- **Origem:** "Donkey, braying #1" (som nº 1549), de Joseph SARDIN — BigSoundBank / LaSonotheque.
- **Página:** https://bigsoundbank.com/donkey-braying-1-s1549.html (arquivo original: https://bigsoundbank.com/UPLOAD/flac/1549.flac)
- **Licença:** CC0 (domínio público equivalente). Uso livre, inclusive comercial, sem obrigação de crédito.
- **Edição:** trecho de 1,45 s a 4,5 s do original, mono, 22.050 Hz, 16 bits, normalizado, com fade-out. Toca quando o Zeca monta no Faísca.
- Crédito (opcional, mas gentil): "Zurro: Joseph SARDIN — BigSoundBank.com (CC0)".

## Derrota de inimigo com a rapadura (`derrota.wav`)
- Sintetizado no próprio projeto (ruído filtrado de "puf" + arpejo curto de estrelinhas), 0,55 s, mono, 22.050 Hz. Criação original, sem licença de terceiros (livre para o jogo).
- Toca quando o Zeca, com a rapadura, encosta num inimigo e ele some numa nuvem com estrelas.

## Vozes do Zeca (`voz/<id>.ogg`)
- Voz: "Puck" (Google AI Studio), com instrução para soar como um menino adolescente nordestino, animado. Escolhida pelo Cristiano; substitui a voz provisória "Algieba".
- 17 falas, todas gravadas com a Puck: inicio ("Corrente, aqui vou eu!" — trecho final da gravação "Meu nome é Zeca! Corrente, aqui vou eu!"; a apresentação agora fica na historinha), faisca_encontro, faisca_monta, checkpoint_primeiro, rio_corrente, igreja_matriz, nuvens, portal, serra, agua_cai, expo, vitoria, rapadura, rio_paraim, faltam_dez, volta_faisca ("Volta aqui, Faísca!" — toca logo após o relincho, quando o Faísca foge de um golpe montado) e todos_tesouros ("Todos os tesouros de Corrente! Ô terra rica!"). Nada pendente.
- Edição: silêncio do início/fim cortado, volume normalizado (fala acima da música), convertidas de WAV para OGG. Lista de ids e textos em `voz_lista.txt`.
- O `VoiceLines.gd` toca cada fala uma vez por partida (a `agua_cai` no máximo a cada 30 s, a `rapadura` a cada 25 s e a `volta_faisca` a cada 15 s), mostra a legenda em balão sobre o Zeca e abaixa a música enquanto ele fala. A `volta_faisca` só começa depois que o relincho do Faísca termina, para os dois sons não se sobreporem. Se faltar o arquivo, mostra só a legenda.
- Para trocar falas: `python3 tools/preparar_vozes.py <pasta com os .wav>` (mesmos ids), reimportar e exportar a versão Web de novo — nada no código precisa mudar.

## Historinha da fase (`historia/<id>.ogg`)
- Corrente: h1, h2, h3, h4, h6, h8 — voz "Puck" (mesma instrução de adolescente), conferidas por transcrição automática. O h3 é a versão com "Rios, praias, serras...". Processadas com `python3 tools/preparar_vozes.py <pasta> audio/historia`.
- Os cartões 5 e 7 (Faísca) não têm voz: usam o zurro (`zurro.wav`) e um balão de onomatopeia.
- Textos, imagens e posições dos balões ficam em `historia/historias.gd` (uma entrada por fase).

## Música das nuvens e sons de ambiente (novos)
Todos **sintetizados no próprio projeto** com o script `tools/sintetizar_audio.py` (Python + numpy/scipy, sem amostras de terceiros) — criação original, sem licença externa, livre para o jogo.
- `bgm_nuvens.ogg` (42 s, em loop sem emenda): faixa calma e "flutuante" para a área das nuvens — pad suave, arpejo de harpa/marimba, baixo em levada de baião leve, triângulo baixinho e melodia de flauta na escala pentatônica de Sol (Sol–Mi m–Dó–Ré). Toca quando o Zeca está lá em cima nas nuvens; no chão e na vitória volta o forró (troca com cruzamento suave de ~1 s).
- `amb_passaros.ogg` (24 s, loop): passarinhos (assobios, subidas e trinados sintetizados) com um ventinho. Toca baixinho no chão, um pouco mais alto na Serra.
- `amb_rio.ogg` (14 s, loop): correnteza (ruído filtrado com ondulação) e borbulhas. O volume sobe quando o Zeca chega perto da água dos rios.
- `planar.wav` (0,55 s): "fuuu" de vento + notinha, quando o Zeca abre a folha de buriti para planar.

## Volumes
O menu de pausa tem controles separados de **Música**, **Vozes** e **Efeitos** (efeitos + ambiente). Cada um usa um bus de áudio próprio (`Musica`, `Vozes`, `Efeitos`) criado pelo `AudioManager.gd`, e a escolha fica salva no aparelho (`user://progresso.cfg`, que no navegador fica no IndexedDB), junto com o botão SOM.

## Chapéu de couro e cristais (power-up da Fase 2)
- `chapeu_lanca.wav` (arremesso), `chapeu_giro.wav` (giro em voo, em loop), `chapeu_volta.wav` (volta à cabeça),
  `cristal_trinca.wav` (1º golpe no geodo), `cristal_quebra.wav` (cristal se partindo) e `poder_troca.wav` (troca com a reserva).
- Sintetizados no próprio projeto por `tools/sintetizar_chapeu.py` (ruído filtrado + senoides), 22.050 Hz, mono, 16 bits.
  Criação original, sem material de terceiros.

## Músicas da Fase 2 — Cristalândia (`bgm_cris_festa.ogg`, `bgm_cris_cristais.ogg`)
Geradas por `tools/sintetizar_cristalandia.py` (síntese própria, sem amostras de terceiros).
- `bgm_cris_festa.ogg`: base de baião com sanfona festiva (zabumba, triângulo, baixo), 124 BPM, ré mixolídio, ~62 s em loop.
- `bgm_cris_cristais.ogg`: mesma progressão e andamento, mais brilhante e cristalina (sinos/celesta), para os veios de cristal.
- As duas tocam juntas desde o início e a troca é só por volume (sem pular de posição); ao mudar de cena tudo recomeça do zero.
  O conjunto ativo fica em `AudioManager.conjunto` ("corrente" ou "cristalandia").

## Vozes e historinha da Cristalândia (ganchos)
- Falas do Zeca: `voz/cris_*.ogg` (ids em `scripts/VoiceLines.gd`). Sem o arquivo, aparece só o balão.
- Historinha: `historia/cris_h1.ogg` … `historia/cris_h4.ogg`. Sem o arquivo, só o texto.
