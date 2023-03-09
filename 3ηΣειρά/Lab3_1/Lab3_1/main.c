#include <avr/io.h>
#include <stdlib.h>

int scan_keypad_rising_edge_sim(); //declaration of assembly functions. 16bit return value must be store in r25:r24
//void wait_msec(int msecs);
//void wait_usec(int usecs);
void initialize_variable();

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

int main(void)
{
	DDRC = 0xF0; //4 MSBs of PORTC as outputs 4LSBs as inputs
	PORTC = 0x00; //disable pull-up resistors
	DDRB = 0xFF; //PORTB as output
	
	int btn;
	int digit1, digit2;
	//scan_keypad_rising_edge_sim(); //just to instantiate _tmp_ assembly variable
	initialize_variable();
	while (1) 
    {
		btn=0;
		while(btn==0){
			btn=scan_keypad_rising_edge_sim(); //scan the keypad until a key is pressed
		}
		//PORTB=0x00;
		digit1=keypad_to_ascii(btn)-48; //translate the first key pressed to an ascii character then to an integer
		btn=0;
		while(btn==0){
			btn=scan_keypad_rising_edge_sim(); //wait until the second key is pressed
		}
		digit2=keypad_to_ascii(btn)-48; //translate the second key pressed to an ascii character then to an integer
		//PORTB = digit2;
		
		if((digit1==4)&&(digit2==5)) { //if password is correct
			PORTB=0xFF; //light all PORTB leds
			for(int i=0; i<190; ++i) {			//we need to keep scanning the keypad. Each scan takes longer than 19ms (19ms is the total delay time from delay routines)
				scan_keypad_rising_edge_sim();	//so we call it 190 times so that the leds stay on for ~4secs
			}
			PORTB=0x00; //PORTB leds off
		}
		else { //if password is incorrect
			for(int i=0; i<4; ++i) { //total of four blinks
				PORTB=0xFF; //light PORTB leds
				for(int i=0; i<24; ++i) { //we need to keep scanning the keypad. Each scan takes longer than 19ms (19ms is the total delay time from delay routines)
					scan_keypad_rising_edge_sim(); //so we call it 24 times for a total of ~0.5secs
				}
				PORTB=0x00; //then turn them off for another 0.5secs
				for(int i=0; i<24; ++i) {
					scan_keypad_rising_edge_sim(); 
				}
			}
		} //read two numbers from the keypad again
    }
}

