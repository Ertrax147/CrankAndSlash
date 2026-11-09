# Genera los iconos de las mejoras del menu de nivel (24x24, 1-bit, negro sobre transparente).
# Uso, desde la raiz del repositorio:  python arte/herramientas/generar_iconos.py
# Necesita Pillow (pip install Pillow). Guarda cada icono en source/images/icons/<nombre>.png;
# el nombre es el que usa la mejora en source/data/upgrades.lua (campo ICON).
import os
from PIL import Image, ImageDraw

B = (0, 0, 0, 255)
W = (255, 255, 255, 255)
T = (0, 0, 0, 0)
SIZE = 24


def canvas():
    img = Image.new('RGBA', (SIZE, SIZE), T)
    return img, ImageDraw.Draw(img)


def heart():  # Vitalidad
    img, d = canvas()
    d.ellipse((2, 3, 12, 13), fill=B)
    d.ellipse((11, 3, 21, 13), fill=B)
    d.polygon([(2, 9), (21, 9), (12, 21)], fill=B)
    d.rectangle((5, 6, 7, 7), fill=W)  # brillo
    d.point((5, 8), fill=W)
    return img


def fist():  # Fuerza
    img, d = canvas()
    d.rectangle((5, 10, 20, 20), fill=B)          # palma
    for x in (5, 9, 13, 17):                       # cuatro dedos
        d.rectangle((x, 5, x + 3, 12), fill=B)
    for x in (8, 12, 16):                          # separacion entre dedos
        d.line([(x, 6), (x, 13)], fill=W)
    d.rectangle((1, 12, 6, 17), fill=B)            # pulgar
    d.line([(6, 13), (10, 13)], fill=W)
    d.rectangle((7, 20, 18, 22), fill=B)           # muneca
    return img


def speed():  # Rapidez: tres flechas hacia la derecha
    img, d = canvas()
    for x0 in (2, 8, 14):
        d.polygon([(x0, 5), (x0 + 5, 12), (x0, 19), (x0 + 3, 19), (x0 + 8, 12), (x0 + 3, 5)], fill=B)
    return img


def battery():  # Carga: bateria con un rayo
    img, d = canvas()
    d.rectangle((2, 6, 19, 18), fill=B)
    d.rectangle((4, 8, 17, 16), fill=W)
    d.rectangle((20, 10, 22, 14), fill=B)
    d.polygon([(11, 9), (7, 13), (10, 13), (8, 16), (14, 11), (11, 11), (13, 9)], fill=B)
    return img


def reach():  # Alcance: flecha de dos puntas
    img, d = canvas()
    d.line([(5, 12), (18, 12)], fill=B, width=3)
    d.polygon([(1, 12), (8, 6), (8, 18)], fill=B)
    d.polygon([(22, 12), (15, 6), (15, 18)], fill=B)
    return img


def magnet():  # Iman: herradura
    img, d = canvas()
    d.ellipse((3, 2, 20, 19), fill=B)
    d.ellipse((8, 7, 15, 19), fill=W)
    d.rectangle((3, 11, 7, 21), fill=B)
    d.rectangle((16, 11, 20, 21), fill=B)
    d.rectangle((8, 12, 15, 21), fill=T)
    d.rectangle((3, 17, 7, 18), fill=W)            # los polos
    d.rectangle((16, 17, 20, 18), fill=W)
    return img


def pistol():  # Pistola
    img, d = canvas()
    d.rectangle((2, 5, 22, 11), fill=B)            # corredera
    d.rectangle((19, 3, 21, 5), fill=B)            # mira de adelante
    d.rectangle((6, 7, 11, 8), fill=W)             # ventana de expulsion
    d.polygon([(4, 11), (11, 11), (10, 22), (5, 22)], fill=B)   # empuñadura
    d.rectangle((11, 11, 17, 16), fill=B)          # guardamonte
    d.rectangle((12, 11, 16, 14), fill=W)
    d.rectangle((13, 11, 14, 14), fill=B)          # gatillo
    d.line([(6, 15), (9, 15)], fill=W)             # textura de la empuñadura
    d.line([(6, 18), (9, 18)], fill=W)
    return img


def whip():  # Latigo
    img, d = canvas()
    d.line([(3, 21), (8, 15)], fill=B, width=6)    # mango
    d.point((4, 19), fill=W)
    d.point((6, 17), fill=W)
    # el cuerpo del latigo: una curva en S que termina en una punta
    d.line([(8, 14), (9, 9), (13, 5), (18, 5), (21, 9), (19, 13), (15, 15)], fill=B, width=3)
    d.polygon([(13, 14), (17, 14), (15, 19)], fill=B)
    return img


def bolt():  # Rayo
    img, d = canvas()
    d.polygon([(15, 1), (4, 13), (11, 13), (7, 23), (20, 9), (13, 9), (18, 1)], fill=B)
    d.line([(14, 4), (9, 11)], fill=W)
    return img


def crosshair():  # Punteria
    img, d = canvas()
    d.ellipse((4, 4, 19, 19), outline=B, width=2)
    for box in ((11, 0, 12, 8), (11, 15, 12, 23), (0, 11, 8, 12), (15, 11, 23, 12)):
        d.rectangle(box, fill=B)
    d.rectangle((10, 10, 13, 13), fill=B)
    return img


ICONS = {
    'vitalidad': heart, 'fuerza': fist, 'rapidez': speed, 'carga': battery, 'alcance': reach,
    'iman': magnet, 'pistola': pistol, 'latigo': whip, 'rayo': bolt, 'punteria': crosshair,
}

os.makedirs('source/images/icons', exist_ok=True)
for name, make in ICONS.items():
    make().save(f'source/images/icons/{name}.png')
print(f'{len(ICONS)} iconos guardados en source/images/icons/')
