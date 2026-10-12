# La música

Todo lo que suena aquí sale de ejecutar el motor de sonido del cartucho (`SUENA`, 0x785D, y `SONIDO`, 0x77FE, que le reparte los tres canales; lo llama la interrupción en 0x4041) en un Z80 emulado, cuadro a cuadro y a 60 por segundo, igual que lo llama el juego. Lo que el motor escribe en el PSG pasa a sonido con un AY-3-8910 (`tools/musica.py`). Cada MP3 es la pieza entera hasta donde vuelve a empezar, más 8 segundos de la vuelta apagándose; las que no se repiten acaban donde acaba el motor.

## Cotejado con openMSX

Las escrituras al PSG se han comparado cuadro a cuadro con las de openMSX (C-BIOS MSX1 japonés). En todos los cuadros el PSG queda igual:

- la música de la salida (0x8E) entera, 1.292 cuadros y su vuelta;
- la fanfarria (0x9C) entera, 194 cuadros.

El timbre no está cotejado: es el de un AY-3-8910 de manual, no una grabación del emulador. Las sondas están en `tools/omsx_psg.tcl` y `tools/coteja_psg.py`.

## Cómo se pide una pieza

`SONIDO` recibe el número en A. Del 0x8E en adelante es música (0x8E usa dos canales, del 0x90 en adelante tres); por debajo es un efecto, que usa solo el canal C. Cada canal tiene diez bytes en 0xE010, 0xE01A y 0xE024, y el motor lee de la pista una nota por evento. En la fanfarria 0x9C el último cuadro de openMSX difiere solo porque el juego la vuelve a pedir en cuanto acaba.

## Las músicas

**La salida** (0x8E)

Lo pide `ESTADO_10_ESPERA` al arrancar la pantalla; dura 21,5 s y vuelve a empezar en el segundo 0,2.

<audio controls preload="none" src="../audio/musica_8E.mp3"></audio>

**La muerte** (0x90)

Lo pide `MUERTE_CON_VIDAS`; dura 2,0 s.

<audio controls preload="none" src="../audio/musica_90.mp3"></audio>

**Game over** (0x93)

Lo pide `ESTADO_12_MUERTE` cuando no quedan vidas; dura 5,0 s.

<audio controls preload="none" src="../audio/musica_93.mp3"></audio>

**Te han dado** (0x96)

Lo pide `LE_HAN_DADO`; dura 0,2 s.

<audio controls preload="none" src="../audio/musica_96.mp3"></audio>

**Te hundes** (0x99)

Lo pide `SE_HUNDE`; dura 0,6 s.

<audio controls preload="none" src="../audio/musica_99.mp3"></audio>

**La fanfarria de meta y del menú** (0x9C)

Lo pide `MENU_CORTINILLA_BUCLE` y `META_ALCANZADA`; dura 3,2 s.

<audio controls preload="none" src="../audio/musica_9C.mp3"></audio>
