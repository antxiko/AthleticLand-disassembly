#!/usr/bin/env python3
"""Reconstruye la VRAM del juego tal como la carga la ROM y la pinta en PNG.

    python3 tools/graficos.py athletic.rom work/gfx

Repite, en el mismo orden y con las mismas direcciones, las copias que hacen
CARGA_FUENTE (0x4626), CARGA_GRAFICOS_JUEGO (0x5937) y 0x70A5, incluidos los
espejos por bits (0x5A4B para tiles, 0x5A09 para sprites) y las sustituciones
de color de 0x7116. No inventa nada: es la lista de `call COPIA_A_VRAM` del
listado, pasada a Python. Con eso salen:

    tiles.png     los 256 tiles de cada tercio (patron + color), 32 por fila
    sprites.png   los 64 sprites de 16x16 en el color que les pone el juego
                  no se sabe aqui: salen en blanco sobre negro
    bloques.png   los 18 bloques de 6x3 de 0x56DD (plataformas que suben y bajan)
    liana.png     las 9 fases de la liana de 0x555B
    fondo_N.png   las distribuciones de 0x6DD4/0x714F pintadas por el motor
                  0x5F65 en una tabla de nombres vacia
"""
import os
import struct
import sys
import zlib

ORG = 0x4000
PAL = [(0, 0, 0), (0, 0, 0), (33, 200, 66), (94, 220, 120), (84, 85, 237), (125, 118, 252),
       (212, 82, 77), (66, 235, 245), (252, 85, 84), (255, 121, 120), (212, 193, 84),
       (230, 206, 128), (33, 176, 59), (201, 91, 186), (204, 204, 204), (255, 255, 255)]


def png(w, h, px, fn):
    raw = b"".join(b"\x00" + bytes(v for p in row for v in p) for row in px)
    def chunk(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    open(fn, "wb").write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
                         + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))


class VRAM:
    def __init__(self):
        self.m = bytearray(0x4000)

    def copia(self, rom, src, dst, n):
        self.m[dst:dst + n] = rom[src - ORG:src - ORG + n]

    def rellena(self, dst, n, v):
        self.m[dst:dst + n] = bytes([v]) * n

    def copia_bytes(self, data, dst):
        self.m[dst:dst + len(data)] = data


def espejo_bits(data):
    return bytes(int(f"{b:08b}"[::-1], 2) for b in data)


def rle(rom, a):
    """RLE_A_VRAM_DE (0x4BB7): 0 fin; n<0x80 repite n veces el siguiente; n>=0x80 copia n&0x7F."""
    out = bytearray()
    p = a - ORG
    while True:
        n = rom[p]; p += 1
        if n == 0:
            break
        if n & 0x80:
            k = n & 0x7F; out += rom[p:p + k]; p += k
        else:
            out += bytes([rom[p]]) * n; p += 1
    return bytes(out)


def motor_5F65(rom, lista, tiles, vram_addr, escribe):
    """El motor de rotulos: lista de cuentas (bit 7 = relleno con un tile), 0x80 = direccion nueva, 0 = fin."""
    lp, tp, va = lista - ORG, tiles - ORG, vram_addr
    while True:
        n = rom[lp]
        if n == 0x80:
            va = rom[lp + 1] | (rom[lp + 2] << 8); lp += 3; n = rom[lp]
        if n == 0:
            return
        c = n & 0x7F
        if n & 0x80:
            for i in range(c):
                escribe(va + i, rom[tp])
            tp += 1
        else:
            for i in range(c):
                escribe(va + i, rom[tp + i])
            tp += c
        va += c
        lp += 1


