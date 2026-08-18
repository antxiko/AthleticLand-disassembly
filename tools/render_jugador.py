#!/usr/bin/env python3
"""Saca los fotogramas del protagonista de la VRAM volcada, tal cual los dibuja
el juego, y los deja en una tira PNG lista para animar en la web.

    python3 tools/render_jugador.py work/omsx/demo.vram.bin docs/imagenes/jugador.png

EL MUNECO SON TRES SPRITES, no uno. 0x9D03 lo monta asi: el sprite principal
lleva el patron P y va abajo; encima, DESPLAZADOS 16 PIXELES HACIA ARRIBA, van
otros dos con los patrones (P-0x20)+0x68 y (P-0x20)+0xB0. O sea que Harry mide
16x32: dos sprites solapados en la mitad de arriba y uno en la de abajo, que es
como se sacan varios colores de los sprites de un solo color del MSX1.

Los colores salen de donde los pone monta_la_escena: 0x9F53 escribe 0x0C en
0xE2A5, 0x9F5B escribe 0x06 en 0xE2A9 y 0x9F60 escribe 0x0F en 0xE2AD, que son
los bytes de atributo de las tres entradas de sprite (0xE2A2, 0xE2A6, 0xE2AA).

Los patrones de cada fotograma NO se eligen aqui: son los que dicen los guiones
de animacion del cartucho, que estan declarados en el .notes.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from monta_mapa import escribe_png                                   # noqa: E402

# Paleta del TMS9918, tal como la usa el MSX1.
PALETA = [
    (0, 0, 0), (0, 0, 0), (33, 200, 66), (94, 220, 120),
    (84, 85, 237), (125, 118, 252), (212, 82, 77), (66, 235, 245),
    (252, 85, 84), (255, 121, 120), (212, 193, 84), (230, 206, 128),
    (33, 176, 59), (201, 91, 186), (204, 204, 204), (255, 255, 255),
]

# Las tres capas: (desplazamiento del patron respecto al principal, color, dy).
#
# EL ORDEN IMPORTA, y es al reves de lo que parece: en el TMS9918 el sprite de
# numero MAS BAJO se pinta DELANTE. Los tres del jugador son entradas
# consecutivas -0xE2A2, 0xE2A6 y 0xE2AA, que el volcado de 0x8103 manda a la
# VRAM como los sprites 14, 15 y 16-, asi que el de 0xE2A6 (el patron +0x68,
# color 0x06) va por delante del de 0xE2AA (+0xB0, color 0x0F). Aqui se pinta
# de atras hacia delante, o sea 0x0F primero.
#
# Y no es un detalle teorico: las dos capas de arriba se solapan en los dos
# fotogramas de trepar, cinco pixeles cada uno, medido sobre esta misma VRAM.
# Con el orden al reves, esos cinco pixeles salen blancos en vez de rojos.
CAPAS = [(0xB0, 0x0F, 0), (0x68, 0x06, 0), (0x00, 0x0C, 16)]

# Los fotogramas, sacados de los guiones de animacion del propio cartucho:
#   0x8AE1 guion_anda_derecha   03 20 / 03 24 / 03 28 / 03 2C / 03 30
#   0x8AED guion_anda_izquierda los mismos tiempos con 0x44..0x54
#   0x8AF9 guion_trepa          01 3C / 01 60
# El de colgado de la liana no sale de un guion: 0xAE67 y 0xAE73 clavan el
# patron 0x3C en los dos sprites de la cuerda y el jugador se queda con el suyo.
FOTOGRAMAS = [
    ("anda_derecha", [0x20, 0x24, 0x28, 0x2C, 0x30], 3),
    ("anda_izquierda", [0x44, 0x48, 0x4C, 0x50, 0x54], 3),
    ("trepa", [0x3C, 0x60], 1),
]


def patron(vram, n, base=0x3800):
    """Los 32 bytes de un patron de sprite de 16x16: 16 de la izquierda y 16 de
    la derecha. El numero de patron se multiplica por 8, no por 32, porque la
    tabla se indexa en bloques de 8 bytes aunque el sprite ocupe cuatro."""
    o = base + n * 8
    return vram[o:o + 32]


def pinta(vram, lienzo, ancho, x0, principal):
    """Deja un fotograma entero -las tres capas- en el lienzo."""
    for desp, color, dy in CAPAS:
        b = patron(vram, (principal - 0x20 + desp) if desp else principal)
        if len(b) < 32:
            continue
        for y in range(16):
            izq, der = b[y], b[16 + y]
            for x in range(16):
                bit = (izq >> (7 - x)) & 1 if x < 8 else (der >> (15 - x)) & 1
                if bit:
                    lienzo[(y + dy) * ancho + x0 + x] = color


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return 1
    vram = open(sys.argv[1], "rb").read()
    salida = sys.argv[2]
    # La escala solo repite pixeles: la de 1 es la que usa la animacion de la
    # portada -el navegador la escala ella- y una mayor es para verla en una
    # pagina, donde 16x32 por fotograma se queda en nada.
    escala = int(sys.argv[3]) if len(sys.argv) > 3 else 1

    todos = [p for _, ps, _ in FOTOGRAMAS for p in ps]
    ancho, alto = 16 * len(todos), 32
    lienzo = [None] * (ancho * alto)        # None = ningun bit puesto: transparente
    for i, p in enumerate(todos):
        pinta(vram, lienzo, ancho, i * 16, p)

    # Sale con canal alfa a proposito: el fondo de un sprite es transparente, y
    # dejarlo negro convierte la tira en un rectangulo negro en cualquier pagina
    # que no tenga el fondo negro.
    filas = []
    for y in range(alto):
        fila = bytearray()
        for x in range(ancho):
            c = lienzo[y * ancho + x]
            fila += (b"\0\0\0\0" if c is None
                     else bytes(PALETA[c]) + b"\xff") * escala
        for _ in range(escala):
            filas.append(bytes(fila))
    escribe_png(salida, ancho * escala, alto * escala, filas, alfa=True)

    print("%s: %d fotogramas de 16x32 (%dx%d)"
          % (salida, len(todos), ancho * escala, alto * escala))
    for nombre, ps, cuadros in FOTOGRAMAS:
        print("  %-16s %d fotogramas, %d cuadros cada uno: %s"
              % (nombre, len(ps), cuadros, " ".join("0x%02X" % p for p in ps)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
