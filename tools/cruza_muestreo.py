#!/usr/bin/env python3
"""Cruza los PCs muestreados en el emulador con el trazado: que se ejecuto y
el trazador no alcanza.

    python3 tools/cruza_muestreo.py <trace.json> <muestreo.pcs> [mas .pcs]

Cada PC muestreado es una instruccion que corrio de verdad. Los que caen fuera
de los bloques de codigo del trazado son la mejor semilla posible; se agrupan
en rangos y se da el primero de cada rango, con la cuenta de muestras.
"""
import json
import sys


def main():
    tr = json.load(open(sys.argv[1]))
    codigo = set()
    for k, a, b in tr["blocks"]:
        if k == "c":
            codigo.update(range(a, b))
    vistos = {}
    for f in sys.argv[2:]:
        for ln in open(f):
            pc, n = ln.split()
            vistos[int(pc, 16)] = vistos.get(int(pc, 16), 0) + int(n)
    fuera = sorted(a for a in vistos if a not in codigo)
    dentro = len(vistos) - len(fuera)
    print(f"PCs distintos vistos: {len(vistos)}; dentro del trazado: {dentro}; FUERA: {len(fuera)}")
    rangos = []
    for a in fuera:
        if rangos and a - rangos[-1][1] <= 16:
            rangos[-1][1] = a
            rangos[-1][2] += vistos[a]
            rangos[-1][3] += 1
        else:
            rangos.append([a, a, vistos[a], 1])
    for a, b, n, k in rangos:
        print(f"  {a:#06x}-{b:#06x}  {k:3d} PCs  {n:6d} muestras")


if __name__ == "__main__":
    main()
