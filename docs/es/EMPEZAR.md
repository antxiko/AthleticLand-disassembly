# Empezar

## Lo que hace falta

`pasmo` y `z80dasm` para ensamblar y desensamblar, y Python 3 para las
herramientas. No hay más dependencias.

El cartucho no se distribuye con este repositorio: hace falta tu propia copia,
con el nombre `athletic.rom` en la raíz del proyecto. Son 16384 bytes exactos
con este sha256:

    7bd280ae4147a5bf5676b15fde310a8106887786c78873344d97a1cd81285485

Con otro volcado el listado no reensamblará. `make comprueba` lo dice en una
línea.

## Las órdenes

```sh
make          # traza, genera el listado y lo comprueba todo
make verify   # ensambla el listado y compara el sha256 con el cartucho
make sanity   # lo que el reensamblado no puede cazar
make test     # los 17 tests del listado, que no necesitan el cartucho
make web      # las imágenes y estas páginas
```

`make` falla si el listado deja de reproducir el cartucho byte a byte, si el
trazador se mete en una zona declarada como datos, si un punto de entrada cae
dentro de una, o si queda un byte de los 16384 sin dueño.

## La prueba que decide

Un desensamblado es fiable si al ensamblarlo vuelve a salir el original. Eso es
`make verify`:

    ensamblado : 16384 bytes  7bd280ae...81285485
    original   : 16384 bytes  7bd280ae...81285485
    OK: reproducible byte a byte

## La segunda prueba

Un listado puede reensamblar perfecto y estar mal: si unos dibujos se leen como
instrucciones, los bytes no cambian —solo cambia lo que se dice de ellos—.
`make sanity` cruza los rangos de datos contra el trazado y termina con el
reparto:

      codigo trazado              7448   45.46 %
      datos identificados         8936   54.54 %
      sin explicar                   0    0.00 %
      ==========================================
      explicado                  16384  100.00 %

## La tercera prueba, la de los gráficos

Ninguna de las dos anteriores caza una tabla de tiles leída con un byte de
desfase: los bytes siguen ensamblando y el rango sigue declarado. Así que los
gráficos se comprueban dibujándolos. `tools/graficos.py` reconstruye la memoria
de vídeo repitiendo las copias del propio cartucho —en el mismo orden, a las
mismas direcciones, con sus espejos por bits y sus sustituciones de color— y
`tools/imagenes_web.py` repite encima las llamadas concretas que pintan cada
cosa. De ahí salen todas las imágenes de esta web: el rótulo del título, los
decorados, los nueve dibujos de la liana, los dieciocho bloques del surtidor,
los tiles y los sprites. Un rango mal etiquetado saldría ruido.

## Sin el cartucho

El trabajo está en `src/athletic.asm` y en las notas: 6.882 líneas con 296
rutinas y tablas bautizadas, 348 comentarios anclados a su dirección y 166
rangos de datos con su explicación al lado. Los 17 tests corren sin el binario.

## Cómo está organizado

El listado **no se toca a mano**: se genera, y lo gobiernan tres ficheros.

| | |
|---|---|
| `src/athletic.entries` | los puntos de entrada: por dónde empieza el trazado |
| `src/athletic.nocode` | las zonas que NO son código, y cómo se sabe |
| `src/athletic.notes` | los nombres, los comentarios y los rangos de datos |

De ahí sale `src/athletic.asm`. Cada nota está anclada a su dirección, así que
sobrevive a un retrazado.

El `.entries` tiene 48 puntos de entrada porque el cartucho declara **uno
solo** —la BIOS lee la cabecera "AB" y llama a 0x4077— y todo lo demás se
alcanza por caminos que ningún trazador estático puede seguir: el gancho de
interrupción (0x4038), que es donde corre el juego entero, y las cinco tablas
del despachador, que 0x40A9 lee de detrás de su propio `call`, declaradas una a
una con la instrucción que las alcanza anotada al lado.

Lleva además una directiva propia, `!skip 0x5F65 6`: el motor de decorados coge
seis bytes de parámetros que van **detrás** de su `call`, así que el trazador
tiene que saltárselos en vez de ejecutarlos. Esos 19 bloques de seis bytes
salen del trazado como datos, y cada uno está declarado en las notas.

El `.nocode` es corto —5 rangos— y son las cinco tablas del despachador, por
las que el trazador se metería de largo.

## Cómo salen los bloques de datos

Cada rango de datos declarado en el `.notes` sale como un bloque aparte: su
cabecera diciendo para qué sirve, su etiqueta y el volcado alineado a su primer
byte, de modo que se ve de un golpe dónde acaba una tabla y empieza la
siguiente. Una línea opcional le da al bloque la anchura de fila de su
estructura real, y eso es lo que hace legibles las tablas en el propio listado:

| | |
|---|---|
| `F 0x48CE 8` | los 48 glifos de la fuente, un glifo por fila |
| `F 0x7608 8` | los patrones de los tiles, un patrón por fila |
| `F 0x6B8A 4` | las catorce poses del jugador, los cuatro patrones de cada una en su fila |
| `F 0x6C06 5` | las poses de muerte, de cinco patrones |
| `F 0x5AAF 4` | atributos de sprite, un registro —Y, X, patrón, color— por fila |
| `F 0x5701 19` | los dieciocho bloques del surtidor: 6×3 tiles y la altura de la tabla, un bloque por fila |
| `F 0x700D 6` y `F 0x707C 3` | bloques de tiles a su anchura de verdad, seis y tres columnas |
| `F 0x5E54 3,1` | los tres tiles de la piedra en la primera fila y el 0xFF de fin en la suya |
| `F 0x4149 w1` | una tabla de punteros como `defw`, uno por fila |
| `F 0x445E w3` | los seis bytes de parámetros de una llamada al motor: tres palabras, que es lo que son |

Y cuando un puntero cae en un bloque que tiene nombre, ese nombre se escribe al
lado: las veinte entradas de la tabla de estados salen con su
`-> ESTADO_00_ARRANCA`, `-> ESTADO_01_LOGO` y así, y las seis que valen 0x0000
se ven por lo que son.

## Las herramientas

En `tools/`, cada una con su cabecera:

| | |
|---|---|
| `z80trace.py` | sigue el flujo desde los puntos de entrada, saltándose los parámetros en línea |
| `mkasm.py` | monta el listado con las notas ancladas |
| `presupuesto.py` | el reparto de los 16384 bytes, y lo que queda sin dueño |
| `refs.py` | qué instrucciones apuntan a un rango, sin inventar punteros |
| `quien_apunta.py` | para cada hueco, quién lo lee desde código trazado |
| `graficos.py` | reconstruye la memoria de vídeo como la carga el cartucho, y la dibuja |
| `imagenes_web.py` | las imágenes de esta web, cada una una rutina repetida |
| `check_datos_como_codigo.py` | ningún rango declarado como datos puede salir como código |
| `check_entradas.py` | ningún punto de entrada puede caer dentro de uno |
| `omsx_*.tcl` | los arneses de openMSX con los que se midió quién lee qué |
