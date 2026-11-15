# Áudio original sintetizado para o jogo (sem material de terceiros).
# Uso: python3 tools/sintetizar_audio.py  (gera bgm_nuvens.ogg, amb_passaros.ogg, amb_rio.ogg e planar.wav em audio/)
import numpy as np, soundfile as sf, subprocess
from scipy.signal import butter, lfilter, fftconvolve
SR=32000
PEAK={'bgm_nuvens.ogg':0.63}
rng=np.random.default_rng(7)
def env(n,a=0.01,r=0.3):
    t=np.arange(n)/SR; e=np.minimum(1,t/max(a,1e-4))*np.exp(-t/r); return e
def note_hz(m): return 440*2**((m-69)/12)
def reverb(x,dec=1.8,mix=0.28):
    n=int(SR*dec); ir=rng.standard_normal(n)*np.exp(-np.arange(n)/SR*4.5/dec)
    b,a=butter(2,4000/(SR/2)); ir=lfilter(b,a,ir); ir/=np.abs(ir).sum()**0.5*8
    w=fftconvolve(x,ir)[:len(x)]; return x*(1-mix)+w*mix*3
def lp(x,f): b,a=butter(2,f/(SR/2)); return lfilter(b,a,x)
def hp(x,f): b,a=butter(2,f/(SR/2),'high'); return lfilter(b,a,x)
def bp(x,f1,f2): b,a=butter(2,[f1/(SR/2),f2/(SR/2)],'band'); return lfilter(b,a,x)
def save_ogg(x,path,q=4):
    x=x/ (np.abs(x).max()+1e-9)*PEAK.get(path.split('/')[-1],0.89)
    sf.write('/tmp/_t.wav',x.astype(np.float32),SR)
    subprocess.run(['ffmpeg','-y','-loglevel','error','-i','/tmp/_t.wav','-c:a','libvorbis','-q:a',str(q),'-ac','1' if x.ndim==1 else '2',path],check=True)

