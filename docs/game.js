const canvas = document.getElementById('gameCanvas');
const ctx = canvas.getContext('2d');

// --- Sistema de Áudio ---
let audioCtx = null;
let soundEnabled = true;
let musicStarted = false;
let bgmAudio = null;
const audioBuffers = {};

const SOUND_FILES = {
  jump: 'audio/jump.wav',
  gem: 'audio/gem.wav',
  crate: 'audio/crate_hit.wav',
  powerup: 'audio/powerup.wav',
  mount: 'audio/mount.wav',
  kick: 'audio/kick.wav',
  hurt: 'audio/hurt.wav',
  checkpoint: 'audio/checkpoint.wav',
  splash: 'audio/splash.wav',
  victory: 'audio/victory.wav'
};

function initAudio() {
  if (audioCtx) return;
  audioCtx = new (window.AudioContext || window.webkitAudioContext)();
  
  // Carrega SFX
  for (const [key, path] of Object.entries(SOUND_FILES)) {
    fetch(path)
      .then(res => res.arrayBuffer())
      .then(buf => audioCtx.decodeAudioData(buf))
      .then(decoded => { audioBuffers[key] = decoded; })
      .catch(() => {});
  }

  // BGM
  bgmAudio = new Audio('audio/bgm_forro.wav');
  bgmAudio.loop = true;
  bgmAudio.volume = 0.45;
}

function playBGM() {
  if (!soundEnabled || !bgmAudio) return;
  bgmAudio.play().catch(() => {});
  musicStarted = true;
}

function playSFX(key) {
  if (!soundEnabled || !audioCtx || !audioBuffers[key]) return;
  try {
    const src = audioCtx.createBufferSource();
    src.buffer = audioBuffers[key];
    src.connect(audioCtx.destination);
    src.start();
  } catch (e) {}
}

function toggleSound() {
  soundEnabled = !soundEnabled;
  if (bgmAudio) {
    if (soundEnabled) bgmAudio.play().catch(() => {});
    else bgmAudio.pause();
  }
}

// --- Carregamento de Imagens ---
const images = {};
const IMAGE_FILES = {
  sky: 'sprites/scenery/sky_bg.png',
  hills: 'sprites/scenery/hills_bg.png',
  midground: 'sprites/scenery/cerrado_midground.png',
  ground: 'sprites/scenery/ground_main.png',
  plat: 'sprites/scenery/plataforma_flutuante.png',
  rock: 'sprites/scenery/pedra_rio.png',
  water: 'sprites/scenery/rio_agua.png',
  sign: 'sprites/scenery/placa_madeira.png',
  spikes: 'sprites/scenery/espinhos.png',

  zeca_idle: 'sprites/player/zeca_idle.png',
  zeca_walk_1: 'sprites/player/zeca_walk_1.png',
  zeca_walk_2: 'sprites/player/zeca_walk_2.png',
  zeca_walk_3: 'sprites/player/zeca_walk_3.png',
  zeca_walk_4: 'sprites/player/zeca_walk_4.png',
  zeca_jump: 'sprites/player/zeca_jump.png',
  zeca_fall: 'sprites/player/zeca_fall.png',

  faisca_solo: 'sprites/faisca/faisca_solo.png',
  mounted_idle: 'sprites/faisca/mounted_idle.png',
  mounted_trot_1: 'sprites/faisca/mounted_trot_1.png',
  mounted_trot_2: 'sprites/faisca/mounted_trot_2.png',
  mounted_jump: 'sprites/faisca/mounted_jump.png',
  coice_1: 'sprites/faisca/coice_1.png',
  coice_2: 'sprites/faisca/coice_2.png',
  coice_3: 'sprites/faisca/coice_3.png',

  tatu_walk: 'sprites/enemies/tatu_walk_1.png',
  tatu_ball: 'sprites/enemies/tatu_ball.png',
  capivara: 'sprites/enemies/capivara_walk_1.png',
  vespa: 'sprites/enemies/vespa_fly_1.png',
  crab: 'sprites/enemies/caranguejo_walk_1.png',
  seriema_1: 'sprites/enemies/seriema_run_1.png',
  seriema_2: 'sprites/enemies/seriema_run_2.png',

  gem: 'sprites/items/gema.png',
  crate: 'sprites/items/caixote_buriti.png',
  crate_open: 'sprites/items/caixote_aberto.png',
  cajuina: 'sprites/items/cajuina.png',
  rapadura: 'sprites/items/rapadura.png',
  ferradura: 'sprites/items/ferradura.png',
  flag_piaui: 'sprites/items/bandeira_piaui.png',
  varal: 'sprites/items/varal_chegada.png',
  heart_full: 'sprites/items/coracao_cheio.png',
  heart_empty: 'sprites/items/coracao_vazio.png',

  btn_left: 'sprites/ui/btn_left.png',
  btn_right: 'sprites/ui/btn_right.png',
  btn_jump: 'sprites/ui/btn_jump.png',
  btn_action: 'sprites/ui/btn_action.png'
};

let loadedImages = 0;
const totalImages = Object.keys(IMAGE_FILES).length;

for (const [key, path] of Object.entries(IMAGE_FILES)) {
  const img = new Image();
  img.src = path;
  img.onload = () => { loadedImages++; };
  images[key] = img;
}