def carga_juego(rom):
    v = VRAM()
    # CARGA_FUENTE 0x4626
    v.rellena(0x0180, 0x180, 0xF0)
    v.copia(rom, 0x48CE, 0x2180, 0x180)
    # 0x70A5
    v.copia(rom, 0x73B0, 0x2050, 0x90)
    v.copia(rom, 0x7440, 0x2100, 0x80)
    for i in range(4):
        v.copia(rom, 0x74C0, 0x2300 + i * 0x58, 0x58)
    v.copia(rom, 0x7518, 0x2480, 0xF0)
    v.copia(rom, 0x7608, 0x2600, 0x1F0)
    motor_5F65(rom, 0x714F, 0x71E3, 0x0008, lambda a, b: v.m.__setitem__(a, b))
    motor_5F65(rom, 0x7172, 0x7237, 0x0100, lambda a, b: v.m.__setitem__(a, b))
    v.copia(rom, 0x723A, 0x0300, 0xB0)
    sub = bytearray()
    for b in rom[0x723A - ORG:0x723A - ORG + 0xB0]:
        hi = 0x30 if (b & 0xF0) == 0x10 else (b & 0xF0)
        lo = 0x03 if (b & 0x0F) == 0x01 else (b & 0x0F)
        sub.append(hi | lo)
    v.copia_bytes(sub, 0x03B0)
    v.copia(rom, 0x72EA, 0x0460, 0x20)
    motor_5F65(rom, 0x7176, 0x730A, 0x0480, lambda a, b: v.m.__setitem__(a, b))
    motor_5F65(rom, 0x719D, 0x7336, 0x0600, lambda a, b: v.m.__setitem__(a, b))
    # TRIPLICA_PATRONES / TRIPLICA_COLORES
    v.m[0x2800:0x3000] = v.m[0x2000:0x2800]; v.m[0x3000:0x3800] = v.m[0x2000:0x2800]
    v.m[0x0800:0x1000] = v.m[0x0000:0x0800]; v.m[0x1000:0x1800] = v.m[0x0000:0x0800]
    # el resto de 0x5937
    v.copia(rom, 0x4C93, 0x2B00, 0xF0)
    v.copia(rom, 0x4C6B, 0x2580, 0x38)
    esp = espejo_bits(rom[0x4C6B - ORG:0x4C6B - ORG + 0x118])   # 0x5A4B -> E130
    v.copia_bytes(esp[:0x30], 0x25B8)
    v.copia_bytes(esp[0x28:0x28 + 0xF0], 0x2BF0)                # desde E158
    v.copia(rom, 0x4D83, 0x2D78, 0x130)
    v.copia(rom, 0x4EAB, 0x2CE0, 0x80)
    v.copia_bytes(espejo_bits(rom[0x4EAB - ORG:0x4EAB - ORG + 0x80]), 0x2EA8)
    v.rellena(0x0B00, 0x278, 0xF0)
    v.rellena(0x0580, 0x68, 0xF0)
    v.copia(rom, 0x4F2B, 0x0D78, 0x70)
    v.rellena(0x0DE8, 0x98, 0xF1)
    v.copia(rom, 0x4F9B, 0x0E88, 0x20)
    v.copia(rom, 0x4FBB, 0x0CE0, 0x80)
    v.copia(rom, 0x4FBB, 0x0EA8, 0x80)
    v.copia(rom, 0x503B, 0x1800, 0x2E0)
    # 0x5A09: espejo de 23 sprites de 16x16 (izquierda<->derecha) a 0x1AE0
    src = rom[0x503B - ORG:0x503B - ORG + 0x2E0]
    esp = bytearray(0x2E0)
    for s in range(23):
        for r in range(16):
            l, rr = src[s * 32 + r], src[s * 32 + 16 + r]
            w = (l << 8) | rr
            w2 = int(f"{w:016b}"[::-1], 2)
            esp[s * 32 + r], esp[s * 32 + 16 + r] = w2 >> 8, w2 & 0xFF
    v.copia_bytes(bytes(esp), 0x1AE0)
    v.copia(rom, 0x531B, 0x1DC0, 0x240)
    return v


def tile_px(v, tercio, t, esc=2):
    pat = v.m[0x2000 + tercio * 0x800 + t * 8: 0x2000 + tercio * 0x800 + t * 8 + 8]
    col = v.m[0x0000 + tercio * 0x800 + t * 8: 0x0000 + tercio * 0x800 + t * 8 + 8]
    rows = []
    for r in range(8):
        fg, bg = PAL[col[r] >> 4], PAL[col[r] & 15]
        row = []
        for b in range(8):
            row += [fg if (pat[r] >> (7 - b)) & 1 else bg] * esc
        rows += [row] * esc
    return rows


def pinta_tiles(v, fn, esc=2):
    W = 32 * 8 * esc + 31
    out = []
    for tercio in range(3):
        for fila in range(8):
            rows = [[(60, 60, 60)] * W for _ in range(8 * esc)]
            for c in range(32):
                t = fila * 32 + c
                px = tile_px(v, tercio, t, esc)
                x0 = c * (8 * esc + 1)
                for r in range(8 * esc):
                    rows[r][x0:x0 + 8 * esc] = px[r]
            out += rows
            out.append([(60, 60, 60)] * W)
        out += [[(255, 0, 0)] * W] * 2
    png(W, len(out), out, fn)


def pinta_sprites(v, fn, esc=2):
    out = []
    W = 16 * (16 * esc + 1)
    for fila in range(4):
        rows = [[(60, 60, 60)] * W for _ in range(16 * esc)]
        for c in range(16):
            s = fila * 16 + c
            d = v.m[0x1800 + s * 32:0x1800 + s * 32 + 32]
            for r in range(16):
                bits = (d[r] << 8) | d[16 + r]
                for b in range(16):
                    colr = (255, 255, 255) if (bits >> (15 - b)) & 1 else (0, 0, 0)
                    for dy in range(esc):
                        for dx in range(esc):
                            rows[r * esc + dy][c * (16 * esc + 1) + b * esc + dx] = colr
        out += rows
        out.append([(60, 60, 60)] * W)
    png(W, len(out), out, fn)