# ---------- música das nuvens: calma, "flutuante", pulsar leve de baião ----------
def bgm_nuvens(path):
    bpm=92; beat=60/bpm; bars=16; spb=4
    L=int(SR*beat*spb*bars); out=np.zeros(L+SR*3)
    prog=[(55,[67,71,74]),(52,[64,67,71]),(48,[64,67,72]),(50,[66,69,74])]  # G Em C D
    def place(sig,t):
        i=int(t*SR); out[i:i+len(sig)]+=sig[:max(0,len(out)-i)]
    def pluck(m,dur,amp,bright=1.0):
        n=int(SR*dur); t=np.arange(n)/SR; f=note_hz(m)
        s=np.sin(2*np.pi*f*t)+0.35*bright*np.sin(4*np.pi*f*t)+0.12*bright*np.sin(6*np.pi*f*t)
        return s*env(n,0.004,dur*0.45)*amp
    def flute(m,dur,amp):
        n=int(SR*dur); t=np.arange(n)/SR; f=note_hz(m)
        vib=1+0.004*np.sin(2*np.pi*5.2*t)*np.minimum(1,t/0.3)
        ph=2*np.pi*np.cumsum(f*vib)/SR
        s=np.sin(ph)+0.18*np.sin(2*ph)+0.05*np.sin(3*ph)
        breath=lp(rng.standard_normal(n),2500)*0.03
        a=np.minimum(1,t/0.06)*np.minimum(1,(dur-t)/0.12).clip(0,1)
        return (s+breath)*a*amp
    def pad(ms,dur,amp):
        n=int(SR*dur); t=np.arange(n)/SR; s=np.zeros(n)
        for m in ms:
            for d in (-0.07,0.07):
                s+=np.sin(2*np.pi*note_hz(m+d)*t)
        a=np.minimum(1,t/0.8)*np.minimum(1,(dur-t)/0.8).clip(0,1)
        return lp(s,1800)*a*amp/len(ms)
    # melodia (pentatônica de Sol), frases de 4 compassos
    mel=[[74,None,76,79, 78,None,76,74, 71,None,74,None, 76,None,None,None],
         [74,None,71,69, 67,None,69,71, 74,None,72,71, 69,None,None,None],
         [79,None,78,76, 74,None,76,78, 79,None,81,79, 78,None,76,None],
         [74,None,71,74, 76,None,74,71, 69,None,71,69, 67,None,None,None]]
    for bar in range(bars):
        root,ch=prog[bar%4]; t0=bar*beat*spb
        place(pad([m-12 for m in ch],beat*spb+0.6,0.22),t0)
        # baixo: baião suave (1, "e" do 2, 3)
        for bt,ln in [(0,0.9),(1.5,0.4),(2,0.9),(3.5,0.4)]:
            place(pluck(root-12,beat*ln*1.6,0.42,0.4),t0+bt*beat)
        # arpejo de "harpa"/marimba
        arp=[ch[0],ch[1],ch[2],ch[1]+12 if False else ch[2]+5-5]
        for k in range(8):
            m=[ch[0],ch[1],ch[2],ch[0]+12][k%4]
            place(pluck(m,0.9,0.13,1.2),t0+k*beat/2)
        # triângulo levinho
        for k in range(8):
            n=int(SR*0.12); tri=hp(rng.standard_normal(n),6000)*env(n,0.001,0.03 if k%2==0 else 0.06)
            place(tri*(0.05 if k%2==0 else 0.08),t0+k*beat/2)
        if bar>=4:
            ph=mel[(bar//4-1)%4 if bar<12 else (bar//4)%4]
            for k in range(4):
                m=ph[(bar%4)*4+k]
                if m:
                    ln=1
                    while (bar%4)*4+k+ln<16 and ph[(bar%4)*4+k+ln] is None and ln<3: ln+=1
                    place(flute(m,beat*ln*0.98,0.2),t0+k*beat)
    out=reverb(out,2.2,0.3)
    # loop sem emenda: cauda volta para o começo
    tail=out[L:L+SR*3].copy(); out=out[:L]; out[:len(tail)]+=tail
    save_ogg(out,path,3)
    return L/SR

def amb_passaros(path,dur=24.0):
    n=int(SR*dur); out=np.zeros(n+SR*2)
    wind=lp(rng.standard_normal(len(out)),500)*0.012
    out+=wind*(0.7+0.3*np.sin(2*np.pi*np.arange(len(out))/SR/7))
    t=0.3
    while t<dur:
        kind=rng.integers(0,3); f0=rng.uniform(2600,4200)
        k=rng.integers(2,6)
        for j in range(k):
            d=rng.uniform(0.05,0.12); m=int(SR*d); tt=np.arange(m)/SR
            if kind==0: f=f0+1200*np.sin(np.pi*tt/d)                # assobio em arco
            elif kind==1: f=f0*(1+0.35*tt/d)                          # subida
            else: f=f0+500*np.sin(2*np.pi*28*tt)                      # trinado
            ph=2*np.pi*np.cumsum(f)/SR
            s=np.sin(ph)*np.sin(np.pi*tt/d)**2*rng.uniform(0.15,0.35)
            i=int((t+j*d*1.4)*SR); out[i:i+m]+=s
        t+=rng.uniform(0.7,2.6)
    out=reverb(out,1.2,0.25)
    tail=out[n:].copy(); out=out[:n]; out[:len(tail)]+=tail
    save_ogg(out*0.6,path,2)

def amb_rio(path,dur=14.0):
    n=int(SR*dur)+SR
    x=rng.standard_normal(n)
    s=bp(x,300,2200)*0.5+lp(x,250)*0.6
    mod=0.75+0.25*np.sin(2*np.pi*np.arange(n)/SR/3.1)*np.sin(2*np.pi*np.arange(n)/SR/1.7)
    s*=mod
    # borbulhas
    for _ in range(int(dur*6)):
        d=rng.uniform(0.02,0.05); m=int(SR*d); tt=np.arange(m)/SR
        f=rng.uniform(500,1400)*(1+2*tt/d)
        b=np.sin(2*np.pi*np.cumsum(f)/SR)*np.exp(-tt/d*3)*0.25
        i=rng.integers(0,n-m); s[i:i+m]+=b
    N=int(SR*dur); fade=SR
    out=s[:N].copy(); w=np.linspace(0,1,fade)
    out[:fade]=out[:fade]*w+s[N:N+fade]*(1-w)
    save_ogg(out,path,2)

def planar(path):
    d=0.55; n=int(SR*d); t=np.arange(n)/SR
    x=rng.standard_normal(n); y=np.zeros(n)
    for i,(a,b) in enumerate([(0,0.5),(0.5,1)]):
        pass
    fc=600+2400*np.sin(np.pi*t/d)
    # filtro variável aproximado em blocos
    blk=256; out=np.zeros(n)
    for i in range(0,n,blk):
        f=fc[i]; seg=bp(x[max(0,i-512):i+blk],max(200,f*0.6),min(SR/2-100,f*1.4))[-min(blk,n-i):]
        out[i:i+len(seg)]=seg
    out*=np.sin(np.pi*t/d)**1.5
    # "fuuu" + nota alegre
    tone=np.sin(2*np.pi*note_hz(84)*t)*env(n,0.01,0.12)*0.15
    out=out+tone
    out=out/np.abs(out).max()*0.7
    sf.write(path,out.astype(np.float32),22050 if False else SR,subtype='PCM_16')

if __name__=='__main__':
    import os; A=os.path.join(os.path.dirname(os.path.abspath(__file__)),'..','audio')+'/'
    print('nuvens',bgm_nuvens(A+'bgm_nuvens.ogg'))
    amb_passaros(A+'amb_passaros.ogg'); amb_rio(A+'amb_rio.ogg'); planar(A+'planar.wav')