// --- Estado do Jogo ---
let gameState = 'MENU'; // 'MENU', 'PLAYING', 'PAUSED', 'GAMEOVER', 'VICTORY'
let lives = 3;
let gemsCollected = 0;
const TOTAL_GEMS = 19;
let checkpointPos = null;

// Controles
const keys = { left: false, right: false, jump: false, action: false };
let touchActive = false;

// Configuração dos botões de toque
const touchButtons = {
  left: { x: 80, y: 880, w: 120, h: 120, active: false, id: null },
  right: { x: 230, y: 880, w: 120, h: 120, active: false, id: null },
  jump: { x: 1720, y: 880, w: 120, h: 120, active: false, id: null },
  action: { x: 1560, y: 880, w: 120, h: 120, active: false, id: null }
};

// Player
const player = {
  x: 120,
  y: 720,
  vx: 0,
  vy: 0,
  w: 50,
  h: 130,
  onFloor: false,
  facing: 1,
  isMounted: false,
  isCoice: false,
  coiceTimer: 0,
  canDoubleJump: false,
  coyoteTimer: 0,
  jumpBufferTimer: 0,
  invincibleTimer: 0,
  rapaduraTimer: 0,
  ferraduraTimer: 0,
  walkFrameTimer: 0,
  walkFrameIndex: 0
};

// Câmera
const camera = { x: 0, y: 0 };

// Dados da Fase 1
let platforms = [];
let gems = [];
let crates = [];
let signs = [];
let enemies = [];
let spikes = [];
let faiscaEntity = null;
let checkpointEntity = null;
let chegadaEntity = null;
let floatingText = null;

function resetGame() {
  lives = 3;
  gemsCollected = 0;
  checkpointPos = null;
  initLevel();
}

function initLevel() {
  player.x = checkpointPos ? checkpointPos.x : 120;
  player.y = checkpointPos ? checkpointPos.y : 720;
  player.vx = 0;
  player.vy = 0;
  player.isMounted = false;
  player.isCoice = false;
  player.invincibleTimer = 0.5;
  player.rapaduraTimer = 0;
  player.ferraduraTimer = 0;

  // Plataformas de terra (chão)
  platforms = [
    { x: 0, y: 780, w: 1350, h: 300, type: 'ground' },
    { x: 1950, y: 780, w: 1000, h: 300, type: 'ground' },
    { x: 3050, y: 780, w: 700, h: 300, type: 'ground' },
    { x: 4400, y: 780, w: 900, h: 300, type: 'ground' },
    { x: 5350, y: 780, w: 1500, h: 300, type: 'ground' },

    // Pedras molhadas no rio
    { x: 1480, y: 830, w: 160, h: 60, type: 'rock' },
    { x: 1740, y: 830, w: 160, h: 60, type: 'rock' },

    // Plataformas flutuantes
    { x: 2350, y: 620, w: 300, h: 50, type: 'plat' },
    { x: 2650, y: 570, w: 300, h: 50, type: 'plat' },
    { x: 3950, y: 660, w: 300, h: 50, type: 'plat' },
    { x: 4220, y: 660, w: 300, h: 50, type: 'plat' }
  ];

  // Placas
  signs = [
    { x: 200, y: 780, text: 'Bem-vindo ao Piauí!\nUse setas ou toque para andar. Pule no botão/Espaço.' },
    { x: 760, y: 780, text: 'Bem-vindo a Corrente' },
    { x: 1240, y: 780, text: 'Cuidado: pedras molhadas escorregam!' },
    { x: 5380, y: 780, text: 'Rios Corrente e Paraim' }
  ];

  // Caixotes de Buriti
  crates = [
    { x: 620, y: 610, w: 80, h: 70, content: 'cajuina', opened: false, bounce: 0 },
    { x: 2500, y: 470, w: 80, h: 70, content: 'rapadura', opened: false, bounce: 0 },
    { x: 4700, y: 630, w: 80, h: 70, content: 'ferradura', opened: false, bounce: 0 }
  ];

  // 19 Gemas Âmbar
  gems = [
    { x: 380, y: 720, taken: false },
    { x: 480, y: 720, taken: false },
    { x: 1150, y: 720, taken: false },
    { x: 1480, y: 740, taken: false },
    { x: 1740, y: 740, taken: false },
    { x: 2200, y: 720, taken: false },
    { x: 2350, y: 540, taken: false },
    { x: 2650, y: 490, taken: false },
    { x: 2760, y: 720, taken: false },
    { x: 2880, y: 680, taken: false },
    { x: 3400, y: 720, taken: false },
    { x: 3950, y: 580, taken: false },
    { x: 4220, y: 580, taken: false },
    { x: 4980, y: 720, taken: false },
    { x: 5100, y: 720, taken: false },
    { x: 5480, y: 720, taken: false },
    { x: 5750, y: 720, taken: false },
    { x: 6050, y: 720, taken: false },
    { x: 6220, y: 720, taken: false }
  ];

  // Faísca no estábulo
  faiscaEntity = { x: 3280, y: 780, available: true };

  // Checkpoint
  checkpointEntity = { x: 2880, y: 780, activated: false };

  // Chegada (Varal)
  chegadaEntity = { x: 6420, y: 780 };

  // Espinhos
  spikes = [
    { x: 4620, y: 780, w: 110, h: 40 },
    { x: 4740, y: 780, w: 110, h: 40 },
    { x: 4860, y: 780, w: 110, h: 40 }
  ];

  // Inimigos
  enemies = [
    { type: 'tatu', x: 980, y: 780, vx: -80, w: 80, h: 50, startX: 980, range: 180, isBall: false, ballTimer: 0, alive: true },
    { type: 'capivara', x: 2120, y: 780, vx: -65, w: 80, h: 60, startX: 2120, range: 160, alive: true },
    { type: 'vespa', x: 2500, y: 400, vx: -90, w: 60, h: 60, startX: 2500, startY: 400, range: 240, time: 0, alive: true },
    { type: 'tatu', x: 3580, y: 780, vx: -80, w: 80, h: 50, startX: 3580, range: 140, isBall: false, ballTimer: 0, alive: true },
    { type: 'crab', x: 5600, y: 780, vx: -70, w: 85, h: 50, startX: 5600, range: 150, alive: true },
    { type: 'seriema', x: 5950, y: 780, vx: -90, w: 60, h: 100, startX: 5950, range: 160, sprint: false, alive: true }
  ];
}

