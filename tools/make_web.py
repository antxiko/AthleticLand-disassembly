#!/usr/bin/env python3
"""Genera la portada de la web, en los dos idiomas.

El diseno es el compartido por la serie (tools/estilo_web.py) y la pagina sale
autocontenida, con las imagenes embebidas como data URI.

Ni el rotulo de la cabecera ni la galeria son ilustraciones traidas de fuera, y
tampoco son capturas: salen de repetir, paso a paso, lo que hace el propio
cartucho. tools/imagenes_web.py reconstruye la memoria de video con las copias
de la ROM y luego repite las llamadas que pintan cada cosa; si un rango
estuviera mal etiquetado, la galeria saldria ruido.

Uso: make_web.py <docs/imagenes> <salida.html> <idioma>
"""
import base64
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from estilo_web import ESTILO                                   # noqa: E402

# Las cifras de la portada salen de contar sobre el listado generado, no de
# escribirlas aqui a ojo: 16384 = 7448 + 8936, que es lo que imprime
# tools/presupuesto.py (make sanity). Los rotulos se formatean a partir de
# estos numeros para que no puedan quedarse desfasados por su cuenta.
CODIGO = 7448
DATOS = 8936
PANTALLAS = 32                      # las dos tablas de 0x5C32 y 0x5C52
FASES = 99                          # la fase es BCD y de 99 vuelve a 00


def mil(n, idioma):
    return f"{n:,}".replace(",", "." if idioma == "es" else ",")


TXT = {
    "es": dict(
        titulo="Athletic Land (1984) — desensamblado comentado",
        aviso="<b>Aquí no hay ni una captura de pantalla.</b> Todas las "
              "imágenes están dibujadas repitiendo lo que hace el cartucho: "
              "se reconstruye la memoria de vídeo con sus mismas copias y "
              "luego se repiten las llamadas que pintan cada cosa. Son las "
              "piezas que dibujan las rutinas, no pantallas de partida. Lo "
              "demás —el listado y las cifras— sale del binario y se "
              "reproduce con <code>make</code>.",
        claim="Un cartucho de 16 KB de 1984, desmontado byte a byte. El "
              "juego entero corre dentro de la interrupción, el mundo son "
              "sesenta y cuatro bytes de tabla, la liana son nueve dibujos y "
              "los créditos están dentro, escritos en tiles corrientes.",
        ficha=["Konami · <b>1984</b>", "Cartucho <b>RC-700</b>, 16 KB",
               "MSX1 · <b>página 1</b>", "Volcado <b>7bd280ae…</b>"],
        nav=[("#numbers", "Las cifras"), ("#findings", "Hallazgos"),
             ("#screens", "Lo que dibuja")],
        docnav=[("EMPEZAR.html", "Empezar"), ("EL-JUEGO.html", "El juego"),
                ("EL-CARTUCHO.html", "El cartucho"),
                ("EL-CODIGO.html", "El código"),
                ("HALLAZGOS.html", "Hallazgos"),
                ("PREGUNTAS-ABIERTAS.html", "Preguntas abiertas")],
        otro=("../", "In English"),
        h_num="El juego en cifras", h_find="Lo que apareció al desmontarlo",
        h_scr="Lo que el cartucho dibuja",
        cifras=[("100 %", "del binario explicado"),
                (str(PANTALLAS), "pantallas en la tabla"),
                (str(FASES), "fases hasta el final"),
                (mil(CODIGO, "es"), "bytes de código"),
                (mil(DATOS, "es"), "bytes de datos"),
                ("0", "bytes sin identificar")],
        nota_scr="Cada una de estas imágenes es una rutina del cartucho "
                 "repetida fuera de él: los tiles se cargan como los carga la "
                 "ROM y luego se llama a lo que los pinta, con sus mismos "
                 "punteros y sus mismas direcciones de vídeo. Debajo de cada "
                 "pie está la dirección de la rutina que la dibuja.",
        pie_leg="Esto es trabajo de documentación y preservación sobre un "
                "juego de 1984: el código y los gráficos siguen siendo de sus "
                "autores y de Konami, y la imagen del cartucho no se "
                "distribuye.",
    ),
    "en": dict(
        titulo="Athletic Land (1984) — a commented disassembly",
        aviso="<b>There is not one screenshot here.</b> Every picture is "
              "drawn by repeating what the cartridge does: video memory is "
              "rebuilt with its own copies and then the calls that paint each "
              "thing are replayed. They are the pieces the routines draw, not "
              "screens of anyone playing. Everything else —the listing and the "
              "numbers— comes from the binary and is reproducible with "
              "<code>make</code>.",
        claim="A 16 KB cartridge from 1984, taken apart byte by byte. The "
              "whole game runs inside the interrupt, the world is sixty-four "
              "bytes of table, the vine is nine drawings, and the credits are "
              "in there, written in ordinary tiles.",
        ficha=["Konami · <b>1984</b>", "An <b>RC-700</b> 16 KB cartridge",
               "MSX1 · <b>page 1</b>", "Dump <b>7bd280ae…</b>"],
        nav=[("#numbers", "The numbers"), ("#findings", "What turned up"),
             ("#screens", "What it draws")],
        docnav=[("GETTING-STARTED.html", "Getting started"),
                ("THE-GAME.html", "The game"),
                ("THE-CARTRIDGE.html", "The cartridge"),
                ("THE-CODE.html", "The code"),
                ("FINDINGS.html", "Findings"),
                ("OPEN-QUESTIONS.html", "Open questions")],
        otro=("es/", "En castellano"),
        h_num="The game in numbers", h_find="What turned up when we took it apart",
        h_scr="What the cartridge draws",
        cifras=[("100%", "of the binary explained"),
                (str(PANTALLAS), "screens in the table"),
                (str(FASES), "stages to the end"),
                (mil(CODIGO, "en"), "bytes of code"),
                (mil(DATOS, "en"), "bytes of data"),
                ("0", "bytes unidentified")],
        nota_scr="Each of these pictures is a routine of the cartridge "
                 "replayed outside it: the tiles are loaded the way the ROM "
                 "loads them and then whatever paints them is called, with "
                 "its own pointers and its own video addresses. Under each "
                 "caption is the address of the routine that draws it.",
        pie_leg="This is documentation and preservation work on a 1984 game: "
                "the code and artwork still belong to their authors and to "
                "Konami, and the cartridge image is not distributed.",
    ),
}

