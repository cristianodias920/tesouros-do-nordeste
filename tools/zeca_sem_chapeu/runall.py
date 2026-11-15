import json
exec(open('align.py').read().split("if __name__")[0])
d=json.load(open('../gen_chapeu/semchapeu/chapeu_ancoras.json')); cuts=json.load(open('cuts.json'))
for k,v in d.items():
    src=('../repo/sprites/player/' if k.startswith('zeca') else '../repo/sprites/faisca/')+k+'.png'
    xr=None
    if not k.startswith('zeca'): xr=(max(0,v['x0']-75),v['x1']+22)
    if k=='coice_2': xr=(100,300)
    run(src,'gen_%s.jpg'%k,'out/%s.png'%k,cuts[k],xr=xr)