// --- Controles de Teclado e Toque ---
window.addEventListener('keydown', e => {
  initAudio();
  if (!musicStarted && soundEnabled) playBGM();

  if (e.code === 'ArrowLeft' || e.code === 'KeyA') keys.left = true;
  if (e.code === 'ArrowRight' || e.code === 'KeyD') keys.right = true;
  if (e.code === 'Space' || e.code === 'ArrowUp' || e.code === 'KeyW') {
    keys.jump = true;
    player.jumpBufferTimer = 0.12;
  }
  if (e.code === 'KeyX') {
    keys.action = true;
    triggerCoice();
  }
  if (e.code === 'Escape' || e.code === 'Enter') {
    if (gameState === 'PLAYING') gameState = 'PAUSED';
    else if (gameState === 'PAUSED') gameState = 'PLAYING';
  }
});

window.addEventListener('keyup', e => {
  if (e.code === 'ArrowLeft' || e.code === 'KeyA') keys.left = false;
  if (e.code === 'ArrowRight' || e.code === 'KeyD') keys.right = false;
  if (e.code === 'Space' || e.code === 'ArrowUp' || e.code === 'KeyW') {
    keys.jump = false;
    if (player.vy < -150) player.vy = -150;
  }
  if (e.code === 'KeyX') keys.action = false;
});

// Toque na tela
function getCanvasCoords(touch) {
  const rect = canvas.getBoundingClientRect();
  const scaleX = canvas.width / rect.width;
  const scaleY = canvas.height / rect.height;
  return {
    x: (touch.clientX - rect.left) * scaleX,
    y: (touch.clientY - rect.top) * scaleY
  };
}

function handleTouches(e) {
  e.preventDefault();
  initAudio();
  if (!musicStarted && soundEnabled) playBGM();
  touchActive = true;

  keys.left = false;
  keys.right = false;

  for (let i = 0; i < e.touches.length; i++) {
    const pt = getCanvasCoords(e.touches[i]);

    // Botões virtuais
    if (pt.x >= 50 && pt.x <= 200 && pt.y >= 840) keys.left = true;
    if (pt.x >= 210 && pt.x <= 360 && pt.y >= 840) keys.right = true;
    if (pt.x >= 1680 && pt.x <= 1860 && pt.y >= 840) {
      if (!keys.jump) {
        keys.jump = true;
        player.jumpBufferTimer = 0.12;
      }
    }
    if (player.isMounted && pt.x >= 1520 && pt.x <= 1670 && pt.y >= 840) {
      triggerCoice();
    }

    // Botão Som no HUD
    if (pt.x >= 1560 && pt.x <= 1740 && pt.y >= 15 && pt.y <= 75) {
      toggleSound();
    }
    // Botão Pausa no HUD
    if (pt.x >= 1760 && pt.x <= 1890 && pt.y >= 15 && pt.y <= 75) {
      if (gameState === 'PLAYING') gameState = 'PAUSED';
      else if (gameState === 'PAUSED') gameState = 'PLAYING';
    }

    // Telas de Menu, GameOver, Victory
    if (gameState === 'MENU') {
      if (pt.x >= 1100 && pt.x <= 1500 && pt.y >= 540 && pt.y <= 630) {
        resetGame();
        gameState = 'PLAYING';
      }
      if (pt.x >= 1100 && pt.x <= 1500 && pt.y >= 660 && pt.y <= 740) {
        toggleSound();
      }
    } else if (gameState === 'GAMEOVER' || gameState === 'VICTORY') {
      if (pt.x >= 700 && pt.x <= 1220 && pt.y >= 600 && pt.y <= 680) {
        resetGame();
        gameState = 'PLAYING';
      }
      if (pt.x >= 700 && pt.x <= 1220 && pt.y >= 700 && pt.y <= 770) {
        gameState = 'MENU';
      }
    } else if (gameState === 'PAUSED') {
      if (pt.x >= 760 && pt.x <= 1160 && pt.y >= 440 && pt.y <= 510) gameState = 'PLAYING';
      if (pt.x >= 760 && pt.x <= 1160 && pt.y >= 530 && pt.y <= 600) toggleSound();
      if (pt.x >= 760 && pt.x <= 1160 && pt.y >= 620 && pt.y <= 690) gameState = 'MENU';
    }
  }

  if (e.touches.length === 0) {
    keys.jump = false;
  }
}

