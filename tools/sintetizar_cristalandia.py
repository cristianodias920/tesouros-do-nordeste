# Músicas originais da Fase 2 (Cristalândia), sintetizadas no próprio projeto (sem material de terceiros).
# Uso: python3 tools/sintetizar_cristalandia.py
#  - bgm_cris_festa.ogg   : baião festivo (festejo de Sant'Ana): zabumba, triângulo, baixo e "sanfona" (palhetas sintetizadas)
#  - bgm_cris_cristais.ogg: mesma levada e mesma harmonia, mais leve e brilhante (celesta/notas cristalinas), para os veios de cristal
# As duas têm exatamente a mesma duração e andamento: tocam juntas desde o começo e a troca é só de volume,
# então ficam sempre no mesmo compasso.
import numpy as np, soundfile as sf, subprocess
from scipy.signal import butter, lfilter, fftconvolve
SR=32000
rng=np.random.default_rng(11)
def env(n,a=0.01,r=0.3):
    t=np.arange(n)/SR; return np.minimum(1,t/max(a,1e-4))*np.exp(-t/r)
def hz(m): return 440*2**((m-69)/12)
def lp(x,f): b,a=butter(2,f/(SR/2)); return lfilter(b,a,x)
def hp(x,f): b,a=butter(2,f/(SR/2),'high'); return lfilter(b,a,x)
def bp(x,f1,f2): b,a=butter(2,[f1/(SR/2),f2/(SR/2)],'band'); return lfilter(b,a,x)
def reverb(x,dec=1.6,mix=0.22,seed=3):
    r=np.random.default_rng(seed); n=int(SR*dec)
    ir=r.standard_normal(n)*np.exp(-np.arange(n)/SR*4.5/dec); ir=lp(ir,4500); ir/=np.abs(ir).sum()**0.5*8
    return x*(1-mix)+fftconvolve(x,ir)[:len(x)]*mix*3
def save_ogg(x,path,peak=0.85):
    x=x/(np.abs(x).max()+1e-9)*peak
    sf.write('/tmp/_c.wav',x.astype(np.float32),SR)
    subprocess.run(['ffmpeg','-y','-loglevel','error','-i','/tmp/_c.wav','-c:a','libvorbis','-q:a','4','-ac','1',path],check=True)

BPM=124; BEAT=60/BPM; BARS=32
L=int(SR*BEAT*4*BARS)
# Ré mixolídio (cara de baião): D  C  G  D | D  A  G  D ...
PROG=[(50,[62,66,69]),(48,[60,64,67]),(43,[62,67,71]),(50,[62,66,69]),
      (50,[62,66,69]),(45,[61,64,69]),(43,[62,67,71]),(45,[61,64,69])]