HALLAZGOS = {
    "es": [
        ("El juego entero corre dentro de la interrupción",
         "<p>INIT escribe <code>jp 0x4038</code> en el gancho H.KEYI y se "
         "queda en un <code>jr $</code> de dos bytes, en 0x40A7. Ese bucle "
         "vacío es el programa principal: a partir de ahí todo —el sonido, "
         "los mandos y un paso del juego— pasa dentro de la interrupción, un "
         "paso por fotograma.</p>"
         "<p>Y como el juego es la interrupción, hace falta un candado: "
         "0xE005. Si un paso tarda más de un fotograma, la interrupción "
         "siguiente toca la música y se va sin ejecutar nada más, así que la "
         "partida se ralentiza pero la música no se corta.</p>"),
        ("La tabla va detrás del <code>call</code>",
         "<p>Para saltar a una dirección calculada, 0x40A9 hace "
         "<code>pop hl</code> y usa la dirección de retorno: la tabla de "
         "palabras está pegada detrás del propio <code>call</code>. Nunca "
         "vuelve. Hay cinco tablas así, del estado del juego a lo que está "
         "haciendo el jugador.</p>"
         "<p>El motor que dibuja el decorado, 0x5F65, hace lo mismo con "
         "parámetros: los <b>seis bytes que siguen a su call</b> son dos "
         "punteros y una dirección de vídeo, y el <code>push hl</code> "
         "devuelve el control justo detrás de ellos. Se le llama diecinueve "
         "veces, y cuatro de ellas para escribir colores en vez de tiles.</p>"),
        ("El mundo son sesenta y cuatro bytes",
         "<p>No hay mapa. La pantalla es un contador, 0xE054, que sube o baja "
         "de uno en uno —y al pasar de 255 cae al 56—, y lo que hay dentro "
         "sale de dos tablas de treinta y dos bytes: una dice los obstáculos "
         "fijos y la otra los que se mueven, indexadas por el contador módulo "
         "32.</p>"
         "<p>Encima, la fase retoca la pareja: la 1 se queda sin arañas ni "
         "abeja, la 3 sin abeja, y toda pantalla cuyo número acabe en 0, 4 u "
         "8 sale vacía. Las acabadas en 0 son las metas, y llevan el rótulo "
         "CHILD PARK.</p>"),
        ("Lo que mata no es la altura a la que caes, sino desde la que caíste",
         "<p>No hay daño por caída en ninguna parte. Hay un byte, 0xE13A, que "
         "se escribe al pulsar el botón de saltar: la altura desde la que "
         "saltaste, más dieciséis. Desde el suelo, eso es el suelo.</p>"
         "<p>Pero si saltas desde una tabla de surtidor de en medio, se "
         "guarda la altura de la tabla sin sumarle nada, y a partir de ahí "
         "aterrizar dieciséis o diecisiete puntos por debajo mata, estés "
         "donde estés en la pantalla. El mismo aterrizaje es inofensivo o "
         "mortal según dónde empezara el salto.</p>"),
        ("El salto es una tabla leída de ida y de vuelta",
         "<p>No hay una velocidad vertical en el cartucho. Un salto es una "
         "lista de incrementos entre un 0xFE y un 0xFF, que se recorre en un "
         "sentido restando —subiendo, cada vez menos— y en el otro sumando. "
         "El 0xFF le da la vuelta y el 0xFE lo termina.</p>"
         "<p>El salto normal son dieciséis bytes: 4 4 3 3 3 3 2 2 2 2 1 1 1 1 "
         "0 0. Treinta y dos puntos de altura, dieciséis fotogramas para "
         "arriba y dieciséis para abajo, y la caída es la subida leída al "
         "revés porque son los mismos bytes.</p>"),
        ("Los créditos están dentro del cartucho, en tiles",
         "<p>En 0x447E, con el código de tile siendo el ASCII de la letra: "
         "<b>ALL STAGE CLEAR</b>, <b>PROGRAM A.H Y.I</b>, <b>SOUND Y.O</b>, "
         "<b>CG R.S C.K</b>. Ni un nombre completo: iniciales.</p>"
         "<p>Se pintan en un solo sitio, 0x445B, cuando la fase da la vuelta "
         "de 99 a 00. Aparte de eso, en el cartucho no hay más firma que el "
         "KONAMI 1984 del título y del pie del marcador.</p>"),
    ],
    "en": [
        ("The whole game runs inside the interrupt",
         "<p>INIT writes <code>jp 0x4038</code> into the H.KEYI hook and drops "
         "into a two-byte <code>jr $</code> at 0x40A7. That empty loop is the "
         "main program: from then on everything —the sound, the controls and "
         "one step of the game— happens inside the interrupt, one step per "
         "frame.</p>"
         "<p>And because the game is the interrupt, it needs a lock: 0xE005. "
         "If a step takes longer than a frame, the next interrupt plays the "
         "music and leaves without running anything else, so the game slows "
         "down but the music never breaks.</p>"),
        ("The table sits behind the <code>call</code>",
         "<p>To jump to a computed address, 0x40A9 does <code>pop hl</code> "
         "and uses the return address: the table of words is packed right "
         "behind the <code>call</code> itself. It never returns. Five tables "
         "work that way, from the state of the game to what the player is "
         "doing.</p>"
         "<p>The routine that draws the scenery, 0x5F65, does the same with "
         "arguments: the <b>six bytes following its call</b> are two pointers "
         "and a video address, and the <code>push hl</code> hands control back "
         "just after them. It is called nineteen times, four of them to write "
         "colours rather than tiles.</p>"),
        ("The world is sixty-four bytes",
         "<p>There is no map. The screen is a counter, 0xE054, stepped up or "
         "down by one —and on passing 255 it drops to 56—, and what is in it "
         "comes out of two thirty-two byte tables: one for the fixed "
         "obstacles and one for the moving ones, indexed by that counter "
         "modulo 32.</p>"
         "<p>On top of that the stage edits the pair: stage 1 loses the "
         "spiders and the bee, stage 3 the bee, and every screen whose number "
         "ends in 0, 4 or 8 comes out empty. The ones ending in 0 are the "
         "finishing lines, and they carry the CHILD PARK sign.</p>"),
        ("What kills you is not the height you fall to, but the one you fell from",
         "<p>There is no fall damage anywhere. There is one byte, 0xE13A, "
         "written when you press the jump button: the height you jumped from, "
         "plus sixteen. From the ground, that is the ground.</p>"
         "<p>But jump from one of the middle water-jet planks and it keeps "
         "that plank's height with nothing added, and from then on landing "
         "sixteen or seventeen points below it kills you, wherever you are on "
         "the screen. The very same landing is harmless or fatal depending on "
         "where the jump started.</p>"),
        ("The jump is a table read forwards and then backwards",
         "<p>There is no vertical speed in the cartridge. A jump is a list of "
         "deltas between a 0xFE and a 0xFF, walked one way subtracting —going "
         "up, less and less— and the other way adding. The 0xFF turns it "
         "round and the 0xFE ends it.</p>"
         "<p>The normal jump is sixteen bytes: 4 4 3 3 3 3 2 2 2 2 1 1 1 1 0 "
         "0. Thirty-two pixels of rise, sixteen frames up and sixteen down, "
         "and the fall is the rise read the other way because it is the same "
         "bytes.</p>"),
        ("The credits are inside the cartridge, in tiles",
         "<p>At 0x447E, the tile codes being the ASCII of the letters: "
         "<b>ALL STAGE CLEAR</b>, <b>PROGRAM A.H Y.I</b>, <b>SOUND Y.O</b>, "
         "<b>CG R.S C.K</b>. No full names: initials.</p>"
         "<p>They are painted in one place only, 0x445B, when the stage "
         "counter wraps from 99 back to 00. Apart from that, nothing in the "
         "cartridge is signed except the KONAMI 1984 on the title screen and "
         "at the foot of the scoreboard.</p>"),
    ],
}