canvas.addEventListener('touchstart', handleTouches, { passive: false });
canvas.addEventListener('touchmove', handleTouches, { passive: false });
canvas.addEventListener('touchend', handleTouches, { passive: false });
canvas.addEventListener('touchcancel', handleTouches, { passive: false });

canvas.addEventListener('mousedown', e => {
  const fakeTouch = { clientX: e.clientX, clientY: e.clientY };
  handleTouches({ preventDefault: () => {}, touches: [fakeTouch] });
});

function triggerCoice() {
  if (!player.isMounted || player.isCoice) return;
  player.isCoice = true;
  player.coiceTimer = 0.3;
  playSFX('kick');

  // Área de impacto atrás do Faísca
  const kickX = player.x + (player.facing > 0 ? -90 : 30);
  const kickY = player.y - 70;
  const kickW = 75;
  const kickH = 75;

  for (const en of enemies) {
    if (!en.alive) continue;
    if (kickX < en.x + en.w && kickX + kickW > en.x && kickY < en.y && kickY + kickH > en.y - en.h) {
      en.alive = false;
      playSFX('kick');
    }
  }
}

// --- Atualização de Física e Lógica ---
let lastTime = performance.now();

function update(dt) {
  if (gameState !== 'PLAYING') return;

  // Timers
  if (player.coyoteTimer > 0) player.coyoteTimer -= dt;
  if (player.jumpBufferTimer > 0) player.jumpBufferTimer -= dt;
  if (player.invincibleTimer > 0) player.invincibleTimer -= dt;
  if (player.rapaduraTimer > 0) player.rapaduraTimer -= dt;
  if (player.ferraduraTimer > 0) player.ferraduraTimer -= dt;

  if (player.isCoice) {
    player.coiceTimer -= dt;
    if (player.coiceTimer <= 0) player.isCoice = false;
  }

  // Movimento Horizontal
  let moveInput = 0;
  if (keys.left) moveInput -= 1;
  if (keys.right) moveInput += 1;

  if (moveInput !== 0) {
    player.facing = moveInput;
    player.walkFrameTimer += dt;
    if (player.walkFrameTimer > 0.12) {
      player.walkFrameTimer = 0;
      player.walkFrameIndex = (player.walkFrameIndex + 1) % 4;
    }
  }

  const baseSpeed = player.isMounted ? 380 : 290;
  const targetSpeed = (baseSpeed + (player.rapaduraTimer > 0 ? 110 : 0)) * moveInput;
  const accel = 1500;
  const friction = 1600;

  if (moveInput !== 0) {
    if (player.vx < targetSpeed) player.vx = Math.min(targetSpeed, player.vx + accel * dt);
    else if (player.vx > targetSpeed) player.vx = Math.max(targetSpeed, player.vx - accel * dt);
  } else {
    if (player.vx > 0) player.vx = Math.max(0, player.vx - friction * dt);
    else if (player.vx < 0) player.vx = Math.min(0, player.vx + friction * dt);
  }

  // Gravidade
  const gravity = 1150;
  player.vy += gravity * dt;

  // Pulo
  if (player.jumpBufferTimer > 0) {
    if (player.onFloor || player.coyoteTimer > 0) {
      player.vy = -510;
      player.coyoteTimer = 0;
      player.jumpBufferTimer = 0;
      playSFX('jump');
    } else if (player.isMounted && player.canDoubleJump) {
      player.canDoubleJump = false;
      player.vy = -490;
      player.jumpBufferTimer = 0;
      playSFX('jump');
    }
  }

  // Aplica movimento
  player.x += player.vx * dt;
  player.y += player.vy * dt;

  // Colisão com plataformas
  player.onFloor = false;
  const footY = player.y;
  const prevFootY = player.y - player.vy * dt;

  for (const plat of platforms) {
    if (player.x + 25 > plat.x && player.x - 25 < plat.x + plat.w) {
      if (prevFootY <= plat.y + 10 && footY >= plat.y) {
        player.y = plat.y;
        player.vy = 0;
        player.onFloor = true;
        player.coyoteTimer = 0.12;
        if (player.isMounted) player.canDoubleJump = true;
      }
    }
  }

  // Colisão com Caixotes de Buriti
  for (const crate of crates) {
    if (player.x + 20 > crate.x && player.x - 20 < crate.x + crate.w) {
      // Bate por baixo
      if (player.y - player.h <= crate.y + crate.h && player.y - player.h >= crate.y && player.vy < 0) {
        player.y = crate.y + crate.h + player.h;
        player.vy = 0;
        if (!crate.opened) {
          crate.opened = true;
          crate.bounce = 12;
          playSFX('crate');
          handleCrateItem(crate);
        }
      }
      // Pousa por cima
      else if (prevFootY <= crate.y && footY >= crate.y) {
        player.y = crate.y;
        player.vy = 0;
        player.onFloor = true;
      }
    }
    if (crate.bounce > 0) crate.bounce = Math.max(0, crate.bounce - 40 * dt);
  }

  // Coleta de Gemas
  for (const gem of gems) {
    if (!gem.taken && Math.hypot(player.x - gem.x, (player.y - 60) - gem.y) < 45) {
      gem.taken = true;
      gemsCollected++;
      playSFX('gem');
    }
  }

  // Montar no Faísca
  if (faiscaEntity && faiscaEntity.available) {
    if (Math.hypot(player.x - faiscaEntity.x, player.y - faiscaEntity.y) < 70) {
      faiscaEntity.available = false;
      player.isMounted = true;
      playSFX('mount');
    }
  }

  // Ativação do Checkpoint
  if (checkpointEntity && !checkpointEntity.activated) {
    if (Math.hypot(player.x - checkpointEntity.x, player.y - checkpointEntity.y) < 60) {
      checkpointEntity.activated = true;
      checkpointPos = { x: checkpointEntity.x, y: checkpointEntity.y };
      floatingText = { text: 'Checkpoint ativado!', x: checkpointEntity.x, y: checkpointEntity.y - 120, life: 2.0 };
      playSFX('checkpoint');
    }
  }

  // Chegada (Varal Junina)
  if (chegadaEntity && Math.hypot(player.x - chegadaEntity.x, (player.y - 80) - (chegadaEntity.y - 80)) < 80) {
    gameState = 'VICTORY';
    playSFX('victory');
  }

  // Espinhos
  for (const spk of spikes) {
    if (player.x + 20 > spk.x && player.x - 20 < spk.x + spk.w && Math.abs(player.y - spk.y) < 25) {
      if (player.ferraduraTimer <= 0 || !player.isMounted) {
        damagePlayer(spk.x);
        player.vy = -350;
      }
    }
  }

  // Inimigos
  for (const en of enemies) {
    if (!en.alive) continue;

    // Movimento específico
    if (en.type === 'tatu') {
      en.x += en.vx * dt;
      if (Math.abs(en.x - en.startX) > en.range) en.vx *= -1;
      en.ballTimer += dt;
      en.isBall = Math.sin(en.ballTimer * 0.8) > 0.4;
    } else if (en.type === 'capivara' || en.type === 'crab') {
      en.x += en.vx * dt;
      if (Math.abs(en.x - en.startX) > en.range) en.vx *= -1;
    } else if (en.type === 'vespa') {
      en.time += dt;
      en.x += en.vx * dt;
      en.y = en.startY + Math.sin(en.time * 3.5) * 45;
      if (Math.abs(en.x - en.startX) > en.range) en.vx *= -1;
    } else if (en.type === 'seriema') {
      if (!en.sprint && Math.abs(player.x - en.x) < 380) {
        en.sprint = true;
        en.vx = (player.x < en.x ? -220 : 220);
      }
      en.x += en.vx * dt;
      if (Math.abs(en.x - en.startX) > 600) en.vx *= -1;
    }

    // Colisão com Player
    const enBox = { x: en.x - en.w/2, y: en.y - en.h, w: en.w, h: en.h };
    const pBox = { x: player.x - 25, y: player.y - player.h, w: 50, h: player.h };

    if (pBox.x < enBox.x + enBox.w && pBox.x + pBox.w > enBox.x && pBox.y < enBox.y + enBox.h && pBox.y + pBox.h > enBox.y) {
      // Pular na cabeça
      if (player.vy > 0 && player.y - player.vy * dt <= enBox.y + 25 && (!en.isBall || player.isMounted)) {
        en.alive = false;
        player.vy = -430;
        playSFX('jump');
      } else {
        damagePlayer(en.x);
      }
    }
  }

  // Queda no Rio
  if (player.y > 980) {
    playSFX('splash');
    lives--;
    if (lives <= 0) {
      gameState = 'GAMEOVER';
    } else {
      player.x = checkpointPos ? checkpointPos.x : 120;
      player.y = checkpointPos ? checkpointPos.y : 720;
      player.vx = 0;
      player.vy = 0;
      player.invincibleTimer = 1.0;
    }
  }

  // Atualiza texto flutuante
  if (floatingText) {
    floatingText.life -= dt;
    floatingText.y -= 25 * dt;
    if (floatingText.life <= 0) floatingText = null;
  }

  // Câmera suave
  const targetCamX = Math.max(0, Math.min(player.x - 960, 5200));
  camera.x += (targetCamX - camera.x) * 6.0 * dt;
}

