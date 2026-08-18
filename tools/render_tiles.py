#!/usr/bin/env python3
"""Dibuja un tramo de la imagen como tiles de 8x8 a 1 bit (32 por fila) para
VER que hay: fuente, tiles del mapa, dibujos grandes... Es una mirada, no una
medida: si el tramo no son tiles de 8 bytes saldra ruido, y eso tambien informa.

    python3 tools/render_tiles.py <imagen> <ini> <fin> <salida.png> [tiles_por_fila] [escala]
"""
import struct
import sys
import zlib


def png(w, h, rows, fn):
    raw = b"".join(b"\x00" + bytes(r) for r in rows)
    def chunk(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    open(fn, "wb").write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 0, 0, 0, 0))
                         + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))


def main():
    img = open(sys.argv[1], "rb").read()
    a, b = int(sys.argv[2], 0), int(sys.argv[3], 0)
    out = sys.argv[4]
    porfila = int(sys.argv[5]) if len(sys.argv) > 5 else 32
    esc = int(sys.argv[6]) if len(sys.argv) > 6 else 2
    datos = img[a:b]
    n = (len(datos) + 7) // 8
    filas = (n + porfila - 1) // porfila
    w, h = porfila * 8, filas * 8
    px = [[255] * w for _ in range(h)]
    for t in range(n):
        tx, ty = (t % porfila) * 8, (t // porfila) * 8
        for l in range(8):
            i = t * 8 + l
            if i >= len(datos):
                break
            v = datos[i]
            for bit in range(8):
                px[ty + l][tx + bit] = 0 if (v >> (7 - bit)) & 1 else 255
    rows = []
    for y in range(h):
        r = []
        for x in range(w):
            r += [px[y][x]] * esc
        for _ in range(esc):
            rows.append(r)
    png(w * esc, h * esc, rows, out)
    print(f"{out}: {n} tiles de 0x{a:04X} a 0x{b:04X}, {porfila} por fila")


if __name__ == "__main__":
    main()
