# Gera scenes/Fase2_Cristalandia.tscn (Fase 2 — Cristalândia do Piauí).
# Uso: python3 tools/gerar_fase2.py   (rodar na pasta do projeto)
# Percurso (x): A caminho de Corrente 0–2600 | B centro e festejo 2600–5600 | C Rio Palmeira e nascente 5600–8700
#               Comunidade Esperança 8700–10400 | D veios de cristal 10400–13500 | E Chapada da Limpeza 13500–15800
from PIL import Image
P = './'
CHAO_Y = 780
ALTO_Y = 480          # topo da chapada
FIM_X = 15800

ext = []      # (tipo, path, id)
def res(tipo, path):
    for t, p, i in ext:
        if p == path:
            return i
    i = '%d_r' % (len(ext) + 1)
    ext.append((tipo, path, i))
    return i
def S(path): return res('PackedScene', path)
def T(path): return res('Texture2D', path)
def SC(path): return res('Script', path)

subs = []
def sub_rect(w, h):
    i = 'Rect_%d' % (len(subs) + 1)
    subs.append('[sub_resource type="RectangleShape2D" id="%s"]\nsize = Vector2(%g, %g)\n' % (i, w, h))
    return i

nodes = []
cont = {}
def nome(pref):
    cont[pref] = cont.get(pref, 0) + 1
    return '%s%d' % (pref, cont[pref])
def v(x, y): return 'Vector2(%g, %g)' % (x, y)
def q(s): return '"' + s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n') + '"'
def node(name, parent, typ=None, inst=None, props=None, groups=None):
    h = '[node name="%s"' % name
    if typ: h += ' type="%s"' % typ
    if parent is not None: h += ' parent="%s"' % parent
    if inst: h += ' instance=ExtResource("%s")' % inst
    if groups: h += ' groups=[%s]' % ', '.join(q(g) for g in groups)
    h += ']'
    lines = [h]
    for k, val in (props or {}).items():
        lines.append('%s = %s' % (k, val))
    nodes.append('\n'.join(lines) + '\n')
    return name

# ---------------- raiz ----------------
node('Fase2_Cristalandia', None, 'Node2D', props={'script': 'ExtResource("%s")' % SC('res://scripts/Fase2.gd')})

# ---------------- fundo (parallax) ----------------
node('ParallaxCeu', '.', 'Parallax2D', props={'z_index': -30, 'scroll_scale': v(0.1, 0), 'repeat_size': v(2560, 0), 'repeat_times': 4})
node('Sprite2D', 'ParallaxCeu', 'Sprite2D', props={'texture': 'ExtResource("%s")' % T('res://sprites/scenery_v2/ceu.png'), 'centered': 'false', 'position': v(0, -200)})
node('ParallaxChapada', '.', 'Parallax2D', props={'z_index': -20, 'scroll_scale': v(0.3, 1), 'repeat_size': v(3840, 0), 'repeat_times': 3})
node('Sprite2D', 'ParallaxChapada', 'Sprite2D', props={'texture': 'ExtResource("%s")' % T('res://sprites/cristalandia/chapada_longe.png'), 'centered': 'false', 'position': v(0, 170)})
node('ParallaxCerrado', '.', 'Parallax2D', props={'z_index': -10, 'scroll_scale': v(0.6, 1), 'repeat_size': v(3840, 0), 'repeat_times': 3})
node('Sprite2D', 'ParallaxCerrado', 'Sprite2D', props={'texture': 'ExtResource("%s")' % T('res://sprites/cristalandia/cerrado_meio.png'), 'centered': 'false', 'position': v(0, 200)})

# ---------------- HUD e Zeca ----------------
node('HUD', '.', inst=S('res://scenes/HUD.tscn'))
node('Player', '.', inst=S('res://scenes/Player.tscn'), props={'position': v(120, CHAO_Y), 'cam_limit_left': 0, 'cam_limit_right': FIM_X, 'cam_limit_bottom': 1000})

