#!/usr/bin/env python3
"""Busca escrituras a la ROM: el efecto de una proteccion, no una forma concreta.

    python3 tools/busca_autoescritura.py

POR QUE ESTA HERRAMIENTA. En esta serie de desensamblados, la primera vez que
se busco una proteccion anticopia se busco UN PATRON concreto de instrucciones,
y de no encontrarlo se concluyo que no habia proteccion. Eso no se sigue: basta
con otro orden de registros, otra longitud o un mecanismo distinto para que la
busqueda no vea nada. Buscar una forma solo sirve para confirmar que ESA forma
no esta.

Asi que aqui se busca el EFECTO, que es lo que define una proteccion de este
tipo: **escribir en una direccion que en un cartucho de verdad es ROM**. Si el
juego corre desde el cartucho, la escritura se pierde y no pasa nada; si corre
desde una copia en RAM, cae, y lo que caiga encima decide si el juego se mata.

EL MAPA DE ESTE CARTUCHO: la ROM ocupa la pagina 2 (0x8000-0xBFFF) y la RAM
del MSX va de 0xC000 hacia arriba. O sea que TODO lo que escriba por debajo de
0xC000 escribe en algo que no es RAM: la BIOS (0x0000-0x3FFF), la pagina 1
(0x4000-0x7FFF, donde no hay nada mapeado) o el propio cartucho
(0x8000-0xBFFF).

Se recorre solo el codigo que el trazador alcanza, instruccion a instruccion, y
se marca todo lo que escriba por debajo de 0xC000:

  - `ld (nn),a` y `ld (nn),hl`, y los `ld (nn),rr` con prefijo ED;
  - LDIR y LDDR, mirando hacia atras que se cargo en DE: si el destino es un
    inmediato por debajo de 0xC000, esa copia va a la ROM;
  - `ld (hl),n` y `ld (hl),r` cuando HL se acaba de cargar con un inmediato de
    esa zona.

Y de propina se buscan las LECTURAS de la propia ROM que puedan ser una
comprobacion: un `ld a,(nn)` con nn dentro del cartucho seguido de un `cp`.

Lo que salga hay que LEERLO. Esta herramienta no dice que algo sea una
proteccion: dice donde hay una escritura que en ROM no hace nada, que es el
sitio donde mirar.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import z80trace

ORG = 0x8000
TAM = 0x4000
RAM = 0xC000                      # de aqui hacia arriba si es RAM


def instrucciones(d, blocks, t):
    """(direccion, longitud) de cada instruccion del codigo trazado."""
    out = []
    for tipo, a, b in blocks:
        if tipo != "c":
            continue
        p = a
        while p < b:
            n = t.ilen(p)
            if not n:
                break
            out.append((p, n))
            p += n
    return out


def analiza():
    with open("pitfall.rom", "rb") as f:
        d = f.read()
    t = z80trace.Tracer(d, ORG)
    blocks = json.load(open("work/pitfall.trace.json"))["blocks"]
    ins = instrucciones(d, blocks, t)
    pos = {a: i for i, (a, n) in enumerate(ins)}

    def by(a):
        return d[a - ORG]

    def wd(a):
        return d[a - ORG] | d[a + 1 - ORG] << 8

    hallazgos = []

    for i, (a, n) in enumerate(ins):
        op = by(a)

        # ld (nn),a / ld (nn),hl
        if op in (0x32, 0x22):
            nn = wd(a + 1)
            if nn < RAM:
                hallazgos.append((a, "ld (%04Xh),%s" % (nn, "a" if op == 0x32 else "hl"),
                                  nn, "escritura directa"))
        # ED 43/53/63/73: ld (nn),rr
        if op == 0xED and by(a + 1) in (0x43, 0x53, 0x63, 0x73):
            nn = wd(a + 2)
            if nn < RAM:
                hallazgos.append((a, "ld (%04Xh),rr" % nn, nn, "escritura directa"))

        # LDIR / LDDR: se mira hacia atras el ultimo ld de,nn
        if op == 0xED and by(a + 1) in (0xB0, 0xB8):
            destino = None
            for j in range(i - 1, max(-1, i - 8), -1):
                aj = ins[j][0]
                if by(aj) == 0x11:                      # ld de,nn
                    destino = wd(aj + 1)
                    break
            if destino is not None and destino < RAM:
                hallazgos.append((a, "ldir/lddr con de=%04Xh" % destino,
                                  destino, "copia a la ROM"))

        # ld (hl),n / ld (hl),r con HL cargado con un inmediato de la zona
        if op == 0x36 or (0x70 <= op <= 0x77 and op != 0x76):
            destino = None
            for j in range(i - 1, max(-1, i - 5), -1):
                aj = ins[j][0]
                if by(aj) == 0x21:                      # ld hl,nn
                    destino = wd(aj + 1)
                    break
            if destino is not None and destino < RAM:
                hallazgos.append((a, "ld (hl),.. con hl=%04Xh" % destino,
                                  destino, "escritura por HL"))

        # Posible comprobacion: ld a,(nn) del propio cartucho seguido de cp
        if op == 0x3A:
            nn = wd(a + 1)
            if ORG <= nn < ORG + TAM and i + 1 < len(ins) and by(ins[i + 1][0]) == 0xFE:
                hallazgos.append((a, "ld a,(%04Xh) / cp" % nn, nn,
                                  "lee la ROM y compara"))
    return hallazgos


def main():
    h = analiza()
    print("=" * 70)
    print(" %d escrituras a memoria por debajo de 0xC000" % len(h))
    print("=" * 70)
    for a, texto, destino, clase in h:
        if destino < 0x4000:
            zona = "BIOS"
        elif destino < 0x8000:
            zona = "PAGINA 1, sin nada mapeado"
        else:
            zona = "EL PROPIO CARTUCHO"
        print("   0x%04X  %-26s -> 0x%04X (%s)  %s"
              % (a, texto, destino, zona, clase))
    if not h:
        print("   ninguna")
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
