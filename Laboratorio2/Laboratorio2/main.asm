;
; Ejemplo_Interrupción_Timer0.asm
;
; Created: 12/9/2021 22:00:38
; Author : curso de microprocesadores
;



; Empiezo con los vectores de interrupción
.ORG 0x0000
	jmp		start		;dirección de comienzo (vector de reset)  
.ORG 0x001C 
	jmp		_tmr0_int	;salto atención a rutina de comparación A del timer 0


; ---------------------------------------------------------------------------------------
; acá empieza el programa
start:
;configuro los puertos:
;	PB2 PB3 PB4 PB5	- son los LEDs del shield
    ldi		r16,	0b00111101	
	out		DDRB,	r16			;4 LEDs del shield son salidas
	out		PORTB,	r16			;apago los LEDs

	ldi		r16,	0b00000000	
	out		DDRC,	r16			;3 botones del shield son entradas
;-------------------------------------------------------------------------------------

;Configuro el TMR0 y su interrupcion.
	ldi		r16,	0b00000010	
	out		TCCR0A,	r16			;configuro para que cuente hasta OCR0A y vuelve a cero (reset on compare), ahí dispara la interrupción
	ldi		r16,	0b00000101	
	out		TCCR0B,	r16			;prescaler = 1024
	ldi		r16,	124	
	out		OCR0A,	r16			;comparo con 125
	ldi		r16,	0b00000010	
	sts		TIMSK0,	r16			;habilito la interrupción (falta habilitar global)
;-------------------------------------------------------------------------------------
;Inicializo algunos registros que voy a usar como variables.
	ldi		r24,	0x00		;inicializo r24 para un contador genérico
;-------------------------------------------------------------------------------------


;Programa principal ... acá puedo hacer lo que quiero

comienzo:
	sei		;habilito las interrupciones globales(set interrupt flag) en SREG
	sleep

loop1:
rjmp loop1


;RUTINAS
;-------------------------------------------------------------------------------------

; ------------------------------------------------
; Rutina de atención a la interrupción del Timer0.
; ------------------------------------------------
; recordar que el timer 0 fue configurado para interrumpir cada 125 ciclos (5^3), y tiene un prescaler 1024 = 2^10.
; El reloj de I/O está configurado @ Fclk = 16.000.000 Hz = 2^10*5^6; entonces voy a interrumpir 125 veces por segundo
; esto sale de dividir Fclk por el prescaler y el valor de OCR0A.
; 
; Esta rutina por ahora no hace casi nada, Ud puede ir agregando funcionalidades.
; Por ahora solo: cambia el valor de un LED en la placa, e incrementa un contador en r24.

_tmr0_int:	
		in		r16, SREG; guardar el contexto cuando se entra en la interrupción, SREG = CONTEXTO que va al r16.
		; AHORA HACEMOS LA INTERRUPCION YA CON EL CONTEXTO GUARDADO
L0:		inc		r24	 ;cuento cuántas veces entré en la rutina.	
L1:
		cpi		r24, 125	
L2:
		brne	L1		
		sbi		PINB,	3			;toggle LED

		; PRONTA LA INTERRUPCIÓN, TENEMOS QUE RECUPERAR EL CONTEXTO QUE HABIA EN SREG
		out		SREG, r16; out = recupera lo que estaba en r16, lo guarda en SREG con los valores originales, porque SREG se modificó durante la interrupción


_tmr0_out:
	    reti						;retorno de la rutina de interrupción del Timer0
