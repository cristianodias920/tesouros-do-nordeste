import numpy as np, cv2, sys, json
from PIL import Image
from scipy import ndimage
def key(path):
    im=np.asarray(Image.open(path).convert('RGB')).astype(np.float32)
    c=np.concatenate([im[:20,:20].reshape(-1,3),im[:20,-20:].reshape(-1,3),im[-20:,:20].reshape(-1,3),im[-20:,-20:].reshape(-1,3)])
    B=np.median(c,0)
    d=np.sqrt(((im-B)**2).sum(-1))
    # magenta: g low, r,b high. use distance plus greenness
    a=np.clip((d-45)/(110-45),0,1)
    aa=np.maximum(a,1e-3)[...,None]
    C=np.clip((im-(1-a[...,None])*B)/aa,0,255)
    # keep largest components
    lab,n=ndimage.label(a>0.5); 
    if n>1:
        sz=ndimage.sum(a>0.5,lab,range(1,n+1)); keep=np.isin(lab,[i+1 for i,s in enumerate(sz) if s>1500])
        keep=ndimage.binary_dilation(keep,iterations=3); a=a*keep
    # despill magenta on edges: clamp r,b to not exceed g too much where alpha partial
    e=(a<0.95)&(a>0)
    m=np.minimum(C[...,0],C[...,2]); ex=np.maximum(m-C[...,1]-20,0)
    C[...,0]-=ex*e; C[...,2]-=ex*e
    return np.dstack([C,a*255]).astype(np.uint8)
def demag(x):
    x=x.copy(); c=x[...,:3].astype(np.float32)
    r,g,b=c[...,0],c[...,1],c[...,2]
    m=np.minimum(r,b)-g
    L=(r+g+b)/3
    hi=(m>8)&(L>150); lo=(m>8)&(L<=150)
    g=np.where(hi,np.minimum(r,b),g)
    r=np.where(lo,r-m,r); b=np.where(lo,b-m,b)
    L=(r+g+b)/3
    pk=(((r>g+12)&(np.abs(g-b)<18))|((r>g+6)&(b>g-4)))&(L>120)
    v=np.maximum(np.maximum(r,g),b)
    r=np.where(pk,v,r); g=np.where(pk,v*0.985,g); b=np.where(pk,v*0.96,b)
    x[...,:3]=np.dstack([r,g,b]).clip(0,255).astype(np.uint8)
    return x
def shirt_top(o):
    a=o[...,3]>100
    rgb=o[...,:3].astype(np.float32)/255
    mx=rgb.max(-1);mn=rgb.min(-1);d=mx-mn+1e-6
    r,g,b=rgb[...,0],rgb[...,1],rgb[...,2]
    h=np.where(mx==r,((g-b)/d)%6,np.where(mx==g,(b-r)/d+2,(r-g)/d+4))*60
    s=(mx-mn)/(mx+1e-6)
    teal=a&(h>150)&(h<200)&(s>0.35)&(mx>0.25)
    lab,n=ndimage.label(teal)
    sz=ndimage.sum(teal,lab,range(1,n+1))
    big=[i+1 for i,s_ in enumerate(sz) if s_>800]
    tops=[(ndimage.find_objects((lab==i).astype(int))[0][0].start,sz[i-1],i) for i in big]
    return sorted(tops)
def run(orig_path, gen_path, out_path, cut, feather=10, dbg=None, xr=None):
    o=np.asarray(Image.open(orig_path).convert('RGBA'))
    h,w=o.shape[:2]; S=max(w,h)+40; ox=(S-w)//2; oy=(S-h)//2
    g=key(gen_path)
    g=np.asarray(Image.fromarray(g).resize((S,S),Image.LANCZOS))[oy:oy+h,ox:ox+w].copy()
    # ECC on gray*alpha within band [cut-90, cut+70]
    def prep(x):
        gr=cv2.cvtColor(x[...,:3],cv2.COLOR_RGB2GRAY).astype(np.float32)/255*(x[...,3]/255.)
        return cv2.GaussianBlur(gr,(0,0),1.5)
    po,pg=prep(o),prep(g)
    mask=np.zeros((h,w),np.uint8); mask[max(0,cut-110):min(h,cut+60)]=255
    if xr: mask[:, :xr[0]]=0; mask[:, xr[1]:]=0
    M=np.eye(2,3,dtype=np.float32)
    try:
        _,M=cv2.findTransformECC(po,pg,M,cv2.MOTION_AFFINE,(cv2.TERM_CRITERIA_EPS|cv2.TERM_CRITERIA_COUNT,300,1e-6),mask,5)
    except cv2.error as ex: print('ecc fail',ex)
    g=demag(g)
    ga=cv2.warpAffine(g,M,(w,h),flags=cv2.INTER_LINEAR|cv2.WARP_INVERSE_MAP,borderMode=cv2.BORDER_CONSTANT,borderValue=(0,0,0,0))
    yy=np.arange(h)[:,None].astype(np.float32)
    t=np.clip((cut-yy)/feather,0,1)   # 1 above cut-feather -> generated
    t=np.broadcast_to(t,(h,w)).copy()
    if xr:
        xx=np.arange(w)[None,:]
        t*=((xx>=xr[0])&(xx<xr[1]))
    # premultiplied blend
    of=o.astype(np.float32); gf=ga.astype(np.float32)
    oa=of[...,3:]/255; gaa=gf[...,3:]/255
    T=t[...,None]
    A=gaa*T+oa*(1-T)
    Cp=gf[...,:3]*gaa*T+of[...,:3]*oa*(1-T)
    C=np.where(A>1e-3,Cp/np.maximum(A,1e-3),0)
    out=np.dstack([C,A*255]).clip(0,255).astype(np.uint8)
    Image.fromarray(out).save(out_path)
    print(out_path,'M',np.round(M,3).tolist())
    return out
if __name__=='__main__':
    run(sys.argv[1],sys.argv[2],sys.argv[3],int(sys.argv[4]))
