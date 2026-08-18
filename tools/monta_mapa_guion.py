#!/usr/bin/env python3
"""El mapa del mundo con las 255 escenas ordenadas y ETIQUETADAS.

Diferencias con monta_mapa.py, que solo pegaba capturas:

  - ORDEN DEL ANILLO DE VERDAD. Las capturas se cruzan por su valor de LFSR
    (el segundo campo del nombre), no por el numero de captura: el recorrido
    del emulador arranca despues de dar el primer paso, asi que su numeracion
    va corrida uno. Aqui la casilla 0 es 0xC4, que es la semilla que INIT
    escribe en 0xE222 y por tanto la pantalla en la que empieza la partida.

  - CADA CASILLA DICE LO QUE ES: numero de paso, valor del LFSR y tipo de
    escena (los bits 3-5), con un marco del color del tipo. Las 32 casillas
    de tipo 5 llevan ademas el valor del tesoro que esconden, que es lo que
    convierte la rejilla en un plan de ruta.

La casilla que sobra de las 256 es el estado 0x00, que no pertenece al anillo
-de un LFSR no se sale del cero- y es el que usa la pantalla del titulo.

Sin PIL: reutiliza el lector y el escritor de PNG de monta_mapa.py.

Uso: monta_mapa_guion.py <dir_capturas> <mapa_escenas.tsv> <salida.png>
"""
import csv
import glob
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from monta_mapa import lee_png, escribe_png, recorta_y_reduce   # noqa: E402

# Los ocho tipos de escena, leidos de sus rutinas (tabla 0xAEB4) y contrastados
# con la captura de cada uno. El color es solo para el mapa.
TIPOS = {
    0: ("HOYO",      (0xC0, 0xC0, 0xC0)),
    1: ("3 HOYOS",   (0xFF, 0xFF, 0xFF)),
    2: ("BREA",      (0xFF, 0x80, 0x00)),
    3: ("AGUA",      (0x40, 0xA0, 0xFF)),
    4: ("COCODRILO", (0x00, 0xC0, 0x40)),
    5: ("TESORO",    (0xFF, 0xD0, 0x00)),
    6: ("BREA+LIANA", (0xFF, 0x40, 0x40)),
    7: ("AGUA+LIANA", (0x00, 0xD0, 0xD0)),
}

# Tabla 0xAEA4, que SOLO se usa cuando el tipo es 5: cuatro rutinas de tesoro,
# cada una con el valor en miles que escribe en 0xE188 antes de pintarlo.
TESOROS = {0xAB1B: 4, 0xAB51: 3, 0xABB7: 5, 0xAC11: 2}
AEA4 = [0xAC11, 0xAB51, 0xAB1B, 0xABB7, 0xAC11, 0xAB51, 0xAB1B, 0xABB7]