function handleCrateItem(crate) {
  let item = crate.content;
  if (item === 'ferradura' && !player.isMounted) item = 'gema';

  if (item === 'cajuina') {
    if (lives < 3) lives++;
    playSFX('powerup');
  } else if (item === 'rapadura') {
    player.rapaduraTimer = 6.0;
    playSFX('powerup');
  } else if (item === 'ferradura') {
    player.ferraduraTimer = 10.0;
    playSFX('powerup');
  } else {
    gemsCollected++;
    playSFX('gem');
  }
}

function damagePlayer(fromX) {
  if (player.rapaduraTimer > 0 || player.invincibleTimer > 0) return;

  if (player.isMounted) {
    player.isMounted = false;
    player.invincibleTimer = 1.2;
    player.vy = -260;
    player.vx = (player.x < fromX ? -200 : 200);
    playSFX('mount');
  } else {
    lives--;
    playSFX('hurt');
    if (lives <= 0) {
      gameState = 'GAMEOVER';
    } else {
      player.invincibleTimer = 1.2;
      player.vy = -280;
      player.vx = (player.x < fromX ? -220 : 220);
    }
  }
}

// --- Renderização Gráfica ---
function render() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);

  if (gameState === 'MENU') {
    renderMenu();
    return;
  }

  // 1. Parallax Sky
  if (images.sky) {
    const skyOff = (camera.x * 0.1) % 1280;
    ctx.drawImage(images.sky, -skyOff, 0, 1280, 500);
    ctx.drawImage(images.sky, 1280 - skyOff, 0, 1280, 500);
    ctx.drawImage(images.sky, 2560 - skyOff, 0, 1280, 500);
  }

  // 2. Parallax Hills
  if (images.hills) {
    const hillsOff = (camera.x * 0.28) % 1280;
    ctx.drawImage(images.hills, -hillsOff, 200, 1280, 450);
    ctx.drawImage(images.hills, 1280 - hillsOff, 200, 1280, 450);
    ctx.drawImage(images.hills, 2560 - hillsOff, 200, 1280, 450);
  }

  // 3. Parallax Cerrado & Ipês
  if (images.midground) {
    const midOff = (camera.x * 0.55) % 1280;
    ctx.drawImage(images.midground, -midOff, 320, 1280, 480);
    ctx.drawImage(images.midground, 1280 - midOff, 320, 1280, 480);
    ctx.drawImage(images.midground, 2560 - midOff, 320, 1280, 480);
  }

  ctx.save();
  ctx.translate(-camera.x, 0);

  // Rio Azul (Água no fundo dos vãos)
  if (images.water) {
    for (let x = 0; x < 7500; x += 1280) {
      ctx.drawImage(images.water, x, 780, 1280, 300);
    }
  }

  // Plataformas de Terra
  for (const plat of platforms) {
    if (plat.type === 'ground') {
      if (images.ground) {
        ctx.drawImage(images.ground, plat.x, plat.y, plat.w, plat.h);
      }
    } else if (plat.type === 'plat') {
      if (images.plat) ctx.drawImage(images.plat, plat.x, plat.y, plat.w, plat.h);
    } else if (plat.type === 'rock') {
      if (images.rock) ctx.drawImage(images.rock, plat.x, plat.y, plat.w, plat.h);
    }
  }

  // Placas de Madeira com Texto
  for (const sign of signs) {
    if (images.sign) {
      ctx.drawImage(images.sign, sign.x - 70, sign.y - 120, 140, 120);
      ctx.fillStyle = '#2b1a09';
      ctx.font = 'bold 15px Segoe UI';
      ctx.textAlign = 'center';
      const lines = sign.text.split('\n');
      lines.forEach((line, idx) => {
        ctx.fillText(line, sign.x, sign.y - 90 + idx * 18, 125);
      });
    }
  }

  // Caixotes de Buriti
  for (const crate of crates) {
    const tex = crate.opened ? images.crate_open : images.crate;
    if (tex) {
      ctx.drawImage(tex, crate.x, crate.y - crate.bounce, crate.w, crate.h);
    }
  }

  // Espinhos
  for (const spk of spikes) {
    if (images.spikes) ctx.drawImage(images.spikes, spk.x, spk.y - 35, spk.w, spk.h);
  }

  // Gemas Âmbar
  for (const gem of gems) {
    if (!gem.taken && images.gem) {
      ctx.drawImage(images.gem, gem.x - 22, gem.y - 22, 44, 44);
    }
  }

  // Checkpoint (Bandeira do Piauí)
  if (checkpointEntity && images.flag_piaui) {
    ctx.drawImage(images.flag_piaui, checkpointEntity.x - 40, checkpointEntity.y - 120, 80, 120);
  }

  // Faísca no Estábulo
  if (faiscaEntity && faiscaEntity.available && images.faisca_solo) {
    ctx.drawImage(images.faisca_solo, faiscaEntity.x - 60, faiscaEntity.y - 110, 120, 110);
    ctx.fillStyle = '#ffefba';
    ctx.font = 'bold 18px Segoe UI';
    ctx.textAlign = 'center';
    ctx.strokeStyle = '#2b1a09';
    ctx.lineWidth = 4;
    ctx.strokeText('Faísca! Pegue para montar!', faiscaEntity.x, faiscaEntity.y - 125);
    ctx.fillText('Faísca! Pegue para montar!', faiscaEntity.x, faiscaEntity.y - 125);
  }

  // Chegada (Varal Junina)
  if (chegadaEntity && images.varal) {
    ctx.drawImage(images.varal, chegadaEntity.x - 70, chegadaEntity.y - 180, 140, 180);
  }

  // Inimigos
  for (const en of enemies) {
    if (!en.alive) continue;
    let img = null;
    if (en.type === 'tatu') img = en.isBall ? images.tatu_ball : images.tatu_walk;
    else if (en.type === 'capivara') img = images.capivara;
    else if (en.type === 'vespa') img = images.vespa;
    else if (en.type === 'crab') img = images.crab;
    else if (en.type === 'seriema') img = en.sprint ? images.seriema_2 : images.seriema_1;

    if (img) {
      ctx.save();
      ctx.translate(en.x, en.y);
      if (en.vx > 0) ctx.scale(-1, 1);
      ctx.drawImage(img, -en.w/2, -en.h, en.w, en.h);
      ctx.restore();
    }
  }

  // Texto Flutuante
  if (floatingText) {
    ctx.fillStyle = '#fff4a3';
    ctx.font = 'bold 24px Segoe UI';
    ctx.textAlign = 'center';
    ctx.strokeStyle = '#1e381b';
    ctx.lineWidth = 5;
    ctx.strokeText(floatingText.text, floatingText.x, floatingText.y);
    ctx.fillText(floatingText.text, floatingText.x, floatingText.y);
  }

  // Render do Player (Zeca / Montado)
  if (player.invincibleTimer <= 0 || Math.floor(player.invincibleTimer * 12) % 2 === 0) {
    ctx.save();
    ctx.translate(player.x, player.y);
    if (player.facing < 0) ctx.scale(-1, 1);

    if (player.rapaduraTimer > 0) {
      ctx.filter = 'drop-shadow(0 0 14px gold)';
    } else if (player.ferraduraTimer > 0) {
      ctx.filter = 'drop-shadow(0 0 14px cyan)';
    }

    if (player.isMounted) {
      let mImg = images.mounted_idle;
      if (player.isCoice) {
        mImg = images.coice_2;
      } else if (!player.onFloor) {
        mImg = images.mounted_jump;
      } else if (Math.abs(player.vx) > 10) {
        mImg = (player.walkFrameIndex % 2 === 0) ? images.mounted_trot_1 : images.mounted_trot_2;
      }
      if (mImg) ctx.drawImage(mImg, -80, -180, 160, 180);
    } else {
      let zImg = images.zeca_idle;
      if (!player.onFloor) {
        zImg = player.vy < 0 ? images.zeca_jump : images.zeca_fall;
      } else if (Math.abs(player.vx) > 10) {
        const walkImgs = [images.zeca_walk_1, images.zeca_walk_2, images.zeca_walk_3, images.zeca_walk_4];
        zImg = walkImgs[player.walkFrameIndex] || images.zeca_walk_1;
      }
      if (zImg) ctx.drawImage(zImg, -45, -145, 90, 145);
    }
    ctx.restore();
  }

  ctx.restore();

  // --- HUD ---
  renderHUD();

  // Overlays
  if (gameState === 'PAUSED') renderPause();
  if (gameState === 'GAMEOVER') renderGameOver();
  if (gameState === 'VICTORY') renderVictory();
}

