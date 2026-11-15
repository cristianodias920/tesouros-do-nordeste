# Efeitos do chapéu bumerangue e dos cristais — sintetizados no próprio projeto (sem material de terceiros).
# Uso: python3 tools/sintetizar_chapeu.py  (gera em audio/: chapeu_lanca.wav, chapeu_giro.wav (loop),
#      chapeu_volta.wav, cristal_trinca.wav, cristal_quebra.wav, poder_troca.wav)
import numpy as np, soundfile as sf
from scipy.signal import butter, lfilter
SR=22050
rng=np.random.default_rng(11)
def lp(x,f): b,a=butter(2,f/(SR/2)); return lfilter(b,a,x)
def hp(x,f): b,a=butter(2,f/(SR/2),'high'); return lfilter(b,a,x)
def bp(x,f1,f2): b,a=butter(2,[f1/(SR/2),f2/(SR/2)],'band'); return lfilter(b,a,x)
def save(x,nome,pico=0.85):
    x=x/(np.abs(x).max()+1e-9)*pico
    sf.write('audio/'+nome,x.astype(np.float32),SR,subtype='PCM_16')
def t_(d): return np.arange(int(SR*d))/SR
def whoosh(d, f0, f1, am_hz=0.0):
    t=t_(d); n=len(t)
    noise=rng.standard_normal(n)
    out=np.zeros(n); blk=256
    fc=np.geomspace(f0,f1,n)
    for i in range(0,n,blk):   # filtro passa-faixa que varre (sopro de ar)
        c=fc[i]; seg=noise[max(0,i-512):i+blk]
        y=bp(seg,c*0.6,min(c*1.6,SR/2-100))[-min(blk,n-i):]
        out[i:i+len(y)]=y
    env=np.sin(np.pi*np.clip(t/d,0,1))**1.5
    if am_hz>0: env*=0.55+0.45*np.abs(np.sin(np.pi*am_hz*t))
    return out*env
# arremesso: sopro rápido subindo + estalo de couro
t=t_(0.32)
lanca=whoosh(0.32,500,2600)
snap=np.zeros_like(t); k=int(0.012*SR); snap[:k]=rng.standard_normal(k)*np.exp(-np.arange(k)/(0.003*SR))
lanca+=hp(snap,900)*0.9
save(lanca,'chapeu_lanca.wav',0.8)
# giro em voo: loop de 0,48 s com "fu-fu-fu" (6 voltas/s), emendável
d=0.5; g=whoosh(d,900,1100,am_hz=6.0)
g=g/np.sin(np.pi*np.clip(t_(d)/d,0.02,0.98))**1.5   # tira o envelope de entrada/saída
g*=0.55+0.45*np.abs(np.sin(np.pi*6.0*t_(d)))
fade=int(0.02*SR); g[:fade]*=np.linspace(0,1,fade); g[-fade:]*=np.linspace(1,0,fade)
save(g,'chapeu_giro.wav',0.45)
# volta à cabeça: "puf" macio de couro + plim dourado
t=t_(0.45)
puf=lp(rng.standard_normal(len(t)),700)*np.exp(-t/0.05)
plim=sum(np.sin(2*np.pi*f*t)*np.exp(-t/0.18)*a for f,a in [(1568,0.5),(2093,0.35),(3136,0.15)])
plim[:int(0.06*SR)]=0; plim=np.roll(plim,0)
save(puf*1.4+plim*0.5,'chapeu_volta.wav',0.75)
# cristal trinca (1º golpe no geodo): estalo seco + ressonâncias de vidro curtas
t=t_(0.4)
clk=hp(rng.standard_normal(len(t)),2500)*np.exp(-t/0.01)
res=sum(np.sin(2*np.pi*f*t+rng.uniform(0,6))*np.exp(-t/0.09) for f in [2637,3520,4186,5274])
save(clk*1.2+res*0.35,'cristal_trinca.wav',0.8)
# cristal quebra: estilhaços cristalinos caindo (muitos "tins" aleatórios) + chiado de vidro
t=t_(1.0); out=np.zeros(len(t))
out+=hp(rng.standard_normal(len(t)),3000)*np.exp(-t/0.12)*0.8
for i in range(34):
    t0=abs(rng.normal(0,0.18)); f=rng.uniform(2200,6200); a=rng.uniform(0.25,1.0)*np.exp(-t0*2.5)
    i0=int(t0*SR); tt=t[:len(t)-i0]
    out[i0:]+=np.sin(2*np.pi*f*tt)*np.exp(-tt/rng.uniform(0.03,0.12))*a
low=sum(np.sin(2*np.pi*f*t)*np.exp(-t/0.35) for f in [523.25,659.25,783.99])*0.25
save(out+low,'cristal_quebra.wav',0.85)
# troca de power-up: dois toques subindo
t=t_(0.3); out=np.zeros(len(t))
for t0,f in [(0.0,880),(0.09,1318.5)]:
    i0=int(t0*SR); tt=t[:len(t)-i0]
    out[i0:]+=(np.sin(2*np.pi*f*tt)+0.3*np.sin(4*np.pi*f*tt))*np.exp(-tt/0.08)
save(out,'poder_troca.wav',0.6)
print('ok')
