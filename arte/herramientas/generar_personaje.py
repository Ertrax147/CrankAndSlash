# Genera los dibujos del personaje (3 disenos, 2 cuadros de caminata cada uno).
# Uso, desde la raiz del repositorio:  python arte/herramientas/generar_personaje.py
# Necesita Pillow (pip install Pillow). Guarda todos en arte/personaje/ y copia el elegido
# (el guerrero) a source/images/player/ como personaje_1.png y personaje_2.png.
import os
import shutil
from PIL import Image, ImageDraw, ImageFilter, ImageOps
B=(0,0,0,255); Wh=(255,255,255,255); T=(0,0,0,0)
W,H=19,23
def halo(img):
    a=img.split()[3]; big=a.filter(ImageFilter.MaxFilter(3))
    out=Image.new('RGBA',img.size,T); out.paste(Wh,mask=big); out.alpha_composite(img); return out
def pad(img):
    o=Image.new('RGBA',(img.width+2,img.height+2),T); o.alpha_composite(img,(1,1)); return o
def blob(d,prims):
    for k,b in prims: (d.ellipse if k=='e' else d.rectangle)(b,fill=B)
    for k,(x0,y0,x1,y1) in prims: (d.ellipse if k=='e' else d.rectangle)((x0+1,y0+1,x1-1,y1-1),fill=Wh)
def dither(s,box):
    x0,y0,x1,y1=box
    for x in range(x0,x1+1):
        for y in range(y0,y1+1):
            if s.getpixel((x,y))==Wh and (x+y)%2==0: s.putpixel((x,y),B)
def legs(d,f,y):
    # piernas: en un cuadro la izquierda adelante, en el otro la derecha
    if f==0: d.rectangle((5,y,7,y+3),fill=B); d.rectangle((10,y,12,y+2),fill=B)
    else:    d.rectangle((5,y,7,y+2),fill=B); d.rectangle((10,y,12,y+3),fill=B)

def head(d,s,b,hair=True):
    blob(d,[('e',(3,4+b,14,13+b))])
def goggles(d,b):
    # lentes gruesos: dos cuadros negros con un brillo blanco
    d.rectangle((4,7+b,7,9+b),fill=B); d.rectangle((10,7+b,13,9+b),fill=B); d.line([(8,8+b),(9,8+b)],fill=B)
    d.point((5,7+b),fill=Wh); d.point((11,7+b),fill=Wh)
def spikes(d,b):
    for x,h in ((4,3),(6,5),(8,3),(10,5),(12,3)):
        d.polygon([(x-1,5+b),(x,4+b-h),(x+1,5+b)],fill=B)
def sci_armor(f):
    s=Image.new('RGBA',(W,H),T); d=ImageDraw.Draw(s); b=f
    legs(d,f,18)
    d.line([(14,14+b),(17,14+b)],fill=B); d.line([(17,14+b),(17,11+b)],fill=B); d.rectangle((16,10+b,18,11+b),fill=B)  # manivela
    blob(d,[('r',(3,13+b,14,19))])                      # peto
    d.rectangle((1,13+b,3,15+b),fill=B); d.rectangle((14,13+b,15,15+b),fill=B)  # hombreras
    dither(s,(9,14+b,13,18))
    spikes(d,b); head(d,s,b); goggles(d,b)
    d.line([(7,11+b),(10,11+b)],fill=B)
    return s
def sci_simple(f):
    s=Image.new('RGBA',(W,H),T); d=ImageDraw.Draw(s); b=f
    legs(d,f,18)
    blob(d,[('r',(3,13+b,14,19))])                      # bata
    d.line([(8,14+b),(8,18)],fill=B); d.point((5,16+b),fill=B); d.point((11,16+b),fill=B)
    d.rectangle((1,14+b,2,17+b),fill=B); d.rectangle((15,14+b,16,17+b),fill=B)
    spikes(d,b); head(d,s,b); goggles(d,b)
    d.line([(7,11+b),(10,11+b)],fill=B)
    return s
