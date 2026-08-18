#!/usr/bin/env python3
"""En que escenas se puede bajar al subterraneo: las escaleras, contadas.

Hace falta para la ruta optima. El subterraneo recorre el mundo al triple
(0x9CBE avanza el LFSR tres pasos en vez de uno cuando el bit 0 de 0xE2EB
esta a cero), asi que el atajo vale oro; pero solo sirve si se puede bajar,
y para bajar hace falta una escalera.

En vez de suponerlo, se mide sobre las capturas del mapa ya montado: en la
franja del tunel, una escalera es una columna con MUCHAS transiciones de
negro a color -es un dibujo a rayas-, mientras que la pared de ladrillo es
un bloque macizo y da una o dos. Se cuenta columna a columna y se cruza con
el tipo de escena.

Uso: busca_escaleras.py <mapa_guion.png> <mapa_escenas.tsv> [salida.tsv]
"""
import collections
import csv
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from monta_mapa import lee_png                                  # noqa: E402

BORDE, ALTO_BANDA, ALTO_LEYENDA, COLUMNAS = 4, 22, 96, 16
MW, MH = 320, 239                       # tamano de la miniatura de cada celda
# La franja del tunel dentro de la miniatura, medida sobre una captura: el
# hueco negro que hay debajo del suelo de la selva.
TUNEL_Y0, TUNEL_Y1 = 168, 198
NEGRO = 40                              # por debajo de esto se considera fondo


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    mapa, tsv = sys.argv[1], sys.argv[2]
    salida = sys.argv[3] if len(sys.argv) > 3 else None

    escenas = sorted(csv.DictReader(open(tsv), delimiter="\t"),
                     key=lambda r: int(r["orden"]))
    print("Leyendo %s ..." % mapa)
    W, H, filas = lee_png(mapa)
    cw, ch = MW + BORDE * 2, MH + ALTO_BANDA + BORDE * 2

    resultados = []
    for n, r in enumerate(escenas):
        cx = (n % COLUMNAS) * cw + BORDE
        cy = (n // COLUMNAS) * ch + ALTO_LEYENDA + BORDE + ALTO_BANDA
        mejor = 0
        for x in range(cx, cx + MW):
            transiciones, previo = 0, True
            for y in range(cy + TUNEL_Y0, cy + TUNEL_Y1):
                px = filas[y][x * 3:x * 3 + 3]
                oscuro = max(px) < NEGRO
                if previo and not oscuro:
                    transiciones += 1
                previo = oscuro
            mejor = max(mejor, transiciones)
        resultados.append((r, mejor))

    # El corte no se elige a ojo: la medida sale BIMODAL y sin un solo caso
    # intermedio. Las 255 escenas dan o bien 8 rayas o bien 3, nada entre medias,
    # asi que cualquier umbral de 4 a 8 reparte igual. Las de 8 son las 63 de
    # tipo 0 y 1; las de 3 son las otras 192, donde lo que se cuenta es el
    # sprite que ronda el tunel, no una escalera.
    UMBRAL = 5
    por_tipo = collections.defaultdict(lambda: [0, 0])
    for r, t in resultados:
        por_tipo[int(r["tipo"])][0 if t >= UMBRAL else 1] += 1

    print("\n  tipo              con escalera / sin escalera")
    for t in sorted(por_tipo):
        con, sin = por_tipo[t]
        print("    %d  %-12s        %3d / %3d" % (t, "", con, sin))
    total = sum(v[0] for v in por_tipo.values())
    print("\n  escenas con escalera: %d de %d" % (total, len(resultados)))

    if salida:
        with open(salida, "w", newline="") as f:
            w = csv.writer(f, delimiter="\t")
            w.writerow(["orden", "lfsr", "tipo", "variante", "rayas", "escalera"])
            for r, t in resultados:
                w.writerow([r["orden"], r["lfsr"], r["tipo"], r["variante"],
                            t, 1 if t >= UMBRAL else 0])
        print("  Escrito %s" % salida)
    return 0


if __name__ == "__main__":
    sys.exit(main())