# Fuente de 5x7 hecha a mano: solo los signos que salen en las etiquetas.
GLIFOS = {
    "0": ("01110", "10001", "10011", "10101", "11001", "10001", "01110"),
    "1": ("00100", "01100", "00100", "00100", "00100", "00100", "01110"),
    "2": ("01110", "10001", "00001", "00010", "00100", "01000", "11111"),
    "3": ("11111", "00010", "00100", "00010", "00001", "10001", "01110"),
    "4": ("00010", "00110", "01010", "10010", "11111", "00010", "00010"),
    "5": ("11111", "10000", "11110", "00001", "00001", "10001", "01110"),
    "6": ("00110", "01000", "10000", "11110", "10001", "10001", "01110"),
    "7": ("11111", "00001", "00010", "00100", "01000", "01000", "01000"),
    "8": ("01110", "10001", "10001", "01110", "10001", "10001", "01110"),
    "9": ("01110", "10001", "10001", "01111", "00001", "00010", "01100"),
    "A": ("01110", "10001", "10001", "11111", "10001", "10001", "10001"),
    "B": ("11110", "10001", "10001", "11110", "10001", "10001", "11110"),
    "C": ("01110", "10001", "10000", "10000", "10000", "10001", "01110"),
    "D": ("11100", "10010", "10001", "10001", "10001", "10010", "11100"),
    "E": ("11111", "10000", "10000", "11110", "10000", "10000", "11111"),
    "F": ("11111", "10000", "10000", "11110", "10000", "10000", "10000"),
    "G": ("01110", "10001", "10000", "10111", "10001", "10001", "01111"),
    "H": ("10001", "10001", "10001", "11111", "10001", "10001", "10001"),
    "I": ("01110", "00100", "00100", "00100", "00100", "00100", "01110"),
    "J": ("00111", "00010", "00010", "00010", "00010", "10010", "01100"),
    "K": ("10001", "10010", "10100", "11000", "10100", "10010", "10001"),
    "L": ("10000", "10000", "10000", "10000", "10000", "10000", "11111"),
    "M": ("10001", "11011", "10101", "10101", "10001", "10001", "10001"),
    "N": ("10001", "11001", "10101", "10011", "10001", "10001", "10001"),
    "O": ("01110", "10001", "10001", "10001", "10001", "10001", "01110"),
    "P": ("11110", "10001", "10001", "11110", "10000", "10000", "10000"),
    "Q": ("01110", "10001", "10001", "10001", "10101", "10010", "01101"),
    "R": ("11110", "10001", "10001", "11110", "10100", "10010", "10001"),
    "V": ("10001", "10001", "10001", "10001", "10001", "01010", "00100"),
    "W": ("10001", "10001", "10001", "10101", "10101", "11011", "10001"),
    "X": ("10001", "10001", "01010", "00100", "01010", "10001", "10001"),
    "Z": ("11111", "00001", "00010", "00100", "01000", "10000", "11111"),
    "-": ("00000", "00000", "00000", "11111", "00000", "00000", "00000"),
    ">": ("01000", "00100", "00010", "00001", "00010", "00100", "01000"),
    "<": ("00010", "00100", "01000", "10000", "01000", "00100", "00010"),
    ":": ("00000", "01100", "01100", "00000", "01100", "01100", "00000"),
    "(": ("00010", "00100", "01000", "01000", "01000", "00100", "00010"),
    ")": ("01000", "00100", "00010", "00010", "00010", "00100", "01000"),
    "S": ("01111", "10000", "10000", "01110", "00001", "00001", "11110"),
    "T": ("11111", "00100", "00100", "00100", "00100", "00100", "00100"),
    "U": ("10001", "10001", "10001", "10001", "10001", "10001", "01110"),
    "Y": ("10001", "10001", "01010", "00100", "00100", "00100", "00100"),
    "$": ("00100", "01111", "10100", "01110", "00101", "11110", "00100"),
    "+": ("00000", "00100", "00100", "11111", "00100", "00100", "00000"),
    ".": ("00000", "00000", "00000", "00000", "00000", "01100", "01100"),
    " ": ("00000", "00000", "00000", "00000", "00000", "00000", "00000"),
}


def escribe_texto(lienzo, x, y, texto, color, escala=2):
    """Pinta texto en el lienzo (lista de bytearray RGB), sin antialias."""
    ancho = len(lienzo[0]) // 3
    for c in texto.upper():
        patron = GLIFOS.get(c, GLIFOS[" "])
        for fy, fila in enumerate(patron):
            for fx, bit in enumerate(fila):
                if bit != "1":
                    continue
                for dy in range(escala):
                    for dx in range(escala):
                        px, py = x + fx * escala + dx, y + fy * escala + dy
                        if 0 <= py < len(lienzo) and 0 <= px < ancho:
                            lienzo[py][px * 3:px * 3 + 3] = bytes(color)
        x += 6 * escala


