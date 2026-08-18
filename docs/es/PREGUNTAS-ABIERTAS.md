# Preguntas abiertas

Cada byte del cartucho está asignado, el listado devuelve el original byte a
byte y sus 296 etiquetas tienen nombre. Eso no quiere decir que se entienda
todo. Esta página dice qué significan las cifras y qué sigue sin saberse.

## 199 destinos de salto siguen llamándose por su dirección

El listado tiene 296 etiquetas bautizadas y 199 que siguen siendo `L_XXXX`.
Esas 199 son **destinos de saltos dentro de una rutina** —el otro lado de un
`jr nz`, el final de un bucle—, y ninguna es el destino de un `call`: hay un
test que se pone rojo si una rutina a la que se llega con `call` se queda sin
nombre.

O sea que ahí no hay nada sin identificar; lo que falta es un buen nombre para
cada rama. Quien siga tiene un trabajo claro y mecánico esperándole.

## Seis estados que no existen

La tabla de estados del jugador (0x66C2) tiene diecisiete entradas y seis de
ellas son `0000`: los estados 9 a 14. Saltar ahí ejecutaría lo que haya en la
dirección cero y reiniciaría la máquina.

Ninguna instrucción trazada escribe un 9 a 14 en 0xE138, y los estados que sí
se escriben son del 0 al 8, el 15 y el 16. La lectura que encaja es que la
tabla se dejó con un hueco para que el 15 y el 16 conservaran su número, pero
**eso es una lectura, no una medida**: lo demostrado es que no se usan nunca.

## Cinco bytes de código que no llama nadie

0x4523 pone el registro 7 del VDP —el color del borde— con lo que traiga A y
luego remanda los ocho registros. Está bien formado, son tres instrucciones, y
en el cartucho no lo alcanza nada: se declaró como punto de entrada a mano, con
esa nota, porque si no el trazador no lo vería jamás.

Para qué era no se puede saber del binario.

## Algunos nombres salen de los dibujos, no del código

A los obstáculos se les puso nombre reconstruyendo la memoria de vídeo y
mirando el resultado (`tools/graficos.py`), lo cual es firme para las formas
pero no para las intenciones. A las cosas redondas de ocho patas que se
descuelgan de arriba este listado las llama arañas **por lo que parecen**; el
código solo las llama un patrón de sprite.

Con la misma prudencia: los nombres que el listado le da a las dos mitades de
la banda de arriba de la pantalla son internos, y lo que enseñan las imágenes
es una copa de hojas con un tronco a cada lado, en dos formas.

## La reconstrucción no está cotejada contra una captura

Todas las imágenes de esta web salen de repetir las copias y las llamadas de
dibujo del propio cartucho. Eso caza un rango mal etiquetado —saldría ruido—,
pero no se ha comparado píxel a píxel con una foto del juego corriendo.

Dos cosas faltan de ella a sabiendas: los sprites salen en blanco sobre negro,
porque el color de un sprite del MSX1 no está en su patrón sino en el registro
de atributos que el juego escribe en marcha; y las imágenes son las piezas que
pintan las rutinas, no pantallas enteras con sus obstáculos colocados.

Lo que sí se midió es lo que se le dice al VDP: los ocho registros se leyeron
en el emulador con el juego corriendo, y son los ocho bytes de 0x4545.

## El otro volcado

Hay un segundo volcado de este juego, de otra compilación: sha256
`ed5b214fdf7272a509f0fcb0496550cf766fff3b2c39cfc9ba37609da8f3447e`, también de
16384 bytes, que se diferencia de este en 14823. **No** está desensamblado
aquí, y nada de esta web dice nada de él.

## Qué respalda cada cifra, y qué no

- **Reensambla byte a byte.** El listado publicado ensambla y el sha256 es el
  del cartucho.
- **Ni un byte sin explicar.** Los 16384 repartidos en 7.448 de código
  alcanzados por el trazador y 8.936 dentro de rangos declarados, cada uno con
  la instrucción que lo lee anotada al lado.
- **Ninguna zona de datos se lee como código.** Es una comprobación aparte del
  reensamblado, que no puede cazar eso: si unos dibujos se leen como
  instrucciones, los bytes no cambian.
- **Ningún punto de entrada cae dentro de una zona de datos.** Sembrar el
  trazador con una dirección mal deducida inflaría la cobertura sin que saltara
  ninguna alarma.

Lo que el 100 % **no** quiere decir: que se sepa para qué sirve cada byte.
Quiere decir que cada byte está dentro de un rango con nombre, y que ese nombre
sale de leer la instrucción que lo consume. Los casos de las secciones de
arriba son la excepción, y por eso están escritos.

Los comentarios del listado están verificados por muestreo, no línea a línea.

## Cuatro avisos para quien siga

**Un periodo no es una velocidad.** El código dice fotogramas por paso —8, 9,
10, 11 para las fases, 256 para un tramo del reloj—; cuánto dura eso depende de
si la máquina interrumpe cincuenta o sesenta veces por segundo, y las dos cosas
se confunden con facilidad.

**Escribir en 0xE054 no repinta nada.** El SCENE solo se lee al montar una
pantalla, y lo único que monta una es el estado 17 (0x43F9), por 0x5A64 y
0x5AE3. Para recorrer el parque en el emulador hay que dejar que el juego
cambie de pantalla por su cuenta.

**Muestrear el contador de programa desde el encendido miente.** Antes de que
la BIOS mapee el cartucho, en la página 1 está la ROM del BASIC, y un muestreo
arrancado demasiado pronto devuelve direcciones del rango de este cartucho que
no son este cartucho. Todo lo que se mida hay que armarlo desde INIT (0x4077),
nunca desde el reset.

**Buscar punteros a lo bruto miente.** Una racha de bytes repetidos parece un
puntero, y leer un operando desde la mitad de una instrucción da direcciones
verosímiles que no existen. Toda pista salida de ahí se confirma contra el
listado; por eso las herramientas de este repositorio solo recorren principios
de instrucción.
