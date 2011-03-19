#include <avr/io.h>
#include <avr/interrupt.h>
#include "io.h"

.text
    .global main
    main:
        sbi IO_DDRD, 6

        loop:
            sbi IO_PORTD, 6

            ldi r16, 0xFF
            delay11:
                ldi r17, 0xFF

                delay12:
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    dec r17

                    brne delay12

                dec r16
                brne delay11

            cbi IO_PORTD, 6

            ldi r16, 0xFF
            delay21:
                ldi r17, 0xFF

                delay22:
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    dec r17
                    brne delay22

                dec r16
                brne delay21

            rjmp loop