# ---------------- decoração (atrás do chão) ----------------
node('Decoracao', '.', 'Node2D', props={'z_index': -3})
def deco(name, tex, x, base_y, escala=1.0, flip=False, parent='Decoracao', z=None):
    w, h = Image.open(P + tex[6:]).size
    props = {'texture': 'ExtResource("%s")' % T(tex), 'centered': 'false',
             'position': v(round(x - w * escala / 2), round(base_y - h * escala)), 'scale': v(escala, escala)}
    if flip: props['flip_h'] = 'true'
    if z is not None: props['z_index'] = z
    node(name, parent, 'Sprite2D', props=props)
CR = 'res://sprites/cristalandia/'
# A — cerrado aberto
deco('BuritiA1', 'res://sprites/corrente/buriti.png', 1350, 770, 0.8)
deco('AflorA', CR + 'afloramento_pequeno.png', 2150, 775, 0.8)
# B — centro, festejo de Sant'Ana
deco('IgrejaSantana', CR + 'igreja_santana.png', 3250, 770, 0.62)
# Banda de forró animada (sanfoneiro, zabumbeiro, menina do triângulo), no ritmo da música
node('BandaForro', 'Decoracao', 'Node2D', props={'position': v(3760, 772)})
for nm_m, x_m, esc_m, ciclo_m, desl_m in [('sanfoneiro', -105, 0.98, 4.0, 0.0), ('zabumbeiro', 5, 0.92, 2.0, 0.5), ('triangulo', 110, 0.84, 1.0, 0.125)]:
    node(nm_m.capitalize(), 'Decoracao/BandaForro', 'Sprite2D', props={'position': v(x_m, 0), 'scale': v(esc_m, esc_m), 'script': 'ExtResource("%s")' % SC('res://scripts/BandaMusico.gd'),
         'nome': q(nm_m), 'batidas_por_ciclo': ciclo_m, 'deslocamento': desl_m})
deco('BarracaDoces', CR + 'barraca_doces.png', 4150, 772, 1.0)
deco('Capelinha', CR + 'capelinha.png', 4470, 772, 0.62)
deco('BarracaArtesanato', CR + 'barraca_artesanato.png', 4950, 772, 1.0)
for i, (x0, w, bar) in enumerate([(2750, 1000, 70), (3760, 900, 60)]):
    node('Bandeirolas%d' % (i + 1), 'Decoracao', 'Node2D', props={'position': v(x0, 380 + 20 * i), 'script': 'ExtResource("%s")' % SC('res://scripts/Bandeirolas.gd'), 'largura': '%g' % w, 'barriga': '%g' % bar,
         'cores': 'PackedColorArray(0.9, 0.25, 0.2, 1, 0.98, 0.8, 0.2, 1, 0.2, 0.55, 0.3, 1, 0.2, 0.45, 0.85, 1, 0.95, 0.5, 0.75, 1)'})
# C — Rio Palmeira, nascente e buritis
deco('BuritiC1', 'res://sprites/corrente/buriti.png', 5560, 770, 0.85)
deco('BuritiC2', 'res://sprites/corrente/buriti.png', 6560, 770, 0.7, True)
deco('Nascente', CR + 'nascente.png', 8230, 790, 1.25)
deco('BuritiC3', 'res://sprites/corrente/buriti.png', 7990, 770, 0.95)
deco('BuritiC4', 'res://sprites/corrente/buriti.png', 8560, 770, 0.8, True)
# Comunidade Esperança
deco('CasasEsperanca', CR + 'casas_esperanca.png', 9560, 772, 1.4)
deco('GenteAcenando', CR + 'gente_acenando.png', 9870, 772, 0.8)
deco('Roca', CR + 'roca.png', 10090, 776, 1.05)
deco('MusicosEsperanca', CR + 'musicos_esperanca.png', 10310, 772, 0.8)
# D — veios de cristal
for i, (x, nm, e) in enumerate([(10560, 'afloramento_grande', 1.5), (11520, 'afloramento_pequeno', 1.2), (12020, 'afloramento_grande', 1.2),
                                 (12620, 'afloramento_pequeno', 1.4), (13120, 'afloramento_grande', 1.7), (13460, 'afloramento_pequeno', 1.0)]):
    deco('Aflor%d' % (i + 1), CR + nm + '.png', x, 778, e, i % 2 == 1)
