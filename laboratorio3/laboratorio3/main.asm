;
; Menejo de display;
; Created: 29/9/2021 19:12:24
; Author: rperdomo
; En este programa vamos a poner el número 0 en dígito display de más a la derecha, la idea es hacer un barrido bien rápido

.ORG 0x0000
	jmp		start	; programa principal
.ORG 0x0008			; Dir de memoria de la interrupcion de botones
	jmp		pcint 
.ORG 0x001C			;dirección para la insterrupciones internas
	jmp		_tmr0_int

;-------------

; acá empieza el programa
start:
;configuro los puertos:
;	PB2 PB3 PB4 PB5	- son los LEDs del shield
;	PB0 es SD (serial data) para el display 7seg
;	PD7 es SCLK, el reloj de los shift registers del display 7seg
;	PD4 es LCH, transfiere los datos que ya ingresaron en serie, a la salida del registro paralelo 
;   	PC son entradas para los botones

	ldi		r16,	0b00111101	
	out		DDRB,	r16			;4 LEDs del shield son salidas
	out		PORTB,	r16			;apago los LEDs
	ldi		r16,	0b00000000	
	out		DDRC,	r16			;3 botones del shield son entradas
	ldi		r16,	0b10010000
	out		DDRD,	r16			;configuro PD.4 y PD.7 como salidas
	cbi		PORTD,	7			;PD.7 a 0, es el reloj serial, inicializo a 0
	cbi		PORTD,	4			;PD.4 a 0, es el reloj del latch, inicializo a 0

;-------------------------------------------------------------------------------------

	ldi		r16,	0b00000000	
	out		DDRC,	r16			;3 botones del shield son entradas
	;out		PORTC,	r16

; botones

	ldi		r19,	0b000001110			; config de los 3 botones
	sts		PCMSK1, r19					; seteamos la configuracion de los 3 botones
	ldi		r17,	0b00000010 			; habilitamos los botones
	sts		PCICR,	r17


;Configuro el TMR0 y su interrupcion, esto está sacado del lab 2

	ldi		r16,	0b00000010
	out		TCCR0A,	r16			;configuro para que cuente hasta OCR0A y vuelve a cero (reset on compare), ahí dispara la interrupción
	ldi		r16,	0b00000101	
	out		TCCR0B,	r16			;prescaler = 1024
	ldi		r16,	62			 ; modifico la interrupcion para actualizar el reloj mas rapido
	out		OCR0A,	r16			;comparo con 63
	ldi		r16,	0b00000010
	sts		TIMSK0,	r16			;habilito la interrupción (falta habilitar global)

;Inicializo algunos registros que voy a usar como variables para generar los números

	ldi r24, 0x00				;inicializo r24 para un contador genérico
	ldi r25, 250				; contador para generar un segundo
	ldi r29, 0b00000100
	ldi r27, 0
	ldi r23, 0
	ldi r22, 0
	ldi r21, 0
	ldi r20, 0
	ldi r19, 0

;Programa principal ... acá puedo hacer lo que quiero

comienzo:
	sei							;habilito las interrupciones globales

/*
apagar:		; apaga todo el display de 7 segmentos
	ldi r16,0b11111111
	ldi r17,0b11110000
	call sacanum
*/


;-------------------------------------------------------------------------------------

; Observar la rutina sacanum, utiliza r16 para los LEDs del numero que quiero mostar, r17 para indicar dónde lo quiero mostrar
; En main: cargo en r16 los leds a encender para formar el '0', y en r17 indico es el primero de los 4 dígitos. 
; Luego se llama la rutina de sacar la iformación serial.
;
; En el ejemplo para ver el numero 0, r16 debe ser 0b00000011 (orden de segmentos es abcdefgh, h es el punto), el binario va a representar un número al final
; y r17 debe ser 0b00010000 (dígito display de más a la derecha)


main:
	;ldi r16,0b00000011		;aquí saco el '0' por el Display
	nop
	rjmp main;


;-------------------------------------------------------------------------------------

; La rutina sacanum, envía lo que hay en r16 y r17 al display de 7 segmentos
; r16 - contiene los LEDs a prender/apagar 0 - prende, 1 - apaga porque es un micro de cátodo común
; r17 - contiene el dígito: r17 = 1000xxxx led de mas a la izquierda, decimales de minutos 0100xxxx minutos led siguiente 0010xxxx siguiente a la derecha decimales de segundos 0001xxxx el de mas a la derecha del dígito menos al más significativo, los segundos.

sacanum: 
	call	dato_serie
	mov		r16, r17
	call	dato_serie
	sbi		PORTD, 4		;PD.4 a 1, es LCH el reloj del latch
	cbi		PORTD, 4		;PD.4 a 0, 
	ret
	;Voy a sacar un byte por el 7seg
dato_serie:
	ldi		r18, 0x08 ; lo utilizo para contar 8 (8 bits)
loop_dato1:
	cbi		PORTD, 7		;SCLK = 0 reloj en 0 (limpio el registro) esto es para que no muestre el mismo numero de barido en todos los numeros del display.
	lsr		r16				;roto a la derecha r16 y el bit 0 se pone en el C (logical shift right) corro un lugar a la derecha, bit 7 se limpia y el cero pasa a acarreo
	brcs	loop_dato2		;salta si C=1 (carry)
	cbi		PORTB, 0		;SD = 0 escribo un 0 
	rjmp	loop_dato3