def warrior(f):
    s=Image.new('RGBA',(W,H),T); d=ImageDraw.Draw(s); b=f
    legs(d,f,18)
    d.line([(14,13+b),(17,8+b)],fill=B); d.line([(15,13+b),(18,8+b)],fill=B)  # espada a la espalda
    blob(d,[('r',(4,13+b,13,19))])
    dither(s,(9,14+b,12,18)); d.line([(4,16+b),(13,16+b)],fill=B)
    d.rectangle((2,14+b,3,17+b),fill=B); d.rectangle((14,14+b,15,17+b),fill=B)
    blob(d,[('e',(3,3+b,14,13+b))])                      # casco
    d.rectangle((4,7+b,13,9+b),fill=B); d.point((6,8+b),fill=Wh); d.point((11,8+b),fill=Wh)  # visor
    d.rectangle((8,0+b,9,4+b),fill=B)                    # cresta
    dither(s,(11,4+b,13,6+b)); dither(s,(11,10+b,13,12+b))
    return s

# ---------- cientifico con caja-generador (sin manivela: la manivela y los rayos los dibuja el codigo en player.lua)
SW, SH = 26, 29
def scientist(f):
    s = Image.new('RGBA', (SW, SH), T); d = ImageDraw.Draw(s); b = f
    # piernas (se alternan entre cuadros)
    if f == 0: d.rectangle((4,25,7,28), fill=B); d.rectangle((10,25,13,27), fill=B)
    else:      d.rectangle((4,25,7,27), fill=B); d.rectangle((10,25,13,28), fill=B)
    # antena con bola sobre la caja
    d.line([(20,11+b),(20,5+b)], fill=B); d.line([(21,11+b),(21,5+b)], fill=B)
    d.ellipse((18,0+b,23,5+b), fill=B); d.point((19,2+b), fill=Wh); d.point((20,1+b), fill=Wh)
    # caja-generador con un rayo dibujado
    blob(d, [('r',(16,11+b,24,24+b))])
    d.line([(21,13+b),(19,17+b)], fill=B); d.line([(19,17+b),(22,17+b)], fill=B); d.line([(22,17+b),(19,22+b)], fill=B)
    # cuerpo (bata)
    blob(d, [('r',(3,17+b,15,25))])
    d.line([(9,18+b),(9,24)], fill=B); d.point((6,21+b), fill=B); d.point((12,21+b), fill=B)
    d.rectangle((1,18+b,2,22+b), fill=B)
    # pelo parado y cabeza grande
    for x, hh in ((4,4),(7,6),(10,4),(13,6)):
        d.polygon([(x-2,6+b),(x-1,5+b-hh+1),(x+1,6+b)], fill=B)
    blob(d, [('e',(2,5+b,16,18+b))])
    # lentes gruesos con brillo y sonrisa
    d.rectangle((3,10+b,8,13+b), fill=B); d.rectangle((10,10+b,15,13+b), fill=B); d.rectangle((8,11+b,10,11+b), fill=B)
    for x in (4,5,11,12): d.point((x,10+b), fill=Wh)
    d.line([(6,15+b),(12,15+b)], fill=B); d.point((5,14+b), fill=B); d.point((13,14+b), fill=B)
    # se dibuja con la caja a la derecha y se refleja: el personaje mira a la derecha y la caja
    # queda a su espalda (a la izquierda). Al ir a la izquierda el juego lo voltea.
    return ImageOps.mirror(s)

ELEGIDO = '4_cientifico'
DESIGNS = [('1_cientifico_armadura', sci_armor), ('2_cientifico_simple', sci_simple), ('3_guerrero', warrior),
           ('4_cientifico', scientist)]
os.makedirs('arte/personaje', exist_ok=True)
os.makedirs('source/images/player', exist_ok=True)
for name, fn in DESIGNS:
    for f in (0, 1):
        path = f'arte/personaje/{name}_{f + 1}.png'
        halo(pad(fn(f))).save(path)
        if name == ELEGIDO:
            shutil.copy(path, f'source/images/player/personaje_{f + 1}.png')
