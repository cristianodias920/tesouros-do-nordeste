# Áudio - Tesouros do Nordeste: Aventura no Piauí

Este diretório contém as faixas e efeitos sonoros do jogo em formato WAV (PCM 16-bit).

## Arquivos Gerados:
- `bgm_forro.wav`: Música de fundo instrumental com ritmo baião (triângulo sincopado, zabumba e linha melódica estilo sanfona).
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

## Vozes do Zeca (`voz/<id>.wav`)
- 12 falas do Zeca em OGG Vorbis (`voz/<id>.ogg`), gravadas com a voz "Algieba" (Google AI Studio), fornecidas pelo Cristiano. Lista de ids e textos em `voz_lista.txt`.
- Edição: silêncio do início/fim cortado, volume normalizado (fala acima da música), convertidas de WAV para OGG.
- O `VoiceLines.gd` toca cada fala uma vez por partida (a `agua_cai` no máximo a cada 30 s), mostra a legenda em balão sobre o Zeca e abaixa a música enquanto ele fala. Se faltar o arquivo, mostra só a legenda.
