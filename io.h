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

#define USB_EPTYPE_CONTROL  0b00 << 6
#define USB_EPTYPE_ISO      0b01 << 6
#define USB_EPTYPE_BULK     0b10 << 6
#define USB_EPTYPE_INT      0b11 << 6

#define USB_EPDIR_OUT       0b0
#define USB_EPDIR_IN        0b1

#define USB_EPSIZE_8        0b000 << 4
#define USB_EPSIZE_16       0b001 << 4
#define USB_EPSIZE_32       0b010 << 4
#define USB_EPSIZE_64       0b011 << 4
#define USB_EPSIZE_128      0b100 << 4
#define USB_EPSIZE_256      0b101 << 4

#define USB_EPBANK_1        0b00 << 2
#define USB_EPBANK_2        0b01 << 2

#define BIT_C 0
#define BIT_Z 1
#define BIT_N 2
#define BIT_V 3
#define BIT_S 4
#define BIT_H 5
#define BIT_T 6
#define BIT_I 7

#define CLOCK_DIV_1     0b0000
#define CLOCK_DIV_2     0b0001
#define CLOCK_DIV_4     0b0010
#define CLOCK_DIV_8     0b0011
#define CLOCK_DIV_16    0b0100
#define CLOCK_DIV_32    0b0101
#define CLOCK_DIV_64    0b0110
#define CLOCK_DIV_128   0b0111
#define CLOCK_DIV_256   0b1000

.macro SET_CLOCK_SPEED tempreg, div
    ldi \tempreg, 0x80
    sts CLKPR, \tempreg

    ldi \tempreg, \div
    sts CLKPR, \tempreg
.endm