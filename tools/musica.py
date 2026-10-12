#!/usr/bin/env python3
"""La musica del cartucho, ejecutando su motor de sonido (ver motor_musica.py).

Pide el sonido con `SONIDO` (0x77FE, A = numero) y corre `SUENA` (0x785D), el
reproductor que la interrupcion llama cada cuadro (0x4041).
Uso:  musica.py registros 0x9C [cuadros] | mp3 0x9C f.mp3 | todas docs/audio
      musica.py barrido 0 0xB0 | emu
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor_musica  # noqa: E402

PIEZAS = [
    # (numero, fichero, grupo, titulo es, titulo en, quien es, quien en)
    (0x8E, "musica_8E.mp3", "musica", "La salida", "The start",
     "`ESTADO_10_ESPERA` al arrancar la pantalla",
     "`ESTADO_10_ESPERA` when a screen starts"),
    (0x90, "musica_90.mp3", "musica", "La muerte", "Death",
     "`MUERTE_CON_VIDAS`", "`MUERTE_CON_VIDAS`"),
    (0x93, "musica_93.mp3", "musica", "Game over", "Game over",
     "`ESTADO_12_MUERTE` cuando no quedan vidas",
     "`ESTADO_12_MUERTE` when no lives are left"),
    (0x96, "musica_96.mp3", "musica", "Te han dado", "Hit",
     "`LE_HAN_DADO`", "`LE_HAN_DADO`"),
    (0x99, "musica_99.mp3", "musica", "Te hundes", "Sinking",
     "`SE_HUNDE`", "`SE_HUNDE`"),
    (0x9C, "musica_9C.mp3", "musica", "La fanfarria de meta y del menú",
     "The finish and menu fanfare",
     "`MENU_CORTINILLA_BUCLE` y `META_ALCANZADA`",
     "`MENU_CORTINILLA_BUCLE` and `META_ALCANZADA`"),
]

PAGINA = dict(
    motor_es="`SUENA`, 0x785D, y `SONIDO`, 0x77FE, que le reparte los tres "
             "canales; lo llama la interrupción en 0x4041",
    motor_en="`SUENA`, 0x785D, and `SONIDO`, 0x77FE, which hands it the "
             "three channels; the interrupt calls it at 0x4041",
    maquina="C-BIOS MSX1 japonés",
    cotejo=[("la música de la salida (0x8E) entera, 1.292 cuadros y su vuelta",
             "the start tune (0x8E), whole, 1,292 frames and its repeat"),
            ("la fanfarria (0x9C) entera, 194 cuadros",
             "the fanfare (0x9C), whole, 194 frames")],
    notas=[("Cómo se pide una pieza",
            "`SONIDO` recibe el número en A. Del 0x8E en adelante es música "
            "(0x8E usa dos canales, del 0x90 en adelante tres); por debajo "
            "es un efecto, que usa solo el canal C. Cada canal tiene diez "
            "bytes en 0xE010, 0xE01A y 0xE024, y el motor lee de la pista "
            "una nota por evento. En la fanfarria 0x9C el último cuadro de "
            "openMSX difiere solo porque el juego la vuelve a pedir en cuanto "
            "acaba.",
            "How a piece is asked for",
            "`SONIDO` takes the number in A. From 0x8E up it is music (0x8E "
            "uses two channels, 0x90 and up three); below that it is an "
            "effect, which uses channel C only. Each channel has ten bytes at "
            "0xE010, 0xE01A and 0xE024, and the engine reads one note per "
            "event from the track. In the 0x9C fanfare the last openMSX frame "
            "differs only because the game asks for it again as soon as it "
            "ends.")],
    grupos=[("musica", "Las músicas", "The tunes", "", "")],
)

CFG = dict(rom="athletic.rom", org=0x4000, frame=0x785D, pide=0x77FE,
           ram=(0xE010, 0xE02E), hz=60, piezas=PIEZAS, pagina=PAGINA,
           cotejado=[(0x8E, 1292, 11), (0x9C, 194, None)])

if __name__ == "__main__":
    sys.exit(motor_musica.main(CFG, sys.argv[1:]))
