# El juego

Un niño cruza un parque saltando lo que le sale al paso, contra un reloj. Todo
lo de esta página sale de leer el código que lo hace.

## El mundo es un contador y una tabla de treinta y dos pantallas

La pantalla en la que estás es el byte 0xE054, el SCENE, y es un contador
pelado, no un mapa. Al salirte por el borde, el estado 16 (0x43C0) lo mueve:
**más uno** si saliste por el lado hacia el que ibas, **menos uno** si te
volviste. Bajando del 1 se queda en 1 y cambia el sentido (0x43E0); pasando de
255 cae a **56** (0x43F2). El marcador lo enseña en BCD abajo a la derecha.

Lo que hay en esa pantalla no sale del SCENE sino de **SCENE módulo 32**
(0x5B8F), que es el índice de dos tablas de treinta y dos bytes:

| | |
|---|---|
| 0x5C32 | los obstáculos fijos, un byte por pantalla, a 0xE156 |
| 0x5C52 | los que se mueven, un byte por pantalla, a 0xE158 |

Ese es el mapa entero del juego: sesenta y cuatro bytes.

| bit | 0x5C32 — lo que se construye | 0x5C52 — lo que se mueve |
|---|---|---|
| 0 | cinco charcos en fila | cuántas bolas ruedan (bits 0-2) |
| 1 | dos lianas | |
| 2 | cuatro trampolines, con una fruta encima | |
| 3 | cuatro surtidores con su tabla | arañas que se descuelgan |
| 4 | el estanque de cinco postes | peces |
| 5 | la piedra | el tronco flotante |
| 6 | la hoguera | la bola que bota |
| 7 | el estanque | la abeja |

## Toda pantalla acabada en 0, 4 u 8 sale vacía

Luego la fase retoca la pareja. Primero 0x5BA4 mira el SCENE en BCD y, si la
última cifra es 0, 4 u 8, borra los obstáculos fijos y de los móviles deja solo
la abeja. Después, la fase (0xE051, guardada en BCD):

| fase | lo que quita |
|---|---|
| 1 | las arañas y la abeja |
| 2 | nada; y la abeja se queda clavada en la más alta de sus cuatro alturas |
| 3 | la abeja |
| 4 y siguientes | nada; y en fase par, si la pantalla salió del todo vacía, vuelve a poner la abeja |

Las pantallas acabadas en 0 se vacían una segunda vez, en 0x5E58, que además
dibuja el rótulo **CHILD PARK**: son la entrada —el SCENE 0— y las metas.

![El rótulo CHILD PARK, que dibuja 0x5E58](../imagenes/child-park.png)

La altura de la abeja es una de cuatro, en 0x64A4: 0x38, 0x48, 0x58 y 0x72.
Cuál no está guardado en ninguna parte ni es una secuencia: cada vez que la
abeja se va de la pantalla, 0x6452 lee **el registro de refresco del propio
Z80** y se queda con dos bits. Solo en la fase 2 es fija, y entonces la más
alta de las cuatro, la que pasa por encima de tu cabeza.

## El fondo lo eligen dos bits del SCENE

Los obstáculos salen de las tablas; el fondo no. Antes de colocar nada, 0x5BF2
elige entre dos. Si el bit 1 del SCENE está puesto **y** la pantalla no lleva
lianas, ni trampolines, ni arañas, pinta un cielo: seis filas de franjas sobre
una línea de cerros, uno de cuatro que eligen los bits 2 y 3 (0x5C72).

![Cielo azul con cerros amarillos](../imagenes/cielo-azul-amarillo.png)
![Cielo azul con cerros verdes](../imagenes/cielo-azul-verde.png)
![Cielo rojo con cerros blancos](../imagenes/cielo-rojo-blanco.png)
![Cielo rojo con cerros verdes](../imagenes/cielo-rojo-verde.png)

Si no, pinta el normal (0x5E71): una tira de hierba en la fila 15 y, arriba,
una copa de hojas con un tronco a cada lado. Cada mitad viene en dos formas
—con pendiente o a nivel— y los bits 1 y 2 del SCENE eligen qué pareja va
arriba.

![Copa con las dos mitades en pendiente](../imagenes/cerros-0.png)
![Copa con pendiente a la izquierda y nivel a la derecha](../imagenes/cerros-1.png)
![Copa con las dos mitades a nivel](../imagenes/cerros-2.png)
![Copa con nivel a la izquierda y pendiente a la derecha](../imagenes/cerros-3.png)

De un modo o de otro, la tierra de las filas 16 a 19 va después (0x5CEA), y
solo entonces se colocan encima los obstáculos, una llamada cada uno, en el
orden en que se leen los bits.

## Una fase son diez pantallas

0xE05A guarda la meta, en BCD, y empieza en 10. Llegar a un SCENE acabado en 0
que además sea esa meta (0x692C) —pasando de X 0xC8 yendo a la derecha, o
bajando de X 0x28 yendo a la izquierda— toca la fanfarria y mete al jugador en
el estado 7, que son seis medias vueltas en el sitio y la fase superada.

Luego 0x438B: una vida más, la fase más uno en BCD, la meta diez pantallas más
allá y el tiempo lleno otra vez. Lo que quede de reloj se cobra a **200 puntos
el tramo**, de cuatro en cuatro fotogramas, mientras acaba la música (0x435E).
Superar la fase 99 la devuelve a 00 (0x4295) y saca ALL STAGE CLEAR con los
créditos.

## Los obstáculos que se mueven no arrancan de golpe