# La galeria: fichero, pie en castellano, pie en ingles. Cada uno lleva la
# direccion de la rutina que lo dibuja, que es de donde sale la imagen.
GALERIA = [
    ("cerros-0.png",
     "0x5E8D — la banda de arriba: una copa de hojas con un tronco a cada "
     "lado. Cada mitad viene en dos formas, y los bits 1-2 del SCENE eligen "
     "la pareja por la tabla de 0x5E85",
     "0x5E8D — the top band: a canopy of leaves with a trunk on each side. "
     "Each half comes in two shapes, and bits 1-2 of SCENE pick the pair "
     "through the table at 0x5E85"),
    ("cerros-2.png",
     "0x5E97 — la otra pareja, las dos mitades a nivel. Las mismas dos "
     "llamadas con otras listas: nada de esto está guardado como pantalla",
     "0x5E97 — the other pair, the two level halves. The same two calls with "
     "different lists: none of this is stored as a screen"),
    ("cielo-azul-amarillo.png",
     "0x5CC2 — uno de los cuatro cielos: seis filas de franjas sobre una "
     "línea de cerros. Los bits 2-3 del SCENE eligen cuál, por 0x5C7F",
     "0x5CC2 — one of the four skies: six rows of bands over a line of hills. "
     "Bits 2-3 of SCENE choose which, through 0x5C7F"),
    ("cielo-rojo-verde.png",
     "0x5CE0 — otro de los cuatro: la misma lista de cuentas con otra lista "
     "de tiles. El decorado con cielo sale cuando no hay lianas, trampolines "
     "ni arañas",
     "0x5CE0 — another of the four: the same list of counts with a different "
     "tile list. The sky scenery is used when there are no vines, trampolines "
     "or spiders"),
    ("seto.png",
     "0x5C91 — el seto de las filas 10 a 12 y la hierba, que solo se pinta si "
     "la pantalla no lleva surtidores ni postes",
     "0x5C91 — the hedge of rows 10 to 12 and the grass, drawn only if the "
     "screen has no water jets and no posts"),
    ("estanque.png",
     "0x5CF4 — el estanque, el bit 7 de los obstáculos fijos: filas 16 a 18, "
     "columnas 9 a 22. Pisar dentro de él ahoga",
     "0x5CF4 — the pond, bit 7 of the fixed obstacles: rows 16 to 18, columns "
     "9 to 22. Step into it and you drown"),
    ("child-park.png",
     "0x5E58 — el rótulo CHILD PARK, en toda pantalla cuyo número acabe en 0: "
     "la entrada y las metas de cada fase, y siempre vacías",
     "0x5E58 — the CHILD PARK sign, on every screen whose number ends in 0: "
     "the entrance and each stage's finishing line, and always empty"),
    ("liana.png",
     "0x555B — los nueve dibujos de la liana, uno al lado de otro. No hay "
     "animación: nueve dibujos leídos hacia delante y hacia atrás",
     "0x555B — the nine drawings of the vine, side by side. There is no "
     "animation: nine drawings read forwards and then backwards"),
]