# E — chapada
deco('AflorE1', CR + 'afloramento_pequeno.png', 14520, ALTO_Y - 4, 0.9, True)
deco('BuritiE1', 'res://sprites/corrente/buriti.png', 15050, ALTO_Y - 8, 0.75)

# ---------------- rio (água) ----------------
node('RioVisual', '.', 'Node2D', props={'z_index': -1})
for i, x in enumerate([5700, 7500]):
    node('Agua%d' % (i + 1), 'RioVisual', 'Sprite2D', props={'position': v(x, 808), 'texture': 'ExtResource("%s")' % T('res://sprites/scenery_v2/agua_tile.png'), 'centered': 'false'})

# ---------------- terreno ----------------
node('Terreno', '.', 'Node2D')
CHAO = S('res://scenes/ChaoTerra.tscn')
def chao_span(x0, x1, y=CHAO_Y, pref='Chao'):
    x = x0
    while x < x1:
        xx = min(x, x1 - 1080)
        node(nome(pref), 'Terreno', inst=CHAO, props={'position': v(xx, y)})
        x += 1080
chao_span(-1080, 5800)
chao_span(6440, 7600)
chao_span(7900, FIM_X + 600)
node('Degrau', 'Terreno', inst=CHAO, props={'position': v(13700, 640)})   # degrau antes da chapada (fica embaixo dela)
chao_span(14200, FIM_X + 600, ALTO_Y, 'Chapada')
PEDRA = S('res://scenes/PedraRio.tscn')
for x in [5990, 6250, 7750]:
    node(nome('Pedra'), 'Terreno', inst=PEDRA, props={'position': v(x, 830)})
PLAT = S('res://scenes/PlataformaFlutuante.tscn')
def plat(x, y):  # (x, y) = canto esquerdo/topo da tábua
    node(nome('Plat'), 'Terreno', inst=PLAT, props={'position': v(x, y)})
plat(1450, 560)
plat(6980, 560)
plat(12500, 560)
plat(12820, 450)
# toldos e palco (plataformas invisíveis de passar por baixo)
def toldo(x0, x1, y):
    n = node(nome('Toldo'), 'Terreno', 'StaticBody2D', props={'position': v((x0 + x1) / 2, y), 'collision_mask': 6})
    node('CollisionShape2D', 'Terreno/' + n, 'CollisionShape2D', props={'shape': 'SubResource("%s")' % sub_rect(x1 - x0, 20), 'position': v(0, 10), 'one_way_collision': 'true'})
toldo(3620, 3900, 488)      # palco do trio de forró (topo dos chapéus)
toldo(4012, 4290, 470)      # toldo da barraca de doces
# Pilar de rocha (chapada) sobre a parede de cristais: obriga a usar o chapéu
def pilar(x, y_topo, y_base, nm):
    n = node(nm, 'Terreno', 'StaticBody2D', props={'position': v(x, 0), 'collision_mask': 6})
    node('CollisionShape2D', 'Terreno/' + n, 'CollisionShape2D', props={'shape': 'SubResource("%s")' % sub_rect(130, y_base - y_topo), 'position': v(0, (y_topo + y_base) / 2)})
    rw, rh = Image.open(P + 'sprites/cristalandia/rocha.png').size
    e = 170.0 / rw
    y = y_base
    k = 0
    while y > y_topo - 40:
        node('Rocha%d' % k, 'Terreno/' + n, 'Sprite2D', props={'texture': 'ExtResource("%s")' % T(CR + 'rocha.png'), 'position': v(0, y - rh * e * 0.5 + 6), 'scale': v(e, e), 'flip_h': 'true' if k % 2 else 'false'})
        y -= rh * e * 0.72
        k += 1
