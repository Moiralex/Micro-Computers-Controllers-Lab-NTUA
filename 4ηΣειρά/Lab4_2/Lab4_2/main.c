#include <avr/io.h>
#include <stdlib.h>
#include <avr/interrupt.h>

int led_state=0; //which leds are on
int previous_state;
int led7; // PB7 state
int blink_timer=0;
int value_read; //variable to store value read from adc
int special_team; //to check whether a special team has entered or not
int scan_keypad_rising_edge_sim(); //declaration of assembly functions. 16bit return value must be store in r25:r24
//void wait_msec(int msecs);
//void wait_usec(int usecs);
void initialize_variable();
void lcd_init_sim();
void clear_lcd();
void print_gas_detected();
void print_clear();
void print_welcome();

char keypad_to_ascii(int btn) { //returns the ascii character that corresponds to the first bit 1 found
	if ((btn & 0x0001)==0x0001) {
		return '*';
	}
	if ((btn & 0x0002)==0x0002) {
		return '0';
	}
	if ((btn & 0x0004)==0x0004) {
		return '#';
	}
	if ((btn & 0x0008)==0x0008) {
		return 'D';
	}
	if ((btn & 0x0010)==0x0010) {
		return '7';
	}
	if ((btn & 0x0020)==0x0020) {
		return '8';
	}
	if ((btn & 0x0040)==0x0040) {
		return '9';
	}
	if ((btn & 0x0080)==0x0080) {
		return 'C';
	}
	if ((btn & 0x0100)==0x0100) {
		return '4';
	}
	if ((btn & 0x0200)==0x0200) {
		return '5';
	}
	if ((btn & 0x0400)==0x0400) {
		return '6';
	}
	if ((btn & 0x0800)==0x0800) {
		return 'B';
	}
	if ((btn & 0x1000)==0x1000) {
		return '1';
	}
	if ((btn & 0x2000)==0x2000) {
		return '2';
	}
	if ((btn & 0x4000)==0x4000) {
		return '3';
	}
	if ((btn & 0x8000)==0x8000) {
		return 'A';
	}
	return 0;
}

ISR(TIMER1_OVF_vect) {
	if(special_team==0) { // if a special team has entered don't blink the leds
		if((led_state & 0x10) == 0x10) { //gas detected
			if(previous_state!=1) { //if previous state was gas detected don't print gas detected again
				clear_lcd();
				print_gas_detected();
				previous_state=1;
			}
			if(blink_timer<5) { //blink gas level leds for 0.5s
				led7=PORTB & 0x80;
				PORTB = led7 | led_state; //without interfering with PB7
				blink_timer++;
			}
			else { //then blink them off for another 0.5s
				led7 = PORTB & 0x80;
				PORTB = led7; //without interfering with PB7
				blink_timer++;
				if(blink_timer==10) { //reset blink timer for the next blink
					blink_timer=0;
				}
			}
		}
		else { //clear
			if(previous_state!=0) { //if previous state was clear don't print clear again
				clear_lcd();
				print_clear();
				previous_state=0;
			}
			led7 = PORTB & 0x80;
			PORTB = led7 | led_state; //print gas level without interfering with PB7
			blink_timer=0; //reset blink timer for gas alarm
		}
	}
	ADCSRA|=(1<<ADSC); //start conversion
	
	while(ADCSRA & (1<<ADSC)); //wait until conversion is done
	value_read = ADCW; //store value read from ADCW in value_read
	if(value_read>=0x117){ //if value read is higher than 90ppm
		led_state=0b01111111;
	}
	else if(value_read>=0xF2){ //if value read is higher than 84ppm
		led_state=0b00111111;
	}
	else if(value_read>=0xCD){ //if value read is higher than 70ppm
		led_state=0b00011111;
	}
	else if(value_read>=0xA8){ //if value read is higher than 56ppm
		led_state=0b00001111;
	}
	else if(value_read>=0x83){ //if value read is higher than 42ppm
		led_state=0b00000111;
	}
	else if(value_read>=0x5E){ //if value read is higher than 28ppm
		led_state=0b00000011;
	}
	else if(value_read>=0x39){ //if value read is higher than 14ppm
		led_state=0b00000001;
	}
	else{ //if value read is lower than 14ppm
		led_state=0;
	}
	
	
	TCNT1H=0xCF;
	TCNT1L=0x2C; //reset TCNT1 for overflow after 0.1s
}

int main(void)
{
	DDRC = 0xF0; //4 MSBs of PORTC as outputs 4LSBs as inputs
	PORTC = 0x00; //disable pull-up resistors
	DDRB = 0xFF; //PORTB as output
	DDRA = 0x00; //PORTA as input
	DDRD = 0xFF; //PORTD as output
	
	ADMUX = 0x40; //Vref: Vcc
	ADCSRA = (1<<ADEN)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0); //no interrupts
	
	TCCR1B = 0x03; //CK/64
	TCNT1H = 0xCF;
	TCNT1L = 0x2C; //initialize TCNT1 for overflow after 0.1s
	TIMSK = 0x04; //enable overflow interrupt for TCNT1
	
	int btn;
	int digit1, digit2;
	//scan_keypad_rising_edge_sim(); //just to instantiate _tmp_ assembly variable
	initialize_variable(); //initialize _tmp_
	lcd_init_sim(); //initialize lcd
	previous_state=2; //invalid previous state so that we get a print at the start
	special_team=0; //no special team has entered at the start
	sei(); //enable interrupts
	while (1)
	{
		btn=0;
		while(btn==0){
			btn=scan_keypad_rising_edge_sim(); //scan the keypad until a key is pressed
		}
		digit1=keypad_to_ascii(btn)-48; //translate the first key pressed to an ascii character then to an integer
		btn=0;
		while(btn==0){
			btn=scan_keypad_rising_edge_sim(); //wait until the second key is pressed
		}
		digit2=keypad_to_ascii(btn)-48; //translate the second key pressed to an ascii character then to an integer
		
		if((digit1==4)&&(digit2==5)) { //if password is correct
			//cli(); //disable interrupts
			special_team=1;
			PORTB=0x80|led_state; //light PB7 and gas indicator constantly
			clear_lcd();
			print_welcome();
			for(int i=0; i<190; ++i) {			//we need to keep scanning the keypad. Each scan takes longer than 19ms (19ms is the total delay time from delay routines)
				scan_keypad_rising_edge_sim();	//so we call it 190 times so that the leds stay on for ~4secs
				PORTB=0x80|led_state; //keep updating the gas level indicator
			}
			previous_state=2; //invalid previous state so that we get a print
			PORTB=led_state; //PB7 off
			special_team=0;
			//sei(); //re-enable interrupts
		}
		else { //if password is incorrect
			for(int i=0; i<4; ++i) { //total of four blinks
				PORTB|=(1<<PB7); //light PB7 without interfering with the rest leds for 0.5s
				for(int i=0; i<24; ++i) { //we need to keep scanning the keypad. Each scan takes longer than 19ms (19ms is the total delay time from delay routines)
					scan_keypad_rising_edge_sim(); //so we call it 24 times for a total of ~0.5secs
				}
				PORTB&=~(1<<PB7); //turn off PB7 without interfering with the rest leds for 0.5s
				for(int i=0; i<24; ++i) {
					scan_keypad_rising_edge_sim();
				}
			}
		} //read two numbers from the keypad again
	}
}



