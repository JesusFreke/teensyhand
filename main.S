#include <avr/io.h>
#include <avr/interrupt.h>
#include "io.h"

.text
    .global main
    main:
        sbi IO_DDRD, 6

        ;enable interrupts
        sei

        ;enable interrupt on timer compare match
        ldi r16, MASK(OCIE1A)
        sts TIMSK1, r16

        ;1s delay @ 2mhz
        ldi r16, 0x7A
        sts OCR1AH, r16
        ldi r16, 0x12
        sts OCR1AL, r16

        ;select CTC mode using OCR1A register
        ;select clk/64
        ;start the timer
        ldi r16, MASK(WGM12) | TIMER_CLK_64
        sts TCCR1B, r16

        loop:
            RJMP loop


    .global t1_int
    t1_int:
        sbis IO_PORTD, 6
        rjmp set_bit

        clear_bit:
            cbi IO_PORTD, 6
            reti

        set_bit:
            sbi IO_PORTD, 6
            reti
