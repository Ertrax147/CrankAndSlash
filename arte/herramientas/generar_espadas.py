# Genera candidatos de espada para el arma que gira alrededor del jugador (la punta mira hacia ARRIBA;
# el juego la gira). Uso, desde la raiz del repositorio:  python arte/herramientas/generar_espadas.py
import math
from PIL import Image, ImageDraw, ImageFilter
B=(0,0,0,255); Wh=(255,255,255,255); T=(0,0,0,0)

def halo(img, r=1):
    a = img.split()[3]; big = a.filter(ImageFilter.MaxFilter(2*r+1))
    out = Image.new('RGBA', img.size, T); out.paste(Wh, mask=big); out.alpha_composite(img); return out
def pad(img, p=1):
    o = Image.new('RGBA',(img.width+2*p,img.height+2*p),T); o.alpha_composite(img,(p,p)); return o

def hilt(d, cx, y, guard_w, grip_len, pommel=True):
    """guarda (barra), empunadura y pomo, centrados en x=cx, empezando en y"""
    d.rectangle((cx-guard_w//2, y, cx+guard_w//2, y+1), fill=B)
    d.rectangle((cx, y+2, cx, y+1+grip_len), fill=B); d.rectangle((cx-1, y+2, cx+1, y+1+grip_len), fill=B)
    if pommel: d.ellipse((cx-2, y+grip_len, cx+2, y+grip_len+4), fill=B)

def estoque():          # fina y muy larga
    s=Image.new('RGBA',(11,42),T); d=ImageDraw.Draw(s)
    d.polygon([(5,0),(6,3),(6,29),(4,29),(4,3)], fill=B)
    for y in range(4,29): s.putpixel((5,y),Wh)
    d.line([(1,30),(9,30)],fill=B); d.line([(1,30),(2,33)],fill=B); d.line([(9,30),(8,33)],fill=B)   # guarda de copa
    d.rectangle((4,31,6,37),fill=B); d.ellipse((3,37,7,41),fill=B)
    return s
def larga():            # clasica, mas delgada que la primera
    s=Image.new('RGBA',(13,38),T); d=ImageDraw.Draw(s)
    d.polygon([(6,0),(9,4),(9,25),(3,25),(3,4)], fill=B)
    d.polygon([(6,2),(8,5),(8,24),(4,24),(4,5)], fill=Wh)
    d.line([(6,4),(6,23)],fill=B)
    d.rectangle((0,25,12,27),fill=B); d.point((0,28),fill=B); d.point((12,28),fill=B)
    d.rectangle((5,28,7,33),fill=B); d.ellipse((4,33,8,37),fill=B)
    return s
def katana():           # curvada, fina, con empunadura envuelta
    s=Image.new('RGBA',(11,42),T); d=ImageDraw.Draw(s)
    for y in range(0,29):
        xc = 4 + 3*(1-y/28)**2
        x0 = int(round(xc))
        d.line([(x0-1,y),(x0+1,y)],fill=B)
        if y>2: s.putpixel((x0,y),Wh)
    d.ellipse((1,29,8,32),fill=B)                                 # tsuba (guarda redonda)
    d.rectangle((3,33,5,40),fill=B)
    for y in range(34,40,2): s.putpixel((4,y),Wh)                 # empunadura envuelta
    return s
def cimitarra():        # curva fuerte, ancha en la punta
    s=Image.new('RGBA',(15,36),T); d=ImageDraw.Draw(s)
    left=[];right=[]
    for y in range(0,26):
        t=1-y/25
        xc = 5 + 5*t**1.8
        hw = 1 + 1.6*t if y>1 else 0.5
        left.append((xc-hw,y)); right.append((xc+hw,y))
    d.polygon(left+right[::-1], fill=B)
    for y in range(3,25): 
        t=1-y/25; xc=int(round(5+5*t**1.8)); s.putpixel((xc,y),Wh)
    d.rectangle((2,26,8,27),fill=B)
    d.rectangle((4,28,6,33),fill=B); d.ellipse((3,33,7,35),fill=B)
    return s
def mandoble():         # grande y ancha
    s=Image.new('RGBA',(15,46),T); d=ImageDraw.Draw(s)
    d.polygon([(7,0),(11,5),(11,33),(3,33),(3,5)], fill=B)
    d.polygon([(7,2),(10,6),(10,32),(4,32),(4,6)], fill=Wh)
    d.line([(7,5),(7,31)],fill=B)
    d.rectangle((0,33,14,35),fill=B); d.rectangle((0,36,1,37),fill=B); d.rectangle((13,36,14,37),fill=B)
    d.rectangle((6,36,8,42),fill=B); d.ellipse((5,42,9,45),fill=B)
    return s

designs=[("estoque",estoque),("larga",larga),("katana",katana),("cimitarra",cimitarra),("mandoble",mandoble)]
grass = Image.open('source/images/grass_tile.png').convert('RGBA').resize((32,32),Image.NEAREST)
cols=len(designs); W=cols*100; H=150
bg=Image.new('RGBA',(W,H),Wh)
for x in range(0,W,32):
    for y in range(0,H,32): bg.alpha_composite(grass,(x,y))
dd=ImageDraw.Draw(bg)
GAP=10   # distancia del jugador a la base de la espada
for i,(n,fn) in enumerate(designs):
    sp=halo(pad(fn(),1),1); sp.save(f"arte/armas/espada_{n}.png")
    for row,angle in enumerate((-35,40)):
        px,py = 38+i*100, 42+row*68
        L = sp.height
        cxs = px + (GAP+L/2)*math.cos(math.radians(angle)); cys = py + (GAP+L/2)*math.sin(math.radians(angle))
        rot = sp.rotate(-(angle+90), expand=True, resample=Image.NEAREST)
        bg.alpha_composite(rot,(int(cxs-rot.width/2),int(cys-rot.height/2)))
        dd.ellipse((px-8,py-8,px+8,py+8),fill=B)
    dd.rectangle((i*100+4,2,i*100+14,13),fill=Wh,outline=B); dd.text((i*100+7,1),str(i+1),fill=B)
bg.convert('RGB').resize((W*4,H*4),Image.NEAREST).save("arte/armas/vista_previa_espadas.png")
print([(n,halo(pad(fn(),1),1).size) for n,fn in designs])
