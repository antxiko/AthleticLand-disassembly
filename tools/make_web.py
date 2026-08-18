#!/usr/bin/env python3
"""Genera la portada de la web, en los dos idiomas.

El diseno es el compartido por la serie (tools/estilo_web.py) y la pagina sale
autocontenida, con las imagenes embebidas como data URI.

Ni el rotulo de la cabecera ni la galeria son ilustraciones traidas de fuera:
salen de las capturas que hace el propio cartucho corriendo en openMSX. El
rotulo es su pantalla de presentacion recortada, y la galeria son ocho
pantallas de partida, una por TIPO DE ESCENA, elegidas cruzando el valor del
LFSR de pantalla con la tabla que genera tools/mapa_escenas.py. O sea que si
la lectura del mundo estuviera mal, la galeria saldria descuadrada.

OJO CON EL NOMBRE DE LAS CAPTURAS: `escena_NNN_VV.png` lleva DOS numeros, y el
bueno es VV, el valor del LFSR. NNN va corrido uno, porque el recorrido del
emulador fotografia despues de dar el paso. Aqui se cruza siempre por VV.

Uso: make_web.py <work/omsx> <work/mapa_escenas.tsv> <docs/imagenes>
                 <salida.html> <idioma>
"""
import base64
import csv
import glob
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from estilo_web import ESTILO                                   # noqa: E402
from monta_mapa import lee_png, escribe_png, recorta_y_reduce   # noqa: E402

# Las cifras de la portada salen de contar sobre el listado generado, no de
# escribirlas aqui a ojo: 16384 = 9467 + 6917, que es lo que imprime
# tools/presupuesto.py. Los rotulos se formatean a partir de estos numeros
# para que no puedan quedarse desfasados por su cuenta.
CODIGO = 9467
DATOS = 6917
ESCENAS = 255                       # el anillo del LFSR de 0xE222, sin el 0x00
TESOROS = 32                        # las 32 escenas de tipo 5


def mil(n, idioma):
    return f"{n:,}".replace(",", "." if idioma == "es" else ",")


