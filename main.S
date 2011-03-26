#include <avr/io.h>
#include <avr/interrupt.h>
#include "io.h"
#include "usb.h"

#define zl ZL
#define zh ZH

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

        ldi r16, USB_EPSIZE_32 | USB_EPBANK_1 | MASK(ALLOC)
        sts UECFG1X, r16

        ;enable setup packet interrupt
        ldi r16, MASK(RXSTPE)
        sts UEIENX, r16

        ret

    .global usb_enp
    usb_enp:
        ;check for endpoints with interrupts
        lds r0, UEINT

        ;check EP0
            bst r0, EPINT0
            brtc usb_enp_end

            ;select ep0
            ldi r16, 0
            sts UENUM, r16

            call handle_setup_packet
            ;call handle_ep_int
    usb_enp_end:
        reti

    handle_setup_packet:
        lds r24, UEINTX
        sbrs r24, RXSTPI
        ret

        #define r16_bmRequestType r16
        lds r16_bmRequestType, UEDATX
        #define r17_bRequest r17
        lds r17_bRequest, UEDATX
        #define r18_wValue_lo r18
        lds r18_wValue_lo, UEDATX
        #define r19_wValue_hi r19
        lds r19_wValue_hi, UEDATX
        #define r20_wIndex_lo r20
        lds r20_wIndex_lo, UEDATX
        #define r21_wIndex_hi r21
        lds r21_wIndex_hi, UEDATX
        #define r22_wLength_lo r22
        lds r22_wLength_lo, UEDATX
        #define r23_wLength_hi r23
        lds r23_wLength_hi, UEDATX

        cbr r24, MASK(RXSTPI)
        sts UEINTX, r24

        cpi r17_bRequest, 0x0D
        brsh setup_unknown

        ldi zl, lo8(pm(setup_request_table))
        ldi zh, hi8(pm(setup_request_table))
        add zl, r17_bRequest
        #define r15_zero r15
        clr r15_zero
        adc zh, r15_zero
        ijmp

        setup_request_table:
        /*0x00*/ rjmp setup_get_status
        /*0x01*/ rjmp setup_clear_feature
        /*0x02*/ rjmp setup_unknown
        /*0x03*/ rjmp setup_set_feature
        /*0x04*/ rjmp setup_unknown
        /*0x05*/ rjmp setup_set_address
        /*0x06*/ rjmp setup_get_descriptor
        /*0x07*/ rjmp setup_set_descriptor
        /*0x08*/ rjmp setup_get_configuration
        /*0x09*/ rjmp setup_set_configuration
        /*0x0A*/ rjmp setup_get_interface
        /*0x0B*/ rjmp setup_set_interface
        /*0x0C*/ rjmp setup_synch_frame

    setup_unknown:
        ret

    setup_get_status:
        ret

    setup_clear_feature:
        ret

    setup_set_feature:
        ret

    setup_set_address:
        cpi r16_bmRequestType, 0b00000000
        brne setup_set_address_end

        cpi r19_wValue_hi, 0
        brne setup_set_address_end

        cpi r18_wValue_lo, 0x80
        brsh setup_set_address_end

        ;store the new address, but don't enable it yet
        sts UDADDR, r18_wValue_lo

        setup_set_address_wait_for_txini:
        lds r24, UEINTX
        andi r24, MASK(TXINI)
        breq setup_set_address_wait_for_txini

        ;send zlp
        lds r24, UEINTX
        cbr r24, MASK(TXINI)
        sts UEINTX, r24

        ;enable the new address
        sbr r18_wValue_lo, MASK(ADDEN)
        sts UDADDR, r18_wValue_lo
        
        sbi IO_PORTD, 6

        setup_set_address_end:
        ret

    setup_get_descriptor:
        cpi r16_bmRequestType, 0b10000000
        brne setup_get_descriptor_end

        cpi r19_wValue_hi, 0x09
        brsh setup_get_descriptor_end

        ;switch based on requested descriptor type
        ldi zl, lo8(pm(setup_get_descriptor_table))
        ldi zh, hi8(pm(setup_get_descriptor_table))
        add zl, r19_wValue_hi
        adc zh, r15_zero
        ijmp

        setup_get_descriptor_end:
        ret

        setup_get_descriptor_table:
        /*0x00*/ rjmp setup_get_descriptor_end
        /*0x01*/ rjmp setup_get_device_descriptor
        /*0x02*/ rjmp setup_get_configuration_descriptor
        /*0x03*/ rjmp setup_get_string_descriptor
        /*0x04*/ rjmp setup_get_interface_descriptor
        /*0x05*/ rjmp setup_get_endpoint_descriptor
        /*0x06*/ rjmp setup_get_device_qualifier_descriptor
        /*0x07*/ rjmp setup_get_other_speed_configuration_descriptor
        /*0x08*/ rjmp setup_get_interface_power_descriptor

        setup_get_device_descriptor:
            ;if more than 255 bytes are requested, round down to 255
            ;(i.e. set the low byte to 255 - the high byte is otherwise ignored)
            cpse r23_wLength_hi, r15_zero
            ldi r22_wLength_lo, 0xFF

            cpi r22_wLength_lo, 0
            breq setup_get_descriptor_end

            setup_get_device_descriptor_wait_for_txini:
            lds r24, UEINTX
            andi r24, MASK(TXINI)
            breq setup_get_device_descriptor_wait_for_txini

            ldi zl, lo8(DEVICE_DESCRIPTOR)
            ldi zh, hi8(DEVICE_DESCRIPTOR)
            cp r22_wLength_lo, 0x12

            brlo setup_get_device_descriptor_send_loop
            ldi r22_wLength_lo, 0x12

            ;r22 now has the number of bytes to transfer
            ;the lesser of the descriptor size or the requested number of bytes
            setup_get_device_descriptor_send_loop:

            lpm r24, z+
            sts UEDATX, r24
            dec r22_wLength_lo

            brne setup_get_device_descriptor_send_loop

            lds r24, UEINTX
            cbr r24, MASK(TXINI)
            sts UEINTX, r24

            ret
        setup_get_configuration_descriptor:
            ret
        setup_get_string_descriptor:
            ret
        setup_get_interface_descriptor:
            ret
        setup_get_endpoint_descriptor:
            ret
        setup_get_device_qualifier_descriptor:
            ldi r16, MASK(STALLRQ) | MASK(EPEN)
            sts UECONX, r16
            ret
        setup_get_other_speed_configuration_descriptor:
            ret
        setup_get_interface_power_descriptor:
            ret

    setup_set_descriptor:
        ret

    setup_get_configuration:
        ret

    setup_set_configuration:
        ret

    setup_get_interface:
        ret

    setup_set_interface:
        ret

    setup_synch_frame:
        ret


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

DEVICE_DESCRIPTOR:
/*bLength*/             .byte 0x12
/*bDescriptorType*/     .byte DESC_DEVICE
/*bcdUSB*/              .word 0x0200
/*bDeviceClass*/        .byte 0xFF
/*bDeviceSubClass*/     .byte 0xFF
/*bDeviceProtocol*/     .byte 0xFF
/*bMaxPacketSize*/      .byte 0x20
/*idVendor*/            .word 0xFEED
/*idProduct*/           .word 0xFACE
/*bcdDevice*/           .word 0xF00D
/*iManufacturer*/       .byte 0x00
/*iProduct*/            .byte 0x00
/*iSerialNumber*/       .byte 0x00
/*bNumConfigurations*/  .byte 0x01