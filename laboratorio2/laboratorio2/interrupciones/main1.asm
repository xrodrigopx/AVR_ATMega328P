;
; lab2.asm
;
; Created: 19/9
; Author : rperdomo
;



; Empiezo con los vectores de interrupci�n
.ORG 0x0000 ;rutina est�ndar
	jmp		start		;direcci�n de comienzo (vector de reset)
.org	0x0008 ;rutina de interrupcion externa
	jmp		interrupcion_externa 
.ORG 0x001C ;rutina del timer
	jmp		_tmr0_int	;salto atenci�n a rutina de comparaci�n A del timer 0


; ---------------------------------------------------------------------------------------
; ac� empieza el programa
start:
;configuro los puertos:
;	PB2 PB3 PB4 PB5	- son los LEDs del shield
    ldi	r16,	0b00111101	;edefino los led que voy a usar
	out	DDRB,	r16			;los defino como salida
	out	PORTB,	r16			;apago los LEDs

	ldi	r16,	0b00000000	
	out	DDRC,	r16			;3 botones del shield son entradas
;-------------------------------------------------------------------------------------

;Configuro el TMR0 y su interrupcion.
	ldi	r16,	0b00000010	
	out	TCCR0A,	r16			;configuro para que cuente hasta OCR0A y vuelve a cero (reset on compare), ah� dispara la interrupci�n
	ldi	r16,	0b00000101	;
	out	TCCR0B,	r16			;prescaler = 1024
	ldi	r16,	124			;
	out	OCR0A,	r16			;comparo con 124, cuando esto llega a 1024 interrumpe, entonces el led hace lo que le pedimos, pero no va a hacer nada si no habilitamos las int globales
	ldi	r16,	0b00000010	;
	sts	TIMSK0,	r16			;habilito la interrupci�n (falta habilitar global)
;-------------------------------------------------------------------------------------
;Inicializo algunos registros que voy a usar como variables.
	ldi	r24,	0x00		;inicializo r24 para un contador gen�rico
	ldi	r18,	0;mi registro de incrementos
	ldi	r19,	0;el registro del segundo bit
	ldi	r20,	0;el registro del tercer bit
;-------------------------------------------------------------------------------------
	ldi	r16, 0b00000010
	sts	PCICR,r16; habilito la interrupcion
	ldi	r16, 0b00000100
	sts	PCMSK1,r16; habilito la interrupt del portC



;Programa principal ... ac� puedo hacer lo que quiero

comienzo:
	sei							;habilito las interrupciones globales(set interrupt flag)

loop1:
	nop
	nop
	nop
	nop
	ori r16, 0xFF
	nop
	nop
	nop
	brne loop1  //branch not equal 0 la zero flag es 0 salta si la operacion anterior da cero por ende va a loop 2
loop2:
	nop
	nop
	nop
fin:
	rjmp loop2

;RUTINAS
;-------------------------------------------------------------------------------------

; ------------------------------------------------
; Rutina de atenci�n a la interrupci�n del Timer0.
; ------------------------------------------------
; recordar que el timer 0 fue configurado para interrumpir cada 125 ciclos (5^3), y tiene un prescaler 1024 = 2^10.
; El reloj de I/O est� configurado @ Fclk = 16.000.000 Hz = 2^10*5^6; entonces voy a interrumpir 125 veces por segundo
; esto sale de dividir Fclk por el prescaler y el valor de OCR0A.
; 
; Esta rutina por ahora no hace casi nada, Ud puede ir agregando funcionalidades.
; Por ahora solo: cambia el valor de un LED en la placa, e incrementa un contador en r24.

_tmr0_int: ;interrupt del timer
	in r17,SREG 			;este es el contexto
	inc	r24					
	cpi	r24,125				;comparamos
	breq count_secs	;aca comparamos el count_secs con 125, si es 125 
	rjmp _tmr0_out

count_secs:
	sbi PINB, 5
	inc r18; para 2 seg
	inc r19; para 4 seg
	inc r20; para 8 seg
	rjmp cambio_led ;aca vamos a empezar a cambiar los led

cambio_led:
	cpi r18, 2 ;compara si el r18 vale 2
	breq cambio_led2 ;la instruccion anterior es igual, as� que pasa a la siguiente instruccion
	cpi r19, 4; compara, 
	breq cambio_led3
	cpi r20, 8
	breq cambio_led4
	cpi r20, 15
	breq reiniciar_count
	rjmp _tmr0_out

cambio_led2:
	sbi PINB, 4
	ldi r18, 0
	rjmp cambio_led

cambio_led3:
	sbi PINB, 3
	ldi r19, 0
	rjmp cambio_led

cambio_led4:
	sbi PINB, 2
	ldi r20, 0
	rjmp cambio_led

reiniciar_count:
	ldi r18, 0
	ldi r19, 0
	ldi r20, 0
	rjmp _tmr0_out

_tmr0_out:
	out	SREG,r17			   
	reti						;retorno de la rutina de interrupci�n del Timer0

interrupcion_externa:
					
	in r17,SREG 	
	rjmp wait
					
wait:
	sbis PINC, 1
	rjmp salir
	sbis PINC, 3
	rjmp reiniciar
	rjmp wait
								
salir:
	out SREG,r17
	reti

reiniciar:
	ldi r18, 0
	ldi r19, 0
	ldi r20, 0
	ldi r16, 0b00111100
	out PORTB, r16
	rjmp salir
	
