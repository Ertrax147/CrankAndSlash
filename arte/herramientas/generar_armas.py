# Genera candidatos de dibujo para el arma que gira alrededor del jugador (cabeza del arma + cadena).
# Uso, desde la raiz del repositorio:  python arte/herramientas/generar_armas.py
# Necesita Pillow (pip install Pillow). Los dibujos miran hacia ARRIBA; el juego los gira.
import math
from PIL import Image, ImageDraw, ImageFilter
B=(0,0,0,255); Wh=(255,255,255,255); T=(0,0,0,0)

def halo(img, r=1):
    a = img.split()[3]; big = a.filter(ImageFilter.MaxFilter(2*r+1))
    out = Image.new('RGBA', img.size, T); out.paste(Wh, mask=big); out.alpha_composite(img); return out
def pad(img, p=1):
    o = Image.new('RGBA',(img.width+2*p,img.height+2*p),T); o.alpha_composite(img,(p,p)); return o

def maza():            # bola con pinchos (morning star)
    s=Image.new('RGBA',(19,19),T); d=ImageDraw.Draw(s)
    cx=cy=9
    for dx,dy,l in [(1,0,4),(-1,0,4),(0,1,4),(0,-1,4),(1,1,3),(1,-1,3),(-1,1,3),(-1,-1,3)]:
        d.line([(cx+dx*3,cy+dy*3),(cx+dx*(3+l-1),cy+dy*(3+l-1))],fill=B)
    d.ellipse((cx-5,cy-5,cx+5,cy+5),fill=B)
    for p in [(6,6),(7,6),(6,7)]: s.putpixel(p,Wh)
    return s
def hacha():           # hacha de doble filo
    s=Image.new('RGBA',(20,18),T); d=ImageDraw.Draw(s)
    d.polygon([(9,3),(0,0),(1,9),(0,17),(9,14)],fill=B)
    d.polygon([(10,3),(19,0),(18,9),(19,17),(10,14)],fill=B)
    d.rectangle((8,1,11,16),fill=B)
    for y in range(4,14,2): s.putpixel((3,y),Wh); s.putpixel((16,y),Wh)   # filo
    s.putpixel((9,5),Wh); s.putpixel((10,5),Wh)
    return s
def martillo():        # martillo
    s=Image.new('RGBA',(18,18),T); d=ImageDraw.Draw(s)
    d.rectangle((1,1,16,9),fill=B)
    d.rectangle((2,2,15,8),fill=Wh)
    d.rectangle((1,5,16,5),fill=B); d.line([(1,5),(16,5)],fill=B)
    for x in range(3,15,2): s.putpixel((x,3),B)
    d.rectangle((7,9,10,17),fill=B)
    return s
def espada():          # espada corta
    s=Image.new('RGBA',(11,24),T); d=ImageDraw.Draw(s)
    d.polygon([(5,0),(9,5),(9,15),(1,15),(1,5)],fill=B)
    d.polygon([(5,2),(8,6),(8,14),(2,14),(2,6)],fill=Wh)
    d.line([(5,3),(5,14)],fill=B)
    d.rectangle((0,15,10,17),fill=B)
    d.rectangle((4,18,6,21),fill=B)
    d.ellipse((3,21,7,23),fill=B)
    return s

def chain(d, x0, y0, x1, y1):
    dist = math.hypot(x1-x0, y1-y0); n = int(dist//4)
    for i in range(1, n):
        t = i/n; x = x0+(x1-x0)*t; y = y0+(y1-y0)*t
        if i % 2: d.rectangle((x-2,y-1,x+1,y),fill=B)
        else:     d.rectangle((x-1,y-2,x,y+1),fill=B)

designs=[("maza",maza),("hacha",hacha),("martillo",martillo),("espada",espada)]
grass = Image.open('source/images/map/grass_tile.png').convert('RGBA').resize((32,32),Image.NEAREST)
cols=len(designs); W=cols*90; H=130
bg=Image.new('RGBA',(W,H),Wh)
for x in range(0,W,32):
    for y in range(0,H,32): bg.alpha_composite(grass,(x,y))
dd=ImageDraw.Draw(bg)
for i,(n,fn) in enumerate(designs):
    sp = halo(pad(fn(),1),1); sp.save(f"arte/armas/{n}.png")
    for row,angle in enumerate((0,50)):
        px,py = 20+i*90, 30+row*62        # jugador
        wx = px + 32*math.cos(math.radians(angle)); wy = py + 32*math.sin(math.radians(angle))
        chain(dd, px, py, wx, wy)
        rot = sp.rotate(-(angle+90), expand=True, resample=Image.NEAREST) if n!="maza" else sp
        if n in ("martillo","hacha"): rot = sp.rotate(-(angle+90), expand=True, resample=Image.NEAREST)
        bg.alpha_composite(rot,(int(wx-rot.width/2),int(wy-rot.height/2)))
        dd.ellipse((px-8,py-8,px+8,py+8),fill=B)
    dd.rectangle((i*90+8,2,i*90+18,13),fill=Wh,outline=B); dd.text((i*90+11,1),str(i+1),fill=B)
bg.convert('RGB').resize((W*4,H*4),Image.NEAREST).save("arte/armas/vista_previa.png")
print([(n,halo(pad(fn(),1),1).size) for n,fn in designs])