def pinta_nombres(v, nombres, fn, esc=2, filas=24):
    """nombres: 32*filas bytes; cada fila cae en su tercio."""
    W = 32 * 8 * esc
    out = []
    for f in range(filas):
        rows = [[(0, 0, 0)] * W for _ in range(8 * esc)]
        for c in range(32):
            t = nombres[f * 32 + c]
            px = tile_px(v, f // 8, t, esc)
            for r in range(8 * esc):
                rows[r][c * 8 * esc:(c + 1) * 8 * esc] = px[r]
        out += rows
    png(W, len(out), out, fn)


def main():
    rom = open(sys.argv[1], "rb").read()
    od = sys.argv[2]
    os.makedirs(od, exist_ok=True)
    v = carga_juego(rom)
    pinta_tiles(v, os.path.join(od, "tiles.png"))
    pinta_sprites(v, os.path.join(od, "sprites.png"))
    # bloques 6x3 de 0x56DD (18) y su byte 19
    nombres = bytearray(32 * 24)
    for i in range(18):
        p = rom[0x56DD - ORG + i * 2] | (rom[0x56DD - ORG + i * 2 + 1] << 8)
        d = rom[p - ORG:p - ORG + 19]
        f0, c0 = 8 + (i // 5) * 4, (i % 5) * 6 + 1
        for r in range(3):
            nombres[(f0 + r) * 32 + c0:(f0 + r) * 32 + c0 + 6] = d[r * 6:(r + 1) * 6]
        print(f"bloque {i:2d} @{p:04X}: byte 19 = 0x{d[18]:02X}")
    pinta_nombres(v, nombres, os.path.join(od, "bloques.png"))
    # liana: 9 flujos de 0x555B en la fila 6 (donde los pinta 0x6026: 0x38CA/0x38D6)
    for i in range(9):
        p = rom[0x555B - ORG + i * 2] | (rom[0x555B - ORG + i * 2 + 1] << 8)
        nombres = bytearray(32 * 24)
        # 0x60EF: 0xFE/0xFD/0xFC saltan 31/32/33 desde el PRINCIPIO de la fila
        # (el push de de 0x60EE), no desde el ultimo tile: fila siguiente una
        # columna a la izquierda, la misma, o una a la derecha
        inicio = 6 * 32 + 10
        pos = inicio
        q = p - ORG
        while True:
            b = rom[q]; q += 1
            if b == 0xFF:
                break
            if b >= 0xFC:
                inicio += {0xFE: 31, 0xFD: 32, 0xFC: 33}[b]; pos = inicio; continue
            nombres[pos] = b; pos += 1
        print(f"liana {i} @{p:04X}: acaba en {q + ORG:04X}, tres bytes {rom[q]:02X} {rom[q+1]:02X} {rom[q+2]:02X}")
        pinta_nombres(v, nombres, os.path.join(od, f"liana_{i}.png"))
    # los fondos: cada call 0x5F65 del juego sobre una tabla de nombres vacia
    fondos = {"5C91": (0x6DDF, 0x6F27, 0x3940), "5CB8": (0x6DDB, 0x6F24, 0x3940),
              "5CC2": (0x6DD4, 0x6E90, 0x3860), "5CCC": (0x6DD4, 0x6EB5, 0x3860),
              "5CD6": (0x6DD4, 0x6EDA, 0x3860), "5CE0": (0x6DD4, 0x6EFF, 0x3860),
              "5CEA": (0x6DE4, 0x6F8B, 0x3A00), "5CFA": (0x6DE8, 0x6F8E, 0x3A09),
              "5E67": (0x6DF8, 0x6FCF, 0x3929), "5E71": (0x6DE2, 0x6F8A, 0x39E0),
              "5EA1": (0x6E2A, 0x6FF9, 0x3840), "5EC9": (0x6E44, 0x703F, 0x3850),
              "5EE3": (0x6E5E, 0x7054, 0x3840), "5F01": (0x6E77, 0x7094, 0x3850)}
    for k, (l, t, a) in fondos.items():
        nombres = bytearray(32 * 24)
        motor_5F65(rom, l, t, a, lambda ad, b: nombres.__setitem__(ad - 0x3800, b))
        pinta_nombres(v, nombres, os.path.join(od, f"fondo_{k}.png"))
    print("ok", od)


if __name__ == "__main__":
    main()