pilar(10900, -700, 516, 'PilarCristais')
pilar(12350, -700, 380, 'PilarPendurado')
# limites
node('Limites', '.', 'StaticBody2D', props={'collision_layer': 1, 'collision_mask': 0})
r = sub_rect(40, 4000)
node('ParedeEsq', 'Limites', 'CollisionShape2D', props={'position': v(-20, -200), 'shape': 'SubResource("%s")' % r})
node('ParedeDir', 'Limites', 'CollisionShape2D', props={'position': v(FIM_X + 20, -200), 'shape': 'SubResource("%s")' % r})

# ---------------- tesouros ----------------
node('Tesouros', '.', 'Node2D')
GEMA = S('res://scenes/Gema.tscn')
def gema(x, y, parent='Tesouros', pref='Gema'):
    return node(nome(pref), parent, inst=GEMA, props={'position': v(x, y)})
def comida(x, y, tex, nm_txt, pref):
    return node(nome(pref), 'Tesouros', inst=GEMA, props={'position': v(x, y), 'textura': 'ExtResource("%s")' % T(CR + tex + '.png'), 'nome': q(nm_txt)})
# A (6)
for x, y in [(1050, 650), (1150, 610), (1250, 650), (1610, 480), (2250, 700)]:
    gema(x, y)
# B (8 com o caixote)
for x, y in [(2950, 690), (3560, 690), (3760, 410), (4080, 395), (4220, 395), (5150, 690), (5400, 640)]:
    gema(x, y)
# C (10 com o caixote e o cristal)
for x, y in [(5990, 610), (6250, 610), (7130, 480), (7300, 480), (7750, 620)]:
    gema(x, y)
for x, y in [(8210, 690), (8320, 620), (8430, 690)]:
    comida(x, y, 'doce_buriti', 'Doce de buriti', 'DoceBuriti')
# Comunidade Esperança (5): a cultura da comunidade
gema(8930, 690)
comida(9330, 680, 'sanfona', 'Sanfona', 'Sanfona')
comida(9660, 680, 'tambor', 'Tambor', 'Tambor')
comida(9960, 680, 'mandioca', 'Mandioca da roça', 'Mandioca')
comida(10240, 620, 'saia_samba', 'Samba de roda', 'SambaDeRoda')
# D (soltas; o resto está dentro de cristais)
for x, y in [(10480, 640), (11050, 690), (11150, 690), (11250, 690), (11850, 600), (12450, 690), (12660, 480), (12980, 370), (13280, 690)]:
    gema(x, y)
# E
for x, y in [(13850, 520), (14050, 520), (14420, 410), (15120, 410)]:
    gema(x, y)

# ---------------- caixotes ----------------
node('Caixotes', '.', 'Node2D')
CAIX = S('res://scenes/Caixote.tscn')
# (1950) fica baixa de propósito: montado não passa por baixo -> dica de descer do Faísca; as outras dão para bater montado
for x, y, c in [(1950, 545, 'gema'), (4700, 485, 'gema'), (2500, 485, 'cajuina'), (8560, 485, 'gema'), (11980, 485, 'rapadura'), (14760, 185, 'gema')]:
    node(nome('Caixote'), 'Caixotes', inst=CAIX, props={'position': v(x, y), 'content_type': q(c)})

# ---------------- cristais (só o chapéu quebra) ----------------
node('Cristais', '.', 'Node2D')
CRI = S('res://scenes/Cristal.tscn')
def cristal(nm, x, y, tipo='pequeno', escala=1.0, gemas=()):
    props = {'position': v(x, y)}
    if tipo != 'pequeno': props['tipo'] = q(tipo)
    if escala != 1.0: props['escala'] = '%g' % escala
    node(nm, 'Cristais', inst=CRI, props=props)
    for k, (gx, gy) in enumerate(gemas):
        node('Gema%d' % k, 'Cristais/' + nm, inst=GEMA, props={'position': v(gx, gy)})
