.include "m16def.inc"

.DEF temp=r21
.DEF counter = r17


jmp start
.org 4
jmp interrupt1
reti

start: ldi r24, low(RAMEND) ; Αρχικοποίηση στοίβας στο τέλος της RAM
out SPL, r24
ldi r24, high(RAMEND)
out SPH, r24
clr counter
clr temp
out DDRA,temp
ser temp
out DDRC,temp
out DDRB, temp

LDI temp,0x80
OUT GIMSK, temp
LDI temp,0x0C
OUT MCUCR,temp
ldi temp, (1<<INT1)
out GICR, temp
SEI


clr r26
loop: out PORTC , r26
ldi r24 , low(100) 
ldi r25 , high(100) 
;rcall wait_msec
inc r26 ; Αύξησε τον μετρητή
rjmp loop ; Επανέλαβε

interrupt1:
sbis PINA, 7
jmp go_back
sbis PINA, 6
jmp go_back
inc counter
out PORTB, counter
go_back: sei
reti