TXT = {
    "es": dict(
        titulo="Pitfall! (1984) — desensamblado comentado",
        aviso="<b>La ruta óptima es un cálculo, no una partida grabada.</b> "
              "Las 189 pantallas del guion salen de recorrer el mundo que "
              "genera el cartucho con sus propias reglas, contadas en "
              "PANTALLAS CRUZADAS: el reloj, saltar y esquivar no entran, y "
              "la escalera se cuenta gratis. Todo lo demás —el listado, las "
              "cifras y el mapa— sale del binario y se reproduce con "
              "<code>make</code>.",
        claim="Un cartucho de 16 KB de 1984, desmontado byte a byte. "
              "Dentro no hay ni un mapa guardado: las 255 pantallas de la "
              "selva las va inventando un registro de ocho bits, los 32 "
              "tesoros son exactamente las 32 escenas de un tipo, y la liana "
              "no está dibujada en ninguna parte.",
        ficha=["Activision · <b>1984</b>", "Cartucho de <b>16 KB</b>",
               "MSX1 · <b>página 2</b>", "Volcado <b>4d899d62…</b>"],
        nav=[("#numbers", "Las cifras"), ("#findings", "Hallazgos"),
             ("#screens", "El mundo")],
        docnav=[("EMPEZAR.html", "Empezar"), ("EL-JUEGO.html", "El juego"),
                ("EL-CARTUCHO.html", "El cartucho"),
                ("EL-CODIGO.html", "El código"),
                ("HALLAZGOS.html", "Hallazgos"),
                ("PREGUNTAS-ABIERTAS.html", "Preguntas abiertas")],
        otro=("../", "In English"),
        h_num="El juego en cifras", h_find="Lo que apareció al desmontarlo",
        h_scr="Los ocho tipos de escena",
        cifras=[("100 %", "del binario explicado"),
                (str(ESCENAS), "escenas del mundo"),
                (str(TESOROS), "tesoros escondidos"),
                (mil(CODIGO, "es"), "bytes de código"),
                (mil(DATOS, "es"), "bytes de datos"),
                ("0", "bytes sin identificar")],
        nota_scr="Capturas del emulador, pero no de jugar: se le dicta el "
                 "valor del registro de pantalla y se le pide una foto de "
                 "cada escena. Aquí hay una de cada tipo, elegida cruzando el "
                 "valor del registro con la tabla que sale del cartucho: si "
                 "esa lectura estuviera mal, debajo de cada pie se vería otra "
                 "cosa.",
        pie_leg="Esto es trabajo de documentación y preservación sobre un "
                "juego de 1984: el código y los gráficos siguen siendo de sus "
                "autores y de Activision, y la imagen del cartucho no se "
                "distribuye.",
    ),
    "en": dict(
        titulo="Pitfall! (1984) — a commented disassembly",
        aviso="<b>The optimal route is a calculation, not a recorded game.</b> "
              "The 189 screens of the walkthrough come from walking the world "
              "the cartridge generates with its own rules, counted in SCREENS "
              "CROSSED: the clock, jumping and dodging are not in it, and "
              "ladders are counted as free. Everything else —the listing, the "
              "numbers and the map— comes from the binary and is reproducible "
              "with <code>make</code>.",
        claim="A 16 KB cartridge from 1984, taken apart byte by byte. "
              "There's no map stored inside it: the jungle's 255 screens are "
              "made up as it goes by an eight-bit register, the 32 treasures "
              "are exactly the 32 scenes of one type, and the vine isn't drawn "
              "anywhere at all.",
        ficha=["Activision · <b>1984</b>", "A <b>16 KB</b> cartridge",
               "MSX1 · <b>page 2</b>", "Dump <b>4d899d62…</b>"],
        nav=[("#numbers", "The numbers"), ("#findings", "What turned up"),
             ("#screens", "The world")],
        docnav=[("GETTING-STARTED.html", "Getting started"),
                ("THE-GAME.html", "The game"),
                ("THE-CARTRIDGE.html", "The cartridge"),
                ("THE-CODE.html", "The code"),
                ("FINDINGS.html", "Findings"),
                ("OPEN-QUESTIONS.html", "Open questions")],
        otro=("es/", "En castellano"),
        h_num="The game in numbers", h_find="What turned up when we took it apart",
        h_scr="The eight kinds of scene",
        cifras=[("100%", "of the binary explained"),
                (str(ESCENAS), "scenes in the world"),
                (str(TESOROS), "treasures hidden"),
                (mil(CODIGO, "en"), "bytes of code"),
                (mil(DATOS, "en"), "bytes of data"),
                ("0", "bytes unidentified")],
        nota_scr="Emulator captures, but not of anyone playing: it is told "
                 "what to put in the screen register and asked for a "
                 "photograph of each scene. Here is one of each kind, picked "
                 "by crossing the register value with the table that comes "
                 "out of the cartridge: get that reading wrong and what sits "
                 "under each caption would be something else.",
        pie_leg="This is documentation and preservation work on a 1984 game: "
                "the code and artwork still belong to their authors and to "
                "Activision, and the cartridge image is not distributed.",
    ),
}