cristal('PrimeiroCristal', 6760, CHAO_Y, gemas=[(0, -60)])                    # 1. tutorial na margem do rio
cristal('Parede', 10900, CHAO_Y, 'pequeno', 2.2)                              # 2. passagem fechada (pilar de rocha em cima)
cristal('Geodo', 11700, CHAO_Y, 'geodo', 1.0, [(-40, -100), (0, -80), (40, -100)])   # 3. geodo (2 golpes)
cristal('Pendurado', 12350, 380, 'pendurado', 0.85, [(0, 170)])               # 4. cristais no alto
cristal('Cerca', 13140, CHAO_Y, 'pequeno', 1.3)                               # 5. cerca de cristal com a seriema atrás
cristal('CristalD1', 11480, CHAO_Y, gemas=[(0, -60)])
cristal('CristalD2', 12160, CHAO_Y, 'pequeno', 0.9, [(0, -55)])
cristal('CristalE1', 14900, ALTO_Y, gemas=[(0, -60)])

# ---------------- power-up: chapéu de couro no estande de artesanato ----------------
node('ChapeuCouro', '.', 'Area2D', props={'position': v(4990, 690), 'script': 'ExtResource("%s")' % SC('res://scripts/PowerUpItem.gd'), 'poder': '"chapeu"'})

# ---------------- Faísca ----------------
node('Faisca', '.', inst=S('res://scenes/Faisca.tscn'), props={'position': v(760, CHAO_Y)})

# ---------------- checkpoints ----------------
node('Checkpoints', '.', 'Node2D')
CK = S('res://scenes/Checkpoint.tscn')
for x, y in [(2400, CHAO_Y), (5330, CHAO_Y), (8500, CHAO_Y), (11950, CHAO_Y), (13560, CHAO_Y)]:
    node(nome('Checkpoint'), 'Checkpoints', inst=CK, props={'position': v(x, y)})

# ---------------- inimigos (fauna do Cerrado, nenhum na Comunidade Esperança) ----------------
node('Inimigos', '.', 'Node2D')
for cena, x, y, extra in [('InimigoTatu', 1800, CHAO_Y, {}), ('InimigoTatu', 2720, CHAO_Y, {'patrol_distance': 120}),
                          ('InimigoVespa', 5480, 560, {'patrol_range': 160}), ('InimigoCapivara', 7150, CHAO_Y, {'patrol_distance': 160}),
                          ('InimigoTeju', 11380, CHAO_Y, {'patrol_distance': 140}), ('InimigoVespa', 12760, 400, {'patrol_range': 150}),
                          ('InimigoSeriema', 13330, CHAO_Y, {'patrol_distance': 110}), ('InimigoTatu', 14620, ALTO_Y, {'patrol_distance': 150})]:
    props = {'position': v(x, y)}
    for k, val in extra.items(): props[k] = '%g' % val
    node(nome(cena[7:]), 'Inimigos', inst=S('res://scenes/%s.tscn' % cena), props=props)

# ---------------- placas ----------------
node('Placas', '.', 'Node2D', props={'z_index': -1})
PL = S('res://scenes/PlacaInfo.tscn')
def placa(x, txt, y=CHAO_Y, nm=None):
    node(nm or nome('Placa'), 'Placas', inst=PL, props={'position': v(x, y), 'texto': q(txt)})
PG = S('res://scenes/PlacaGrande.tscn')
def placa_grande(x, titulo, txt, y=CHAO_Y, nm=None, larg=620, alt=250):
    node(nm or nome('PlacaGrande'), 'Placas', inst=PG, props={'position': v(x, y), 'titulo': q(titulo), 'texto': q(txt), 'largura': larg, 'altura': alt})
