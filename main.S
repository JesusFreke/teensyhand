#include <avr/io.h>
#include <avr/interrupt.h>
#include "io.h"

.text
    .global main
    main:
        sbi IO_DDRD, 6

        ;enable interrupts
        sei

        ;enable interrupt on timer overflow
        ldi r16, 0b1
        sts TIMSK1, r16

        ;select clk/64 and start the timer
        ldi r16, 0b011
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