function renderHUD() {
  // Corações
  for (let i = 0; i < 3; i++) {
    const hImg = i < lives ? images.heart_full : images.heart_empty;
    if (hImg) ctx.drawImage(hImg, 40 + i * 55, 25, 48, 48);
  }

  // Título da Fase
  ctx.fillStyle = '#ffefca';
  ctx.font = 'bold 26px Segoe UI';
  ctx.textAlign = 'center';
  ctx.strokeStyle = '#281708';
  ctx.lineWidth = 5;
  ctx.strokeText('FASE 1 • CORRENTE, PIAUÍ', 960, 55);
  ctx.fillText('FASE 1 • CORRENTE, PIAUÍ', 960, 55);

  // Gemas
  if (images.gem) ctx.drawImage(images.gem, 1400, 25, 46, 46);
  ctx.fillStyle = '#ffd152';
  ctx.font = 'bold 28px Segoe UI';
  ctx.textAlign = 'left';
  ctx.strokeStyle = '#2b1a03';
  ctx.lineWidth = 4;
  ctx.strokeText(`${gemsCollected}/${TOTAL_GEMS}`, 1455, 58);
  ctx.fillText(`${gemsCollected}/${TOTAL_GEMS}`, 1455, 58);

  // Botões HUD
  drawButton(1570, 22, 160, 48, soundEnabled ? 'SOM: LIGADO' : 'SOM: MUDO', 18);
  drawButton(1760, 22, 120, 48, 'PAUSA', 18);

  // Botões Virtuais de Toque (Mobile)
  if (images.btn_left) ctx.drawImage(images.btn_left, 80, 880, 120, 120);
  if (images.btn_right) ctx.drawImage(images.btn_right, 230, 880, 120, 120);
  if (images.btn_jump) ctx.drawImage(images.btn_jump, 1720, 880, 120, 120);
  if (player.isMounted && images.btn_action) {
    ctx.drawImage(images.btn_action, 1560, 880, 120, 120);
  }
}