placa(270, 'Bem-vindo a Cristalândia do Piauí')
placa(2635, 'Festejos de Sant\'Ana — 17 a 26 de julho')
placa(2990, 'Igreja Matriz de Sant\'Ana')
placa(4620, 'Capelinha de N. Sra. Sant\'Ana')
placa(5070, 'Artesanato de couro e cristal')
placa(5660, 'Rio Palmeira')
placa(6580, 'Cristal: use o chapéu!', nm='PlacaPrimeiroCristal')
placa(7480, 'Riacho das Mocinhas')
placa_grande(8060, 'Olho d\'Água Caraíbas', 'Também chamado Fonte Lorena: a nascente do Rio Palmeira, cheia de buritis.', nm='PlacaNascente', larg=600, alt=250)
placa_grande(8960, 'Comunidade Esperança', 'Comunidade quilombola! A certificação foi celebrada em 14 de julho de 2024, com Mandacaru, Mocambinho e Cocos. Samba de roda, tambor e sanfona marcam a cultura das comunidades.', nm='PlacaEsperanca', larg=680, alt=400)
placa(10720, 'Cristais fecham a passagem!', nm='PlacaParede')
placa_grande(15150, 'Chapada da Limpeza', 'O ponto mais ao sul do Piauí, na nascente do Riacho Serrito.', y=ALTO_Y, nm='PlacaExtremoSul', larg=560, alt=240)
node('DicaTutorial', 'Placas', 'Label', props={'offset_left': 380.0, 'offset_top': 330.0, 'offset_right': 1180.0, 'offset_bottom': 420.0,
     'theme_override_colors/font_color': 'Color(0.25, 0.13, 0.04, 1)', 'theme_override_colors/font_outline_color': 'Color(1, 0.96, 0.84, 1)',
     'theme_override_constants/outline_size': 8, 'theme_override_font_sizes/font_size': 30, 'text': '""', 'horizontal_alignment': 1, 'autowrap_mode': 3})

# ---------------- falas do Zeca (gatilhos) ----------------
node('FalasZeca', '.', 'Node2D')
VZ = S('res://scenes/VozGatilho.tscn')
for x, fala, y in [(2820, 'cris_festejo', CHAO_Y), (3250, 'cris_igreja', CHAO_Y), (5600, 'cris_rio', CHAO_Y), (6560, 'cris_cristal_dica', CHAO_Y),
                   (8120, 'cris_nascente', CHAO_Y), (9200, 'cris_esperanca', CHAO_Y), (10450, 'cris_cristais', CHAO_Y), (15200, 'cris_extremo_sul', ALTO_Y)]:
    node('Voz_' + fala, 'FalasZeca', inst=VZ, props={'position': v(x, y), 'fala': q(fala)})

# ---------------- chegada (no mirante da chapada) ----------------
node('BandeirolasChegada', 'Decoracao', 'Node2D', props={'position': v(15480, ALTO_Y - 300), 'script': 'ExtResource("%s")' % SC('res://scripts/Bandeirolas.gd'), 'largura': '300', 'barriga': '40',
     'cores': 'PackedColorArray(0.9, 0.25, 0.2, 1, 0.98, 0.8, 0.2, 1, 0.2, 0.55, 0.3, 1, 0.2, 0.45, 0.85, 1)'})
node('Chegada', '.', inst=S('res://scenes/Chegada.tscn'), props={'position': v(15580, ALTO_Y)})

# água (cair no rio) — o Player também volta se passar da linha d'água
n = node('ZonaAgua', '.', 'Area2D', props={'position': v(7900, 960), 'collision_layer': 16, 'collision_mask': 2, 'script': 'ExtResource("%s")' % SC('res://scripts/ZonaAgua.gd')})
node('CollisionShape2D', 'ZonaAgua', 'CollisionShape2D', props={'shape': 'SubResource("%s")' % sub_rect(18000, 160)})

out = '[gd_scene load_steps=%d format=3]\n\n' % (len(ext) + len(subs) + 1)
for t, p, i in ext:
    out += '[ext_resource type="%s" path="%s" id="%s"]\n' % (t, p, i)
out += '\n' + '\n'.join(subs) + '\n' + '\n'.join(nodes)
open(P + 'scenes/Fase2_Cristalandia.tscn', 'w').write(out)
print('ok', len(nodes), 'nós')
