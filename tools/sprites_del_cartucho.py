#!/usr/bin/env python3
"""Reconstruye la tabla de patrones de sprite tal como la deja el arranque, a
partir SOLO del cartucho: descomprime los tres bloques y fabrica los espejados.

    python3 tools/sprites_del_cartucho.py pitfall.rom [work/omsx/demo.vram.bin]

Por que hace falta esto y no basta con volcar la VRAM del emulador: los huecos de
patron SE REUTILIZAN. El patron 0x3C -uno de los dos del guion de trepar- vive en
la VRAM 0x39E0, y ahi mismo copia 0xAA07 el `sprite_crudo_1` cuando la escena lo
pide. En un volcado cualquiera, ese hueco puede tener el sprite de la escena y no
el del jugador, asi que los fotogramas hay que sacarlos de donde no cambian: del
cartucho.

Lo que hace el arranque, y lo que se reproduce aqui:

  0x8B5E  descomprime 0x939D a la VRAM 0x3880   (416 bytes)
  0x8B6F  descomprime 0x9473 a la VRAM 0x3B40   (288 bytes)
  0x8B80  descomprime 0x956A a la VRAM 0x3D80   (288 bytes)
  0x8B5E  y ADEMAS fabrica los espejados: nueve sprites de cuatro patrones, o sea
          36 patrones, que van justo al hueco que los bloques dejan libre
          (0x3A20-0x3B40, patrones 0x44 a 0x67).

El formato RLE se lee entero en el descompresor de 0xB142: dos bytes de direccion
de VRAM -al byte alto se le suma 0x40, que es el bit de escritura- y luego tokens
de un byte con el contador en los seis bits bajos: bit 7 saltar N, bit 6 copiar N
literales, ninguno de los dos repetir N veces el byte siguiente, y un cero cierra.

Y el espejo son DOS rutinas, no una (0xB1D1 y 0xB20B): un sprite de 16x16 en el
MSX son dos mitades de 16 bytes, asi que para darle la vuelta hay que invertir
cada byte bit a bit Y cruzar las dos mitades.
"""
import sys

ORG = 0x8000
BASE_SPRITES = 0x3800

# (donde esta el bloque en el cartucho, quien lo carga)
BLOQUES = [(0x939D, "0x8B5E"), (0x9473, "0x8B6F"), (0x956A, "0x8B80")]

# El espejo va por SPRITES, no por patrones: un sprite de 16x16 son cuatro
# patrones de 8 bytes. Son tres grupos de nueve sprites, uno por capa de color,
# y los tres los dispara el mismo arranque justo detras de su bloque:
#   0x8B66  ld hl,00044h / ld de,00020h    nueve sprites
#   0x8B77  ld hl,0008Ch / ld de,00068h
#   0x8B88  ld hl,000D4h / ld de,000B0h
GRUPOS_DE_ESPEJO = [(0x20, 0x44), (0x68, 0x8C), (0xB0, 0xD4)]
SPRITES_POR_GRUPO = 9
PATRONES_POR_SPRITE = 4


def descomprime(rom, off):
    """Devuelve (direccion_de_vram, bytes) del bloque RLE que empieza en off."""
    destino = rom[off] | (rom[off + 1] << 8)
    destino &= 0x3FFF                          # el 0x40 del byte alto es el bit de escritura
    p = off + 2
    salida = {}
    d = destino
    while True:
        t = rom[p]
        n = t & 0x3F
        if n == 0:
            return destino, salida
        if t & 0x80:                           # saltar n posiciones
            d += n
            p += 1
            continue
        p += 1
        if t & 0x40:                           # n bytes literales
            for i in range(n):
                salida[d] = rom[p + i]
                d += 1
            p += n
        else:                                  # n veces el byte siguiente
            for _ in range(n):
                salida[d] = rom[p]
                d += 1
            p += 1


def espeja(patron):
    """El espejo horizontal de un patron de 16x16: cada byte del reves y las dos
    mitades cruzadas."""
    def invierte(b):
        return int("{:08b}".format(b)[::-1], 2)
    izq, der = patron[:16], patron[16:]
    return bytes(invierte(b) for b in der) + bytes(invierte(b) for b in izq)


def tabla_de_patrones(rom):
    """La tabla de patrones de sprite como la deja el arranque, en un dict
    direccion -> byte, y luego una funcion para leer un patron entero."""
    vram = {}
    for off, quien in BLOQUES:
        destino, datos = descomprime(rom, off - ORG)
        vram.update(datos)
        print("  0x%04X -> VRAM 0x%04X, %d bytes (lo carga %s)"
              % (off, destino, len(datos), quien))

    def patron(n):
        o = BASE_SPRITES + n * 8
        return bytes(vram.get(o + i, 0) for i in range(32))

    # los espejados, encima: nueve sprites por grupo, cuatro patrones cada uno
    for origen, destino in GRUPOS_DE_ESPEJO:
        for k in range(SPRITES_POR_GRUPO):
            s = origen + k * PATRONES_POR_SPRITE
            d = destino + k * PATRONES_POR_SPRITE
            for i, b in enumerate(espeja(patron(s))):
                vram[BASE_SPRITES + d * 8 + i] = b
        print("  espejo: nueve sprites de 0x%02X a 0x%02X (patrones 0x%02X-0x%02X)"
              % (origen, destino, destino,
                 destino + SPRITES_POR_GRUPO * PATRONES_POR_SPRITE - 1))
    return patron


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 1
    rom = open(sys.argv[1], "rb").read()
    print("Reconstruyendo la tabla de sprites desde el cartucho:")
    patron = tabla_de_patrones(rom)

    if len(sys.argv) > 2:
        # La comprobacion que decide si el descompresor esta bien leido: los
        # patrones reconstruidos tienen que salir IDENTICOS a los del volcado del
        # emulador, salvo justo en los huecos que las escenas reutilizan.
        vram = open(sys.argv[2], "rb").read()
        iguales, distintos = [], []
        # Hasta 0x100: el tercer grupo de espejo llega a 0xF7, y cortar en
        # 0xE0 dejaba seis de sus nueve sprites sin comparar. Las dos ventanas
        # que salen distintas (0xF5, 0xF6) pisan la celda 0x3FC0, que es el
        # hueco que las escenas recargan (sprites_rle_7/8/9): reutilizacion
        # documentada, no un fallo del espejo.
        for n in range(0x20, 0x100):
            mio = patron(n)
            suyo = vram[BASE_SPRITES + n * 8:BASE_SPRITES + n * 8 + 32]
            if not any(mio):
                continue
            (iguales if mio == suyo else distintos).append(n)
        print("\nContra %s:" % sys.argv[2])
        print("  patrones identicos : %d" % len(iguales))
        print("  patrones distintos : %d  %s" % (len(distintos),
              " ".join("0x%02X" % n for n in distintos)))
        print("  (los distintos son los huecos que una escena ha reutilizado)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