function drawButton(x, y, w, h, text, fontSize) {
  ctx.fillStyle = 'rgba(45, 28, 12, 0.9)';
  ctx.strokeStyle = '#e8c76c';
  ctx.lineWidth = 3;
  roundRect(ctx, x, y, w, h, 10, true, true);

  ctx.fillStyle = '#fff0c7';
  ctx.font = `bold ${fontSize}px Segoe UI`;
  ctx.textAlign = 'center';
  ctx.fillText(text, x + w / 2, y + h / 2 + fontSize / 3);
}

function roundRect(ctx, x, y, w, h, r, fill, stroke) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.lineTo(x + w - r, y);
  ctx.quadraticCurveTo(x + w, y, x + w, y + r);
  ctx.lineTo(x + w, y + h - r);
  ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
  ctx.lineTo(x + r, y + h);
  ctx.quadraticCurveTo(x, y + h, x, y + h - r);
  ctx.lineTo(x, y + r);
  ctx.quadraticCurveTo(x, y, x + r, y);
  ctx.closePath();
  if (fill) ctx.fill();
  if (stroke) ctx.stroke();
}

function renderMenu() {
  if (images.sky) ctx.drawImage(images.sky, 0, 0, 1920, 1080);

  // Título e Subtítulo
  ctx.fillStyle = '#ffefca';
  ctx.font = 'bold 64px Segoe UI';
  ctx.textAlign = 'center';
  ctx.strokeStyle = '#2c1605';
  ctx.lineWidth = 8;
  ctx.strokeText('Tesouros do Nordeste: O Game', 960, 180);
  ctx.fillText('Tesouros do Nordeste: O Game', 960, 180);

  ctx.fillStyle = '#ffd677';
  ctx.font = 'bold 32px Segoe UI';
  ctx.strokeText('Uma aventura pelo Nordeste', 960, 245);
  ctx.fillText('Uma aventura pelo Nordeste', 960, 245);

  // Zeca e Faísca
  if (images.zeca_idle) ctx.drawImage(images.zeca_idle, 460, 480, 190, 360);
  if (images.faisca_solo) ctx.drawImage(images.faisca_solo, 680, 540, 240, 280);

  // Botões
  drawButton(1120, 540, 360, 80, 'COMEÇAR', 30);
  drawButton(1120, 650, 360, 70, soundEnabled ? 'SOM: LIGADO' : 'SOM: MUDO', 22);
}

