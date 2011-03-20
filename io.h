#define IO_PINA _SFR_IO_ADDR(PINA)
#define IO_DDRA _SFR_IO_ADDR(DDRA)
#define IO_PORTA _SFR_IO_ADDR(PORTA)
#define IO_PINB _SFR_IO_ADDR(PINB)
#define IO_DDRB _SFR_IO_ADDR(DDRB)
#define IO_PORTB _SFR_IO_ADDR(PORTB)
#define IO_PINC _SFR_IO_ADDR(PINC)
#define IO_DDRC _SFR_IO_ADDR(DDRC)
#define IO_PORTC _SFR_IO_ADDR(PORTC)
#define IO_PIND _SFR_IO_ADDR(PIND)
#define IO_DDRD _SFR_IO_ADDR(DDRD)
#define IO_PORTD _SFR_IO_ADDR(PORTD)
#define IO_PINE _SFR_IO_ADDR(PINE)
#define IO_DDRE _SFR_IO_ADDR(DDRE)
#define IO_PORTE _SFR_IO_ADDR(PORTE)
#define IO_PINF _SFR_IO_ADDR(PINF)
#define IO_DDRF _SFR_IO_ADDR(DDRF)
#define IO_PORTF _SFR_IO_ADDR(PORTF)

#define MASK(x) 1<<x

#define TIMER_CLK_OFF       0b000
#define TIMER_CLK_1         0b001
#define TIMER_CLK_8         0b010
#define TIMER_CLK_64        0b011
#define TIMER_CLK_256       0b100
#define TIMER_CLK_1024      0b101
#define TIMER_CLK_EXT_RISE  0b110
#define TIMER_CLK_EXT_FALL  0b111

#define USB_PLL_4           0b011 << 2
#define USB_PLL_8           0b101 << 2
