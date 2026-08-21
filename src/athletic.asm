; ==========================================================================
; ATHLETIC LAND - Konami (1984) - MSX1 - cartucho RC-700 de 16 KB en la pagina 1
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x04000


; ----------------------------------------------------------------------
; DATOS cabecera_del_cartucho: La cabecera que lee la BIOS: "AB", INIT=0x4077
;   y a cero STATEMENT, DEVICE y TEXT. La BIOS mapea el cartucho en la pagina
;   1 (0x4000-0x7FFF) y salta a 0x4077 al terminar de arrancar
;   0x4000..0x4010  (16 bytes)
DATA_cabecera_del_cartucho:
	defb 041h,042h	; 4000
	defw 04077h,00000h,00000h,00000h	; 4002  -> INIT 0x0000 0x0000 0x0000
	defb 000h,000h,000h,000h,000h,000h	; 400a

; ======================================================================
; CODIGO 0x4010..0x4034  (36 bytes)
; ======================================================================


VPOKE:		; Escribe A en la VRAM DE. Salta a 0x4070 para acabar (res 6,d deja DE como estaba)
	di			;4010
	push af			;4011
	set 6,d		;4012
	call VDP_DIRECCION		;4014
	jr $+89		;4017
VPEEK:		; Lee en A el byte de la VRAM DE
	di			;4019   ; Sin interrupciones desde que se pone la direccion hasta que se lee el dato
	call VDP_DIRECCION		;401a   ; Sin poner el bit 6 de D: direccion de LECTURA de la VRAM
	nop			;401d   ; Dos nop de margen entre mandar la direccion y leer el puerto de datos
	nop			;401e
	in a,(098h)		;401f   ; Puerto 0x98: el byte de la VRAM
	ei			;4021
	ret			;4022
VDP_DIRECCION:		; Manda DE al VDP como direccion (con el bit 6 de D a 1 es de escritura)
	ld a,e			;4023
	out (099h),a		;4024
	ld a,d			;4026
	out (099h),a		;4027
	ret			;4029
HL_MAS_A:		; HL = HL + A, sin signo
	add a,l			;402a
	ld l,a			;402b
	ret nc			;402c
	inc h			;402d
	ret			;402e
DE_MAS_A:		; DE = DE + A, sin signo
	add a,e			;402f
	ld e,a			;4030
	ret nc			;4031
	inc d			;4032
	ret			;4033

; ----------------------------------------------------------------------
; DATOS relleno_4034: Cuatro 0xFF entre la ultima rutina y la interrupcion
;   0x4034..0x4038  (4 bytes)
DATA_relleno_4034:
	defb 0ffh,0ffh,0ffh,0ffh	; 4034

; ======================================================================
; CODIGO 0x4038..0x4122  (234 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ######################################################################
; LA INTERRUPCION (gancho H.KEYI). Todo el juego corre aqui dentro:
; INIT la instala y se queda en un jr $ para siempre. Cada fotograma:
; 785D  el sonido, SIEMPRE, aunque el fotograma anterior no acabara
; 40B3  los mandos, solo con partida en marcha (bit 6 de E002)
; 412A  el paso del juego, un estado de la tabla de 0x4149
; E005 es el candado: si un paso tarda mas de un fotograma, la
; siguiente interrupcion solo toca el sonido y se va (0x4067).
; ######################################################################
; ----------------------------------------------------------------------
INTERRUPCION:		; Cada fotograma: sonido, mandos y un paso del juego. Reentrante solo para el sonido
	push af			;4038
	push bc			;4039
	push de			;403a
	push hl			;403b
	push ix		;403c
	di			;403e
	in a,(099h)		;403f   ; Leer el estado del VDP baja la peticion de interrupcion
	call SUENA		;4041   ; El sonido va antes del candado: suena aunque el paso anterior siga a medias
	ld hl,0e005h		;4044
	bit 0,(hl)		;4047   ; Candado echado: paso anterior sin terminar
	jr nz,INTERRUPCION_OCUPADA		;4049
	ld (hl),001h		;404b
	ei			;404d   ; Con el candado echado ya se pueden admitir interrupciones (para el sonido)
	ld a,(0e002h)		;404e
	and 040h		;4051   ; Bit 6: hay partida en marcha
	call nz,LEE_MANDOS		;4053
	call PASO_DEL_JUEGO		;4056   ; Un paso del juego segun E000
	di			;4059
	pop ix		;405a
	pop hl			;405c
	pop de			;405d
	pop bc			;405e
	xor a			;405f
	ld (0e005h),a		;4060
	pop af			;4063
	ei			;4064
	reti		;4065
INTERRUPCION_OCUPADA:		; El paso anterior sigue corriendo: solo ha sonado la musica
	pop ix		;4067   ; Deshace los cinco push de 0x4038 sin abrir el candado E005: lo abre el paso que sigue corriendo
	pop hl			;4069
	pop de			;406a
	pop bc			;406b
	pop af			;406c   ; El AF de la interrupcion, que aqui no lleva nada util
	ei			;406d   ; El sonido ya ha sonado en 0x4041: aunque el paso vaya tarde, la musica no se corta
	reti		;406e
VPOKE_FIN:		; El final de VPOKE: manda el dato y devuelve D sin el bit de escritura
	res 6,d		;4070
	pop af			;4072
	out (098h),a		;4073
	ei			;4075
	ret			;4076

; ----------------------------------------------------------------------
; ######################################################################
; INIT. Pila en 0xE400, RAM 0xE000-0xE3FF a cero, `jp 0x4038` en el
; gancho H.KEYI (0xFD9A), VDP y PSG (44FD), la fuente (4626), y a
; esperar interrupciones para siempre en 0x40A7.
; ######################################################################
; ----------------------------------------------------------------------
INIT:		; Arranque desde la cabecera: prepara RAM, gancho, VDP, PSG y fuente
	di			;4077
	im 1		;4078
	ld sp,0e400h		;407a
	ld hl,0e000h		;407d
	ld de,0e001h		;4080
	ld bc,003ffh		;4083
	ld (hl),000h		;4086
	ldir		;4088
	ld a,0c3h		;408a   ; C3 = jp; el gancho H.KEYI queda como `jp 0x4038`
	ld (0fd9ah),a		;408c
	ld hl,INTERRUPCION		;408f
	ld (0fd9bh),hl		;4092
	ld a,001h		;4095   ; Candado echado mientras dura el arranque: la interrupcion no ejecuta pasos
	ld (0e005h),a		;4097
	call ARRANCA_VDP_Y_PSG		;409a
	call CARGA_FUENTE		;409d
	xor a			;40a0   ; Se abre el candado: la interrupcion ya corre el estado 0
	ld (0e005h),a		;40a1
	in a,(099h)		;40a4
	ei			;40a6
ESPERA_ETERNA:		; Aqui se queda el programa principal; el juego es la interrupcion
	jr ESPERA_ETERNA		;40a7

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL DESPACHADOR. Se llama con el indice en A y la tabla de palabras
; va PEGADA detras del CALL: el POP HL recoge la direccion de retorno,
; que es la tabla. Cinco tablas: 0x4149 (20 estados), 0x41F8 (2),
; 0x5C7F (4), 0x5E85 (4) y 0x66C2 (17). Nunca vuelve al CALL.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
DESPACHA:		; Salta al destino A de la tabla de palabras que va detras del CALL
	add a,a			;40a9
	pop hl			;40aa   ; La direccion de retorno ES la tabla
	call HL_MAS_A		;40ab
	ld e,(hl)			;40ae
	inc hl			;40af
	ld d,(hl)			;40b0
	ex de,hl			;40b1
	jp (hl)			;40b2

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LOS MANDOS. Deja en E009 lo pulsado en este fotograma y en E008 lo
; del anterior, siempre en el formato del joystick: bit0 arriba,
; bit1 abajo, bit2 izquierda, bit3 derecha, bit4 disparo (espacio),
; bit5 segundo boton (tecla SELECT). El teclado se lee del PPI a
; pelo (filas 7 y 8 de la matriz) y se recoloca bit a bit para que
; salga igual. El puerto del joystick lo elige 0x4614 por jugador.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
LEE_MANDOS:		; E009 = ahora, E008 = el fotograma anterior; joystick o teclado segun el bit 4 de E002
	ld a,(0e002h)		;40b3
	bit 4,a		;40b6
	jr nz,LEE_TECLADO		;40b8
	ld a,00eh		;40ba   ; Registro 14 del PSG: el joystick que haya elegido 0x4614
	out (0a0h),a		;40bc
	in a,(0a2h)		;40be
	cpl			;40c0
	and 03fh		;40c1   ; Cuatro direcciones y dos botones
GUARDA_MANDOS:		; Lo de ahora pasa a E009 y lo que habia baja a E008
	ld hl,0e009h		;40c3   ; E009 es lo pulsado ahora; E008, lo del fotograma anterior
	ld c,(hl)			;40c6   ; Lo que habia en E009 se aparta antes de pisarlo...
	ld (hl),a			;40c7
	dec hl			;40c8
	ld (hl),c			;40c9   ; ...y baja a E008; asi 0x6DAA puede ver el flanco del boton en vez de si esta pulsado
	ret			;40ca
LEE_TECLADO:		; Monta el mismo mapa de bits con las filas 7 (SELECT) y 8 (flechas y espacio) del teclado
	ld bc,057aah		;40cb   ; Fila 7 del teclado (0x57: fila 7, motor de cinta y CAPS apagados)
	out (c),b		;40ce
	out (c),b		;40d0
	in a,(0a9h)		;40d2
	cpl			;40d4
	rrca			;40d5
	and 020h		;40d6   ; SELECT (bit 6 de la fila 7) al bit 5: el segundo boton
	ld e,a			;40d8
	inc b			;40d9   ; Fila 8: espacio, flechas
	out (c),b		;40da
	out (c),b		;40dc
	in a,(0a9h)		;40de
	cpl			;40e0
	rrca			;40e1
	rrca			;40e2
	ld b,a			;40e3
	and 004h		;40e4   ; IZQUIERDA al bit 2
	or e			;40e6
	ld c,a			;40e7
	ld a,b			;40e8
	rrca			;40e9
	rrca			;40ea
	ld b,a			;40eb
	and 018h		;40ec   ; DERECHA al bit 3 y ESPACIO al bit 4
	or c			;40ee
	ld c,a			;40ef
	ld a,b			;40f0
	rrca			;40f1
	and 003h		;40f2   ; ARRIBA al bit 0 y ABAJO al bit 1
	or c			;40f4
	jr GUARDA_MANDOS		;40f5

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LAS TECLAS 1-4 DEL MENU. Se miran en cada fotograma del titulo, la
; demo y la partida de demostracion (estados 0-7, 18 y 19). Fila 0
; del teclado, bits 1-4 = teclas 1-4; con la tabla de 0x4122 se
; convierten en las opciones de E002: 1=0x00 un jugador con joystick,
; 2=0x20 dos jugadores con joystick, 3=0x10 uno con teclado, 4=0x30
; dos con teclado. Cualquier otra combinacion (0xFF) no vale.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
TECLAS_1_A_4:		; Si se pulsa 1, 2, 3 o 4: guarda la opcion en E002 y pasa al estado 8 (el menu)
	ld a,050h		;40f7   ; Fila 0 del teclado
	out (0aah),a		;40f9
	out (0aah),a		;40fb
	in a,(0a9h)		;40fd
	cpl			;40ff
	and 01eh		;4100   ; Bits 1-4: teclas 1, 2, 3 y 4
	rra			;4102
	dec a			;4103
	cp 008h		;4104   ; Sin tecla, dec a deja 0xFF: fuera
	ret nc			;4106
	ld hl,04122h		;4107   ; Tabla de 8: 1 -> 0, 2 -> 1, 3 -> 3, 4 -> 7
	call HL_MAS_A		;410a
	ld a,(hl)			;410d
	cp 0ffh		;410e
	ret z			;4110
	ld (0e002h),a		;4111
	xor a			;4114
	ld (0e001h),a		;4115
	ld a,008h		;4118   ; Estado 8: el menu
	ld (0e000h),a		;411a
	call PUERTO_DEL_JOYSTICK		;411d   ; El puerto del joystick del jugador 1
	pop hl			;4120   ; Tira la direccion de retorno: este fotograma ya no despacha ningun estado
	ret			;4121

; ----------------------------------------------------------------------
; DATOS opciones_por_tecla: Ocho bytes indexados por la combinacion de teclas
;   1-4: 00 20 FF 10 FF FF FF 30. Solo valen las cuatro teclas sueltas; el
;   resto es 0xFF
;   0x4122..0x412a  (8 bytes)
DATA_opciones_por_tecla:
	defb 000h,020h,0ffh,010h,0ffh,0ffh,0ffh,030h	; 4122  . .....0

; ======================================================================
; CODIGO 0x412a..0x4149  (31 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; UN PASO DEL JUEGO. Cuenta el fotograma, refresca el rotulo 1P/2P
; si toca (472C), mira las teclas 1-4 fuera de la partida, y salta
; al estado E000 por la tabla de 0x4149.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
PASO_DEL_JUEGO:		; Cada fotograma: contador, parpadeo del 1P/2P, teclas 1-4 y el estado de turno
	ld hl,0e003h		;412a   ; E003, el contador de fotogramas: sube uno por interrupcion y de el cuelgan casi todos los ritmos del juego
	inc (hl)			;412d
	ld a,(0e002h)		;412e
	and 040h		;4131   ; Bit 6 de E002: el rotulo 1P/2P solo parpadea con partida en marcha
	call nz,PARPADEA_1P_2P		;4133
	ld a,(0e000h)		;4136   ; E000, el estado del juego, se guarda en C porque TECLAS_1_A_4 machaca A
	ld c,a			;4139
	cp 012h		;413a   ; Estados 8-17 (menu y partida): aqui no valen las teclas 1-4
	jr nc,L_4142		;413c
	cp 008h		;413e   ; ...y por debajo del 8 tambien; del 8 al 17 son el menu y la partida, donde ya no se puede cambiar de opcion
	jr nc,L_4145		;4140
L_4142:
	call TECLAS_1_A_4		;4142
L_4145:
	ld a,c			;4145
	call DESPACHA		;4146   ; Tabla de 20 estados justo detras

; ----------------------------------------------------------------------
; DATOS tabla_de_estados: Los 20 estados del juego, indice E000. 0 espera; 1-6
;   la secuencia del titulo (KONAMI que sube, VIDEO CARTRIDGE, ATHLETIC LAND,
;   PLAY SELECT, cortinilla); 7,18,19 la partida de demostracion; 8 el menu; 9
;   vida nueva; 10 espera; 11 la partida; 12-14 muerte, cambio de jugador y
;   GAME OVER; 15 fase superada; 16,17 cambio de pantalla. Cierra clavada
;   contra su primer destino, 0x4171
;   0x4149..0x4171  (40 bytes)
DATA_tabla_de_estados:
	defw 04171h	; 4149  -> ESTADO_00_ARRANCA
	defw 04174h	; 414b  -> ESTADO_01_LOGO
	defw 04188h	; 414d  -> ESTADO_02_SUBE_LOGO
	defw 0419ah	; 414f  -> ESTADO_03_ESPERA
	defw 041a5h	; 4151  -> ESTADO_04_TITULO
	defw 041b8h	; 4153  -> ESTADO_05_MENU_QUIETO
	defw 041c0h	; 4155  -> ESTADO_06_CORTINILLA
	defw 041d3h	; 4157  -> ESTADO_07_DEMO
	defw 041f2h	; 4159  -> ESTADO_08_MENU
	defw 04265h	; 415b  -> ESTADO_09_VIDA_NUEVA
	defw 042aah	; 415d  -> ESTADO_10_ESPERA
	defw 042ceh	; 415f  -> ESTADO_11_EN_JUEGO
	defw 042eeh	; 4161  -> ESTADO_12_MUERTE
	defw 04329h	; 4163  -> ESTADO_13_CAMBIO_TURNO
	defw 04340h	; 4165  -> ESTADO_14_GAME_OVER
	defw 0435eh	; 4167  -> ESTADO_15_FASE_SUPERADA
	defw 043c0h	; 4169  -> ESTADO_16_CAMBIA_PANTALLA
	defw 043f9h	; 416b  -> ESTADO_17_PANTALLA_NUEVA
	defw 043c0h	; 416d  -> ESTADO_16_CAMBIA_PANTALLA
	defw 04408h	; 416f  -> ESTADO_19_DEMO_PANTALLA

; ======================================================================
; CODIGO 0x4171..0x41f8  (135 bytes)
; ======================================================================


ESTADO_00_ARRANCA:		; Estado 0: no hace nada; pasa al 1
	jp ESTADO_SIGUIENTE		;4171
ESTADO_01_LOGO:		; Estado 1: si hace falta, la cortinilla (E00B); luego carga el logotipo KONAMI (4B52) y pasa al 2
	ld a,(0e00bh)		;4174   ; E00B lo pone a 1 el fin de la demo (0x41E5): antes del logotipo hay que borrar lo que hubiera
	or a			;4177
	jr z,L_4182		;4178
	call CORTINILLA		;417a   ; Una columna por fotograma; este estado se repite hasta que termine
	ret p			;417d   ; CORTINILLA vuelve positiva mientras le queden columnas
	xor a			;417e   ; Borrada del todo: se apaga la peticion y el logotipo se carga en este mismo fotograma
	ld (0e00bh),a		;417f
L_4182:
	call CARGA_LOGO_KONAMI		;4182   ; Descomprime los 26 tiles del KONAMI grande y prepara la subida
	jp ESTADO_SIGUIENTE		;4185
ESTADO_02_SUBE_LOGO:		; Estado 2: cada dos fotogramas sube una fila el KONAMI (4B75); al llegar arriba pinta VIDEO CARTRIDGE y espera 80 fotogramas en el 3
	ld a,(0e003h)		;4188
	rra			;418b   ; Un fotograma si y otro no
	ret nc			;418c
	call SUBE_LOGO_KONAMI		;418d
	ret nz			;4190
	ld hl,04b29h		;4191   ; "@ VIDEO CARTRIDGE @" en la fila 11
	call PINTA_LISTA		;4194
	jp ESPERA_80_Y_SIGUIENTE		;4197
ESTADO_03_ESPERA:		; Estado 3: pasados los 80 fotogramas, dibuja la pantalla del titulo (4795) y pasa al 4
	ld hl,0e004h		;419a
	dec (hl)			;419d
	ret nz			;419e
	call PANTALLA_DEL_TITULO		;419f
	jp ESTADO_SIGUIENTE		;41a2
ESTADO_04_TITULO:		; Estado 4: va sacando ATHLETIC LAND columna a columna (47CB); al acabar pinta el PLAY SELECT y pasa al 5 con E004 a 0
	ld a,0ffh		;41a5
	ld (0e00fh),a		;41a7
	call TITULO_COLUMNA		;41aa
	ret c			;41ad
	ld hl,04a95h		;41ae   ; El menu de cuatro opciones
	call PINTA_LISTA		;41b1
	xor a			;41b4   ; E004 = 0: el estado 5 esperara 256 fotogramas
	jp ESPERA_A_Y_SIGUIENTE		;41b5
ESTADO_05_MENU_QUIETO:		; Estado 5: 256 fotogramas con el titulo y el menu; luego cortinilla en el 6
	ld hl,0e004h		;41b8
	dec (hl)			;41bb
	ret nz			;41bc
	jp ESPERA_80_Y_SIGUIENTE		;41bd
ESTADO_06_CORTINILLA:		; Estado 6: pasa la cortinilla sin borrar el recuadro SCENE y prepara la partida de demostracion (58A3)
	ld a,0ffh		;41c0   ; E00F a 0xFF: mientras dure la cortinilla no se repinta el recuadro del SCENE (0x45E2)
	ld (0e00fh),a		;41c2
	call CORTINILLA		;41c5   ; Otra vez una columna por fotograma
	ret p			;41c8
	call PREPARA_DEMO		;41c9   ; Ya borrada: fuente, graficos del juego, partida nueva, marcador y la primera pantalla
	xor a			;41cc
	ld (0e00fh),a		;41cd   ; E00F otra vez a 0: a partir de aqui la cortinilla si vuelve a pintar el recuadro
	jp ESTADO_SIGUIENTE		;41d0   ; Al estado 7, la partida de demostracion, sin espera ninguna
ESTADO_07_DEMO:		; Estado 7: un fotograma de la partida de demostracion (58B2). Si muere, vuelve al titulo por el 1; si sale de la pantalla, cambia de pantalla por el 18
	call FOTOGRAMA_DE_DEMO		;41d3
	ld hl,0e00ch		;41d6
	xor a			;41d9
	cp (hl)			;41da   ; E00C: ha muerto
	jr nz,DEMO_TERMINA		;41db
	inc hl			;41dd
	inc hl			;41de
	cp (hl)			;41df   ; E00E: se ha salido de la pantalla
	ret z			;41e0
	ld a,011h		;41e1   ; Estado 17+1 = 18: cambio de pantalla de la demo
	jr ESTADO_A_MAS_UNO		;41e3
DEMO_TERMINA:		; Vuelve al estado 1 pidiendo cortinilla (E00B)
	ld a,001h		;41e5
	ld (0e00bh),a		;41e7
	xor a			;41ea
	ld (hl),a			;41eb
ESTADO_A_MAS_UNO:		; Pone el estado A, E004 = 80 y suma 1 (igual que 0x43B1)
	ld (0e000h),a		;41ec
	jp ESPERA_80_Y_SIGUIENTE		;41ef
ESTADO_08_MENU:		; Estado 8: el menu, en dos pasos por E001
	ld a,(0e001h)		;41f2
	call DESPACHA		;41f5

; ----------------------------------------------------------------------
; DATOS tabla_del_menu: Los dos pasos del menu: 0x41FC pinta, 0x421C hace
;   parpadear la opcion elegida
;   0x41f8..0x41fc  (4 bytes)
DATA_tabla_del_menu:
	defw 041fch	; 41f8  -> MENU_0_PINTA
	defw 0421ch	; 41fa  -> MENU_1_PARPADEA

; ======================================================================
; CODIGO 0x41fc..0x4243  (71 bytes)
; ======================================================================


MENU_0_PINTA:		; Paso 0: cortinilla entera de golpe, titulo y menu de una vez, la musica del menu (0x9C) y 80 fotogramas para elegir
	ld a,050h		;41fc
	ld (0e004h),a		;41fe
MENU_CORTINILLA_BUCLE:		; La cortinilla entera, columna a columna, sin salir
	call CORTINILLA		;4201   ; La cortinilla completa dentro de este mismo fotograma
	jp p,MENU_CORTINILLA_BUCLE		;4204
	call PANTALLA_DEL_TITULO		;4207
	call TITULO_DE_GOLPE		;420a   ; Titulo, KONAMI 1984 y menu de golpe
	ld a,09ch		;420d   ; Musica del menu
	call SONIDO		;420f
	ld a,050h		;4212
	ld (0e004h),a		;4214
	ld hl,0e001h		;4217
	inc (hl)			;421a
	ret			;421b
MENU_1_PARPADEA:		; Paso 1: durante 80 fotogramas la opcion elegida parpadea (bit 3 de E004); al acabar arranca la partida (4256)
	ld hl,0e004h		;421c
	dec (hl)			;421f
	jr z,$+54		;4220   ; A cero: empieza la partida (0x4256)
	bit 3,(hl)		;4222
	jr nz,$+35		;4224   ; Con el bit 3 a 1 se vuelve a pintar el menu (0x4247)
	ld a,(0e002h)		;4226
	rra			;4229   ; Bits 4-5 de E002: la opcion, 0-3
	rra			;422a
	rra			;422b
	rra			;422c
	and 003h		;422d
	ld hl,04243h		;422f
	call HL_MAS_A		;4232
	ld a,(hl)			;4235
	ld de,03a00h		;4236   ; La fila de la opcion, borrada entera
	call DE_MAS_A		;4239
	ld bc,00020h		;423c
	xor a			;423f
	jp RELLENA_VRAM		;4240

; ----------------------------------------------------------------------
; DATOS fila_por_opcion: Desplazamiento en la tabla de nombres de la fila de
;   cada opcion desde 0x3A00: 0x00 (fila 16, un jugador joystick), 0x80 (fila
;   20, uno con teclado), 0x40 (fila 18, dos con joystick), 0xC0 (fila 22, dos
;   con teclado)
;   0x4243..0x4247  (4 bytes)
DATA_fila_por_opcion:
	defb 000h,080h,040h,0c0h	; 4243

; ======================================================================
; CODIGO 0x4247..0x445e  (535 bytes)
; ======================================================================


TITULO_DE_GOLPE:		; Saca las 17 columnas de ATHLETIC LAND, el KONAMI 1984 y el menu en una sola llamada
	call TITULO_COLUMNA		;4247   ; En el menu el titulo no se anima: las 52 llamadas de TITULO_COLUMNA caben en este fotograma
	jr c,TITULO_DE_GOLPE		;424a   ; Acarreo mientras quede columna o quede KONAMI 1984 que repintar
	xor a			;424c
	ld (0e00ah),a		;424d   ; E00A, el contador de columnas, a cero para la proxima vez que se anime
	ld hl,04a95h		;4250   ; Y encima el menu de las cuatro opciones
	jp PINTA_LISTA		;4253
MENU_ARRANCA_PARTIDA:		; Prepara la partida (44C8) y pasa al estado 9 con cortinilla
	call PARTIDA_NUEVA		;4256   ; Vidas, fase, tiempo y puntos a los valores de arranque de 0x44F2
	ld a,0ffh		;4259
	ld (0e00fh),a		;425b   ; E00F a 0xFF: la cortinilla del estado 9 no repintara el recuadro del SCENE
	inc a			;425e   ; El inc a deja 0: con E001 a cero, el estado 9 saca PLAYER 1 aunque se juegue solo
	ld (0e001h),a		;425f
	jp ESPERA_80_Y_SIGUIENTE		;4262   ; 80 fotogramas y al estado 9
ESTADO_09_VIDA_NUEVA:		; Estado 9: tras la cortinilla, una vida menos, fuente y decorado, marcador, PLAYER n si son dos, y BONUS SCORE 2000 o los creditos si viene de superar fase
	call CORTINILLA		;4265
	ret p			;4268
	ld hl,0e002h		;4269
	set 6,(hl)		;426c   ; Bit 6: la partida esta en marcha
	ld hl,0e050h		;426e
	dec (hl)			;4271   ; Una vida menos
	call CARGA_FUENTE		;4272
	call CARGA_GRAFICOS_JUEGO		;4275
	call MARCADOR		;4278
	ld a,(0e001h)		;427b
	or a			;427e
	ld hl,04b20h		;427f   ; "PLAYER" y el numero, solo cuando E001 vale 0. OJO: eso NO es "solo con dos jugadores". E001 es el subestado, y quien lo pone a 0x20 con un jugador es SUBESTADO_POR_JUGADORES (0x444F), que solo la llaman el estado 12 (muerte, 0x4324) y el 15 (fase superada, 0x43A1). La primera vez que se entra aqui viene del menu por 0x425E, que deja E001 a 0 sin mirar cuantos juegan: al empezar la partida sale PLAYER 1 aunque se juegue solo
	call z,ROTULO_Y_JUGADOR		;4282
	ld hl,0e00dh		;4285
	xor a			;4288
	cp (hl)			;4289   ; E00D: se viene de superar una fase
	jr z,L_42A5		;428a
	ld (hl),a			;428c
	ld a,00ah		;428d   ; Sonido de fase superada
	call SONIDO		;428f
	ld a,(0e051h)		;4292
	or a			;4295   ; La fase ha dado la vuelta de 99 a 00: ALL STAGE CLEAR y los creditos
	jp z,ALL_STAGE_CLEAR		;4296
	ld hl,04b3fh		;4299   ; "BONUS SCORE 2000" en la fila 12
	call PINTA_LISTA		;429c
	ld de,02000h		;429f   ; 2000 puntos
	call SUMA_PUNTOS		;42a2
L_42A5:
	ld a,090h		;42a5   ; 144 fotogramas de espera en el estado 10
	jp ESPERA_A_Y_SIGUIENTE		;42a7
ESTADO_10_ESPERA:		; Estado 10: pasada la espera, sonido de salida, borra las filas 9 y 12, arranca la pantalla (5857) y entra en juego
	ld hl,0e004h		;42aa
	dec (hl)			;42ad
	ret nz			;42ae
	ld a,08eh		;42af   ; Sonido de salida
	call SONIDO		;42b1
	xor a			;42b4
	ld de,03920h		;42b5   ; Fila 9: PLAYER n
	ld bc,00020h		;42b8
	call RELLENA_VRAM		;42bb
	ld de,03980h		;42be   ; Fila 12: BONUS SCORE
	ld bc,00020h		;42c1
	xor a			;42c4
	call RELLENA_VRAM		;42c5
	call MONTA_PANTALLA		;42c8
	jp ESPERA_80_Y_SIGUIENTE		;42cb
ESTADO_11_EN_JUEGO:		; Estado 11: un fotograma de partida (585E) y mira como acabo: muerte (E00C) al 12, fase superada (E00D) al 15, cambio de pantalla (E00E) al 16
	call FOTOGRAMA_DE_PARTIDA		;42ce
	ld hl,0e00ch		;42d1
	xor a			;42d4
	cp (hl)			;42d5   ; E00C: ha muerto
	jp nz,ESPERA_80_Y_SIGUIENTE		;42d6
	inc hl			;42d9
	cp (hl)			;42da   ; E00D: fase superada
	jr nz,A_FASE_SUPERADA		;42db
	inc hl			;42dd
	cp (hl)			;42de   ; E00E: sale de la pantalla
	ret z			;42df
	ld a,00fh		;42e0   ; 15+1 = 16: cambio de pantalla
	ld (0e000h),a		;42e2
	jp ESTADO_A_MAS_UNO		;42e5
A_FASE_SUPERADA:		; Al estado 15
	ld a,00fh		;42e8
	ld (0e000h),a		;42ea
	ret			;42ed
ESTADO_12_MUERTE:		; Estado 12: con vidas, sonido de muerte y vida nueva (o turno del otro); sin vidas, GAME OVER y al 14
	xor a			;42ee
	ld (0e00ch),a		;42ef
	ld (0e00fh),a		;42f2
	ld a,(0e050h)		;42f5
	or a			;42f8   ; Quedan vidas
	jr nz,MUERTE_CON_VIDAS		;42f9
	call CORTINILLA		;42fb
	ret p			;42fe
	ld a,093h		;42ff   ; Sonido de GAME OVER
	call SONIDO		;4301
	ld hl,04b13h		;4304   ; "GAME  OVER" en la fila 11 y "PLAYER n" en la 9
	call ROTULO_Y_JUGADOR		;4307
	ld a,00dh		;430a   ; 13+1 = 14: la espera del GAME OVER
	ld (0e000h),a		;430c
	xor a			;430f
	jp ESPERA_A_Y_SIGUIENTE		;4310
MUERTE_CON_VIDAS:		; Sonido de muerte; si el otro jugador tiene vidas, al 13 (cambio de turno); si no, vida nueva por el 9
	ld a,090h		;4313   ; Sonido de muerte
	call SONIDO		;4315
	ld a,(0e080h)		;4318   ; Vidas del otro jugador
	or a			;431b
	ld hl,0e001h		;431c
	ld (hl),000h		;431f
	jp nz,ESTADO_SIGUIENTE		;4321
	call SUBESTADO_POR_JUGADORES		;4324
	jr L_433E		;4327
ESTADO_13_CAMBIO_TURNO:		; Estado 13: intercambia los 32 bytes de los dos jugadores, cambia el bit 7 de E002 y el puerto del joystick, y vida nueva por el 9
	ld hl,0e050h		;4329
	ld de,0e080h		;432c
	ld b,020h		;432f
	call INTERCAMBIA		;4331
	ld hl,0e002h		;4334
	ld a,(hl)			;4337
	xor 080h		;4338   ; Cambia de jugador
	ld (hl),a			;433a
	call PUERTO_DEL_JOYSTICK		;433b
L_433E:
	jr A_VIDA_NUEVA		;433e
ESTADO_14_GAME_OVER:		; Estado 14: 256 fotogramas de GAME OVER; luego el turno del otro (13) o vuelta al titulo con cortinilla (E00B)
	ld hl,0e004h		;4340
	dec (hl)			;4343
	ret nz			;4344
	ld a,(0e080h)		;4345   ; Si el otro jugador tiene vidas, sigue el
	or a			;4348
	ld a,00ch		;4349
	jr nz,CAMBIA_ESTADO_ESPERA		;434b
	ld hl,0e002h		;434d
	res 6,(hl)		;4350   ; Se acabo la partida
	ld a,050h		;4352
	ld (0e004h),a		;4354
	ld (0e00bh),a		;4357
	xor a			;435a
	jp CAMBIA_ESTADO_ESPERA		;435b
ESTADO_15_FASE_SUPERADA:		; Estado 15: espera a que acabe la musica; cada 4 fotogramas convierte el tiempo que queda en 200 puntos; al agotarse, fase siguiente, vida extra y vida nueva por el 9
	ld a,0ech		;435e   ; Sonido 0xEC por 0x6699
	call CARAS_DE_LAS_VIDAS		;4360
	ld hl,0e11ch		;4363   ; Las cuatro caras de las vidas (sprites 27-30) a la VRAM
	ld de,03b6ch		;4366
	ld bc,00010h		;4369
	call COPIA_A_VRAM		;436c
	ld a,(0e012h)		;436f   ; E012: canal A ocupado, la musica sigue sonando
	or a			;4372
	ret nz			;4373
	ld a,(0e003h)		;4374
	and 003h		;4377   ; Cada cuatro fotogramas
	ret nz			;4379
	ld a,(0e055h)		;437a
	cp 002h		;437d   ; Tiempo agotado
	jr z,FASE_SIGUIENTE		;437f
	ld de,00200h		;4381   ; 200 puntos por cada tramo de tiempo
	call SUMA_PUNTOS_CON_SONIDO		;4384
	call TIEMPO_UN_TRAMO_MENOS		;4387
	ret			;438a
FASE_SIGUIENTE:		; Una vida mas, fase+1 en BCD, la meta diez SCENE mas alla (E05A), y el tiempo lleno (0x3A) para la fase nueva
	ld hl,0e050h		;438b
	inc (hl)			;438e
	inc hl			;438f
	ld a,(hl)			;4390
	add a,001h		;4391
	daa			;4393
	ld (hl),a			;4394
	ld hl,0e05ah		;4395
	ld a,(hl)			;4398
	add a,010h		;4399
	daa			;439b
	ld (hl),a			;439c
	xor a			;439d
	ld (0e00fh),a		;439e
	call SUBESTADO_POR_JUGADORES		;43a1
	ld a,03ah		;43a4
	ld (0e055h),a		;43a6   ; Tiempo lleno: 0x3A tramos
	ld hl,0383eh		;43a9   ; La barra de tiempo empieza en la fila 1, columna 30
	ld (0e056h),hl		;43ac
A_VIDA_NUEVA:		; Estado 9 con 80 fotogramas de espera
	ld a,008h		;43af
CAMBIA_ESTADO_ESPERA:		; Pone el estado A, E004 = 80 y suma 1
	ld (0e000h),a		;43b1
	jr ESPERA_80_Y_SIGUIENTE		;43b4
ESPERA_80_Y_SIGUIENTE:		; E004 = 80 y estado siguiente
	ld a,050h		;43b6
ESPERA_A_Y_SIGUIENTE:		; E004 = A y estado siguiente
	ld (0e004h),a		;43b8
ESTADO_SIGUIENTE:		; E000 + 1
	ld hl,0e000h		;43bb
	inc (hl)			;43be
	ret			;43bf
ESTADO_16_CAMBIA_PANTALLA:		; Estado 16 (y 18 en la demo): calla los efectos, cortinilla y SCENE +1 o -1 segun el sentido de la marcha (bit 0 de E053) y por donde salio (bit 1 de E00E); en la 1 da la vuelta
	ld a,006h		;43c0   ; Sonido 6: calla el canal de efectos (el zumbido de la abeja) al dejar la pantalla
	call SONIDO		;43c2
	xor a			;43c5
	ld (0e00fh),a		;43c6
	call CORTINILLA		;43c9
	ret p			;43cc
	ld hl,0e00eh		;43cd   ; Bit 1 de E00E: salio por la derecha; se cruza con el sentido (bit 0 de E053)
	ld b,(hl)			;43d0
	ld (hl),000h		;43d1
	ld hl,0e053h		;43d3
	ld a,(hl)			;43d6
	bit 1,b		;43d7
	jr z,L_43DC		;43d9
	cpl			;43db
L_43DC:
	inc hl			;43dc
	rra			;43dd   ; Por la derecha con sentido 0, o por la izquierda con sentido 1: SCENE+1; si no, SCENE-1
	jr c,L_43EF		;43de
	dec (hl)			;43e0   ; Retrocede: al bajar de 1 se queda en 1 y cambia el sentido
	ld a,(hl)			;43e1
	jr z,L_43E7		;43e2
	inc a			;43e4
	jr nz,L_43ED		;43e5
L_43E7:
	ld a,001h		;43e7
	ld (hl),a			;43e9
	dec hl			;43ea
	xor (hl)			;43eb
	ld (hl),a			;43ec
L_43ED:
	jr L_43F4		;43ed
L_43EF:
	inc (hl)			;43ef   ; Avanza: si se pasa de 255, a 56
	jr nz,L_43F4		;43f0
	ld (hl),038h		;43f2
L_43F4:
	call SCENE_A_BCD		;43f4   ; SCENE a BCD para el marcador
	jr ESPERA_80_Y_SIGUIENTE		;43f7
ESTADO_17_PANTALLA_NUEVA:		; Estado 17: monta la pantalla nueva (5A64, 5AE3), pinta el SCENE y vuelve al juego (11)
	call BORRA_PANTALLA		;43f9   ; Borra el estado EN RAM de la pantalla anterior (E130-E330); el decorado ya lo borro la cortinilla del estado 16
	call CONSTRUYE_PANTALLA		;43fc   ; Monta la pantalla nueva entera: sprites, lianas, decorado y obstaculos
	call PINTA_SCENE		;43ff   ; El SCENE nuevo en el recuadro de abajo a la derecha
	ld a,00bh		;4402   ; Vuelta al estado 11, el de jugar, sin espera ninguna
	ld (0e000h),a		;4404
	ret			;4407
ESTADO_19_DEMO_PANTALLA:		; Estado 19: la demo solo tiene dos pantallas: en la 2 vuelve al titulo; si no, monta la pantalla y sigue la demo en el 7
	ld hl,0e054h		;4408   ; E054, el numero de pantalla; el estado 18 acaba de subirlo
	ld a,(hl)			;440b
	cp 002h		;440c   ; La demo solo ensena la 0 y la 1: al llegar a la 2 se acaba y se vuelve al titulo
	jp z,DEMO_TERMINA		;440e
	call BORRA_PANTALLA		;4411   ; Igual que el estado 17, pero aqui si hay que repintar el marcador...
	call MARCADOR		;4414   ; ...porque en la demo el bit 6 de E002 esta apagado y la cortinilla borra las 24 filas, no solo las 19 de en medio
	call CONSTRUYE_PANTALLA		;4417
	ld a,006h		;441a   ; Estado 6+1 = 7 con 80 fotogramas de espera: sigue la demo
	jp CAMBIA_ESTADO_ESPERA		;441c
ROTULO_Y_JUGADOR:		; Pinta la lista HL y el numero del jugador (1 o 2, bit 7 de E002) en la fila 9, columna 19
	call PINTA_LISTA		;441f
	ld a,(0e002h)		;4422
	rlca			;4425   ; Bit 7 al bit 0: 0 o 1
	and 001h		;4426
	add a,031h		;4428   ; '1' o '2'
	ld de,03933h		;442a
	call VPOKE		;442d
	ret			;4430
SCENE_A_BCD:		; E059 = E054 en BCD (dos cifras: E054 modulo 100)
	ld a,(0e054h)		;4431
SCENE_A_BCD_RESTA_100:		; Quita centenas
	ld b,a			;4434
	sub 064h		;4435
	jr nc,SCENE_A_BCD_RESTA_100		;4437
	ld c,000h		;4439
SCENE_A_BCD_DECENAS:		; Cuenta decenas en el nibble alto de C
	ld a,b			;443b   ; Lo que quedo tras quitar las centenas, de diez en diez
	sub 00ah		;443c
	jr c,L_4449		;443e   ; Por debajo de diez, lo que queda son las unidades y ya estan en B
	push af			;4440
	ld a,c			;4441
	add a,010h		;4442   ; Cada resta suma una decena al nibble alto de C
	ld c,a			;4444
	pop af			;4445
	ld b,a			;4446
	jr nz,SCENE_A_BCD_DECENAS		;4447   ; El pop af ha devuelto las banderas del sub: se para justo cuando el resto da cero
L_4449:
	ld a,c			;4449
	or b			;444a
	ld (0e059h),a		;444b
	ret			;444e
SUBESTADO_POR_JUGADORES:		; E001 = 0x20 con un jugador, 0 con dos (con dos se pinta PLAYER n)
	ld hl,0e001h		;444f   ; E001, el subestado, que en la partida solo dice si hay que pintar PLAYER n
	ld a,(0e002h)		;4452   ; Bit 5 de E002: dos jugadores
	xor 020h		;4455   ; Se invierte y se aisla: con dos jugadores queda 0 y con uno 0x20
	and 020h		;4457
	ld (hl),a			;4459   ; Y el estado 9 saca el rotulo PLAYER solo cuando E001 vale 0
	ret			;445a
ALL_STAGE_CLEAR:		; La fase 99 superada: los creditos por el motor de rotulos y espera sin limite
	call MOTOR_DE_ROTULOS		;445b

; ----------------------------------------------------------------------
; DATOS parametros_de_445B: Los seis bytes del call 0x5F65: lista 0x4468,
;   tiles 0x447E, VRAM 0x38A7 (fila 5, columna 7)
;   0x445e..0x4464  (6 bytes)
DATA_parametros_de_445B:
	defw 04468h,0447eh,038a7h	; 445e  -> DATA_creditos_lista DATA_creditos_tiles 0x38a7

; ======================================================================
; CODIGO 0x4464..0x4468  (4 bytes)
; ======================================================================


ALL_STAGE_CLEAR_ESPERA:		; Al estado 10 con E004 = 0
	xor a			;4464
	jp ESPERA_A_Y_SIGUIENTE		;4465

; ----------------------------------------------------------------------
; DATOS creditos_lista: Lista del motor de rotulos: relleno de 18 en la fila
;   5, copia de 18 en la 6, relleno de 18 en la 7 (el marco), y copias de 18
;   en las filas 16, 17 y 18 (los creditos)
;   0x4468..0x447e  (22 bytes)
DATA_creditos_lista:
	defb 092h,080h,0c7h,038h,012h,080h,0e7h,038h,092h,080h,007h,03ah,012h,080h,027h,03ah	; 4468  ...8...8...:..':
	defb 012h,080h,047h,03ah,012h,000h	; 4478

; ----------------------------------------------------------------------
; DATOS creditos_tiles: Los tiles: la raya (0x40) del marco, "ALL STAGE
;   CLEAR", y "PROGRAM A.H Y.I", "SOUND Y.O", "CG R.S C.K" con rayas de
;   relleno entre el oficio y las iniciales
;   0x447e..0x44c8  (74 bytes)
DATA_creditos_tiles:
	defb 040h,040h,041h,04ch,04ch,001h,053h,054h,041h,047h,045h,001h,043h,04ch,045h,041h	; 447e  @@ALL.STAGE.CLEA
	defb 052h,001h,040h,040h,050h,052h,04fh,047h,052h,041h,04dh,040h,040h,040h,040h,041h	; 448e  R.@@PROGRAM@@@@A
	defb 0adh,048h,001h,059h,0adh,049h,053h,04fh,055h,04eh,044h,001h,001h,040h,040h,040h	; 449e  .H.Y.ISOUND..@@@
	defb 040h,059h,0adh,04fh,001h,001h,001h,001h,043h,047h,001h,001h,001h,001h,001h,040h	; 44ae  @Y.O....CG.....@
	defb 040h,040h,040h,052h,0adh,053h,001h,043h,0adh,04bh	; 44be  @@@R.S.C.K

; ======================================================================
; CODIGO 0x44c8..0x44f2  (42 bytes)
; ======================================================================


PARTIDA_NUEVA:		; Borra E043-E142, copia los 11 valores iniciales a E050 y, con dos jugadores, tambien a E080
	ld hl,0e043h		;44c8   ; Desde E043, los puntos del 1P; el record (E040-E042) se salva
	ld de,0e044h		;44cb
	ld bc,00100h		;44ce   ; 0x100 bytes mas el propio E043: se borra hasta E143
	ld (hl),000h		;44d1
	ldir		;44d3
	ld hl,044f2h		;44d5   ; Los once valores de arranque al jugador que va a jugar
	ld de,0e050h		;44d8
	ld bc,0000bh		;44db
	ldir		;44de
	ld a,(0e002h)		;44e0
	bit 5,a		;44e3   ; Bit 5: dos jugadores
	ret z			;44e5   ; Con un solo jugador no hay copia que hacer
	ld hl,0e050h		;44e6   ; Con dos, los 32 bytes de E050 se clonan en E080: el segundo arranca igual
	ld de,0e080h		;44e9
	ld bc,00020h		;44ec
	ldir		;44ef
	ret			;44f1

; ----------------------------------------------------------------------
; DATOS valores_iniciales: Los 11 bytes que arrancan al jugador en E050: 3
;   vidas, fase 1, vida extra a 0, sentido 0, SCENE 0, tiempo 0x3A, barra en
;   0x383E, entra por la izquierda (8), SCENE en BCD 0, y la meta en el SCENE
;   10
;   0x44f2..0x44fd  (11 bytes)
DATA_valores_iniciales:
	defb 003h,001h,000h,000h,000h,03ah,03eh,038h,008h,000h,010h	; 44f2  .....:>8...

; ======================================================================
; CODIGO 0x44fd..0x4545  (72 bytes)
; ======================================================================


ARRANCA_VDP_Y_PSG:		; Registros del VDP, mezclador del PSG (0xB8), puerto del joystick, volumenes a cero y VRAM entera a cero
	call REGISTROS_DEL_VDP		;44fd
	ld a,007h		;4500   ; Registro 7 del PSG: los tres tonos, sin ruido
	out (0a0h),a		;4502
	ld a,0b8h		;4504
	out (0a1h),a		;4506
	call PUERTO_DEL_JOYSTICK		;4508
	xor a			;450b
	ld bc,003a0h		;450c   ; Registros 8, 9 y 10 a cero: los tres volumenes
	ld d,008h		;450f
L_4511:
	out (c),d		;4511
	inc d			;4513
	out (0a1h),a		;4514
	djnz L_4511		;4516
	ld de,00000h		;4518   ; Los 16 KB de VRAM a cero
	ld bc,04000h		;451b
	xor a			;451e
	call RELLENA_VRAM		;451f
	ret			;4522
COLOR_DE_BORDE:		; Nadie lo llama: pondria A en el registro 7 (borde) y remandaria los 8 registros
	ld (0e03fh),a		;4523
	jr MANDA_REGISTROS_VDP		;4526
REGISTROS_DEL_VDP:		; Copia los 8 valores de 0x4545 a E038 y los manda al VDP
	ld hl,04545h		;4528
	ld de,0e038h		;452b
	ld bc,00008h		;452e
	ldir		;4531
MANDA_REGISTROS_VDP:		; Manda al VDP los 8 registros guardados en E038
	ld hl,0e038h		;4533
	ld b,008h		;4536
	ld d,080h		;4538
L_453A:
	ld e,(hl)			;453a   ; El valor del registro, sacado de la copia E038-E03F
	di			;453b
	call VDP_DIRECCION		;453c   ; Escribir un registro del VDP es mandar el dato por el 0x99 y detras 0x80 mas el numero
	ei			;453f
	inc hl			;4540
	inc d			;4541   ; D arranca en 0x80 y sube: los ocho registros, del 0 al 7
	djnz L_453A		;4542
	ret			;4544

; ----------------------------------------------------------------------
; DATOS registros_del_vdp: R0=02 SCREEN 2, R1=E2
;   16K/pantalla/interrupciones/sprites de 16x16, R2=0E nombres en 0x3800,
;   R3=7F colores en 0x0000, R4=07 patrones en 0x2000, R5=76 atributos de
;   sprites en 0x3B00, R6=03 patrones de sprites en 0x1800, R7=E1 borde negro
;   0x4545..0x454d  (8 bytes)
DATA_registros_del_vdp:
	defb 002h	; 4545
	defb 0e2h	; 4546
	defb 00eh	; 4547
	defb 07fh	; 4548
	defb 007h	; 4549
	defb 076h	; 454a
	defb 003h	; 454b
	defb 0e1h	; 454c

; ======================================================================
; CODIGO 0x454d..0x45e2  (149 bytes)
; ======================================================================


COPIA_A_VRAM:		; BC bytes de HL a la VRAM DE
	di			;454d
	set 6,d		;454e
	call VDP_DIRECCION		;4550
	res 6,d		;4553
COPIA_A_VRAM_BUCLE:		; El bucle de salida, con la direccion ya puesta
	ld a,(hl)			;4555
	out (098h),a		;4556   ; El puerto 0x98 va solo: el VDP adelanta la direccion en cada byte
	inc hl			;4558
	dec bc			;4559
	ld a,b			;455a
	or c			;455b
	jr nz,COPIA_A_VRAM_BUCLE		;455c
	ei			;455e   ; El di solo protegia poner la direccion
	ret			;455f
RELLENA_VRAM:		; BC bytes de A en la VRAM DE
	di			;4560
	ld h,a			;4561
	set 6,d		;4562
	call VDP_DIRECCION		;4564
	res 6,d		;4567
L_4569:
	ld a,h			;4569   ; H guarda el byte de relleno porque A se gasta en la cuenta
	out (098h),a		;456a   ; El VDP adelanta solo la direccion: basta con repetir por el 0x98
	dec bc			;456c
	ld a,b			;456d
	or c			;456e
	jr nz,L_4569		;456f
	ei			;4571   ; Las interrupciones vuelven al salir; el di solo tapaba el poner la direccion
	ret			;4572
COPIA_VRAM_A_VRAM:		; BC bytes de la VRAM DE a la VRAM HL, byte a byte
	call VPEEK		;4573   ; Un byte de la VRAM DE...
	ex de,hl			;4576
	call VPOKE		;4577   ; ...a la VRAM HL; VPEEK y VPOKE mandan la direccion cada vez
	ex de,hl			;457a
	inc hl			;457b
	inc de			;457c
	dec bc			;457d
	ld a,c			;457e
	or b			;457f
	jr nz,COPIA_VRAM_A_VRAM		;4580
	ret			;4582
TRIPLICA_PATRONES:		; Copia el primer tercio de la tabla de patrones (0x2000) a los otros dos
	ld de,02000h		;4583
	ld hl,02800h		;4586
L_4589:
	ld bc,00800h		;4589
	call COPIA_VRAM_A_VRAM		;458c
	ld bc,00800h		;458f
	jr COPIA_VRAM_A_VRAM		;4592
TRIPLICA_COLORES:		; Lo mismo con la tabla de colores (0x0000)
	ld de,00000h		;4594
	ld hl,00800h		;4597
	jr L_4589		;459a

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LA CORTINILLA. Borra la pantalla desde el centro hacia los lados,
; una columna por fotograma: 15, 16, 14, 17, 13, 18... con E004 de
; contador y su bit 6 marcando de que lado toca. Con partida en
; marcha respeta las dos filas de arriba y las tres de abajo (borra 19
; filas desde la 2). Devuelve el signo: mientras
; queda por borrar, positivo (los que la llaman hacen `ret p`).
; Esconde los sprites (0xD0) y, salvo con E00F, borra el recuadro SCENE.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
CORTINILLA:		; Borra una columna por fotograma desde el centro; negativo cuando termina
	ld d,038h		;459c
	ld hl,0e004h		;459e
	ld b,018h		;45a1
	bit 6,(hl)		;45a3   ; Bit 6: toca la columna de la derecha
	jr nz,L_45AF		;45a5
	ld a,01fh		;45a7   ; Columna 31 - E004: la de la derecha
	sub (hl)			;45a9
	ld e,a			;45aa
	set 6,(hl)		;45ab
	jr L_45B4		;45ad
L_45AF:
	res 6,(hl)		;45af
	dec (hl)			;45b1   ; Se acabo: negativo
	ret m			;45b2
	ld e,(hl)			;45b3
L_45B4:
	ld a,(0e002h)		;45b4
	and 040h		;45b7   ; Con partida en marcha, desde la fila 2 y solo 19 filas
	jr z,L_45C1		;45b9
	ld a,040h		;45bb
	add a,e			;45bd
	ld e,a			;45be
	ld b,013h		;45bf
L_45C1:
	xor a			;45c1
	call VPOKE		;45c2
	ld a,020h		;45c5
	call DE_MAS_A		;45c7
	djnz L_45C1		;45ca
	ld de,03b00h		;45cc   ; 0xD0 en el primer atributo: ningun sprite se pinta
	ld a,0d0h		;45cf
	call VPOKE		;45d1
	ld a,(0e00fh)		;45d4   ; E00F: no borrar el recuadro SCENE
	or a			;45d7
	jr nz,L_45E0		;45d8
	ld hl,045e2h		;45da
	call PINTA_LISTA		;45dd
L_45E0:
	xor a			;45e0
	ret			;45e1

; ----------------------------------------------------------------------
; DATOS borra_recuadro_scene: Lista de rotulo: ocho ceros en la fila 21,
;   columna 22, y otros ocho en la 22: borra el recuadro donde va SCENE
;   0x45e2..0x45f8  (22 bytes)
DATA_borra_recuadro_scene:
	defb 0b6h,03ah,000h,000h,000h,000h,000h,000h,000h,000h,0feh,0d6h,03ah,000h,000h,000h	; 45e2  .:..........:...
	defb 000h,000h,000h,000h,000h,0ffh	; 45f2

; ======================================================================
; CODIGO 0x45f8..0x478b  (403 bytes)
; ======================================================================


PINTA_LISTA:		; Pinta una lista de rotulos: palabra de VRAM y tiles hasta 0xFF; 0xFE cambia de direccion
	ld e,(hl)			;45f8
	inc hl			;45f9
	ld d,(hl)			;45fa
	inc hl			;45fb
PINTA_LISTA_TILES:		; El bucle de tiles con DE ya puesto
	ld a,(hl)			;45fc
	inc hl			;45fd
	ld b,a			;45fe
	inc b			;45ff   ; 0xFF: fin
	ret z			;4600
	inc b			;4601   ; 0xFE: sigue otra direccion
	jr z,PINTA_LISTA		;4602
	call VPOKE		;4604
	inc de			;4607
	jr PINTA_LISTA_TILES		;4608
INTERCAMBIA:		; Cambia B bytes entre (HL) y (DE)
	ld c,(hl)			;460a   ; Un byte de cada lado por vuelta, con C de apoyo
	ld a,(de)			;460b
	ld (hl),a			;460c
	ld a,c			;460d
	ld (de),a			;460e
	inc hl			;460f
	inc de			;4610
	djnz INTERCAMBIA		;4611
	ret			;4613
PUERTO_DEL_JOYSTICK:		; Registro 15 del PSG: joystick 1 para el jugador 1, joystick 2 para el 2 (bit 7 de E002)
	ld a,00fh		;4614   ; Registro 15 del PSG: el que elige que puerto de mando se lee
	out (0a0h),a		;4616
	ld a,08fh		;4618   ; 0x8F: los dos puertos como entrada y el joystick 1 conectado
	ld hl,0e002h		;461a
	bit 7,(hl)		;461d
	jr z,L_4623		;461f
	set 6,a		;4621   ; Bit 6: pasa al joystick 2
L_4623:
	out (0a1h),a		;4623
	ret			;4625
CARGA_FUENTE:		; Colores blancos (0xF0) y patrones de la fuente (0x48CE, 48 tiles 0x30-0x5F) y los triplica a los tres tercios
	ld a,0f0h		;4626   ; Blanco sobre transparente para los tiles 0x30-0x5F
	ld de,00180h		;4628
	ld bc,00180h		;462b
	call RELLENA_VRAM		;462e
	ld hl,048ceh		;4631   ; La fuente: 48 glifos
	ld de,02180h		;4634
	ld bc,00180h		;4637
	call COPIA_A_VRAM		;463a
	call TRIPLICA_PATRONES		;463d
	jp TRIPLICA_COLORES		;4640
SUMA_PUNTOS_CON_SONIDO:		; Sonido 1 y suma DE puntos
	ld a,001h		;4643
	call SONIDO		;4645
SUMA_PUNTOS:		; Suma DE (BCD) a los puntos del jugador que juega; en la demo no; vida extra y record de paso
	ld a,(0e002h)		;4648
	add a,a			;464b   ; Bit 6 al signo (sin partida no se puntua) y bit 7 al acarreo (que jugador)
	ret p			;464c
	ld hl,0e043h		;464d   ; E043 los puntos del 1P, E046 los del 2P
	jr nc,L_4654		;4650
	ld l,046h		;4652
L_4654:
	ld a,(hl)			;4654   ; Byte bajo, con daa detras: los puntos estan en BCD
	add a,e			;4655
	daa			;4656
	ld (hl),a			;4657
	ld e,a			;4658
	inc l			;4659   ; inc l y no inc hl: los tres bytes no se salen de la pagina
	ld a,(hl)			;465a
	adc a,d			;465b
	daa			;465c
	ld (hl),a			;465d
	ld d,a			;465e
	jr nc,L_4676		;465f
	inc hl			;4661   ; El tercer byte solo si hubo acarreo
	ld a,(hl)			;4662
	adc a,000h		;4663
	daa			;4665
	ld (hl),a			;4666
	jr nc,VIDA_EXTRA		;4667
	ld bc,09999h		;4669   ; Se pasa de 999999: record a 999999
	ld (0e040h),bc		;466c   ; Dos escrituras de 16 bits solapadas dejan los tres bytes del record a 0x99
	ld (0e041h),bc		;4670
	jr PINTA_RECORD		;4674
L_4676:
	inc hl			;4676
VIDA_EXTRA:		; A los 10000 y luego cada 20000 (E052 guarda las decenas de millar del proximo)
	ld a,(0e052h)		;4677
	cp (hl)			;467a
	push de			;467b
	push hl			;467c
	jr nc,RECORD		;467d
	add a,002h		;467f   ; Proximo umbral: +20000
	daa			;4681
	jr nc,L_4686		;4682
	ld a,0ffh		;4684   ; Ya no hay mas vidas extra
L_4686:
	ld (0e052h),a		;4686
	ld hl,0e050h		;4689
	inc (hl)			;468c
	call PINTA_VIDAS		;468d
	ld a,00ch		;4690   ; Sonido de vida extra
	call SONIDO		;4692
RECORD:		; Si los puntos superan el record, se copian y se pinta
	pop hl			;4695
	ld a,(0e042h)		;4696   ; E042, el byte alto del record
	ld b,(hl)			;4699   ; (HL) es el byte alto de los puntos
	sub (hl)			;469a
	ex de,hl			;469b
	pop de			;469c
	jr c,RECORD_NUEVO		;469d   ; El record se queda corto: hay marca nueva
	jr nz,PINTA_PUNTOS		;469f   ; Distintos y sin acarreo: el record sigue por delante
	push hl			;46a1
	ld hl,(0e040h)		;46a2
	sbc hl,de		;46a5
	pop hl			;46a7
	jr nc,PINTA_PUNTOS		;46a8
RECORD_NUEVO:		; E040-E042 = los puntos
	ld (0e040h),de		;46aa
	ld a,b			;46ae
	ld (0e042h),a		;46af
	jr PINTA_RECORD		;46b2
MARCADOR:		; Pinta el marcador entero: rotulos, puntos de los dos, fase, tiempo, SCENE y el KONAMI 1984 de abajo
	ld hl,04a4eh		;46b4   ; "1P", "HI", "STAGE", "TIME" y "SCENE"
	call PINTA_LISTA		;46b7
	ld a,(0e002h)		;46ba
	bit 5,a		;46bd   ; Bit 5: dos jugadores
	jr z,L_46CF		;46bf
	ld hl,04a81h		;46c1   ; "2P"
	call PINTA_LISTA		;46c4
	ld a,(0e002h)		;46c7
	xor 080h		;46ca   ; Los puntos del otro jugador
	call PINTA_PUNTOS_DE		;46cc
L_46CF:
	call PINTA_FASE		;46cf
	call PINTA_TIEMPO		;46d2
	call PINTA_SCENE		;46d5
	ld hl,04a89h		;46d8   ; KONAMI 1984 en la fila 23, columna 2
	ld de,03ae2h		;46db
	call PINTA_LISTA_TILES		;46de
PINTA_RECORD:		; Seis cifras del record en la fila 0, columna 15
	ld hl,0e042h		;46e1
	ld de,0380fh		;46e4
	call PINTA_3_BYTES_BCD		;46e7
PINTA_PUNTOS:		; Los del jugador que juega
	ld a,(0e002h)		;46ea
PINTA_PUNTOS_DE:		; Los del jugador del bit 7 de A: 1P en la fila 0, columna 5; 2P en la fila 1
	ld de,03805h		;46ed   ; Fila 0, columna 5: los puntos del 1P
	ld hl,0e045h		;46f0   ; E043-E045; se entra por el byte alto porque PINTA_BCD recorre HL hacia atras
	add a,a			;46f3   ; El bit 7 de A al acarreo: puesto, es el jugador 2
	jr nc,PINTA_3_BYTES_BCD		;46f4
	ld e,025h		;46f6   ; Fila 1, columna 5 (0x3825), y sus puntos en E046-E048
	ld hl,0e048h		;46f8
PINTA_3_BYTES_BCD:		; Seis cifras
	ld b,003h		;46fb
	jr PINTA_BCD		;46fd
PINTA_SCENE:		; Dos cifras de E059 en la fila 23, columna 28
	ld de,03afch		;46ff
	ld hl,0e059h		;4702
	jr PINTA_1_BYTE_BCD		;4705
PINTA_FASE:		; Dos cifras de E051 en la fila 0, columna 28
	ld de,0381ch		;4707
	ld hl,0e051h		;470a
PINTA_1_BYTE_BCD:		; Dos cifras
	ld b,001h		;470d
PINTA_BCD:		; B bytes BCD desde HL hacia abajo, dos cifras por byte, en la VRAM DE
	ld a,(hl)			;470f   ; HL va hacia atras: la cifra menos significativa esta la primera
	push af			;4710
	and 00fh		;4711   ; El nibble bajo es la cifra de la derecha; 0x30 es el tile del cero
	or 030h		;4713
	ld c,a			;4715
	pop af			;4716
	and 0f0h		;4717   ; El alto, la de la izquierda, que se pinta antes
	rra			;4719
	rra			;471a
	rra			;471b
	rra			;471c
	or 030h		;471d
	call VPOKE		;471f
	inc de			;4722
	ld a,c			;4723
	call VPOKE		;4724
	dec hl			;4727
	inc de			;4728   ; DE hacia delante: dos columnas por byte
	djnz PINTA_BCD		;4729
	ret			;472b
PARPADEA_1P_2P:		; Cada 32 fotogramas borra o repinta el rotulo del jugador que juega (1P en 0x3802, 2P en 0x3822)
	ld bc,(0e002h)		;472c
	ld a,b			;4730
	and 01fh		;4731   ; Bits 0-4 del contador de fotogramas a cero: cada 32
	ret nz			;4733
	ld de,03802h		;4734
	ld hl,04a7bh		;4737
	bit 7,c		;473a   ; Bit 7 de C: el jugador 2
	jr z,L_4743		;473c
	ld hl,04a81h		;473e
	ld e,022h		;4741
L_4743:
	call VPEEK		;4743
	or a			;4746   ; Si hay algo pintado, se borra; si no, se pinta
	jp z,PINTA_LISTA		;4747
	xor a			;474a
	ld bc,00003h		;474b
	jp RELLENA_VRAM		;474e
PINTA_VIDAS:		; Los hombrecitos de las vidas: cuatro huecos de 2x2 en la fila 21 desde la columna 28 hacia la izquierda, llenos o vacios
	ld a,(0e000h)		;4751
	cp 009h		;4754   ; En el estado 9 todavia no
	ret z			;4756
	ld hl,0e11fh		;4757
	ld (0e186h),hl		;475a
	ld de,03abch		;475d
	ld a,(0e050h)		;4760
	ld c,a			;4763
	ld b,004h		;4764
L_4766:
	push de			;4766
	ld hl,04790h		;4767   ; Bloque de 2x2 lleno (0x4790)
	dec c			;476a
	jp p,VIDA_PINTA_HUECO		;476b
	ld hl,0478bh		;476e   ; Bloque vacio (0x478B)
VIDA_PINTA_HUECO:		; Un hueco de 2x2 y el color de su cara
	push bc			;4771
	ld bc,00202h		;4772   ; Un bloque de 2 por 2 tiles
	call PINTA_BLOQUE		;4775
	ld b,(hl)			;4778   ; El quinto byte de la tabla es el color de la cara
	ld hl,(0e186h)		;4779   ; E186 recorre los colores de los sprites 27-30, las caras de las vidas
	ld (hl),b			;477c
	inc hl			;477d   ; Cuatro bytes mas alla, el sprite siguiente
	inc hl			;477e
	inc hl			;477f
	inc hl			;4780
	ld (0e186h),hl		;4781
	pop bc			;4784
	pop de			;4785
	dec de			;4786   ; Dos columnas a la izquierda: el hueco siguiente
	dec de			;4787
	djnz L_4766		;4788
	ret			;478a

; ----------------------------------------------------------------------
; DATOS vida_vacia: Cinco bytes: un bloque de 2x2 tiles vacio (ceros) y el
;   byte que se guarda de el
;   0x478b..0x4790  (5 bytes)
DATA_vida_vacia:
	defb 000h,000h,000h,000h	; 478b
	defb 000h	; 478f

; ----------------------------------------------------------------------
; DATOS vida_llena: Los cuatro tiles del hombrecito de una vida (0x15 0x17
;   0x16 0x18) y el 0x06
;   0x4790..0x4795  (5 bytes)
DATA_vida_llena:
	defb 015h,017h,016h,018h	; 4790
	defb 006h	; 4794

; ======================================================================
; CODIGO 0x4795..0x47fb  (102 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LA PANTALLA DEL TITULO. Los tiles 0x40-0x61 del primer tercio se
; redefinen con el logotipo ATHLETIC LAND (RLE de 0x47FB) y sus
; colores (RLE de 0x48C2, 17 veces 16 bytes); la fuente del tercio
; de abajo se pone en cyan (0x70) para el menu.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
PANTALLA_DEL_TITULO:		; Patrones y colores del logotipo ATHLETIC LAND, fuente cyan abajo, y borra VIDEO CARTRIDGE
	ld hl,047fbh		;4795   ; RLE con la direccion delante: patrones a 0x2200 (tiles 0x40-0x61)
	call RLE_A_VRAM		;4798
	ld de,04200h		;479b
	ld b,011h		;479e   ; 17 filas de 16 colores desde 0x0200: los tiles 0x40-0x61
L_47A0:
	push bc			;47a0   ; Diecisiete vueltas, una por fila de 16 colores
	push de			;47a1
	ld hl,048c2h		;47a2   ; Siempre el mismo bloque RLE: los 34 tiles del logotipo llevan colores identicos de dos en dos
	call RLE_A_VRAM_DE		;47a5   ; Descomprime 16 bytes: 0x08 0xE0 son ocho 0xE0, y 0x88 copia e0 e0 30 30 30 20 20 c0 tal cual
	pop hl			;47a8
	ld bc,00010h		;47a9   ; DE avanza 16 bytes, los colores de dos tiles
	add hl,bc			;47ac
	ex de,hl			;47ad
	pop bc			;47ae
	djnz L_47A0		;47af
	ld a,070h		;47b1   ; Cyan sobre transparente para la fuente del tercio de abajo (el menu)
	ld de,01180h		;47b3   ; VRAM 0x1180: la tabla de colores empieza en 0x0000, y ahi cae el tile 0x30 del tercio de abajo
	ld bc,00180h		;47b6   ; 0x180 bytes son 48 tiles, del 0x30 al 0x5F: las cifras y las letras que usa el menu
	call RELLENA_VRAM		;47b9
	ld de,03966h		;47bc   ; Borra "@ VIDEO CARTRIDGE @"
	ld bc,00013h		;47bf
	xor a			;47c2
	call RELLENA_VRAM		;47c3
	xor a			;47c6
	ld (0e00ah),a		;47c7   ; E00A a cero: TITULO_COLUMNA empezara por la columna 0
	ret			;47ca
TITULO_COLUMNA:		; Una columna del logotipo por llamada (17 columnas de 2 tiles, filas 5 y 6); luego el KONAMI 1984 hasta 52 llamadas. Acarreo mientras queda
	ld hl,0e00ah		;47cb   ; E00A cuenta las llamadas y sube en cada una
	ld a,(hl)			;47ce
	inc (hl)			;47cf
	cp 011h		;47d0   ; De la 17 en adelante ya no queda columna: solo el KONAMI 1984 (0x47F0)
	jr nc,L_47F0		;47d2
	ld de,03888h		;47d4   ; Fila 4, columna 8: la fila 4 se borra y las 5 y 6 llevan los tiles 0x40+2n y 0x41+2n
	ld c,a			;47d7
	add a,e			;47d8   ; La columna n de la fila 4 es 0x3888 mas n
	ld e,a			;47d9
	ld a,c			;47da
	add a,a			;47db   ; Dos tiles por columna: 0x40+2n arriba y 0x41+2n justo debajo
	add a,040h		;47dc
	ld c,a			;47de
	ld b,003h		;47df
	xor a			;47e1   ; El primer tile que se escribe es un 0: la fila 4 se va limpiando por delante
L_47E2:
	call VPOKE		;47e2   ; Tres tiles en la misma columna: el 0 de la fila 4 y los dos del logotipo, filas 5 y 6
	ld a,020h		;47e5   ; Bajar una fila en la tabla de nombres es sumar 32
	call DE_MAS_A		;47e7
	ld a,c			;47ea   ; A para la vuelta siguiente, y C ya apunta al tile de abajo
	inc c			;47eb
	djnz L_47E2		;47ec
	scf			;47ee   ; Acarreo: aun quedan columnas por sacar
	ret			;47ef
L_47F0:
	push af			;47f0
	ld hl,04a87h		;47f1   ; KONAMI 1984 en la fila 8, columna 11
	call PINTA_LISTA		;47f4
	pop af			;47f7
	cp 034h		;47f8   ; 52 llamadas en total
	ret			;47fa

; ----------------------------------------------------------------------
; DATOS logo_titulo_rle: El logotipo ATHLETIC LAND comprimido (RLE de 0x4BB3,
;   direccion 0x2200 delante): los patrones de los tiles 0x40-0x61 del primer
;   tercio
;   0x47fb..0x48c2  (199 bytes)
DATA_logo_titulo_rle:
	defb 000h,062h,003h,007h,003h,00fh,083h,01fh,01eh,01fh,003h,03fh,084h,07ch,07ch,078h	; 47fb  .b.........?.||x
	defb 0f8h,003h,0f0h,086h,0f8h,0f8h,078h,07ch,03ch,0fch,003h,0feh,086h,01fh,01fh,00fh	; 480b  ......x|<.......
	defb 00fh,000h,00ch,003h,03ch,003h,07fh,004h,03ch,084h,03fh,03fh,01fh,08eh,004h,078h	; 481b  ....<...<.??...x
	defb 081h,07bh,003h,07fh,081h,07dh,007h,078h,004h,007h,082h,0c7h,0e7h,00ah,0f7h,004h	; 482b  .{...}.x........
	defb 080h,0a1h,087h,08fh,09eh,09ch,0bfh,0bfh,0bch,0beh,09fh,09fh,08fh,083h,000h,000h	; 483b  ................
	defb 001h,001h,0e1h,0f3h,073h,03bh,0f9h,0f9h,001h,009h,0f9h,0f9h,0f0h,0c0h,001h,063h	; 484b  ....s;.........c
	defb 0e3h,0e1h,0e0h,003h,0fbh,004h,0e3h,003h,0fbh,091h,073h,080h,0c0h,0c0h,080h,003h	; 485b  ..........s.....
	defb 0c7h,0cfh,0cfh,0dfh,0deh,0deh,0dfh,0cfh,0cfh,0c7h,0c1h,004h,000h,081h,0e0h,003h	; 486b  ................
	defb 0f0h,004h,000h,003h,0f0h,081h,0e0h,010h,01fh,00bh,080h,081h,081h,003h,0fdh,081h	; 487b  ................
	defb 0fch,004h,000h,08ch,07eh,0ffh,0ffh,087h,007h,07fh,0ffh,0e7h,0e7h,0ffh,0ffh,0f7h	; 488b  ....~...........
	defb 005h,000h,081h,01eh,003h,09fh,006h,09eh,081h,0deh,005h,000h,084h,0f0h,0f8h,0fch	; 489b  ................
	defb 07dh,003h,03dh,004h,03ch,004h,001h,08ch,01dh,07fh,0ffh,0ffh,0f9h,0f1h,0f1h,0f9h	; 48ab  }.=.<...........
	defb 0ffh,0ffh,07fh,01dh,010h,0e0h,000h	; 48bb

; ----------------------------------------------------------------------
; DATOS logo_titulo_colores_rle: Los 16 colores de una fila de tiles del
;   logotipo, comprimidos; 0x4795 los repite 17 veces
;   0x48c2..0x48ce  (12 bytes)
DATA_logo_titulo_colores_rle:
	defb 008h,0e0h,088h,0e0h,0e0h,030h,030h,030h,020h,020h,0c0h,000h	; 48c2  .....000  ..

; ----------------------------------------------------------------------
; DATOS fuente: Los 48 glifos de 8 bytes de la fuente: '0'-'9', el KONAMI
;   pequeno (0x3A-0x3F), la raya (0x40), 'A'-'Z', ':' y los dos iconos de 2x1
;   del menu (0x5C-0x5F). El codigo de tile es el ASCII
;   0x48ce..0x4a4e  (384 bytes)
DATA_fuente:
	defb 000h,01ch,022h,063h,063h,063h,022h,01ch	; 48ce  .."ccc".
	defb 000h,018h,038h,018h,018h,018h,018h,07eh	; 48d6  ..8....~
	defb 000h,03eh,063h,003h,00eh,03ch,070h,07fh	; 48de  .>c..<p.
	defb 000h,03eh,063h,003h,00eh,003h,063h,03eh	; 48e6  .>c...c>
	defb 000h,00eh,01eh,036h,066h,066h,07fh,006h	; 48ee  ...6ff..
	defb 000h,07fh,060h,07eh,063h,003h,063h,03eh	; 48f6  ..`~c.c>
	defb 000h,03eh,063h,060h,07eh,063h,063h,03eh	; 48fe  .>c`~cc>
	defb 000h,07fh,063h,006h,00ch,018h,018h,018h	; 4906  ..c.....
	defb 000h,03eh,063h,063h,03eh,063h,063h,03eh	; 490e  .>cc>cc>
	defb 000h,03eh,063h,063h,03fh,003h,063h,03eh	; 4916  .>cc?.c>
	defb 03ch,042h,099h,0a1h,0a1h,099h,042h,03ch	; 491e  <B....B<
	defb 000h,003h,003h,003h,003h,003h,003h,003h	; 4926  ........
	defb 01ch,038h,070h,0e1h,0cdh,0cdh,0fdh,079h	; 492e  .8p....y
	defb 000h,000h,000h,0eeh,06bh,06bh,06bh,0ebh	; 4936  ....kkk.
	defb 000h,000h,000h,073h,01ah,07ah,05ah,07ah	; 493e  ...s.zZz
	defb 000h,003h,000h,0f3h,05bh,05bh,05bh,05bh	; 4946  ....[[[[
	defb 000h,000h,000h,000h,07eh,000h,000h,000h	; 494e  ....~...
	defb 000h,01ch,036h,063h,063h,07fh,063h,063h	; 4956  ..6cc.cc
	defb 000h,07eh,063h,063h,07eh,063h,063h,07eh	; 495e  .~cc~cc~
	defb 000h,03eh,063h,060h,060h,060h,063h,03eh	; 4966  .>c```c>
	defb 000h,07ch,066h,063h,063h,063h,066h,07ch	; 496e  .|fcccf|
	defb 000h,07fh,060h,060h,07eh,060h,060h,07fh	; 4976  ..``~``.
	defb 000h,07fh,060h,060h,07eh,060h,060h,060h	; 497e  ..``~```
	defb 000h,03eh,063h,060h,067h,063h,063h,03fh	; 4986  .>c`gcc?
	defb 000h,063h,063h,063h,07fh,063h,063h,063h	; 498e  .ccc.ccc
	defb 000h,03ch,018h,018h,018h,018h,018h,03ch	; 4996  .<.....<
	defb 000h,01fh,006h,006h,006h,006h,066h,03ch	; 499e  ......f<
	defb 000h,063h,066h,06ch,078h,07ch,06eh,067h	; 49a6  .cflx|ng
	defb 000h,060h,060h,060h,060h,060h,060h,07fh	; 49ae  .``````.
	defb 000h,063h,077h,07fh,07fh,06bh,063h,063h	; 49b6  .cw..kcc
	defb 000h,063h,073h,07bh,07fh,06fh,067h,063h	; 49be  .cs{.ogc
	defb 000h,03eh,063h,063h,063h,063h,063h,03eh	; 49c6  .>ccccc>
	defb 000h,07eh,063h,063h,063h,07eh,060h,060h	; 49ce  .~ccc~``
	defb 000h,03eh,063h,063h,063h,06fh,066h,03dh	; 49d6  .>cccof=
	defb 000h,07eh,063h,063h,062h,07ch,066h,063h	; 49de  .~ccb|fc
	defb 000h,03eh,063h,060h,03eh,003h,063h,03eh	; 49e6  .>c`>.c>
	defb 000h,07eh,018h,018h,018h,018h,018h,018h	; 49ee  .~......
	defb 000h,063h,063h,063h,063h,063h,063h,03eh	; 49f6  .cccccc>
	defb 000h,063h,063h,063h,063h,036h,01ch,008h	; 49fe  .cccc6..
	defb 000h,063h,063h,06bh,06bh,07fh,077h,022h	; 4a06  .cckk.w"
	defb 000h,063h,076h,03ch,01ch,01eh,037h,063h	; 4a0e  .cv<..7c
	defb 000h,066h,066h,07eh,03ch,018h,018h,018h	; 4a16  .ff~<...
	defb 000h,07fh,007h,00eh,01ch,038h,070h,07fh	; 4a1e  .....8p.
	defb 000h,024h,024h,024h,000h,000h,000h,000h	; 4a26  .$$$....
	defb 000h,000h,040h,049h,05ah,073h,052h,059h	; 4a2e  ..@IZsRY
	defb 000h,000h,000h,092h,052h,0ceh,002h,0dch	; 4a36  ....R...
	defb 000h,000h,002h,000h,08ah,0aah,0aah,0dah	; 4a3e  ........
	defb 000h,000h,008h,048h,0eeh,04ah,04ah,06ah	; 4a46  ...H.JJj

; ----------------------------------------------------------------------
; DATOS rotulos_del_marcador: Lista de rotulos, cada uno con su raya (0x40)
;   detras: "HI-" en 0x380C (fila 0, columna 12), "STAGE-" en 0x3816 (columna
;   22), "TIME" y 14 blancos en 0x382C (fila 1, columna 12), "SCENE-" en
;   0x3AF6 (fila 23, columna 22); y sigue con el "1P-" de 0x4A7B
;   0x4a4e..0x4a7b  (45 bytes)
DATA_rotulos_del_marcador:
	defb 00ch,038h,048h,049h,040h,0feh,016h,038h,053h,054h,041h,047h,045h,040h,0feh,02ch	; 4a4e  .8HI@..8STAGE@.,
	defb 038h,054h,049h,04dh,045h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 4a5e  8TIME...........
	defb 000h,000h,000h,0feh,0f6h,03ah,053h,043h,045h,04eh,045h,040h,0feh	; 4a6e  .....:SCENE@.

; ----------------------------------------------------------------------
; DATOS rotulo_1p: "1P-" en 0x3802 (fila 0, columna 2)
;   0x4a7b..0x4a81  (6 bytes)
DATA_rotulo_1p:
	defb 002h,038h,031h,050h,040h,0ffh	; 4a7b

; ----------------------------------------------------------------------
; DATOS rotulo_2p: "2P-" en 0x3822 (fila 1, columna 2)
;   0x4a81..0x4a87  (6 bytes)
DATA_rotulo_2p:
	defb 022h,038h,032h,050h,040h,0ffh	; 4a81

; ----------------------------------------------------------------------
; DATOS direccion_konami_1984: La palabra 0x390B (fila 8, columna 11) delante
;   de la lista de KONAMI 1984
;   0x4a87..0x4a89  (2 bytes)
DATA_direccion_konami_1984:
	defw 0390bh	; 4a87

; ----------------------------------------------------------------------
; DATOS konami_1984: Los seis tiles del KONAMI pequeno y " 1984"
;   0x4a89..0x4a95  (12 bytes)
DATA_konami_1984:
	defb 03ah,03bh,03ch,03dh,03eh,03fh	; 4a89
	defb 000h,031h,039h,038h,034h,0ffh	; 4a8f

; ----------------------------------------------------------------------
; DATOS menu: "PLAY SELECT" en la fila 13 y las cuatro opciones en las filas
;   16, 18, 20 y 22: 1 PLAYER JOYSTICK, 2 PLAYERS JOYSTICK, 1 PLAYER KEYBOARD,
;   2 PLAYERS KEYBOARD, con los iconos 0x5C-0x5F
;   0x4a95..0x4b13  (126 bytes)
DATA_menu:
	defb 0abh,039h,050h,04ch,041h,059h,000h,053h,045h,04ch,045h,043h,054h,0feh,004h,03ah	; 4a95  .9PLAY.SELECT..:
	defb 031h,040h,05ch,05dh,000h,031h,050h,04ch,041h,059h,045h,052h,000h,000h,05eh,05fh	; 4aa5  1@\].1PLAYER..^_
	defb 000h,04ah,04fh,059h,053h,054h,049h,043h,04bh,0feh,044h,03ah,032h,040h,05ch,05dh	; 4ab5  .JOYSTICK.D:2@\]
	defb 000h,032h,050h,04ch,041h,059h,045h,052h,053h,000h,05eh,05fh,000h,04ah,04fh,059h	; 4ac5  .2PLAYERS.^_.JOY
	defb 053h,054h,049h,043h,04bh,0feh,084h,03ah,033h,040h,05ch,05dh,000h,031h,050h,04ch	; 4ad5  STICK..:3@\].1PL
	defb 041h,059h,045h,052h,000h,000h,05eh,05fh,000h,04bh,045h,059h,042h,04fh,041h,052h	; 4ae5  AYER..^_.KEYBOAR
	defb 044h,0feh,0c4h,03ah,034h,040h,05ch,05dh,000h,032h,050h,04ch,041h,059h,045h,052h	; 4af5  D..:4@\].2PLAYER
	defb 053h,000h,05eh,05fh,000h,04bh,045h,059h,042h,04fh,041h,052h,044h,0ffh	; 4b05  S.^_.KEYBOARD.

; ----------------------------------------------------------------------
; DATOS game_over: "GAME  OVER" en la fila 11, columna 11; sigue en la lista
;   de PLAYER
;   0x4b13..0x4b20  (13 bytes)
DATA_game_over:
	defb 06bh,039h,047h,041h,04dh,045h,000h,000h,04fh,056h,045h,052h,0feh	; 4b13  k9GAME..OVER.

; ----------------------------------------------------------------------
; DATOS rotulo_player: "PLAYER" en la fila 9, columna 12 (el numero lo pone
;   0x441F)
;   0x4b20..0x4b29  (9 bytes)
DATA_rotulo_player:
	defb 02ch,039h,050h,04ch,041h,059h,045h,052h,0ffh	; 4b20  ,9PLAYER.

; ----------------------------------------------------------------------
; DATOS video_cartridge: "@ VIDEO CARTRIDGE @" en la fila 11, columna 6
;   0x4b29..0x4b3f  (22 bytes)
DATA_video_cartridge:
	defb 066h,039h,040h,000h,056h,049h,044h,045h,04fh,000h,043h,041h,052h,054h,052h,049h	; 4b29  f9@.VIDEO.CARTRI
	defb 044h,047h,045h,000h,040h,0ffh	; 4b39

; ----------------------------------------------------------------------
; DATOS bonus_score: "BONUS SCORE 2000" en la fila 12, columna 8
;   0x4b3f..0x4b52  (19 bytes)
DATA_bonus_score:
	defb 088h,039h,042h,04fh,04eh,055h,053h,000h,053h,043h,04fh,052h,045h,000h,032h,030h	; 4b3f  .9BONUS.SCORE.20
	defb 030h,030h,0ffh	; 4b4f

; ======================================================================
; CODIGO 0x4b52..0x4bd8  (134 bytes)
; ======================================================================


CARGA_LOGO_KONAMI:		; Descomprime los 26 tiles del KONAMI grande (0x60-0x79) en 0x2300, colores blancos, la fuente, y prepara la subida (17 pasos, cursor E050 a 0)
	ld hl,04bd8h		;4b52
	ld de,06300h		;4b55   ; 0x6300 = escritura en 0x2300: patrones de los tiles 0x60-0x79
	call RLE_A_VRAM_DE		;4b58
	ld de,00300h		;4b5b   ; Blanco para 26 tiles
	ld bc,000d0h		;4b5e
	ld a,0f0h		;4b61
	call RELLENA_VRAM		;4b63
	call CARGA_FUENTE		;4b66
	ld a,011h		;4b69   ; 17 filas por subir
	ld (0e00ah),a		;4b6b
	ld hl,00000h		;4b6e
	ld (0e050h),hl		;4b71
	ret			;4b74
SUBE_LOGO_KONAMI:		; Una fila mas arriba: pinta las tres filas del KONAMI (3, 11 y 12 tiles desde la columna 10) y borra la de debajo. Z al llegar a la fila 4
	ld hl,(0e050h)		;4b75   ; En el titulo E050 no son las vidas: es el cursor de 16 bits de lo que lleva subido el logotipo
	ld de,00020h		;4b78   ; Una fila entera de la tabla de nombres son 32 bytes
	add hl,de			;4b7b
	ld (0e050h),hl		;4b7c
	ex de,hl			;4b7f
	or a			;4b80
	ld hl,03aaah		;4b81   ; Desde la fila 21 hacia arriba
	sbc hl,de		;4b84   ; 0x3AAA menos lo subido; la primera vez sale 0x3A8A, fila 20 y columna 10
	ex de,hl			;4b86
	ld a,060h		;4b87   ; Los 26 tiles del logotipo van seguidos desde el 0x60
	ld b,003h		;4b89   ; Tres tiles arriba, once en medio y doce abajo: asi esta partido el KONAMI grande
	call PINTA_TILES_SEGUIDOS		;4b8b
	ld b,00bh		;4b8e
	call PINTA_TILES_SEGUIDOS		;4b90
	ld b,00ch		;4b93
	call PINTA_TILES_SEGUIDOS		;4b95
	ld bc,0000ch		;4b98   ; Doce ceros en la fila de debajo: borran el rastro que deja al subir
	xor a			;4b9b
	call RELLENA_VRAM		;4b9c
	ld hl,0e00ah		;4b9f
	dec (hl)			;4ba2   ; E00A cuenta las 17 filas; al llegar a cero es el z que espera 0x4188
	ret			;4ba3
PINTA_TILES_SEGUIDOS:		; B tiles consecutivos desde A en la VRAM DE y baja una fila
	push de			;4ba4
L_4BA5:
	call VPOKE		;4ba5   ; Un tile por posicion, y el codigo del tile sube con la columna
	inc de			;4ba8
	inc a			;4ba9
	djnz L_4BA5		;4baa
	pop de			;4bac   ; Se recupera el principio de la fila...
	ld hl,00020h		;4bad   ; ...y se le suman 32: DE se va a la fila de debajo para la llamada siguiente
	add hl,de			;4bb0
	ex de,hl			;4bb1
	ret			;4bb2
RLE_A_VRAM:		; Descomprime en la VRAM cuya direccion va delante de los datos
	ld e,(hl)			;4bb3
	inc hl			;4bb4
	ld d,(hl)			;4bb5
	inc hl			;4bb6
RLE_A_VRAM_DE:		; Descomprime HL en la VRAM DE: 0 fin; n<0x80 repite n veces el byte siguiente; n>=0x80 copia n&0x7F bytes tal cual
	di			;4bb7
	call VDP_DIRECCION		;4bb8
L_4BBB:
	ld a,(hl)			;4bbb
	inc hl			;4bbc
	or a			;4bbd   ; Cero: fin
	ret z			;4bbe
	bit 7,a		;4bbf   ; Bit 7: bytes tal cual
	jr nz,RLE_TAL_CUAL		;4bc1
	ld b,a			;4bc3
	ld a,(hl)			;4bc4
	inc hl			;4bc5
L_4BC6:
	out (098h),a		;4bc6
	nop			;4bc8
	nop			;4bc9
	djnz L_4BC6		;4bca
	jr L_4BBB		;4bcc
RLE_TAL_CUAL:		; Copia A&0x7F bytes
	res 7,a		;4bce
	ld c,a			;4bd0
	ld b,000h		;4bd1
	call COPIA_A_VRAM_BUCLE		;4bd3
	jr L_4BBB		;4bd6

; ----------------------------------------------------------------------
; DATOS logo_konami_rle: El KONAMI grande de 26 tiles (0x60-0x79) comprimido:
;   3 tiles de la fila de arriba, 11 de la de en medio y 12 de la de abajo
;   (con la R de marca registrada)
;   0x4bd8..0x4c6b  (147 bytes)
DATA_logo_konami_rle:
	defb 00eh,000h,082h,007h,00fh,006h,000h,082h,0f8h,0f0h,004h,03eh,004h,03fh,090h,01fh	; 4bd8  ...........>.?..
	defb 03fh,07fh,0ffh,0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h,000h,000h,000h,03eh,03eh,005h	; 4be8  ?............>>.
	defb 000h,083h,01fh,07fh,0fbh,005h,000h,083h,00fh,0cfh,0efh,005h,000h,083h,078h,0fch	; 4bf8  ..............x.
	defb 0bch,005h,000h,083h,03fh,07fh,0f3h,005h,000h,083h,087h,0c7h,0c7h,005h,000h,083h	; 4c08  ....?...........
	defb 0bch,0feh,0dfh,005h,000h,08dh,078h,0fch,0bch,060h,0f0h,0f0h,060h,000h,0f0h,0f0h	; 4c18  ......x..`..`...
	defb 0f0h,03fh,03fh,006h,03eh,090h,0f8h,0fch,0feh,07fh,03fh,01fh,00fh,007h,03eh,03eh	; 4c28  .??.>.....?...>>
	defb 03eh,07eh,0fch,0fch,0f8h,0e0h,005h,0f1h,083h,0fbh,07fh,01fh,006h,0efh,082h,0cfh	; 4c38  >~..............
	defb 00fh,008h,01eh,088h,0e1h,003h,03fh,0f1h,0e1h,0f3h,07fh,01eh,008h,0e7h,008h,08fh	; 4c48  ......?.........
	defb 008h,01eh,082h,0f1h,0f2h,004h,0f5h,08ah,0f2h,0f1h,0e0h,010h,0c8h,068h,0c8h,028h	; 4c58  .............h.(
	defb 010h,0e0h,000h	; 4c68

; ----------------------------------------------------------------------
; DATOS tiles_B0: Siete tiles 0xB0-0xB6 (los cabos y remates de las lianas)
;   que 0x5937 copia al primer tercio y espeja para 0xB7-0xBC
;   0x4c6b..0x4c93  (40 bytes)
DATA_tiles_B0:
	defb 000h,000h,001h,002h,002h,004h,004h,008h	; 4c6b  ........
	defb 080h,080h,000h,000h,000h,000h,000h,000h	; 4c73  ........
	defb 000h,000h,000h,000h,000h,001h,001h,001h	; 4c7b  ........
	defb 040h,040h,080h,080h,080h,000h,000h,000h	; 4c83  @@......
	defb 010h,020h,020h,020h,020h,020h,040h,040h	; 4c8b  .     @@

; ----------------------------------------------------------------------
; DATOS tiles_lianas: 30 tiles 0x60-0x7D del tercio de en medio: los tramos de
;   la liana en sus nueve fases; espejados van a 0x7E-0x9B
;   0x4c93..0x4d83  (240 bytes)
DATA_tiles_lianas:
	defb 001h,002h,002h,004h,004h,008h,010h,010h	; 4c93  ........
	defb 008h,008h,008h,008h,008h,008h,008h,008h	; 4c9b  ........
	defb 000h,000h,000h,000h,001h,002h,004h,008h	; 4ca3  ........
	defb 020h,040h,040h,080h,000h,000h,000h,000h	; 4cab   @@.....
	defb 000h,000h,000h,000h,000h,000h,001h,002h	; 4cb3  ........
	defb 008h,010h,020h,040h,080h,080h,000h,000h	; 4cbb  .. @....
	defb 004h,008h,010h,020h,040h,080h,000h,000h	; 4cc3  ... @...
	defb 000h,000h,000h,000h,000h,003h,004h,038h	; 4ccb  .......8
	defb 00ch,010h,020h,040h,080h,000h,000h,000h	; 4cd3  .. @....
	defb 000h,000h,000h,000h,000h,000h,000h,001h	; 4cdb  ........
	defb 008h,010h,010h,020h,040h,040h,080h,000h	; 4ce3  ... @@..
	defb 001h,002h,004h,004h,008h,010h,020h,020h	; 4ceb  ......  
	defb 000h,000h,001h,002h,002h,004h,008h,010h	; 4cf3  ........
	defb 040h,080h,000h,000h,000h,000h,000h,000h	; 4cfb  @.......
	defb 020h,020h,040h,080h,000h,000h,000h,000h	; 4d03    @.....
	defb 010h,020h,040h,080h,000h,000h,000h,000h	; 4d0b  . @.....
	defb 002h,002h,004h,004h,008h,008h,008h,010h	; 4d13  ........
	defb 010h,020h,020h,040h,040h,080h,080h,000h	; 4d1b  .  @@...
	defb 000h,000h,000h,000h,000h,001h,001h,002h	; 4d23  ........
	defb 020h,040h,040h,080h,080h,000h,000h,000h	; 4d2b   @@.....
	defb 002h,004h,008h,008h,010h,020h,020h,040h	; 4d33  .....  @
	defb 080h,000h,000h,000h,000h,000h,000h,000h	; 4d3b  ........
	defb 000h,000h,000h,000h,000h,000h,001h,001h	; 4d43  ........
	defb 040h,040h,080h,080h,080h,080h,000h,000h	; 4d4b  @@......
	defb 001h,001h,002h,002h,002h,002h,004h,004h	; 4d53  ........
	defb 004h,004h,008h,008h,008h,008h,010h,010h	; 4d5b  ........
	defb 010h,020h,020h,020h,040h,040h,040h,040h	; 4d63  .   @@@@
	defb 000h,000h,000h,000h,001h,001h,001h,002h	; 4d6b  ........
	defb 080h,080h,080h,080h,000h,000h,000h,000h	; 4d73  ........
	defb 002h,002h,004h,004h,004h,008h,000h,000h	; 4d7b  ........

; ----------------------------------------------------------------------
; DATOS tiles_AF: 38 tiles 0xAF-0xD4 del tercio de en medio: las tablas y el
;   agua de los surtidores, el trampolin y el charco
;   0x4d83..0x4eab  (296 bytes)
DATA_tiles_AF:
	defb 018h,018h,018h,018h,018h,018h,018h,018h	; 4d83  ........
	defb 018h,018h,018h,018h,018h,018h,018h,018h	; 4d8b  ........
	defb 018h,018h,018h,018h,018h,018h,018h,018h	; 4d93  ........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 4d9b  ........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00fh	; 4da3  ........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,024h	; 4dab  .......$
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0f0h	; 4db3  ........
	defb 000h,000h,000h,000h,000h,000h,000h,0ffh	; 4dbb  ........
	defb 0ffh,0ffh,000h,000h,0afh,03fh,07fh,0ffh	; 4dc3  .....?..
	defb 0ffh,0ffh,000h,000h,081h,0e7h,0ffh,0ffh	; 4dcb  ........
	defb 0ffh,0ffh,000h,000h,0f5h,0fch,0feh,0ffh	; 4dd3  ........
	defb 0ffh,0ffh,000h,00fh,0bfh,07fh,05fh,034h	; 4ddb  ......_4
	defb 0ffh,0ffh,000h,024h,099h,0ffh,0ffh,0bdh	; 4de3  ...$....
	defb 0ffh,0ffh,000h,0f0h,0fdh,0feh,0fah,02ch	; 4deb  .......,
	defb 018h,018h,018h,018h,018h,018h,018h,018h	; 4df3  ........
	defb 081h,0e7h,0ffh,0ffh,0bdh,03ch,018h,05ah	; 4dfb  .....<.Z
	defb 0afh,03fh,07fh,0ffh,0b4h,0a0h,064h,0a0h	; 4e03  .?....d.
	defb 0f5h,0fch,0feh,0ffh,02dh,005h,026h,005h	; 4e0b  ....-.&.
	defb 000h,000h,001h,000h,020h,000h,002h,000h	; 4e13  .... ...
	defb 000h,000h,080h,000h,004h,000h,080h,000h	; 4e1b  ........
	defb 0bfh,07fh,05fh,034h,094h,020h,000h,040h	; 4e23  .._4. .@
	defb 099h,0ffh,0ffh,0bdh,018h,018h,099h,018h	; 4e2b  ........
	defb 0fdh,0feh,0fah,02ch,029h,004h,000h,002h	; 4e33  ...,)...
	defb 008h,080h,000h,000h,000h,000h,000h,000h	; 4e3b  ........
	defb 010h,001h,000h,000h,000h,000h,000h,000h	; 4e43  ........
	defb 0b4h,0a0h,064h,0a0h,000h,000h,001h,000h	; 4e4b  ..d.....
	defb 0bdh,03ch,018h,05ah,018h,018h,018h,018h	; 4e53  .<.Z....
	defb 02dh,005h,026h,005h,000h,000h,080h,000h	; 4e5b  -.&.....
	defb 020h,000h,001h,000h,000h,000h,000h,000h	; 4e63   .......
	defb 004h,000h,080h,000h,000h,000h,000h,000h	; 4e6b  ........
	defb 094h,020h,000h,040h,008h,080h,000h,000h	; 4e73  . .@....
	defb 018h,018h,099h,018h,018h,018h,018h,018h	; 4e7b  ........
	defb 029h,004h,000h,002h,010h,001h,000h,000h	; 4e83  ).......
	defb 0b4h,0a0h,064h,0a0h,05bh,05fh,07eh,0ffh	; 4e8b  ..d.[_~.
	defb 02dh,005h,026h,005h,05bh,05fh,07eh,0ffh	; 4e93  -.&.[_~.
	defb 094h,020h,000h,040h,05bh,05fh,07eh,0ffh	; 4e9b  . .@[_~.
	defb 029h,004h,000h,002h,05bh,05fh,07eh,0ffh	; 4ea3  )...[_~.

; ----------------------------------------------------------------------
; DATOS tiles_9C: 16 tiles 0x9C-0xAB (hierba y matojos); espejados van a
;   0xD5-0xE4
;   0x4eab..0x4f2b  (128 bytes)
DATA_tiles_9C:
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 4eab  ........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 4eb3  ........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 4ebb  ........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0f7h	; 4ec3  ........
	defb 0ffh,0ffh,0ffh,0ffh,0f7h,0f7h,0f7h,0ffh	; 4ecb  ........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0efh	; 4ed3  ........
	defb 0ffh,0ffh,07fh,07fh,0f7h,0f7h,0f7h,0ffh	; 4edb  ........
	defb 0bfh,0bfh,0efh,0efh,0ffh,0ffh,0ffh,0ffh	; 4ee3  ........
	defb 0bfh,0bfh,0fdh,0fdh,0f7h,0f7h,0f7h,0bfh	; 4eeb  ........
	defb 07fh,07fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 4ef3  ........
	defb 0ffh,0ffh,0bfh,0bfh,0bfh,0bfh,0bfh,0bfh	; 4efb  ........
	defb 0f7h,0f7h,0f7h,0ffh,0ffh,0ffh,0ffh,0ffh	; 4f03  ........
	defb 0efh,0efh,0efh,0ffh,0ffh,0ffh,0ffh,0ffh	; 4f0b  ........
	defb 0ffh,0ffh,0fdh,0fdh,0fdh,0fdh,0fdh,0fdh	; 4f13  ........
	defb 0bfh,0bfh,0bfh,0ffh,0ffh,0ffh,0ffh,0ffh	; 4f1b  ........
	defb 07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh	; 4f23  ........

; ----------------------------------------------------------------------
; DATOS colores_AF: Los colores de los tiles 0xAF-0xBC del tercio de en medio
;   0x4f2b..0x4f9b  (112 bytes)
DATA_colores_AF:
	defb 0fah,0fah,0fah,0fah,0fah,0fah,0fah,0f1h	; 4f2b  ........
	defb 0fah,0fah,0fah,0fah,0fah,0f1h,0f1h,0f4h	; 4f33  ........
	defb 0f1h,0f1h,0f1h,0f1h,0f1h,0f1h,0f3h,0f3h	; 4f3b  ........
	defb 011h,011h,011h,0aah,0aah,066h,011h,011h	; 4f43  .....f..
	defb 011h,011h,011h,0aah,0aah,066h,011h,01fh	; 4f4b  .....f..
	defb 011h,011h,011h,0aah,0aah,066h,011h,01fh	; 4f53  .....f..
	defb 011h,011h,011h,0aah,0aah,066h,011h,01fh	; 4f5b  .....f..
	defb 011h,011h,011h,011h,011h,011h,011h,0aah	; 4f63  ........
	defb 0aah,066h,011h,011h,0f1h,0f1h,0f1h,0f1h	; 4f6b  .f......
	defb 0aah,066h,011h,011h,0f1h,0f1h,0f1h,0f1h	; 4f73  .f......
	defb 0aah,066h,011h,011h,0f1h,0f1h,0f1h,0f1h	; 4f7b  .f......
	defb 0aah,066h,011h,011h,0f1h,0f1h,0f1h,0f1h	; 4f83  .f......
	defb 0aah,066h,011h,011h,0f1h,0f1h,0f1h,0f1h	; 4f8b  .f......
	defb 0aah,066h,011h,011h,0f1h,0f1h,0f1h,0f1h	; 4f93  .f......

; ----------------------------------------------------------------------
; DATOS colores_D1: Los colores del trampolin (0xD1-0xD4)
;   0x4f9b..0x4fbb  (32 bytes)
DATA_colores_D1:
	defb 0f1h,0f1h,0f1h,0f1h,031h,031h,031h,031h	; 4f9b  ....1111
	defb 0f1h,0f1h,0f1h,0f1h,031h,031h,031h,031h	; 4fa3  ....1111
	defb 0f1h,0f1h,0f1h,0f1h,031h,031h,031h,031h	; 4fab  ....1111
	defb 0f1h,0f1h,0f1h,0f1h,031h,031h,031h,031h	; 4fb3  ....1111

; ----------------------------------------------------------------------
; DATOS colores_9C: Los colores de 0x9C-0xAB, repetidos para 0xD5-0xE4
;   0x4fbb..0x503b  (128 bytes)
DATA_colores_9C:
	defb 033h,0cch,033h,0cch,033h,0cch,0cch,033h	; 4fbb  3.3.3..3
	defb 0cch,0cch,0cch,033h,0cch,0cch,0cch,0cch	; 4fc3  ...3....
	defb 033h,0cch,0cch,0cch,0cch,0cch,0cch,0cch	; 4fcb  3.......
	defb 033h,0cch,033h,0cch,033h,0cch,0cch,031h	; 4fd3  3.3.3..1
	defb 033h,0cch,033h,0cch,031h,0c1h,0c1h,033h	; 4fdb  3.3.1..3
	defb 033h,0cch,033h,0cch,033h,0cch,0cch,031h	; 4fe3  3.3.3..1
	defb 033h,0cch,031h,0c1h,031h,0c1h,0c1h,033h	; 4feb  3.1.1..3
	defb 031h,0c1h,031h,0c1h,033h,0cch,0cch,033h	; 4ff3  1.1.3..3
	defb 031h,0c1h,031h,0c1h,031h,0c1h,0c1h,031h	; 4ffb  1.1.1..1
	defb 031h,0c1h,033h,0cch,033h,0cch,0cch,033h	; 5003  1.3.3..3
	defb 0cch,0cch,0c1h,031h,0c1h,0c1h,0c1h,0c1h	; 500b  ...1....
	defb 0c1h,0c1h,0c1h,033h,0cch,0cch,0cch,0cch	; 5013  ...3....
	defb 0c1h,0c1h,0c1h,033h,0cch,0cch,0cch,0cch	; 501b  ...3....
	defb 0cch,0cch,0c1h,031h,0c1h,0c1h,0c1h,0c1h	; 5023  ...1....
	defb 0c1h,0c1h,0c1h,033h,0cch,0cch,0cch,0cch	; 502b  ...3....
	defb 031h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h	; 5033  1.......

; ----------------------------------------------------------------------
; DATOS sprites_0_22: 23 sprites de 16x16 (32 bytes cada uno): el jugador por
;   partes (0-14), las poses de muerte (15-22). Espejados dan los sprites
;   23-45
;   0x503b..0x531b  (736 bytes)
DATA_sprites_0_22:
	defb 000h,001h,00fh,01fh,03fh,07fh,0ffh,0ffh	; 503b  ....?...
	defb 0fch,0f8h,0f8h,0fch,03fh,01fh,00fh,000h	; 5043  ....?...
	defb 000h,0e4h,0ffh,0ffh,0fch,000h,000h,000h	; 504b  ........
	defb 008h,008h,000h,000h,000h,000h,000h,000h	; 5053  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 505b  ........
	defb 003h,007h,007h,003h,000h,000h,000h,001h	; 5063  ........
	defb 000h,000h,000h,000h,000h,0feh,0feh,0feh	; 506b  ........
	defb 0f6h,0f7h,0ffh,0feh,0feh,0f8h,0fch,080h	; 5073  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 507b  ........
	defb 003h,007h,007h,003h,000h,000h,000h,001h	; 5083  ........
	defb 000h,000h,000h,000h,000h,0feh,0feh,0f6h	; 508b  ........
	defb 0f6h,0f7h,0ffh,0feh,0e2h,0e0h,0f8h,080h	; 5093  ........
	defb 003h,00fh,01fh,03bh,033h,033h,007h,000h	; 509b  ...;33..
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 50a3  ........
	defb 0c0h,0e0h,0f3h,0ffh,0feh,0f0h,0f0h,000h	; 50ab  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 50b3  ........
	defb 000h,000h,000h,000h,000h,000h,000h,007h	; 50bb  ........
	defb 007h,003h,003h,007h,00eh,018h,01ch,00eh	; 50c3  ........
	defb 000h,000h,000h,000h,000h,000h,000h,0f0h	; 50cb  ........
	defb 0f0h,0f8h,018h,009h,00fh,00fh,00ch,000h	; 50d3  ........
	defb 003h,003h,007h,007h,007h,003h,007h,000h	; 50db  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 50e3  ........
	defb 0c0h,0e0h,0f0h,0f0h,0f0h,0fch,0fch,000h	; 50eb  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 50f3  ........
	defb 000h,000h,000h,000h,000h,000h,000h,007h	; 50fb  ........
	defb 007h,003h,01bh,01fh,018h,018h,010h,000h	; 5103  ........
	defb 000h,000h,000h,000h,000h,000h,000h,0f0h	; 510b  ........
	defb 0f0h,0f0h,030h,030h,030h,060h,0f0h,0fch	; 5113  ..000`..
	defb 003h,003h,003h,003h,003h,003h,007h,000h	; 511b  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 5123  ........
	defb 0c0h,0e0h,0f0h,0f0h,0f0h,0f0h,0f0h,000h	; 512b  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 5133  ........
	defb 000h,000h,000h,000h,000h,000h,000h,007h	; 513b  ........
	defb 007h,003h,001h,003h,007h,006h,005h,001h	; 5143  ........
	defb 000h,000h,000h,000h,000h,000h,000h,0f0h	; 514b  ........
	defb 0f0h,0f0h,0f8h,0f8h,0f0h,0c0h,0e0h,0f8h	; 5153  ........
	defb 003h,00fh,01fh,03bh,033h,033h,007h,000h	; 515b  ...;33..
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 5163  ........
	defb 0e0h,0f0h,0f8h,0fch,0f6h,0f6h,0f0h,000h	; 516b  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 5173  ........
	defb 000h,000h,000h,000h,000h,000h,000h,007h	; 517b  ........
	defb 007h,003h,001h,001h,001h,001h,003h,003h	; 5183  ........
	defb 000h,000h,000h,000h,000h,000h,000h,0f0h	; 518b  ........
	defb 0f0h,0e0h,0c0h,0c0h,0c0h,0c0h,0e0h,0f8h	; 5193  ........
	defb 003h,00fh,01fh,03bh,033h,033h,007h,000h	; 519b  ...;33..
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 51a3  ........
	defb 0c0h,0e0h,0f3h,0ffh,0fch,0f0h,0f0h,000h	; 51ab  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 51b3  ........
	defb 000h,000h,000h,000h,000h,000h,000h,007h	; 51bb  ........
	defb 067h,0ffh,0dch,0c0h,000h,000h,000h,000h	; 51c3  g.......
	defb 000h,000h,000h,000h,000h,000h,000h,0f0h	; 51cb  ........
	defb 0fdh,00fh,006h,006h,000h,000h,000h,000h	; 51d3  ........
	defb 03ch,03fh,07fh,07fh,07eh,07eh,070h,000h	; 51db  <?..~~p.
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 51e3  ........
	defb 038h,038h,0f0h,0e0h,000h,000h,000h,000h	; 51eb  88......
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 51f3  ........
	defb 000h,000h,000h,000h,000h,001h,00fh,07fh	; 51fb  ........
	defb 03fh,01eh,000h,000h,000h,000h,000h,000h	; 5203  ?.......
	defb 000h,000h,000h,000h,0e0h,0f2h,0fah,0beh	; 520b  ........
	defb 01eh,00eh,006h,000h,000h,000h,000h,000h	; 5213  ........
	defb 070h,070h,074h,032h,031h,072h,074h,070h	; 521b  ppt21rtp
	defb 070h,070h,07eh,07eh,07fh,03fh,03fh,01fh	; 5223  pp~~.??.
	defb 000h,000h,040h,080h,000h,080h,040h,000h	; 522b  ..@...@.
	defb 000h,000h,01ch,01ch,03ch,0fch,0f8h,0f0h	; 5233  ....<...
	defb 007h,000h,000h,000h,000h,000h,000h,000h	; 523b  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 5243  ........
	defb 0e0h,000h,000h,000h,000h,000h,000h,000h	; 524b  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 5253  ........
	defb 000h,007h,00bh,00dh,00eh,00dh,00bh,00fh	; 525b  ........
	defb 00fh,00fh,001h,001h,000h,000h,000h,000h	; 5263  ........
	defb 060h,0f8h,0b0h,060h,0e0h,062h,0a2h,0f2h	; 526b  `..`.b..
	defb 0feh,0feh,0e3h,0e3h,0c0h,000h,000h,000h	; 5273  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 527b  ........
	defb 03eh,07eh,0feh,0feh,0feh,07fh,03fh,000h	; 5283  >~....?.
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 528b  ........
	defb 000h,000h,000h,000h,070h,0f0h,0f0h,000h	; 5293  ....p...
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 529b  ........
	defb 001h,001h,001h,001h,001h,000h,000h,000h	; 52a3  ........
	defb 000h,0e0h,070h,038h,078h,0e0h,0c0h,0c0h	; 52ab  ..p8x...
	defb 0c0h,0f0h,0f0h,0f0h,080h,000h,000h,000h	; 52b3  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 52bb  ........
	defb 03eh,07fh,0ffh,0feh,0feh,07eh,03eh,000h	; 52c3  >....~>.
	defb 000h,000h,000h,000h,000h,070h,070h,070h	; 52cb  .....ppp
	defb 070h,0e0h,0c0h,000h,000h,000h,000h,000h	; 52d3  p.......
	defb 000h,00fh,003h,001h,003h,006h,007h,003h	; 52db  ........
	defb 001h,000h,000h,001h,001h,001h,001h,000h	; 52e3  ........
	defb 000h,000h,000h,000h,001h,001h,003h,08fh	; 52eb  ........
	defb 08fh,003h,020h,0e0h,0e0h,0c0h,080h,000h	; 52f3  .. .....
	defb 000h,000h,00fh,07fh,0ffh,07fh,00fh,000h	; 52fb  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 5303  ........
	defb 000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 530b  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 5313  ........

; ----------------------------------------------------------------------
; DATOS sprites_46_63: 18 sprites: peces (46-48), bola que rueda (49), bola
;   que bota (50), arana (51), pajaro sin uso (52), sombra (53), 50/100/200
;   (54-56 no: 56-58), caras contenta/llorando/normal/preocupada (59-62) y la
;   fruta (63)
;   0x531b..0x555b  (576 bytes)
DATA_sprites_46_63:
	defb 001h,003h,007h,007h,00fh,00fh,00fh,00fh	; 531b  ........
	defb 00fh,007h,00fh,00dh,008h,000h,000h,000h	; 5323  ........
	defb 000h,000h,000h,000h,000h,000h,0c0h,000h	; 532b  ........
	defb 080h,080h,0c0h,0ffh,01ch,00ch,004h,000h	; 5333  ........
	defb 000h,000h,000h,000h,000h,000h,002h,002h	; 533b  ........
	defb 01fh,07fh,03fh,00fh,000h,000h,000h,000h	; 5343  ..?.....
	defb 010h,010h,01eh,01ch,018h,010h,030h,0f0h	; 534b  ......0.
	defb 0f0h,0e0h,0f0h,0b8h,000h,000h,000h,000h	; 5353  ........
	defb 000h,020h,030h,038h,0ffh,003h,001h,001h	; 535b  . 08....
	defb 000h,003h,000h,000h,000h,000h,000h,000h	; 5363  ........
	defb 000h,000h,000h,010h,0b0h,0f0h,0e0h,0f0h	; 536b  ........
	defb 0f0h,0f0h,0f0h,0b0h,0e0h,0e0h,0c0h,000h	; 5373  ........
	defb 000h,000h,007h,00fh,01bh,03fh,02fh,02fh	; 537b  .....?//
	defb 02fh,02fh,03fh,01fh,00fh,007h,000h,000h	; 5383  //?.....
	defb 000h,000h,0e0h,0f0h,0f8h,0fch,0fch,0fch	; 538b  ........
	defb 0fch,0fch,0fch,0f8h,0f0h,0e0h,000h,000h	; 5393  ........
	defb 000h,000h,000h,001h,003h,006h,00dh,01bh	; 539b  ........
	defb 01bh,01fh,00dh,007h,000h,000h,000h,000h	; 53a3  ........
	defb 000h,000h,000h,080h,0c0h,0e0h,0f0h,0f8h	; 53ab  ........
	defb 0f8h,0f8h,0f0h,0e0h,000h,000h,000h,000h	; 53b3  ........
	defb 000h,000h,002h,00ah,01fh,00eh,03bh,01bh	; 53bb  ......;.
	defb 06bh,01bh,02fh,01fh,013h,002h,000h,000h	; 53c3  k./.....
	defb 000h,000h,040h,050h,0f8h,0f0h,0fch,0f8h	; 53cb  ..@P....
	defb 0f6h,0f8h,0f4h,0f8h,0c8h,040h,000h,000h	; 53d3  .....@..
	defb 01ch,00eh,002h,060h,0f8h,040h,000h,000h	; 53db  ...`.@..
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 53e3  ........
	defb 038h,070h,040h,006h,01fh,002h,000h,000h	; 53eb  8p@.....
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 53f3  ........
	defb 07fh,000h,000h,000h,000h,000h,000h,000h	; 53fb  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 5403  ........
	defb 0feh,000h,000h,000h,000h,000h,000h,000h	; 540b  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 5413  ........
	defb 066h,0e7h,0a5h,024h,018h,0c3h,0e7h,0a5h	; 541b  f..$....
	defb 099h,0ffh,07eh,042h,024h,000h,000h,000h	; 5423  ..~B$...
	defb 063h,077h,014h,000h,02ch,06ch,06dh,06dh	; 542b  cw..,lmm
	defb 06dh,06dh,0dbh,0b7h,06fh,01eh,002h,006h	; 5433  mm..o...
	defb 000h,000h,000h,000h,000h,000h,000h,042h	; 543b  .......B
	defb 066h,000h,000h,000h,000h,000h,000h,000h	; 5443  f.......
	defb 000h,000h,000h,000h,010h,092h,092h,092h	; 544b  ........
	defb 092h,092h,024h,048h,010h,000h,000h,000h	; 5453  ..$H....
	defb 000h,000h,000h,000h,00fh,008h,008h,00eh	; 545b  ........
	defb 001h,001h,00eh,000h,000h,000h,000h,000h	; 5463  ........
	defb 000h,000h,000h,000h,030h,048h,048h,048h	; 546b  ....0HHH
	defb 048h,048h,030h,000h,000h,000h,000h,000h	; 5473  HH0.....
	defb 000h,000h,000h,000h,011h,032h,012h,012h	; 547b  .....2..
	defb 012h,012h,039h,000h,000h,000h,000h,000h	; 5483  ..9.....
	defb 000h,000h,000h,000h,08ch,052h,052h,052h	; 548b  .....RRR
	defb 052h,052h,08ch,000h,000h,000h,000h,000h	; 5493  RR......
	defb 000h,000h,000h,000h,031h,04ah,00ah,00ah	; 549b  ....1J..
	defb 012h,022h,079h,000h,000h,000h,000h,000h	; 54a3  ."y.....
	defb 000h,000h,000h,000h,08ch,052h,052h,052h	; 54ab  .....RRR
	defb 052h,052h,08ch,000h,000h,000h,000h,000h	; 54b3  RR......
	defb 000h,00fh,01fh,03eh,074h,060h,040h,040h	; 54bb  ...>t`@@
	defb 002h,000h,000h,008h,007h,000h,000h,000h	; 54c3  ........
	defb 000h,0f0h,0f8h,0bch,02eh,006h,002h,002h	; 54cb  ........
	defb 040h,000h,000h,010h,0e0h,000h,000h,000h	; 54d3  @.......
	defb 000h,00fh,01fh,03eh,074h,060h,040h,044h	; 54db  ...>t`@D
	defb 00eh,004h,000h,000h,005h,00ah,000h,000h	; 54e3  ........
	defb 000h,0f0h,0f8h,0bch,02eh,006h,002h,022h	; 54eb  ......."
	defb 070h,020h,000h,000h,0a0h,050h,000h,000h	; 54f3  p ...P..
	defb 000h,00fh,01fh,03eh,074h,060h,040h,040h	; 54fb  ...>t`@@
	defb 002h,000h,000h,000h,004h,003h,000h,000h	; 5503  ........
	defb 000h,0f0h,0f8h,0bch,02eh,006h,002h,002h	; 550b  ........
	defb 040h,000h,000h,000h,020h,0c0h,000h,000h	; 5513  @... ...
	defb 000h,00fh,01fh,03eh,074h,060h,042h,040h	; 551b  ...>t`B@
	defb 000h,000h,000h,000h,005h,00ah,000h,000h	; 5523  ........
	defb 000h,0f0h,0f8h,0bch,02eh,006h,042h,002h	; 552b  ......B.
	defb 000h,000h,000h,000h,0a0h,050h,000h,000h	; 5533  .....P..
	defb 000h,000h,001h,00dh,01eh,037h,02fh,02fh	; 553b  .....7//
	defb 02fh,03fh,01fh,01fh,00fh,006h,000h,000h	; 5543  /?......
	defb 000h,0e0h,000h,060h,0f0h,0f8h,0f8h,0f8h	; 554b  ...`....
	defb 0f8h,0f8h,0f0h,0f0h,0e0h,0c0h,000h,000h	; 5553  ........

; ----------------------------------------------------------------------
; DATOS tabla_de_lianas: Nueve punteros a los nueve dibujos de la liana, de
;   izquierda a derecha
;   0x555b..0x556d  (18 bytes)
DATA_tabla_de_lianas:
	defw 0556dh	; 555b  -> DATA_dibujos_de_la_liana
	defw 05595h	; 555d
	defw 055bdh	; 555f
	defw 055e5h	; 5561
	defw 0560dh	; 5563
	defw 0563dh	; 5565
	defw 05665h	; 5567
	defw 0568dh	; 5569
	defw 056b5h	; 556b

; ----------------------------------------------------------------------
; DATOS dibujos_de_la_liana: Nueve dibujos de 40 bytes: tiles con
;   0xFE/0xFD/0xFC de salto de fila y 0xFF de fin, y detras Y, X1, X2 del cabo
;   (donde se agarra)
;   0x556d..0x56dd  (368 bytes)
DATA_dibujos_de_la_liana:
	defb 0feh,0b5h,000h,0feh,062h,063h,000h,0feh,064h,065h,000h,000h,0feh,064h,066h,000h	; 556d  ....bc..de...df.
	defb 000h,000h,0feh,067h,068h,000h,000h,000h,000h,0fch,000h,000h,000h,000h,000h,0fch	; 557d  ...gh...........
	defb 000h,000h,000h,000h,0ffh,04eh,01ch,07ch,0feh,0b0h,0b1h,0feh,069h,06ah,000h,0feh	; 558d  .....N.|....ij..
	defb 000h,06bh,000h,000h,0feh,000h,06ch,06dh,000h,000h,0feh,000h,062h,06eh,000h,000h	; 559d  .k....lm....bn..
	defb 000h,0fch,06fh,000h,000h,000h,000h,0fch,000h,000h,000h,000h,0ffh,052h,022h,082h	; 55ad  ..o..........R".
	defb 0feh,0b2h,0b3h,0feh,000h,070h,000h,0feh,000h,069h,071h,000h,0feh,000h,000h,060h	; 55bd  .....p...iq....`
	defb 000h,000h,0feh,000h,000h,072h,073h,000h,000h,0fch,000h,074h,000h,000h,000h,0fch	; 55cd  .....rs....t....
	defb 075h,000h,000h,000h,0ffh,057h,02ah,08ah,0feh,000h,0b4h,0feh,000h,076h,077h,0feh	; 55dd  u....W*......vw.
	defb 000h,000h,078h,000h,0feh,000h,000h,000h,079h,000h,0feh,000h,000h,000h,000h,07ah	; 55ed  ..x.....y......z
	defb 000h,0fch,000h,000h,07bh,07ch,000h,0fch,000h,07dh,000h,000h,0ffh,05ch,036h,096h	; 55fd  ....{|...}...\6.
	defb 0feh,000h,0b6h,0feh,000h,000h,061h,000h,0feh,000h,000h,000h,061h,000h,0feh,000h	; 560d  ......a.....a...
	defb 000h,000h,000h,061h,000h,0feh,000h,000h,000h,000h,000h,061h,000h,0fch,000h,000h	; 561d  ...a.......a....
	defb 000h,000h,061h,000h,000h,0fch,000h,000h,000h,061h,000h,000h,0ffh,05eh,045h,0a5h	; 562d  ..a......a...^E.
	defb 0fdh,0bbh,000h,0fdh,095h,094h,000h,0fdh,000h,096h,000h,000h,0fdh,000h,097h,000h	; 563d  ................
	defb 000h,000h,0fdh,000h,098h,000h,000h,000h,000h,0fdh,000h,09ah,099h,000h,000h,0fdh	; 564d  ................
	defb 000h,000h,09bh,000h,0ffh,05ch,054h,0b4h,0fdh,0bah,0b9h,0fdh,000h,08eh,000h,0fdh	; 565d  .....\T.........
	defb 000h,08fh,087h,000h,0fdh,000h,000h,07eh,000h,000h,0fdh,000h,000h,091h,090h,000h	; 566d  .......~........
	defb 000h,0fdh,000h,000h,000h,092h,000h,0fdh,000h,000h,000h,093h,0ffh,057h,060h,0c0h	; 567d  .............W`.
	defb 0fdh,0b8h,0b7h,0fdh,000h,088h,087h,0fdh,000h,000h,089h,000h,0fdh,000h,000h,08bh	; 568d  ................
	defb 08ah,000h,0fdh,000h,000h,000h,08ch,080h,000h,0fdh,000h,000h,000h,000h,08dh,0fdh	; 569d  ................
	defb 000h,000h,000h,000h,0ffh,052h,068h,0c8h,0fdh,000h,0bch,0fdh,000h,081h,080h,0fdh	; 56ad  .....Rh.........
	defb 000h,000h,083h,082h,0fdh,000h,000h,000h,084h,082h,0fdh,000h,000h,000h,000h,086h	; 56bd  ................
	defb 085h,0fdh,000h,000h,000h,000h,000h,0fdh,000h,000h,000h,000h,0ffh,04eh,06eh,0ceh	; 56cd  .............Nn.

; ----------------------------------------------------------------------
; DATOS tabla_de_surtidores: 18 punteros a los 18 bloques de la tabla del
;   surtidor subiendo
;   0x56dd..0x5701  (36 bytes)
DATA_tabla_de_surtidores:
	defw 05701h,05714h,05727h,0573ah,0574dh,05760h,05773h,05786h,05799h	; 56dd
	defw 057ach,057bfh,057d2h,057e5h,057f8h,0580bh,0581eh,05831h,05844h	; 56ef

; ----------------------------------------------------------------------
; DATOS bloques_de_surtidor: 18 bloques de 6x3 tiles mas un byte: la tabla
;   sobre su chorro de agua a 18 alturas, y la altura (0x52 abajo... 0x32
;   arriba, de dos en dos)
;   0x5701..0x5857  (342 bytes)
DATA_bloques_de_surtidor:
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,0b3h,0b4h,0b5h,0c3h,0c4h,0c5h,052h	; 5701  ..................R
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,0b2h,0b2h,0b2h,0bfh,0beh,0c0h,052h	; 5714  ..................R
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,0b6h,0b6h,0b6h,0bah,0bbh,0bch,0cdh,0ceh,0cfh,04eh	; 5727  ..................N
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,0b6h,0b6h,0b6h,0b7h,0b8h,0b9h,0c8h,0c9h,0cah,04eh	; 573a  ..................N
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,0b3h,0b4h,0b5h,0c3h,0c4h,0c5h,000h,0bdh,000h,04ah	; 574d  ..................J
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,0b2h,0b2h,0b2h,0bfh,0beh,0c0h,000h,0bdh,000h,04ah	; 5760  ..................J
	defb 000h,000h,000h,000h,000h,000h,0b6h,0b6h,0b6h,0bah,0bbh,0bch,0cdh,0ceh,0cfh,000h,0bdh,000h,046h	; 5773  ..................F
	defb 000h,000h,000h,000h,000h,000h,0b6h,0b6h,0b6h,0b7h,0b8h,0b9h,0c8h,0c9h,0cah,000h,0bdh,000h,046h	; 5786  ..................F
	defb 000h,000h,000h,000h,000h,000h,0b3h,0b4h,0b5h,0c3h,0c4h,0c5h,000h,0bdh,000h,000h,0bdh,000h,042h	; 5799  ..................B
	defb 000h,000h,000h,000h,000h,000h,0b2h,0b2h,0b2h,0bfh,0beh,0c0h,000h,0bdh,000h,000h,0bdh,000h,042h	; 57ac  ..................B
	defb 000h,000h,000h,0b6h,0b6h,0b6h,0bah,0bbh,0bch,0cdh,0ceh,0cfh,000h,0bdh,000h,000h,0bdh,000h,03eh	; 57bf  ..................>
	defb 000h,000h,000h,0b6h,0b6h,0b6h,0b7h,0b8h,0b9h,0c8h,0c9h,0cah,000h,0bdh,000h,000h,0bdh,000h,03eh	; 57d2  ..................>
	defb 000h,000h,000h,0b3h,0b4h,0b5h,0c3h,0c4h,0c5h,000h,0bdh,000h,000h,0bdh,000h,000h,0bdh,000h,03ah	; 57e5  ..................:
	defb 000h,000h,000h,0b2h,0b2h,0b2h,0bfh,0beh,0c0h,000h,0bdh,000h,000h,0bdh,000h,000h,0bdh,000h,03ah	; 57f8  ..................:
	defb 0b6h,0b6h,0b6h,0bah,0bbh,0bch,0cdh,0ceh,0cfh,000h,0bdh,000h,000h,0bdh,000h,000h,0bdh,000h,036h	; 580b  ..................6
	defb 0b6h,0b6h,0b6h,0b7h,0b8h,0b9h,0c8h,0c9h,0cah,0cbh,0bdh,0cch,000h,0bdh,000h,000h,0bdh,000h,036h	; 581e  ..................6
	defb 0b3h,0b4h,0b5h,0c3h,0c4h,0c5h,0c6h,0bdh,0c7h,000h,0bdh,000h,000h,0bdh,000h,000h,0bdh,000h,032h	; 5831  ..................2
	defb 0b2h,0b2h,0b2h,0bfh,0beh,0c0h,0c2h,0bdh,0c1h,000h,0bdh,000h,000h,0bdh,000h,000h,0bdh,000h,032h	; 5844  ..................2

; ======================================================================
; CODIGO 0x5857..0x5aaf  (600 bytes)
; ======================================================================


MONTA_PANTALLA:		; Borra el estado de la pantalla (5A64) y la construye (5AE3)
	call BORRA_PANTALLA		;5857
	call CONSTRUYE_PANTALLA		;585a
	ret			;585d

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; UN FOTOGRAMA DE PARTIDA. Primero manda los 32 atributos de sprite a la
; VRAM; a los 24 pasos copia E158 en E159, que solo miran las bolas que
; ruedan; mientras el jugador este vivo (estado < 7) corre todo lo de la
; pantalla: tiempo, contadores,
; lianas, surtidores, bolas, peces, hoguera, bola que bota, aranas,
; abeja y tronco; y siempre el jugador (66A6).
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
FOTOGRAMA_DE_PARTIDA:		; Sprites a la VRAM, los obstaculos y el jugador
	ld hl,0e0b0h		;585e   ; Los 32 sprites (128 bytes) de la RAM a la VRAM, de una vez por fotograma
	ld de,03b00h		;5861
	ld bc,00080h		;5864
	call COPIA_A_VRAM		;5867
	ld a,(0e13bh)		;586a   ; E13B, los pasos que lleva andados el jugador
	cp 018h		;586d   ; A los 24 pasos arrancan los moviles que miran E159
	jr nz,L_5877		;586f
	ld hl,0e158h		;5871   ; E159 solo lo miran las bolas que ruedan (0x611B) y su cobro (0x6AF4); los demas moviles leen E158 y salen desde el primer fotograma
	ld a,(hl)			;5874
	inc hl			;5875
	ld (hl),a			;5876
L_5877:
	ld a,(0e138h)		;5877
	cp 007h		;587a   ; Del 7 en adelante el jugador esta muriendo: los obstaculos se paran
	jr nc,L_589F		;587c
	call TIEMPO		;587e   ; El tiempo y los contadores de fase, antes que los obstaculos
	call CONTADORES		;5881
	call LIANAS		;5884
	call SURTIDORES		;5887
	call BOLAS_QUE_RUEDAN		;588a
	call PECES		;588d
	call HOGUERA		;5890
	call BOLA_QUE_BOTA		;5893
	call ARANAS		;5896
	call ABEJA		;5899
	call TRONCO		;589c
L_589F:
	call JUGADOR		;589f   ; El jugador se pinta siempre, este muriendo o no
	ret			;58a2
PREPARA_DEMO:		; Fuente, graficos del juego, partida nueva, marcador y la primera pantalla
	call CARGA_FUENTE		;58a3
	call CARGA_GRAFICOS_JUEGO		;58a6
	call PARTIDA_NUEVA		;58a9
	call MARCADOR		;58ac
	jp MONTA_PANTALLA		;58af

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LOS MANDOS DE LA DEMO. En la pantalla 0 corre a la derecha y salta en
; X=0x38 y X=0x80; en la 1 decide por el estado del jugador: andando,
; salta al azar (el registro R resiembra el contador de fotogramas) y da
; la vuelta al pasar de X=0xB0; en la liana suelta cuando toca; sobre el
; tronco salta al llegar al borde. Luego corre el fotograma normal.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
FOTOGRAMA_DE_DEMO:		; Escribe en E009 lo que "pulsa" la demo y corre 585E
	ld a,(0e054h)		;58b2   ; E054, la pantalla: la demo se comporta distinto en la 0 y en la 1
	or a			;58b5
	jr nz,L_58D0		;58b6
	ld hl,0e009h		;58b8   ; E009 es lo que el juego lee como pulsado ahora; aqui lo escribe la demo, no el mando
	ld a,008h		;58bb   ; Derecha
	ld (hl),a			;58bd
	ld a,(0e135h)		;58be   ; En la pantalla 0 solo salta en dos sitios, X=0x38 y X=0x80: el resto es correr
	cp 038h		;58c1
	jr z,L_58C9		;58c3
	cp 080h		;58c5
	jr nz,L_58CE		;58c7
L_58C9:
	ld (hl),038h		;58c9   ; Derecha y salto (0x38 = derecha, espacio y SELECT), sin lo del fotograma anterior
	dec hl			;58cb
	ld (hl),000h		;58cc
L_58CE:
	jr L_5919		;58ce
L_58D0:
	dec a			;58d0   ; Solo la pantalla 1 tiene mandos propios; en cualquier otra la demo no toca nada
	jr nz,L_5919		;58d1
	ld hl,0e135h		;58d3   ; HL a la X del jugador, que es lo que miran las tres ramas de abajo
	ld a,(0e138h)		;58d6   ; E138, el estado del jugador
	or a			;58d9
	jr z,L_58E8		;58da   ; Cero: andando (0x58E8)
	dec a			;58dc
	jr z,L_5919		;58dd   ; Uno, en el aire: nada que pulsar, el arco va solo
	dec a			;58df
	jr z,L_591C		;58e0   ; Con A ya rebajado en dos, este cero es el estado 2: colgado de la liana
	cp 003h		;58e2   ; Y este 3 es el estado 5, montado en el tronco
	jr z,L_5925		;58e4
	jr L_5919		;58e6   ; Cualquier otro estado (trampolin, surtidor, poste, muriendo): quieto
L_58E8:
	ld a,(hl)			;58e8
	cp 0b0h		;58e9   ; Andando: si X esta entre 0x2E y 0xAF, cada cuatro fotogramas...
	jr nc,L_5914		;58eb
	sub 004h		;58ed
	cp 02ah		;58ef
	jr c,L_5914		;58f1
	ld a,(0e003h)		;58f3
	and 003h		;58f6
	jr z,L_5904		;58f8
	ld a,(0e139h)		;58fa
	xor 00ch		;58fd   ; ...da la vuelta (0x0C cambia izquierda por derecha)
L_58FF:
	ld (0e009h),a		;58ff
	jr L_5919		;5902
L_5904:
	ld a,r		;5904   ; ...o resiembra el contador con el registro R y salta
	and 07fh		;5906
	ld (0e003h),a		;5908
	ld hl,0e008h		;590b
	ld (hl),000h		;590e
	ld a,030h		;5910
	jr L_58FF		;5912
L_5914:
	ld a,(0e139h)		;5914
	jr L_58FF		;5917
L_5919:
	jp FOTOGRAMA_DE_PARTIDA		;5919
L_591C:
	ld a,(0e003h)		;591c   ; En la liana: suelta cuando el contador da la vuelta
	and 07fh		;591f
	jr z,L_5932		;5921
	jr L_5914		;5923
L_5925:
	ld a,(0e0d9h)		;5925   ; Sobre el tronco: sigue mientras el tronco vaya delante; salta al pasar de X=0xA4
	cp (hl)			;5928
	jr nc,L_5914		;5929
	cp 0a4h		;592b
	jr nc,L_5932		;592d
	xor a			;592f
	jr L_58FF		;5930
L_5932:
	ld hl,0e009h		;5932
	jr L_58C9		;5935
CARGA_GRAFICOS_JUEGO:		; Patrones y colores del juego (70A5), los espejos de las lianas y de los objetos, y los 64 sprites (23 dibujados, 23 espejados y 18 mas)
	call CARGA_PATRONES_Y_COLORES		;5937
	call TRIPLICA_PATRONES		;593a
	call TRIPLICA_COLORES		;593d
	ld hl,04c93h		;5940   ; Los objetos: 30 tiles 0x60-0x7D del tercio de en medio
	ld de,02b00h		;5943
	ld bc,000f0h		;5946
	call COPIA_A_VRAM		;5949
	ld hl,04c6bh		;594c   ; Siete tiles 0xB0-0xB6 del primer tercio...
	ld de,02580h		;594f
	ld bc,00038h		;5952
	call COPIA_A_VRAM		;5955
	ld hl,04c6bh		;5958   ; ...y su espejo (0x5A4B) para los 0xB7-0xBC
	ld bc,00118h		;595b
	call ESPEJA_TILES		;595e
	ld de,025b8h		;5961
	ld bc,00030h		;5964
	call COPIA_A_VRAM		;5967
	ld hl,0e158h		;596a   ; Las lianas espejadas: tiles 0x7E-0x9B del tercio de en medio
	ld de,02bf0h		;596d
	ld bc,000f0h		;5970
	call COPIA_A_VRAM		;5973
	ld hl,04d83h		;5976   ; 38 tiles 0xAF-0xD4 del tercio de en medio
	ld de,02d78h		;5979
	ld bc,00130h		;597c
	call COPIA_A_VRAM		;597f
	ld hl,04eabh		;5982   ; 16 tiles 0x9C-0xAB y su espejo en 0xD5-0xE4
	ld de,02ce0h		;5985
	ld bc,00080h		;5988
	call COPIA_A_VRAM		;598b
	ld hl,04eabh		;598e
	ld bc,00080h		;5991
	call ESPEJA_TILES		;5994
	ld de,02ea8h		;5997
	ld bc,00080h		;599a
	call COPIA_A_VRAM		;599d
	ld de,00b00h		;59a0   ; Blanco para los tiles 0x60-0xAE del tercio de en medio y 0xB0-0xBC del primero
	ld bc,00278h		;59a3
	ld a,0f0h		;59a6
	call RELLENA_VRAM		;59a8
	ld de,00580h		;59ab
	ld bc,00068h		;59ae
	ld a,0f0h		;59b1
	call RELLENA_VRAM		;59b3
	ld hl,04f2bh		;59b6   ; Colores de los 0xAF-0xBC, blanco sobre negro para los 0xBD-0xCF, y los de 0xD1-0xE4
	ld de,00d78h		;59b9
	ld bc,00070h		;59bc
	call COPIA_A_VRAM		;59bf
	ld de,00de8h		;59c2
	ld bc,00098h		;59c5
	ld a,0f1h		;59c8
	call RELLENA_VRAM		;59ca
	ld hl,04f9bh		;59cd
	ld de,00e88h		;59d0
	ld bc,00020h		;59d3
	call COPIA_A_VRAM		;59d6
	ld de,00ce0h		;59d9
	ld hl,04fbbh		;59dc
	ld bc,00080h		;59df
	call COPIA_A_VRAM		;59e2
	ld de,00ea8h		;59e5
	ld hl,04fbbh		;59e8
	ld bc,00080h		;59eb
	call COPIA_A_VRAM		;59ee
	ld de,01800h		;59f1   ; 23 sprites de 16x16 en 0x1800...
	ld hl,0503bh		;59f4
	ld bc,002e0h		;59f7
	call COPIA_A_VRAM		;59fa
	ld de,0503bh		;59fd   ; ...y sus espejos, mirando a la izquierda, en 0x1AE0 (sprites 23-45)
	ld hl,0504bh		;5a00
	ld ix,0e0b0h		;5a03
	ld b,017h		;5a07
ESPEJA_SPRITES:		; Da la vuelta a 23 sprites de 16x16 bit a bit en E0B0
	push bc			;5a09
	ld b,010h		;5a0a
ESPEJA_SPRITE_FILA:		; Una fila de 16 bits
	ld a,(de)			;5a0c   ; DE trae la columna izquierda del patron y HL la derecha, 16 bytes mas alla
	exx			;5a0d
	ld h,a			;5a0e
	exx			;5a0f
	ld a,(hl)			;5a10
	exx			;5a11
	ld l,a			;5a12
	ld b,010h		;5a13   ; Las dos columnas de la fila, 16 bits
ESPEJA_16_BITS:		; Los 16 bits, uno a uno
	add hl,hl			;5a15   ; El bit mas alto de la fila sale al acarreo...
	rr (ix+000h)		;5a16   ; ...y entra por arriba en el par IX+0 / IX+16, que se desplaza a la derecha: quedan del reves
	rr (ix+010h)		;5a1a   ; La columna izquierda del espejo recibe el reflejo de la derecha
	djnz ESPEJA_16_BITS		;5a1e
	exx			;5a20
	inc hl			;5a21
	inc de			;5a22
	inc ix		;5a23
	djnz ESPEJA_SPRITE_FILA		;5a25
	ld c,010h		;5a27   ; B ya vale 0, asi que BC son 16: los otros 16 bytes del sprite
	add hl,bc			;5a29
	ex de,hl			;5a2a
	add hl,bc			;5a2b
	ex de,hl			;5a2c
	add ix,bc		;5a2d
	pop bc			;5a2f
	djnz ESPEJA_SPRITES		;5a30
	ld de,01ae0h		;5a32   ; Los 23 espejos (0x2E0 bytes) montados en la RAM se copian a la VRAM
	ld hl,0e0b0h		;5a35
	ld bc,002e0h		;5a38
	call COPIA_A_VRAM		;5a3b
	ld hl,0531bh		;5a3e   ; Los sprites 46-63: peces, bolas, aranas, abeja, sombra, puntos, caras y fruta
	ld de,01dc0h		;5a41
	ld bc,00240h		;5a44
	call COPIA_A_VRAM		;5a47
	ret			;5a4a
ESPEJA_TILES:		; Da la vuelta bit a bit a BC bytes de HL en E130 (tiles espejados)
	ld de,0e130h		;5a4b
ESPEJA_TILES_BUCLE:		; Un byte
	push bc			;5a4e
	ld b,008h		;5a4f
	ld c,(hl)			;5a51
ESPEJA_8_BITS:		; Los 8 bits
	rl c		;5a52   ; El bit alto de C sale al acarreo y entra por el alto de A, que baja: A acaba del reves
	rra			;5a54
	djnz ESPEJA_8_BITS		;5a55
	ld (de),a			;5a57
	inc hl			;5a58
	inc de			;5a59
	pop bc			;5a5a
	dec bc			;5a5b   ; Un byte menos de los BC
	ld a,c			;5a5c
	or b			;5a5d
	jr nz,ESPEJA_TILES_BUCLE		;5a5e
	ld hl,0e130h		;5a60
	ret			;5a63
BORRA_PANTALLA:		; Pone a cero E130-E330 salvo las cuatro fases de lianas y surtidores, y arranca los tiempos de los peces y la abeja
	ld a,(0e131h)		;5a64   ; E131 y E133, la fase de las dos lianas
	ld b,a			;5a67
	ld a,(0e133h)		;5a68
	ld c,a			;5a6b
	ld a,(0e14dh)		;5a6c   ; E14D y E14F, la de dos de los surtidores
	ld d,a			;5a6f
	ld a,(0e14fh)		;5a70
	ld e,a			;5a73
	push bc			;5a74
	push de			;5a75
	ld hl,0e130h		;5a76   ; De E130 a E330 a cero de un ldir
	ld de,0e131h		;5a79
	ld (hl),000h		;5a7c
	ld bc,00200h		;5a7e
	ldir		;5a81
	pop de			;5a83
	pop bc			;5a84
	ld a,b			;5a85   ; Y las cuatro fases vuelven a su sitio
	ld (0e131h),a		;5a86
	ld a,c			;5a89
	ld (0e133h),a		;5a8a
	ld a,d			;5a8d
	ld (0e14dh),a		;5a8e
	ld a,e			;5a91
	ld (0e14fh),a		;5a92
	ld a,00ch		;5a95   ; Peces escalonados: E177 en 12 y E178 en 24 de los 31; aranas en las fases 5, 0 y 1
	ld (0e177h),a		;5a97
	ld a,018h		;5a9a
	ld (0e178h),a		;5a9c
	ld a,001h		;5a9f
	ld (0e17eh),a		;5aa1
	ld a,005h		;5aa4
	ld (0e17ch),a		;5aa6
	ld a,06ch		;5aa9   ; Altura segura del salto: el suelo
	ld (0e13ah),a		;5aab
	ret			;5aae

; ----------------------------------------------------------------------
; DATOS sprites_iniciales_11_15: Cinco atributos de sprite (Y, X, patron,
;   color) para los sprites 11-15: peces y bolas, escondidos
;   (Y=0xFC/0xCC/0xEC) hasta que arrancan
;   0x5aaf..0x5ac3  (20 bytes)
DATA_sprites_iniciales_11_15:
	defb 0fch,038h,000h,000h	; 5aaf
	defb 0cch,078h,000h,000h	; 5ab3
	defb 0ech,0b8h,000h,000h	; 5ab7
	defb 0cch,0ffh,000h,000h	; 5abb
	defb 0cch,0ffh,000h,000h	; 5abf

; ----------------------------------------------------------------------
; DATOS sprites_del_tronco: Los dos sprites del tronco (9 y 10): Y=0x87,
;   X=0x98 y 0xA8, patrones 0x58 y 0xB4 (uno el espejo del otro), verde claro
;   0x5ac3..0x5acb  (8 bytes)
DATA_sprites_del_tronco:
	defb 087h,098h,058h,003h	; 5ac3
	defb 087h,0a8h,0b4h,003h	; 5ac7

; ----------------------------------------------------------------------
; DATOS sprites_iniciales_16_18: Tres veces Y=0x8C, X=0xD0: las aranas (16-18)
;   y, reusado, la bola que bota (22)
;   0x5acb..0x5ad7  (12 bytes)
DATA_sprites_iniciales_16_18:
	defb 08ch,0d0h,000h,000h	; 5acb
	defb 08ch,0d0h,000h,000h	; 5acf
	defb 08ch,0d0h,000h,000h	; 5ad3

; ----------------------------------------------------------------------
; DATOS sprites_de_las_vidas: Cuatro tripletas Y=0xA7, X=0xE0/D0/C0/B0, patron
;   0xF4 (la cara normal): los sprites 27-30 de las vidas
;   0x5ad7..0x5ae3  (12 bytes)
DATA_sprites_de_las_vidas:
	defb 0a7h,0e0h,0f4h	; 5ad7
	defb 0a7h,0d0h,0f4h	; 5ada
	defb 0a7h,0c0h,0f4h	; 5add
	defb 0a7h,0b0h,0f4h	; 5ae0

; ======================================================================
; CODIGO 0x5ae3..0x5c32  (335 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; CONSTRUYE LA PANTALLA. Los flags de la pantalla salen de la tabla
; 0x5C32 (5B8F); luego se colocan los sprites de los obstaculos, se
; eligen las lianas espejadas o no, se pinta el decorado (5C72 o 5E71)
; y encima cada obstaculo fijo segun su bit de E156.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
CONSTRUYE_PANTALLA:		; Sprites fuera (0xC3), flags, sprites de obstaculos, lianas, decorado, obstaculos y jugador
	ld a,0c3h		;5ae3   ; Todos los atributos a 0xC3: ningun sprite a la vista
	ld hl,0e0b0h		;5ae5
	ld de,0e0b1h		;5ae8
	ld (hl),a			;5aeb
	ld bc,0007fh		;5aec
	ldir		;5aef
	call FLAGS_DE_PANTALLA		;5af1
	ld hl,05aafh		;5af4   ; Sprites 11-15 de la tabla de 0x5AAF
	ld de,0e0dch		;5af7
	ld bc,00014h		;5afa
	ldir		;5afd
	push hl			;5aff
	ld a,(0e058h)		;5b00   ; Entrando por la izquierda, las bolas E1AC/E1AD empiezan sin X (0xFF)
	cp 008h		;5b03
	jr nz,L_5B0F		;5b05
	ld hl,0e1ach		;5b07
	ld a,0ffh		;5b0a
	ld (hl),a			;5b0c
	inc hl			;5b0d
	ld (hl),a			;5b0e
L_5B0F:
	pop hl			;5b0f
	ld a,(0e158h)		;5b10
	and 020h		;5b13   ; Con tronco (bit 5 de E158) y sin surtidores, los sprites 9 y 10: el tronco (Y=0x87)
	jr z,L_5B26		;5b15
	ld a,(0e156h)		;5b17
	and 008h		;5b1a
	jr nz,L_5B26		;5b1c
	ld de,0e0d4h		;5b1e
	ld bc,00008h		;5b21
	ldir		;5b24
L_5B26:
	ld hl,05acbh		;5b26   ; Aranas (16-18) y bola que bota (22): Y=0x8C, X=0xD0
	ld de,0e0f0h		;5b29
	ld bc,0000ch		;5b2c
	ldir		;5b2f
	ld de,0e108h		;5b31
	ld hl,05acbh		;5b34
	ld bc,00004h		;5b37
	ldir		;5b3a
	ld a,(0e058h)		;5b3c   ; Entrando por la derecha la bola que bota sale por X=0x20
	cp 008h		;5b3f
	jr z,L_5B48		;5b41
	ld a,020h		;5b43
	ld (0e109h),a		;5b45
L_5B48:
	ld a,004h		;5b48   ; Los cuatro sprites de las vidas (27-30) y sus tiles
	ld hl,05ad7h		;5b4a
	ld de,0e11ch		;5b4d
L_5B50:
	ld bc,00003h		;5b50   ; Tres bytes por cara: Y, X y patron
	ldir		;5b53
	inc de			;5b55   ; El cuarto, el color, se salta: es el que dice si la vida se ve, y lo pone PINTA_VIDAS
	dec a			;5b56
	jr nz,L_5B50		;5b57
	call PINTA_VIDAS		;5b59   ; Y ahi se decide cuales de las cuatro caras llevan color y cuales quedan a cero
	ld a,(0e158h)		;5b5c   ; Arco de las bolas que ruedan: medio con el bit 1 de E158, alto con el bit 0, plano si no
	ld b,a			;5b5f   ; B guarda E158 entero: el bit 1 se mira ahora y el 0 despues
	ld hl,06ce3h		;5b60   ; Bit 1 puesto: el arco de 0x6CE3, que sube dieciseis puntos
	and 002h		;5b63
	jr nz,L_5B72		;5b65
	ld a,b			;5b67
	and 001h		;5b68
	ld hl,063a5h		;5b6a   ; Solo el bit 0: el de 0x63A5, que sube cuarenta y ocho
	jr nz,L_5B72		;5b6d
	ld hl,063b7h		;5b6f   ; Ninguno de los dos: el de 0x63B7, que solo sube tres: la bola casi no despega
L_5B72:
	ld (0e160h),hl		;5b72   ; E160, por donde va la primera bola dentro de su arco
	ld a,00eh		;5b75   ; La segunda bola arranca 14 bytes mas alla del arco
	call HL_MAS_A		;5b77
	ld (0e162h),hl		;5b7a   ; E162: en las tres tablas el byte 14 es el penultimo delta, asi que la segunda bola entra por la punta del arco y no bota a la vez que la primera
	ld hl,063c9h		;5b7d   ; El arco de salto para la bola que bota y los tres peces
	ld (0e173h),hl		;5b80
	ld (0e169h),hl		;5b83   ; E169, E16B y E16D: los tres peces arrancan todos al principio del mismo arco
	ld (0e16bh),hl		;5b86
	ld (0e16dh),hl		;5b89
	jp COLOCA_JUGADOR		;5b8c   ; Con los sprites ya puestos, el jugador entra por su lado
FLAGS_DE_PANTALLA:		; E156 y E158 = la pareja de la tabla 0x5C32 para SCENE modulo 32, retocada por la fase y por el SCENE
	ld a,(0e054h)		;5b8f
	and 01fh		;5b92   ; Modulo 32: de la pantalla 32 en adelante se repiten las mismas
	ld hl,05c32h		;5b94   ; La tabla de los obstaculos fijos
	call HL_MAS_A		;5b97
	ld b,(hl)			;5b9a   ; B, los fijos de esta pantalla
	ld a,020h		;5b9b   ; Los moviles estan 32 bytes mas alla, con el mismo indice
	call HL_MAS_A		;5b9d
	ld c,(hl)			;5ba0   ; C, los moviles
	ld a,(0e059h)		;5ba1   ; E059, el mismo numero de pantalla pero en BCD, que es el que se lee en el marcador
	and 003h		;5ba4   ; SCENE acabado en 0, 4 u 8 (BCD): sin obstaculos fijos, y de los moviles solo la abeja
	jr nz,L_5BAD		;5ba6
	ld b,a			;5ba8   ; A vale 0: ni un obstaculo fijo
	ld a,c			;5ba9
	and 080h		;5baa   ; Y de los moviles solo queda en pie el bit 7, la abeja
	ld c,a			;5bac
L_5BAD:
	ld a,(0e051h)		;5bad   ; La fase, tambien en BCD
	cp 001h		;5bb0   ; Fase 1: sin aranas ni abeja
	jr nz,L_5BB9		;5bb2
	ld a,c			;5bb4
	and 077h		;5bb5   ; Fuera los bits 3 y 7 de los moviles
	jr L_5BC4		;5bb7
L_5BB9:
	cp 004h		;5bb9   ; Fases 4 y siguientes...
	jr nc,L_5BC7		;5bbb   ; De la fase 4 en adelante no se quita nada: se anade
	cp 002h		;5bbd   ; Fase 2: como esta
	jr z,L_5BD1		;5bbf
	ld a,c			;5bc1   ; Fase 3: sin abeja
	and 07fh		;5bc2   ; Fuera el bit 7
L_5BC4:
	ld c,a			;5bc4
	jr L_5BD1		;5bc5
L_5BC7:
	bit 0,a		;5bc7   ; ...pares y con la pantalla vacia: al menos la abeja
	jr nz,L_5BD1		;5bc9   ; Fase impar: lo que diga la tabla
	ld a,c			;5bcb
	or b			;5bcc   ; Ni fijos ni moviles
	jr nz,L_5BD1		;5bcd
	ld c,080h		;5bcf   ; Una pantalla vacia en fase par no se queda en nada: al menos la abeja
L_5BD1:
	ld hl,0e156h		;5bd1   ; E156, los fijos
	ld (hl),b			;5bd4
	inc hl			;5bd5   ; E157 queda en medio y aqui se salta: lo escribe 0x5C79 con el cielo y no lo lee nadie en todo el cartucho
	inc hl			;5bd6
	ld (hl),c			;5bd7   ; E158, los moviles
	ld a,(0e051h)		;5bd8   ; Fase 2: la abeja baja al primer nivel; en las demas al cuarto
	cp 002h		;5bdb
	ld a,003h		;5bdd   ; 3 es el cuarto de los cuatro niveles de 0x64A4; solo vale para la primera salida, porque al esconderse se sortea otro (0x6452)
	jr nz,L_5BE2		;5bdf
	xor a			;5be1
L_5BE2:
	ld (0e179h),a		;5be2
	ld a,c			;5be5   ; Con bolas: 50 puntos por pasar cada una
	and 007h		;5be6   ; Bits 0-2: si esta pantalla lleva bolas rodando
	jr z,L_5BF2		;5be8
	ld hl,0e19ch		;5bea   ; E19C y E19D, lo que valen las dos
	ld (hl),005h		;5bed   ; 0x05 son 50 puntos: COBRA_PUNTOS parte el byte en dos cifras BCD y les pega un cero (0x6652)
	inc hl			;5bef
	ld (hl),005h		;5bf0
L_5BF2:
	ld a,(0e054h)		;5bf2   ; Bit 1 del SCENE, sin liana ni trampolines ni aranas: decorado con cielo (5C72)
	bit 1,a		;5bf5
	jr z,L_5C0C		;5bf7
	ld a,(0e156h)		;5bf9   ; Bits 1 y 2: liana o trampolines, algo de lo que colgarse o sobre lo que botar
	and 006h		;5bfc
	jr nz,L_5C0C		;5bfe
	ld a,(0e158h)		;5c00   ; Bit 3 de los moviles: aranas
	and 008h		;5c03
	jr nz,L_5C0C		;5c05
	call DECORADO_CON_CIELO		;5c07   ; Con la pantalla despejada se ve el fondo del cielo
	jr L_5C0F		;5c0a
L_5C0C:
	call DECORADO_NORMAL		;5c0c   ; El decorado normal: suelo y los cerros de arriba (5E71)
L_5C0F:
	call PINTA_TIERRA		;5c0f   ; La tierra, el rotulo del CHILD PARK si toca, el estanque, los postes, los trampolines, los charcos, la hoguera y la piedra
	call ROTULO_CHILD_PARK		;5c12   ; En las pantallas acabadas en 0 esta llamada pone E156 y E158 a cero: por eso va delante de los seis pintores, que asi se vuelven todos por donde han venido
	call PINTA_ESTANQUE		;5c15
	call PINTA_CHARCOS		;5c18   ; Los charcos antes que los trampolines: en la unica pantalla que lleva las dos cosas, los trampolines les pisan las X
	call PINTA_POSTES		;5c1b
	call PINTA_TRAMPOLINES		;5c1e
	call PREPARA_HOGUERA		;5c21   ; La hoguera y la piedra se reparten el sprite 31; ninguna de las 32 pantallas lleva las dos (los bits 5 y 6 nunca coinciden en 0x5C32)
	call PINTA_PIEDRA		;5c24   ; Y si alguna llevara las dos, la piedra pisaria a la hoguera: va la ultima
	ld b,004h		;5c27   ; 200 puntos por cada obstaculo de la lista E18C
	ld hl,0e18ch		;5c29   ; E18C-E18F, lo que se cobra por colgarse de una liana
L_5C2C:
	ld (hl),020h		;5c2c   ; 0x20 son 200 puntos, y se ponen los cuatro aunque la pantalla no tenga lianas
	inc hl			;5c2e
	djnz L_5C2C		;5c2f
	ret			;5c31

; ----------------------------------------------------------------------
; DATOS obstaculos_por_pantalla: Un byte por cada una de las 32 pantallas
;   (E156), indice SCENE modulo 32: bit 0 cinco charcos, 1 lianas, 2
;   trampolines, 3 surtidores, 4 postes, 5 piedra, 6 hoguera, 7 estanque
;   0x5c32..0x5c52  (32 bytes)
DATA_obstaculos_por_pantalla:
	defb 003h,082h,020h,004h,088h,000h,001h,020h,041h,010h,0c0h,000h,088h,040h,088h,020h	; 5c32  .. .... A....@. 
	defb 001h,004h,050h,080h,050h,040h,010h,020h,010h,082h,000h,005h,041h,088h,001h,050h	; 5c42  ..P.P@. ....A..P

; ----------------------------------------------------------------------
; DATOS moviles_por_pantalla: Un byte por cada una de las 32 pantallas (E158),
;   con el mismo indice: bits 0-2 bolas que ruedan, 3 aranas, 4 peces, 5
;   tronco, 6 bola que bota, 7 abeja
;   0x5c52..0x5c72  (32 bytes)
DATA_moviles_por_pantalla:
	defb 080h,0a0h,008h,008h,008h,00ch,080h,00ch,010h,008h,060h,008h,000h,080h,018h,002h	; 5c52  ..........`.....
	defb 010h,008h,048h,0a0h,040h,0c0h,008h,009h,008h,000h,001h,010h,058h,010h,018h,040h	; 5c62  ..H.@.......X..@

; ======================================================================
; CODIGO 0x5c72..0x5c7f  (13 bytes)
; ======================================================================


DECORADO_CON_CIELO:		; Cuatro cielos segun los bits 2-3 del SCENE (E157), por el despachador
	ld a,(0e054h)		;5c72
	and 00ch		;5c75   ; Bits 2-3 del numero de pantalla
	rrca			;5c77   ; A 0..3: el indice de la tabla de cielos
	rrca			;5c78
	ld (0e157h),a		;5c79
	call DESPACHA		;5c7c   ; Los cuatro destinos van pegados detras del CALL

; ----------------------------------------------------------------------
; DATOS tabla_de_cielos: Los cuatro decorados con cielo: 0x5C87, 0x5C9B,
;   0x5CAC, 0x5CA7
;   0x5c7f..0x5c87  (8 bytes)
DATA_tabla_de_cielos:
	defw 05c87h	; 5c7f  -> CIELO_0
	defw 05c9bh	; 5c81  -> CIELO_1
	defw 05cach	; 5c83  -> CIELO_2
	defw 05ca7h	; 5c85  -> CIELO_3

; ======================================================================
; CODIGO 0x5c87..0x5c94  (13 bytes)
; ======================================================================


CIELO_0:		; Cielo azul con cerros amarillos; el seto salvo con surtidores o postes (entonces solo la hierba)
	call CIELO_AZUL_AMARILLO		;5c87   ; Primero el fondo de las filas 3-8...
CIELO_SETO:		; El seto de la fila 10 salvo con surtidores o postes (bits 3-4 de E156)
	ld a,(0e156h)		;5c8a
	and 018h		;5c8d   ; Bits 3-4 de los fijos: surtidores o postes
	jr nz,$+41		;5c8f   ; Con ellos el seto taparia la fila 10, por donde salen: solo la hierba (0x5CB8)
PINTA_SETO:		; El seto verde de las filas 10-12 y la hierba
	call MOTOR_DE_ROTULOS		;5c91   ; ...y encima el seto y la hierba

; ----------------------------------------------------------------------
; DATOS parametros_de_5C91: Lista 0x6DDF, tiles 0x6F27, VRAM 0x3940 (fila 10)
;   0x5c94..0x5c9a  (6 bytes)
DATA_parametros_de_5C91:
	defw 06ddfh,06f27h,03940h	; 5c94  -> DATA_fondo_lista_seto DATA_fondo_tiles_seto 0x3940

; ======================================================================
; CODIGO 0x5c9a..0x5cbb  (33 bytes)
; ======================================================================


	ret			;5c9a
CIELO_1:		; Cielo azul con cerros verdes y el seto; con surtidores o postes se pinta en cambio el cielo 0 sin seto (0x5C87)
	ld a,(0e156h)		;5c9b
	and 018h		;5c9e
	jr nz,$-25		;5ca0   ; Con surtidores o postes se cambia de cielo entero: el 0, que ya vuelve a mirar estos mismos bits
	call CIELO_AZUL_VERDE		;5ca2
	jr $-20		;5ca5   ; Y al seto directamente, sin repetir la comprobacion
CIELO_3:		; Cielo rojo con cerros blancos; el seto salvo con surtidores o postes
	call CIELO_ROJO_BLANCO		;5ca7
	jr $-32		;5caa   ; Al seto de 0x5C8A, que si la hace: el cielo 3 se pinta tambien desde el 2
CIELO_2:		; Cielo rojo con cerros verdes y el seto; con surtidores o postes se pinta en cambio el cielo 3 sin seto (0x5CA7)
	ld a,(0e156h)		;5cac
	and 018h		;5caf
	jr nz,CIELO_3		;5cb1   ; El cielo 2 y el 3 llevan el mismo rojo; lo que cambia es el color de los cerros
	call CIELO_ROJO_VERDE		;5cb3
	jr $-37		;5cb6
PINTA_HIERBA:		; Solo la hierba de la fila 15
	call MOTOR_DE_ROTULOS		;5cb8   ; Arranca en la misma VRAM que el seto (0x3940), pero su lista solo llega a la fila de la hierba

; ----------------------------------------------------------------------
; DATOS parametros_de_5CB8: Lista 0x6DDB, tiles 0x6F24, VRAM 0x3940
;   0x5cbb..0x5cc1  (6 bytes)
DATA_parametros_de_5CB8:
	defw 06ddbh,06f24h,03940h	; 5cbb  -> DATA_fondo_lista_hierba DATA_fondo_tiles_hierba 0x3940

; ======================================================================
; CODIGO 0x5cc1..0x5cc5  (4 bytes)
; ======================================================================


	ret			;5cc1
CIELO_AZUL_AMARILLO:		; Filas 3-8: franjas azules y cerros amarillos
	call MOTOR_DE_ROTULOS		;5cc2   ; Los cuatro cielos comparten la lista 0x6DD4; lo unico que cambia son los tiles

; ----------------------------------------------------------------------
; DATOS parametros_de_5CC2: Lista 0x6DD4, tiles 0x6E90, VRAM 0x3860 (fila 3)
;   0x5cc5..0x5ccb  (6 bytes)
DATA_parametros_de_5CC2:
	defw 06dd4h,06e90h,03860h	; 5cc5  -> DATA_fondo_lista_cielo DATA_fondo_tiles_cielo_azul_amarillo 0x3860

; ======================================================================
; CODIGO 0x5ccb..0x5ccf  (4 bytes)
; ======================================================================


	ret			;5ccb
CIELO_AZUL_VERDE:		; Filas 3-8: franjas azules y cerros verdes
	call MOTOR_DE_ROTULOS		;5ccc   ; Otro bloque de tiles 0x25 bytes mas alla: mismo azul, cerros verdes

; ----------------------------------------------------------------------
; DATOS parametros_de_5CCC: Lista 0x6DD4, tiles 0x6EB5, VRAM 0x3860
;   0x5ccf..0x5cd5  (6 bytes)
DATA_parametros_de_5CCC:
	defw 06dd4h,06eb5h,03860h	; 5ccf  -> DATA_fondo_lista_cielo DATA_fondo_tiles_cielo_azul_verde 0x3860

; ======================================================================
; CODIGO 0x5cd5..0x5cd9  (4 bytes)
; ======================================================================


	ret			;5cd5
CIELO_ROJO_BLANCO:		; Filas 3-8: franjas rojas y cerros blancos
	call MOTOR_DE_ROTULOS		;5cd6   ; Otros 0x25: rojo con cerros blancos

; ----------------------------------------------------------------------
; DATOS parametros_de_5CD6: Lista 0x6DD4, tiles 0x6EDA, VRAM 0x3860
;   0x5cd9..0x5cdf  (6 bytes)
DATA_parametros_de_5CD6:
	defw 06dd4h,06edah,03860h	; 5cd9  -> DATA_fondo_lista_cielo DATA_fondo_tiles_cielo_rojo_blanco 0x3860

; ======================================================================
; CODIGO 0x5cdf..0x5ce3  (4 bytes)
; ======================================================================


	ret			;5cdf
CIELO_ROJO_VERDE:		; Filas 3-8: franjas rojas y cerros verdes
	call MOTOR_DE_ROTULOS		;5ce0   ; Y otros 0x25: rojo con cerros verdes

; ----------------------------------------------------------------------
; DATOS parametros_de_5CE0: Lista 0x6DD4, tiles 0x6EFF, VRAM 0x3860
;   0x5ce3..0x5ce9  (6 bytes)
DATA_parametros_de_5CE0:
	defw 06dd4h,06effh,03860h	; 5ce3  -> DATA_fondo_lista_cielo DATA_fondo_tiles_cielo_rojo_verde 0x3860

; ======================================================================
; CODIGO 0x5ce9..0x5ced  (4 bytes)
; ======================================================================


	ret			;5ce9
PINTA_TIERRA:		; La tierra de las filas 16-19
	call MOTOR_DE_ROTULOS		;5cea   ; La tierra se pinta siempre, lleve la pantalla lo que lleve

; ----------------------------------------------------------------------
; DATOS parametros_de_5CEA: Lista 0x6DE4, tiles 0x6F8B, VRAM 0x3A00 (fila 16)
;   0x5ced..0x5cf3  (6 bytes)
DATA_parametros_de_5CEA:
	defw 06de4h,06f8bh,03a00h	; 5ced  -> DATA_fondo_lista_tierra DATA_fondo_tiles_tierra 0x3a00

; ======================================================================
; CODIGO 0x5cf3..0x5cfd  (10 bytes)
; ======================================================================


	ret			;5cf3
PINTA_ESTANQUE:		; Bit 7 de E156: el estanque de las filas 16-18, columnas 9-22
	ld a,(0e156h)		;5cf4
	and 080h		;5cf7   ; Bit 7
	ret z			;5cf9   ; Sin estanque la fila 16 se queda con la tierra que acaba de pintar 0x5CEA
	call MOTOR_DE_ROTULOS		;5cfa   ; Y el estanque encima, en las mismas filas

; ----------------------------------------------------------------------
; DATOS parametros_de_5CFA: Lista 0x6DE8, tiles 0x6F8E, VRAM 0x3A09
;   0x5cfd..0x5d03  (6 bytes)
DATA_parametros_de_5CFA:
	defw 06de8h,06f8eh,03a09h	; 5cfd  -> DATA_fondo_lista_estanque DATA_fondo_tiles_estanque 0x3a09

; ======================================================================
; CODIGO 0x5d03..0x5e54  (337 bytes)
; ======================================================================


	ret			;5d03
PINTA_TRAMPOLINES:		; Bit 2: cuatro trampolines de 2x2 en la fila 16 (columnas 9, 13, 17, 21), sus X en E1A5 (100 puntos cada uno) y la fruta (sprite 19) arriba en una X al azar
	ld a,(0e156h)		;5d04
	and 004h		;5d07   ; Bit 2
	ret z			;5d09
	ld de,03a09h		;5d0a   ; Fila 16, columna 9: el primero
L_5D0D:
	ld hl,06fabh		;5d0d   ; El trampolin (tiles 0xD1-0xD4) cada cuatro columnas
	ld bc,00202h		;5d10   ; Dos filas por dos columnas
	push de			;5d13   ; PINTA_BLOQUE deja DE al final de la ultima fila, asi que la de partida se guarda
	call PINTA_BLOQUE		;5d14
	pop de			;5d17
	ld a,004h		;5d18   ; Cuatro columnas hasta el siguiente
	call DE_MAS_A		;5d1a
	ld a,e			;5d1d
	cp 019h		;5d1e   ; Columna 25: ya estan los cuatro
	jr nz,L_5D0D		;5d20
	ld hl,05fcdh		;5d22   ; X de los trampolines: 0x48, 0x68, 0x88, 0xA8 (misma tabla desde el otro lado)
	ld a,(0e058h)		;5d25   ; Por donde ha entrado el jugador
	cp 008h		;5d28
	jr z,L_5D2F		;5d2a
	ld hl,05fd0h		;5d2c   ; La otra mitad de la tabla; para los trampolines las dos dan el mismo 0x48
L_5D2F:
	ld de,0e1a5h		;5d2f   ; E1A5-E1A8, las X con que se cobran
	ld b,004h		;5d32
	call RELLENA_CADA_32		;5d34   ; 0x48, 0x68, 0x88 y 0xA8: justo las cuatro columnas que se acaban de pintar
	ld b,004h		;5d37
	ld hl,0e195h		;5d39   ; E195-E198, los puntos aun sin cobrar
L_5D3C:
	ld (hl),010h		;5d3c   ; 100 puntos cada uno
	inc hl			;5d3e
	djnz L_5D3C		;5d3f
	ld a,020h		;5d41   ; 200 por la fruta
	ld (0e19eh),a		;5d43
	ld hl,0e0fch		;5d46   ; La fruta: sprite 19 en Y=0x20, X = 0x48 + 32 al azar, patron 0xFC, amarilla
	ld (hl),a			;5d49   ; El 0x20 vale de paso como Y: la fruta se queda arriba del todo
	inc hl			;5d4a
	ld a,r		;5d4b   ; El registro de refresco hace de azar
	and 003h		;5d4d   ; Uno de cuatro
	rla			;5d4f   ; Por 32...
	rla			;5d50
	rla			;5d51
	rla			;5d52
	rla			;5d53
	add a,048h		;5d54   ; ...y desde 0x48: la fruta cae en la vertical de uno de los cuatro trampolines
	ld (hl),a			;5d56
	inc hl			;5d57
	ld (hl),0fch		;5d58   ; Patron 0xFC
	inc hl			;5d5a
	ld (hl),00ah		;5d5b   ; Color 0x0A, amarillo claro
	ret			;5d5d
PINTA_CHARCOS:		; Bit 0: cinco charcos de dos tiles en la fila 17 (columnas 7, 11, 15, 19, 23), sus X en E1A5 (100 puntos cada uno)
	ld a,(0e156h)		;5d5e
	and 001h		;5d61   ; Bit 0
	ret z			;5d63
	ld de,03a27h		;5d64   ; Fila 17, columna 7: una fila por debajo de los trampolines
	ld b,005h		;5d67   ; Cinco
L_5D69:
	push bc			;5d69
	ld hl,06fafh		;5d6a   ; Los dos tiles del charco (0xCF 0xD0)
	ld bc,00002h		;5d6d   ; Dos tiles seguidos, sin PINTA_BLOQUE: el charco es una sola fila
	call COPIA_A_VRAM		;5d70
	ld a,004h		;5d73   ; Cuatro columnas hasta el siguiente
	call DE_MAS_A		;5d75
	pop bc			;5d78
	djnz L_5D69		;5d79
	ld hl,05fceh		;5d7b   ; La tercera X de la tabla: 0x40 entrando por la izquierda
	ld a,(0e058h)		;5d7e
	cp 008h		;5d81
	jr z,L_5D88		;5d83
	ld hl,05fd1h		;5d85   ; 0x30 entrando por la derecha, porque yendo hacia la izquierda se cobra al bajar de la X y no al pasarla
L_5D88:
	ld de,0e1a5h		;5d88   ; Los mismos cinco huecos que los trampolines: la pantalla 27 es la unica que lleva las dos cosas (0x5C32 vale 0x05) y estas X pisan las que dejo 0x5D2F
	ld b,005h		;5d8b
	call RELLENA_CADA_32		;5d8d
	ld b,005h		;5d90
	ld hl,0e195h		;5d92   ; Y los mismos cinco contadores de puntos
L_5D95:
	ld (hl),010h		;5d95
	inc hl			;5d97
	djnz L_5D95		;5d98
	ret			;5d9a
PINTA_POSTES:		; Bit 4: los cinco postes del estanque, sus X en E1A0 (100 puntos), dos bajos de 3x2 en la fila 15 y tres altos de 4x2 en la 14
	ld a,(0e156h)		;5d9b
	and 010h		;5d9e   ; Bit 4
	ret z			;5da0
	ld hl,05fcch		;5da1   ; X de los postes: 0x30, 0x50, 0x70, 0x90, 0xB0
	ld a,(0e058h)		;5da4   ; Por donde ha entrado
	cp 008h		;5da7
	jr z,L_5DAE		;5da9
	ld hl,05fcfh		;5dab   ; Entrando por la derecha las X van 0x18 por delante de los postes: al caer encima de uno se esta como mucho a 15 puntos de su X (0x6726), y el cp de COBRA_AL_PASAR la exige estrictamente menor
L_5DAE:
	ld de,0e1a0h		;5dae   ; E1A0-E1A4
	ld b,005h		;5db1
	call RELLENA_CADA_32		;5db3   ; Cinco X separadas 32, las mismas que la tabla de 0x6746
	ld b,005h		;5db6
	ld hl,0e190h		;5db8   ; E190-E194
L_5DBB:
	ld (hl),010h		;5dbb   ; 0x10 son 100 puntos por poste
	inc hl			;5dbd
	djnz L_5DBB		;5dbe
	ld hl,06fb1h		;5dc0   ; Poste verde de la izquierda, en la fila 15
	ld de,039e7h		;5dc3   ; Fila 15, columna 7
	call PINTA_BLOQUE_3x2		;5dc6
	ld hl,06fb7h		;5dc9   ; Los tres altos: azul, verde y rojo, en la fila 14
	ld de,039cbh		;5dcc   ; Fila 14, columna 11
	call PINTA_BLOQUE_4x2		;5dcf
	ld hl,06fbfh		;5dd2   ; El verde, columna 15
	ld de,039cfh		;5dd5
	call PINTA_BLOQUE_4x2		;5dd8
	ld hl,06fc7h		;5ddb   ; El rojo, columna 19
	ld de,039d3h		;5dde
	call PINTA_BLOQUE_4x2		;5de1
	ld hl,06fb1h		;5de4   ; Poste verde de la derecha
	ld de,039f7h		;5de7   ; Fila 15, columna 23: el mismo dibujo que el de la izquierda
PINTA_BLOQUE_3x2:		; Bloque de 3 filas por 2 columnas
	ld bc,00302h		;5dea   ; El quinto poste cae aqui por su propio pie: ni CALL ni RET
	jp PINTA_BLOQUE		;5ded
PINTA_BLOQUE_4x2:		; Bloque de 4 filas por 2 columnas
	ld bc,00402h		;5df0
	jp PINTA_BLOQUE		;5df3
PREPARA_HOGUERA:		; Bit 6: la hoguera al fondo de la pantalla (X=0xDC o 0x14, segun por donde se entre) y su caja invisible, el sprite 31 en Y=0x7C
	ld a,(0e156h)		;5df6
	and 040h		;5df9   ; Bit 6
	ret z			;5dfb
	ld hl,0e1aah		;5dfc   ; E1AA, la X con la que se cobra la hoguera
	ld a,(0e058h)		;5dff
	cp 008h		;5e02   ; 8 = ha entrado por la izquierda
	ld (hl),0dch		;5e04   ; Entrando por la izquierda esta a la derecha, X=0xDC
	ld a,0d0h		;5e06   ; Y la caja de choque doce puntos a la izquierda de esa X
	jr z,L_5E0E		;5e08
	ld (hl),014h		;5e0a   ; Entrando por la derecha, la hoguera al otro lado
	ld a,020h		;5e0c
L_5E0E:
	ld hl,0e12ch		;5e0e   ; Sprite 31: Y=0x7C, X=0xD0 o 0x20, color 0x10 (invisible): la caja de choque
	ld (hl),07ch		;5e11   ; Y=0x7C son los pies del jugador, que anda con Y=0x6C
	inc hl			;5e13
	ld (hl),a			;5e14
	inc hl			;5e15
	inc hl			;5e16   ; El patron ni se toca: con color 0 el sprite no se ve, solo choca
	ld a,010h		;5e17   ; 100 puntos por saltarla
	ld (hl),a			;5e19   ; El color del sprite 31
	ld (0e19ah),a		;5e1a   ; El mismo 0x10 sirve dos veces: color del sprite y cien puntos en E19A
	ret			;5e1d
PINTA_PIEDRA:		; Bit 5: la piedra con matojo (tiles 0x19-0x1B) en la fila 17, columna 18 o 10, y su caja invisible (sprite 31, Y=0x80)
	ld a,(0e156h)		;5e1e
	and 020h		;5e21   ; Bit 5
	ret z			;5e23
	ld hl,0e1abh		;5e24   ; E1AB, la X con la que se cobra la piedra
	ld a,(0e058h)		;5e27
	cp 008h		;5e2a
	ld (hl),0a0h		;5e2c   ; X de la piedra para los puntos: 0xA0 o 0x48
	ld de,03a32h		;5e2e   ; Fila 17, columna 18
	ld a,094h		;5e31   ; Y la caja invisible en X=0x94, cuatro a la derecha del primer tile
	jr z,L_5E3C		;5e33
	ld de,03a2ah		;5e35   ; Entrando por la derecha, fila 17 columna 10
	ld (hl),048h		;5e38
	ld a,054h		;5e3a   ; Y la caja en X=0x54
L_5E3C:
	ld hl,05e54h		;5e3c   ; Los tres tiles y el 0xFF que los cierra
	push af			;5e3f   ; PINTA_LISTA_TILES se lleva A por delante
	call PINTA_LISTA_TILES		;5e40
	pop af			;5e43
	ld hl,0e12ch		;5e44   ; El sprite 31, el mismo de la hoguera
	ld (hl),080h		;5e47   ; Y=0x80, cuatro mas abajo que la caja de la hoguera: la piedra es mas baja
	inc hl			;5e49
	ld (hl),a			;5e4a
	inc hl			;5e4b
	inc hl			;5e4c
	ld a,010h		;5e4d   ; Otra vez el 0x10 doble: color invisible y cien puntos
	ld (hl),a			;5e4f   ; El color del 31, otra vez invisible
	ld (0e19bh),a		;5e50   ; E19B, el ultimo de los siete que repasa 0x6C67
	ret			;5e53

; ----------------------------------------------------------------------
; DATOS tiles_de_la_piedra: Los tres tiles de la piedra con matojo, 0x19 0x1A
;   0x1B, y el 0xFF de fin de lista
;   0x5e54..0x5e58  (4 bytes)
DATA_tiles_de_la_piedra:
	defb 019h,01ah,01bh	; 5e54
	defb 0ffh	; 5e57

; ======================================================================
; CODIGO 0x5e58..0x5e6a  (18 bytes)
; ======================================================================


ROTULO_CHILD_PARK:		; En el SCENE 0 y en los acabados en 0: sin obstaculos ninguno (E156 = E158 = 0) y el rotulo CHILD PARK en ladrillo rojo
	ld a,(0e059h)		;5e58
	or a			;5e5b   ; La pantalla 0, la de salida
	jr z,L_5E61		;5e5c
	and 00fh		;5e5e   ; SCENE 0, 10, 20...: la entrada y las metas
	ret nz			;5e60
L_5E61:
	ld (0e156h),a		;5e61   ; A vale 0: se borran los obstaculos que acaba de elegir 0x5B8F
	ld (0e158h),a		;5e64   ; Y los moviles: en la entrada y en las metas no hay nada que esquivar
	call MOTOR_DE_ROTULOS		;5e67   ; El cartel, fila 9 columna 9

; ----------------------------------------------------------------------
; DATOS parametros_de_5E67: Lista 0x6DF8, tiles 0x6FCF, VRAM 0x3929 (fila 9,
;   columna 9)
;   0x5e6a..0x5e70  (6 bytes)
DATA_parametros_de_5E67:
	defw 06df8h,06fcfh,03929h	; 5e6a  -> DATA_fondo_lista_child_park DATA_fondo_tiles_child_park 0x3929

; ======================================================================
; CODIGO 0x5e70..0x5e74  (4 bytes)
; ======================================================================


	ret			;5e70
DECORADO_NORMAL:		; La hierba de la fila 15 y los cerros de arriba: cuatro combinaciones por el bit 0 y el bit 2 del SCENE
	call MOTOR_DE_ROTULOS		;5e71   ; La hierba de la fila 15 va siempre, haya cerro o meseta

; ----------------------------------------------------------------------
; DATOS parametros_de_5E71: Lista 0x6DE2, tiles 0x6F8A, VRAM 0x39E0 (fila 15)
;   0x5e74..0x5e7a  (6 bytes)
DATA_parametros_de_5E71:
	defw 06de2h,06f8ah,039e0h	; 5e74  -> DATA_fondo_lista_hierba_15 DATA_fondo_tiles_hierba_15 0x39e0

; ======================================================================
; CODIGO 0x5e7a..0x5e85  (11 bytes)
; ======================================================================


	ld a,(0e054h)		;5e7a
	rra			;5e7d   ; Bits 1-2 del SCENE
	rra			;5e7e
	rlca			;5e7f   ; El rlca devuelve al bit 0 el bit que se habia ido al acarreo: el indice acaba siendo el bit 0 mas dos veces el bit 2 del numero de pantalla, no los bits 1-2
	and 003h		;5e80
	call DESPACHA		;5e82

; ----------------------------------------------------------------------
; DATOS tabla_de_cerros: Las cuatro combinaciones: 0x5E8D, 0x5E92, 0x5E97,
;   0x5E9C
;   0x5e85..0x5e8d  (8 bytes)
DATA_tabla_de_cerros:
	defw 05e8dh	; 5e85  -> CERROS_0
	defw 05e92h	; 5e87  -> CERROS_1
	defw 05e97h	; 5e89  -> CERROS_2
	defw 05e9ch	; 5e8b  -> CERROS_3

; ======================================================================
; CODIGO 0x5e8d..0x5ea4  (23 bytes)
; ======================================================================


CERROS_0:		; Cerro con pendiente a la izquierda y cerro con pendiente a la derecha
	call CERRO_IZQUIERDA		;5e8d
	jr $+57		;5e90   ; Y a la derecha, otro cerro (0x5EC9)
CERROS_1:		; Cerro con pendiente a la izquierda y meseta a la derecha
	call CERRO_IZQUIERDA		;5e92
	jr $+108		;5e95   ; A la derecha, meseta (0x5F01)
CERROS_2:		; Meseta a la izquierda y meseta a la derecha
	call MESETA_IZQUIERDA		;5e97
	jr $+103		;5e9a   ; Las dos mesetas
CERROS_3:		; Meseta a la izquierda y cerro con pendiente a la derecha
	call MESETA_IZQUIERDA		;5e9c
	jr $+42		;5e9f   ; Meseta a la izquierda y cerro a la derecha
CERRO_IZQUIERDA:		; Filas 2-4, columnas 0-15: el cerro con pendiente, y sus dos bloques de tiles
	call MOTOR_DE_ROTULOS		;5ea1   ; El perfil del cerro, filas 2-4 y columnas 0-15

; ----------------------------------------------------------------------
; DATOS parametros_de_5EA1: Lista 0x6E2A, tiles 0x6FF9, VRAM 0x3840 (fila 2)
;   0x5ea4..0x5eaa  (6 bytes)
DATA_parametros_de_5EA1:
	defw 06e2ah,06ff9h,03840h	; 5ea4  -> DATA_fondo_lista_cerro_izq DATA_fondo_tiles_cerro_izq 0x3840

; ======================================================================
; CODIGO 0x5eaa..0x5ecc  (34 bytes)
; ======================================================================


	ld hl,0700dh		;5eaa   ; Encima del cerro, la copa del arbol: 3 filas por 6 en la fila 5
	ld de,038a0h		;5ead
	call PINTA_BLOQUE_3x6		;5eb0
	ld hl,0701fh		;5eb3   ; Y su tronco, 8 por 4 desde la fila 8 columna 1
	ld de,03901h		;5eb6
PINTA_BLOQUE_8x4:		; Bloque de 8 filas por 4 columnas
	ld bc,00804h		;5eb9
	jr L_5EC6		;5ebc   ; Los tres tamanos acaban en el mismo salto
PINTA_BLOQUE_3x6:		; Bloque de 3 filas por 6 columnas
	ld bc,00306h		;5ebe
	jr L_5EC6		;5ec1
PINTA_BLOQUE_3x8:		; Bloque de 3 filas por 8 columnas
	ld bc,00308h		;5ec3
L_5EC6:
	jp PINTA_BLOQUE		;5ec6
CERRO_DERECHA:		; Filas 2-4, columnas 16-31: el cerro con pendiente
	call MOTOR_DE_ROTULOS		;5ec9   ; Su gemelo de la derecha, con lista y tiles propios

; ----------------------------------------------------------------------
; DATOS parametros_de_5EC9: Lista 0x6E44, tiles 0x703F, VRAM 0x3850 (fila 2,
;   columna 16)
;   0x5ecc..0x5ed2  (6 bytes)
DATA_parametros_de_5EC9:
	defw 06e44h,0703fh,03850h	; 5ecc  -> DATA_fondo_lista_cerro_der DATA_fondo_tiles_cerro_der 0x3850

; ======================================================================
; CODIGO 0x5ed2..0x5ee6  (20 bytes)
; ======================================================================


	ld hl,0700dh		;5ed2   ; El mismo arbol del cerro, ahora en la columna 26
	ld de,038bah		;5ed5
	call PINTA_BLOQUE_3x6		;5ed8
	ld hl,0701fh		;5edb
	ld de,0391bh		;5ede   ; Y su tronco, columna 27
	jr $-40		;5ee1   ; Vuelve al 8x4 del cerro de la izquierda
MESETA_IZQUIERDA:		; Filas 2-5, columnas 0-15: la meseta
	call MOTOR_DE_ROTULOS		;5ee3   ; La meseta llega una fila mas abajo que el cerro

; ----------------------------------------------------------------------
; DATOS parametros_de_5EE3: Lista 0x6E5E, tiles 0x7054, VRAM 0x3840
;   0x5ee6..0x5eec  (6 bytes)
DATA_parametros_de_5EE3:
	defw 06e5eh,07054h,03840h	; 5ee6  -> DATA_fondo_lista_meseta_izq DATA_fondo_tiles_meseta_izq 0x3840

; ======================================================================
; CODIGO 0x5eec..0x5f04  (24 bytes)
; ======================================================================


	ld hl,07064h		;5eec   ; La meseta lleva otro arbol: copa de 3 por 8 en la fila 5
	ld de,038a0h		;5eef
	call PINTA_BLOQUE_3x8		;5ef2
	ld hl,0707ch		;5ef5   ; Y tronco de 8 por 3 desde la fila 8, columna 3
	ld de,03903h		;5ef8
PINTA_BLOQUE_8x3:		; Bloque de 8 filas por 3 columnas
	ld bc,00803h		;5efb
	jp PINTA_BLOQUE		;5efe
MESETA_DERECHA:		; Filas 2-5, columnas 16-31: la meseta
	call MOTOR_DE_ROTULOS		;5f01   ; Y la meseta de la derecha

; ----------------------------------------------------------------------
; DATOS parametros_de_5F01: Lista 0x6E77, tiles 0x7094, VRAM 0x3850
;   0x5f04..0x5f0a  (6 bytes)
DATA_parametros_de_5F01:
	defw 06e77h,07094h,03850h	; 5f04  -> DATA_fondo_lista_meseta_der DATA_fondo_tiles_meseta_der 0x3850

; ======================================================================
; CODIGO 0x5f0a..0x5f4c  (66 bytes)
; ======================================================================


	ld hl,07064h		;5f0a   ; El arbol de meseta, columna 24
	ld de,038b8h		;5f0d
	call PINTA_BLOQUE_3x8		;5f10
	ld hl,0707ch		;5f13   ; Su tronco en la columna 27...
	ld de,0391bh		;5f16
	jr $-30		;5f19   ; ...con el 8x3 de la meseta de la izquierda
COLOCA_JUGADOR:		; Sprites 0-3 fuera, colores de los cuatro sprites del jugador, Y=0x6C, X y mirada segun por donde entra (E058), y sus sprites
	ld hl,05f61h		;5f1b   ; Y=0x90, patron 0 y color 0: los sprites 0-3 no pintan nada
	call CUATRO_SPRITES_IGUALES		;5f1e   ; Los sprites 0-3, los cuatro iguales
	ld hl,0e0c3h		;5f21   ; E0C3 es el color del sprite 4: el jugador son los sprites 4-7 uno encima de otro
	ld de,05f4ch		;5f24   ; Rojo, amarillo, magenta y azul: los cuatro sprites del jugador
	ld b,004h		;5f27   ; Los cuatro colores
L_5F29:
	ld a,(de)			;5f29   ; Solo el color, saltando de cuatro en cuatro; Y, X y patron los pone PINTA_JUGADOR
	ld (hl),a			;5f2a
	inc de			;5f2b
	inc hl			;5f2c
	inc hl			;5f2d
	inc hl			;5f2e
	inc hl			;5f2f
	djnz L_5F29		;5f30
	ld hl,0e134h		;5f32   ; Y del suelo
	ld (hl),06ch		;5f35   ; Y=0x6C, de pie en el suelo
	inc hl			;5f37
	ld a,(0e058h)		;5f38   ; X de entrada: 8 por la izquierda, 0xE8 por la derecha
	ld (hl),a			;5f3b   ; E135, la X
	cp 008h		;5f3c
	ld a,008h		;5f3e   ; Mira hacia donde va: 8 derecha, 4 izquierda
	jr z,L_5F43		;5f40
	rrca			;5f42   ; El 8 pasa a 4 con un solo rrca: mirando a la izquierda
L_5F43:
	inc hl			;5f43
	ld (hl),000h		;5f44   ; E136, la pose: de pie
	ld (0e139h),a		;5f46   ; E139, hacia donde mira
	jp PINTA_JUGADOR		;5f49   ; Y a pintarlo ya, sin esperar al fotograma siguiente

; ----------------------------------------------------------------------
; DATOS colores_del_jugador: Los colores de los sprites 4-7: 8 rojo, 0xB
;   amarillo, 0xD magenta, 4 azul
;   0x5f4c..0x5f50  (4 bytes)
DATA_colores_del_jugador:
	defb 008h,00bh,00dh,004h	; 5f4c

; ======================================================================
; CODIGO 0x5f50..0x5f61  (17 bytes)
; ======================================================================


CUATRO_SPRITES_IGUALES:		; Copia los 4 bytes de HL a los sprites 0-3
	ld de,0e0b0h		;5f50
	ld bc,00404h		;5f53   ; B = 4 sprites, C = 4 bytes cada uno
L_5F56:
	push hl			;5f56
	push bc			;5f57
	ld b,000h		;5f58   ; B a cero para que BC sean 4 en el ldir; el djnz recupera el suyo del push
	ldir		;5f5a
	pop bc			;5f5c
	pop hl			;5f5d
	djnz L_5F56		;5f5e
	ret			;5f60

; ----------------------------------------------------------------------
; DATOS sprite_fuera: Y=0x90 y ceros: los sprites 0-3 apartados
;   0x5f61..0x5f65  (4 bytes)
DATA_sprite_fuera:
	defb 090h,000h,000h,000h	; 5f61

; ======================================================================
; CODIGO 0x5f65..0x5fcc  (103 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL MOTOR DE ROTULOS. Tras cada CALL van SEIS BYTES de parametros:
; puntero a la lista, puntero a los tiles y direccion de VRAM. El
; POP HL los recoge y el PUSH HL devuelve el control detras de ellos.
; La lista es una cuenta por entrada: n copia n tiles de la lista de
; tiles; n|0x80 rellena n posiciones con UN tile; 0x80 solo, cambio de
; direccion (palabra detras); 0 fin. La VRAM avanza siempre n.
; Diecinueve llamadas: los creditos, todos los decorados y, en 0x70F0,
; las tablas de COLORES de los tiles.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
MOTOR_DE_ROTULOS:		; Pinta la lista de tiles que describen los 6 bytes que siguen al CALL
	pop hl			;5f65   ; HL = los seis bytes de parametros
	ld de,0e150h		;5f66   ; E150 la lista, E152 los tiles, E154 la VRAM
	ld bc,00006h		;5f69   ; Los seis: dos punteros y una direccion de VRAM
	ldir		;5f6c
	push hl			;5f6e   ; Se vuelve detras de los parametros
ROTULO_ENTRADA:		; Siguiente entrada de la lista
	ld hl,(0e150h)		;5f6f   ; Por donde va la lista
	ld a,(hl)			;5f72   ; El byte de la entrada
	cp 080h		;5f73   ; 0x80: direccion nueva
	jr nz,L_5F84		;5f75
	inc hl			;5f77   ; Detras del 0x80 viene la VRAM nueva
	ld e,(hl)			;5f78
	inc hl			;5f79
	ld d,(hl)			;5f7a
	inc hl			;5f7b
	ld (0e150h),hl		;5f7c
	ld (0e154h),de		;5f7f
	ld a,(hl)			;5f83   ; Y se sigue con la entrada que venga despues
L_5F84:
	or a			;5f84
	ret z			;5f85   ; 0: fin
	ld b,a			;5f86   ; B se queda el byte con su bit 7
	and 07fh		;5f87   ; C, la cuenta sin el
	ld c,a			;5f89
	xor a			;5f8a   ; El xor va delante del bit para no pisar el flag que decide relleno o copia
	bit 7,b		;5f8b   ; Bit 7: relleno con un solo tile
	ld b,a			;5f8d
	ld hl,(0e152h)		;5f8e   ; HL los tiles...
	ld de,(0e154h)		;5f91   ; ...y DE la VRAM
	jr z,L_5F9F		;5f95   ; El flag que se mira es el del bit 7, no el del xor de dos instrucciones antes
	ld a,(hl)			;5f97
	call RELLENA_VRAM		;5f98   ; Relleno de C posiciones con el tile (HL)
	ld a,001h		;5f9b   ; El relleno gasta un solo tile de la lista
	jr ROTULO_AVANZA		;5f9d
L_5F9F:
	push bc			;5f9f
	call COPIA_A_VRAM		;5fa0   ; Copia de C tiles
	pop bc			;5fa3
	ld a,c			;5fa4   ; La copia gasta C
ROTULO_AVANZA:		; Avanza los tiles (1 o C) y la VRAM (C)
	ld hl,(0e152h)		;5fa5
	call HL_MAS_A		;5fa8   ; El puntero de tiles avanza 1 o C
	ld (0e152h),hl		;5fab
	ld hl,(0e150h)		;5fae
	ld a,(hl)			;5fb1
	and 07fh		;5fb2   ; La VRAM avanza siempre C, lleve el byte el bit 7 o no
	inc hl			;5fb4   ; Y la lista, una entrada
	ld (0e150h),hl		;5fb5
	ld hl,(0e154h)		;5fb8
	call HL_MAS_A		;5fbb
	ld (0e154h),hl		;5fbe
	jp ROTULO_ENTRADA		;5fc1   ; Y a por la entrada siguiente hasta dar con el 0
RELLENA_CADA_32:		; Escribe B veces (HL) en DE sumando 32 cada vez: las X de una fila de obstaculos
	ld a,(hl)			;5fc4
L_5FC5:
	ld (de),a			;5fc5
	add a,020h		;5fc6   ; 32 puntos de X entre obstaculo y obstaculo: cuatro columnas de tiles
	inc de			;5fc8
	djnz L_5FC5		;5fc9
	ret			;5fcb

; ----------------------------------------------------------------------
; DATOS x_de_obstaculos: Seis X de arranque, a las que 0x5FC4 va sumando 32,
;   para cobrar al pasar: entrando por la izquierda, postes 0x30, trampolines
;   0x48, charcos 0x40; entrando por la derecha, 0x48, 0x48 y 0x30
;   0x5fcc..0x5fd2  (6 bytes)
DATA_x_de_obstaculos:
	defb 030h,048h,040h,048h,048h,030h	; 5fcc

; ======================================================================
; CODIGO 0x5fd2..0x60a4  (210 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LOS CONTADORES. Cada fotograma: E130; y a su ritmo E131 (cada 8),
; E133 (cada 10), E14D (cada 9), E14F (cada 11): las fases de las dos
; lianas y de los cuatro surtidores, que asi no van a la par. Con E131
; sube E17B (la abeja) y con E133 los aranas E17C-E17E; E176-E178
; (los peces) siempre; y bajan los cuatro tiempos de los rotulos de puntos.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
CONTADORES:		; Los contadores de fases y las esperas de los moviles
	ld de,0e17bh		;5fd2   ; DE se queda en la espera de la abeja; HL va recorriendo los contadores
	ld hl,0e130h		;5fd5
	inc (hl)			;5fd8   ; E130 sube un fotograma
	ld a,(hl)			;5fd9
	and 007h		;5fda   ; Cada 8 fotogramas: E131 y la espera de la abeja
	inc hl			;5fdc   ; HL a E131
	jr nz,L_5FE3		;5fdd
	inc (hl)			;5fdf   ; E131, la fase de una liana y de un surtidor
	ex de,hl			;5fe0   ; Y al mismo ritmo E17B, lo que le queda a la abeja para salir
	inc (hl)			;5fe1
	ex de,hl			;5fe2
L_5FE3:
	inc hl			;5fe3   ; E132, el divisor por 10
	inc (hl)			;5fe4
	ld a,(hl)			;5fe5
	cp 00ah		;5fe6   ; Cada 10: E133 y las tres fases de los aranas
	jr nz,L_5FF5		;5fe8
	xor a			;5fea
	ld (hl),a			;5feb   ; A cero, que es un divisor y no un contador libre como E130
	inc hl			;5fec
	inc (hl)			;5fed   ; E133, la fase de la otra liana y del otro surtidor
	ex de,hl			;5fee   ; DE seguia en E17B: E17C, E17D y E17E son las tres aranas
	inc hl			;5fef
	inc (hl)			;5ff0
	inc hl			;5ff1
	inc (hl)			;5ff2
	inc hl			;5ff3
	inc (hl)			;5ff4
L_5FF5:
	ld hl,0e14ch		;5ff5   ; E14C, el divisor por 9
	inc (hl)			;5ff8
	ld a,(hl)			;5ff9
	cp 009h		;5ffa   ; Cada 9: E14D
	jr nz,L_6004		;5ffc
	xor a			;5ffe
	ld (hl),a			;5fff
	inc hl			;6000
	inc (hl)			;6001   ; E14D
	jr L_6005		;6002
L_6004:
	inc hl			;6004   ; Sin dar la vuelta HL tiene que llegar igual a E14E
L_6005:
	inc hl			;6005   ; E14E, el divisor por 11
	inc (hl)			;6006
	ld a,(hl)			;6007
	cp 00bh		;6008   ; Cada 11: E14F
	jr nz,L_6010		;600a
	xor a			;600c
	ld (hl),a			;600d
	inc hl			;600e
	inc (hl)			;600f   ; E14F
L_6010:
	ld hl,0e176h		;6010   ; Las tres esperas de los peces
	inc (hl)			;6013   ; E176, E177 y E178 suben cada fotograma: los peces no llevan divisor
	inc hl			;6014
	inc (hl)			;6015
	inc hl			;6016
	inc (hl)			;6017
	ld b,004h		;6018   ; Los cuatro rotulos de puntos, hacia cero
	ld hl,0e181h		;601a   ; E181-E184, lo que le queda en pantalla a cada rotulo de puntos
L_601D:
	ld a,(hl)			;601d
	or a			;601e   ; Se para en cero: sin esto daria la vuelta a 0xFF
	jr z,L_6022		;601f
	dec (hl)			;6021
L_6022:
	inc hl			;6022
	djnz L_601D		;6023
	ret			;6025
LIANAS:		; Bit 1 de E156: pinta las dos lianas en su fase (E131 y E133) y guarda donde esta el cabo de cada una (E140-E143)
	ld a,(0e156h)		;6026
	and 002h		;6029   ; Bit 1
	ret z			;602b
	ld de,038cah		;602c   ; Liana 1 en la fila 6, columna 10
	ld a,(0e131h)		;602f   ; Su fase es la del divisor de 8
	call PINTA_LIANA		;6032   ; Devuelve en B, C y D los tres bytes que van detras del 0xFF del dibujo
	ld hl,0e140h		;6035   ; E140 la Y del cabo y E141 una de sus dos X
	ld (hl),b			;6038
	inc hl			;6039
	ld (hl),c			;603a
	ld de,038d6h		;603b   ; Liana 2 en la columna 22, doce columnas mas alla
	ld a,(0e133h)		;603e   ; La otra va con el de 10: asi las dos lianas nunca se balancean a la vez
	call PINTA_LIANA		;6041
	ld hl,0e142h		;6044   ; E142 la Y, y E143 la OTRA X que devuelve el dibujo (D, no C)
	ld (hl),b			;6047
	inc hl			;6048
	ld (hl),d			;6049
	ret			;604a
SURTIDORES:		; Bit 3: pinta las cuatro tablas de los surtidores en su fase (fila 10, columnas 8, 12, 17, 21) y guarda la altura de cada una en E148-E14B; y el borde de agua de la fila 16
	ld a,(0e156h)		;604b
	and 008h		;604e   ; Bit 3
	ret z			;6050
	ld de,03948h		;6051   ; Fila 10, columna 8: la tabla de mas a la izquierda
	ld a,(0e131h)		;6054   ; Su fase es la misma que la de una de las lianas
	call PINTA_SURTIDOR		;6057
	ld (0e148h),a		;605a   ; E148, la altura de la tabla de la izquierda: por ahi se anda por encima
	ld de,03951h		;605d   ; Fila 10, columna 17
	ld a,(0e14dh)		;6060
	call PINTA_SURTIDOR		;6063
	ld (0e14ah),a		;6066
	ld de,0394ch		;6069   ; Fila 10, columna 12
	ld a,(0e133h)		;606c
	call PINTA_SURTIDOR		;606f
	ld (0e149h),a		;6072
	ld de,03955h		;6075   ; Fila 10, columna 21
	ld a,(0e14fh)		;6078
	call PINTA_SURTIDOR		;607b
	ld (0e14bh),a		;607e   ; E148-E14B quedan de izquierda a derecha, no en el orden en que se pintan
	ld hl,060a4h		;6081   ; El agua de la fila 16, columnas 8-24
	call PINTA_LISTA		;6084
	ld a,0cbh		;6087   ; Las bases de los cuatro chorros en la fila 17 (columnas 9, 13, 18 y 22)
	ld de,03a29h		;6089   ; Fila 17, columna 9
	call VPOKE		;608c
	ld de,03a36h		;608f   ; Y columna 22: los dos de fuera llevan el mismo tile 0xCB
	call VPOKE		;6092
	ld a,0cch		;6095   ; Los dos de dentro, el 0xCC
	ld de,03a2dh		;6097
	call VPOKE		;609a
	ld de,03a32h		;609d
	call VPOKE		;60a0
	ret			;60a3

; ----------------------------------------------------------------------
; DATOS agua_surtidores: Lista de rotulo: 17 tiles de agua en la fila 16 desde
;   la columna 8
;   0x60a4..0x60b7  (19 bytes)
DATA_agua_surtidores:
	defb 008h,03ah,007h,0cdh,0c6h,0c6h,0c7h,0ceh,0c7h,0c7h,0c7h,0c7h,0ceh,0c7h,0c6h,0c6h	; 60a4  .:..............
	defb 0cdh,007h,0ffh	; 60b4

; ======================================================================
; CODIGO 0x60b7..0x62d4  (541 bytes)
; ======================================================================


PINTA_SURTIDOR:		; Bloque de 6x3 de la fase A (0..31: sube hasta la 17 y baja) en la VRAM DE; devuelve en A la altura de la tabla
	and 01fh		;60b7   ; La fase, 0..31
	cp 012h		;60b9   ; De la 18 a la 31 se repite hacia atras: la tabla sube y baja
	jr c,L_60C2		;60bb
	neg		;60bd   ; 33 menos A: de la 18 a la 31 se recorren los dibujos 15 a 2, y la tabla parece bajar
	inc a			;60bf
	and 01fh		;60c0
L_60C2:
	ld hl,056ddh		;60c2   ; Tabla de 18 bloques
	rlca			;60c5   ; Por dos: la tabla es de palabras
	call HL_MAS_A		;60c6
	push de			;60c9   ; La VRAM se guarda mientras se saca el puntero al bloque
	ld e,(hl)			;60ca
	inc hl			;60cb
	ld d,(hl)			;60cc
	ex de,hl			;60cd   ; El bloque a HL y la VRAM otra vez a DE
	pop de			;60ce
	ld bc,00603h		;60cf   ; Seis filas por tres columnas, 18 bytes
	call PINTA_BLOQUE		;60d2   ; Y HL queda justo detras de los 18
	ld a,(hl)			;60d5   ; El byte 19 de cada bloque: la altura de la tabla
	ret			;60d6
PINTA_LIANA:		; La liana en la fase A (0..15: 9 dibujos, del 9 en adelante hacia atras) desde DE; devuelve B=Y y C, D = las dos X del cabo
	and 00fh		;60d7   ; La fase, 0..15
	cp 009h		;60d9   ; Del 9 al 15 se repite hacia atras: la liana va y vuelve
	jr c,L_60E1		;60db
	neg		;60dd   ; 16 menos A: del 9 al 15 se repiten los dibujos 7 a 1
	and 00fh		;60df
L_60E1:
	ld hl,0555bh		;60e1   ; Tabla de 9 dibujos
	rlca			;60e4   ; Por dos: palabras otra vez
	call HL_MAS_A		;60e5
	push de			;60e8
	ld e,(hl)			;60e9
	inc hl			;60ea
	ld d,(hl)			;60eb
	ex de,hl			;60ec
	pop de			;60ed
PINTA_DIBUJO:		; Un dibujo de tiles: 0xFF fin, 0xFE/0xFD/0xFC bajan una fila (una columna a la izquierda, la misma, una a la derecha), lo demas tiles
	push de			;60ee   ; La DE del principio de la fila, que hara falta al bajar
PINTA_DIBUJO_BUCLE:		; Siguiente byte
	ld a,(hl)			;60ef
	inc hl			;60f0
	ld b,a			;60f1   ; Los cuatro codigos se prueban sumando uno cada vez
	inc b			;60f2
	jr z,PINTA_DIBUJO_FIN		;60f3   ; 0xFF: fin, y detras vienen Y, X1 y X2 del cabo
	inc b			;60f5
	jr nz,L_6100		;60f6
	ld a,01fh		;60f8   ; 0xFE: fila siguiente, una columna a la izquierda
L_60FA:
	pop de			;60fa   ; Vuelve al principio de la fila...
	call DE_MAS_A		;60fb   ; ...y baja 32, mas o menos una columna
	jr PINTA_DIBUJO		;60fe   ; Otra vez por el push: la fila nueva pasa a ser el origen
L_6100:
	inc b			;6100
	jr nz,L_6107		;6101
	ld a,020h		;6103   ; 0xFD: fila siguiente, misma columna
	jr L_60FA		;6105
L_6107:
	inc b			;6107
	jr nz,L_610E		;6108
	ld a,021h		;610a   ; 0xFC: fila siguiente, una a la derecha
	jr L_60FA		;610c
L_610E:
	call VPOKE		;610e   ; Lo que no sea codigo es un tile
	inc de			;6111   ; Y a la columna de al lado
	jr PINTA_DIBUJO_BUCLE		;6112
PINTA_DIBUJO_FIN:		; B, C, D = los tres bytes de detras del 0xFF
	pop de			;6114
	ld b,(hl)			;6115   ; Y, X1 y X2: donde ha quedado el cabo de la liana
	inc hl			;6116
	ld c,(hl)			;6117
	inc hl			;6118
	ld d,(hl)			;6119
	ret			;611a

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LAS BOLAS QUE RUEDAN. Una (sprite 14) y, de la fase 3 en adelante,
; otra (sprite 15) cada 32 o 64 fotogramas. Ruedan siempre hacia la
; izquierda a un punto por fotograma, dando botes con el arco que eligio
; 5B5C (alto 0x63A5, casi plano 0x63B7 o medio 0x6CE3). Al acabar el arco
; vuelven a Y=0x7E (el suelo) con el sonido 8. 50 puntos por pasarlas.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
BOLAS_QUE_RUEDAN:		; Bits 0-2 de E159: mueve la bola (y la segunda si toca)
	ld a,(0e159h)		;611b
	and 007h		;611e   ; Bits 0-2 de E159, la copia de los moviles que solo miran las bolas
	ret z			;6120
	ld a,(0e164h)		;6121   ; E164, por que mitad del arco va
	ld b,a			;6124
	ld de,(0e160h)		;6125   ; E160, en que paso
	ld hl,0e0e8h		;6129   ; E0E8 es el sprite 14
	ld c,001h		;612c   ; Bit 0 de C y nada mas: mueve tambien la X, y sin el bit 7 siempre hacia la izquierda, entre por donde entre el jugador
	call PASO_DE_ARCO		;612e   ; Un paso por el arco: Y y X-1
	ld (0e160h),hl		;6131   ; Por donde ha quedado, para el fotograma que viene
	ld (0e164h),a		;6134
	ld a,(0e0e9h)		;6137   ; E1AC, la X con la que se cobra
	ld (0e1ach),a		;613a
	cp 0ffh		;613d   ; Aun sin X: aparece
	jr nz,L_6146		;613f
	ld a,005h		;6141   ; Vuelve a valer 50: cada pasada de la bola se cobra otra vez
	ld (0e19ch),a		;6143
L_6146:
	bit 0,b		;6146   ; El bit 0 de B llega a 1 al acabarse el arco
	jr z,L_6150		;6148
	ld hl,0e0e8h		;614a   ; Otra vez el sprite 14
	call BOLA_ARRANCA		;614d
L_6150:
	ld a,(0e051h)		;6150   ; La segunda bola solo de la fase 3 en adelante
	cp 003h		;6153
	ret c			;6155
	ld hl,0e187h		;6156   ; E187, los fotogramas que lleva la pantalla
	inc (hl)			;6159
	ld b,040h		;615a   ; Espera 64 fotogramas antes de arrancar (32 si la fase no tiene el bit 2: 3, 8-11...); luego siempre
	bit 2,a		;615c   ; A sigue siendo la fase
	jr nz,L_6162		;615e
	ld b,020h		;6160   ; 32 fotogramas
L_6162:
	ld a,(hl)			;6162   ; E188 a 1 el fotograma justo; a partir de ahi la segunda bola ya no vuelve a esperar
	inc hl			;6163
	cp b			;6164
	jr nz,L_6169		;6165
	ld (hl),001h		;6167
L_6169:
	ld a,(hl)			;6169   ; Sin ese 1 no hay segunda bola
	and 001h		;616a
	ret z			;616c
	ld a,(0e165h)		;616d   ; E165 y E162, el sentido y el paso de la segunda
	ld b,a			;6170
	ld de,(0e162h)		;6171
	ld hl,0e0ech		;6175   ; E0EC es el sprite 15
	ld c,001h		;6178
	call PASO_DE_ARCO		;617a
	ld (0e162h),hl		;617d
	ld (0e165h),a		;6180
	ld a,(0e0edh)		;6183   ; E1AD, su X de cobro
	ld (0e1adh),a		;6186
	cp 0ffh		;6189
	jr nz,L_6192		;618b
	ld a,005h		;618d   ; E19D, sus otros 50
	ld (0e19dh),a		;618f
L_6192:
	bit 0,b		;6192   ; Y aqui se cae en BOLA_ARRANCA sin llamarla
	ret z			;6194
	ld hl,0e0ech		;6195
BOLA_ARRANCA:		; Y=0x7E, patron 0xC4 (la bola grande), rojo, sonido 8
	ld (hl),07eh		;6198   ; Y=0x7E, rodando por el suelo
	inc hl			;619a   ; La X no se toca: la bola sigue por donde iba
	inc hl			;619b
	ld (hl),0c4h		;619c   ; Patron 0xC4
	inc hl			;619e
	ld (hl),008h		;619f   ; Color 8, rojo
	ld a,008h		;61a1   ; Sonido 8 cada vez que la bola vuelve al suelo
	jp SONIDO		;61a3

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; UN PASO POR UN ARCO. DE apunta a una tabla de deltas entre 0xFE y
; 0xFF; B bit 0 dice el sentido: a 0 se recorre hacia delante RESTANDO
; (subiendo, cada vez menos), a 1 hacia atras SUMANDO (bajando, cada
; vez mas). Al tocar 0xFF se da la vuelta; al volver al 0xFE devuelve
; B=1: se acabo el salto. C: bit 0 tambien mueve la X (1 a 3 puntos
; segun sus bits 1-2, hacia el lado que diga E058 si el bit 7 esta a 1,
; y si no siempre a la izquierda).
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
ARCO_X_DERECHA:		; X + 1..3 (bits 1-2 de C)
	bit 7,c		;61a6   ; Sin el bit 7 de C, a la izquierda pase lo que pase
	jr z,ARCO_X_IZQUIERDA		;61a8
	bit 1,c		;61aa   ; Sin el bit 1, un solo punto
	jr z,L_61B4		;61ac
	bit 2,c		;61ae   ; Con el bit 2, tres
	jr z,L_61B3		;61b0
	inc (hl)			;61b2   ; Tres
L_61B3:
	inc (hl)			;61b3   ; Dos
L_61B4:
	inc (hl)			;61b4   ; Uno, siempre
	jr ARCO_AVANZA		;61b5
PASO_DE_ARCO:		; (HL) += o -= (DE) segun B; opcionalmente X; avanza DE; A = sentido nuevo, B = 1 al terminar
	bit 0,b		;61b7   ; El sentido: a 0 se resta y se sube, a 1 se suma y se baja
	ld a,(de)			;61b9   ; El delta de este paso; DE apunta al que toca, no al siguiente
	jr nz,L_61BE		;61ba
	neg		;61bc   ; Sentido 0: resta (sube)
L_61BE:
	add a,(hl)			;61be   ; La Y, mas o menos el delta
	ld (hl),a			;61bf
	bit 0,c		;61c0   ; Bit 0 de C: mover tambien la X
	jr z,ARCO_AVANZA		;61c2
	inc hl			;61c4   ; Ahora (HL) es la X
	ld a,(0e058h)		;61c5
	cp 008h		;61c8   ; Con el bit 7 de C, hacia el lado por el que se entro
	jr nz,ARCO_X_DERECHA		;61ca
ARCO_X_IZQUIERDA:		; X - 1..3
	bit 1,c		;61cc   ; Lo mismo restando
	jr z,L_61D6		;61ce
	bit 2,c		;61d0
	jr z,L_61D5		;61d2
	dec (hl)			;61d4
L_61D5:
	dec (hl)			;61d5
L_61D6:
	dec (hl)			;61d6
ARCO_AVANZA:		; Puntero adelante o atras; en 0xFF da la vuelta; en 0xFE devuelve B=1
	ex de,hl			;61d7   ; Y ahora HL es el puntero del arco
	bit 0,b		;61d8
	jr nz,L_61DF		;61da
	inc hl			;61dc   ; Subiendo se avanza...
	jr L_61E0		;61dd
L_61DF:
	dec hl			;61df   ; ...y bajando se vuelve
L_61E0:
	ld a,(hl)			;61e0   ; 0xFF cierra la tabla por arriba
	inc a			;61e1
	jr nz,ARCO_MARCA_FE		;61e2
	dec hl			;61e4   ; 0xFF: dos atras y a bajar
	dec hl			;61e5   ; Dos atras y no una: el delta de la cima ya se ha usado y no se repite al bajar
	inc a			;61e6
ARCO_SIGUE:		; B = 0: sigue
	ld b,000h		;61e7   ; B a 0: aun queda arco
	ret			;61e9
ARCO_MARCA_FE:		; 0xFE: se acabo el arco (B=1) y el sentido vuelve a 0
	inc a			;61ea   ; Y un 0xFE la cierra por abajo; como las tablas van pegadas, el 0xFE de una es el byte de detras del 0xFF de la anterior
	ld a,b			;61eb   ; Sin llegar al 0xFE el sentido no cambia
	jr nz,ARCO_SIGUE		;61ec
	inc hl			;61ee   ; El puntero se deja en el primer delta, listo para el salto siguiente
	xor a			;61ef   ; Sentido 0: el arco que venga vuelve a subir
	ld b,001h		;61f0   ; B a 1: quien llamo se entera de que el salto se ha acabado
	ret			;61f2

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LOS PECES. Bit 4 de E158 y charcos o estanque: tres peces (sprites
; 11-13) que saltan uno tras otro cuando su espera (E176-E178) llega a
; 0x1F, con el arco de salto 0x63C9 (el mismo del jugador), y al caer
; vuelven a salir por una X al azar de las de los charcos (0x62D4),
; Y=0x8C, con el sonido 7. Tres dibujos: subiendo, bajando y arriba
; del todo. El arco sube 96 puntos en 26 pasos y baja los mismos en
; 25: 51 fotogramas de salto que devuelven la Y a donde estaba.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
PECES:		; Los tres peces que saltan de los charcos o del estanque
	ld a,(0e158h)		;61f3   ; Bit 4 de E158: esta pantalla lleva peces
	and 010h		;61f6
	ret z			;61f8
	ld a,(0e156h)		;61f9   ; Y bits 0 o 7 de E156: hacen falta charcos o estanque de donde salir
	and 081h		;61fc
	ret z			;61fe
	ld a,(0e176h)		;61ff   ; E176, la espera del primer pez
	cp 01fh		;6202   ; Espera cumplida
	jr c,PEZ_2		;6204
	ld a,(0e16fh)		;6206   ; E16F el sentido (0 subiendo, 1 bajando) y E169 el puntero dentro de la tabla del arco
	ld b,a			;6209
	ld de,(0e169h)		;620a
	ld hl,0e0dch		;620e   ; E0DC es el sprite 11
	ld c,000h		;6211   ; C=0: el arco solo mueve la Y, el pez sube y baja a plomo
	call PASO_DE_ARCO		;6213
	ld (0e169h),hl		;6216   ; E169 se queda con el puntero ya avanzado
	ld (0e16fh),a		;6219   ; y E16F con el sentido nuevo
	bit 0,b		;621c   ; Se acabo el salto: otro desde el agua
	jr z,L_6229		;621e
	ld hl,0e176h		;6220   ; HL la espera y DE el sprite, que es como los quiere PEZ_SALTA
	ld de,0e0dch		;6223
	call PEZ_SALTA		;6226
L_6229:
	or a			;6229   ; Patron: 0xB8 subiendo, 0xBC bajando...
	ld b,0b8h		;622a
	jr z,L_6230		;622c
	ld b,0bch		;622e   ; 0xBC, el pez de cabeza
L_6230:
	ld a,(0e0dch)		;6230
	cp 034h		;6233   ; ...y 0xC0 por encima de Y=0x34
	jr nc,L_6239		;6235
	ld b,0c0h		;6237   ; 0xC0, el pez estirado: el arco sube 96 puntos, o sea de 0x8C a 0x2C
L_6239:
	ld hl,0e0deh		;6239   ; E0DE, el byte del patron del sprite
	ld (hl),b			;623c
PEZ_2:		; El segundo pez (sprite 12)
	ld a,(0e177h)		;623d   ; E177, la espera del segundo
	cp 01fh		;6240   ; El mismo 0x1F: los tres peces llevan la espera igual
	jr c,PEZ_3		;6242
	ld a,(0e170h)		;6244   ; E170 el sentido y E16B el puntero del segundo
	ld b,a			;6247
	ld de,(0e16bh)		;6248
	ld hl,0e0e0h		;624c   ; E0E0 es el sprite 12
	ld c,000h		;624f   ; Tambien a plomo
	call PASO_DE_ARCO		;6251
	ld (0e16bh),hl		;6254
	ld (0e170h),a		;6257
	bit 0,b		;625a   ; Se acabo el salto: otro desde el agua
	jr z,L_6267		;625c
	ld hl,0e177h		;625e
	ld de,0e0e0h		;6261
	call PEZ_SALTA		;6264
L_6267:
	or a			;6267   ; El sentido que ha devuelto el arco: 0 subiendo, 0xB8
	ld b,0b8h		;6268
	jr z,L_626E		;626a
	ld b,0bch		;626c   ; Bajando, 0xBC
L_626E:
	ld a,(0e0e0h)		;626e
	cp 034h		;6271   ; Por encima de Y=0x34 manda el patron de arriba
	jr nc,L_6277		;6273
	ld b,0c0h		;6275   ; 0xC0
L_6277:
	ld hl,0e0e2h		;6277   ; Su patron
	ld (hl),b			;627a
PEZ_3:		; El tercero (sprite 13)
	ld a,(0e178h)		;627b   ; E178, la del tercero
	cp 01fh		;627e   ; Y la misma cuenta
	ret c			;6280
	ld a,(0e171h)		;6281   ; E171 el sentido y E16D el puntero del tercero
	ld b,a			;6284
	ld de,(0e16dh)		;6285
	ld hl,0e0e4h		;6289   ; E0E4 es el sprite 13
	ld c,000h		;628c   ; El tercero tampoco se mueve de columna
	call PASO_DE_ARCO		;628e
	ld (0e16dh),hl		;6291
	ld (0e171h),a		;6294
	bit 0,b		;6297   ; Fin del arco
	jr z,L_62A4		;6299
	ld hl,0e178h		;629b
	ld de,0e0e4h		;629e
	call PEZ_SALTA		;62a1
L_62A4:
	or a			;62a4   ; Subiendo
	ld b,0b8h		;62a5
	jr z,L_62AB		;62a7
	ld b,0bch		;62a9   ; Bajando
L_62AB:
	ld a,(0e0e4h)		;62ab
	cp 034h		;62ae   ; La misma altura para los tres
	jr nc,L_62B4		;62b0
	ld b,0c0h		;62b2   ; Arriba del todo
L_62B4:
	ld hl,0e0e6h		;62b4   ; Y su patron
	ld (hl),b			;62b7
	ret			;62b8
PEZ_SALTA:		; Espera a cero, Y=0x8C, X al azar de la tabla, rojo claro y sonido 7
	ld (hl),000h		;62b9   ; La espera vuelve a cero
	ex de,hl			;62bb   ; DE traia el sprite; ahora HL escribe sus cuatro bytes
	ld (hl),08ch		;62bc   ; Y=0x8C: asomando por el agua
	inc hl			;62be
	ld de,062d4h		;62bf   ; La tabla de ocho X de 0x62D4
	ld a,r		;62c2   ; El registro de refresco hace de azar: una de las ocho X
	and 007h		;62c4   ; Los tres bits bajos de R: una de las ocho
	call DE_MAS_A		;62c6
	ld a,(de)			;62c9
	ld (hl),a			;62ca
	inc hl			;62cb   ; Dos adelante: el patron se lo pone el que llamo, al volver
	inc hl			;62cc
	ld (hl),009h		;62cd   ; El cuarto byte del sprite, el color
	ld a,007h		;62cf   ; Sonido 7 cada vez que un pez sale del agua
	jp SONIDO		;62d1

; ----------------------------------------------------------------------
; DATOS x_de_los_peces: Ocho X por donde puede saltar un pez: 0x38, 0x58,
;   0x58, 0x78, 0x78, 0x98, 0x98, 0xB8 (las de los charcos, con las de en
;   medio dobles)
;   0x62d4..0x62dc  (8 bytes)
DATA_x_de_los_peces:
	defb 038h,058h,058h,078h,078h,098h,098h,0b8h	; 62d4  8XXxx...

; ======================================================================
; CODIGO 0x62dc..0x63a4  (200 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LA BOLA QUE BOTA (sprite 22). Bit 6 de E158, un fotograma de cada
; dos: cruza la pantalla botando (arco 0x63C9) desde el lado contrario al
; del jugador, avanzando 1 a 3 puntos por fotograma al azar (E172).
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
BOLA_QUE_BOTA:		; La bola pequena que viene botando por el aire
	ld a,(0e158h)		;62dc   ; Bit 6 de E158: esta pantalla lleva bola que bota
	and 040h		;62df
	ret z			;62e1
	ld hl,0e003h		;62e2
	bit 0,(hl)		;62e5   ; Fotogramas impares
	ret z			;62e7
	ld a,(0e175h)		;62e8   ; E175 el sentido y E173 el puntero, los dos del arco 0x63C9
	ld b,a			;62eb
	ld de,(0e173h)		;62ec
	ld hl,0e108h		;62f0   ; E108 es el sprite 22
	ld a,(0e172h)		;62f3   ; E172, el azar de la vuelta anterior: sus bits 1-2 dicen si la X corre 1, 2 o 3 puntos por paso
	ld c,a			;62f6
	set 7,c		;62f7   ; Bit 7 de C: la X va hacia el lado por el que entro el jugador
	call PASO_DE_ARCO		;62f9
	ld (0e173h),hl		;62fc   ; El puntero avanzado y el sentido nuevo
	ld (0e175h),a		;62ff
	ld hl,0e10ah		;6302   ; E10A y E10B, el patron y el color del sprite 22
	ld (hl),0c8h		;6305   ; Patron 0xC8, rojo oscuro
	inc hl			;6307
	ld (hl),006h		;6308
	bit 0,b		;630a   ; Bit 0 de B: el arco se ha acabado
	ret z			;630c
	ld a,r		;630d   ; Al acabar el arco: nuevo azar y otra vez desde el lado de enfrente, sonido 4
	ld (0e172h),a		;630f
	ld a,(0e058h)		;6312   ; Entrando el jugador por la izquierda (E058=8) la bola cruza de derecha a izquierda: reaparece en X=0xD0
	cp 008h		;6315
	ld a,0d0h		;6317
	jr z,L_631D		;6319
	ld a,020h		;631b   ; Y al reves, en X=0x20
L_631D:
	ld hl,0e109h		;631d   ; E109, la X del sprite 22
	ld (hl),a			;6320
	ld a,004h		;6321   ; Sonido 4: la bola vuelve a entrar
	jp SONIDO		;6323

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LAS ARANAS (redondas con ocho patas, sprite 51). Bit 3 de E158: tres
; (sprites 16-18) en X=0x58, 0x78 y 0x98. Su fase (E17C-E17E) sube cada
; 10 fotogramas: en la 8 aparecen arriba (Y=0x28) y se balancean diez
; puntos a cada lado; de la 15 en adelante caen dos puntos por fotograma
; hasta el suelo (0x8C) y vuelven a la fase 0. Blancas, patron 0xCC.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
ARANAS:		; Las tres aranas que se descuelgan de arriba
	ld a,(0e158h)		;6326   ; Bit 3 de E158: esta pantalla lleva aranas
	and 008h		;6329
	ret z			;632b
	ld hl,0e0f0h		;632c   ; E0F0 es el sprite 16, el primero de los tres
	ld a,(0e17ch)		;632f
	cp 008h		;6332   ; Fase 8: aparece
	jr z,L_6346		;6334
	call ARANA_MUEVE		;6336   ; Hasta la fase 14 se balancea; de la 15 en adelante cae
	jr c,ARANA_2		;6339   ; Sigue en el aire
	xor a			;633b   ; Toco el suelo: fase 0 y la arana aparcada abajo
	ld (0e17ch),a		;633c
	ld a,090h		;633f   ; Y=0x90, cuatro por debajo del suelo: no es el 0xC3 con el que ESCONDE_OBSTACULOS saca los sprites de la pantalla, pero ahi ya no alcanza al jugador de pie (0x6C+8 = 0x74)
	ld (0e0f0h),a		;6341
	jr ARANA_2		;6344
L_6346:
	ld a,058h		;6346   ; X=0x58: la primera, la de la izquierda
	call ARANA_APARECE		;6348
ARANA_2:		; La segunda (sprite 17, X=0x78)
	ld hl,0e0f4h		;634b   ; E0F4 es el sprite 17
	ld a,(0e17dh)		;634e   ; E17D, la fase de la segunda
	cp 008h		;6351   ; La segunda tambien aparece en la fase 8
	jr z,L_6365		;6353
	call ARANA_MUEVE		;6355   ; Y se mueve igual
	jr c,ARANA_3		;6358
	xor a			;635a   ; Al tocar el suelo: fase 0 y escondida en Y=0x90
	ld (0e17dh),a		;635b
	ld a,090h		;635e
	ld (0e0f4h),a		;6360
	jr ARANA_3		;6363
L_6365:
	ld a,078h		;6365   ; X=0x78: la de en medio
	call ARANA_APARECE		;6367
ARANA_3:		; La tercera (sprite 18, X=0x98)
	ld hl,0e0f8h		;636a   ; E0F8 es el sprite 18
	ld a,(0e17eh)		;636d   ; E17E, la de la tercera
	cp 008h		;6370
	jr z,ARANA_APARECE_3		;6372
	call ARANA_MUEVE		;6374
	ret c			;6377   ; Acarreo: sigue en el aire, y con la tercera se acaba la rutina
	xor a			;6378
	ld (0e17eh),a		;6379
	ld a,090h		;637c   ; La tercera queda igual, en Y=0x90
	ld (0e0f8h),a		;637e
	ret			;6381
ARANA_APARECE_3:		; Y=0x28, X=0x98
	ld a,098h		;6382   ; X=0x98: la de la derecha
ARANA_APARECE:		; Y=0x28, X=A, patron 0xCC, blanca
	ld (hl),028h		;6384   ; Y=0x28: cuelga desde arriba del todo
	inc hl			;6386
	ld (hl),a			;6387   ; La X que trae A; mientras la fase valga 8 se vuelve a clavar aqui, diez fotogramas seguidos
	inc hl			;6388
	ld (hl),0cch		;6389   ; Patron 0xCC, color 15 (blanco)
	inc hl			;638b
	ld (hl),00fh		;638c
	ret			;638e
ARANA_MUEVE:		; Fase < 15: se balancea (X+1 o X-1 segun el bit 0 de la fase, acarreo); si no cae 2 y devuelve acarreo mientras no llegue a 0x8C
	cp 00fh		;638f   ; Por debajo de la fase 15 solo se balancea colgada
	jr c,L_6399		;6391
	inc (hl)			;6393   ; Baja dos puntos por fotograma
	inc (hl)			;6394
	ld a,(hl)			;6395
	cp 08ch		;6396   ; Acarreo mientras no llegue al suelo (Y=0x8C)
	ret			;6398
L_6399:
	inc hl			;6399   ; HL a la X del sprite
	bit 0,a		;639a   ; Fase impar a la derecha, par a la izquierda
	jr z,L_63A1		;639c
	inc (hl)			;639e   ; Un punto por fotograma y diez fotogramas por fase: diez puntos a cada lado
	scf			;639f
	ret			;63a0
L_63A1:
	dec (hl)			;63a1   ; Fase par, un punto a la izquierda
	scf			;63a2   ; Acarreo: la arana sigue colgada
	ret			;63a3

; ----------------------------------------------------------------------
; DATOS arco_alto: El arco de salto alto (0xFE ... 0xFF): 6 5 5 5 4 4 3 3 3 3
;   2 2 2 1 0 0. Lo usa la bola que rueda cuando el bit 0 de E158 esta a 1
;   0x63a4..0x63b6  (18 bytes)
DATA_arco_alto:
	defb 0feh,006h,005h,005h,005h,004h,004h,003h,003h,003h,003h,002h,002h,002h,001h,000h	; 63a4  ................
	defb 000h,0ffh	; 63b4

; ----------------------------------------------------------------------
; DATOS arco_plano: El arco casi plano: 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 0. La
;   bola que rueda por defecto
;   0x63b6..0x63c8  (18 bytes)
DATA_arco_plano:
	defb 0feh,000h,000h,000h,001h,000h,000h,000h,001h,000h,000h,000h,001h,000h,000h,000h	; 63b6  ................
	defb 000h,0ffh	; 63c6

; ----------------------------------------------------------------------
; DATOS arco_de_salto: El arco del jugador (0x682A), de la bola que bota y de
;   los tres peces (0x5B7D): 8 8 8 8 8 8 7 7 5 5 4 4 3 3 2 1 1 1 1 1 1 1 1 0
;   0, que suman 96 puntos de subida
;   0x63c8..0x63e4  (28 bytes)
DATA_arco_de_salto:
	defb 0feh,000h,008h,008h,008h,008h,008h,008h,007h,007h,005h,005h,004h,004h,003h,003h	; 63c8  ................
	defb 002h,001h,001h,001h,001h,001h,001h,001h,001h,000h,000h,0ffh	; 63d8  ............

; ======================================================================
; CODIGO 0x63e4..0x6409  (37 bytes)
; ======================================================================


HOGUERA:		; Bit 6 de E156: la hoguera de 2x2 en la fila 16, columna 26 o 4, con las llamas cambiando cada 11 fotogramas (bit 0 de E14F)
	ld a,(0e156h)		;63e4   ; Bit 6 de E156: esta pantalla lleva hoguera
	and 040h		;63e7
	ret z			;63e9
	ld a,(0e14fh)		;63ea   ; E14F sube cada 11 fotogramas (0x600F)
	bit 0,a		;63ed
	ld hl,06409h		;63ef   ; Con el bit 0 puesto, los cuatro tiles de las llamas altas
	jr nz,L_63F7		;63f2
	ld hl,0640dh		;63f4   ; Y sin el, los de las bajas: la hoguera cambia de dibujo cada 11 fotogramas
L_63F7:
	ld de,03a1ah		;63f7   ; 0x3A1A es la tabla de nombres (0x3800) mas 538: fila 16, columna 26
	ld a,(0e058h)		;63fa
	cp 008h		;63fd
	jr z,L_6404		;63ff
	ld de,03a04h		;6401   ; Entrando por la derecha, 0x3A04: fila 16, columna 4; la hoguera se pinta siempre al fondo del camino
L_6404:
	ld bc,00202h		;6404   ; Dos filas por dos columnas
	jr $+10		;6407   ; jr $+10 es 0x6411: se cae en PINTA_BLOQUE saltando por encima de los ocho bytes de tiles

; ----------------------------------------------------------------------
; DATOS hoguera_a: Los cuatro tiles de la hoguera, llamas altas: 0xE6 0xE7 /
;   0xE8 0xE9
;   0x6409..0x640d  (4 bytes)
DATA_hoguera_a:
	defb 0e6h,0e7h	; 6409
	defb 0e8h,0e9h	; 640b

; ----------------------------------------------------------------------
; DATOS hoguera_b: Llamas bajas: 0xEA 0xEB / 0xE8 0xE9
;   0x640d..0x6411  (4 bytes)
DATA_hoguera_b:
	defb 0eah,0ebh	; 640d
	defb 0e8h,0e9h	; 640f

; ======================================================================
; CODIGO 0x6411..0x64a4  (147 bytes)
; ======================================================================


PINTA_BLOQUE:		; Bloque de B filas por C columnas de tiles desde HL en la VRAM DE
	push bc			;6411   ; Las dos cuentas y el principio de la fila, a la pila
	push de			;6412   ; DE, para volver luego al principio de esta fila
PINTA_BLOQUE_FILA:		; Una fila
	ld a,(hl)			;6413   ; Un tile
	call VPOKE		;6414   ; VPOKE devuelve DE como estaba (res 6,d en 0x4070): se puede seguir contando con el
	inc hl			;6417
	inc de			;6418
	dec c			;6419   ; C columnas
	jr nz,PINTA_BLOQUE_FILA		;641a
	pop de			;641c   ; Otra vez el principio de la fila
	ld a,020h		;641d   ; Mas 32: la fila de abajo
	call DE_MAS_A		;641f
	pop bc			;6422   ; La pila devuelve tambien C, la anchura, para la fila siguiente
	djnz PINTA_BLOQUE		;6423
	ret			;6425

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LA ABEJA (sprites 20 y 21, amarillo y negro). Bit 7 de E158: cuando su
; espera E17B llega a 8 sale arriba a la derecha (Y=0x28, X=0xD8) con el
; sonido 5, baja dos puntos por fotograma hasta la altura E179 (una de
; cuatro, al azar salvo en la fase 2) y vuela hacia la izquierda a dos
; puntos por fotograma; al salir por X<8 se esconde (sonido 6) y a
; esperar. 100 puntos por pasarla.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
ABEJA:		; La abeja
	ld a,(0e158h)		;6426   ; Bit 7 de E158: esta pantalla lleva abeja
	and 080h		;6429
	ret z			;642b
	ld hl,0e100h		;642c   ; E100 es el sprite 20
	ld a,(0e17bh)		;642f
	cp 008h		;6432   ; Espera cumplida: aparece
	jr z,ABEJA_APARECE		;6434
	call ABEJA_MUEVE		;6436   ; Sin acarreo aun esta dentro: a pintarla
	jr nc,ABEJA_SPRITES		;6439
	ld a,006h		;643b   ; Se fue por la izquierda: sonido 6, escondida (Y=0xC8) y altura nueva
	call SONIDO		;643d
	xor a			;6440
	ld (0e17bh),a		;6441   ; La espera vuelve a cero; E17B sube cada 8 fotogramas (0x5FDF), asi que hasta la salida siguiente pasan 64
	ld a,0c8h		;6444
	ld (0e100h),a		;6446
	ld a,(0e051h)		;6449   ; La fase, en BCD
	cp 002h		;644c   ; En la fase 2 siempre baja al primer nivel
	ld a,000h		;644e
	jr z,L_6456		;6450
	ld a,r		;6452   ; El registro de refresco: una de las cuatro alturas al azar
	and 003h		;6454
L_6456:
	ld (0e179h),a		;6456   ; E179, la altura de la pasada siguiente
ABEJA_SPRITES:		; El sprite 21 copia Y y X del 20; patrones 0xD8 amarillo y 0xDC negro
	ld hl,0e100h		;6459   ; E100 es el sprite 20 y E104 el 21: el mismo bicho en dos colores
	ld de,0e104h		;645c
	ld a,(hl)			;645f   ; La Y del 20 al 21
	ld (de),a			;6460
	inc hl			;6461
	inc de			;6462
	ld a,(hl)			;6463   ; Y la X
	ld (de),a			;6464
	ld (0e1aeh),a		;6465   ; E1AE se queda con la X: por ahi se mira si el jugador la ha dejado atras
	inc hl			;6468
	inc de			;6469
	ld (hl),0d8h		;646a   ; Patron 0xD8 en color 11 (amarillo claro)
	inc hl			;646c
	ld (hl),00bh		;646d
	ex de,hl			;646f   ; Ahora HL es el sprite 21
	ld (hl),0dch		;6470   ; Y encima el 0xDC en color 1 (negro): las rayas
	inc hl			;6472
	ld (hl),001h		;6473
	ret			;6475
ABEJA_APARECE:		; Y=0x28, X=0xD8, 100 puntos por pasarla, sonido 5
	ld a,010h		;6476   ; E19E = 0x10 en BCD: cien puntos por dejarla atras
	ld (0e19eh),a		;6478
	ld (hl),028h		;647b   ; Y=0x28, X=0xD8: entra por arriba a la derecha
	inc hl			;647d
	ld (hl),0d8h		;647e
	ld a,005h		;6480   ; Sonido 5: el zumbido, en bucle hasta que el 6 lo calla
	call SONIDO		;6482
	jr ABEJA_SPRITES		;6485
ABEJA_MUEVE:		; Escondida: nada. Por encima de su altura: baja 2. Si no, X-2; acarreo al pasar de X=8
	ld a,0c8h		;6487   ; Y=0xC8 es la abeja escondida
	cp (hl)			;6489   ; Escondida no se mueve: de ahi solo la saca ABEJA_APARECE
	jr z,L_64A2		;648a
	ld a,(0e179h)		;648c   ; E179 elige una de las cuatro alturas de 0x64A4
	ld de,064a4h		;648f
	call DE_MAS_A		;6492
	ld a,(de)			;6495
	cp (hl)			;6496   ; Aun por encima de su altura: baja dos
	jr nc,L_64A0		;6497
	inc hl			;6499   ; Ya a su altura: dos puntos a la izquierda
	dec (hl)			;649a
	dec (hl)			;649b
	ld a,(hl)			;649c
	cp 008h		;649d   ; Acarreo al llegar a X=8: se sale por el borde
	ret			;649f
L_64A0:
	inc (hl)			;64a0   ; Dos puntos mas abajo; como sale de 0x28 y las cuatro alturas son pares, se pasa dos y acaba volando en 0x3A, 0x4A, 0x5A o 0x74 (el cobro de 0x6AFC mira ese 0x74)
	inc (hl)			;64a1
L_64A2:
	or a			;64a2   ; Sin acarreo: aun no se ha salido
	ret			;64a3

; ----------------------------------------------------------------------
; DATOS alturas_de_la_abeja: Las cuatro alturas a las que baja: 0x38, 0x48,
;   0x58, 0x72
;   0x64a4..0x64a8  (4 bytes)
DATA_alturas_de_la_abeja:
	defb 038h,048h,058h,072h	; 64a4

; ======================================================================
; CODIGO 0x64a8..0x66c2  (538 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL TRONCO (sprites 9 y 10). Bit 5 de E158 y sin surtidores, un
; fotograma de cada dos: va y viene por el estanque entre X=0x48 y
; X=0x98 un punto cada dos fotogramas; si el jugador va montado (estado
; 5) lo lleva.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
TRONCO:		; El tronco que flota en el estanque
	ld a,(0e158h)		;64a8   ; Bit 5 de E158: esta pantalla lleva tronco
	and 020h		;64ab
	ret z			;64ad
	ld a,(0e156h)		;64ae   ; Y bit 3 de E156: con surtidores no hay tronco
	and 008h		;64b1
	ret nz			;64b3
	ld hl,0e003h		;64b4
	bit 0,(hl)		;64b7   ; Un fotograma de cada dos: medio punto por fotograma
	ret z			;64b9
	ld a,(0e138h)		;64ba   ; E138, el estado del jugador
	cp 00fh		;64bd   ; Con el jugador cayendo al agua, quieto
	ret z			;64bf
	cp 005h		;64c0   ; Estado 5: el jugador va montado y se mueve con el
	ld a,(0e17ah)		;64c2   ; E17A, hacia donde va el tronco
	ld b,a			;64c5
	jr nz,L_64D2		;64c6
	ld hl,0e135h		;64c8   ; Montado encima, la X del jugador se mueve con el
	or a			;64cb
	jr nz,L_64D1		;64cc
	dec (hl)			;64ce
	jr L_64D2		;64cf
L_64D1:
	inc (hl)			;64d1   ; Sentido 1: el jugador a la derecha
L_64D2:
	ld hl,0e0d5h		;64d2   ; E0D5 es la X del sprite 9, la mitad izquierda del tronco
	ld a,b			;64d5
	or a			;64d6
	jr nz,L_64DC		;64d7
	dec (hl)			;64d9   ; Sentido 0: el tronco tira a la izquierda
	jr L_64DD		;64da
L_64DC:
	inc (hl)			;64dc   ; Y el tronco tambien a la derecha
L_64DD:
	ld a,(hl)			;64dd   ; El sprite 10 va 16 a la derecha: ese es el borde
	add a,010h		;64de
	ld (0e0d9h),a		;64e0
	cp 058h		;64e3   ; Con el borde derecho (X+16) en 0x58, da la vuelta hacia la derecha
	jr nz,L_64ED		;64e5
	ld a,001h		;64e7
TRONCO_SENTIDO:		; E17A = 1 derecha, 0 izquierda
	ld (0e17ah),a		;64e9   ; E17A, el sentido nuevo
	ret			;64ec
L_64ED:
	cp 0a8h		;64ed   ; Con el borde derecho en 0xA8, hacia la izquierda
	ret nz			;64ef
	xor a			;64f0
	jr TRONCO_SENTIDO		;64f1
CHOCA_CON_SPRITE:		; El jugador contra el sprite (HL): NC si sus 16x16 se solapan (Y+8 y X)
	ld de,0e134h		;64f3   ; E134 y E135, la Y y la X del jugador
	ld a,(de)			;64f6
	add a,008h		;64f7   ; Y del jugador mas 8, menos la del sprite: solapan si cae entre 0 y 15
	sub (hl)			;64f9
	jr c,NO_CHOCA		;64fa
	cp 010h		;64fc   ; Mas de 15: el sprite queda demasiado abajo
	jr nc,NO_CHOCA		;64fe
	inc de			;6500   ; DE a la X del jugador y HL a la del sprite
	inc hl			;6501
	ld a,(de)			;6502   ; Lo mismo con las X, estas sin desplazar
	sub (hl)			;6503
	jr c,NO_CHOCA		;6504
	cp 010h		;6506   ; Ventana de 16 tambien en la X; entre dos sprites (0x6580) se usa una de 17
	jr nc,NO_CHOCA		;6508
	or a			;650a   ; Sin acarreo: se tocan
	ret			;650b
NO_CHOCA:		; Acarreo: no
	scf			;650c   ; Acarreo: no se tocan
	ret			;650d

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; CAER SOBRE UN SURTIDOR. Cuatro tramos de X (0x38-0x50, 0x58-0x70,
; 0x80-0x98, 0xA0-0xB8) con la altura de su tabla en E148-E14B; si el
; jugador esta a menos de 9 puntos por encima, se sube (estado 4). Con
; acarreo si ademas cayo 16 o mas por debajo de donde salto: al agua.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
CAE_SOBRE_SURTIDOR:		; NC y estado 4 si aterriza en una tabla; acarreo si la caida mata
	ld de,0e148h		;650e   ; E148-E14B, la altura de las cuatro tablas
	ld hl,0e134h		;6511
	ld a,(0e135h)		;6514   ; La X del jugador se compara con los cuatro tramos; el primero, de 0x38 a 0x50
	ld b,a			;6517
	cp 038h		;6518
	jr c,L_652C		;651a
	cp 051h		;651c
	jr nc,L_652C		;651e
	ld a,(de)			;6520   ; Su altura mas 4 menos la Y del jugador: vale de 0 a 8, o sea hasta 8 por encima
	add a,004h		;6521
	sub (hl)			;6523
	jr c,L_652C		;6524
	cp 009h		;6526
	jr nc,L_652C		;6528
	jr SOBRE_SURTIDOR		;652a
L_652C:
	inc de			;652c   ; La altura de la segunda tabla
	ld a,b			;652d
	cp 058h		;652e   ; Segundo tramo, de 0x58 a 0x70
	jr c,L_6542		;6530
	cp 071h		;6532
	jr nc,L_6542		;6534
	ld a,(de)			;6536
	add a,004h		;6537
	sub (hl)			;6539
	jr c,L_6542		;653a
	cp 009h		;653c
	jr nc,L_6542		;653e
	jr SOBRE_SURTIDOR		;6540
L_6542:
	inc de			;6542   ; La altura de la tercera tabla, E14A
	ld a,b			;6543
	cp 080h		;6544   ; Tercero, de 0x80 a 0x98
	jr c,L_6558		;6546
	cp 099h		;6548
	jr nc,L_6558		;654a
	ld a,(de)			;654c   ; Su altura mas 4 menos la Y: el mismo margen de 0 a 8 puntos por encima
	add a,004h		;654d
	sub (hl)			;654f
	jr c,L_6558		;6550
	cp 009h		;6552
	jr nc,L_6558		;6554
	jr SOBRE_SURTIDOR		;6556   ; Dentro: se sube a la tabla
L_6558:
	inc de			;6558   ; La cuarta y ultima, E14B
	ld a,b			;6559
	cp 0a0h		;655a   ; Y cuarto, de 0xA0 a 0xB8
	jr c,CAE_AL_VACIO		;655c
	cp 0b9h		;655e
	jr nc,CAE_AL_VACIO		;6560
	ld a,(de)			;6562   ; Fallar tambien aqui ya es CAE_AL_VACIO: no hay quinta tabla
	add a,004h		;6563
	sub (hl)			;6565
	jr c,CAE_AL_VACIO		;6566
	cp 009h		;6568   ; Y el mismo margen de 9 puntos que en los otros tres tramos
	jr nc,CAE_AL_VACIO		;656a
SOBRE_SURTIDOR:		; Estado 4; acarreo si Y-16 >= la altura desde la que salto
	ld a,004h		;656c
	ld (0e138h),a		;656e   ; Estado 4: encaramado a la tabla
	ld a,(0e134h)		;6571
	ld hl,0e13ah		;6574   ; E13A es la Y desde la que empezo a caer
	sub 010h		;6577
	cp (hl)			;6579
	jr c,CAE_AL_VACIO		;657a
	scf			;657c
	ret			;657d
CAE_AL_VACIO:		; Sin acarreo: o no ha dado en ninguna tabla, o ha dado y la caida no mata
	or a			;657e
	ret			;657f
CHOCAN_SPRITES:		; NC si los sprites B y C se solapan (16x16, con 8 de margen en Y y en X)
	ld a,b			;6580   ; Cuatro bytes por sprite en E0B0: Y, X, patron y color
	rlca			;6581
	rlca			;6582
	ld hl,0e0b0h		;6583
	call HL_MAS_A		;6586
	ex de,hl			;6589   ; DE al sprite B
	ld a,c			;658a
	rlca			;658b
	rlca			;658c
	ld hl,0e0b0h		;658d
	call HL_MAS_A		;6590   ; HL al sprite C
	ld a,(de)			;6593
	add a,008h		;6594   ; Yb mas 8 menos Yc: solapan si cae entre 0 y 15
	sub (hl)			;6596
	jr c,L_65AB		;6597
	cp 010h		;6599
	jr nc,L_65AB		;659b
	inc de			;659d
	inc hl			;659e
	ld a,(de)			;659f   ; Con las X la ventana es de 0 a 16, un punto mas ancha
	add a,008h		;65a0
	sub (hl)			;65a2
	jr c,L_65AB		;65a3
	cp 011h		;65a5
	jr nc,L_65AB		;65a7
	or a			;65a9   ; Sin acarreo: se tocan
	ret			;65aa
L_65AB:
	scf			;65ab
	ret			;65ac

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL TIEMPO. E055 son 0x3A tramos que bajan uno cada 256 fotogramas;
; la barra va de la columna 30 hacia la 16 en la fila 1, un tile por
; cada cuatro tramos (0x2F lleno, 0x11-0x13 a medias, 0x14 vacio). Por
; debajo de 0x10 las caras de las vidas se ponen preocupadas (0xF8) y
; cada 64 fotogramas pita (sonido 0x0D). En 2 se para: no mata.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
TIEMPO:		; Cada 256 fotogramas un tramo menos; aviso por debajo de 0x10
	ld hl,0e055h		;65ad
	ld a,(hl)			;65b0
	ld c,a			;65b1
	cp 010h		;65b2
	jr nc,L_65CB		;65b4
	ld a,0f8h		;65b6   ; Caras preocupadas
	call CARAS_DE_LAS_VIDAS		;65b8
	ld a,c			;65bb
	cp 002h		;65bc
	ret z			;65be
	ld a,(0e003h)		;65bf
	and 03fh		;65c2
	jr nz,L_65CB		;65c4
	ld a,00dh		;65c6   ; El pitido de la prisa
	call SONIDO		;65c8
L_65CB:
	ld a,(0e003h)		;65cb
	and 0ffh		;65ce   ; Solo cuando el contador de fotogramas da la vuelta
	ret nz			;65d0
TIEMPO_UN_TRAMO_MENOS:		; Un tramo menos, salvo que ya este en 2
	ld hl,0e055h		;65d1
	ld a,(hl)			;65d4
	cp 002h		;65d5
	ret z			;65d7
PINTA_BARRA_TIEMPO:		; El tile del cursor segun E055 modulo 4, luego vacios a su derecha y llenos a su izquierda
	ld de,(0e056h)		;65d8
	ld a,(hl)			;65dc
	and 003h		;65dd   ; Modulo 4: en 2 se empieza tile nuevo a la izquierda con 0x13 (tres cuartos), 1 -> 0x12, 0 -> 0x11, 3 -> 0x14 (vacio)
	add a,011h		;65df
	cp 013h		;65e1
	jr nz,L_65E6		;65e3
	dec de			;65e5
L_65E6:
	call VPOKE		;65e6
	dec (hl)			;65e9
	ex de,hl			;65ea
	ld (0e056h),hl		;65eb
	ex de,hl			;65ee
	push de			;65ef
	ld a,03dh		;65f0   ; Hasta la columna 29, vacios (0x14)
	sub e			;65f2
	jr z,L_65FE		;65f3
	ld b,a			;65f5
L_65F6:
	inc de			;65f6
	ld a,014h		;65f7
	call VPOKE		;65f9
	djnz L_65F6		;65fc
L_65FE:
	pop de			;65fe
	ld a,e			;65ff   ; Desde la columna 16, llenos (0x2F)
	sub 030h		;6600
	ret z			;6602
	ld b,a			;6603
L_6604:
	dec de			;6604
	ld a,02fh		;6605
	call VPOKE		;6607
	djnz L_6604		;660a
	ret			;660c
PINTA_TIEMPO:		; La barra entera (y de paso un tramo menos); agotada (2), catorce vacios
	ld hl,0e055h		;660d   ; E055, los tramos de tiempo que quedan
	ld a,(hl)			;6610
	cp 002h		;6611   ; Con mas de 2 se repinta la barra desde el cursor, y de paso se gasta un tramo
	jr nz,PINTA_BARRA_TIEMPO		;6613
	ld de,03830h		;6615   ; Agotado: catorce tiles vacios seguidos desde la fila 1, columna 16
	ld b,00eh		;6618   ; Catorce, que es la barra entera
L_661A:
	ld a,014h		;661a
	call VPOKE		;661c
	inc de			;661f
	djnz L_661A		;6620
	ret			;6622
COBRA_AL_PASAR:		; Para B obstaculos con su X en (HL): si el jugador ya los ha dejado atras, cobra los puntos E18C+C (una sola vez)
	ld a,(0e058h)		;6623
	cp 008h		;6626
	jr nz,COBRA_AL_PASAR_IZQ		;6628
L_662A:
	ld a,(0e135h)		;662a   ; La X del jugador contra la del obstaculo de turno
	cp (hl)			;662d
	call nc,COBRA_PUNTOS		;662e   ; Entrando por la izquierda (E058 = 8) se anda hacia la derecha: pasados son los que tienen X menor
	inc c			;6631   ; C es el indice en la tabla de puntos E18C, HL la X del obstaculo siguiente
	inc hl			;6632
	djnz L_662A		;6633
	ret			;6635
COBRA_AL_PASAR_IZQ:		; Lo mismo yendo hacia la izquierda
	ld a,(0e135h)		;6636   ; Entrando por la derecha se anda hacia la izquierda: los pasados son los que quedan a la derecha
	cp (hl)			;6639
	call c,COBRA_PUNTOS		;663a
	inc c			;663d
	inc hl			;663e
	djnz COBRA_AL_PASAR_IZQ		;663f
	ret			;6641
COBRA_PUNTOS:		; Cobra los puntos E18C+C si aun no estan cobrados: los suma, y saca el rotulo 50/100/200 sobre el jugador 30 fotogramas
	push hl			;6642
	push bc			;6643
	ld a,c			;6644
	ld hl,0e18ch		;6645
	call HL_MAS_A		;6648
	ld a,(hl)			;664b
	or a			;664c   ; Ya cobrados
	jr z,COBRA_PUNTOS_FIN		;664d
	ld e,000h		;664f
	ld (hl),e			;6651
	rra			;6652   ; Los dos nibbles a DE en BCD: 0x20 son 200
	rr e		;6653
	rra			;6655
	rr e		;6656
	rra			;6658
	rr e		;6659
	rra			;665b
	rr e		;665c
	ld d,a			;665e
	push de			;665f
	call SUMA_PUNTOS_CON_SONIDO		;6660
	pop de			;6663
	ld b,004h		;6664
	ld c,000h		;6666
	ld hl,0e181h		;6668   ; El primer rotulo libre de los cuatro (sprites 23-26)
L_666B:
	ld a,(hl)			;666b   ; E181-E184: los fotogramas que le quedan a cada rotulo; a cero esta libre
	or a			;666c
	jr z,L_6673		;666d
	inc c			;666f
	inc hl			;6670
	djnz L_666B		;6671
L_6673:
	push hl			;6673   ; C es el numero de rotulo libre; por cuatro, los bytes del sprite
	ld a,c			;6674
	add a,a			;6675
	add a,a			;6676
	ld hl,0e10ch		;6677   ; E10C es el sprite 23, el primero de los cuatro rotulos
	call HL_MAS_A		;667a
	ld bc,0e134h		;667d   ; E134 y E135: el rotulo sale 16 por encima del jugador
	ld a,(bc)			;6680
	sub 010h		;6681
	ld (hl),a			;6683
	inc hl			;6684
	inc bc			;6685
	ld a,(bc)			;6686
	ld (hl),a			;6687
	inc hl			;6688
	ld a,d			;6689   ; Patron 0xE0 (50), 0xE4 (100) o 0xE8 (200), blanco
	add a,a			;668a
	add a,a			;668b
	add a,0e0h		;668c
	ld (hl),a			;668e
	inc hl			;668f
	ld (hl),00fh		;6690   ; Color 15, blanco
	ld a,01eh		;6692   ; 30 fotogramas a la vista
	pop hl			;6694
	ld (hl),a			;6695
COBRA_PUNTOS_FIN:		; Nada que cobrar
	pop bc			;6696
	pop hl			;6697
	ret			;6698
CARAS_DE_LAS_VIDAS:		; Pone el patron A en las cuatro caras: 0xF4 normal, 0xF8 preocupada, 0xEC contenta, 0xF0 llorando
	ld b,004h		;6699
	ld hl,0e11eh		;669b
L_669E:
	ld (hl),a			;669e   ; Cuatro bytes por sprite: solo se toca el patron
	inc hl			;669f
	inc hl			;66a0
	inc hl			;66a1
	inc hl			;66a2
	djnz L_669E		;66a3
	ret			;66a5

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL JUGADOR. Esconde los rotulos de puntos que hayan caducado y
; despacha por su estado E138: 0 anda, 1 en el aire, 2 colgado de la
; liana, 3 botando en el trampolin, 4 sobre una tabla de surtidor, 5
; montado en el tronco, 6 sobre un poste, 7 llego a la meta, 8 fase
; superada, 15 se hunde, 16 le han dado. Del 9 al 14 no existen (0000).
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
JUGADOR:		; Rotulos caducados fuera y el estado del jugador por la tabla
	ld b,004h		;66a6
	ld de,0e10ch		;66a8
	ld hl,0e181h		;66ab
L_66AE:
	ld a,(hl)			;66ae
	or a			;66af
	jr nz,L_66B5		;66b0
	ld a,0c8h		;66b2   ; Rotulo caducado: Y=0xC8, escondido
	ld (de),a			;66b4
L_66B5:
	inc hl			;66b5   ; Al contador siguiente (E181-E184) y al sprite siguiente, cuatro bytes mas alla
	inc de			;66b6
	inc de			;66b7
	inc de			;66b8
	inc de			;66b9
	djnz L_66AE		;66ba
	ld a,(0e138h)		;66bc   ; E138, el estado del jugador: el indice de la tabla de 0x66C2
	call DESPACHA		;66bf   ; DESPACHA no vuelve: el ret del estado es el de JUGADOR

; ----------------------------------------------------------------------
; DATOS tabla_de_estados_del_jugador: Los 17 estados del jugador: 0x689B anda,
;   0x66E4 en el aire, 0x6D06 en la liana, 0x67E0 trampolin, 0x6847 surtidor,
;   0x6873 tronco, 0x6888 poste, 0x6987 meta, 0x69B3 fase superada, seis
;   0x0000 sin uso, 0x6A05 se hunde, 0x69D8 le han dado
;   0x66c2..0x66e4  (34 bytes)
DATA_tabla_de_estados_del_jugador:
	defw 0689bh	; 66c2  -> ESTADO_0_ANDA
	defw 066e4h	; 66c4  -> ESTADO_1_EN_EL_AIRE
	defw 06d06h	; 66c6  -> ESTADO_2_LIANA
	defw 067e0h	; 66c8  -> ESTADO_3_TRAMPOLIN
	defw 06847h	; 66ca  -> ESTADO_4_SURTIDOR
	defw 06873h	; 66cc  -> ESTADO_5_TRONCO
	defw 06888h	; 66ce  -> ESTADO_6_POSTE
	defw 06987h	; 66d0  -> ESTADO_7_META
	defw 069b3h	; 66d2  -> ESTADO_8_FASE_SUPERADA
	defw 00000h	; 66d4
	defw 00000h	; 66d6
	defw 00000h	; 66d8
	defw 00000h	; 66da
	defw 00000h	; 66dc
	defw 00000h	; 66de
	defw 06a05h	; 66e0  -> ESTADO_15_SE_HUNDE
	defw 069d8h	; 66e2  -> ESTADO_16_LE_HAN_DADO

; ======================================================================
; CODIGO 0x66e4..0x6746  (98 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; ESTADO 1: EN EL AIRE. Un paso por el arco de salto (6C3C, que de paso
; mira si agarra una liana). Bajando: si hay trampolines y cae en uno,
; bota (estado 3, sonido 9); si no, mira si cae en un surtidor (650E:
; estado 4, o al agua) o aterriza (676A).
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
ESTADO_1_EN_EL_AIRE:		; Un paso del salto y, bajando, donde cae
	call PASO_DE_SALTO		;66e4
	ld a,(0e202h)		;66e7
	or a			;66ea   ; Subiendo todavia: solo la X y los bordes
	jp z,AIRE_MOVIMIENTO_COMUN		;66eb
	ld a,(0e156h)		;66ee
	bit 2,a		;66f1
	jr z,AIRE_SIN_TRAMPOLIN		;66f3
	call CAE_EN_TRAMPOLIN		;66f5   ; En un trampolin
	jr nc,$+108		;66f8
	ld a,009h		;66fa   ; Bota: sonido 9, estado 3, arco desde el principio
	call SONIDO		;66fc
	ld a,003h		;66ff
	ld (0e138h),a		;6701
	ld hl,06cf5h		;6704
	call ARCO_SUBIENDO		;6707
	ld (0e137h),a		;670a
	ret			;670d
AIRE_SIN_TRAMPOLIN:		; Con postes: si cae sobre uno, se queda de pie en el (estado 6)
	bit 4,a		;670e
	jr z,$+64		;6710
	ld b,005h		;6712   ; Cinco postes: Y y X en 0x6746
	ld hl,06746h		;6714
L_6717:
	ld a,(0e134h)		;6717   ; La Y del jugador menos la de la cabeza del poste (parejas Y,X en 0x6746)
	ld c,(hl)			;671a   ; HL avanza a la X en cuanto lee la Y
	inc hl			;671b
	sub c			;671c
	cp 005h		;671d   ; A menos de 5 puntos por encima y a menos de 16 de su X
	jr nc,L_672A		;671f
	ld a,(0e135h)		;6721   ; Y la X del jugador menos la del poste, sin signo: solo cae encima por la derecha
	ld c,(hl)			;6724
	sub c			;6725
	cp 010h		;6726
	jr c,L_672F		;6728
L_672A:
	inc hl			;672a
	djnz L_6717		;672b
	jr $+55		;672d
L_672F:
	dec hl			;672f   ; De pie sobre el poste (Y+4), estado 6, y cobra los 100 puntos del poste
	ld a,(hl)			;6730
	add a,004h		;6731
	ld (0e134h),a		;6733   ; Se queda de pie 4 puntos por debajo de la cabeza del poste
	ld a,006h		;6736
	ld (0e138h),a		;6738
	ld hl,0e1a0h		;673b   ; E1A0-E1A4, las X de los cinco postes; con C=4 sus puntos salen de E190-E194
	ld b,005h		;673e
	ld c,004h		;6740
	call COBRA_AL_PASAR		;6742
	ret			;6745

; ----------------------------------------------------------------------
; DATOS postes_y_x: Cinco parejas Y,X de la cabeza de cada poste: (0x58,0x30)
;   (0x50,0x50) (0x50,0x70) (0x50,0x90) (0x58,0xB0)
;   0x6746..0x6750  (10 bytes)
DATA_postes_y_x:
	defb 058h,030h	; 6746
	defb 050h,050h	; 6748
	defb 050h,070h	; 674a
	defb 050h,090h	; 674c
	defb 058h,0b0h	; 674e

; ======================================================================
; CODIGO 0x6750..0x686f  (287 bytes)
; ======================================================================


AIRE_CAE:		; Surtidor, tronco o suelo; y si sale de la pantalla
	call CAE_SOBRE_SURTIDOR		;6750
	jp c,LE_HAN_DADO		;6753   ; Cayo al agua desde muy alto
	ld a,(0e138h)		;6756
	cp 004h		;6759
	jr nz,L_6764		;675b
	ld a,e			;675d   ; Sobre una tabla: cobra los 200 puntos de ese surtidor
	sub 048h		;675e
	ld c,a			;6760
	call COBRA_PUNTOS		;6761
L_6764:
	call ATERRIZA		;6764
AIRE_MOVIMIENTO_COMUN:		; Al movimiento comun (6A24)
	jp MOVIMIENTO_COMUN		;6767

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; ATERRIZAR. Al llegar a Y=0x6C: sobre el estanque de postes (X 0x28-
; 0xC8) o el foso de los trampolines (X 0x38-0xB8) es caer al agua; si el
; tronco esta activo (Y=0x87) y se cae a menos de 32 de el, se monta
; (estado 5); si no, de pie (estado 0).
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
ATERRIZA:		; De pie, en el tronco, o al agua
	ld hl,0e134h		;676a
	ld a,(hl)			;676d
	cp 06ch		;676e   ; Aun en el aire
	jr c,ATERRIZA_FIN		;6770
	inc hl			;6772
	ld a,(0e156h)		;6773
	bit 4,a		;6776
	jr z,L_677F		;6778
	call SOBRE_ESTANQUE_POSTES		;677a   ; El estanque de postes: al agua
	jr c,AL_AGUA		;677d
L_677F:
	bit 2,a		;677f
	jr z,L_6788		;6781
	call SOBRE_FOSO		;6783   ; El foso de los trampolines: al agua
	jr c,AL_AGUA		;6786
L_6788:
	ld a,(0e0d4h)		;6788
	cp 087h		;678b   ; Tronco activo (Y=0x87)...
	jr nz,L_679D		;678d
	ld a,(0e0d5h)		;678f
	sub 008h		;6792
	ld b,a			;6794
	ld a,(hl)			;6795
	sub b			;6796
	cp 020h		;6797   ; ...y a menos de 32 puntos: montado (estado 5)
	ld a,005h		;6799
	jr c,L_679E		;679b
L_679D:
	xor a			;679d
L_679E:
	ld (0e138h),a		;679e
	ld a,06ch		;67a1
	ld (0e134h),a		;67a3
ATERRIZA_FIN:		; Sigue en el aire
	ret			;67a6
AL_AGUA:		; Muere ahogado
	jp LE_HAN_DADO		;67a7
SOBRE_ESTANQUE_POSTES:		; Acarreo si X esta entre 0x28 y 0xC7
	ld a,(hl)			;67aa
	sub 028h		;67ab
	cp 0a0h		;67ad
	ret			;67af
SOBRE_FOSO:		; Acarreo si X esta entre 0x38 y 0xB7
	ld a,(hl)			;67b0
	sub 038h		;67b1
	cp 080h		;67b3
	ret			;67b5
CAE_EN_TRAMPOLIN:		; Acarreo si Y esta entre 0x64 y 0x68 y X a menos de 16 de un trampolin (0x40, 0x60, 0x80, 0xA0): lo centra (X+8) y cobra sus 100 puntos
	ld a,(0e134h)		;67b6   ; La Y del jugador: solo entre 0x64 y 0x68 esta a la altura de la lona
	sub 064h		;67b9
	cp 005h		;67bb
	ret nc			;67bd
	ld hl,0e135h		;67be
	ld bc,00440h		;67c1   ; B=4 trampolines y C=0x40, la X del primero
L_67C4:
	ld a,(hl)			;67c4   ; La X del jugador menos la del trampolin de turno
	sub c			;67c5
	cp 010h		;67c6   ; A menos de 16 por su derecha: ha caido en el
	ld a,c			;67c8
	jr c,L_67D1		;67c9
	add a,020h		;67cb   ; El trampolin siguiente, 0x20 mas a la derecha
	ld c,a			;67cd
	djnz L_67C4		;67ce
	ret			;67d0   ; Ninguno: se vuelve sin acarreo
L_67D1:
	add a,008h		;67d1   ; A trae la X del trampolin: el jugador se centra 8 puntos a su derecha
	ld (hl),a			;67d3
	ld hl,0e1a5h		;67d4   ; E1A5-E1A8, las X de los cuatro; con C=9 sus puntos salen de E195-E198
	ld b,004h		;67d7
	ld c,009h		;67d9
	call COBRA_AL_PASAR		;67db
	scf			;67de   ; Acarreo: ha caido en un trampolin
	ret			;67df

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; ESTADO 3: BOTANDO EN EL TRAMPOLIN. Un paso del arco (con la liana de
; paso), y con izquierda/derecha se mueve; con el boton pulsado en el
; aire (E204) el siguiente bote sale con el arco alto (0x63C9), y sin el
; con el corto (0x6CF5). Bajando por debajo de Y=0x40 se mira si cae en
; un trampolin (Y=0x64, sonido 9) o fuera (aterriza como en el aire).
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
ESTADO_3_TRAMPOLIN:		; Botando en los trampolines
	call PASO_DE_SALTO		;67e0
	ld a,(0e009h)		;67e3
	and 00ch		;67e6   ; Izquierda o derecha pulsadas
	jr nz,L_67EB		;67e8
	xor a			;67ea
L_67EB:
	ld (0e203h),a		;67eb
	or a			;67ee
	jr z,L_67F4		;67ef
	ld (0e139h),a		;67f1   ; Y hacia alli mira
L_67F4:
	ld a,(0e202h)		;67f4
	or a			;67f7
	jr z,TRAMPOLIN_SIGUE		;67f8
	ld a,(0e134h)		;67fa
	cp 040h		;67fd   ; Aun por encima de Y=0x40
	jr c,TRAMPOLIN_SIGUE		;67ff
	call SALTA_SI_BOTON		;6801   ; Boton: el proximo bote sera alto
	jr nc,L_680B		;6804
	ld a,001h		;6806
	ld (0e204h),a		;6808
L_680B:
	call CAE_EN_TRAMPOLIN		;680b
	ld a,06ch		;680e   ; Altura segura: el suelo
	ld (0e13ah),a		;6810
	jr nc,TRAMPOLIN_FUERA		;6813
	ld a,064h		;6815   ; En el trampolin: Y=0x64
	ld (0e134h),a		;6817
	ld hl,0e204h		;681a
	ld a,(hl)			;681d
	or a			;681e
	jr z,BOTE_SIN_BOTON		;681f
	ld (hl),000h		;6821   ; Bote alto pedido: arco 0x63C9 y sonido 9
	ld a,(0e203h)		;6823
	ld (0e137h),a		;6826
	or a			;6829
	ld hl,063c9h		;682a
	jr z,L_6832		;682d
BOTE_CORTO:		; Arco corto 0x6CF5
	ld hl,06cf5h		;682f
L_6832:
	call ARCO_SUBIENDO		;6832
	ld a,009h		;6835
	call SONIDO		;6837
TRAMPOLIN_SIGUE:		; Al movimiento comun (6A24)
	jp MOVIMIENTO_COMUN		;683a
BOTE_SIN_BOTON:		; Bote corto sin cambiar de direccion
	ld (0e137h),a		;683d
	jr BOTE_CORTO		;6840
TRAMPOLIN_FUERA:		; No cayo en trampolin: aterriza (o al foso)
	call ATERRIZA		;6842
	jr TRAMPOLIN_SIGUE		;6845

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; ESTADO 4: SOBRE UN SURTIDOR. Sigue la altura de la tabla en la que va
; (X entre 0x38 y 0xB8, cuatro tramos de 0x19); si la X se sale de las
; cuatro, cae (estado 1 con el arco corto).
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
ESTADO_4_SURTIDOR:		; Subir y bajar con la tabla; fuera de ellas, caer
	ld b,004h		;6847
	ld hl,0686fh		;6849
	ld de,0e148h		;684c
L_684F:
	ld a,(0e135h)		;684f
	ld c,(hl)			;6852
	sub c			;6853
	cp 019h		;6854   ; A menos de 0x19 de la X de una tabla
	jr c,SIGUE_LA_TABLA		;6856
	inc hl			;6858
	inc de			;6859
	djnz L_684F		;685a
CAE_DE_LO_ALTO:		; Estado 1 con el arco corto, cayendo desde aqui
	ld hl,06cf5h		;685c
	call ARCO_CAYENDO		;685f
	ld a,001h		;6862
	ld (0e138h),a		;6864
	ret			;6867
SIGUE_LA_TABLA:		; Y = la altura de la tabla
	ld a,(de)			;6868
	ld (0e134h),a		;6869
A_ANDAR_O_SALTAR:		; A andar/saltar (696B)
	jp ANDA_O_SALTA		;686c

; ----------------------------------------------------------------------
; DATOS x_de_los_surtidores: Las X de las cuatro tablas: 0x38, 0x58, 0x80,
;   0xA0
;   0x686f..0x6873  (4 bytes)
DATA_x_de_los_surtidores:
	defb 038h,058h,080h,0a0h	; 686f

; ======================================================================
; CODIGO 0x6873..0x68ea  (119 bytes)
; ======================================================================


ESTADO_5_TRONCO:		; Montado en el tronco: cobra sus 200 puntos, va con el, y si se aleja mas de 32 de el cae al agua (68C4)
	ld c,000h		;6873   ; El indice 0 de la tabla de puntos: los 200 que 0x5C27 pone en E18C, y que comparten la liana 1, el primer surtidor y el tronco
	call COBRA_PUNTOS		;6875
	ld a,(0e0d5h)		;6878   ; E0D5 es la X del sprite 9, la mitad izquierda del tronco; menos 8, su borde util
	sub 008h		;687b
	ld b,a			;687d
	ld a,(0e135h)		;687e
	sub b			;6881
	cp 020h		;6882   ; Mas de 32 puntos de separacion: se ha salido del tronco al agua
	jr nc,SE_HUNDE		;6884
	jr $-26		;6886   ; Sigue montado: anda o salta como en el suelo (0x686C)
ESTADO_6_POSTE:		; De pie en un poste: mientras este a menos de 16 de su X puede andar o saltar; si no, cae (685C)
	ld b,005h		;6888
	ld hl,06747h		;688a
L_688D:
	ld a,(0e135h)		;688d   ; HL arranca en 0x6747, la X del primer poste; las Y se van salteando
	sub (hl)			;6890
	cp 010h		;6891   ; A menos de 16 de su X: sigue encima
	jr c,$-39		;6893   ; Encima: puede andar o saltar (0x686C)
	inc hl			;6895   ; Dos bytes por poste, Y y X
	inc hl			;6896
	djnz L_688D		;6897
	jr $-61		;6899   ; Se ha salido de los cinco: cae con el arco corto (0x685C)

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; ESTADO 0: ANDANDO. Con estanque (bit 7), pisar entre X=0x36 y 0xB7 es
; hundirse (68C4); con charcos, pisar uno (X a menos de 16 de 0x30+32n) es
; caer en el (68AE); sobre el estanque de postes o el foso de los
; trampolines a ras de suelo se avanza un punto mas y suena el 0x0B (se
; chapotea). Luego la meta (692C), la caida mortal (6960) y andar/saltar.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
ESTADO_0_ANDA:		; Andando por el suelo
	ld a,(0e156h)		;689b
	bit 7,a		;689e
	jr z,$+78		;68a0
	ld a,(0e135h)		;68a2   ; X entre 0x36 y 0xB7: dentro del estanque
	sub 036h		;68a5
	cp 082h		;68a7
	jp nc,META		;68a9
	jr SE_HUNDE		;68ac
CAE_EN_CHARCO:		; Sprites 0-3 a Y=0x8C, dos puntos mas alla, y a hundirse
	ld hl,068eah		;68ae   ; La plantilla de 0x68EA: los sprites 0-3, aparcados en Y=0x90 (0x5F61), suben cuatro lineas a Y=0x8C
	call CUATRO_SPRITES_IGUALES		;68b1   ; Van con patron y color 0: no pintan nada, solo ocupan plaza de sprite en esas lineas (?)
	ld a,(0e139h)		;68b4   ; E139, hacia donde mira: 4 es a la izquierda
	cp 004h		;68b7
	ld hl,0e135h		;68b9
	jr nz,L_68C2		;68bc
	dec (hl)			;68be   ; Mirando a la izquierda, dos puntos mas a la izquierda; mirando a la derecha, dos a la derecha
	dec (hl)			;68bf
	jr SE_HUNDE		;68c0
L_68C2:
	inc (hl)			;68c2
	inc (hl)			;68c3
SE_HUNDE:		; Arco de hundimiento 0x6CE3, estado 15, sonido 0x99, caras llorando y todos los obstaculos fuera
	ld hl,06ce3h		;68c4
	call ARCO_CAYENDO		;68c7
	ld (0e137h),a		;68ca
	ld a,00fh		;68cd   ; Estado 15: hundirse
	ld (0e138h),a		;68cf
	ld a,099h		;68d2   ; Sonido de ahogarse
	call SONIDO		;68d4
	ld a,0f0h		;68d7   ; Caras llorando
	call CARAS_DE_LAS_VIDAS		;68d9
ESCONDE_OBSTACULOS:		; Sprites 11-25 a 0xC3
	ld hl,0e0dch		;68dc   ; E0DC es el sprite 11, el primero de los obstaculos
	ld de,0e0ddh		;68df
	ld (hl),0c3h		;68e2   ; 0xC3 en todos los bytes; lo que importa es la Y, que deja el sprite por debajo de las 192 filas
	ld bc,0003ch		;68e4   ; 61 bytes: los sprites 11 a 25 enteros y la Y del 26
	ldir		;68e7
	ret			;68e9

; ----------------------------------------------------------------------
; DATOS sprite_en_el_charco: Y=0x8C y ceros para los sprites 0-3
;   0x68ea..0x68ee  (4 bytes)
DATA_sprite_en_el_charco:
	defb 08ch,000h,000h,000h	; 68ea

; ======================================================================
; CODIGO 0x68ee..0x6b8a  (668 bytes)
; ======================================================================


ANDA_SIN_ESTANQUE:		; Los cinco charcos (X 0x30, 0x50, 0x70, 0x90, 0xB0)
	bit 0,a		;68ee
	jr z,ANDA_ESTANQUE_POSTES		;68f0
	ld bc,00530h		;68f2
L_68F5:
	ld a,(0e135h)		;68f5   ; La X del jugador menos la del charco de turno (B=5 charcos desde C=0x30)
	sub c			;68f8
	cp 010h		;68f9
	jr c,$-77		;68fb   ; Dentro de la ventana de 16: cae en el (0x68AE)
	ld a,c			;68fd
	add a,020h		;68fe   ; El charco siguiente, 0x20 mas alla
	ld c,a			;6900
	djnz L_68F5		;6901
	jr META		;6903   ; Ninguno pisado: a mirar si se ha llegado a la meta
ANDA_ESTANQUE_POSTES:		; Bit 4: sobre el estanque de postes chapotea (X+1 y sonido 0x0B)
	ld hl,0e135h		;6905
	bit 4,a		;6908
	jr z,ANDA_FOSO		;690a
	call SOBRE_ESTANQUE_POSTES		;690c
	jr nc,META		;690f
CHAPOTEA:		; Un punto mas hacia donde mira y sonido 0x0B
	ld a,(0e139h)		;6911
	bit 3,a		;6914
	jr nz,L_691B		;6916
	inc (hl)			;6918
	jr L_691C		;6919
L_691B:
	dec (hl)			;691b
L_691C:
	ld a,00bh		;691c
	call SONIDO		;691e
	jr META		;6921
ANDA_FOSO:		; Bit 2: sobre el foso de los trampolines, igual
	bit 2,a		;6923
	jr z,META		;6925
	call SOBRE_FOSO		;6927
	jr c,CHAPOTEA		;692a

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LA META. En los SCENE acabados en 0 (salvo el 0) que coincidan con la
; meta de la fase (E05A: 10, 20, 30...), al pasar de X=0xC8 (o bajar de
; 0x28 si se avanza hacia la izquierda) suena la fanfarria (0x9C) y el
; jugador entra en el estado 7 con seis medias vueltas.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
META:		; Mira si se ha llegado a la meta de la fase
	ld hl,0e059h		;692c
	ld a,(hl)			;692f
	and 00fh		;6930   ; SCENE acabado en 0
	jr nz,CAIDA_MORTAL		;6932
	ld a,(0e054h)		;6934
	or a			;6937   ; Pero no el 0
	jr z,CAIDA_MORTAL		;6938
	ld a,(hl)			;693a
	inc hl			;693b
	cp (hl)			;693c   ; Y el que dice E05A: la meta de esta fase
	jr nz,CAIDA_MORTAL		;693d
	ld hl,0e135h		;693f
	ld a,(0e053h)		;6942   ; Bit 0 de E053: hacia donde se avanza
	rra			;6945
	ld a,0c8h		;6946   ; Avanzando a la derecha, pasar de X=0xC8
	jr nc,L_6951		;6948
	ld a,028h		;694a   ; Avanzando a la izquierda, bajar de X=0x28
	cp (hl)			;694c
	jr nc,META_ALCANZADA		;694d
	jr CAIDA_MORTAL		;694f
L_6951:
	cp (hl)			;6951
	jr nc,CAIDA_MORTAL		;6952
META_ALCANZADA:		; Seis medias vueltas (E001) y la fanfarria
	ld a,006h		;6954
	ld (0e001h),a		;6956
	ld a,09ch		;6959
	call SONIDO		;695b
	jr MEDIA_VUELTA		;695e
CAIDA_MORTAL:		; Si Y-17 llega a la altura desde la que salto (E13A): se ha caido al agua
	ld a,(0e134h)		;6960
	ld hl,0e13ah		;6963
	sub 011h		;6966
	cp (hl)			;6968
	jr nc,LE_HAN_DADO		;6969
ANDA_O_SALTA:		; Andar (6D72) y, con el boton, saltar (arco corto 0x6CF5, sonido 3)
	call ANDA		;696b
	call SALTA_SI_BOTON		;696e
	jp nc,MOVIMIENTO_COMUN		;6971
	ld hl,06cf5h		;6974   ; Salto normal: arco corto
	call ARCO_SUBIENDO		;6977
	ld a,001h		;697a
	ld (0e138h),a		;697c
	ld a,003h		;697f   ; Sonido de saltar
	call SONIDO		;6981
	jp MOVIMIENTO_COMUN		;6984
ESTADO_7_META:		; Llegado a la meta: cada media vuelta cambia de lado; a la sexta, estado 8
	call PASO_DE_SALTO		;6987
	call ATERRIZA		;698a
	cp 06ch		;698d   ; Aun en el aire
	jr nz,A_PINTAR_JUGADOR		;698f
	ld hl,0e001h		;6991
	dec (hl)			;6994
	ld a,(hl)			;6995
	dec a			;6996
	ld a,008h		;6997   ; Ultima: estado 8
	jr z,L_69AD		;6999
	ld hl,0e139h		;699b
	ld a,(hl)			;699e
	xor 00ch		;699f   ; Media vuelta
	ld (hl),a			;69a1
MEDIA_VUELTA:		; Arco corto y estado 7
	ld hl,06cf5h		;69a2
	call ARCO_SUBIENDO		;69a5
	ld (0e137h),a		;69a8
	ld a,007h		;69ab
L_69AD:
	ld (0e138h),a		;69ad
A_PINTAR_JUGADOR:		; Pinta los sprites del jugador
	jp PINTA_JUGADOR		;69b0
ESTADO_8_FASE_SUPERADA:		; E00D = 1: la fase esta superada (lo recoge el estado 11 del juego)
	ld a,001h		;69b3
	ld (0e00dh),a		;69b5
	ret			;69b8
LE_HAN_DADO:		; Caras llorando, obstaculos fuera, sonido 0x96, pose 16, estado 16 y el contador de fotogramas a cero
	ld a,0f0h		;69b9   ; 0xF0: el patron de la cara llorando en la fila de las vidas
	call CARAS_DE_LAS_VIDAS		;69bb
	call ESCONDE_OBSTACULOS		;69be
	ld a,096h		;69c1   ; Sonido 0x96: el de la muerte por golpe, tres canales
	call SONIDO		;69c3
	ld a,010h		;69c6   ; E136 = 0x10: la primera de las dos poses de muerte
	ld (0e136h),a		;69c8
	call PINTA_JUGADOR_MUERTO		;69cb
	ld a,010h		;69ce
	ld (0e138h),a		;69d0   ; Estado 16 del jugador
	xor a			;69d3   ; El contador de fotogramas a cero: los 128 del estado 16 cuentan desde aqui
	ld (0e003h),a		;69d4
	ret			;69d7
ESTADO_16_LE_HAN_DADO:		; Cae dos puntos por fotograma hasta el suelo (Y=0x6C); cada 16 alterna las dos poses de muerte; a los 128 fotogramas, muerto (E00C)
	ld hl,0e134h		;69d8
	ld a,(hl)			;69db
	cp 06ch		;69dc   ; 0x6C es la Y del suelo
	jr nc,L_69E2		;69de
	inc (hl)			;69e0
	inc (hl)			;69e1
L_69E2:
	ld a,(0e003h)		;69e2
	and 00fh		;69e5   ; Cada 16 fotogramas
	jr nz,L_69F1		;69e7
	inc hl			;69e9
	inc hl			;69ea
	ld a,(hl)			;69eb   ; E136, la pose
	xor 001h		;69ec   ; Cambia el bit 0 de la pose: alterna las dos poses de muerte
	and 011h		;69ee
	ld (hl),a			;69f0
L_69F1:
	call PINTA_JUGADOR_MUERTO		;69f1
	ld a,(0e134h)		;69f4
	cp 06ch		;69f7
	ret c			;69f9
	ld a,(0e003h)		;69fa
	and 07fh		;69fd   ; Ciento veintiocho fotogramas tirado antes de dar la vida por perdida
	ret nz			;69ff
	inc a			;6a00
	ld (0e00ch),a		;6a01
	ret			;6a04
ESTADO_15_SE_HUNDE:		; Cada 8 fotogramas un paso del arco de hundimiento, con la pose 6; al llegar a Y=0x7C, muerto (E00C)
	ld a,(0e003h)		;6a05   ; Un paso cada ocho fotogramas: el hundimiento va ocho veces mas lento que un salto
	and 007h		;6a08
	ret nz			;6a0a
	ld a,0c3h		;6a0b   ; Sin sombra
	ld (0e0d0h),a		;6a0d   ; E0D0 es la Y del sprite 8, la sombra: a 0xC3 se sale de la pantalla
	call PASO_DE_SALTO		;6a10
	ld a,006h		;6a13   ; La pose 6 fija, la ultima de las siete de 0x6B8A
	ld (0e136h),a		;6a15
	ld a,(0e134h)		;6a18
	cp 07ch		;6a1b   ; A Y=0x7C ya no se le ve
	jp c,PINTA_JUGADOR		;6a1d
	ld (0e00ch),a		;6a20   ; E00C distinto de cero es muerto, y aqui se le mete la propia Y; lo recoge el estado 12
	ret			;6a23
MOVIMIENTO_COMUN:		; Pinta al jugador y mira los bordes: X<3 sale por la izquierda (E00E=1, entrara por la derecha), X>=0xF0 por la derecha (E00E=2, entrara por la izquierda); si no, los choques
	call PINTA_JUGADOR		;6a24
	ld a,(0e135h)		;6a27
	ld bc,001e8h		;6a2a   ; Por la izquierda: E00E=1 y la proxima entrada en X=0xE8
	cp 003h		;6a2d
	jr c,SALE_DE_PANTALLA		;6a2f
	cp 0f0h		;6a31
	jr c,CHOQUES		;6a33
	ld bc,00208h		;6a35   ; Por la derecha: E00E=2 y la proxima entrada en X=8
SALE_DE_PANTALLA:		; E00E y E058 con lo que diga BC
	ld a,b			;6a38
	ld (0e00eh),a		;6a39
	ld a,c			;6a3c
	ld (0e058h),a		;6a3d
	ret			;6a40

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LOS CHOQUES. La cabeza (sprite 4) contra los peces (11-13), las bolas
; (14-15), los aranas (16-18), la abeja (20) y la bola que bota (22)
; mata; contra la fruta (19) son 200 puntos y sonido 0x0A. Las piernas
; (sprite 6) contra los mismos, y contra la caja invisible de la piedra
; o la hoguera (31). Al final, los puntos por pasar las bolas y la abeja.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
CHOQUES:		; La cabeza contra los sprites 11-22, las piernas contra 11-31
	ld bc,0040bh		;6a41   ; B=4 es el sprite de la cabeza, C=11 el primer pez; C sube de uno en uno
	call CHOCAN_SPRITES		;6a44   ; Cabeza contra pez 1
	jp nc,LE_HAN_DADO		;6a47
	inc bc			;6a4a
	call CHOCAN_SPRITES		;6a4b
	jp nc,LE_HAN_DADO		;6a4e
	inc bc			;6a51
	call CHOCAN_SPRITES		;6a52
	jp nc,LE_HAN_DADO		;6a55
	inc bc			;6a58
	call CHOCAN_SPRITES		;6a59   ; Sprites 14 y 15, las bolas que ruedan
	jp nc,LE_HAN_DADO		;6a5c
	inc bc			;6a5f
	call CHOCAN_SPRITES		;6a60
	jp nc,LE_HAN_DADO		;6a63
	inc bc			;6a66
	call CHOCAN_SPRITES		;6a67   ; Sprites 16, 17 y 18, las aranas
	jp nc,LE_HAN_DADO		;6a6a
	inc bc			;6a6d
	call CHOCAN_SPRITES		;6a6e
	jp nc,LE_HAN_DADO		;6a71
	inc bc			;6a74
	call CHOCAN_SPRITES		;6a75
	jp nc,LE_HAN_DADO		;6a78
	inc bc			;6a7b
	call CHOCAN_SPRITES		;6a7c   ; Cabeza contra la fruta
	jr c,CHOQUES_ABEJA_BOLA		;6a7f
	push bc			;6a81
	ld c,012h		;6a82   ; 200 puntos, la fruta desaparece, sonido 0x0A
	call COBRA_PUNTOS		;6a84
	ld a,0c8h		;6a87
	ld (0e0fch),a		;6a89
	ld a,00ah		;6a8c
	call SONIDO		;6a8e
	pop bc			;6a91
CHOQUES_ABEJA_BOLA:		; Cabeza contra la abeja y la bola que bota
	inc bc			;6a92   ; Sprite 20, la abeja
	call CHOCAN_SPRITES		;6a93
	jp nc,LE_HAN_DADO		;6a96
	inc bc			;6a99   ; Dos de golpe: el 21 es la otra mitad de la abeja
	inc bc			;6a9a
	call CHOCAN_SPRITES		;6a9b
	jp nc,LE_HAN_DADO		;6a9e
	ld bc,0060bh		;6aa1   ; Las piernas: contra los peces, bolas, aranas, la fruta no (salta el 19)...
	call CHOCAN_SPRITES		;6aa4
	jp nc,LE_HAN_DADO		;6aa7
	inc bc			;6aaa
	call CHOCAN_SPRITES		;6aab
	jp nc,LE_HAN_DADO		;6aae
	inc bc			;6ab1
	call CHOCAN_SPRITES		;6ab2
	jp nc,LE_HAN_DADO		;6ab5
	inc bc			;6ab8
	call CHOCAN_SPRITES		;6ab9   ; Sprites 14 y 15, las bolas
	jp nc,LE_HAN_DADO		;6abc
	inc bc			;6abf
	call CHOCAN_SPRITES		;6ac0
	jp nc,LE_HAN_DADO		;6ac3
	inc bc			;6ac6
	call CHOCAN_SPRITES		;6ac7   ; Sprites 16, 17 y 18, las aranas
	jp nc,LE_HAN_DADO		;6aca
	inc bc			;6acd
	call CHOCAN_SPRITES		;6ace
	jp nc,LE_HAN_DADO		;6ad1
	inc bc			;6ad4
	call CHOCAN_SPRITES		;6ad5
	jp nc,LE_HAN_DADO		;6ad8
	inc bc			;6adb   ; ...la abeja, la bola que bota...
	inc bc			;6adc
	call CHOCAN_SPRITES		;6add
	jp nc,LE_HAN_DADO		;6ae0
	inc bc			;6ae3   ; Otro salto de dos: del 20 al 22
	inc bc			;6ae4
	call CHOCAN_SPRITES		;6ae5
	jp nc,LE_HAN_DADO		;6ae8
	ld bc,0061fh		;6aeb   ; ...y la caja invisible de la piedra o la hoguera
	call CHOCAN_SPRITES		;6aee
	jp nc,LE_HAN_DADO		;6af1
COBRA_BOLAS_Y_ABEJA:		; Con los moviles activos: por pasar las dos bolas (E1AC, E1AD) y, si la abeja esta baja, tambien a ella (E1AE)
	ld a,(0e159h)		;6af4
	or a			;6af7
	ret z			;6af8
	ld a,(0e100h)		;6af9
	cp 074h		;6afc   ; Y=0x74 es donde se queda con la altura mas baja (0x72): solo entonces cuenta
	ld hl,0e1ach		;6afe   ; E1AC y E1AD son las X de las dos bolas, E1AE la de la abeja
	ld b,003h		;6b01
	jr z,L_6B07		;6b03
	ld b,002h		;6b05
L_6B07:
	ld c,010h		;6b07   ; Del 16 en adelante en la tabla de cobrados
	jp COBRA_AL_PASAR		;6b09

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LOS SPRITES DEL JUGADOR. Cuatro sprites: dos arriba (cabeza y torso,
; rojo y amarillo) y dos abajo (piernas, magenta y azul). La pose E136
; (0-6 mirando a la derecha; +7 a la izquierda) elige en 0x6B8A los
; cuatro patrones. Debajo, la sombra (sprite 8, patron 0xD4, negro) en
; Y=0x8C, o sobre la tabla del surtidor.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
PINTA_JUGADOR:		; Los cuatro sprites del jugador segun pose y lado, y la sombra
	ld a,(0e139h)		;6b0c
	cp 004h		;6b0f   ; Mirando a la izquierda: las poses 7-13
	jr nz,L_6B1A		;6b11
	ld hl,0e136h		;6b13
	ld a,(hl)			;6b16
	add a,007h		;6b17
	ld (hl),a			;6b19
L_6B1A:
	ld hl,0e134h		;6b1a   ; E134 y E135, la Y y la X del jugador, a B y C
	ld b,(hl)			;6b1d
	inc hl			;6b1e
	ld c,(hl)			;6b1f
	inc hl			;6b20
	ld a,(hl)			;6b21   ; E136, la pose, con el lado ya sumado
	push af			;6b22
	ld hl,0e0c0h		;6b23   ; E0C0 es el sprite 4: cabeza y torso. Las piernas son el 6 y el 7, 16 filas mas abajo
	bit 0,a		;6b26   ; Poses impares un punto mas abajo
	jr z,L_6B2B		;6b28
	inc b			;6b2a
L_6B2B:
	ld de,06b8ah		;6b2b   ; Cuatro patrones por pose
	add a,a			;6b2e
	add a,a			;6b2f
	call DE_MAS_A		;6b30
	call DOS_SPRITES		;6b33
	ld a,010h		;6b36
	add a,b			;6b38
	ld b,a			;6b39
	pop af			;6b3a
	cp 005h		;6b3b   ; La pose 5 (colgado) desplaza las piernas 4 a la derecha...
	jr nz,L_6B43		;6b3d
	inc c			;6b3f
	inc c			;6b40
	inc c			;6b41
	inc c			;6b42
L_6B43:
	cp 00ch		;6b43   ; ...y la 12 (colgado a la izquierda) 4 a la izquierda
	jr nz,L_6B4B		;6b45
	dec c			;6b47
	dec c			;6b48
	dec c			;6b49
	dec c			;6b4a
L_6B4B:
	call DOS_SPRITES		;6b4b
	ld a,(0e138h)		;6b4e
	cp 00fh		;6b51   ; Muriendo la sombra se queda como este
	ret nc			;6b53
	cp 001h		;6b54   ; En el aire, sin sombra; en la meta, en el suelo
	jr z,SIN_SOMBRA		;6b56
	cp 007h		;6b58
	jr z,SOMBRA_EN_EL_SUELO		;6b5a
	cp 003h		;6b5c   ; Sobre tabla o poste (estados 3+): sombra 16 por debajo
	ld a,08ch		;6b5e
	jr c,SOMBRA		;6b60
	ld a,010h		;6b62
	add a,b			;6b64
SOMBRA:		; Sprite 8: Y=A, X del jugador, patron 0xD4, negro; con Y>=0x48 se ve
	ld hl,0e0d0h		;6b65   ; E0D0 son los cuatro bytes del sprite 8
	ld (hl),a			;6b68
	inc hl			;6b69
	ld (hl),c			;6b6a
	inc hl			;6b6b
	ld (hl),0d4h		;6b6c   ; El patron 0xD4 es la mancha, en color 1 (negro)
	inc hl			;6b6e
	ld (hl),001h		;6b6f
	cp 048h		;6b71   ; Por encima de la fila 0x48 se queda sin color y no se ve
	ret nc			;6b73
SIN_SOMBRA:		; Color 0: no se ve
	xor a			;6b74
	ld (0e0d3h),a		;6b75
	ret			;6b78
SOMBRA_EN_EL_SUELO:		; Y=0x8C
	ld a,08ch		;6b79
	jr SOMBRA		;6b7b
DOS_SPRITES:		; Dos sprites seguidos con la misma Y,X y los dos patrones siguientes de DE
	call UN_SPRITE		;6b7d
UN_SPRITE:		; Y=B, X=C, patron (DE), y salta el color
	ld (hl),b			;6b80   ; Los cuatro bytes del sprite: Y, X, patron y color
	inc hl			;6b81
	ld (hl),c			;6b82
	inc hl			;6b83
	ld a,(de)			;6b84   ; El patron sale de la tabla que trae DE, y DE avanza
	inc de			;6b85
	ld (hl),a			;6b86
	inc hl			;6b87   ; El segundo inc hl salta el color, que no se toca
	inc hl			;6b88
	ret			;6b89

; ----------------------------------------------------------------------
; DATOS poses_del_jugador: Catorce poses de cuatro patrones (dos de arriba,
;   dos de abajo): 0-6 mirando a la derecha (parado, andando, saltando,
;   colgado...), 7-13 las mismas con los sprites espejados
;   0x6b8a..0x6bc2  (56 bytes)
DATA_poses_del_jugador:
	defb 000h,004h,00ch,010h	; 6b8a
	defb 000h,004h,014h,018h	; 6b8e
	defb 000h,004h,01ch,020h	; 6b92
	defb 000h,004h,01ch,020h	; 6b96
	defb 000h,008h,02ch,030h	; 6b9a
	defb 000h,008h,034h,038h	; 6b9e
	defb 000h,004h,024h,028h	; 6ba2
	defb 05ch,060h,068h,06ch	; 6ba6
	defb 05ch,060h,070h,074h	; 6baa
	defb 05ch,060h,078h,07ch	; 6bae
	defb 05ch,060h,078h,07ch	; 6bb2
	defb 05ch,064h,088h,08ch	; 6bb6
	defb 05ch,064h,090h,094h	; 6bba
	defb 05ch,060h,080h,084h	; 6bbe

; ======================================================================
; CODIGO 0x6bc2..0x6c06  (68 bytes)
; ======================================================================


PINTA_JUGADOR_MUERTO:		; Los sprites del jugador con la pose de muerte (0x6C06) segun hacia donde mira, y el color 8
	ld hl,0e134h		;6bc2   ; Y del jugador mas 16 y X menos 16
	ld a,(hl)			;6bc5
	add a,010h		;6bc6
	ld b,a			;6bc8
	inc hl			;6bc9
	ld a,(hl)			;6bca
	sub 010h		;6bcb
	ld c,a			;6bcd
	inc hl			;6bce
	ld a,(0e139h)		;6bcf   ; E139 es hacia donde mira
	cp 004h		;6bd2   ; Mirando a la izquierda: X+16 y la otra mitad de la tabla
	ld a,(hl)			;6bd4
	jr nz,L_6BE0		;6bd5
	dec hl			;6bd7
	ld a,(hl)			;6bd8
	add a,010h		;6bd9
	ld c,a			;6bdb
	inc hl			;6bdc
	ld a,(hl)			;6bdd
	add a,002h		;6bde
L_6BE0:
	ld de,06c06h		;6be0   ; La tabla de cuatro poses de cinco patrones
	ld l,a			;6be3
	add a,a			;6be4   ; El indice por 5; el bit 4 de E136 no estorba porque 16 por 5 es multiplo de 16
	add a,a			;6be5
	add a,l			;6be6
	and 00fh		;6be7
	call DE_MAS_A		;6be9
	ld hl,0e0c0h		;6bec   ; E0C0 es el sprite 4, la cabeza
	call DOS_SPRITES		;6bef
	push bc			;6bf2
	ld a,(0e135h)		;6bf3   ; Los sprites 6 y 7, en la X del jugador sin desplazar
	ld c,a			;6bf6
	call DOS_SPRITES		;6bf7
	pop bc			;6bfa
	ld a,b			;6bfb   ; El quinto patron 16 mas abajo, en el hueco del sprite 8 (la sombra)
	add a,010h		;6bfc
	ld b,a			;6bfe
	call UN_SPRITE		;6bff
	dec hl			;6c02
	ld (hl),008h		;6c03   ; Y a ese quinto sprite, el color 8
	ret			;6c05

; ----------------------------------------------------------------------
; DATOS poses_de_muerte: Cuatro poses de 5 patrones (los cuatro del jugador y
;   uno mas en el hueco de la sombra): dos mirando a la derecha, que alternan
;   cada 16 fotogramas, y sus espejos. Indice E136*5 modulo 16
;   0x6c06..0x6c1a  (20 bytes)
DATA_poses_de_muerte:
	defb 03ch,044h,048h,04ch,040h	; 6c06
	defb 03ch,044h,050h,054h,040h	; 6c0b
	defb 098h,0a0h,0a4h,0a8h,09ch	; 6c10
	defb 098h,0a0h,0ach,0b0h,09ch	; 6c15

; ======================================================================
; CODIGO 0x6c1a..0x6ce2  (200 bytes)
; ======================================================================


ARCO_SUBIENDO:		; Arranca el arco HL hacia arriba (E202=0): un salto
	xor a			;6c1a
	jr ARCO_ARRANCA		;6c1b
ARCO_CAYENDO:		; Arranca el arco HL hacia abajo (E202=1): una caida
	ld a,001h		;6c1d
ARCO_ARRANCA:		; E200 = HL, E202 = A, E205 = 0
	ld (0e200h),hl		;6c1f
	ld (0e202h),a		;6c22
	xor a			;6c25
	ld (0e205h),a		;6c26
	ret			;6c29
AGARRA_CUALQUIER_LIANA:		; Prueba con la 2 y con la 1
	ld hl,0e142h		;6c2a   ; E142 y E143, la Y y la X del cabo de la liana 2
	call CHOCA_CON_SPRITE		;6c2d   ; El jugador contra ese cabo, con la caja de 16x16 de 0x64F3
	jr nc,COLGADO		;6c30
	ld hl,0e140h		;6c32   ; Y si no la agarra, se prueba con la liana 1
	call CHOCA_CON_SPRITE		;6c35
	jr nc,COLGADO		;6c38
	jr PASO_DE_ARCO_JUGADOR		;6c3a   ; Ninguna de las dos: el salto sigue su arco

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; UN PASO DEL SALTO. Si puede agarrar (E144=0) y toca el cabo de una
; liana (E140 o E142), se cuelga (estado 2) y cobra sus puntos. Si no:
; cobra lo que haya saltado (E1A5-E1AB), avanza el arco (E200/E202) en Y,
; mueve la X segun la direccion guardada (E137: 2 puntos, o 1 saliendo
; de la liana), y al agotar el arco lo da la vuelta o lo termina.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
PASO_DE_SALTO:		; Liana si se puede; si no, un paso del arco
	ld a,(0e144h)		;6c3c
	or a			;6c3f   ; E144 distinto de 0: no puede agarrar
	jr nz,PASO_DE_ARCO_JUGADOR		;6c40
	ld hl,0e140h		;6c42
	ld a,(0e13ch)		;6c45
	bit 1,a		;6c48   ; E13C=2: viene de la liana 2 y solo puede agarrar la 1; a 0, cualquiera de las dos
	jr nz,AGARRA_LIANA		;6c4a
	ld hl,0e142h		;6c4c
	bit 0,a		;6c4f
	jr z,AGARRA_CUALQUIER_LIANA		;6c51
AGARRA_LIANA:		; Toca el cabo: cuelga
	call CHOCA_CON_SPRITE		;6c53
	jr c,PASO_DE_ARCO_JUGADOR		;6c56
COLGADO:		; E13C = que liana, cobra sus puntos, estado 2
	ld a,l			;6c58   ; Los dos bits bajos del puntero dicen cual de las dos lianas es
	and 003h		;6c59
	ld (0e13ch),a		;6c5b
	ld c,a			;6c5e
	call COBRA_PUNTOS		;6c5f   ; Sus puntos, por el indice de la tabla de cobrados
	ld a,002h		;6c62
	ld (0e138h),a		;6c64   ; Estado 2: colgado
PASO_DE_ARCO_JUGADOR:		; Cobra lo saltado y avanza el arco
	ld hl,0e1a5h		;6c67   ; Trampolines, charcos, piedra y hoguera (E1A5-E1AB)
	ld b,007h		;6c6a   ; Siete obstaculos, del 9 al 15 de la tabla de cobrados
	ld c,009h		;6c6c
	call COBRA_AL_PASAR		;6c6e
	ld a,(0e202h)		;6c71   ; Bit 0 de E202: hacia donde va el arco del salto
	ld b,a			;6c74
	ld hl,0e205h		;6c75
	bit 0,b		;6c78
	jr nz,L_6C7F		;6c7a
	inc (hl)			;6c7c   ; E205 es el paso dentro del arco
	jr L_6C80		;6c7d
L_6C7F:
	dec (hl)			;6c7f
L_6C80:
	ld a,(hl)			;6c80
	cp 008h		;6c81   ; Pose 6 los primeros 8 fotogramas, luego la 4
	ld a,006h		;6c83
	jr c,L_6C89		;6c85
	ld a,004h		;6c87
L_6C89:
	ld (0e136h),a		;6c89
	ld hl,0e134h		;6c8c
	ld de,(0e200h)		;6c8f
	bit 0,b		;6c93
	ld a,(de)			;6c95   ; Y mas o menos el delta
	jr nz,L_6C9A		;6c96
	neg		;6c98
L_6C9A:
	add a,(hl)			;6c9a   ; La Y del jugador
	ld (hl),a			;6c9b
	inc hl			;6c9c
	ld a,(0e137h)		;6c9d   ; E137: izquierda o derecha, guardadas al saltar
	or a			;6ca0
	jr z,ARCO_JUGADOR_AVANZA		;6ca1
	ld c,a			;6ca3
	ld a,(0e144h)		;6ca4   ; Saliendo de la liana (E144=0xFF), dos puntos por fotograma
	inc a			;6ca7
	jr nz,L_6CB6		;6ca8
	bit 3,c		;6caa   ; Bit 3: hacia la derecha
	jr z,L_6CB2		;6cac
	inc (hl)			;6cae
	inc (hl)			;6caf
	jr ARCO_JUGADOR_AVANZA		;6cb0
L_6CB2:
	dec (hl)			;6cb2
	dec (hl)			;6cb3
	jr ARCO_JUGADOR_AVANZA		;6cb4
L_6CB6:
	bit 3,c		;6cb6   ; Si no, uno
	jr z,L_6CBD		;6cb8
	inc (hl)			;6cba
	jr ARCO_JUGADOR_AVANZA		;6cbb
L_6CBD:
	dec (hl)			;6cbd
ARCO_JUGADOR_AVANZA:		; Puntero adelante (subiendo) o atras (bajando); 0xFF da la vuelta y E144+1 (desde el suelo ya no se agarra liana bajando; desde otra liana, 0xFF pasa a 0 y si); 0xFE termina
	ex de,hl			;6cbe
	bit 0,b		;6cbf
	jr nz,L_6CC6		;6cc1
	inc hl			;6cc3
	jr L_6CC7		;6cc4
L_6CC6:
	dec hl			;6cc6
L_6CC7:
	ld a,(hl)			;6cc7   ; 0xFF cierra la tabla por el lado de subir
	ld b,a			;6cc8
	inc a			;6cc9
	jr nz,L_6CDC		;6cca
	dec hl			;6ccc   ; Dos atras: se vuelve al ultimo valor bueno
	dec hl			;6ccd
	push hl			;6cce
	ld hl,0e144h		;6ccf
	inc (hl)			;6cd2   ; E144 sube: sale del 0xFF y ya se puede agarrar otra liana
	pop hl			;6cd3
	inc a			;6cd4
	ld (0e202h),a		;6cd5   ; E202 = 1: el arco se recorre al reves, cayendo
L_6CD8:
	ld (0e200h),hl		;6cd8
	ret			;6cdb
L_6CDC:
	inc a			;6cdc   ; 0xFE es el tope de abajo: se vuelve al primer valor y el paso se repite sin fin
	jr nz,L_6CD8		;6cdd
	inc hl			;6cdf
	jr L_6CD8		;6ce0

; ----------------------------------------------------------------------
; DATOS arco_de_hundirse: El arco medio: 2 1 2 1 2 1 1 1 1 1 1 1 0 1 0 0. Lo
;   usan hundirse y la bola que rueda con el bit 1 de E158
;   0x6ce2..0x6cf2  (16 bytes)
DATA_arco_de_hundirse:
	defb 0feh,002h,001h,002h,001h,002h,001h,001h,001h,001h,001h,001h,001h,000h,001h,000h	; 6ce2  ................

; ----------------------------------------------------------------------
; DATOS arco_corto: El arco corto: 4 4 3 3 3 3 2 2 2 2 1 1 1 1 0 0. El salto
;   normal, el bote sin boton, y caer de tabla o poste
;   0x6cf2..0x6d06  (20 bytes)
DATA_arco_corto:
	defb 000h,0ffh,0feh,004h,004h,003h,003h,003h,003h,002h,002h,002h,002h,001h,001h,001h	; 6cf2  ................
	defb 001h,000h,000h,0ffh	; 6d02

; ======================================================================
; CODIGO 0x6d06..0x6dd4  (206 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; ESTADO 2: COLGADO DE LA LIANA. Sigue al cabo (E140 o E142), pose 5;
; con abajo se suelta (estado 1, arco corto cayendo, E144=1); con el
; boton salta (arco cortito desde 0x6CED, sonido 3, E144=0xFF), y
; mirando a la izquierda la pose 12.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
ESTADO_2_LIANA:		; Colgado del cabo de la liana
	ld hl,0e140h		;6d06
	ld a,(0e13ch)		;6d09
	bit 1,a		;6d0c   ; Bit 1 de E13C: la liana 2
	jr z,L_6D13		;6d0e
	ld hl,0e142h		;6d10
L_6D13:
	ld b,(hl)			;6d13   ; El cabo de la liana: Y en B, X en C
	inc hl			;6d14
	ld c,(hl)			;6d15
	ld hl,0e134h		;6d16   ; El jugador se pega al cabo
	ld (hl),b			;6d19
	inc hl			;6d1a
	ld a,(0e139h)		;6d1b
	cp 004h		;6d1e
	ld a,c			;6d20
	jr nz,L_6D26		;6d21
	add a,00eh		;6d23   ; Mirando a la izquierda, 14 mas a la derecha
	ld c,a			;6d25
L_6D26:
	ld (hl),a			;6d26
	inc hl			;6d27
	ld (hl),005h		;6d28   ; Pose 5: colgado
	ld a,(0e009h)		;6d2a   ; E009, lo que se pulsa en este fotograma
	ld b,a			;6d2d
	bit 1,a		;6d2e   ; Abajo: se suelta
	jr z,L_6D43		;6d30
	ld hl,06cf2h		;6d32   ; Al soltarse, el arco corto de 0x6CF2
	call ARCO_CAYENDO		;6d35
	ld a,001h		;6d38
	ld (0e138h),a		;6d3a   ; Estado 1 (en el aire) y E144=1: soltado desde liana
	ld (0e144h),a		;6d3d
L_6D40:
	jp MOVIMIENTO_COMUN		;6d40
L_6D43:
	and 00ch		;6d43   ; Izquierda o derecha guardadas para el salto
	ld (0e137h),a		;6d45
	call SALTA_SI_BOTON		;6d48
	jr nc,L_6D40		;6d4b
	ld hl,06cedh		;6d4d   ; El arco cortito de 0x6CED, el impulso del salto
	call ARCO_SUBIENDO		;6d50
	ld a,001h		;6d53
	ld (0e138h),a		;6d55
	ld a,003h		;6d58
	call SONIDO		;6d5a
	ld a,0ffh		;6d5d   ; E144 = 0xFF: acaba de saltar de una liana
	ld (0e144h),a		;6d5f
	ld a,(0e139h)		;6d62
	cp 004h		;6d65
	jr nz,L_6D70		;6d67
	ld hl,0e136h		;6d69   ; Mirando a la izquierda, seis poses mas alla: las espejadas
	ld a,(hl)			;6d6c
	add a,006h		;6d6d
	ld (hl),a			;6d6f
L_6D70:
	jr L_6D40		;6d70
ANDA:		; Izquierda o derecha: un paso (X mas o menos 1), sonido 2, mirada, y la pose por los pasos (E13B); parado, pose 6
	xor a			;6d72
	ld (0e144h),a		;6d73   ; E144 a cero: desde el suelo no se agarra liana
	ld (0e13ch),a		;6d76
	ld a,(0e009h)		;6d79   ; Bits 2 y 3 de lo pulsado: izquierda y derecha
	and 00ch		;6d7c
	ld (0e137h),a		;6d7e
	ld hl,0e135h		;6d81
	ld de,0e13bh		;6d84   ; E13B cuenta los pasos; de el sale la pose
	jr nz,L_6D8D		;6d87
	ld a,006h		;6d89   ; Parado: pose 6
	jr L_6DA7		;6d8b
L_6D8D:
	ex de,hl			;6d8d   ; Un paso mas
	inc (hl)			;6d8e
	ex de,hl			;6d8f
	ld (0e139h),a		;6d90
	bit 3,a		;6d93
	jr z,L_6D9A		;6d95
	inc (hl)			;6d97
	jr L_6D9B		;6d98
L_6D9A:
	dec (hl)			;6d9a
L_6D9B:
	push hl			;6d9b
	ld a,002h		;6d9c   ; Sonido de pisada
	call SONIDO		;6d9e
	pop hl			;6da1
	ld a,(de)			;6da2   ; Pose 0-3 por los bits 2-3 de los pasos
	and 00ch		;6da3
	rrca			;6da5
	rrca			;6da6
L_6DA7:
	inc hl			;6da7
	ld (hl),a			;6da8
	ret			;6da9
SALTA_SI_BOTON:		; Acarreo si se acaba de pulsar espacio o SELECT (bits 4-5, ahora si y antes no); guarda la altura segura E13A: la del jugador sobre un surtidor de en medio, o 16 mas abajo
	ld hl,0e008h		;6daa
	ld a,(hl)			;6dad
	cpl			;6dae   ; Los botones de antes al reves: los que estaban sueltos
	and 030h		;6daf
	inc hl			;6db1
	and (hl)			;6db2   ; Y ahora pulsados: cuenta el flanco, no que este apretado
	ret z			;6db3
	ld a,(0e134h)		;6db4   ; E134, la Y desde la que arranca el salto
	ld b,a			;6db7
	ld a,(0e138h)		;6db8
	cp 004h		;6dbb   ; Sobre un surtidor y entre X=0x48 y 0x9F: la altura es la de la tabla
	jr nz,L_6DCA		;6dbd
	ld a,(0e135h)		;6dbf
	cp 0a0h		;6dc2
	jr nc,L_6DCA		;6dc4
	cp 048h		;6dc6
	jr nc,L_6DCE		;6dc8
L_6DCA:
	ld a,010h		;6dca   ; Si no, 16 por debajo (el suelo)
	add a,b			;6dcc
	ld b,a			;6dcd
L_6DCE:
	ld a,b			;6dce
	ld (0e13ah),a		;6dcf
	scf			;6dd2   ; Acarreo: hay salto
	ret			;6dd3

; ----------------------------------------------------------------------
; DATOS fondo_lista_cielo: Lista del motor: los cielos de las filas 3-8
;   (0x6DD4)
;   0x6dd4..0x6ddb  (7 bytes)
DATA_fondo_lista_cielo:
	defb 0a0h,0a0h,0a0h,0a0h,020h,0c0h,000h	; 6dd4

; ----------------------------------------------------------------------
; DATOS fondo_lista_hierba: Lista: la hierba de la fila 15 (0x6DDB); 0x6DDF la
;   del seto y la hierba
;   0x6ddb..0x6ddf  (4 bytes)
DATA_fondo_lista_hierba:
	defb 0d0h,0d0h,0a0h,000h	; 6ddb

; ----------------------------------------------------------------------
; DATOS fondo_lista_seto: Lista: el seto de las filas 10-12 y la hierba
;   0x6ddf..0x6de2  (3 bytes)
DATA_fondo_lista_seto:
	defb 060h,0a0h,0a0h	; 6ddf

; ----------------------------------------------------------------------
; DATOS fondo_lista_hierba_15: Lista: la hierba de la fila 15 (decorado
;   normal)
;   0x6de2..0x6de4  (2 bytes)
DATA_fondo_lista_hierba_15:
	defb 0a0h,000h	; 6de2

; ----------------------------------------------------------------------
; DATOS fondo_lista_tierra: Lista: la tierra de las filas 16-19
;   0x6de4..0x6de8  (4 bytes)
DATA_fondo_lista_tierra:
	defb 0e0h,0a0h,0a0h,000h	; 6de4

; ----------------------------------------------------------------------
; DATOS fondo_lista_estanque: Lista: el estanque, filas 16-18
;   0x6de8..0x6df8  (16 bytes)
DATA_fondo_lista_estanque:
	defb 003h,088h,003h,080h,027h,03ah,007h,084h,007h,080h,049h,03ah,003h,088h,003h,000h	; 6de8  ....':....I:....

; ----------------------------------------------------------------------
; DATOS fondo_lista_child_park: Lista: el rotulo CHILD PARK con su marco de
;   ladrillo, filas 9-14
;   0x6df8..0x6e2a  (50 bytes)
DATA_fondo_lista_child_park:
	defb 082h,080h,02ch,039h,082h,080h,02fh,039h,082h,080h,032h,039h,082h,080h,035h,039h	; 6df8  ..,9../9..29..59
	defb 082h,080h,049h,039h,00eh,080h,069h,039h,001h,08ch,001h,080h,089h,039h,00eh,080h	; 6e08  ..I9..i9.....9..
	defb 0a9h,039h,001h,08ch,001h,080h,0c9h,039h,08eh,080h,0e9h,039h,08eh,080h,009h,03ah	; 6e18  .9.....9...9...:
	defb 08eh,000h	; 6e28

; ----------------------------------------------------------------------
; DATOS fondo_lista_cerro_izq: Lista: el cerro con pendiente de la izquierda
;   0x6e2a..0x6e44  (26 bytes)
DATA_fondo_lista_cerro_izq:
	defb 090h,080h,060h,038h,08eh,002h,080h,080h,038h,08dh,003h,080h,0a6h,038h,001h,084h	; 6e2a  ..`8....8....8..
	defb 002h,080h,0c6h,038h,006h,080h,0e8h,038h,002h,000h	; 6e3a  ...8...8..

; ----------------------------------------------------------------------
; DATOS fondo_lista_cerro_der: Lista: el cerro con pendiente de la derecha
;   0x6e44..0x6e5e  (26 bytes)
DATA_fondo_lista_cerro_der:
	defb 090h,080h,070h,038h,002h,08eh,080h,090h,038h,003h,08eh,080h,0b3h,038h,002h,084h	; 6e44  ..p8....8....8..
	defb 001h,080h,0d4h,038h,006h,080h,0f6h,038h,003h,000h	; 6e54  ...8...8..

; ----------------------------------------------------------------------
; DATOS fondo_lista_meseta_izq: Lista: la meseta de la izquierda
;   0x6e5e..0x6e77  (25 bytes)
DATA_fondo_lista_meseta_izq:
	defb 090h,080h,060h,038h,08fh,001h,080h,080h,038h,08eh,002h,080h,0a8h,038h,084h,002h	; 6e5e  ..`8....8....8..
	defb 080h,0c8h,038h,005h,080h,0e9h,038h,002h,000h	; 6e6e  ..8...8..

; ----------------------------------------------------------------------
; DATOS fondo_lista_meseta_der: Lista: la meseta de la derecha
;   0x6e77..0x6e90  (25 bytes)
DATA_fondo_lista_meseta_der:
	defb 090h,080h,070h,038h,002h,08eh,080h,090h,038h,003h,08dh,080h,0b3h,038h,002h,083h	; 6e77  ..p8....8....8..
	defb 080h,0d4h,038h,004h,080h,0f6h,038h,002h,000h	; 6e87  ..8...8..

; ----------------------------------------------------------------------
; DATOS fondo_tiles_cielo_azul_amarillo: Tiles: cielo azul con cerros
;   amarillos
;   0x6e90..0x6eb5  (37 bytes)
DATA_fondo_tiles_cielo_azul_amarillo:
	defb 01ch,01dh,01eh,01fh,068h,069h,06ah,065h,066h,069h,06ah,060h,064h,060h,061h,062h	; 6e90  ....hijefij`d`ab
	defb 063h,064h,065h,066h,067h,001h,068h,069h,06ah,060h,064h,060h,061h,063h,064h,065h	; 6ea0  cdefg.hij`d`acde
	defb 066h,067h,068h,069h,001h	; 6eb0

; ----------------------------------------------------------------------
; DATOS fondo_tiles_cielo_azul_verde: Tiles: cielo azul con cerros verdes
;   0x6eb5..0x6eda  (37 bytes)
DATA_fondo_tiles_cielo_azul_verde:
	defb 01ch,01dh,01eh,01fh,07eh,07fh,080h,07bh,07ch,07fh,080h,076h,07ah,076h,077h,078h	; 6eb5  ....~..{|..vzvwx
	defb 079h,07ah,07bh,07ch,07dh,00ah,07eh,07fh,080h,076h,07ah,076h,077h,079h,07ah,07bh	; 6ec5  yz{|}.~..vzvwyz{
	defb 07ch,07dh,07eh,07fh,00ah	; 6ed5

; ----------------------------------------------------------------------
; DATOS fondo_tiles_cielo_rojo_blanco: Tiles: cielo rojo con cerros blancos
;   0x6eda..0x6eff  (37 bytes)
DATA_fondo_tiles_cielo_rojo_blanco:
	defb 08ch,08dh,08eh,08fh,073h,074h,075h,070h,071h,074h,075h,06bh,06fh,06bh,06ch,06dh	; 6eda  ....stupqtukoklm
	defb 06eh,06fh,070h,071h,072h,001h,073h,074h,075h,06bh,06fh,06bh,06ch,06eh,06fh,070h	; 6eea  nopqr.stukoklnop
	defb 071h,072h,073h,074h,001h	; 6efa

; ----------------------------------------------------------------------
; DATOS fondo_tiles_cielo_rojo_verde: Tiles: cielo rojo con cerros verdes
;   0x6eff..0x6f24  (37 bytes)
DATA_fondo_tiles_cielo_rojo_verde:
	defb 08ch,08dh,08eh,08fh,089h,08ah,08bh,086h,087h,08ah,08bh,081h,085h,081h,082h,083h	; 6eff  ................
	defb 084h,085h,086h,087h,088h,00ah,089h,08ah,08bh,081h,085h,081h,082h,084h,085h,086h	; 6f0f  ................
	defb 087h,088h,089h,08ah,00ah	; 6f1f

; ----------------------------------------------------------------------
; DATOS fondo_tiles_hierba: Tiles: la hierba
;   0x6f24..0x6f27  (3 bytes)
DATA_fondo_tiles_hierba:
	defb 001h,001h,00bh	; 6f24

; ----------------------------------------------------------------------
; DATOS fondo_tiles_seto: Tiles: el seto (con la hierba al final, en 0x6F8A)
;   0x6f27..0x6f8a  (99 bytes)
DATA_fondo_tiles_seto:
	defb 09ch,09ch,09ch,09ch,09ch,09ch,09ch,09ch,09fh,09ch,0a0h,0a1h,0a2h,0a3h,0a4h,0a5h	; 6f27  ................
	defb 0deh,0ddh,0dch,0dbh,0dah,0d9h,09ch,0d8h,09ch,09ch,09ch,09ch,09ch,09ch,09ch,09ch	; 6f37  ................
	defb 09dh,09dh,09dh,09dh,09dh,09dh,0a6h,09dh,0a7h,09dh,0a6h,0a8h,09dh,0a9h,0aah,09dh	; 6f47  ................
	defb 09dh,0e3h,0e2h,09dh,0e1h,0dfh,09dh,0e0h,09dh,0dfh,09dh,09dh,09dh,09dh,09dh,09dh	; 6f57  ................
	defb 09eh,09eh,09eh,0abh,09eh,09eh,09eh,09eh,0abh,09eh,09eh,09eh,09eh,0abh,09eh,09eh	; 6f67  ................
	defb 09eh,09eh,0e4h,09eh,09eh,09eh,09eh,0e4h,09eh,09eh,09eh,09eh,0e4h,09eh,09eh,09eh	; 6f77  ................
	defb 09eh,008h,00ch	; 6f87

; ----------------------------------------------------------------------
; DATOS fondo_tiles_hierba_15: El tile de la hierba del decorado normal
;   0x6f8a..0x6f8b  (1 bytes)
DATA_fondo_tiles_hierba_15:
	defb 00bh	; 6f8a

; ----------------------------------------------------------------------
; DATOS fondo_tiles_tierra: Tiles: la tierra
;   0x6f8b..0x6f8e  (3 bytes)
DATA_fondo_tiles_tierra:
	defb 007h,0c0h,00ch	; 6f8b

; ----------------------------------------------------------------------
; DATOS fondo_tiles_estanque: Tiles: el estanque
;   0x6f8e..0x6fab  (29 bytes)
DATA_fondo_tiles_estanque:
	defb 0c5h,0c6h,0c6h,0c7h,0c6h,0c6h,0c5h,0c1h,0c9h,0cah,003h,003h,003h,003h,003h,003h	; 6f8e  ................
	defb 003h,003h,003h,0cah,0c9h,0c8h,0c2h,0c3h,0c3h,0c4h,0c3h,0c3h,0c2h	; 6f9e  .............

; ----------------------------------------------------------------------
; DATOS bloque_trampolin: Los cuatro tiles del trampolin (0xD1 0xD2 / 0xD3
;   0xD4)
;   0x6fab..0x6faf  (4 bytes)
DATA_bloque_trampolin:
	defb 0d1h,0d2h	; 6fab
	defb 0d3h,0d4h	; 6fad

; ----------------------------------------------------------------------
; DATOS bloque_charco: Los dos tiles del charco (0xCF 0xD0)
;   0x6faf..0x6fb1  (2 bytes)
DATA_bloque_charco:
	defb 0cfh,0d0h	; 6faf

; ----------------------------------------------------------------------
; DATOS bloque_poste_verde_bajo: Poste bajo de 3x2 (0xEC 0xEC / 0xD9 0xD9 /
;   0xDA 0xDA)
;   0x6fb1..0x6fb7  (6 bytes)
DATA_bloque_poste_verde_bajo:
	defb 0ech,0ech	; 6fb1
	defb 0d9h,0d9h	; 6fb3
	defb 0dah,0dah	; 6fb5

; ----------------------------------------------------------------------
; DATOS bloque_poste_azul: Poste alto de 4x2, azul
;   0x6fb7..0x6fbf  (8 bytes)
DATA_bloque_poste_azul:
	defb 0edh,0eeh	; 6fb7
	defb 0efh,003h	; 6fb9
	defb 0efh,003h	; 6fbb
	defb 0dch,0ddh	; 6fbd

; ----------------------------------------------------------------------
; DATOS bloque_poste_verde_alto: Poste alto de 4x2, verde
;   0x6fbf..0x6fc7  (8 bytes)
DATA_bloque_poste_verde_alto:
	defb 0f0h,0f1h	; 6fbf
	defb 0f2h,008h	; 6fc1
	defb 0e0h,008h	; 6fc3
	defb 0e1h,0e2h	; 6fc5

; ----------------------------------------------------------------------
; DATOS bloque_poste_rojo: Poste alto de 4x2, rojo
;   0x6fc7..0x6fcf  (8 bytes)
DATA_bloque_poste_rojo:
	defb 0f3h,0f4h	; 6fc7
	defb 0f5h,004h	; 6fc9
	defb 0f5h,004h	; 6fcb
	defb 0e4h,0e5h	; 6fcd

; ----------------------------------------------------------------------
; DATOS fondo_tiles_child_park: Tiles: CHILD PARK y su marco
;   0x6fcf..0x6ff9  (42 bytes)
DATA_fondo_tiles_child_park:
	defb 00dh,00dh,00dh,00dh,00dh,00eh,00eh,00dh,00eh,00eh,00dh,00eh,00eh,00dh,00eh,00eh	; 6fcf  ................
	defb 00dh,00eh,00eh,00eh,00fh,00eh,00eh,003h,043h,048h,049h,04ch,044h,003h,050h,041h	; 6fdf  ........CHILD.PA
	defb 052h,04bh,003h,00eh,00eh,010h,00eh,00eh,00eh,00eh	; 6fef  RK........

; ----------------------------------------------------------------------
; DATOS fondo_tiles_cerro_izq: Tiles del cerro con pendiente de la izquierda
;   0x6ff9..0x700d  (20 bytes)
DATA_fondo_tiles_cerro_izq:
	defb 0abh,002h,0a8h,0a8h,002h,0a9h,090h,090h,09ah,002h,0a8h,0a9h,09fh,092h,0a8h,0ach	; 6ff9  ................
	defb 0a9h,091h,090h,000h	; 7009

; ----------------------------------------------------------------------
; DATOS bloque_cerro_3x6: Bloque de 3x6 de la pendiente (0x5EBE)
;   0x700d..0x701f  (18 bytes)
DATA_bloque_cerro_3x6:
	defb 094h,095h,096h,097h,098h,099h	; 700d
	defb 09ch,09dh,09eh,0a2h,0a0h,0a1h	; 7013
	defb 0a3h,0a4h,004h,004h,0a5h,0a6h	; 7019

; ----------------------------------------------------------------------
; DATOS bloque_cerro_8x4: Bloque de 8x4 de la pendiente (0x5EB9)
;   0x701f..0x703f  (32 bytes)
DATA_bloque_cerro_8x4:
	defb 020h,004h,021h,000h	; 701f
	defb 022h,004h,023h,000h	; 7023
	defb 024h,004h,025h,000h	; 7027
	defb 026h,004h,027h,000h	; 702b
	defb 028h,004h,029h,000h	; 702f
	defb 000h,02ah,004h,02bh	; 7033
	defb 000h,02ch,004h,02dh	; 7037
	defb 00bh,02eh,02eh,02eh	; 703b

; ----------------------------------------------------------------------
; DATOS fondo_tiles_cerro_der: Tiles del cerro con pendiente de la derecha
;   0x703f..0x7054  (21 bytes)
DATA_fondo_tiles_cerro_der:
	defb 0abh,0a8h,0a8h,002h,090h,090h,0aah,002h,0aah,0a8h,002h,093h,091h,0aah,0ach,0ach	; 703f  ................
	defb 0a7h,09bh,000h,000h,090h	; 704f

; ----------------------------------------------------------------------
; DATOS fondo_tiles_meseta_izq: Tiles de la meseta de la izquierda
;   0x7054..0x7064  (16 bytes)
DATA_fondo_tiles_meseta_izq:
	defb 0abh,002h,0a8h,002h,0a9h,090h,002h,0a8h,0a9h,092h,0ach,0ach,0a9h,091h,000h,000h	; 7054  ................

; ----------------------------------------------------------------------
; DATOS bloque_meseta_3x8: Bloque de 3x8 de la meseta (0x5EC3)
;   0x7064..0x707c  (24 bytes)
DATA_bloque_meseta_3x8:
	defb 002h,093h,094h,095h,096h,098h,099h,09ah	; 7064  ........
	defb 0a7h,09bh,09ch,09dh,0a2h,0a0h,0a1h,09fh	; 706c  ........
	defb 090h,000h,0a3h,0a4h,004h,0a5h,0a6h,000h	; 7074  ........

; ----------------------------------------------------------------------
; DATOS bloque_meseta_8x3: Bloque de 8x3 de la meseta (0x5EFB)
;   0x707c..0x7094  (24 bytes)
DATA_bloque_meseta_8x3:
	defb 020h,021h,000h	; 707c
	defb 022h,023h,000h	; 707f
	defb 024h,025h,000h	; 7082
	defb 026h,027h,000h	; 7085
	defb 028h,029h,000h	; 7088
	defb 000h,02ah,02bh	; 708b
	defb 000h,02ch,02dh	; 708e
	defb 00bh,02eh,02eh	; 7091

; ----------------------------------------------------------------------
; DATOS fondo_tiles_meseta_der: Tiles de la meseta de la derecha
;   0x7094..0x70a5  (17 bytes)
DATA_fondo_tiles_meseta_der:
	defb 0abh,0a8h,0a8h,002h,090h,090h,0aah,002h,0aah,0a8h,002h,091h,0aah,0ach,0ach,000h	; 7094  ................
	defb 000h	; 70a4

; ======================================================================
; CODIGO 0x70a5..0x70f3  (78 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LOS PATRONES Y COLORES DEL JUEGO. Los patrones van a la VRAM 0x2000
; por trozos (y once tiles se repiten cuatro veces en 0x60-0x8B para
; tener el mismo dibujo con cuatro colores). Los COLORES los escribe el
; propio motor de rotulos en la tabla de colores (0x0000): las listas
; de 0x714F son colores, no tiles. Los de 0x60-0x75 se copian tal cual a
; 0x0300 y, cambiando el negro por verde claro, a 0x03B0 (0x76-0x8B).
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
CARGA_PATRONES_Y_COLORES:		; Patrones a 0x2000 y colores a 0x0000, estos ultimos por el motor de rotulos
	ld hl,073b0h		;70a5   ; 18 tiles 0x0A-0x1B
	ld de,02050h		;70a8
	ld bc,00090h		;70ab
	call COPIA_A_VRAM		;70ae
	ld hl,07440h		;70b1   ; 16 tiles 0x20-0x2F
	ld de,02100h		;70b4
	ld bc,00080h		;70b7
	call COPIA_A_VRAM		;70ba
	ld hl,074c0h		;70bd   ; Once tiles, cuatro veces: 0x60-0x8B
	ld de,02300h		;70c0
	ld b,004h		;70c3
L_70C5:
	push bc			;70c5
	push hl			;70c6
	push de			;70c7
	ld bc,00058h		;70c8
	call COPIA_A_VRAM		;70cb
	pop de			;70ce
	ld a,058h		;70cf
	call DE_MAS_A		;70d1
	pop hl			;70d4
	pop bc			;70d5
	djnz L_70C5		;70d6
	ld hl,07518h		;70d8   ; 30 tiles 0x90-0xAD
	ld de,02480h		;70db
	ld bc,000f0h		;70de
	call COPIA_A_VRAM		;70e1
	ld hl,07608h		;70e4   ; 62 tiles 0xC0-0xFD
	ld de,02600h		;70e7
	ld bc,001f0h		;70ea
	call COPIA_A_VRAM		;70ed
	call MOTOR_DE_ROTULOS		;70f0   ; Colores desde el tile 1

; ----------------------------------------------------------------------
; DATOS parametros_de_70F0: Lista 0x714F, colores 0x71E3, VRAM 0x0008 (colores
;   del tile 1 en adelante)
;   0x70f3..0x70f9  (6 bytes)
DATA_parametros_de_70F0:
	defw 0714fh,071e3h,00008h	; 70f3  -> DATA_colores_lista_01 DATA_colores_01 0x0008

; ======================================================================
; CODIGO 0x70f9..0x70fc  (3 bytes)
; ======================================================================


	call MOTOR_DE_ROTULOS		;70f9   ; Colores desde el tile 0x20

; ----------------------------------------------------------------------
; DATOS parametros_de_70F9: Lista 0x7172, colores 0x7237, VRAM 0x0100 (del
;   tile 0x20)
;   0x70fc..0x7102  (6 bytes)
DATA_parametros_de_70F9:
	defw 07172h,07237h,00100h	; 70fc  -> DATA_colores_lista_20 DATA_colores_20 0x0100

; ======================================================================
; CODIGO 0x7102..0x713f  (61 bytes)
; ======================================================================


	ld hl,0723ah		;7102   ; Colores de 0x60-0x75 tal cual...
	ld de,00300h		;7105
	ld bc,000b0h		;7108
	call COPIA_A_VRAM		;710b
	ld hl,0723ah		;710e   ; ...y para 0x76-0x8B con el negro (1) cambiado por verde claro (3), tinta y fondo
	ld de,003b0h		;7111
	ld b,0b0h		;7114
L_7116:
	push bc			;7116   ; B lleva la cuenta de los 0xB0 bytes y hace falta A: se guarda
	ld a,0f0h		;7117   ; El nibble alto, la tinta
	and (hl)			;7119
	cp 010h		;711a   ; Tinta 1, negro, pasa a 3, verde claro
	jr nz,L_7120		;711c
	ld a,030h		;711e   ; Las demas tintas se copian tal cual
L_7120:
	ld b,a			;7120   ; La tinta, cambiada o no, se aparca en B
	ld a,00fh		;7121   ; Y ahora el nibble bajo, el fondo
	and (hl)			;7123
	cp 001h		;7124   ; El mismo cambio: fondo 1 pasa a 3
	jr nz,L_712A		;7126   ; Y si no es negro, se queda como esta
	ld a,003h		;7128
L_712A:
	or b			;712a
	call VPOKE		;712b
	inc de			;712e
	inc hl			;712f
	pop bc			;7130
	djnz L_7116		;7131
	ld hl,072eah		;7133   ; Colores de 0x8C-0x8F
	ld bc,00020h		;7136
	call COPIA_A_VRAM		;7139
	call MOTOR_DE_ROTULOS		;713c   ; Colores desde el tile 0x90

; ----------------------------------------------------------------------
; DATOS parametros_de_713C: Lista 0x7176, colores 0x730A, VRAM 0x0480 (del
;   tile 0x90)
;   0x713f..0x7145  (6 bytes)
DATA_parametros_de_713C:
	defw 07176h,0730ah,00480h	; 713f  -> DATA_colores_lista_90 DATA_colores_90 0x0480

; ======================================================================
; CODIGO 0x7145..0x7148  (3 bytes)
; ======================================================================


	call MOTOR_DE_ROTULOS		;7145   ; Colores desde el tile 0xC0

; ----------------------------------------------------------------------
; DATOS parametros_de_7145: Lista 0x719D, colores 0x7336, VRAM 0x0600 (del
;   tile 0xC0)
;   0x7148..0x714e  (6 bytes)
DATA_parametros_de_7145:
	defw 0719dh,07336h,00600h	; 7148  -> DATA_colores_lista_C0 DATA_colores_C0 0x0600

; ======================================================================
; CODIGO 0x714e..0x714f  (1 bytes)
; ======================================================================


	ret			;714e

; ----------------------------------------------------------------------
; DATOS colores_lista_01: Lista del motor para los colores de los tiles
;   0x01-0x1F
;   0x714f..0x7172  (35 bytes)
DATA_colores_lista_01:
	defb 088h,088h,088h,088h,088h,088h,088h,088h,088h,088h,088h,088h,084h,014h,084h,083h	; 714f  ................
	defb 001h,082h,085h,083h,085h,083h,085h,089h,086h,085h,08bh,085h,085h,088h,084h,084h	; 715f  ................
	defb 088h,020h,000h	; 716f

; ----------------------------------------------------------------------
; DATOS colores_lista_20: Lista para los colores de 0x20-0x2F
;   0x7172..0x7176  (4 bytes)
DATA_colores_lista_20:
	defb 0f0h,088h,088h,000h	; 7172

; ----------------------------------------------------------------------
; DATOS colores_lista_90: Lista para los colores de 0x90-0xAD
;   0x7176..0x719d  (39 bytes)
DATA_colores_lista_90:
	defb 090h,086h,002h,002h,086h,002h,086h,002h,086h,001h,087h,083h,085h,002h,086h,002h	; 7176  ................
	defb 086h,085h,088h,083h,085h,083h,083h,085h,08fh,001h,083h,001h,084h,084h,0ach,093h	; 7186  ................
	defb 085h,083h,08ah,088h,083h,088h,000h	; 7196

; ----------------------------------------------------------------------
; DATOS colores_lista_C0: Lista para los colores de 0xC0-0xFD
;   0x719d..0x71e3  (70 bytes)
DATA_colores_lista_C0:
	defb 088h,004h,09ch,097h,005h,084h,090h,001h,08fh,087h,001h,085h,007h,084h,004h,084h	; 719d  ................
	defb 004h,084h,004h,084h,004h,084h,004h,084h,084h,004h,084h,004h,004h,084h,004h,084h	; 71ad  ................
	defb 088h,088h,08eh,002h,088h,085h,003h,085h,083h,08eh,002h,088h,08eh,002h,088h,090h	; 71bd  ................
	defb 090h,090h,08dh,003h,085h,083h,088h,085h,003h,084h,084h,088h,085h,003h,085h,083h	; 71cd  ................
	defb 088h,0b6h,002h,086h,002h,000h	; 71dd

; ----------------------------------------------------------------------
; DATOS colores_01: Los bytes de color (tinta y fondo por fila) de los tiles
;   0x01-0x1F
;   0x71e3..0x7237  (84 bytes)
DATA_colores_01:
	defb 001h,002h,004h,006h,007h,008h,00ah,00ch,005h,033h,0c1h,03ch,01eh,06fh,06fh,06fh	; 71e3  .........3.<.ooo
	defb 061h,06fh,06fh,06fh,061h,06fh,06fh,06fh,061h,06fh,06fh,06fh,061h,061h,064h,064h	; 71f3  aoooaoooaoooaadd
	defb 064h,04eh,06fh,011h,000h,078h,000h,078h,000h,078h,080h,0b1h,0bfh,0b1h,0bfh,0b1h	; 7203  dNo..x.x.x......
	defb 0cah,0fah,0efh,0eah,044h,044h,044h,044h,055h,044h,044h,055h,044h,044h,077h,055h	; 7213  ....DDDDUDDUDDwU
	defb 055h,055h,044h,0aah,055h,055h,077h,055h,0aah,055h,055h,077h,0aah,055h,077h,055h	; 7223  UUD.UUwU.UUw.UwU
	defb 0bbh,055h,0bbh,077h	; 7233

; ----------------------------------------------------------------------
; DATOS colores_20: Los de 0x20-0x2F (tres bytes de relleno)
;   0x7237..0x723a  (3 bytes)
DATA_colores_20:
	defb 016h,06ch,070h	; 7237

; ----------------------------------------------------------------------
; DATOS colores_60: Los 176 bytes de color de los tiles 0x60-0x75 (22 tiles),
;   que se repiten en 0x76-0x8B con verde
;   0x723a..0x72ea  (176 bytes)
DATA_colores_60:
	defb 01ah,017h,01bh,017h,01ah,01bh,01bh,01bh	; 723a  ........
	defb 01ah,017h,01bh,017h,011h,011h,011h,011h	; 7242  ........
	defb 01ah,017h,011h,011h,011h,011h,011h,011h	; 724a  ........
	defb 01ah,017h,01bh,017h,011h,011h,011h,011h	; 7252  ........
	defb 01ah,017h,01bh,017h,01ah,01bh,01bh,01bh	; 725a  ........
	defb 01ah,017h,01bh,017h,01ah,01bh,01bh,01bh	; 7262  ........
	defb 01ah,017h,01bh,017h,01ah,01ah,01ah,01ah	; 726a  ........
	defb 01ah,017h,01bh,01bh,01bh,01bh,01bh,01bh	; 7272  ........
	defb 01ah,017h,01bh,01bh,01bh,01bh,01bh,01bh	; 727a  ........
	defb 01ah,017h,01bh,017h,01ah,01ah,01ah,01ah	; 7282  ........
	defb 01ah,017h,01bh,017h,01ah,01bh,01bh,01bh	; 728a  ........
	defb 01eh,019h,01fh,019h,01eh,01fh,01fh,01fh	; 7292  ........
	defb 01eh,019h,01fh,019h,019h,019h,019h,019h	; 729a  ........
	defb 01eh,019h,019h,019h,019h,019h,019h,019h	; 72a2  ........
	defb 01eh,019h,01fh,019h,019h,019h,019h,019h	; 72aa  ........
	defb 01eh,019h,01fh,019h,01eh,01fh,01fh,01fh	; 72b2  ........
	defb 01eh,019h,01fh,019h,01eh,01fh,01fh,01fh	; 72ba  ........
	defb 01eh,019h,01fh,019h,01eh,01eh,01eh,01eh	; 72c2  ........
	defb 01eh,019h,01fh,01fh,01fh,01fh,01fh,01fh	; 72ca  ........
	defb 01eh,019h,01fh,01fh,01fh,01fh,01fh,01fh	; 72d2  ........
	defb 01eh,019h,01fh,019h,01eh,01eh,01eh,01eh	; 72da  ........
	defb 01eh,019h,01fh,019h,01eh,01fh,01fh,01fh	; 72e2  ........

; ----------------------------------------------------------------------
; DATOS colores_8C: Los 32 bytes de color de los tiles 0x8C-0x8F
;   0x72ea..0x730a  (32 bytes)
DATA_colores_8C:
	defb 066h,066h,066h,066h,088h,066h,066h,088h	; 72ea  ffff.ff.
	defb 066h,066h,099h,088h,088h,088h,066h,0eeh	; 72f2  ff....f.
	defb 088h,088h,099h,088h,0eeh,088h,088h,099h	; 72fa  ........
	defb 0eeh,088h,099h,088h,0ffh,088h,0ffh,099h	; 7302  ........

; ----------------------------------------------------------------------
; DATOS colores_90: Los de 0x90-0xAD
;   0x730a..0x7336  (44 bytes)
DATA_colores_90:
	defb 0c1h,02ch,0c1h,0c1h,02ch,02ch,0c6h,02ch,02ch,0c6h,02ch,02ch,0c6h,02ch,0c6h,02ch	; 730a  .,..,,.,,.,,.,.,
	defb 0c6h,02ch,02ch,0c6h,02ch,02ch,0c6h,02ch,0c6h,01ch,0c6h,016h,0c6h,016h,0c6h,01ch	; 731a  .,,.,,.,........
	defb 0c6h,01ch,016h,0c6h,016h,0c2h,01ch,0c2h,01ch,0c2h,0c1h,0f0h	; 732a  ............

; ----------------------------------------------------------------------
; DATOS colores_C0: Los de 0xC0-0xFD
;   0x7336..0x73b0  (122 bytes)
DATA_colores_C0:
	defb 0cah,0a1h,0a1h,0a1h,014h,0a4h,0a1h,0a4h,0a1h,0a1h,0a1h,014h,0a4h,014h,017h,047h	; 7336  ...............G
	defb 0fah,0f1h,0fah,0f1h,0f1h,0f4h,01ah,01ah,01ah,014h,04ah,01ah,01ah,01ah,041h,04ah	; 7346  ..........J...AJ
	defb 0afh,0afh,04fh,04fh,06ah,0afh,0afh,04fh,04fh,06ah,06fh,06fh,04fh,04fh,04ah,06fh	; 7356  ..OOj..OOjooOOJo
	defb 06fh,04fh,04fh,04ah,0afh,04fh,04ah,06ah,06ah,0afh,04fh,04ah,06ah,06ah,06fh,06fh	; 7366  oOOJ.OJjj.OJjjoo
	defb 04fh,04fh,04ah,06fh,06fh,04fh,04fh,04ah,0feh,0aeh,057h,05ah,05ah,04ah,01fh,0f3h	; 7376  OOJooOOJ..WZZJ..
	defb 0f3h,023h,01fh,0cfh,023h,02ah,02ah,0ach,089h,08ah,08ah,0a6h,08ah,01ah,08ah,01fh	; 7386  .#..#**.........
	defb 07fh,07fh,075h,01fh,04fh,057h,01fh,03fh,03fh,023h,01fh,0cfh,023h,01fh,09fh,09fh	; 7396  ..u.OW.??#..#...
	defb 089h,01fh,06fh,089h,01fh,013h,013h,01fh,013h,013h	; 73a6  ..o.......

; ----------------------------------------------------------------------
; DATOS patrones_0A: Patrones de los tiles 0x0A-0x1B: barra de tiempo,
;   hombrecito de las vidas, piedra
;   0x73b0..0x7440  (144 bytes)
DATA_patrones_0A:
	defb 000h,010h,010h,000h,000h,010h,010h,000h	; 73b0  ........
	defb 040h,024h,032h,09ah,05bh,05fh,07eh,0ffh	; 73b8  @$2.[_~.
	defb 040h,024h,032h,09ah,05bh,05fh,07eh,0ffh	; 73c0  @$2.[_~.
	defb 000h,000h,000h,0ffh,0efh,0efh,0efh,000h	; 73c8  ........
	defb 0feh,0feh,0feh,000h,0efh,0efh,0efh,000h	; 73d0  ........
	defb 0feh,0feh,0feh,000h,000h,000h,000h,000h	; 73d8  ........
	defb 0ffh,0ffh,0ffh,000h,0efh,0efh,0efh,000h	; 73e0  ........
	defb 000h,000h,0c0h,0c0h,0c0h,0c0h,0c0h,000h	; 73e8  ........
	defb 000h,000h,0f0h,0f0h,0f0h,0f0h,0f0h,000h	; 73f0  ........
	defb 000h,000h,0fch,0fch,0fch,0fch,0fch,000h	; 73f8  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,000h	; 7400  ........
	defb 000h,00fh,01fh,03fh,07fh,07fh,0f9h,0f1h	; 7408  ...?....
	defb 0f1h,0f1h,0f9h,03fh,03fh,01fh,00fh,007h	; 7410  ...??...
	defb 000h,0f0h,0f8h,0fch,0feh,0feh,09fh,08fh	; 7418  ........
	defb 08fh,08fh,09fh,0fch,0fch,0f8h,0f0h,0e0h	; 7420  ........
	defb 038h,00ch,006h,076h,09fh,01fh,07fh,04fh	; 7428  8..v...O
	defb 000h,007h,01fh,07fh,00eh,066h,027h,07fh	; 7430  .....f'.
	defb 000h,000h,0c0h,0e0h,0e0h,0f0h,0f0h,0f0h	; 7438  ........

; ----------------------------------------------------------------------
; DATOS patrones_20: Patrones de los tiles 0x20-0x2F: suelo, ladrillo, la
;   barra llena
;   0x7440..0x74c0  (128 bytes)
DATA_patrones_20:
	defb 000h,080h,0c0h,0e0h,0f0h,0f0h,0f0h,0f0h	; 7440  ........
	defb 001h,003h,007h,007h,007h,007h,007h,007h	; 7448  ........
	defb 0f0h,0f8h,0f8h,0f8h,01ch,00ch,004h,080h	; 7450  ........
	defb 007h,007h,003h,003h,003h,003h,003h,003h	; 7458  ........
	defb 080h,0e0h,0f0h,0fch,0fch,0fch,0feh,0ffh	; 7460  ........
	defb 003h,003h,003h,003h,003h,003h,001h,001h	; 7468  ........
	defb 0ffh,0feh,0feh,0feh,0feh,0feh,0feh,0feh	; 7470  ........
	defb 001h,001h,001h,000h,000h,000h,000h,000h	; 7478  ........
	defb 0feh,0feh,0feh,0fch,0fch,0fch,0feh,0feh	; 7480  ........
	defb 000h,000h,000h,000h,001h,001h,001h,000h	; 7488  ........
	defb 000h,000h,080h,080h,080h,0c0h,0c0h,0c0h	; 7490  ........
	defb 07fh,03fh,03fh,01fh,01fh,01fh,007h,007h	; 7498  .??.....
	defb 0e0h,0e0h,0e0h,0e0h,0c0h,0c0h,080h,000h	; 74a0  ........
	defb 00fh,007h,007h,003h,003h,003h,001h,000h	; 74a8  ........
	defb 0bfh,0dbh,0cdh,065h,0a4h,0a0h,081h,000h	; 74b0  ...e....
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,000h	; 74b8  ........

; ----------------------------------------------------------------------
; DATOS patrones_60: Los once tiles de cerros que se repiten cuatro veces
;   (0x60-0x8B)
;   0x74c0..0x7518  (88 bytes)
DATA_patrones_60:
	defb 000h,000h,000h,000h,000h,007h,01fh,0ffh	; 74c0  ........
	defb 000h,000h,000h,00fh,0ffh,0ffh,0ffh,0ffh	; 74c8  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 74d0  ........
	defb 000h,000h,000h,0f0h,0ffh,0ffh,0ffh,0ffh	; 74d8  ........
	defb 000h,000h,000h,000h,000h,0e0h,0f8h,0ffh	; 74e0  ........
	defb 000h,000h,000h,000h,000h,000h,003h,01fh	; 74e8  ........
	defb 000h,000h,000h,003h,01fh,0ffh,0ffh,0ffh	; 74f0  ........
	defb 000h,007h,07fh,0ffh,0ffh,0ffh,0ffh,0ffh	; 74f8  ........
	defb 000h,0e0h,0feh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7500  ........
	defb 000h,000h,000h,0c0h,0f8h,0ffh,0ffh,0ffh	; 7508  ........
	defb 000h,000h,000h,000h,000h,000h,0c0h,0f8h	; 7510  ........

; ----------------------------------------------------------------------
; DATOS patrones_90: Patrones de los tiles 0x90-0xAD: cerros, arboles y
;   matojos
;   0x7518..0x7608  (240 bytes)
DATA_patrones_90:
	defb 0fbh,071h,000h,000h,000h,000h,000h,000h	; 7518  .q......
	defb 0edh,080h,000h,000h,000h,000h,000h,000h	; 7520  ........
	defb 07fh,00fh,003h,001h,001h,001h,0dfh,08fh	; 7528  ........
	defb 0e1h,080h,0ffh,0ffh,07fh,01fh,08fh,0cfh	; 7530  ........
	defb 0efh,0efh,0e7h,0f7h,0f1h,0f9h,0f8h,0fch	; 7538  ........
	defb 0cfh,005h,0ffh,0ffh,0ffh,0ffh,01fh,00fh	; 7540  ........
	defb 0c1h,0ffh,0ffh,0e0h,0e0h,0e0h,0c0h,080h	; 7548  ........
	defb 09fh,00eh,004h,07fh,03fh,01eh,00ch,000h	; 7550  ....?...
	defb 0f7h,063h,0ffh,0ffh,0ffh,03eh,03eh,03eh	; 7558  .c...>>>
	defb 0b9h,010h,0ffh,07bh,073h,063h,047h,00fh	; 7560  ...{scG.
	defb 0bfh,03fh,00fh,003h,001h,0efh,0cfh,0cfh	; 7568  .?......
	defb 021h,080h,0f0h,0ffh,0ffh,001h,001h,033h	; 7570  !......3
	defb 0feh,07eh,03ch,01ch,08ch,0c0h,0e1h,0f1h	; 7578  .~<.....
	defb 047h,063h,0e3h,0e0h,0f0h,0f8h,0fch,0feh	; 7580  Gc......
	defb 080h,080h,080h,080h,000h,000h,000h,000h	; 7588  ........
	defb 0cfh,0cfh,08fh,00fh,01fh,07fh,0ffh,09ch	; 7590  ........
	defb 07fh,0ffh,0ffh,0a3h,0feh,0feh,0f8h,080h	; 7598  ........
	defb 00fh,01fh,01fh,01fh,03ch,030h,000h,001h	; 75a0  ....<0..
	defb 000h,000h,000h,000h,000h,001h,001h,001h	; 75a8  ........
	defb 0f1h,0f0h,0f0h,0f8h,0f8h,0f8h,0f8h,0fch	; 75b0  ........
	defb 0feh,0feh,0feh,0feh,07eh,01ch,004h,000h	; 75b8  ....~...
	defb 000h,000h,000h,00fh,00fh,01fh,03fh,07fh	; 75c0  ......?.
	defb 003h,01fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 75c8  ........
	defb 003h,003h,001h,001h,003h,007h,0dfh,0ffh	; 75d0  ........
	defb 000h,000h,000h,000h,000h,001h,0d9h,0ffh	; 75d8  ........
	defb 007h,03fh,07fh,001h,013h,01fh,03fh,0ffh	; 75e0  .?....?.
	defb 0e0h,0fch,0feh,080h,0c8h,0f8h,0fch,0ffh	; 75e8  ........
	defb 0ffh,0ffh,0b3h,001h,000h,0bbh,010h,000h	; 75f0  ........
	defb 000h,000h,000h,001h,0d9h,0ffh,0fbh,071h	; 75f8  .......q
	defb 000h,000h,000h,000h,000h,030h,030h,000h	; 7600  .....00.

; ----------------------------------------------------------------------
; DATOS patrones_C0: Patrones de los tiles 0xC0-0xFD: hierba, agua, trampolin,
;   postes, charco, hoguera, ladrillo
;   0x7608..0x77f8  (496 bytes)
DATA_patrones_C0:
	defb 040h,024h,032h,09ah,05bh,05fh,07eh,0ffh	; 7608  @$2.[_~.
	defb 0ffh,0f0h,080h,0c0h,000h,080h,0f0h,0ffh	; 7610  ........
	defb 000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7618  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7620  ........
	defb 000h,000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh	; 7628  ........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h	; 7630  ........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,000h	; 7638  ........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,000h,000h,000h	; 7640  ........
	defb 0ffh,00fh,001h,003h,000h,001h,00fh,0ffh	; 7648  ........
	defb 0ffh,0ffh,000h,000h,000h,000h,000h,000h	; 7650  ........
	defb 0ffh,000h,000h,000h,000h,000h,000h,000h	; 7658  ........
	defb 0c3h,0c3h,0c3h,0c3h,0ffh,0ffh,0ffh,0ffh	; 7660  ........
	defb 0c3h,0c3h,0c3h,0c3h,0ffh,0ffh,0ffh,0ffh	; 7668  ........
	defb 018h,018h,018h,018h,018h,018h,018h,018h	; 7670  ........
	defb 018h,018h,018h,018h,018h,018h,018h,018h	; 7678  ........
	defb 000h,00fh,07fh,0c0h,0ffh,07fh,00fh,000h	; 7680  ........
	defb 000h,0f0h,0feh,0fch,0ffh,0feh,0f0h,000h	; 7688  ........
	defb 080h,000h,080h,07fh,019h,031h,061h,031h	; 7690  .....1a1
	defb 001h,000h,001h,0feh,098h,08ch,086h,08ch	; 7698  ........
	defb 019h,00fh,080h,0ffh,07fh,000h,000h,000h	; 76a0  ........
	defb 098h,0f0h,001h,0ffh,0feh,000h,000h,000h	; 76a8  ........
	defb 0ffh,0ffh,080h,000h,080h,07fh,039h,0e1h	; 76b0  ......9.
	defb 0ffh,0ffh,001h,000h,001h,0feh,09ch,087h	; 76b8  ........
	defb 039h,00fh,080h,0ffh,07fh,000h,000h,000h	; 76c0  9.......
	defb 09ch,0f0h,001h,0ffh,0feh,000h,000h,000h	; 76c8  ........
	defb 0ffh,000h,000h,000h,000h,000h,000h,000h	; 76d0  ........
	defb 000h,000h,000h,000h,000h,000h,000h,0ffh	; 76d8  ........
	defb 01fh,01fh,01fh,01fh,01fh,01fh,01fh,01fh	; 76e0  ........
	defb 01fh,01fh,01fh,01fh,01fh,01fh,07fh,01fh	; 76e8  ........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0feh,0f8h	; 76f0  ........
	defb 0ffh,0e0h,080h,000h,000h,07fh,01fh,01fh	; 76f8  ........
	defb 0ffh,007h,001h,000h,000h,001h,007h,0ffh	; 7700  ........
	defb 01fh,01fh,01fh,01fh,01fh,01fh,01fh,01fh	; 7708  ........
	defb 01fh,01fh,01fh,01fh,01fh,01fh,07fh,01fh	; 7710  ........
	defb 000h,000h,000h,000h,000h,000h,001h,007h	; 7718  ........
	defb 01fh,01fh,01fh,01fh,01fh,01fh,01fh,01fh	; 7720  ........
	defb 01fh,01fh,01fh,01fh,01fh,01fh,07fh,01fh	; 7728  ........
	defb 000h,000h,000h,000h,000h,000h,001h,007h	; 7730  ........
	defb 001h,004h,003h,007h,007h,007h,003h,001h	; 7738  ........
	defb 020h,040h,0c8h,0d0h,0e0h,0e0h,0c0h,080h	; 7740   @......
	defb 000h,005h,00fh,01fh,03fh,065h,0cdh,089h	; 7748  ....?e..
	defb 000h,0a0h,0f0h,0f8h,0fch,0a6h,0b3h,091h	; 7750  ........
	defb 004h,002h,013h,00bh,007h,007h,003h,001h	; 7758  ........
	defb 080h,020h,0c0h,0e0h,0e0h,0e0h,0c0h,080h	; 7760  . ......
	defb 0ffh,0ffh,0ffh,000h,000h,000h,000h,000h	; 7768  ........
	defb 0ffh,0e0h,080h,000h,000h,080h,0e0h,0e0h	; 7770  ........
	defb 0ffh,007h,001h,000h,000h,001h,007h,0ffh	; 7778  ........
	defb 01fh,01fh,01fh,01fh,01fh,01fh,01fh,01fh	; 7780  ........
	defb 0ffh,0e0h,080h,000h,000h,080h,0e0h,01fh	; 7788  ........
	defb 0ffh,007h,001h,000h,000h,001h,007h,0ffh	; 7790  ........
	defb 01fh,01fh,01fh,01fh,01fh,01fh,01fh,01fh	; 7798  ........
	defb 0ffh,0e0h,080h,000h,000h,080h,0e0h,01fh	; 77a0  ........
	defb 0ffh,007h,001h,000h,000h,001h,007h,0ffh	; 77a8  ........
	defb 01fh,01fh,01fh,01fh,01fh,01fh,01fh,01fh	; 77b0  ........
	defb 0ffh,0f9h,0f3h,0f3h,0f3h,0f9h,0ffh,0ffh	; 77b8  ........
	defb 0ffh,09fh,0cfh,0cfh,0cfh,09fh,0ffh,0ffh	; 77c0  ........
	defb 0ffh,0f3h,0e7h,0e7h,0e7h,0e7h,0f3h,0ffh	; 77c8  ........
	defb 0ffh,0cfh,0e7h,0e7h,0e7h,0e7h,0cfh,0ffh	; 77d0  ........
	defb 0cfh,09fh,03fh,03fh,03fh,03fh,09fh,0cfh	; 77d8  ..????..
	defb 0f3h,0f9h,0fch,0fch,0fch,0fch,0f9h,0f3h	; 77e0  ........
	defb 0ffh,0f9h,0f3h,0f3h,0f3h,0f9h,000h,000h	; 77e8  ........
	defb 0ffh,09fh,0cfh,0cfh,0cfh,09fh,000h,000h	; 77f0  ........

; ----------------------------------------------------------------------
; DATOS relleno_77F8: Seis bytes sin uso entre los patrones y el sonido
;   0x77f8..0x77fe  (6 bytes)
DATA_relleno_77F8:
	defb 021h,002h,0e0h,0cbh,076h,0c8h	; 77f8

; ======================================================================
; CODIGO 0x77fe..0x7960  (354 bytes)
; ======================================================================


SONIDO:		; Pide el sonido A: efecto (canal C), musica de dos canales (0x8E) o de tres (0x90+)
	di			;77fe   ; El reproductor corre dentro de la interrupcion: no puede pillar los canales a medio repartir
	push de			;77ff
	ld d,000h		;7800   ; D=0: solo entra si el canal no lleva ya algo igual o mas alto
	call SONIDO_ARRANCA		;7802
	pop de			;7805
	ei			;7806
	ret			;7807
SONIDO_ARRANCA:		; D=0 respeta la prioridad; D=1 (desde el bucle) no. Reparte los canales y apunta las pistas
	ld b,002h		;7808
	ld hl,0e012h		;780a
	cp 08eh		;780d   ; Por debajo de 0x8E: efecto, un canal
	jr c,SONIDO_UN_CANAL		;780f
	cp 090h		;7811   ; 0x8E: dos canales (A y B); del 0x90 en adelante, tres
	jr c,SONIDO_PRIORIDAD		;7813
	inc b			;7815
	jr SONIDO_PRIORIDAD		;7816
SONIDO_UN_CANAL:		; El canal C (E024) para los efectos
	dec b			;7818
	ld hl,0e026h		;7819
SONIDO_PRIORIDAD:		; Si el canal ya suena algo igual o mayor, nada
	dec d			;781c
	jr z,SONIDO_PISTAS		;781d
	cp (hl)			;781f
	jr z,SONIDO_FIN		;7820
	jr c,SONIDO_FIN		;7822
	cp 095h		;7824   ; Del 0x95 al 0x9A se guardan sin el bit 7: suenan con el formato de efecto aunque vayan por tres canales
	jr c,SONIDO_PISTAS		;7826
	cp 09bh		;7828
	jr nc,SONIDO_PISTAS		;782a
	and 07fh		;782c
SONIDO_PISTAS:		; Indice = numero & 0x3F en la tabla de punteros; una palabra por canal seguida
	ld c,a			;782e
	and 03fh		;782f
	add a,a			;7831
	ld de,0796ah		;7832
	call DE_MAS_A		;7835
SONIDO_CANAL:		; Arranca un canal: 1 fotograma, duracion 1, el numero, y el puntero de la tabla; y al siguiente canal (10 bytes mas alla)
	dec hl			;7838   ; HL llega apuntando a +2 del canal: atras hasta +0
	dec hl			;7839
	ld (hl),001h		;783a   ; +0, lo que queda de nota: 1 fotograma, para que el primer paso ya lea el evento
	inc hl			;783c
	ld (hl),001h		;783d   ; +1, la duracion de las notas
	inc hl			;783f
	ld a,c			;7840
	ld (hl),a			;7841   ; +2, el numero del sonido; con el bit 7 puesto es musica
	inc hl			;7842
	ld a,(de)			;7843   ; +3/+4, el puntero de la pista que da la tabla de 0x796A
	ld (hl),a			;7844
	inc hl			;7845
	inc de			;7846
	ld a,(de)			;7847
	ld (hl),a			;7848
	ld a,008h		;7849   ; Desde +4, ocho mas caen en el +2 del canal siguiente
	call HL_MAS_A		;784b
	inc de			;784e
	djnz SONIDO_CANAL		;784f
SONIDO_FIN:		; Nada que hacer
	ret			;7851
SONIDO_REPITE:		; 0xFE en la pista: vuelve a arrancar el mismo sonido sin mirar prioridades (bucle)
	ld a,(ix+002h)		;7852   ; +2 guarda el numero del sonido que estaba sonando
	push bc			;7855
	ld d,001h		;7856   ; D=1: sin mirar prioridad, o el bucle se cortaria a si mismo
	call SONIDO_ARRANCA		;7858
	pop bc			;785b
	ret			;785c

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL REPRODUCTOR, en cada interrupcion (aunque el juego vaya atrasado).
; Para cada canal ocupado descuenta la nota y, si acabo, lee el
; siguiente evento de su pista. Dos formatos segun el bit 7 del numero:
; EFECTO: [0x2n duracion n] vp pp -> volumen v, periodo 0xppp
; MUSICA: [0xFD oo] ln -> l duracion (tabla 0x79AE), n nota 0-11 en
; la octava de 0x7960 bajada oo&7 octavas, 12 silencio;
; oo>>3 es el volumen de arranque
; 0xFE vuelve al principio (bucle), 0xFF apaga el canal.
; La musica lleva envolvente: la nota arranca al volumen v y baja tres
; pasos en tres fotogramas, se mantiene, y baja dos mas al acabar.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
SUENA:		; Un fotograma de los tres canales (IX = E010, +10 por canal; C = registro de periodo)
	ld b,003h		;785d
	ld de,0000ah		;785f   ; Diez bytes por canal: E010, E01A y E024
	push bc			;7862
	push de			;7863
	ld l,001h		;7864   ; L=1: registros 1 y 0 del PSG; luego 3 y 5
	ld ix,0e010h		;7866
	jr SUENA_CANAL_MIRA		;786a
SUENA_CANAL:		; Siguiente canal
	push bc			;786c
	push de			;786d
SUENA_CANAL_MIRA:		; Con sonido en curso (+2 distinto de 0), un paso
	ld c,l			;786e   ; C se lleva el registro de periodo de este canal
	ld a,(ix+002h)		;786f   ; +2 a cero es canal libre: ni se le mira la pista
	or a			;7872
	call nz,SUENA_PASO		;7873
	inc c			;7876   ; Los dos registros del canal siguiente: 1, 3, 5
	inc c			;7877
	ld l,c			;7878
	pop de			;7879
	pop bc			;787a
	add ix,de		;787b   ; IX al bloque del canal siguiente
	djnz SUENA_CANAL		;787d
	ret			;787f
SUENA_PASO:		; Musica (bit 7) por 78D7; efecto: descuenta y, a cero, siguiente evento
	jp m,MUSICA_PASO		;7880
	dec (ix+000h)		;7883
	ret nz			;7886
SIGUIENTE_EVENTO:		; Lee la pista: 0xFE bucle, 0xFF apaga, musica por 7902, efecto aqui
	ld l,(ix+003h)		;7887
	ld h,(ix+004h)		;788a
	ld a,(hl)			;788d
	cp 0feh		;788e   ; 0xFE: bucle
	jr z,SONIDO_REPITE		;7890
	jr nc,CANAL_APAGA		;7892   ; 0xFF: canal apagado
	bit 7,(ix+002h)		;7894   ; Musica: otro formato
	jp nz,MUSICA_EVENTO		;7898
	and 0f0h		;789b
	cp 020h		;789d   ; 0x2n: nueva duracion de las notas del efecto
	jr nz,EFECTO_EVENTO		;789f
	ld a,(hl)			;78a1
	and 00fh		;78a2
	ld (ix+001h),a		;78a4
	inc hl			;78a7
EFECTO_EVENTO:		; Nibble alto volumen, nibble bajo y byte siguiente el periodo
	ld a,(hl)			;78a8
	and 0f0h		;78a9   ; El nibble alto, el volumen
	ld b,a			;78ab
	xor (hl)			;78ac   ; El xor deja el nibble bajo: los 4 bits altos del periodo
	ld d,a			;78ad
	inc hl			;78ae
	ld e,(hl)			;78af   ; Y el byte de detras, los 8 bajos
	inc hl			;78b0
	ld (ix+003h),l		;78b1   ; La pista queda apuntando a lo que venga detras
	ld (ix+004h),h		;78b4
	ex de,hl			;78b7
	call PSG_PERIODO		;78b8
	ld a,b			;78bb
	rrca			;78bc   ; El volumen baja al nibble bajo para PSG_VOLUMEN
	rrca			;78bd
	rrca			;78be
	rrca			;78bf
	and 00fh		;78c0
NOTA_ARRANCA:		; H = volumen; +0 = duracion, +8 = duracion + 3 (la envolvente); y al PSG
	ld h,a			;78c2
	ld a,(ix+001h)		;78c3   ; +1 es la duracion fijada; +0 la cuenta atras que se le pone al lado
	ld (ix+000h),a		;78c6
	add a,003h		;78c9
	ld (ix+008h),a		;78cb   ; +8 arranca tres por encima: la envolvente los gasta al principio
	jr PSG_VOLUMEN		;78ce
CANAL_APAGA:		; Numero 0 y volumen 0
	xor a			;78d0
	ld (ix+002h),a		;78d1
	ld h,a			;78d4
	jr PSG_VOLUMEN		;78d5
MUSICA_PASO:		; Descuenta la nota; envolvente: tres pasos abajo al principio, dos al final
	dec (ix+000h)		;78d7
	jr z,SIGUIENTE_EVENTO		;78da
	dec (ix+008h)		;78dc
	ld a,(ix+008h)		;78df
	cp (ix+000h)		;78e2
	jr nz,ENVOLVENTE_ARRANQUE		;78e5
	cp 003h		;78e7   ; Los ultimos tres fotogramas: baja
	jr c,VOLUMEN_BAJA		;78e9
	ret			;78eb
ENVOLVENTE_ARRANQUE:		; Los tres primeros fotogramas: baja
	dec (ix+008h)		;78ec
VOLUMEN_BAJA:		; Un paso menos, sin pasar de cero
	ld a,(ix+007h)		;78ef
	dec a			;78f2
	ret m			;78f3
	ld (ix+007h),a		;78f4
	ld h,a			;78f7
PSG_VOLUMEN:		; Registro 8/9/10 (segun C) = H
	ld a,c			;78f8
	rrca			;78f9   ; C vale 1, 3 o 5: registros 8, 9 y 10, los tres volumenes
	add a,088h		;78fa
	out (0a0h),a		;78fc
	ld a,h			;78fe   ; H trae el volumen, de 0 a 15
	out (0a1h),a		;78ff
	ret			;7901
MUSICA_EVENTO:		; 0xFD: octava (bits 0-2) y volumen (bits 3-7); luego la nota
	cp 0fdh		;7902
	jr nz,MUSICA_NOTA		;7904
	inc hl			;7906
	ld a,(hl)			;7907
	and 007h		;7908   ; Bits 0-2: cuantas octavas se baja, a +5
	ld (ix+005h),a		;790a
	xor (hl)			;790d   ; El xor deja los bits 3-7 y tres rrca los bajan: el volumen de arranque, a +6
	rrca			;790e
	rrca			;790f
	rrca			;7910
	ld (ix+006h),a		;7911
	inc hl			;7914
	ld a,(hl)			;7915   ; Y detras del 0xFD viene ya el byte de la nota
MUSICA_NOTA:		; Nibble bajo la nota, alto el indice de duracion; 12 es silencio (no repone el volumen)
	and 00fh		;7916
	ld b,a			;7918
	xor (hl)			;7919
	inc hl			;791a
	ld (ix+003h),l		;791b
	ld (ix+004h),h		;791e
	rrca			;7921
	rrca			;7922
	rrca			;7923
	rrca			;7924
	ld hl,079aeh		;7925   ; Tabla de 14 duraciones
	call HL_MAS_A		;7928
	ld a,(hl)			;792b
	ld (ix+001h),a		;792c
	ld a,b			;792f
	sub 00ch		;7930   ; Nota 12: silencio
	jr z,MUSICA_PERIODO		;7932
	ld a,(ix+006h)		;7934
	ld (ix+007h),a		;7937
MUSICA_PERIODO:		; Periodo de la nota por 0x7960, doblado tantas veces como octavas
	call NOTA_ARRANCA		;793a
	ld a,b			;793d
	ld hl,07960h		;793e   ; Los doce periodos de la octava mas alta
	call HL_MAS_A		;7941
	ld l,(hl)			;7944
	ld h,000h		;7945
	ld a,(ix+005h)		;7947   ; Sin octavas que bajar, el periodo va tal cual
	or a			;794a
	jr z,PSG_PERIODO		;794b
	ld b,a			;794d
MUSICA_OCTAVA:		; Una octava mas abajo por vuelta
	add hl,hl			;794e   ; Doblar el periodo es bajar una octava
	djnz MUSICA_OCTAVA		;794f
PSG_PERIODO:		; Registros C y C-1 = HL (periodo)
	ld a,c			;7951   ; El registro impar lleva el byte alto del periodo
	out (0a0h),a		;7952
	ld a,h			;7954
	out (0a1h),a		;7955
	dec c			;7957   ; Y el par de debajo, el bajo
	ld a,c			;7958
	out (0a0h),a		;7959
	ld a,l			;795b
	out (0a1h),a		;795c
	inc c			;795e
	ret			;795f

; ----------------------------------------------------------------------
; DATOS periodos_de_notas: Los periodos del PSG de Do6 a La6 (106, 100, 95,
;   89, 84, 80, 75, 71, 67, 63); La#6 y Si6 (60, 56) son los dos bytes
;   siguientes, que a la vez son la entrada 0 de la tabla de punteros
;   0x7960..0x796a  (10 bytes)
DATA_periodos_de_notas:
	defb 06ah,064h,05fh,059h,054h,050h,04bh,047h,043h,03fh	; 7960  jd_YTPKGC?

; ----------------------------------------------------------------------
; DATOS tabla_de_sonidos: 34 punteros de pista, indice = numero del sonido &
;   0x3F, con los canales seguidos: 1-13 los efectos, 14-15 la musica de la
;   partida (0x8E), 16-18 la muerte (0x90), 19-21 GAME OVER (0x93), 22-24 le
;   han dado (0x96), 25-27 se hunde (0x99), 28-30 la fanfarria del menu y la
;   meta (0x9C), 31-33 mudos. La entrada 0 (0x383C) no es un puntero: son las
;   dos ultimas notas de la tabla de periodos. 0x79DB (un 0xFF) es la pista
;   muda de los canales vacios y del sonido 6
;   0x796a..0x79ae  (68 bytes)
DATA_tabla_de_sonidos:
	defw 0383ch	; 796a
	defw 07bb5h	; 796c  -> DATA_efecto_puntos
	defw 07b81h	; 796e  -> DATA_efecto_pisada
	defw 07b2ah	; 7970  -> DATA_efecto_salto
	defw 07bc5h	; 7972  -> DATA_efecto_bola_bota
	defw 07bbfh	; 7974  -> DATA_efecto_abeja
	defw 079dbh	; 7976
	defw 07b6fh	; 7978  -> DATA_efecto_pez
	defw 07b4eh	; 797a  -> DATA_efecto_bola_arranca
	defw 07b38h	; 797c  -> DATA_efecto_trampolin
	defw 07c30h	; 797e  -> DATA_efecto_fruta
	defw 07bfbh	; 7980  -> DATA_efecto_chapoteo
	defw 07c06h	; 7982  -> DATA_efecto_vida_extra
	defw 07c18h	; 7984  -> DATA_efecto_prisa
	defw 079ffh	; 7986  -> DATA_musica_partida_canal_a
	defw 07a59h	; 7988  -> DATA_musica_partida_canal_b
	defw 07be2h	; 798a  -> DATA_muerte_canal_a
	defw 07bf4h	; 798c  -> DATA_muerte_canal_b
	defw 079dbh	; 798e
	defw 07ad4h	; 7990  -> DATA_game_over_canal_a
	defw 07af4h	; 7992  -> DATA_game_over_canal_b
	defw 07b08h	; 7994  -> DATA_game_over_canal_c
	defw 07ba9h	; 7996  -> DATA_efecto_le_han_dado
	defw 079dbh	; 7998
	defw 079dbh	; 799a
	defw 07b8fh	; 799c  -> DATA_efecto_se_hunde
	defw 079dbh	; 799e
	defw 079dbh	; 79a0
	defw 079bch	; 79a2  -> DATA_fanfarria_canal_a
	defw 079dch	; 79a4  -> DATA_fanfarria_canal_b
	defw 079edh	; 79a6  -> DATA_fanfarria_canal_c
	defw 079dbh	; 79a8
	defw 079dbh	; 79aa
	defw 079dbh	; 79ac

; ----------------------------------------------------------------------
; DATOS duraciones_de_notas: Las 14 duraciones en fotogramas que elige el
;   nibble alto de cada nota: 5, 10, 15, 6, 12, 24, 40, 72, 4, 8, 16, 32, 20,
;   66
;   0x79ae..0x79bc  (14 bytes)
DATA_duraciones_de_notas:
	defb 005h,00ah,00fh,006h,00ch,018h,028h,048h,004h,008h,010h,020h,014h,042h	; 79ae  ......(H... .B

; ----------------------------------------------------------------------
; DATOS fanfarria_canal_a: Sonido 0x9C (el menu y la meta), canal A. Su 0xFF
;   final, en 0x79DB, es la pista muda del sonido 6 (calla el zumbido de la
;   abeja) y de los canales vacios
;   0x79bc..0x79dc  (32 bytes)
DATA_fanfarria_canal_a:
	defb 0fdh,05ah,045h,035h,035h,045h,035h,035h,049h,0fdh,059h,030h,030h,0fdh,05ah,039h	; 79bc  .ZE55E55I.Y00.Z9
	defb 039h,045h,0fdh,059h,040h,0fdh,05ah,03ah,03ah,039h,039h,037h,037h,055h,055h,0ffh	; 79cc  9E.Y@.Z::9977UU.

; ----------------------------------------------------------------------
; DATOS fanfarria_canal_b: Sonido 0x9C, canal B
;   0x79dc..0x79ed  (17 bytes)
DATA_fanfarria_canal_b:
	defb 0fdh,05bh,045h,049h,045h,049h,045h,049h,045h,049h,044h,047h,050h,045h,040h,05ch	; 79dc  .[EIEIEIEIDGPE@\
	defb 0ffh	; 79ec

; ----------------------------------------------------------------------
; DATOS fanfarria_canal_c: Sonido 0x9C, canal C
;   0x79ed..0x79ff  (18 bytes)
DATA_fanfarria_canal_c:
	defb 0fdh,059h,04ch,040h,04ch,040h,04ch,040h,04ch,040h,04ch,040h,05ch,05ch,0fdh,05ah	; 79ed  .YL@L@L@L@L@\\.Z
	defb 055h,0ffh	; 79fd

; ----------------------------------------------------------------------
; DATOS musica_partida_canal_a: Sonido 0x8E: la musica de la partida, canal A;
;   acaba en 0xFE, en bucle mientras dura la pantalla
;   0x79ff..0x7a59  (90 bytes)
DATA_musica_partida_canal_a:
	defb 0fdh,05ah,01ch,014h,01ch,017h,0fdh,059h,020h,002h,010h,0fdh,05ah,017h,01ch,014h	; 79ff  .Z.....Y ...Z...
	defb 01ch,017h,0fdh,059h,060h,0fdh,05ah,01ch,015h,01ch,019h,0fdh,059h,022h,004h,012h	; 7a0f  ...Y`.Z.....Y"..
	defb 0fdh,05ah,019h,01ch,015h,01ch,019h,0fdh,059h,062h,0fdh,05ah,01ch,014h,01ch,017h	; 7a1f  .Z......Yb.Z....
	defb 0fdh,059h,020h,002h,010h,0fdh,05ah,017h,01ch,014h,01ch,017h,0fdh,059h,060h,0fdh	; 7a2f  .Y ...Z......Y`.
	defb 05ah,01ch,015h,01ch,019h,0fdh,059h,022h,004h,012h,0fdh,05ah,019h,01ch,015h,01ch	; 7a3f  Z.....Y"...Z....
	defb 019h,0fdh,059h,024h,002h,0fdh,05ah,019h,015h,0feh	; 7a4f  ..Y$..Z...

; ----------------------------------------------------------------------
; DATOS musica_partida_canal_b: La musica de la partida, canal B (0xFE, en
;   bucle)
;   0x7a59..0x7ad4  (123 bytes)
DATA_musica_partida_canal_b:
	defb 0fdh,05bh,010h,017h,0fdh,05ch,01bh,0fdh,05bh,017h,0fdh,05ch,019h,0fdh,05bh,017h	; 7a59  .[...\..[..\..[.
	defb 0fdh,05ch,01bh,0fdh,05bh,017h,010h,017h,0fdh,05ch,01bh,0fdh,05bh,017h,0fdh,05ch	; 7a69  .\..[....\..[..\
	defb 019h,0fdh,05bh,017h,0fdh,05ch,017h,0fdh,05bh,017h,012h,019h,011h,019h,010h,019h	; 7a79  ..[..\..[.......
	defb 011h,019h,012h,019h,011h,019h,010h,019h,0fdh,05ch,01bh,0fdh,05bh,017h,010h,017h	; 7a89  .........\..[...
	defb 0fdh,05ch,01bh,0fdh,05bh,017h,0fdh,05ch,019h,0fdh,05bh,017h,0fdh,05ch,01bh,0fdh	; 7a99  .\..[..\..[..\..
	defb 05bh,017h,010h,017h,0fdh,05ch,01bh,0fdh,05bh,017h,0fdh,05ch,019h,0fdh,05bh,017h	; 7aa9  [....\..[..\..[.
	defb 0fdh,05ch,017h,0fdh,05bh,017h,012h,019h,011h,019h,010h,019h,011h,019h,012h,019h	; 7ab9  .\..[...........
	defb 011h,019h,010h,019h,0fdh,05ch,01bh,0fdh,05bh,017h,0feh	; 7ac9  .....\..[..

; ----------------------------------------------------------------------
; DATOS game_over_canal_a: Sonido 0x93 (GAME OVER), canal A
;   0x7ad4..0x7af4  (32 bytes)
DATA_game_over_canal_a:
	defb 0fdh,059h,0c2h,021h,0c4h,0c2h,001h,0c1h,0fdh,05ah,02bh,0fdh,059h,0c2h,0c1h,0fdh	; 7ad4  .Y.!.....Z+.Y...
	defb 05ah,00bh,02bh,00ah,02bh,0fdh,059h,002h,0c1h,0fdh,05ah,029h,0fdh,059h,0d2h,0ffh	; 7ae4  Z.+.+.Y...Z).Y..

; ----------------------------------------------------------------------
; DATOS game_over_canal_b: Canal B
;   0x7af4..0x7b08  (20 bytes)
DATA_game_over_canal_b:
	defb 0fdh,05ah,0c6h,026h,0c6h,0c6h,006h,0c6h,026h,0c6h,0c6h,006h,027h,006h,027h,00bh	; 7af4  .Z.&....&...'.'.
	defb 0c9h,027h,0d6h,0ffh	; 7b04

; ----------------------------------------------------------------------
; DATOS game_over_canal_c: Canal C
;   0x7b08..0x7b2a  (34 bytes)
DATA_game_over_canal_c:
	defb 0fdh,05bh,0c2h,0c9h,0c2h,0c9h,0fdh,054h,0cbh,0fdh,053h,0c6h,0fdh,054h,0cbh,0fdh	; 7b08  .[.....T..S..T..
	defb 053h,0c6h,0c7h,027h,008h,0c9h,029h,0c2h,008h,019h,0fdh,052h,011h,012h,0fdh,053h	; 7b18  S..'..)....R...S
	defb 012h,0ffh	; 7b28

; ----------------------------------------------------------------------
; DATOS efecto_salto: Sonido 3: saltar y soltarse de la liana
;   0x7b2a..0x7b38  (14 bytes)
DATA_efecto_salto:
	defb 022h,0d0h,08fh,0b0h,080h,0b0h,087h,0a0h,072h,090h,060h,080h,053h,0ffh	; 7b2a  ".......r.`.S.

; ----------------------------------------------------------------------
; DATOS efecto_trampolin: Sonido 9: el bote en el trampolin
;   0x7b38..0x7b4e  (22 bytes)
DATA_efecto_trampolin:
	defb 022h,0c1h,077h,0b1h,055h,0a1h,077h,091h,055h,081h,077h,071h,050h,061h,077h,051h	; 7b38  ".w.U.w.U.wqPawQ
	defb 050h,041h,077h,031h,050h,0ffh	; 7b48

; ----------------------------------------------------------------------
; DATOS efecto_bola_arranca: Sonido 8: una bola echa a rodar
;   0x7b4e..0x7b6f  (33 bytes)
DATA_efecto_bola_arranca:
	defb 021h,0c2h,011h,0c2h,000h,0c2h,011h,0c2h,000h,0a2h,011h,092h,000h,082h,011h,072h	; 7b4e  !..............r
	defb 000h,023h,062h,011h,052h,000h,052h,011h,042h,000h,042h,011h,042h,000h,032h,011h	; 7b5e  .#b.R.R.B.B.B.2.
	defb 0ffh	; 7b6e

; ----------------------------------------------------------------------
; DATOS efecto_pez: Sonido 7: un pez salta
;   0x7b6f..0x7b81  (18 bytes)
DATA_efecto_pez:
	defb 021h,0b0h,0aah,0b0h,077h,0b0h,088h,0b0h,055h,0b0h,066h,0b0h,033h,0b0h,044h,0b0h	; 7b6f  !...w...U.f.3.D.
	defb 022h,0ffh	; 7b7f

; ----------------------------------------------------------------------
; DATOS efecto_pisada: Sonido 2: cada paso
;   0x7b81..0x7b8f  (14 bytes)
DATA_efecto_pisada:
	defb 021h,0b0h,090h,0b0h,0a0h,028h,000h,000h,021h,0b0h,070h,0b0h,080h,0ffh	; 7b81  !....(..!.p...

; ----------------------------------------------------------------------
; DATOS efecto_se_hunde: Sonido 0x99 (formato de efecto por tres canales):
;   ahogarse; solo el canal A suena, B y C van a la pista muda
;   0x7b8f..0x7ba9  (26 bytes)
DATA_efecto_se_hunde:
	defb 023h,0c1h,027h,0c1h,09ah,0c1h,0c4h,0c2h,012h,0c2h,006h,0c2h,0f7h,0c3h,0c3h,050h	; 7b8f  #.'............P
	defb 0a3h,0cfh,084h,030h,064h,0b5h,026h,045h,031h,0ffh	; 7b9f  ...0d.&E1.

; ----------------------------------------------------------------------
; DATOS efecto_le_han_dado: Sonido 0x96 (idem): le ha dado un bicho; canal A
;   0x7ba9..0x7bb5  (12 bytes)
DATA_efecto_le_han_dado:
	defb 022h,0c2h,005h,0c2h,00eh,0c3h,022h,0c2h,0cch,0c2h,0fbh,0ffh	; 7ba9  ".....".....

; ----------------------------------------------------------------------
; DATOS efecto_puntos: Sonido 1: puntos cobrados
;   0x7bb5..0x7bbf  (10 bytes)
DATA_efecto_puntos:
	defb 021h,0b0h,038h,0a0h,038h,0b0h,048h,0a0h,048h,0ffh	; 7bb5  !.8.8.H.H.

; ----------------------------------------------------------------------
; DATOS efecto_abeja: Sonido 5: el zumbido de la abeja, en bucle (0xFE) hasta
;   que el 6 lo calla
;   0x7bbf..0x7bc5  (6 bytes)
DATA_efecto_abeja:
	defb 021h,092h,000h,091h,0f5h,0feh	; 7bbf

; ----------------------------------------------------------------------
; DATOS efecto_bola_bota: Sonido 4: la bola que bota entra
;   0x7bc5..0x7be2  (29 bytes)
DATA_efecto_bola_bota:
	defb 021h,0d1h,099h,0c1h,099h,0d1h,099h,000h,000h,022h,0c0h,090h,0b0h,080h,0a0h,070h	; 7bc5  !........".....p
	defb 090h,060h,080h,050h,070h,04ch,060h,048h,050h,044h,040h,040h,0ffh	; 7bd5  .`.PpL`HPD@@.

; ----------------------------------------------------------------------
; DATOS muerte_canal_a: Sonido 0x90 (la muerte, con vidas), canal A
;   0x7be2..0x7bf4  (18 bytes)
DATA_muerte_canal_a:
	defb 0fdh,062h,040h,084h,097h,094h,042h,085h,099h,095h,044h,087h,09bh,097h,0fdh,061h	; 7be2  .b@...B...D....a
	defb 050h,0ffh	; 7bf2

; ----------------------------------------------------------------------
; DATOS muerte_canal_b: Canal B; el C va a la pista muda
;   0x7bf4..0x7bfb  (7 bytes)
DATA_muerte_canal_b:
	defb 0fdh,063h,0b4h,0b5h,0b7h,050h,0ffh	; 7bf4

; ----------------------------------------------------------------------
; DATOS efecto_chapoteo: Sonido 0x0B: chapotear en el agua
;   0x7bfb..0x7c06  (11 bytes)
DATA_efecto_chapoteo:
	defb 021h,0b1h,050h,0b1h,060h,0b1h,050h,025h,000h,000h,0ffh	; 7bfb  !.P.`.P%...

; ----------------------------------------------------------------------
; DATOS efecto_vida_extra: Sonido 0x0C: vida extra
;   0x7c06..0x7c18  (18 bytes)
DATA_efecto_vida_extra:
	defb 024h,0c1h,01dh,0c0h,0d5h,0c0h,0a9h,0c0h,08eh,0c1h,01dh,0c0h,0d5h,0c0h,0a9h,0c0h	; 7c06  $...............
	defb 08eh,0ffh	; 7c16

; ----------------------------------------------------------------------
; DATOS efecto_prisa: Sonido 0x0D: el pitido de que se acaba el tiempo
;   0x7c18..0x7c30  (24 bytes)
DATA_efecto_prisa:
	defb 023h,090h,060h,090h,040h,090h,060h,090h,040h,090h,060h,090h,040h,090h,060h,090h	; 7c18  #.`.@.`.@.`.@.`.
	defb 040h,090h,060h,090h,040h,090h,060h,0ffh	; 7c28  @.`.@.`.

; ----------------------------------------------------------------------
; DATOS efecto_fruta: Sonido 0x0A: coger la fruta, y el aviso de fase superada
;   0x7c30..0x7c3e  (14 bytes)
DATA_efecto_fruta:
	defb 022h,0d0h,0a9h,0d0h,08eh,0d0h,06ah,0d0h,0a9h,0d0h,08eh,0d0h,06ah,0ffh	; 7c30  ".....j.....j.

; ----------------------------------------------------------------------
; DATOS relleno_final: 962 bytes a 0xFF hasta el final del cartucho
;   0x7c3e..0x8000  (962 bytes)
DATA_relleno_final:
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7c3e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7c4e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7c5e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7c6e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7c7e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7c8e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7c9e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7cae  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7cbe  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7cce  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7cde  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7cee  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7cfe  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7d0e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7d1e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7d2e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7d3e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7d4e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7d5e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7d6e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7d7e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7d8e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7d9e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7dae  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7dbe  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7dce  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7dde  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7dee  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7dfe  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7e0e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7e1e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7e2e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7e3e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7e4e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7e5e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7e6e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7e7e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7e8e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7e9e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7eae  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7ebe  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7ece  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7ede  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7eee  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7efe  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f0e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f1e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f2e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f3e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f4e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f5e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f6e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f7e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f8e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f9e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fae  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fbe  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fce  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fde  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fee  ................
	defb 0ffh,0ffh	; 7ffe
