#!/usr/bin/env python3
"""Las imagenes de la web, dibujadas repitiendo lo que hace el cartucho.

    python3 tools/imagenes_web.py athletic.rom docs/imagenes

Aqui no hay capturas de emulador: cada PNG sale de rehacer, paso a paso, la
misma secuencia de escrituras que hace la ROM. La memoria de video la monta
tools/graficos.py -las copias de CARGA_FUENTE, CARGA_GRAFICOS_JUEGO y 0x70A5,
con sus espejos por bits y sus sustituciones de color-, y aqui encima se
repiten las llamadas concretas que pintan cada cosa:

    logo.png        PANTALLA_DEL_TITULO (0x4795) + TITULO_COLUMNA (0x47CB):
                    el RLE de 0x47FB en los tiles 0x40-0x61 y sus 17 columnas
                    de dos tiles en las filas 5 y 6
    cielo-*.png     los cuatro CIELO_* (0x5CC2, 0x5CCC, 0x5CD6, 0x5CE0)
    cerros-N.png    las cuatro combinaciones de CERROS_0..3 (0x5E8D..0x5E9C),
                    con los bloques de tiles que van detras del motor
    seto.png        PINTA_SETO (0x5C91)
    hierba.png      la hierba de DECORADO_NORMAL (0x5E71)
    tierra.png      PINTA_TIERRA (0x5CEA)
    estanque.png    PINTA_ESTANQUE (0x5CF4)
    child-park.png  ROTULO_CHILD_PARK (0x5E58)
    liana.png       los nueve dibujos de 0x555B, uno al lado de otro
    surtidor.png    los 18 bloques de 0x56DD, la tabla del surtidor subiendo
    tiles.png       los tres tercios de la tabla de patrones con sus colores
    sprites.png     los 64 sprites de 16x16

Si un rango estuviera mal etiquetado, estas imagenes saldrian ruido.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from graficos import (ORG, VRAM, carga_juego, motor_5F65, pinta_sprites,   # noqa: E402
                      pinta_tiles, png, rle, tile_px)

NOMBRES = 0x3800                    # base de la tabla de nombres (R2 = 0x0E)
FONDO = (0, 0, 0)


# ---------------------------------------------------------------------------
# Pintar una region de la tabla de nombres
# ---------------------------------------------------------------------------
class Pantalla:
    """Una tabla de nombres de 32x24 y la cuenta de que casillas se han escrito.

    El recorte de cada PNG no se da a ojo: se recorta al rectangulo de las
    casillas que la propia rutina ha tocado.
    """

    def __init__(self):
        self.t = bytearray(32 * 24)
        self.tocadas = set()

    def pon(self, vram, tile):
        p = vram - NOMBRES
        if 0 <= p < 32 * 24:
            self.t[p] = tile
            self.tocadas.add(p)

    def motor(self, rom, lista, tiles, vram):
        """Una llamada al motor de rotulos de 0x5F65 con sus tres punteros."""
        motor_5F65(rom, lista, tiles, vram, self.pon)

    def bloque(self, rom, origen, vram, filas, columnas):
        """PINTA_BLOQUE (0x6411): filas x columnas desde la ROM, +32 por fila."""
        p = origen - ORG
        for f in range(filas):
            for c in range(columnas):
                self.pon(vram + f * 32 + c, rom[p])
                p += 1

    def caja(self):
        fs = sorted({p // 32 for p in self.tocadas})
        cs = sorted({p % 32 for p in self.tocadas})
        return fs[0], fs[-1], cs[0], cs[-1]


def dibuja(v, pant, esc=2, caja=None):
    """La region tocada, con el tercio de patrones que le toca a cada fila."""
    f0, f1, c0, c1 = caja or pant.caja()
    out = []
    for f in range(f0, f1 + 1):
        filas = [[FONDO] * ((c1 - c0 + 1) * 8 * esc) for _ in range(8 * esc)]
        for c in range(c0, c1 + 1):
            px = tile_px(v, f // 8, pant.t[f * 32 + c], esc)
            for r in range(8 * esc):
                filas[r][(c - c0) * 8 * esc:(c - c0 + 1) * 8 * esc] = px[r]
        out += filas
    return len(out[0]), len(out), out


def escribe(od, nombre, w, h, px):
    png(w, h, px, os.path.join(od, nombre))
    print("  %-22s %dx%d" % (nombre, w, h))


def junta(trozos, hueco=8):
    """Varias imagenes en una fila, apoyadas abajo y con separacion."""
    h = max(t[1] for t in trozos)
    w = sum(t[0] for t in trozos) + hueco * (len(trozos) - 1)
    out = [[FONDO] * w for _ in range(h)]
    x = 0
    for tw, th, px in trozos:
        for r in range(th):
            out[h - th + r][x:x + tw] = px[r]
        x += tw + hueco
    return w, h, out


# ---------------------------------------------------------------------------
# El rotulo del titulo
# ---------------------------------------------------------------------------
def logo(rom, od, esc=6):
    """El ATHLETIC LAND de la pantalla del titulo, tal como lo monta el cartucho.

    0x4795 descomprime el RLE de 0x47FB en los patrones de los tiles 0x40-0x61
    (0x2200, primer tercio) y repite 17 veces los 16 bytes de color de 0x48C2
    desde 0x0200. 0x47CB reparte esos 34 tiles en 17 columnas de dos, filas 5 y
    6, desde la columna 8. Aqui se hace lo mismo.
    """
    v = VRAM()
    v.copia_bytes(rle(rom, 0x47FD), 0x2200)             # la direccion va delante
    color = rle(rom, 0x48C2)
    for i in range(17):
        v.copia_bytes(color, 0x0200 + i * len(color))
    pant = Pantalla()
    for n in range(17):
        pant.pon(NOMBRES + 5 * 32 + 8 + n, 0x40 + 2 * n)
        pant.pon(NOMBRES + 6 * 32 + 8 + n, 0x41 + 2 * n)
    escribe(od, "logo.png", *dibuja(v, pant, esc))


# ---------------------------------------------------------------------------
# Los decorados: cada uno es la llamada (o llamadas) que lo pinta
# ---------------------------------------------------------------------------
# (fichero, [(lista, tiles, vram)], [(origen, vram, filas, columnas)])
DECORADOS = [
    ("cielo-azul-amarillo.png", [(0x6DD4, 0x6E90, 0x3860)], []),        # 5CC2
    ("cielo-azul-verde.png",    [(0x6DD4, 0x6EB5, 0x3860)], []),        # 5CCC
    ("cielo-rojo-blanco.png",   [(0x6DD4, 0x6EDA, 0x3860)], []),        # 5CD6
    ("cielo-rojo-verde.png",    [(0x6DD4, 0x6EFF, 0x3860)], []),        # 5CE0
    ("seto.png",                [(0x6DDF, 0x6F27, 0x3940)], []),        # 5C91
    ("hierba.png",              [(0x6DE2, 0x6F8A, 0x39E0)], []),        # 5E71
    ("tierra.png",              [(0x6DE4, 0x6F8B, 0x3A00)], []),        # 5CEA
    ("estanque.png",            [(0x6DE8, 0x6F8E, 0x3A09)], []),        # 5CFA
    ("child-park.png",          [(0x6DF8, 0x6FCF, 0x3929)], []),        # 5E67
]

# Los cuatro cerros de arriba, como los arma DECORADO_NORMAL por los bits 1-2
# del SCENE: cada mitad es una llamada al motor mas sus dos bloques de tiles.
CERRO_IZQ = ([(0x6E2A, 0x6FF9, 0x3840)],
             [(0x700D, 0x38A0, 3, 6), (0x701F, 0x3901, 8, 4)])          # 5EA1
CERRO_DER = ([(0x6E44, 0x703F, 0x3850)],
             [(0x700D, 0x38BA, 3, 6), (0x701F, 0x391B, 8, 4)])          # 5EC9
MESETA_IZQ = ([(0x6E5E, 0x7054, 0x3840)],
              [(0x7064, 0x38A0, 3, 8), (0x707C, 0x3903, 8, 3)])         # 5EE3
MESETA_DER = ([(0x6E77, 0x7094, 0x3850)],
              [(0x7064, 0x38B8, 3, 8), (0x707C, 0x391B, 8, 3)])         # 5F01
CERROS = [("cerros-0.png", CERRO_IZQ, CERRO_DER),
          ("cerros-1.png", CERRO_IZQ, MESETA_DER),
          ("cerros-2.png", MESETA_IZQ, MESETA_DER),
          ("cerros-3.png", MESETA_IZQ, CERRO_DER)]


def _pinta(rom, pant, mitad):
    for l, t, a in mitad[0]:
        pant.motor(rom, l, t, a)
    for o, a, f, c in mitad[1]:
        pant.bloque(rom, o, a, f, c)


def decorados(rom, v, od, esc=2):
    for fich, motores, bloques in DECORADOS:
        pant = Pantalla()
        _pinta(rom, pant, (motores, bloques))
        escribe(od, fich, *dibuja(v, pant, esc))
    for fich, izq, der in CERROS:
        pant = Pantalla()
        _pinta(rom, pant, izq)
        _pinta(rom, pant, der)
        f0, f1, _, _ = pant.caja()
        escribe(od, fich, *dibuja(v, pant, esc, (f0, f1, 0, 31)))


# ---------------------------------------------------------------------------
# La liana y el surtidor
# ---------------------------------------------------------------------------
def liana(rom, v, od, esc=2):
    """Los nueve dibujos de 0x555B, uno al lado de otro.

    No es una animacion descomprimida ni una interpolacion: son los nueve
    dibujos que hay en el cartucho, pintados como los pinta PINTA_DIBUJO
    (0x60EE) desde la fila 6, columna 10, que es de donde cuelga la liana 1.
    """
    trozos = []
    for i in range(9):
        p = rom[0x555B - ORG + i * 2] | (rom[0x555B - ORG + i * 2 + 1] << 8)
        pant = Pantalla()
        inicio = pos = NOMBRES + 6 * 32 + 10
        q = p - ORG
        while True:
            b = rom[q]
            q += 1
            if b == 0xFF:
                break
            if b >= 0xFC:                   # fila siguiente: 31, 32 o 33
                inicio += {0xFE: 31, 0xFD: 32, 0xFC: 33}[b]
                pos = inicio
                continue
            pant.pon(pos, b)
            pos += 1
        _, f1, c0, c1 = pant.caja()
        trozos.append(dibuja(v, pant, esc, (6, f1, c0, c1)))
    escribe(od, "liana.png", *junta(trozos))


def surtidor(rom, v, od, esc=2):
    """Los 18 bloques de 6x3 de 0x56DD: la tabla del surtidor, subiendo.

    El juego los pinta en la fila 10 (tercio de en medio), asi que aqui van a
    la misma fila: es donde estan sus tiles.
    """
    trozos = []
    for i in range(18):
        p = rom[0x56DD - ORG + i * 2] | (rom[0x56DD - ORG + i * 2 + 1] << 8)
        pant = Pantalla()
        pant.bloque(rom, p, NOMBRES + 10 * 32, 3, 6)
        trozos.append(dibuja(v, pant, esc, (10, 12, 0, 5)))
    escribe(od, "surtidor.png", *junta(trozos, 4))


def main(argv):
    if len(argv) < 3:
        print(__doc__)
        return 2
    with open(argv[1], "rb") as f:
        rom = f.read()
    od = argv[2]
    os.makedirs(od, exist_ok=True)
    v = carga_juego(rom)
    logo(rom, od)
    decorados(rom, v, od)
    liana(rom, v, od)
    surtidor(rom, v, od)
    pinta_tiles(v, os.path.join(od, "tiles.png"))
    print("  tiles.png")
    pinta_sprites(v, os.path.join(od, "sprites.png"))
    print("  sprites.png")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