def main():
    if len(sys.argv) < 4:
        sys.exit(__doc__)
    origen, tsv, salida = sys.argv[1], sys.argv[2], sys.argv[3]
    columnas = int(sys.argv[4]) if len(sys.argv) > 4 else 16

    escenas = list(csv.DictReader(open(tsv), delimiter="\t"))
    escenas.sort(key=lambda r: int(r["orden"]))

    # Las capturas se localizan por su LFSR, que es el unico campo del nombre
    # que identifica la escena sin depender de por donde arrancase el recorrido.
    por_lfsr = {}
    for ruta in glob.glob(os.path.join(origen, "escena_*.png")):
        trozos = os.path.basename(ruta)[:-4].split("_")
        if len(trozos) == 3:
            por_lfsr[int(trozos[2], 16)] = ruta
        elif len(trozos) == 2:                      # escena_00.png, el titulo
            por_lfsr.setdefault(int(trozos[1], 16), ruta)

    faltan = [r for r in escenas if int(r["lfsr"], 16) not in por_lfsr]
    if faltan:
        sys.exit("Faltan %d capturas (p.ej. LFSR %s)" % (len(faltan), faltan[0]["lfsr"]))
    print("Escenas: %d   capturas encontradas: %d" % (len(escenas), len(por_lfsr)))

    ALTO_BANDA, BORDE, ALTO_LEYENDA = 22, 4, 96
    miniaturas = []
    for i, r in enumerate(escenas):
        w, h, filas = lee_png(por_lfsr[int(r["lfsr"], 16)])
        mw, mh, mini = recorta_y_reduce(w, h, filas)
        miniaturas.append((r, mw, mh, mini))
        if i % 32 == 0:
            print("  %3d/%d  paso %s -> %dx%d" % (i, len(escenas), r["orden"], mw, mh))

    _, mw, mh, _ = miniaturas[0]
    cw, ch = mw + BORDE * 2, mh + ALTO_BANDA + BORDE * 2
    filas_rejilla = (len(miniaturas) + columnas - 1) // columnas
    W, H = cw * columnas, ch * filas_rejilla + ALTO_LEYENDA
    print("Mapa: %d escenas en %dx%d celdas -> %dx%d pixeles"
          % (len(miniaturas), columnas, filas_rejilla, W, H))

    lienzo = [bytearray(W * 3) for _ in range(H)]

    # La leyenda, arriba del todo: sin ella la rejilla es un mural bonito y
    # nada mas.
    escribe_texto(lienzo, 8, 8, "PITFALL. EL MUNDO ENTERO. 255 ESCENAS EN EL ORDEN "
                                "EN QUE SE RECORREN YENDO A LA DERECHA", (255, 255, 255), 3)
    escribe_texto(lienzo, 8, 34, "CASILLA 0 = LFSR 0XC4, LA SEMILLA QUE PONE INIT. "
                                 "ETIQUETA. PASO.LFSR TIPO", (170, 170, 170), 2)
    x = 8
    for t in range(8):
        nombre, color = TIPOS[t]
        for y in range(58, 78):
            lienzo[y][x * 3:(x + 18) * 3] = bytes(color) * 18
        escribe_texto(lienzo, x + 24, 60, "%d %s" % (t, nombre), color, 2)
        x += 24 + (len(nombre) + 2) * 12 + 20
    escribe_texto(lienzo, x, 60, "32 TESOROS. 8 DE CADA VALOR", (255, 208, 0), 2)

    for n, (r, mw, mh, mini) in enumerate(miniaturas):
        tipo = int(r["tipo"])
        nombre, color = TIPOS[tipo]
        cx, cy = (n % columnas) * cw, (n // columnas) * ch + ALTO_LEYENDA

        for y in range(ch):                          # el marco, del color del tipo
            for x in range(cw):
                dentro = (BORDE <= x < cw - BORDE and
                          BORDE + ALTO_BANDA <= y < ch - BORDE)
                if not dentro:
                    lienzo[cy + y][(cx + x) * 3:(cx + x) * 3 + 3] = bytes(color)

        for y, fila in enumerate(mini):              # la captura
            px = (cx + BORDE) * 3
            lienzo[cy + BORDE + ALTO_BANDA + y][px:px + len(fila)] = fila

        etiqueta = "%03d.%02X %s" % (int(r["orden"]), int(r["lfsr"], 16), nombre)
        if tipo == 5:
            etiqueta += " $%d000" % TESOROS[AEA4[int(r["variante"])]]
        escribe_texto(lienzo, cx + BORDE + 4, cy + BORDE + 2, etiqueta, (0, 0, 0), 2)

    escribe_png(salida, W, H, lienzo)
    print("Escrito %s" % salida)
    return 0


if __name__ == "__main__":
    sys.exit(main())
