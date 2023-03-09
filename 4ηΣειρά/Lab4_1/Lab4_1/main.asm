.DSEG
_tmp_: .byte 2

.CSEG

rjmp main ; go to the start of the program
.org 0x10
rjmp ISR_TIMER1_OVF
.org 0x1C
rjmp ADC_INT

ADC_init:
ldi r24,(1<<REFS0) ; Vref: Vcc
out ADMUX,r24 ;MUX4:0 = 00000 for A0.
;ADC is Enabled (ADEN=1)
;ADC Interrupts are Enabled (ADIE=1)
;Set Prescaler CK/128 = 62.5Khz (ADPS2:0=111)
ldi r24,(1<<ADEN)|(1<<ADIE)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)
out ADCSRA,r24
ret


wait_msec:
push r24 ; 2 κύκλοι (0.250 μsec)
push r25 ; 2 κύκλοι
ldi r24 , low(998) ; φόρτωσε τον καταχ. r25:r24 με 998 (1 κύκλος - 0.125 μsec)
ldi r25 , high(998) ; 1 κύκλος (0.125 μsec)
rcall wait_usec ; 3 κύκλοι (0.375 μsec), προκαλεί συνολικά καθυστέρηση 998.375 μsec
pop r25 ; 2 κύκλοι (0.250 μsec)
pop r24 ; 2 κύκλοι
sbiw r24 , 1 ; 2 κύκλοι
brne wait_msec ; 1 ή 2 κύκλοι (0.125 ή 0.250 μsec)
ret ; 4 κύκλοι (0.500 μsec)

wait_usec:
sbiw r24 ,1 ; 2 κύκλοι (0.250 μsec)
nop ; 1 κύκλος (0.125 μsec)
nop ; 1 κύκλος (0.125 μsec)
nop ; 1 κύκλος (0.125 μsec)
nop ; 1 κύκλος (0.125 μsec)
brne wait_usec ; 1 ή 2 κύκλοι (0.125 ή 0.250 μsec)
ret ; 4 κύκλοι (0.500 μsec)

scan_row_sim:
out PORTC, r25 ; η αντίστοιχη γραμμή τίθεται στο λογικό ‘1’
push r24 ; τμήμα κώδικα που προστίθεται για τη σωστή
push r25 ; λειτουργία του προγραμματος απομακρυσμένης
ldi r24,low(500) ; πρόσβασης
ldi r25,high(500)
rcall wait_usec
pop r25
pop r24 ; τέλος τμήμα κώδικα
nop
nop ; καθυστέρηση για να προλάβει να γίνει η αλλαγή κατάστασης
in r24, PINC ; επιστρέφουν οι θέσεις (στήλες) των διακοπτών που είναι πιεσμένοι
andi r24 ,0x0f ; απομονώνονται τα 4 LSB όπου τα ‘1’ δείχνουν που είναι πατημένοι
ret ; οι διακόπτες.

