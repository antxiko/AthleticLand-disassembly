#!/usr/bin/env python3
"""El guion de la partida perfecta, dibujado: una pantalla por paso.

Toma la ruta que calcula ruta_optima.py y la pinta como un diagrama de flujo
en serpentina -la fila impar se lee al reves, como los bueyes al arar-, con la
captura real de cada pantalla y, debajo, la unica cosa que hay que hacer en
ella. Las flechas van entre casilla y casilla, asi que el recorrido se sigue
con el dedo de principio a fin.

Las capturas no se releen una a una: se sacan del mapa ya montado, que las
tiene todas a media resolucion y en el orden del anillo.

Uso: dibuja_guion.py <mapa_guion.png> <ruta_optima.tsv> <salida.png> [columnas]
"""
import csv
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from monta_mapa import lee_png, escribe_png                     # noqa: E402
from monta_mapa_guion import escribe_texto, TIPOS               # noqa: E402

BORDE, ALTO_BANDA, ALTO_LEYENDA, COLS_MAPA = 4, 22, 96, 16
MW, MH = 320, 239
CABECERA = 126                     # el alto del titulo y la leyenda DE ESTE dibujo


def saca_miniaturas(mapa, cuantas=255):
    """Las 255 escenas del mapa montado, a la mitad otra vez (160x119)."""
    print("Leyendo %s ..." % mapa)
    W, H, filas = lee_png(mapa)
    cw, ch = MW + BORDE * 2, MH + ALTO_BANDA + BORDE * 2
    out = []
    for n in range(cuantas):
        cx = (n % COLS_MAPA) * cw + BORDE
        cy = (n // COLS_MAPA) * ch + ALTO_LEYENDA + BORDE + ALTO_BANDA
        mini = []
        for y in range(0, MH - 1, 2):
            fila = filas[cy + y]
            nueva = bytearray()
            for x in range(cx, cx + MW - 1, 2):
                nueva += fila[x * 3:x * 3 + 3]
            mini.append(nueva)
        out.append(mini)
    return out


def raya(lienzo, x0, y0, x1, y1, color):
    for y in range(min(y0, y1), max(y0, y1) + 1):
        for x in range(min(x0, x1), max(x0, x1) + 1):
            if 0 <= y < len(lienzo) and 0 <= x < len(lienzo[0]) // 3:
                lienzo[y][x * 3:x * 3 + 3] = bytes(color)


def main():
    if len(sys.argv) < 4:
        sys.exit(__doc__)
    mapa, tsv, salida = sys.argv[1], sys.argv[2], sys.argv[3]
    columnas = int(sys.argv[4]) if len(sys.argv) > 4 else 8

    pasos = list(csv.DictReader(open(tsv), delimiter="\t"))

    # Los movimientos de escalera no cruzan pantalla: se pegan como marca a la
    # casilla de la escena donde ocurren, que es donde el jugador tiene que
    # pararse a bajar o a subir.
    celdas, marca = [], None
    for p in pasos:
        if p["accion"] == "escalera":
            marca = "BAJA" if p["nivel_destino"] == "tunel" else "SUBE"
            continue
        celdas.append({
            "orden": int(p["desde"]), "lfsr": p["lfsr"], "tipo": int(p["tipo"]),
            "nivel": p["nivel"], "accion": p["accion"],
            "tesoro": int(p["tesoro"]), "marca": marca,
        })
        marca = None
    # La ultima casilla es la escena en la que se recoge el ultimo tesoro.
    ultimo = pasos[-1]
    celdas.append({
        "orden": int(ultimo["hasta"]), "lfsr": ultimo["lfsr_destino"],
        "tipo": int(ultimo["tipo_destino"]), "nivel": ultimo["nivel_destino"],
        "accion": "fin", "tesoro": int(ultimo["tesoro"]), "marca": marca,
    })
    # El tesoro se recoge AL LLEGAR, asi que la marca va en la casilla siguiente.
    for i in range(len(celdas) - 1, 0, -1):
        celdas[i]["tesoro"] = celdas[i - 1]["tesoro"]
    celdas[0]["tesoro"] = 0

    minis = saca_miniaturas(mapa)
    mw, mh = 160, len(minis[0])
    HUECO, BANDA = 34, 26
    cw, ch = mw + BORDE * 2, mh + BANDA + BORDE * 2
    filas_rejilla = (len(celdas) + columnas - 1) // columnas
    W = columnas * cw + (columnas - 1) * HUECO + 40
    H = CABECERA + filas_rejilla * (ch + HUECO) + 40
    print("Guion: %d pasos en %d columnas -> %dx%d" % (len(celdas), columnas, W, H))

    lienzo = [bytearray(W * 3) for _ in range(H)]
    total = sum(c["tesoro"] for c in celdas)
    escribe_texto(lienzo, 20, 8, "PITFALL. EL GUION DE LA PARTIDA PERFECTA", (255, 255, 255), 4)
    escribe_texto(lienzo, 20, 42,
                  "%d PANTALLAS PARA LOS 32 TESOROS: %d PUNTOS MAS LOS 2000 DE SALIDA"
                  % (len(celdas) - 1, total), (255, 208, 0), 2)
    escribe_texto(lienzo, 20, 60,
                  "SE LEE EN SERPENTINA, SIGUIENDO LAS FLECHAS. SIEMPRE HACIA LA DERECHA.",
                  (170, 170, 170), 2)
    escribe_texto(lienzo, 20, 76,
                  "> CRUZAR POR ARRIBA   >>> CRUZAR POR EL TUNEL (AVANZA TRES ESCENAS)   "
                  "BAJA Y SUBE: LA ESCALERA", (170, 170, 170), 2)
    x = 20
    for t in range(8):
        nombre, color = TIPOS[t]
        for y in range(94, 108):
            lienzo[y][x * 3:(x + 14) * 3] = bytes(color) * 14
        escribe_texto(lienzo, x + 18, 95, nombre, color, 2)
        x += 18 + (len(nombre) + 1) * 12 + 14

    for n, c in enumerate(celdas):
        fila, col = n // columnas, n % columnas
        if fila % 2:                                   # serpentina: se lee al reves
            col = columnas - 1 - col
        cx = 20 + col * (cw + HUECO)
        cy = CABECERA + fila * (ch + HUECO)

        # El marco dice SIEMPRE de que tipo es la escena; que se cruce por el
        # tunel se marca aparte, oscureciendo la banda del rotulo, para no
        # perder de vista lo que hay en esa pantalla.
        _, color = TIPOS[c["tipo"]]
        tunel = c["nivel"] == "tunel"
        for y in range(ch):
            for x in range(cw):
                if not (BORDE <= x < cw - BORDE and BORDE + BANDA <= y < ch - BORDE):
                    fondo = (40, 40, 40) if (tunel and y < BORDE + BANDA) else color
                    lienzo[cy + y][(cx + x) * 3:(cx + x) * 3 + 3] = bytes(fondo)
        for y, f in enumerate(minis[c["orden"]]):
            px = (cx + BORDE) * 3
            lienzo[cy + BORDE + BANDA + y][px:px + len(f)] = f

        if c["accion"] == "fin":
            texto = "%03d FIN" % n
        elif n == 0:
            texto = "000 SALIDA"
        elif tunel:
            texto = "%03d >>>" % n
        else:
            texto = "%03d >" % n
        if c["marca"]:
            texto += " " + c["marca"]
        escribe_texto(lienzo, cx + BORDE + 4, cy + BORDE + 4, texto,
                      (255, 255, 255) if tunel else (0, 0, 0), 2)

        if c["tesoro"]:
            escribe_texto(lienzo, cx + BORDE + 6, cy + BORDE + BANDA + 6,
                          "$%d" % c["tesoro"], (255, 208, 0), 3)
            for g in range(3):                         # doble marco para el tesoro
                for y in range(ch):
                    for x in range(cw):
                        if (BORDE + g <= x < cw - BORDE - g and
                                BORDE + BANDA + g <= y < ch - BORDE - g and
                                (x in (BORDE + g, cw - BORDE - g - 1) or
                                 y in (BORDE + BANDA + g, ch - BORDE - g - 1))):
                            lienzo[cy + y][(cx + x) * 3:(cx + x) * 3 + 3] = bytes((255, 208, 0))

        if n == len(celdas) - 1:
            continue
        # La flecha al paso siguiente: horizontal dentro de la fila, y vertical
        # cuando la serpentina cambia de renglon.
        blanco = (255, 255, 255)
        if (n + 1) // columnas == fila:
            if fila % 2 == 0:
                x0, x1 = cx + cw, cx + cw + HUECO
            else:
                x0, x1 = cx - HUECO, cx
            y = cy + ch // 2
            raya(lienzo, x0, y - 1, x1, y + 1, blanco)
            for i in range(8):                          # la punta
                px = x1 - i if fila % 2 == 0 else x0 + i
                raya(lienzo, px, y - i // 2, px, y + i // 2, blanco)
        else:
            x = cx + cw // 2
            raya(lienzo, x - 1, cy + ch, x + 1, cy + ch + HUECO, blanco)
            for i in range(8):
                raya(lienzo, x - i // 2, cy + ch + HUECO - i, x + i // 2,
                     cy + ch + HUECO - i, blanco)

    escribe_png(salida, W, H, lienzo)
    print("Escrito %s" % salida)
    return 0


if __name__ == "__main__":
    sys.exit(main())