def img64(ruta):
    with open(ruta, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode()


def main(argv):
    if len(argv) < 4:
        print(__doc__)
        return 2
    imgdir, salida, idioma = argv[1:4]
    t = TXT[idioma]

    ruta_logo = os.path.join(imgdir, "logo.png")
    cabecera = (f'<img src="{img64(ruta_logo)}" alt="Athletic Land (1984)">'
                if os.path.exists(ruta_logo) else "<h1>Athletic Land (1984)</h1>")

    nav = "".join(f'<a href="{h}">{x}</a>' for h, x in t["nav"])
    nav += "".join(f'<a href="{h}">{x}</a>' for h, x in t["docnav"])
    nav += (f'<a href="{t["otro"][0]}" style="margin-left:auto;color:var(--oro)">'
            f'{t["otro"][1]}</a>')

    cifras = "".join(f'<div class="cifra"><b>{v}</b><span>{e}</span></div>'
                     for v, e in t["cifras"])
    halls = "".join(f'<div class="hall"><h3>{tit}</h3>{cuerpo}</div>'
                    for tit, cuerpo in HALLAZGOS[idioma])
    imgs = ""
    faltan = []
    for fich, es, en in GALERIA:
        ruta = os.path.join(imgdir, fich)
        if not os.path.exists(ruta):
            faltan.append(fich)
            continue
        pie = es if idioma == "es" else en
        imgs += (f'<figure><img src="{img64(ruta)}" alt="{pie}">'
                 f'<figcaption>{pie}</figcaption></figure>')
    if faltan:
        print("  (faltan %d imagenes: %s)" % (len(faltan), " ".join(faltan)))

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
