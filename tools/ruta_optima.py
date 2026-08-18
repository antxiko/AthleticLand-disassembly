#!/usr/bin/env python3
"""La ruta minima para llevarse los 32 tesoros: el guion de la partida perfecta.

TODO lo que usa esta calculado sobre el cartucho, no sobre una partida:

  - EL ORDEN DEL MUNDO. Las 255 escenas salen del LFSR de 0xE222 (semilla
    0xC4, realimentacion b7^b5^b4^b3), simulado y contrastado escena a escena
    contra el emulador: 255 de 255.
  - LOS 32 TESOROS son las 32 escenas de tipo 5 (bits 3-5 del LFSR). Su valor
    lo escribe cada rutina en 0xE188 antes de pintarlo: 2, 3, 4 o 5, o sea
    2000, 3000, 4000 y 5000 puntos, ocho de cada uno.
  - EL MOVIMIENTO lo dicta 0x9CBE: al tocar el borde, el registro de pantalla
    avanza UN paso o TRES segun el bit 0 de 0xE2EB. Tres es el subterraneo,
    que por eso recorre el mundo al triple. La rutina de la izquierda es
    simetrica, con la funcion inversa del registro.
  - LAS ESCALERAS estan medidas sobre las 255 capturas (busca_escaleras.py) y
    salen exactamente en los tipos 0 y 1: 63 escenas y ni una mas. Son los
    unicos sitios por donde se baja y se sube.

LO QUE AQUI ES MODELO Y NO MEDIDA: el coste se cuenta en PANTALLAS CRUZADAS,
que es lo unico que el binario fija. El tiempo real de cada pantalla depende
de correr, saltar y esquivar, y eso no esta en estas cuentas. Bajar o subir
una escalera se cuenta como gratis.

Uso: ruta_optima.py <mapa_escenas.tsv> <escaleras.tsv> [salida.tsv]
"""
import csv
import heapq
import os
import sys

N = 255
ARRIBA, TUNEL = 0, 1
AEA4 = [0xAC11, 0xAB51, 0xAB1B, 0xABB7, 0xAC11, 0xAB51, 0xAB1B, 0xABB7]
VALOR = {0xAB1B: 4000, 0xAB51: 3000, 0xABB7: 5000, 0xAC11: 2000}


def vecinos(p, nivel, escalera):
    """Los movimientos que el juego permite desde una escena."""
    salto = 1 if nivel == ARRIBA else 3
    yield ((p + salto) % N, nivel), 1, "derecha"
    yield ((p - salto) % N, nivel), 1, "izquierda"
    if escalera[p]:                       # bajar o subir, solo donde hay escalera
        yield (p, TUNEL if nivel == ARRIBA else ARRIBA), 0, "escalera"


def dijkstra(origen, escalera):
    """Coste minimo desde un estado a todos los demas, con el camino."""
    dist = {origen: 0}
    previo = {}
    cola = [(0, origen)]
    while cola:
        d, u = heapq.heappop(cola)
        if d > dist.get(u, 1 << 30):
            continue
        for v, coste, como in vecinos(u[0], u[1], escalera):
            nd = d + coste
            if nd < dist.get(v, 1 << 30):
                dist[v] = nd
                previo[v] = (u, como)
                heapq.heappush(cola, (nd, v))
    return dist, previo