Las bolas que ruedan arrancan a los **veinticuatro pasos**. La rutina del
fotograma (0x586A) vigila el contador de pasos 0xE13B y, justo cuando llega a
24, copia 0xE158 en 0xE159.

Y ahí hay que afinar, porque esta página lo contaba mal: **0xE159 solo lo miran
las bolas que ruedan** (0x611B) y la rutina que las cobra (0x6AF4). Los peces
(0x61F3), la bola que bota (0x62DC), las arañas (0x6326), la abeja (0x6426) y el
tronco (0x64A8) leen **0xE158** directamente y salen desde el primer fotograma.
La tregua de dos docenas de pasos es solo con las bolas.

Del estado 7 en adelante el jugador se está muriendo, y entonces no se llama a
ninguna de las once rutinas de obstáculos (0x587A): la pantalla se congela y
solo se mueve él.

## Lo que vale cada cosa

Los puntos se cobran al pasar por delante, no al tocar: 0x6623 recorre una
lista de X y, cuando el jugador ha dejado una atrás, la suma una sola vez y
saca el número flotando sobre su cabeza treinta fotogramas. Se guardan como
nibbles BCD —0x05, 0x10, 0x20—:

| | |
|---|---|
| 50 | cada bola que rueda |
| 100 | cada poste, cada trampolín, cada charco, la hoguera, la piedra, la abeja |
| 200 | la fruta, cada tabla de surtidor, el tronco flotante |

El marcador son seis cifras BCD, y lo que se planta en **999999** es el
**récord**: al desbordar, 0x4669 mete tres 0x99 en 0xE040-0xE042 con dos
escrituras de 16 bits solapadas. Los puntos del jugador (0xE043 y 0xE046) no se
topan: el `daa` da la vuelta y siguen contando desde cero. Hay vida nueva a los 10000 y luego cada 20000 (0x4677); pasado el último
umbral no hay más. Superar una fase vale un **BONUS SCORE 2000** escrito en la
fila 12 (0x4299).

Se empieza con tres vidas y se gasta una cada vez que se entra (0x4271), o sea
que una partida son tres intentos. Se pintan por duplicado: como hasta cuatro
bloques de 2×2 en la fila 21, y como cuatro sprites de cara que cambian de
gesto —normal, preocupada, contenta, llorando— por 0x6699.

## El reloj son 58 tramos y no mata

0xE055 empieza en 0x3A y baja un tramo cada 256 fotogramas (0x65AD). La barra
va de la columna 30 hacia la izquierda por la fila 1, un tile por cada cuatro
tramos, con tres tiles a medias por el camino. Por debajo de 0x10 las cuatro
caras se ponen preocupadas y pita cada 64 fotogramas.

Y en **2 se para** (0x65D1). El reloj no se te acaba nunca: se queda ahí con la
barra vacía. En el código no hay nada que mate al jugador por quedarse sin
tiempo.

## Lo que mata

Cuatro cosas, y solo cuatro:

- **un choque.** 0x6A41 cruza la cabeza del jugador (sprite 4) y sus piernas
  (sprite 6) con los peces, las bolas que ruedan, las arañas, la abeja y la
  bola que bota; las piernas además con el sprite 31, la caja invisible —color
  0x10— que la piedra y la hoguera se ponen delante. La fruta (sprite 19) va en
  el mismo barrido, pero son 200 puntos y un sonido;
- **el agua.** Pisar dentro del estanque (0x689B), o caer en el estanque de
  postes o en el foso de los trampolines (0x676A), te hunde: estado 15, las
  caras llorando, y un paso del arco de hundimiento cada ocho fotogramas;
- **meter el pie en un charco**, que te deja dos puntos más allá y en el mismo
  hundimiento (0x68AE);
- **una caída.** No por la altura a la que llegas: por la altura desde la que
  caíste. Está en [Hallazgos](HALLAZGOS.html).

Morirse no repinta la pantalla: se esconden todos los sprites de obstáculos
(0x68DC), el jugador da vueltas 128 fotogramas (0x69D8), y la máquina de
estados sigue.

## Los mandos, y las cuatro maneras de jugar

Cuatro direcciones y dos botones, en formato de joystick en 0xE009, con lo del
fotograma anterior guardado en 0xE008 para poder distinguir "acaba de pulsar"
de "lo tiene pulsado". El teclado se lee del PPI a pelo —fila 8 para las
flechas y el espacio, fila 7 para SELECT— y se recoloca bit a bit en ese mismo
formato (0x40CB), así que de ahí para dentro nadie sabe cuál estás usando.

En el título, las teclas 1 a 4 eligen cómo jugar (0x40F7), con una tabla de
ocho bytes en 0x4122: un jugador con joystick, dos con joystick, uno con
teclado, dos con teclado. Con dos jugadores se intercambian 32 bytes de estado
al cambiar el turno (0x4329).

## La demo se juega sola, pero no está grabada

La partida de demostración corre el juego con unas cuantas reglas en vez de con
una grabación (0x58B2). En la pantalla 0 corre a la derecha y salta en X 0x38 y
X 0x80. En la 1 mira lo que está haciendo el jugador: andando, da la vuelta al
pasar de X 0xB0 y si no salta al azar —resembrando el contador de fotogramas
con el registro R del propio Z80—; colgado de una liana, se suelta cuando el
contador da la vuelta; montado en el tronco, salta al llegar al borde.

Solo tiene dos pantallas: llegar al SCENE 2 la devuelve al título (0x4408).