function renderPause() {
  ctx.fillStyle = 'rgba(0, 0, 0, 0.65)';
  ctx.fillRect(0, 0, 1920, 1080);

  ctx.fillStyle = 'rgba(40, 25, 10, 0.95)';
  ctx.strokeStyle = '#e6c86a';
  ctx.lineWidth = 4;
  roundRect(ctx, 720, 320, 480, 420, 16, true, true);

  ctx.fillStyle = '#ffefca';
  ctx.font = 'bold 44px Segoe UI';
  ctx.textAlign = 'center';
  ctx.fillText('PAUSADO', 960, 390);

  drawButton(760, 440, 400, 65, 'Continuar', 24);
  drawButton(760, 530, 400, 65, soundEnabled ? 'Som: Ligado' : 'Som: Mudo', 24);
  drawButton(760, 620, 400, 65, 'Menu Principal', 24);
}

function renderGameOver() {
  ctx.fillStyle = 'rgba(25, 5, 5, 0.8)';
  ctx.fillRect(0, 0, 1920, 1080);

  ctx.fillStyle = 'rgba(50, 15, 15, 0.95)';
  ctx.strokeStyle = '#e6736a';
  ctx.lineWidth = 4;
  roundRect(ctx, 640, 340, 640, 460, 16, true, true);

  ctx.fillStyle = '#ffdeda';
  ctx.font = 'bold 36px Segoe UI';
  ctx.textAlign = 'center';
  ctx.fillText('FIM DA AVENTURA', 960, 420);
  ctx.font = 'bold 26px Segoe UI';
  ctx.fillText('NÃO DESISTA, ZECA!', 960, 470);

  drawButton(720, 540, 480, 70, 'Jogar novamente', 26);
  drawButton(720, 640, 480, 70, 'Menu Principal', 24);
}

function renderVictory() {
  ctx.fillStyle = 'rgba(5, 25, 10, 0.8)';
  ctx.fillRect(0, 0, 1920, 1080);

  ctx.fillStyle = 'rgba(15, 45, 20, 0.95)';
  ctx.strokeStyle = '#6ae691';
  ctx.lineWidth = 4;
  roundRect(ctx, 600, 260, 720, 540, 16, true, true);

  ctx.fillStyle = '#daffe3';
  ctx.font = 'bold 46px Segoe UI';
  ctx.textAlign = 'center';
  ctx.fillText('FASE CONCLUÍDA!', 960, 340);

  ctx.fillStyle = '#ffd564';
  ctx.font = 'bold 30px Segoe UI';
  ctx.fillText(`Tesouros coletados: ${gemsCollected}/${TOTAL_GEMS}`, 960, 410);

  ctx.fillStyle = '#c7edd2';
  ctx.font = '22px Segoe UI';
  ctx.fillText('Fase 2 em breve: São Gonçalo do Gurguéia e Barreiras do Piauí', 960, 465);

  drawButton(720, 530, 480, 70, 'Jogar novamente', 26);
  drawButton(720, 630, 480, 70, 'Menu Principal', 24);
}

// --- Loop Principal ---
function loop(time) {
  const dt = Math.min((time - lastTime) / 1000, 0.1);
  lastTime = time;

  update(dt);
  render();

  requestAnimationFrame(loop);
}

requestAnimationFrame(loop);
