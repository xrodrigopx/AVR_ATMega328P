;
; AssemblerApplication8.asm
;
; Created: 1/9/2021 18:40:54
; Author : rperdomo
;
.include "./m328Pdef.inc"
.org 0x00 ;aca arranca el programa
; Replace with your application code
setup: ; configuro los puerto y pongo valores incinales
ldi r16,0b00111100; 
out DDRB,r16; configuro el puerto para para que los pines 5 al 2 sean salida
ldi r16,0b00000000;
out PORTB,r16;

start:


;PRENDIDO

prendo1:
	ldi r16,0b00111000; 
	out PORTB,r16; 
	call delay; 
	rjmp prendo2;
prendo2:
	ldi r16,0b00110100;
	out PORTB,r16;
	call delay;
	rjmp prendo3; 
prendo3:
	ldi r16,0b00101100; 
	out PORTB,r16;
	call delay;
    rjmp prendo4;
prendo4:
	ldi r16,0b00011100; 
	out PORTB,r16;
	call delay;
    rjmp prendo1r; //invertir el movimiento del LED
prendo1r:
	ldi r16,0b00011100;
	out PORTB,r16; 
	call delay; 
	rjmp prendo2r;
prendo2r:
	ldi r16,0b00101100; 
	out PORTB,r16;
	call delay;  
	rjmp prendo3r; 
prendo3r:
	ldi r16,0b00110100; 
	out PORTB,r16; 
	call delay;  
	rjmp prendo4r; 
prendo4r:
	ldi r16,0b00111000;
	out PORTB,r16; 
	call delay;  
	rjmp prendo1; 


	// para calcular el delay es important conocer la cantidad de diclos de reloj. 
	//en este caso el procesador del Atmel ATMega328P y el XplainedMini tienen una frecuencia de reloj de 16 millones de ciclos por segundo.
	//Por lo tanto, debemos ejecutar una cantidad de 16 millones de ciclos en un segundo para tener una intermitencia de los LED en el r16. para eso vamos a configurar el delay de la siguiente manera

delay:	    
	ldi  r18, 6; tenemos en el r18 cargado con un 6 HEX, lo mismo para el 19 y 20. No pueden sobrepasar el 255 por el buffer overflow (pueden pasar cositas)
	ldi  r19, 75;
	ldi  r20, 189;
	//vamos a dividir el loop en 3 etapas para que quedae mas legible, 
L1: 
	dec  r20; la instruccion DEC, tiene como valor iterable 1, decrementara el r20 en 1 punto y pasara a la siguiente instruccion.
	brne L1; BRNE chequea si r20 vale 0 mediante el flag Z, cuando el flag Z vale 1 o 0 dependera el status del registro inicial., si vale 0, salta a la siguiente instrucción, si no vale 0, sigue ejecutando dec, por lo que brne vale 1 siempre y cuando la flag no sea 0, y si es 0 y se brenchea pasa a valer 2


L2:
	dec  r19 //1
	brne L1
L3:
	dec  r18
	brne L1 

	RET 