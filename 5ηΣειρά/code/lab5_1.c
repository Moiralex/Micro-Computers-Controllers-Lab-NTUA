#define F_CPU 8000000UL
#include <avr/io.h>
#include <util/delay.h>

//OC0 is connected to pin PB3
//OC1A is connected to pin PD5
//OC2 is connected to pin PD7

int counter;
int scan_keypad_rising_edge_sim();
void initialize_variable();
char Symbol1[16] = {'*', '0', '#', 'D', '7', '8', '9', 'C','4', '5', '6', 'B', '1', '2','3', 'A'};
	
char our_toascii(int myr2524){
	counter = 0;
	if(myr2524 != 0x0000){
		while((myr2524 & 0x0001) != 0x0001){
			myr2524 = myr2524 >> 1;
			counter += 1;
		}
		return Symbol1[counter];
	}
	else
	return 0;
}

void PWM_init()
{
    //set TMR0 in fast PWM mode with non-inverted output, prescale=8
    TCCR0 = (1<<WGM00) | (1<<WGM01) | (1<<COM01) | (1<<CS01); // WGM for fast PWM, COM0 for non-inverting mode and CS for prescaler=8
    DDRB|=(1<<PB3); //set PB3 pin as output
    //set TMR1A in fast PWM 8 bit mode with non-inverted output
    //prescale=8
    //pwmfreq=8*10^6/(8*256)=3906.25Hz for 8 bit registers we cannot alter TOP value so we can achieve exactly 4KHz
    TCCR1A = (1<<WGM10) | (1<<COM1A1); //COM1A to clear OC1A on compare match and WGM13-10=0001 for 8 bit mode 
    TCCR1B = (1<<WGM12) | (1<<CS11);   //WGM13-12=01 CS for prescaler=8
    DDRD|=(1<<PD5); //set PD5 pin as output
    //set TMR2 in fast PWM mode with non-inverted output, prescale=8
    TCCR2 = (1<<WGM20) | (1<<WGM21) | (1<<COM21) | (1<<CS21);
    DDRD|=(1<<PD7); //set PD7 pin as output
}

int main ()
{
    DDRC = 0xF0;
	DDRB = 0xFF;
    int read, ascii, timer0, timer1, timer2;
    PWM_init();
    initialize_variable();

    timer0 = 0;
    timer1 = 0;
    timer2 = 0;

    while(1){
        OCR0 = timer0;
        OCR1AL = timer1;
        OCR2 = timer2;
        _delay_ms(8);

        read = 0;
        while(read == 0x0000){
            /*if(TCNT0==250) //to get a 4kHZ frequency
                TCNT0=255;
            if(TCNT1L==250)
                TCNT1L=255;
            if(TCNT2==250)
                TCNT2=255;*/
            read = scan_keypad_rising_edge_sim();
        }
        ascii = our_toascii(read) - 48;
        switch(ascii){
            case 1:
                timer0++;
                break;
            case 2:
                timer0--;
                break;
            case 4:
                timer1++;
                break;
            case 5:
                timer1--;
                break;
            case 7:
                timer2++;
                break;
            case 8:
                timer2--;
                break;
        }

    }
}