import numpy as np, json
from PIL import Image
from scipy import ndimage
cuts=json.load(open('cuts.json'))
def src(k): return ('../repo/sprites/player/' if k.startswith('zeca') else '../repo/sprites/faisca/')+k+'.png'
def hatmask(k):
    o=np.asarray(Image.open(src(k)).convert('RGBA')).astype(np.float32)
    n=np.asarray(Image.open('out/%s.png'%k).convert('RGBA')).astype(np.float32)
    H,W=o.shape[:2]
    oa=o[...,3]/255; na=n[...,3]/255
    d=np.abs(o[...,:3]*oa[...,None]-n[...,:3]*na[...,None]).mean(-1)+np.abs(oa-na)*255
    rgb=o[...,:3]/255; mx=rgb.max(-1)
    m=(d>45)&(oa>0.3)&(np.arange(H)[:,None]<cuts[k])&(mx>0.30)   # não-escuro (palha/fita), diferente
    m=ndimage.binary_opening(m,iterations=2)
    lab,nn=ndimage.label(m)
    if nn==0: return None
    sz=ndimage.sum(m,lab,range(1,nn+1)); keep=[i+1 for i,s in enumerate(sz) if s>=0.25*sz.max()]
    m=np.isin(lab,keep)
    m=ndimage.binary_fill_holes(ndimage.binary_closing(m,iterations=4))
    # contorno escuro do chapéu: inclui pixels a até 4 px
    m2=ndimage.binary_dilation(m,iterations=4)&(oa>0.05)&(np.arange(H)[:,None]<cuts[k])
    return m2
if __name__=='__main__':
    import sys
    for k in sys.argv[1:]:
        m=hatmask(k); o=Image.open(src(k)).convert('RGBA')
        a=np.asarray(o).copy(); a[~m,3]=0
        bg=Image.new('RGBA',o.size,(120,170,230,255)); bg.alpha_composite(Image.fromarray(a))
        bg.save('mask_%s.png'%k)
