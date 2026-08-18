# Athletic Land (Konami, 1984, MSX1) — desensamblado comentado

El primer cartucho de Konami para MSX, desmontado byte a byte. Los 16.384 bytes
están acotados y explicados: ni un hueco sin justificar, ni un "bloque de
gráficos", ni una tabla adivinada.

[README in English](README.md)

---

## Qué es esto

*Athletic Land* es el RC-700, el primer cartucho que Konami sacó para MSX.
Aquí está su código, comentado, con las herramientas para volver a montarlo y
comprobar que lo que sale es el original.

La máquina mapea los 16 KB en 0x4000-0x7FFF —la página 1—, la BIOS llama al
punto de entrada 0x4077, y de ahí el programa ya no vuelve: el arranque escribe
un `jp` en el gancho H.KEYI y se mete en un bucle de dos bytes, así que **el
juego entero corre dentro de la interrupción**, un paso por fotograma. Si un
paso tarda más de un fotograma, la interrupción siguiente toca la música y se
va.

## Por qué esto se puede creer

`make` traza el flujo, construye el listado y exige que al ensamblarlo salga
exactamente el original:

```
  ensamblado : 16384 bytes  7bd280ae...81285485
  original   : 16384 bytes  7bd280ae...81285485
OK: reproducible byte a byte
```

Un listado puede reensamblar perfectamente y estar mal —si se leen dibujos como
instrucciones, los bytes no cambian—, así que corren dos comprobaciones más:
ningún rango declarado como datos puede salir como código, y ningún punto de
entrada puede caer dentro de uno.

Los gráficos se comprueban por una tercera vía. `tools/graficos.py` reconstruye
la memoria de vídeo repitiendo las copias del propio cartucho, en el mismo
orden y a las mismas direcciones, y dibuja el resultado. Si un rango estuviera
mal etiquetado saldría ruido; en cambio salen los tiles, los sprites y los
nueve fotogramas de la liana tal como son.

## El juego en cifras

| | |
|---|---|
| bytes de código | 7.448 |
| bytes de datos | 8.936 |
| bytes sin identificar | **0** |
| etiquetas con nombre | 296 |
| comentarios anclados | 348 |
| rangos de datos con explicación | 166 |

## Algunas cosas que han salido

- **El juego es una tabla de treinta y dos pantallas, no un mapa.** Dos bytes
  por pantalla en 0x5C32: uno dice qué obstáculos fijos hay (charcos, lianas,
  trampolines, surtidores, el estanque de cinco postes, la piedra, la hoguera,
  el estanque), el otro cuáles se mueven (bolas que ruedan, arañas, peces, el
  tronco flotante, la bola que bota, la abeja). El SCENE módulo 32 elige la
  pareja, y luego la fase la retoca.
- **Toda pantalla cuyo número acaba en 0, 4 u 8 sale vacía**, y las acabadas en
  0 llevan el rótulo CHILD PARK. Una fase son diez pantallas: la meta se guarda
  en BCD, y superar la fase 99 la devuelve a 00 y saca ALL STAGE CLEAR con los
  créditos.
- **Una sola rutina dibuja todo el decorado**, y coge sus argumentos de los seis
  bytes que van detrás de su propio `call`: dos punteros y una dirección de
  vídeo. Se la llama diecinueve veces, y cuatro de ellas escriben la tabla de
  colores en vez de tiles.
- **Un salto es una tabla de incrementos leída de ida y de vuelta.** La misma
  lista de dieciséis bytes, recorrida en un sentido restando y en el otro
  sumando, es la subida y la caída; los bytes 0xFE y 0xFF de los extremos son
  los que la dan la vuelta y los que la terminan.
- **Lo que mata no es la altura a la que caes, sino la altura desde la que
  caíste.** El código guarda desde dónde saltaste y compara: aterrizar
  dieciséis puntos por debajo es mortal, estés donde estés en la pantalla.
- **La liana son nueve dibujos**, no una animación: un péndulo en nueve
  fotogramas, cada uno terminado con los tres bytes que dicen dónde está su
  cabo, que es donde te puedes agarrar.
- **Los créditos están dentro del cartucho**, en tiles corrientes: PROGRAM A.H
  Y.I, SOUND Y.O, CG R.S C.K. Solo aparecen después de la fase 99.

## Cómo empezar

Hacen falta `pasmo`, `z80dasm` y Python 3. La imagen del cartucho **no** se
distribuye aquí: pon la tuya en la raíz como `athletic.rom`, 16384 bytes,
sha256 `7bd280ae4147a5bf5676b15fde310a8106887786c78873344d97a1cd81285485`.

```sh
make          # traza, construye el listado y lo comprueba todo
make verify   # ensambla y compara con el cartucho
make sanity   # lo que el reensamblado no puede cazar
```

## Licencia y atribución

El juego no es nuestro: *Athletic Land* es de Konami, y todos los derechos
siguen siendo de sus titulares. Lo que sí es nuestro —las herramientas, los
comentarios y la documentación— se publica con la licencia de `LICENSE`. La
imagen del cartucho no se distribuye. Ver [AVISO-LEGAL.md](AVISO-LEGAL.md).