HALLAZGOS = {
    "es": [
        ("El mundo no está guardado: se genera",
         "<p>No hay un mapa en el cartucho. Las 255 pantallas salen de un solo "
         "byte, 0xE222, que es un registro de desplazamiento realimentado: la "
         "semilla es 0xC4 y la realimentación, los bits 7, 5, 4 y 3. Al salir "
         "por la derecha lo avanza 0xB68F y al salir por la izquierda lo "
         "retrocede 0xB69F, que es su inversa exacta.</p>"
         "<p>De esos ocho bits salen las tres decisiones de cada pantalla: dos "
         "bits eligen el decorado, tres el tipo de escena y tres la variante. "
         "El anillo es máximo —255 estados, el 0x00 se queda fuera y es el que "
         "usa la pantalla del título— y la simulación coincide con el emulador "
         "en las 255.</p>"),
        ("Los 32 tesoros son exactamente las 32 escenas de un tipo",
         "<p>El tipo 5 es el único que despacha por la tabla 0xAEA4, que lleva "
         "cuatro rutinas repetidas de dos en dos. Como las ocho variantes se "
         "reparten a cuatro escenas cada una, sale un tesoro de cada clase "
         "ocho veces: 8+8+8+8 = 32, y ni uno más.</p>"
         "<p>Cada rutina escribe en 0xE188 lo que vale el suyo —2, 3, 4 o 5, o "
         "sea miles de puntos—, así que el mundo entero guarda "
         "8·(2000+3000+4000+5000) = 112000 puntos. Con los 2000 con los que "
         "arranca el marcador, <b>114000: el techo del juego</b>.</p>"),
        ("Al tesoro ya cogido se le come la dirección de retorno",
         "<p>Lo recogido se recuerda en 32 bits, 0xE21D-0xE220: un byte por "
         "clase de tesoro y un bit por tesoro. Antes de pintar uno, 0xAAFF "
         "rota su bit hasta el acarreo.</p>"
         "<p>Y si estaba a uno no salta ni pone una bandera: hace "
         "<code>pop hl</code> y <code>ret</code>. Se traga la dirección de "
         "retorno del que le llamó, y la rutina que pintaba el tesoro no "
         "llega a ejecutarse.</p>"),
        ("El subterráneo recorre el mundo al triple",
         "<p>El cambio de pantalla lo hace 0x9CBE: cuando la X del jugador "
         "llega al borde derecho lo reposiciona al otro lado y avanza el "
         "registro de pantalla. Pero avanza <b>uno o tres pasos</b> según el "
         "bit 0 de 0xE2EB, que es el que dice si se va por arriba o por el "
         "túnel. La rutina de la izquierda es simétrica.</p>"
         "<p>La ruta que se lleva los 32 tesoros baja siempre que puede: 189 "
         "pantallas con el túnel contra 238 sin bajar, un 21 % menos. Solo se "
         "baja por una escalera, y las escaleras están medidas sobre las 255 "
         "capturas: las 63 escenas de tipos 0 y 1.</p>"),
        ("La liana no está dibujada en ninguna parte",
         "<p>No hay un solo dibujo de liana en el cartucho. En cada paso, "
         "0xA471 traza una recta de dieciséis puntos sobre un mapa de bits en "
         "0xE18A y la manda a la memoria de vídeo como patrón de sprite. La "
         "inclinación sale de la tabla de 0xA61A, indexada por la fase del "
         "balanceo, que va y viene entre 1 y 0x20.</p>"),
        ("En este cartucho no hay ni una palabra escrita",
         "<p>Ni una cadena, ni un alfabeto, ni un mensaje escondido. La fuente "
         "que carga el juego son diez dígitos, los dos puntos y el blanco: con "
         "eso se escriben el marcador y el reloj, y no da para una letra.</p>"
         "<p>Todo lo que parece texto —el rótulo de la presentación y el "
         "<b>Copyright 1982, 1984</b> del pie— son dibujos partidos en "
         "casillas, una por posición. Por eso buscar cadenas en la ROM no "
         "devuelve nada legible, y por eso esa línea del pie, con sus dos "
         "fechas, es lo único que el cartucho firma.</p>"),
    ],
    "en": [
        ("The world isn't stored, it's generated",
         "<p>There is no map in the cartridge. The 255 screens come out of a "
         "single byte, 0xE222, a feedback shift register: the seed is 0xC4 and "
         "the feedback taps are bits 7, 5, 4 and 3. Leaving to the right, "
         "0xB68F steps it forward; leaving to the left, 0xB69F —its exact "
         "inverse— steps it back.</p>"
         "<p>Those eight bits carry the three decisions of every screen: two "
         "bits pick the scenery, three the kind of scene and three the "
         "variant. The ring is maximal —255 states, with 0x00 left outside it "
         "and used by the title screen— and the simulation agrees with the "
         "emulator on all 255.</p>"),
        ("The 32 treasures are exactly the 32 scenes of one kind",
         "<p>Type 5 is the only one dispatched through table 0xAEA4, which "
         "holds four routines repeated two by two. Since the eight variants "
         "share out four scenes each, every class of treasure comes up eight "
         "times: 8+8+8+8 = 32, and not one more.</p>"
         "<p>Each routine writes what its own is worth into 0xE188 —2, 3, 4 or "
         "5, that is thousands of points— so the whole world holds "
         "8·(2000+3000+4000+5000) = 112000 points. With the 2000 the score "
         "starts at, <b>114000: the ceiling of the game</b>.</p>"),
        ("A treasure already taken has its return address eaten",
         "<p>What has been picked up is remembered in 32 bits, 0xE21D-0xE220: "
         "one byte per class of treasure and one bit per treasure. Before "
         "drawing one, 0xAAFF rotates its bit out into the carry.</p>"
         "<p>And if it was set, there's no branch and no flag: it does "
         "<code>pop hl</code> and <code>ret</code>. It swallows its caller's "
         "return address, and the routine that was going to draw the treasure "
         "never runs.</p>"),
        ("The tunnel crosses the world three times as fast",
         "<p>Changing screen is 0x9CBE's job: when the player's X reaches the "
         "right-hand edge it puts him back on the other side and steps the "
         "screen register on. But it steps on <b>one place or three</b> "
         "depending on bit 0 of 0xE2EB, which is what says whether you're up "
         "on the surface or down in the tunnel. The left-hand routine is "
         "symmetrical.</p>"
         "<p>The route that collects the 32 treasures goes down whenever it "
         "can: 189 screens with the tunnel against 238 never going down, 21 % "
         "fewer. The only way down is a ladder, and the ladders are measured "
         "over the 255 captures: the 63 scenes of kinds 0 and 1.</p>"),
        ("The vine isn't drawn anywhere",
         "<p>There isn't a single picture of a vine in the cartridge. On every "
         "step, 0xA471 traces a sixteen-point straight line onto a bitmap at "
         "0xE18A and sends it to video memory as a sprite pattern. The slope "
         "comes from the table at 0xA61A, indexed by the phase of the swing, "
         "which runs up and down between 1 and 0x20.</p>"),
        ("There isn't one written word in this cartridge",
         "<p>Not a string, not an alphabet, not a hidden message. The font the "
         "game loads is ten digits, the colon and a blank: enough for the "
         "score and the clock, and not enough for a single letter.</p>"
         "<p>Everything that looks like text —the title banner and the "
         "<b>Copyright 1982, 1984</b> at the foot— is drawing, cut into tiles, "
         "one per position. That's why searching the ROM for strings returns "
         "nothing readable, and why that one line at the foot, with its two "
         "dates, is the only thing the cartridge signs.</p>"),
    ],
}

