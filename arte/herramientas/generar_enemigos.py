# Genera los dibujos de los enemigos (fantasma, murcielago, oso, golem, arana) con 2 cuadros cada uno.
# Uso, desde la raiz del repositorio:  python arte/herramientas/generar_enemigos.py
# Necesita Pillow (pip install Pillow). Los elegidos se copian a source/images/ con prefijo enemy_.
from PIL import Image, ImageDraw, ImageFilter
SCR = "arte/enemigos/"  # aqui se guarda la vista previa
B=(0,0,0,255); Wh=(255,255,255,255); T=(0,0,0,0)
def halo(img, r=1):
    a = img.split()[3]; big = a.filter(ImageFilter.MaxFilter(2*r+1))
    out = Image.new('RGBA', img.size, T); out.paste(Wh, mask=big); out.alpha_composite(img); return out
def pad(img, p=1):
    o = Image.new('RGBA',(img.width+2*p,img.height+2*p),T); o.alpha_composite(img,(p,p)); return o
def blob(d, prims):
    for kind,box in prims: (d.ellipse if kind=='e' else d.rectangle)(box, fill=B)
    for kind,(x0,y0,x1,y1) in prims: (d.ellipse if kind=='e' else d.rectangle)((x0+1,y0+1,x1-1,y1-1), fill=Wh)
def shade(img, fn):
    for x in range(img.width):
        for y in range(img.height):
            if img.getpixel((x,y))==Wh and fn(x,y) and (x+y)%2==0: img.putpixel((x,y),B)
def shift(img, dx, dy):
    o=Image.new('RGBA',img.size,T); o.alpha_composite(img,(dx,dy)) if dx>=0 and dy>=0 else o.paste(img,(dx,dy)); return o

# ---------- fantasma (2 cuadros: sube y baja 1 px, y la orilla cambia)
def ghost(f):
    s=Image.new('RGBA',(17,20),T); d=ImageDraw.Draw(s)
    dy = 0 if f==0 else 1
    bumps = [('e',(1,13+dy,5,18+dy)),('e',(6,13+dy,10,18+dy)),('e',(11,13+dy,15,18+dy))] if f==0 else \
            [('e',(1,14,5,19)),('e',(6,13,10,18)),('e',(11,14,15,19))]
    blob(d,[('e',(1,dy,15,13+dy)),('r',(1,7+dy,15,16+dy))]+bumps)
    d.rectangle((4,6+dy,5,8+dy),fill=B); d.rectangle((10,6+dy,11,8+dy),fill=B)
    d.rectangle((7,10+dy,8,12+dy),fill=B)
    shade(s, lambda x,y: x>=10 and y>=9+dy)
    return s
# ---------- murcielago (2 cuadros: alas arriba / abajo)
def bat(f):
    s=Image.new('RGBA',(20,14),T); d=ImageDraw.Draw(s)
    if f==0:   # alas arriba
        d.polygon([(9,6),(0,0),(1,6),(3,4),(4,8),(6,6),(9,9)],fill=B)
        d.polygon([(10,6),(19,0),(18,6),(16,4),(15,8),(13,6),(10,9)],fill=B)
    else:      # alas abajo
        d.polygon([(9,5),(0,8),(2,13),(4,10),(5,13),(7,10),(9,9)],fill=B)
        d.polygon([(10,5),(19,8),(17,13),(15,10),(14,13),(12,10),(10,9)],fill=B)
    d.ellipse((7,3,12,11),fill=B)
    d.polygon([(7,4),(7,0),(9,3)],fill=B); d.polygon([(12,4),(12,0),(10,3)],fill=B)
    s.putpixel((8,6),Wh); s.putpixel((11,6),Wh)
    return s