def camino(previo, origen, destino):
    pasos, actual = [], destino
    while actual != origen:
        anterior, como = previo[actual]
        pasos.append((anterior, como, actual))
        actual = anterior
    return list(reversed(pasos))


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    tsv_escenas, tsv_escaleras = sys.argv[1], sys.argv[2]
    salida = sys.argv[3] if len(sys.argv) > 3 else None

    escenas = sorted(csv.DictReader(open(tsv_escenas), delimiter="\t"),
                     key=lambda r: int(r["orden"]))
    escalera = [False] * N
    for r in csv.DictReader(open(tsv_escaleras), delimiter="\t"):
        escalera[int(r["orden"])] = r["escalera"] == "1"

    tipo = [int(r["tipo"]) for r in escenas]
    lfsr = [int(r["lfsr"], 16) for r in escenas]
    tesoros = [(int(r["orden"]), VALOR[AEA4[int(r["variante"])]])
               for r in escenas if int(r["tipo"]) == 5]
    print("Tesoros: %d, valor total %d puntos" % (len(tesoros), sum(v for _, v in tesoros)))
    print("Escaleras: %d escenas\n" % sum(escalera))

    # En un anillo, la ruta que visita todos los tesoros los recorre en su
    # orden; lo unico que queda por decidir es QUE HUECO no se cruza nunca.
    # Eso es exactamente enumerar las particiones "a la derecha hasta el tesoro
    # i, media vuelta, y el resto barrido por la izquierda" (con las dos puntas
    # como casos: corte=32 es todo a la derecha y corte=0 todo a la izquierda).
    # Entre tesoro y tesoro, el camino minimo lo da Dijkstra, que es donde el
    # subterraneo hace su trabajo. Probarlas todas costo UNA pantalla: la ruta
    # todo-a-la-derecha daba 190, y la de "derecha hasta el primero y vuelta"
    # da 189, que es el minimo del modelo.
    posiciones = [t[0] for t in sorted(tesoros)]
    valor_de = dict(tesoros)

    def mejor_particion(escalera):
        cache = {}

        def desde(a):
            if a not in cache:
                cache[a] = dijkstra((a, ARRIBA), escalera)
            return cache[a]

        mejor = None
        for corte in range(len(posiciones) + 1):
            orden = posiciones[:corte] + list(reversed(posiciones[corte:]))
            total, actual = 0, 0
            for p in orden:
                total += desde(actual)[0][(p, ARRIBA)]
                actual = p
            if mejor is None or total < mejor[0]:
                mejor = (total, corte, orden, desde)
        return mejor

    total, corte, orden, desde = mejor_particion(escalera)
    tramos, actual = [], (0, ARRIBA)
    for pos in orden:
        dist, previo = desde(actual[0])
        destino = (pos, ARRIBA)
        tramos.append((camino(previo, actual, destino), pos, valor_de[pos]))
        actual = destino
    nombre = ("derecha" if corte == len(posiciones) else
              "izquierda" if corte == 0 else
              "derecha hasta el paso %d y vuelta" % orden[corte - 1])

    # La mejor ruta posible SIN bajar nunca al subterraneo, para comparar.
    solo_arriba = mejor_particion([False] * N)[0]

    todo_derecha = sum(desde(a)[0][(b, ARRIBA)] for a, b in
                       zip([0] + posiciones[:-1], posiciones))
    print("\n  GANA: %s, %d pantallas (todo a la derecha serian %d)"
          % (nombre, total, todo_derecha))
    print("  Sin usar el subterraneo serian %d: el atajo ahorra %d (%d %%)"
          % (solo_arriba, solo_arriba - total,
             round(100 * (solo_arriba - total) / solo_arriba)))

    # El guion, paso a paso.
    guion = []
    for pasos, pos_tesoro, valor in tramos:
        for (p, niv), como, (p2, niv2) in pasos:
            guion.append({
                "desde": p, "nivel": niv, "hasta": p2, "nivel_destino": niv2,
                "accion": como, "lfsr": lfsr[p], "tipo": tipo[p],
                "lfsr_destino": lfsr[p2], "tipo_destino": tipo[p2],
                "tesoro": 0,
            })
        if guion:
            guion[-1]["tesoro"] = valor

    print("\n  El guion son %d movimientos (%d de ellos por el subterraneo)"
          % (len([g for g in guion if g["accion"] != "escalera"]),
             len([g for g in guion if g["accion"] != "escalera" and g["nivel"] == TUNEL])))

    if salida:
        with open(salida, "w", newline="") as f:
            w = csv.writer(f, delimiter="\t")
            w.writerow(["n", "desde", "lfsr", "tipo", "nivel", "accion",
                        "hasta", "lfsr_destino", "tipo_destino", "nivel_destino",
                        "tesoro"])
            for i, g in enumerate(guion):
                w.writerow([i, g["desde"], "0x%02X" % g["lfsr"], g["tipo"],
                            "tunel" if g["nivel"] else "arriba", g["accion"],
                            g["hasta"], "0x%02X" % g["lfsr_destino"],
                            g["tipo_destino"],
                            "tunel" if g["nivel_destino"] else "arriba",
                            g["tesoro"]])
        print("  Escrito %s" % salida)
    return 0


if __name__ == "__main__":
    sys.exit(main())
