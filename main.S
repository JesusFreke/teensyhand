#include <avr/io.h>
#include <avr/interrupt.h>
#include "io.h"

.text
    .global main
    main:
        sbi IO_DDRD, 6

        ;enable usb pad regulator and select usb device mode
        ldi r16, MASK(UIMOD) | MASK(UVREGE)
        sts UHWCON, r16

        ;enable USB module, with clock frozen
        ldi r16, MASK(USBE) | MASK(FRZCLK)
        sts USBCON, r16

        ;set USB PLL prescalar value
        ldi r16, USB_PLL_8 | MASK(PLLE)
        sts PLLCSR, r16

        ;wait for USB PLL lock
        pll_lock:
            lds r16, PLLCSR
            bst r16, PLOCK
            brtc pll_lock

        ;enable VBUS pad
        ldi r16, MASK(USBE) | MASK(OTGPADE)
        sts USBCON, r16

        ;attach usb
        ldi r16, 0
        sts UDCON, r16

        ;enable end of reset interrupt
        ldi r16, MASK(EORSTE)
        sts UDIEN, r16

        ;enable interrupts
        sei

        RJMP loop

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

    .global usb_gen
    usb_gen:
        lds r16, UDINT
        sbrc r16, EORSTI
        call eor_int

        ;clear USB device interrupts
        ldi r16, 0
        sts UDINT, r16

        reti

    eor_int:
        ;select ep0
        ldi r16, 0
        sts UENUM, r16

        ;enable ep0
        ldi r16, MASK(EPEN)
        sts UECONX, r16

        ;configure ep0
        ldi r16, USB_EPTYPE_CONTROL | USB_EPDIR_OUT
        sts UECFG0X, r16

        ldi r16, USB_EPSIZE_8 | USB_EPBANK_1 | MASK(ALLOC)
        sts UECFG1X, r16

        ;enable setup packet interrupt
        ldi r16, MASK(RXSTPE)
        sts UEIENX, r16

        ret

    .global usb_enp
    usb_enp:
        ;check for setup interrupt
        lds r16, UEINTX
        bst r16, RXSTPI
        brts setup_int
        reti

    setup_int:
        sbi IO_PORTD, 6
        reti

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