# ---------- oso (2 cuadros: rebota 1 px)
def bear(f):
    s=Image.new('RGBA',(24,24),T); d=ImageDraw.Draw(s)
    dy = 0 if f==0 else 1
    blob(d,[('e',(3,0+dy,8,5+dy)),('e',(15,0+dy,20,5+dy)),('e',(2,2+dy,21,13+dy)),('e',(4,11,19,22)),
            ('e',(0,12-dy,5,20-dy)),('e',(18,12-dy,23,20-dy))])
    d.rectangle((7,6+dy,8,7+dy),fill=B); d.rectangle((15,6+dy,16,7+dy),fill=B)       # ojos
    d.ellipse((8,8+dy,15,12+dy),fill=Wh,outline=B)                                   # hocico
    d.rectangle((11,9+dy,12,9+dy),fill=B)                                            # nariz
    d.line([(11,10+dy),(11,11+dy)],fill=B)
    d.ellipse((8,14,15,20),outline=B)                                                # panza
    for x in (1,3): d.point((x,19-dy),fill=B)
    for x in (20,22): d.point((x,19-dy),fill=B)                                      # garras
    shade(s, lambda x,y: x>=15 and y>=13)
    return s
# ---------- golem (2 cuadros: brazos suben / bajan)
def golem(f):
    s=Image.new('RGBA',(24,22),T); d=ImageDraw.Draw(s)
    a = 0 if f==0 else 2
    blob(d,[('r',(6,7,17,17)),('r',(8,1,15,8)),('r',(0,6+a,5,14+a)),('r',(18,6+a,23,14+a)),('r',(6,16,10,21)),('r',(13,16,17,21))])
    d.rectangle((9,3,10,4),fill=B); d.rectangle((13,3,14,4),fill=B)                  # ojos
    d.line([(10,6),(13,6)],fill=B)
    d.line([(10,10),(12,13)],fill=B); d.line([(12,13),(11,15)],fill=B)               # grieta
    d.point((15,9),fill=B); d.point((8,14),fill=B)
    shade(s, lambda x,y: x>=12 and 8<=y<=19)
    return s
# ---------- arana (2 cuadros: las patas cambian de posicion)
def spider(f):
    s=Image.new('RGBA',(22,17),T); d=ImageDraw.Draw(s)
    k = 0 if f==0 else 1
    legs=[[(8,6),(4,2+k),(1,5)],[(8,7),(3,6-k),(0,9)],[(8,9),(3,11+k),(1,14)],[(9,10),(6,14-k),(4,16)]]
    for leg in legs:
        d.line(leg,fill=B); d.line([(21-x,y) for x,y in leg],fill=B)
    d.ellipse((6,6,15,14),fill=B)                    # abdomen
    d.ellipse((8,3,13,8),fill=B)                     # cabeza
    for p in [(9,5),(12,5)]: s.putpixel(p,Wh)        # ojos
    s.putpixel((10,10),Wh); s.putpixel((11,10),Wh); s.putpixel((10,11),Wh); s.putpixel((11,11),Wh)  # marca blanca
    return s

# ---------- jefe: el murcielago agrandado al doble, con colmillos (2 cuadros: alas arriba / abajo)
def boss(f):
    small = bat(f)
    big = small.resize((small.width*2, small.height*2), Image.NEAREST)
    d = ImageDraw.Draw(big)
    for x in (17, 21):                       # colmillos blancos bajo los ojos
        d.rectangle((x, 17, x+1, 20), fill=Wh)
    for x in (16, 22):                       # ojos mas grandes
        d.rectangle((x, 11, x+1, 13), fill=Wh)
    return big

designs=[("fantasma",ghost),("murcielago",bat),("oso",bear),("golem",golem),("arana",spider),("jefe",boss)]
rows=[]
for n,fn in designs:
    for f in (0,1):
        sp=halo(pad(fn(f),1),1); sp.save(f"arte/enemigos/{n}_{f+1}.png"); rows.append((n,f,sp))
grass = Image.open('source/images/grass_tile.png').convert('RGBA').resize((32,32),Image.NEAREST)
W=len(designs)*58+16; H=44
bg=Image.new('RGBA',(W,H),Wh)
for x in range(0,W,32):
    for y in range(0,H,32): bg.alpha_composite(grass,(x,y))
dd=ImageDraw.Draw(bg)
for i,(n,fn) in enumerate(designs):
    x0=8+i*58
    for f in (0,1):
        sp=rows[i*2+f][2]
        bg.alpha_composite(sp,(x0+f*27+(26-sp.width)//2, 8))
    dd.text((x0+22,34),str(i+1),fill=B)
bg.convert('RGB').resize((W*5,H*5),Image.NEAREST).save(SCR+"enemies2_preview.png")
print([(n,f,sp.size) for n,f,sp in rows][::2])
