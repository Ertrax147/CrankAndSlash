# Genera los tiles de suelo alternativos (16x16, 1-bit, fondo blanco) que se pueden elegir en la
# pantalla de pruebas. El pasto original (grass_tile.png) viene del tileset de chuckiecatt y no se toca.
# Uso, desde la raiz del repositorio:  python arte/herramientas/generar_suelos.py
# Necesita Pillow (pip install Pillow). Guarda source/images/map/floor_<nombre>.png
import os
from PIL import Image

B = (0, 0, 0, 255)
W = (255, 255, 255, 255)
SIZE = 16


def tile(points=(), hlines=(), vlines=()):
    """Tile blanco con puntos sueltos y lineas. hlines: (y, x0, x1). vlines: (x, y0, y1)."""
    img = Image.new('RGBA', (SIZE, SIZE), W)
    for (x, y) in points:
        img.putpixel((x % SIZE, y % SIZE), B)
    for (y, x0, x1) in hlines:
        for x in range(x0, x1 + 1):
            img.putpixel((x % SIZE, y % SIZE), B)
    for (x, y0, y1) in vlines:
        for y in range(y0, y1 + 1):
            img.putpixel((x % SIZE, y % SIZE), B)
    return img


FLOORS = {
    # casi blanco: solo unas pocas motas. Los enemigos resaltan mas y comprime mejor en una videollamada
    'clean': tile(points=[(3, 4), (12, 9), (7, 13), (14, 2)]),
    # un punto en diagonal, como la grilla del primer prototipo
    'dots': tile(points=[(4, 4), (12, 12)]),
    # piedritas sueltas (formas de L) y algunas motas
    'dirt': tile(points=[(2, 2), (3, 2), (2, 3), (10, 6), (11, 6), (11, 7), (5, 11), (6, 11), (13, 13),
                         (13, 12), (14, 13), (8, 0), (0, 9)]),
    # adoquines: dos filas de ladrillos desfasadas a la mitad
    'stone': tile(hlines=[(0, 0, 15), (8, 0, 15)], vlines=[(0, 1, 7), (8, 9, 15)]),
    # arena: rayitas horizontales y motas
    'sand': tile(points=[(2, 3), (3, 3), (4, 3), (10, 8), (11, 8), (12, 8), (13, 8), (5, 12), (6, 12),
                         (13, 2), (1, 9), (9, 14)]),
}

for name, img in FLOORS.items():
    img.save(f'source/images/map/floor_{name}.png')
print(f'{len(FLOORS)} suelos guardados en source/images/map/')