# melodia em Ré mixolídio, 8 compassos por frase (colcheias; None = segura, 0 = pausa)
FR=[
 [74,0,76,78, 79,0,78,76, 74,0,72,0, 74,None,None,0,   69,0,72,74, 76,0,74,72, 74,0,None,None, 0,0,0,0,
  74,0,76,78, 79,0,81,79, 78,0,76,0, 74,None,72,0,     71,0,72,74, 76,0,72,69, 74,None,None,None, 0,0,0,0],
 [81,0,79,0, 78,79,81,0, 79,0,78,76, 74,None,0,0,     72,0,74,76, 78,0,76,74, 76,None,None,None, 0,0,74,76,
  78,0,79,81, 83,0,81,79, 78,0,76,74, 72,None,0,0,     74,76,78,76, 74,0,72,69, 74,None,None,None, 0,0,0,0],
]
def tocar(festa=True):
    out=np.zeros(L+SR*3)
    def put(sig,t):
        i=int(t*SR)%L; n=len(sig)
        end=min(len(out),i+n); out[i:end]+=sig[:end-i]
    def zabumba(t,amp):
        n=int(SR*0.35); tt=np.arange(n)/SR
        f=95*np.exp(-tt*9)+52
        s=np.sin(2*np.pi*np.cumsum(f)/SR)*np.exp(-tt*9)+lp(rng.standard_normal(n),900)*np.exp(-tt*40)*0.4
        put(s*amp,t)
    def bacalhau(t,amp):
        n=int(SR*0.08); s=bp(rng.standard_normal(n),1500,5000)*env(n,0.001,0.02); put(s*amp,t)
    def triang(t,aberto,amp):
        n=int(SR*(0.5 if aberto else 0.08)); tt=np.arange(n)/SR
        s=sum(np.sin(2*np.pi*f*tt)*w for f,w in [(5200,1),(7900,0.6),(10300,0.4)])
        s+=hp(rng.standard_normal(n),7000)*0.3
        put(s*env(n,0.001,0.22 if aberto else 0.02)*amp,t)
    def baixo(m,t,dur,amp):
        n=int(SR*dur); tt=np.arange(n)/SR; f=hz(m)
        s=np.sin(2*np.pi*f*tt)+0.3*np.sin(4*np.pi*f*tt)
        put(lp(s,600)*env(n,0.005,dur*0.6)*amp,t)
    def sanfona(ms,t,dur,amp,bright=1.0):
        # palhetas: duas ondas "dente de serra" levemente desafinadas + trêmolo, filtradas
        n=int(SR*dur); tt=np.arange(n)/SR; s=np.zeros(n)
        for m in ms:
            for d in (-0.06,0.0,0.07):
                f=hz(m+d)
                ph=(f*tt)%1.0
                s+=(2*ph-1)*0.5+np.sign(np.sin(2*np.pi*f*tt))*0.25
        s=bp(s,220,2600*bright)/len(ms)
        trem=1+0.08*np.sin(2*np.pi*6.0*tt)
        a=np.minimum(1,tt/0.02)*np.clip((dur-tt)/0.05,0,1)
        put(s*trem*a*amp,t)
    def celesta(m,t,dur,amp):
        n=int(SR*dur); tt=np.arange(n)/SR; f=hz(m)
        s=np.sin(2*np.pi*f*tt)+0.45*np.sin(2*np.pi*f*4.0*tt)*np.exp(-tt*6)+0.2*np.sin(2*np.pi*f*2*tt)
        put(s*env(n,0.002,dur*0.5)*amp,t)
    def pad(ms,t,dur,amp):
        n=int(SR*dur); tt=np.arange(n)/SR; s=np.zeros(n)
        for m in ms:
            for d in (-0.08,0.08): s+=np.sin(2*np.pi*hz(m+d)*tt)
        a=np.minimum(1,tt/0.5)*np.clip((dur-tt)/0.5,0,1)
        put(lp(s,1600)*a*amp/len(ms),t)
    for bar in range(BARS):
        root,ch=PROG[bar%8]; t0=bar*BEAT*4
        for b in range(4):
            tb=t0+b*BEAT
            # zabumba do baião: 1 e o "e" do 2 (e 3), bacalhau no contratempo
            if b%2==0: zabumba(tb,0.9 if festa else 0.45)
            else: zabumba(tb+BEAT*0.5,0.7 if festa else 0.35)
            bacalhau(tb+BEAT*0.5,0.18 if festa else 0.08)
            for k in range(4):
                triang(tb+k*BEAT/4,k==2,(0.11 if k==2 else 0.06)*(1.0 if festa else 0.8))
        for bt,ln in [(0,1.4),(1.5,0.5),(2,1.4),(3.5,0.5)]:
            baixo(root-12 if root>45 else root,t0+bt*BEAT,BEAT*ln,0.7 if festa else 0.5)
        if festa:
            # "puxada" de sanfona nos contratempos (acordes curtos)
            for bt in (0.5,1.5,2.5,3.5):
                sanfona(ch,t0+bt*BEAT,BEAT*0.35,0.22)
        else:
            pad([m-12 for m in ch],t0,BEAT*4+0.4,0.28)
            # arpejo cristalino
            for k in range(8):
                m=[ch[0],ch[1],ch[2],ch[0]+12,ch[2]+12,ch[0]+12,ch[2],ch[1]][k]+12
                celesta(m,t0+k*BEAT/2,0.8,0.16 if k%2==0 else 0.11)
        # melodia: frase A (8 compassos), frase B (8 compassos), repete
        fr=FR[(bar//8)%2]
        if bar<2: continue   # 2 compassos de introdução só com a levada
        for k in range(8):
            i=(bar%8)*8+k
            m=fr[i]
            if m in (None,0): continue
            ln=1
            while i+ln<len(fr) and fr[i+ln] is None: ln+=1
            if festa:
                sanfona([m],t0+k*BEAT/2,BEAT/2*ln*0.95,0.42,1.3)
            else:
                celesta(m+12,t0+k*BEAT/2,BEAT/2*ln+0.5,0.24)
                celesta(m,t0+k*BEAT/2,BEAT/2*ln+0.3,0.1)
    out=reverb(out,1.4 if festa else 2.4,0.18 if festa else 0.32)
    tail=out[L:].copy(); out=out[:L]; out[:len(tail)]+=tail
    return out
if __name__=='__main__':
    save_ogg(tocar(True),'audio/bgm_cris_festa.ogg',0.72)
    save_ogg(tocar(False),'audio/bgm_cris_cristais.ogg',0.68)
    print('ok', L/SR,'s')
