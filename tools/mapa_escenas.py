#!/usr/bin/env python3
"""El mapa del mundo: las 255 escenas, sacadas del cartucho y no de jugar.

POR QUE ASI Y NO JUGANDO. Recorrer el mundo con el mando en la mano da
repeticiones y atascos -una carrera de 25 minutos con el personaje corriendo
a la derecha visito CINCO escenas- porque el jugador se muere, se cae y
vuelve sobre sus pasos. El mundo, en cambio, esta escrito en el binario: se
replica como lo hace el juego y salen las 255 seguidas, sin repetir ninguna.

COMO GENERA EL JUEGO SUS ESCENAS, que es lo que aqui se replica:

  - 0xE222 es un REGISTRO DE DESPLAZAMIENTO REALIMENTADO (LFSR) de 8 bits, el
    mismo truco del Pitfall! original de Atari 2600: el mundo no esta
    almacenado, se genera. INIT lo siembra con 0xC4; la rutina 0xB68F lo
    avanza al salir por la derecha y 0xB69F -su inversa exacta- lo retrocede
    al salir por la izquierda. Su anillo tiene periodo 255.

  - De ese unico byte salen las tres decisiones de la escena:
        bits 6-7  -> DECORADO: indexa las tablas 0xA086 (juego de 16 tiles) y
                     0xA08E (layout de la escena). Lo calcula 0x9F91-0x9FA3.
        bits 3-5  -> TIPO: indexa la tabla de 0xAEB4, que despacha a la rutina
                     que pone los obstaculos. Lo calcula 0x9EF4-0x9EFF.
        bits 0-2  -> VARIANTE: el submodo, que consumen las tres tablas de
                     0xAE94/0xAEA4/0xAEC4 por el despachador de 0xA99F.

Uso: mapa_escenas.py <rom> [salida.tsv]
"""
import sys


def avanza(v):
    """El paso adelante de 0xB68F, con la semantica exacta del Z80.

    Cada `rla` mete el acarreo por el bit 0 y saca el bit 7 al acarreo, asi
    que el orden importa: lo que la rutina calcula con los xor es UN bit de
    realimentacion, y el ultimo par de instrucciones desplaza el registro
    metiendolo por abajo.
    """
    a, c = v, 0
    for xor in (True, True, False, True):          # rla / xor (hl) intercalados
        a, c = ((a << 1) | c) & 0xFF, a >> 7
        if xor:
            a ^= v
    a, c = ((a << 1) | c) & 0xFF, a >> 7           # el rla que deja la realimentacion
    a = v
    a, c = ((a << 1) | c) & 0xFF, a >> 7           # y el desplazamiento de verdad
    return a


def anillo(semilla=0xC4):
    """Las escenas en el orden en que se recorren yendo siempre a la derecha."""
    out, v = [semilla], semilla
    while True:
        v = avanza(v)
        if v == out[0]:
            break
        out.append(v)
        if len(out) > 4096:                        # red de seguridad
            raise SystemExit("el anillo no cierra: revisar la rutina")
    return out


def palabras(rom, org, base, n):
    return [rom[base - org + i * 2] | rom[base - org + i * 2 + 1] << 8
            for i in range(n)]


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    org = 0x8000
    with open(sys.argv[1], "rb") as f:
        rom = f.read()

    tiles = palabras(rom, org, 0xA086, 4)          # juegos de 16 tiles
    layouts = palabras(rom, org, 0xA08E, 4)        # layouts de escena
    tipos = palabras(rom, org, 0xAEB4, 8)          # rutinas por tipo

    escenas = anillo()
    print("El mundo son %d escenas, y ninguna se repite." % len(escenas))
    print()
    print("  #    LFSR  decorado          tipo              variante")
    print("  " + "-" * 62)

    filas = []
    for i, v in enumerate(escenas):
        d = (v >> 6) & 3
        t = (v >> 3) & 7
        s = v & 7
        filas.append((i, v, d, tiles[d], layouts[d], t, tipos[t], s))
        if i < 8 or i >= len(escenas) - 2:
            print("  %3d   0x%02X  %d (tiles %04X)   %d (rutina %04X)   %d"
                  % (i, v, d, tiles[d], t, tipos[t], s))
        elif i == 8:
            print("  ...")

    print()
    print("  Reparto de las %d escenas:" % len(escenas))
    for nombre, idx, total in (("decorado", 2, 4), ("tipo", 5, 8), ("variante", 7, 8)):
        cuenta = [0] * total
        for fila in filas:
            cuenta[fila[idx]] += 1
        print("    %-9s %s" % (nombre, "  ".join("%d:%d" % (k, n)
                                                 for k, n in enumerate(cuenta))))

    if len(sys.argv) > 2:
        with open(sys.argv[2], "w", encoding="utf-8") as f:
            f.write("orden\tlfsr\tdecorado\ttiles\tlayout\ttipo\trutina\tvariante\n")
            for fila in filas:
                f.write("%d\t0x%02X\t%d\t0x%04X\t0x%04X\t%d\t0x%04X\t%d\n" % fila)
        print()
        print("  Escrito %s" % sys.argv[2])
    return 0


if __name__ == "__main__":
    sys.exit(main())