# Los pies de la galeria: uno por TIPO DE ESCENA (los bits 3-5 del registro de
# pantalla), en el orden de la tabla de 0xAEB4. Lo que dice cada uno esta en
# src/pitfall.notes, en el bloque de 0xA9AA.
TIPOS = [
    ("Tipo 0 · 0xA9AA — hoyos en el suelo, con escalera al subterráneo. El "
     "bit 7 del registro de pantalla parte el tipo en dos: un hoyo o tres",
     "Type 0 · 0xA9AA — pits in the ground, with a ladder down to the tunnel. "
     "Bit 7 of the screen register splits the type in two: one pit or three"),
    ("Tipo 1 · 0xA9AA — la otra mitad de los hoyos, y la otra mitad de las "
     "escaleras: entre los tipos 0 y 1 están las 63 bajadas que hay",
     "Type 1 · 0xA9AA — the other half of the pits, and the other half of the "
     "ladders: types 0 and 1 hold the 63 ways down there are"),
    ("Tipo 2 · 0xAC7C — charca de brea. El mismo dibujo que el tipo 3 con "
     "otro color: escribe 1B 1B 1B en la tabla de colores",
     "Type 2 · 0xAC7C — a tar pit. The same drawing as type 3 in another "
     "colour: it writes 1B 1B 1B into the colour table"),
    ("Tipo 3 · 0xAC6B — charca de agua, que es el parche de color deshecho: "
     "7B 7B 7B donde el tipo 2 ponía 1B 1B 1B",
     "Type 3 · 0xAC6B — a water pool, which is that colour patch undone: "
     "7B 7B 7B where type 2 put 1B 1B 1B"),
    ("Tipo 4 · 0xAD75 — laguna con tres cocodrilos: tres bloques de cuatro "
     "bytes en el código, tres cocodrilos en la pantalla",
     "Type 4 · 0xAD75 — a lagoon with three crocodiles: three four-byte "
     "blocks in the code, three crocodiles on screen"),
    ("Tipo 5 · 0xADF6 — la escena del tesoro, la única que puntúa. Son 32 en "
     "el anillo, ocho de cada valor",
     "Type 5 · 0xADF6 — the treasure scene, the only one that scores. There "
     "are 32 of them in the ring, eight of each value"),
    ("Tipo 6 · 0xAE04 — brea con liana, y la liana se traza punto a punto en "
     "cada paso",
     "Type 6 · 0xAE04 — tar with a vine, and the vine is traced point by "
     "point on every step"),
    ("Tipo 7 · 0xADE8 — agua con liana. Con el tipo 6 y el 4, las tres "
     "escenas que obligan a cruzar por arriba",
     "Type 7 · 0xADE8 — water with a vine. With types 6 and 4, the three "
     "scenes that make you cross over the top"),
]