loop_dato2:
	sbi		PORTB, 0		;SD = 1 escribo un 1
loop_dato3:
	sbi		PORTD, 7		;SCLK = 1 reloj en 1
	dec		r18
	brne	loop_dato1		; cuando r17 llega a 0 corta y vuelve
	ret


; botones

;Guardamos el contexto

pcint:
	   in	r26, SREG		; guardo el contexto
	   sbis PINC, 1     ;sbis prueba si un bit está seteado y skipea en caso que si lo este
	   ldi	r29,0b00000010
	   sbis PINC, 2     ;prueba si el bit 2 está seteado o no 
	   ldi	r29,0b00000100
	   sbis PINC, 3
	   call _reset_contador
	   rjmp pcint_out

pcint_out:
		out SREG, r26
		reti

;-Interrupcion del reloj

; analogo al lab 3 donde hacemos un contador para contar los segundos 
_tmr0_int:
		in r17, SREG
		inc r23
		call _act_display
		dec r25
		breq _1hz
		rjmp _tmr0_out

_tmr0_out:
		out SREG, r17
	    reti						;retorno de la rutina de interrupción del Timer0

_1hz:
	sbrs r29,2
	inc r19
	ldi r25, 250				;aca veo tema frecuencia para que avance mas o menos rapido
	rjmp _tmr0_out

/*
 comparamos si lo que hay en el r23 es alguno de los numeros que asociamos a los dispalys 
 en caso que así sea se envá al _pos_numero
*/
_act_display:
	cpi r23, 1
	breq _pos_uno

	cpi r23, 2
	breq _pos_dos

	cpi r23, 3
	breq _pos_tres

	brne _pos_cuatro
	ret

/*
------------------------- las insrucciones siguientes lo que hacen es setear una posicion de salida para cada numero que queremos ver
 luego lo que hace es ir a un control de unidades para ir contando y viendo los casos bordes
*/

_pos_uno:							;seteamos posiciones de salida para cada valor del display 
	ldi r17, 0b00010000
	call _unidades
	call sacanum
	ret

_pos_dos:
	ldi r17,0b00100000
	call _decenas
	call sacanum
	ret

_pos_tres:
	ldi r17,0b01000000
	call _unidades_m
	call sacanum
	ret

_pos_cuatro:
	ldi r17,0b10000000
	call _decenas_m
	call sacanum
	ldi r23, 0
	ret

_unidades:
	mov r27, r19 ;se hace una copia en el registro 19 del registro 27, para poder ver el desborde en _desborde_unidades
	cpi r27,10
	brne _traductor
	call _desborde_unidades
	ret

_desborde_unidades:
	inc r20
	ldi r19,0		;recargamos en cero el 19 nuevamente
	mov r27,r19
	call _traductor
	ret

_decenas:
	mov r27, r20
	cpi r27,6
	brne _traductor
	call _desborde_decenas
	ret

_desborde_decenas:
	inc r21
	ldi r20,0
	mov r27,r20
	call _traductor
	ret

_unidades_m:
	mov r27, r21
	cpi r27,10
	brne _traductor
	call _desborde_unidades_m
	ret

_desborde_unidades_m:
	inc r22
	ldi r21,0
	mov r27,r21
	call _traductor
	ret

_decenas_m:
	mov r27, r22
	cpi r27,10
	brne _traductor
	call _desborde_decenas_m
	ret

_desborde_decenas_m:   ; desborda cuando las decenas llegan a  9 
	call _reset_contador
	mov r27,r22
	call _traductor
	ret

_reset_contador:   ; resetea el contador cuando llega a	10:00    
	ldi r19,0
	ldi r20,0
	ldi r21,0
	ldi r22,0
	ret

/*
 Esta interrupción chequea que lo que hay en el registro es el numero que se pregunta al lado y en caso que sea igual va a la 
 interrupción del numero y escribe ese número en la posicion que corresponde habiendo entrado a ella antes por _pos_numero
*/

_traductor:
	cpi r27,0
	breq num_cero
	cpi r27,1
	breq num_uno
	cpi r27,2
	breq num_dos
	cpi r27,3
	breq num_tres
	cpi r27,4
	breq num_cuatro
	cpi r27,5
	breq num_cinco
	cpi r27,6
	breq num_seis
	cpi r27,7
	breq num_siete
	cpi r27,8
	breq num_ocho
	cpi r27,9
	breq num_nueve

; tablita de valores decimales representadas en binario

num_cero:
	ldi r16, 0b00000011
	ret

num_uno:
	ldi r16, 0b10011111
	ret

num_dos:
	ldi r16, 0b00100101
	ret

num_tres:
	ldi r16, 0b00001101
	ret

num_cuatro:
	ldi r16, 0b10011001
	ret

num_cinco:
	ldi r16, 0b01001001
	ret

num_seis:
	ldi r16, 0b01000001
	ret

num_siete:
	ldi r16, 0b00011111
	ret

num_ocho:
	ldi r16, 0b00000001
	ret

num_nueve:
	ldi r16, 0b00011001
	ret
	
