#!/usr/bin/env python3
"""Dibuja la pantalla de creditos con los tiles y la fuente del propio cartucho.

    python3 tools/creditos_png.py athletic.rom docs/imagenes/creditos.png

Los creditos solo se ven jugando: la fase se lleva en BCD en 0xE051 y solo
cuando pasa de 99 a 00 -diez pantallas por fase, asi que 990- el codigo de
0x4292 salta a ALL_STAGE_CLEAR. Esto los saca sin jugar, leyendo los mismos
bytes que leeria el juego: la lista de tiles de 0x447E, la fuente de 0x48CE
(donde el codigo de tile ES el ASCII) y el punto, que es el tile 0xAD de la
tabla de patrones de 0x7518.

El 0x01 se pinta en blanco: es el hueco entre palabras y no esta en ninguna de
las tablas de patrones que el cartucho sube a la VRAM. Y el color es cosa de la
tabla de colores, que aqui no se mira: esto sale en blanco y negro.
"""
import struct
import sys
import zlib

ORG = 0x4000
TILES = (0x447E, 0x44C8)          # los 74 tiles de los creditos
FUENTE = 0x48CE                   # 48 glifos de 8 bytes desde el codigo 0x30
PATRONES_90 = 0x7518              # tiles 0x90-0xAD, el punto es el ultimo
PATRONES_0A = 0x73B0              # tiles 0x0A-0x1B
FILAS = (20, 18, 18, 18)          # la primera lleva el marco a los dos lados


def patron(rom, tile):
    if 0x30 <= tile <= 0x5F:
        a = FUENTE + (tile - 0x30) * 8
    elif 0x90 <= tile <= 0xAD:
        a = PATRONES_90 + (tile - 0x90) * 8
    elif 0x0A <= tile <= 0x1B:
        a = PATRONES_0A + (tile - 0x0A) * 8
    else:
        return b"\0" * 8
    return rom[a - ORG:a - ORG + 8]


def png(ancho, alto, pixeles):
    raw = b"".join(b"\0" + bytes(255 if v else 0 for v in fila) for fila in pixeles)

    def trozo(tipo, datos):
        return (struct.pack(">I", len(datos)) + tipo + datos
                + struct.pack(">I", zlib.crc32(tipo + datos) & 0xFFFFFFFF))

    return (b"\x89PNG\r\n\x1a\n"
            + trozo(b"IHDR", struct.pack(">IIBBBBB", ancho, alto, 8, 0, 0, 0, 0))
            + trozo(b"IDAT", zlib.compress(raw))
            + trozo(b"IEND", b""))


def main(argv):
    if len(argv) != 3:
        print(__doc__)
        return 2
    rom = open(argv[1], "rb").read()
    datos = rom[TILES[0] - ORG:TILES[1] - ORG]
    filas, i = [], 0
    for n in FILAS:
        filas.append(datos[i:i + n])
        i += n
    esc, cols = 4, max(FILAS)
    ancho, alto = cols * 8 * esc, len(filas) * 8 * esc
    img = [[0] * ancho for _ in range(alto)]
    for fy, fila in enumerate(filas):
        margen = 0 if len(fila) == cols else 1   # las cortas van centradas
        for fx, tile in enumerate(fila):
            p = patron(rom, tile)
            for y in range(8):
                for x in range(8):
                    if p[y] & (0x80 >> x):
                        for sy in range(esc):
                            for sx in range(esc):
                                img[(fy * 8 + y) * esc + sy][
                                    ((fx + margen) * 8 + x) * esc + sx] = 1
    open(argv[2], "wb").write(png(ancho, alto, img))
    texto = "".join(chr(c) if 32 <= c < 127 else " " for c in datos)
    print("%s: %dx%d px" % (argv[2], ancho, alto))
    for n, fila in zip(FILAS, [texto[a:b] for a, b in
                               ((0, 20), (20, 38), (38, 56), (56, 74))]):
        print("  %s" % fila)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
