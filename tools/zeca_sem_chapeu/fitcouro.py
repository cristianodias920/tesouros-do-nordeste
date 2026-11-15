import numpy as np, cv2, json
from PIL import Image
cuts=json.load(open('cuts.json'))
def load(p): return np.asarray(Image.open(p).convert('RGBA'))
ref=load('palha/zeca_idle.png'); cou=load('couro_idle_layer.png')
def feats(x,s):
    a=x[...,3].astype(np.float32)/255
    g=cv2.cvtColor(x[...,:3],cv2.COLOR_RGB2GRAY).astype(np.float32)/255*a
    return cv2.GaussianBlur(a,(0,0),s), cv2.GaussianBlur(g,(0,0),1.2)
def mom(a):
    ys,xs=np.nonzero(a>0.5); return xs.mean(),ys.mean(),len(xs)
res={}
for k in cuts:
    fr=load('palha/%s.png'%k); H,W=fr.shape[:2]
    # pad ref into frame-size canvas (same coords: top-left aligned)
    R=np.zeros((max(H,512),max(W,512),4),np.uint8); R[:512,:512]=ref
    C=np.zeros_like(R); C[:512,:512]=cou
    F=np.zeros_like(R); F[:H,:W]=fr
    fa,fg=feats(F,4); ra,rg=feats(R,4)
    fx,fy,fn=mom(F[...,3]/255.); rx,ry,rn=mom(R[...,3]/255.)
    s=np.sqrt(rn/fn)  # frame->idle scale
    M=np.array([[s,0,rx-s*fx],[0,s,ry-s*fy]],np.float32)
    ok=True
    try:
        _,M=cv2.findTransformECC(fa,ra,M,cv2.MOTION_AFFINE,(3,200,1e-5),None,5)
        _,M=cv2.findTransformECC(cv2.GaussianBlur(fa,(0,0),1.5),cv2.GaussianBlur(ra,(0,0),1.5),M,cv2.MOTION_AFFINE,(3,200,1e-6),None,3)
        cc,M2=cv2.findTransformECC(fg,rg,M.copy(),cv2.MOTION_AFFINE,(3,200,1e-6),None,3)
        M=M2
    except cv2.error as e:
        ok=False; print(k,'ecc fail',e)
    out=cv2.warpAffine(C,M,(R.shape[1],R.shape[0]),flags=cv2.INTER_LINEAR|cv2.WARP_INVERSE_MAP)[:H,:W]
    Image.fromarray(out).save('couro/%s.png'%k)
    # IoU check of warped straw vs frame straw
    wr=cv2.warpAffine(R,M,(R.shape[1],R.shape[0]),flags=cv2.INTER_LINEAR|cv2.WARP_INVERSE_MAP)[:H,:W]
    a1=wr[...,3]>128; a2=fr[...,3]>128
    iou=(a1&a2).sum()/max(1,(a1|a2).sum())
    # decompose idle->frame (inverse)
    Mi=cv2.invertAffineTransform(M)
    sc=np.sqrt(abs(np.linalg.det(Mi[:,:2]))); ang=np.degrees(np.arctan2(Mi[1,0],Mi[0,0]))
    res[k]=dict(M=Mi.tolist(),scale=float(sc),ang=float(ang),iou=float(iou))
    print(k,'iou=%.2f scale=%.3f ang=%.1f'%(iou,sc,ang), 'ok' if ok else '')
json.dump(res,open('couro_fit.json','w'),indent=1)