scan_keypad_sim:
push r26 ; αποθήκευσε τους καταχωρητές r27:r26 γιατι τους
push r27 ; αλλάζουμε μέσα στην ρουτίνα
ldi r25 , 0x10 ; έλεγξε την πρώτη γραμμή του πληκτρολογίου (PC4: 1 2 3 A)
rcall scan_row_sim
swap r24 ; αποθήκευσε το αποτέλεσμα
mov r27, r24 ; στα 4 msb του r27
ldi r25 ,0x20 ; έλεγξε τη δεύτερη γραμμή του πληκτρολογίου (PC5: 4 5 6 B)
rcall scan_row_sim
add r27, r24 ; αποθήκευσε το αποτέλεσμα στα 4 lsb του r27
ldi r25 , 0x40 ; έλεγξε την τρίτη γραμμή του πληκτρολογίου (PC6: 7 8 9 C)
rcall scan_row_sim
swap r24 ; αποθήκευσε το αποτέλεσμα
mov r26, r24 ; στα 4 msb του r26
ldi r25 ,0x80 ; έλεγξε την τέταρτη γραμμή του πληκτρολογίου (PC7: * 0 # D)
rcall scan_row_sim
add r26, r24 ; αποθήκευσε το αποτέλεσμα στα 4 lsb του r26
movw r24, r26 ; μετέφερε το αποτέλεσμα στους καταχωρητές r25:r24
clr r26 ; προστέθηκε για την απομακρυσμένη πρόσβαση
out PORTC,r26 ; προστέθηκε για την απομακρυσμένη πρόσβαση
pop r27 ; επανάφερε τους καταχωρητές r27:r26
pop r26
ret 

scan_keypad_rising_edge_sim:
push r22 ; αποθήκευσε τους καταχωρητές r23:r22 και τους
push r23 ; r26:r27 γιατι τους αλλάζουμε μέσα στην ρουτίνα
push r26
push r27
rcall scan_keypad_sim ; έλεγξε το πληκτρολόγιο για πιεσμένους διακόπτες
push r24 ; και αποθήκευσε το αποτέλεσμα
push r25
ldi r24 ,15 ; καθυστέρησε 15 ms (τυπικές τιμές 10-20 msec που καθορίζεται από τον
ldi r25 ,0 ; κατασκευαστή του πληκτρολογίου – χρονοδιάρκεια σπινθηρισμών)
rcall wait_msec
rcall scan_keypad_sim ; έλεγξε το πληκτρολόγιο ξανά και απόρριψε
pop r23 ; όσα πλήκτρα εμφανίζουν σπινθηρισμό
pop r22
and r24 ,r22
and r25 ,r23
ldi r26 ,low(_tmp_) ; φόρτωσε την κατάσταση των διακοπτών στην
ldi r27 ,high(_tmp_) ; προηγούμενη κλήση της ρουτίνας στους r27:r26
ld r23 ,X+
ld r22 ,X
st X ,r24 ; αποθήκευσε στη RAM τη νέα κατάσταση
st -X ,r25 ; των διακοπτών
com r23
com r22 ; βρες τους διακόπτες που έχουν «μόλις» πατηθεί
and r24 ,r22
and r25 ,r23
pop r27 ; επανάφερε τους καταχωρητές r27:r26
pop r26 ; και r23:r22
pop r23
pop r22
ret

keypad_to_ascii_sim:
push r26 ; αποθήκευσε τους καταχωρητές r27:r26 γιατι τους
push r27 ; αλλάζουμε μέσα στη ρουτίνα
movw r26 ,r24	; λογικό ‘1’ στις θέσεις του καταχωρητή r26 δηλώνουν
ldi r24 ,'*'	; τα παρακάτω σύμβολα και αριθμούς
sbrc r26 ,0
rjmp return_ascii
ldi r24 ,'0'
sbrc r26 ,1
rjmp return_ascii
ldi r24 ,'#'
sbrc r26 ,2
rjmp return_ascii
ldi r24 ,'D'
sbrc r26 ,3 ; αν δεν είναι ‘1’παρακάμπτει την ret, αλλιώς (αν είναι ‘1’)
rjmp return_ascii ; επιστρέφει με τον καταχωρητή r24 την ASCII τιμή του D.
ldi r24 ,'7'
sbrc r26 ,4
rjmp return_ascii
ldi r24 ,'8'
sbrc r26 ,5
rjmp return_ascii
ldi r24 ,'9'
sbrc r26 ,6
rjmp return_ascii ;
ldi r24 ,'C'
sbrc r26 ,7
rjmp return_ascii
ldi r24 ,'4' ; λογικό ‘1’ στις θέσεις του καταχωρητή r27 δηλώνουν
sbrc r27 ,0 ; τα παρακάτω σύμβολα και αριθμούς
rjmp return_ascii
ldi r24 ,'5'
sbrc r27 ,1
rjmp return_ascii
ldi r24 ,'6'
sbrc r27 ,2
rjmp return_ascii
ldi r24 ,'B'
sbrc r27 ,3
rjmp return_ascii
ldi r24 ,'1'
sbrc r27 ,4
rjmp return_ascii ;
ldi r24 ,'2'
sbrc r27 ,5
rjmp return_ascii
ldi r24 ,'3' 
sbrc r27 ,6
rjmp return_ascii
ldi r24 ,'A'
sbrc r27 ,7
rjmp return_ascii
clr r24
rjmp return_ascii
return_ascii:
pop r27 ; επανάφερε τους καταχωρητές r27:r26
pop r26
ret 

write_2_nibbles_sim:
push r24 ; τμήμα κώδικα που προστίθεται για τη σωστή
push r25 ; λειτουργία του προγραμματος απομακρυσμένης
ldi r24 ,low(6000) ; πρόσβασης
ldi r25 ,high(6000)
rcall wait_usec
pop r25
pop r24 ; τέλος τμήμα κώδικα
push r24 ; στέλνει τα 4 MSB
in r25, PIND ; διαβάζονται τα 4 LSB και τα ξαναστέλνουμε
andi r25, 0x0f ; για να μην χαλάσουμε την όποια προηγούμενη κατάσταση
andi r24, 0xf0 ; απομονώνονται τα 4 MSB και
add r24, r25 ; συνδυάζονται με τα προϋπάρχοντα 4 LSB
out PORTD, r24 ; και δίνονται στην έξοδο
sbi PORTD, PD3 ; δημιουργείται παλμός Enable στον ακροδέκτη PD3
cbi PORTD, PD3 ; PD3=1 και μετά PD3=0
push r24 ; τμήμα κώδικα που προστίθεται για τη σωστή
push r25 ; λειτουργία του προγραμματος απομακρυσμένης
ldi r24 ,low(6000) ; πρόσβασης
ldi r25 ,high(6000)
rcall wait_usec
pop r25
pop r24 ; τέλος τμήμα κώδικα
pop r24 ; στέλνει τα 4 LSB. Ανακτάται το byte.
swap r24 ; εναλλάσσονται τα 4 MSB με τα 4 LSB
andi r24 ,0xf0 ; που με την σειρά τους αποστέλλονται
add r24, r25
out PORTD, r24
sbi PORTD, PD3 ; Νέος παλμός Enable
cbi PORTD, PD3
ret

lcd_data_sim:
push r24 ; αποθήκευσε τους καταχωρητές r25:r24 γιατί τους
push r25 ; αλλάζουμε μέσα στη ρουτίνα
sbi PORTD, PD2 ; επιλογή του καταχωρητή δεδομένων (PD2=1)
rcall write_2_nibbles_sim ; αποστολή του byte
ldi r24 ,43 ; αναμονή 43μsec μέχρι να ολοκληρωθεί η λήψη
ldi r25 ,0 ; των δεδομένων από τον ελεγκτή της lcd
rcall wait_usec
pop r25 ;επανάφερε τους καταχωρητές r25:r24
pop r24
ret 

lcd_command_sim:
push r24 ; αποθήκευσε τους καταχωρητές r25:r24 γιατί τους
push r25 ; αλλάζουμε μέσα στη ρουτίνα
cbi PORTD, PD2 ; επιλογή του καταχωρητή εντολών (PD2=0)
rcall write_2_nibbles_sim ; αποστολή της εντολής και αναμονή 39μsec
ldi r24, 39 ; για την ολοκλήρωση της εκτέλεσης της από τον ελεγκτή της lcd.
ldi r25, 0 ; ΣΗΜ.: υπάρχουν δύο εντολές, οι clear display και return home,
rcall wait_usec ; που απαιτούν σημαντικά μεγαλύτερο χρονικό διάστημα.
pop r25 ; επανάφερε τους καταχωρητές r25:r24
pop r24
ret 

lcd_init_sim:
push r24 ; αποθήκευσε τους καταχωρητές r25:r24 γιατί τους
push r25 ; αλλάζουμε μέσα στη ρουτίνα

ldi r24, 40 ; Όταν ο ελεγκτής της lcd τροφοδοτείται με
ldi r25, 0 ; ρεύμα εκτελεί την δική του αρχικοποίηση.
rcall wait_msec ; Αναμονή 40 msec μέχρι αυτή να ολοκληρωθεί.
ldi r24, 0x30 ; εντολή μετάβασης σε 8 bit mode
out PORTD, r24 ; επειδή δεν μπορούμε να είμαστε βέβαιοι
sbi PORTD, PD3 ; για τη διαμόρφωση εισόδου του ελεγκτή
cbi PORTD, PD3 ; της οθόνης, η εντολή αποστέλλεται δύο φορές
ldi r24, 39
ldi r25, 0 ; εάν ο ελεγκτής της οθόνης βρίσκεται σε 8-bit mode
rcall wait_usec ; δεν θα συμβεί τίποτα, αλλά αν ο ελεγκτής έχει διαμόρφωση
 ; εισόδου 4 bit θα μεταβεί σε διαμόρφωση 8 bit
push r24 ; τμήμα κώδικα που προστίθεται για τη σωστή
push r25 ; λειτουργία του προγραμματος απομακρυσμένης
ldi r24,low(1000) ; πρόσβασης
ldi r25,high(1000)
rcall wait_usec
pop r25
pop r24 ; τέλος τμήμα κώδικα
ldi r24, 0x30
out PORTD, r24
sbi PORTD, PD3
cbi PORTD, PD3
ldi r24,39
ldi r25,0
rcall wait_usec 
push r24 ; τμήμα κώδικα που προστίθεται για τη σωστή
push r25 ; λειτουργία του προγραμματος απομακρυσμένης
ldi r24 ,low(1000) ; πρόσβασης
ldi r25 ,high(1000)
rcall wait_usec
pop r25
pop r24 ; τέλος τμήμα κώδικα
ldi r24,0x20 ; αλλαγή σε 4-bit mode
out PORTD, r24
sbi PORTD, PD3
cbi PORTD, PD3
ldi r24,39
ldi r25,0
rcall wait_usec
push r24 ; τμήμα κώδικα που προστίθεται για τη σωστή
push r25 ; λειτουργία του προγραμματος απομακρυσμένης
ldi r24 ,low(1000) ; πρόσβασης
ldi r25 ,high(1000)
rcall wait_usec
pop r25
pop r24 ; τέλος τμήμα κώδικα
ldi r24,0x28 ; επιλογή χαρακτήρων μεγέθους 5x8 κουκίδων
rcall lcd_command_sim ; και εμφάνιση δύο γραμμών στην οθόνη
ldi r24,0x0c ; ενεργοποίηση της οθόνης, απόκρυψη του κέρσορα
rcall lcd_command_sim
ldi r24,0x01 ; καθαρισμός της οθόνης
rcall lcd_command_sim
ldi r24, low(1530)
ldi r25, high(1530)
rcall wait_usec
ldi r24 ,0x06 ; ενεργοποίηση αυτόματης αύξησης κατά 1 της διεύθυνσης
rcall lcd_command_sim ; που είναι αποθηκευμένη στον μετρητή διευθύνσεων και
 ; απενεργοποίηση της ολίσθησης ολόκληρης της οθόνης
pop r25 ; επανάφερε τους καταχωρητές r25:r24
pop r24
ret

print_clear:
ldi r24,0x01 ;clear the lcd
rcall lcd_command_sim
ldi r24, 'C'
rcall lcd_data_sim
ldi r24, 'L'
rcall lcd_data_sim
ldi r24, 'E'
rcall lcd_data_sim
ldi r24, 'A'
rcall lcd_data_sim
ldi r24, 'R'
rcall lcd_data_sim
ret

print_gas_detected:
ldi r24,0x01 ;clear the lcd
rcall lcd_command_sim
ldi r24, 'G'
rcall lcd_data_sim
ldi r24, 'A'
rcall lcd_data_sim
ldi r24, 'S'
rcall lcd_data_sim
ldi r24, ' '
rcall lcd_data_sim
ldi r24, 'D'
rcall lcd_data_sim
ldi r24, 'E'
rcall lcd_data_sim
ldi r24, 'T'
rcall lcd_data_sim
ldi r24, 'E'
rcall lcd_data_sim
ldi r24, 'C'
rcall lcd_data_sim
ldi r24, 'T'
rcall lcd_data_sim
ldi r24, 'E'
rcall lcd_data_sim
ldi r24, 'D'
rcall lcd_data_sim
ret

main:
ldi r24, low(RAMEND) ;initialize stack pointer
out SPL, r24
ldi r24, high(RAMEND)
out SPH, r24
ldi r24, (1 << PC7) | (1 << PC6) | (1 << PC5) | (1 << PC4) ; 4 MSB of PORTC as outputs
out DDRC, r24
clr r24
out PORTC, r24 ;disable pull-ups
out DDRA, r24 ; PINA as input
ser r24
out DDRB, r24 ;PORTB as output
out DDRD, r24 ;PORTD as output
sts _tmp_, r24 ; initialize _tmp_
clr r24
ldi r18, 0x00
rcall lcd_init_sim ;initialize the lcd
rcall ADC_init

ldi r24 ,(0<<CS12) | (1<<CS11) | (1<<CS10) ; CK/64=125KHz
out TCCR1B ,r24

ldi r24,0xCF ; initialize TCNT1 for overflow after 0.1s
out TCNT1H ,r24 ; 0.1s = 12.500 cycles 65536-12500=53036=0xCF2C
ldi r24 ,0x2C
out TCNT1L ,r24

ldi r24 ,(1<<TOIE1) ; enable overflow interrupt of TCNT1
out TIMSK ,r24

ldi r18, 0x00 ; initialize led state
ldi r28, 0x00 ; initialize PB7
ldi r19, 0x02 ; previous state (gas(1)-no gas(0)) initialized at 2 so that we get an initial print
ldi r30, 0x00 ; 1 if a special team has entered. no speacial team has entered

sei ;enable all interrupts

digit1:
rcall scan_keypad_rising_edge_sim ;read the first number
rcall keypad_to_ascii_sim ;convert the button pressed to ascii
cpi r24,0x00 ;check if a button was pressed otherwise read again
breq digit1
mov r20,r24 ;Store the ascii code in r20
subi r20,0x30 ;then convert it to an integer

digit2:
rcall scan_keypad_rising_edge_sim ;same for the second number
rcall keypad_to_ascii_sim
cpi r24,0x00
breq digit2
mov r21,r24 ;Store the ascii code in r21
subi r21,0x30 ;then convert it to an integer

cpi r20,0x04 ;Check if both digits of the password are correct
brne wrong
cpi r21,0x05
brne wrong

correct: ;if they are
;cli ;disable interrupts-alarm
ldi r30 , 0x01 ; a special team has entered
ldi r19, 0x02 ; invalid previous state so that a new message is printed after 4s
ldi r24,0x01 ;clear the lcd
rcall lcd_command_sim
ldi r20, 0x80
or r20, r18
out PORTB,r20 ;PB7 on alongside led state
ldi r24, 'W' ;Print "WELCOME" on the lcd
rcall lcd_data_sim
ldi r24, 'E'
rcall lcd_data_sim
ldi r24, 'L'
rcall lcd_data_sim
ldi r24, 'C'
rcall lcd_data_sim
ldi r24, 'O'
rcall lcd_data_sim
ldi r24, 'M'
rcall lcd_data_sim
ldi r24, 'E'
rcall lcd_data_sim
ldi r24, ' '
rcall lcd_data_sim       
ldi r20,0xBE  ; each call of scan_keypad_rising_edge_sim takes longer than 19ms (19ms is the total delay time from delay routines).
			;we call it 190 times for a total delay ~4s

loop1:
ldi r31, 0x80
or r31, r18
out PORTB, r31 ;keep updating gas levels
dec r20
rcall scan_keypad_rising_edge_sim
cpi r20,0x00
brne loop1 ;keep reading from keypad and ignoring until 4s have passed
;clr r20
mov r20, r18 ; turn PB7 off
out PORTB,r20 ;turn off the leds
ldi r24,0x01 ;clear the lcd
rcall lcd_command_sim
;sei ; re-enable interrupts and alarm
ldi r30, 0x00 ;special team has exited
rjmp digit1 ;read a new code

wrong: ;if the wrong password was inserted
ldi r20,0x04 ;total of 4 blinks
outerloop:
dec r20
ldi r28, 0x80 ; PB7 on for 0.5s
ldi r21,0x18 ;each call of scan_keypad_rising_edge_sim takes longer than 19ms (19ms is the total delay time from delay routines).
				;we call it 24 times for a total delay of ~0.5s

inner1:
sbi PORTB, 7 ; Turn PB7 on for 0.5s
dec r21
rcall scan_keypad_rising_edge_sim ;keep reading digits but ignoring them for 0.5s
cpi r21,0x00
brne inner1

ldi r21,0x18 ;each call of scan_keypad_rising_edge_sim takes longer than 19ms (19ms is the total delay time from delay routines).
				;we call it 24 times for a total delay of ~0.5s

inner2:
cbi PORTB, 7 ; Then PB7 back off
dec r21
rcall scan_keypad_rising_edge_sim ;keep reading digits but ignoring them for 0.5s
cpi r21,0x00
brne inner2

cpi r20,0x00
brne outerloop ;total of four blinks
rjmp digit1 ;read a new password

ISR_TIMER1_OVF: ;every 0.1s
cpi r30, 0x01 ;check if a special team has entered
breq read_adc ;if yes don't blink the lights
ldi r16, 0x10
and r16, r18 ;isolate bit4 of r18 which indicates gas presence
cpi r16, 0x10;
breq gas

no_gas:
cpi r19, 0x00 ; if previous state was clear don't print clear again
breq skip_print_clear
rcall print_clear
skip_print_clear:
ldi r19,0x00 ; previous state = no gas
in r29, PORTB
andi r29, 0x80 ;Consider the state in which PB7 is
or r29, r18
out PORTB, r29 ;Print gas level alongside PB7
ldi r17,0x00 ;reset blink timer for gas alarm
jmp read_adc

gas:
cpi r19, 0x01 ; if previous state was gas_detected don't print gas detected again
breq skip_print_gas_detected
rcall print_gas_detected
skip_print_gas_detected:
ldi r19, 0x01 ; previous state = gas
inc r17
cpi r17,0x06 ;for the first 5*0.1=0.5s led's on then off for another 0.5s
brsh blink_off

blink_on:
;mov r29, r28
;or r29, r18
;out PORTB, r29
in r29, PORTB ;Consider the state in which PB7 is
andi r29, 0x80
or r29, r18
out PORTB, r29 ;Print gas level for 0.5s alongside PB7
;out PORTB, r18
jmp read_adc

blink_off:
;out PORTB, r28
;ldi r16, 0x00
in r29, PORTB ;Consider the state in which PB7 is
andi r29, 0x80
out PORTB, r29 ;Blink all leds off keeping PB7 as is
;out PORTB, r16
cpi r17,0x0A
brne read_adc
ldi r17,0x00 

read_adc:
SBI ADCSRA, 6 ;read from ADC
sei ; re-enable interrupts
ret

ADC_INT:
push r16 ;Store registers r16, r17 that will be used
push r17
in r16, ADCL ;retrieve the value read from ADC
in r17, ADCH
andi r17,0x03

ldi r18, 0b01111111
cpi r17, 0x01 ;if value read is higher than 90ppm
brsh go_back

ldi r18, 0b00111111
cpi r16, 0xF2 ;if value read is higher than 84ppm
brsh go_back

ldi r18, 0b00011111
cpi r16, 0xCD ;if value read is higher than 70ppm
brsh go_back

ldi r18, 0b00001111
cpi r16, 0xA8 ;if value read is higher than 56ppm
brsh go_back

ldi r18, 0b00000111
cpi r16, 0x83 ;if value read is higher than 42ppm
brsh go_back

ldi r18, 0b00000011
cpi r16, 0x5E ;if value read is higher than 28ppm
brsh go_back

ldi r18, 0b00000001
cpi r16, 0x39 ;if value read is higher than 14ppm
brsh go_back

ldi r18, 0x00 ;if value read is lower than 14ppm
go_back:
ldi r24,0xCF ; reset TCNT1
out TCNT1H ,r24 ; for overflow after 0.1s
ldi r24 ,0x2C
out TCNT1L ,r24
sei ; re-enable interrupts
pop r17
pop r16
ret

