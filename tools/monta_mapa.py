#!/usr/bin/env python3
"""Monta el mapa del mundo con las capturas de las 255 escenas.

Las capturas las hace el propio juego (tools/omsx_mapa_lfsr.tcl le dicta al
LFSR de 0xE222 que escena montar y le pide una foto a cada una), asi que aqui
solo hay recorte y pegado: ni un pixel se reinterpreta.

De cada captura de 640x480 se queda con el area util, se reduce a la mitad y
se pegan todas en una rejilla, en el ORDEN DEL ANILLO, que es el orden en que
el mundo se recorre yendo siempre a la derecha. Con la rejilla al lado del
listado se ve de un vistazo lo que el LFSR reparte: cuatro decorados y ocho
tipos de escena barajados sin repetir ninguna combinacion.

No usa PIL -no esta instalado en esta maquina- sino un lector y un escritor
de PNG minimos sobre zlib, que para imagenes RGB de 8 bits sin entrelazar es
media pagina de codigo.

Uso: monta_mapa.py <dir_capturas> <salida.png> [ancho_en_escenas]
"""
import glob
import os
import struct
import sys
import zlib


def lee_png(ruta):
    """(ancho, alto, filas RGB) de un PNG de 8 bits sin entrelazar."""
    with open(ruta, "rb") as f:
        datos = f.read()
    if datos[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("%s no es un PNG" % ruta)
    p = 8
    idat = bytearray()
    w = h = tipo = None
    while p < len(datos):
        (largo,) = struct.unpack(">I", datos[p:p + 4])
        clase = datos[p + 4:p + 8]
        cuerpo = datos[p + 8:p + 8 + largo]
        if clase == b"IHDR":
            w, h, prof, tipo = struct.unpack(">IIBB", cuerpo[:10])
            if prof != 8 or tipo not in (2, 6):
                raise ValueError("%s: solo RGB/RGBA de 8 bits (tipo %d, prof %d)"
                                 % (ruta, tipo, prof))
        elif clase == b"IDAT":
            idat += cuerpo
        elif clase == b"IEND":
            break
        p += 12 + largo

    canales = 3 if tipo == 2 else 4
    crudo = zlib.decompress(bytes(idat))
    ancho_linea = w * canales
    filas, prev = [], bytearray(ancho_linea)
    q = 0
    for _ in range(h):
        filtro = crudo[q]
        linea = bytearray(crudo[q + 1:q + 1 + ancho_linea])
        q += 1 + ancho_linea
        for i in range(ancho_linea):
            a = linea[i - canales] if i >= canales else 0
            b = prev[i]
            c = prev[i - canales] if i >= canales else 0
            x = linea[i]
            if filtro == 1:
                x += a
            elif filtro == 2:
                x += b
            elif filtro == 3:
                x += (a + b) >> 1
            elif filtro == 4:
                pa, pb, pc = abs(b - c), abs(a - c), abs(a + b - 2 * c)
                x += a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
            linea[i] = x & 0xFF
        prev = linea
        if canales == 4:                      # se tira el alfa: las capturas son opacas
            linea = bytearray(b for i, b in enumerate(linea) if i % 4 != 3)
        filas.append(linea)
    return w, h, filas


def escribe_png(ruta, w, h, filas, alfa=False):
    """Con alfa=True las filas llevan cuatro bytes por pixel en vez de tres.

    Hace falta para los sprites: un sprite tiene fondo transparente, y guardarlo
    como negro lo convierte en un rectangulo negro en cuanto la pagina que lo
    ensena no tiene el fondo negro.
    """
    crudo = bytearray()
    for fila in filas:
        crudo.append(0)                       # filtro 0: sin filtrar
        crudo += fila
    def trozo(clase, cuerpo):
        return (struct.pack(">I", len(cuerpo)) + clase + cuerpo +
                struct.pack(">I", zlib.crc32(clase + cuerpo) & 0xFFFFFFFF))
    with open(ruta, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(trozo(b"IHDR", struct.pack(">IIBBBBB", w, h, 8,
                                           6 if alfa else 2, 0, 0, 0)))
        f.write(trozo(b"IDAT", zlib.compress(bytes(crudo), 9)))
        f.write(trozo(b"IEND", b""))


def recorta_y_reduce(w, h, filas):
    """El area util de la captura, a la mitad de tamano.

    openMSX entrega 640x480 con banda negra arriba y abajo; el area de la
    pantalla del MSX es la franja central. Se recorta por deteccion: la
    primera y la ultima fila que no sean enteramente negras.
    """
    def negra(fila):
        return not any(fila)
    y0 = 0
    while y0 < h and negra(filas[y0]):
        y0 += 1
    y1 = h - 1
    while y1 > y0 and negra(filas[y1]):
        y1 -= 1
    alto = y1 - y0 + 1
    out = []
    for y in range(y0, y0 + alto - 1, 2):     # una fila de cada dos
        fila = filas[y]
        nueva = bytearray()
        for x in range(0, w - 1, 2):          # una columna de cada dos
            nueva += fila[x * 3:x * 3 + 3]
        out.append(nueva)
    return w // 2, len(out), out


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    origen, salida = sys.argv[1], sys.argv[2]
    columnas = int(sys.argv[3]) if len(sys.argv) > 3 else 8

    # Las capturas van numeradas por el orden del anillo: escena_NNN_VV.png.
    # Se descarta el estado 0x00, que es la pantalla del titulo y no pertenece
    # al anillo, y cualquier captura suelta sin numero de orden.
    rutas = sorted(r for r in glob.glob(os.path.join(origen, "escena_[0-9][0-9][0-9]_*.png"))
                   if not r.endswith("_00.png"))
    if not rutas:
        sys.exit("No hay capturas en %s" % origen)
    print("Capturas encontradas: %d" % len(rutas))

    miniaturas = []
    for i, ruta in enumerate(rutas):
        w, h, filas = lee_png(ruta)
        mw, mh, mini = recorta_y_reduce(w, h, filas)
        miniaturas.append(mini)
        if i % 32 == 0:
            print("  %3d/%d  %s -> %dx%d" % (i, len(rutas), os.path.basename(ruta), mw, mh))

    mw = len(miniaturas[0][0]) // 3
    mh = len(miniaturas[0])
    filas_rejilla = (len(miniaturas) + columnas - 1) // columnas
    W, H = mw * columnas, mh * filas_rejilla
    print("Mapa: %d escenas en %dx%d celdas -> %dx%d pixeles"
          % (len(miniaturas), columnas, filas_rejilla, W, H))

    lienzo = [bytearray(W * 3) for _ in range(H)]
    for n, mini in enumerate(miniaturas):
        cx, cy = (n % columnas) * mw, (n // columnas) * mh
        for y, fila in enumerate(mini):
            lienzo[cy + y][cx * 3:cx * 3 + len(fila)] = fila

    escribe_png(salida, W, H, lienzo)
    print("Escrito %s" % salida)
    return 0


if __name__ == "__main__":
    sys.exit(main())