# El recorte del rotulo: sobre la captura ya reducida a la mitad se busca EL
# TITULO Y NADA MAS. La pantalla de presentacion trae cuatro cosas -la franja de
# colores con "ACTIVISION", el "PRESENTS", un munequito de 17x15 corriendo y el
# "PITFALL!" de abajo-, y aqui solo se quiere el ultimo: el munequito de la
# pantalla no es el mismo dibujo que el sprite de la partida, y verlos juntos es
# ver dos Harrys de distinto tamano.
#
# El corte NO se da a ojo con unas coordenadas: el titulo es lo unico AMARILLO
# de la pantalla aparte de una raya de la franja de colores, asi que se buscan
# los pixeles amarillos y se toma el grupo de filas mas alto -el titulo son
# quince filas seguidas; la raya de la franja, dos-.
UMBRAL, MARGEN, ESCALA = 40, 4, 6
AMARILLO = (140, 140, 130)          # minimo de rojo y verde, maximo de azul

def img64(ruta):
    with open(ruta, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode()


def _reduce(captura):
    """La captura de openMSX (640x480) recortada a la pantalla del MSX y a la mitad."""
    w, h, filas = lee_png(captura)
    return recorta_y_reduce(w, h, filas)


def _recorta(w, h, filas, x0, y0, x1, y1, escala):
    out = []
    for y in range(y0, y1 + 1):
        fila = filas[y]
        nueva = bytearray()
        for x in range(x0, x1 + 1):
            nueva += fila[x * 3:x * 3 + 3] * escala
        for _ in range(escala):
            out.append(nueva)
    return (x1 - x0 + 1) * escala, (y1 - y0 + 1) * escala, out


def logo_png(captura, ruta):
    """El rotulo de la cabecera: el titulo de la pantalla de presentacion.

    No es una imagen dibujada aparte ni un logotipo bajado de ningun sitio: es
    lo que el cartucho pinta al arrancar, recortado a las letras del titulo por
    su color (ver AMARILLO). Lo demas de esa pantalla -la franja de colores, el
    "PRESENTS" y el munequito- se queda fuera.
    """
    w, h, filas = _reduce(captura)
    rmin, gmin, bmax = AMARILLO

    def amarillo(fila, x):
        r, g, b = fila[x * 3:x * 3 + 3]
        return r > rmin and g > gmin and b < bmax

    # Las filas con amarillo, agrupadas en tiras seguidas; se queda la mas alta.
    ys = [y for y, fila in enumerate(filas) if any(amarillo(fila, x) for x in range(w))]
    if not ys:
        raise SystemExit("no hay titulo amarillo en %s" % captura)
    tiras, tira = [], [ys[0]]
    for y in ys[1:]:
        if y == tira[-1] + 1:
            tira.append(y)
        else:
            tiras.append(tira)
            tira = [y]
    tiras.append(tira)
    titulo = max(tiras, key=len)
    xs = [x for x in range(w) if any(amarillo(filas[y], x) for y in titulo)]
    y0, y1 = max(0, titulo[0] - MARGEN), min(h - 1, titulo[-1] + MARGEN)
    x0, x1 = max(0, xs[0] - MARGEN), min(w - 1, xs[-1] + MARGEN)
    escribe_png(ruta, *_recorta(w, h, filas, x0, y0, x1, y1, ESCALA))


def por_tipo(tsv):
    """El valor del LFSR de la primera escena de cada tipo, en orden de anillo."""
    elegido = {}
    with open(tsv, newline="", encoding="utf-8") as f:
        for fila in csv.DictReader(f, delimiter="\t"):
            t = int(fila["tipo"])
            if t not in elegido:
                elegido[t] = fila["lfsr"]
    return elegido


def muestras(capturas, tsv, imgdir):
    """Una pantalla de partida por tipo de escena, recortada y a media resolucion.

    Devuelve la lista de (fichero, pie_es, pie_en) que la galeria embebe. Si no
    estan las capturas -hacen falta openMSX y tools/omsx_mapa_lfsr.tcl- la
    galeria se queda vacia y la portada se genera igual.
    """
    if not os.path.isdir(capturas) or not os.path.exists(tsv):
        print("  (sin capturas en %s: la portada sale sin galeria)" % capturas)
        return []
    elegido = por_tipo(tsv)
    out = []
    for tipo in range(len(TIPOS)):
        lfsr = elegido.get(tipo)
        if lfsr is None:
            continue
        # se cruza por el LFSR, NUNCA por el numero de captura
        halladas = glob.glob(os.path.join(
            capturas, "escena_[0-9][0-9][0-9]_%s.png" % lfsr[2:].upper()))
        if not halladas:
            continue
        w, h, filas = _reduce(sorted(halladas)[0])
        fich = "escena-tipo-%d.png" % tipo
        escribe_png(os.path.join(imgdir, fich), w, h, filas)
        out.append((fich,) + TIPOS[tipo])
    return out


def main(argv):
    if len(argv) < 6:
        print(__doc__)
        return 2
    capturas, tsv, imgdir, salida, idioma = argv[1:6]
    t = TXT[idioma]
    os.makedirs(imgdir, exist_ok=True)

    ruta_logo = os.path.join(imgdir, "logo.png")
    arranque = os.path.join(capturas, "arranque.png")
    if os.path.exists(arranque):
        logo_png(arranque, ruta_logo)
    cabecera = (f'<img src="{img64(ruta_logo)}" alt="Pitfall! (1984)">'
                if os.path.exists(ruta_logo) else "<h1>Pitfall! (1984)</h1>")

    nav = "".join(f'<a href="{h}">{x}</a>' for h, x in t["nav"])
    nav += "".join(f'<a href="{h}">{x}</a>' for h, x in t["docnav"])
    nav += (f'<a href="{t["otro"][0]}" style="margin-left:auto;color:var(--oro)">'
            f'{t["otro"][1]}</a>')

    cifras = "".join(f'<div class="cifra"><b>{v}</b><span>{e}</span></div>'
                     for v, e in t["cifras"])
    halls = "".join(f'<div class="hall"><h3>{tit}</h3>{cuerpo}</div>'
                    for tit, cuerpo in HALLAZGOS[idioma])
    imgs = ""
    for fich, es, en in muestras(os.path.join(capturas, "mapa"), tsv, imgdir):
        pie = es if idioma == "es" else en
        imgs += (f'<figure><img src="{img64(os.path.join(imgdir, fich))}" '
                 f'alt="{pie}"><figcaption>{pie}</figcaption></figure>')

    html = f"""<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{t['titulo']}</title>
<style>{ESTILO}</style>
<header class="top">
  {cabecera}
  <p class="claim">{t['claim']}</p>
  <p class="ficha">{' · '.join(t['ficha'])}</p>
</header>
<p class="ficha" style="border:1px solid var(--oro);padding:.8em 1em;margin:1.5em 0">
{t['aviso']}</p>
<nav>{nav}</nav>
<section id="numbers">
  <h2>{t['h_num']}</h2>
  <div class="cifras">{cifras}</div>
</section>
<section id="findings"><h2>{t['h_find']}</h2>{halls}</section>
<section id="screens">
  <h2>{t['h_scr']}</h2>
  <p class="n">{t['nota_scr']}</p>
  <div class="galeria">{imgs}</div>
</section>
<footer><p>{t['pie_leg']}</p></footer>
"""
    with open(salida, "w", encoding="utf-8") as f:
        f.write(html)
    print("  %s: %d KB (%s)" % (salida, len(html) // 1024, idioma))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
