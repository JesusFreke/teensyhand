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

        ldi r16, USB_EPSIZE_64 | USB_EPBANK_1 | MASK(ALLOC)
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

            #define r10_max_packet_len r10
            ldi r16, 0x40
            mov r10_max_packet_len, r16

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

        usb_send_zlp r24

        ;enable the new address
        sbr r18_wValue_lo, MASK(ADDEN)
        sts UDADDR, r18_wValue_lo

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

            ;TODO: do we need to send a zlp if 0 bytes are requested?
            cpi r22_wLength_lo, 0
            breq setup_get_descriptor_end

            ldi zl, lo8(DEVICE_DESCRIPTOR)
            ldi zh, hi8(DEVICE_DESCRIPTOR)
            
            ;check if the requested number of bytes is less than the descriptor length
            cpi r22_wLength_lo, 0x12
            brlo setup_get_device_descriptor_send_data
            ldi r22_wLength_lo, 0x12
            
            setup_get_device_descriptor_send_data:
            rjmp usb_send_data_short ;tail call

        setup_get_configuration_descriptor:
            .equ configuration_length, END_CONFIGURATION - CONFIGURATION

            ;if more than 255 bytes are requested, round down to 255
            ;(i.e. set the low byte to 255 - the high byte is otherwise ignored)
            cpse r23_wLength_hi, r15_zero
            ldi r22_wLength_lo, 0xFF

            ;TODO: do we need to send a zlp if 0 bytes are requested?
            cpi r22_wLength_lo, 0
            breq setup_get_descriptor_end

            ldi zl, lo8(CONFIGURATION_DESCRIPTOR)
            ldi zh, hi8(CONFIGURATION_DESCRIPTOR)
            
            ;check if the requested number of bytes is less than the total amount of data we have to send
            cpi r22_wLength_lo, configuration_length
            brlo setup_get_configuration_descriptor_send_data
            ldi r22_wLength_lo, configuration_length

            setup_get_configuration_descriptor_send_data:
            rjmp usb_send_data_short ;tail call

        setup_get_string_descriptor:
            ;if more than 255 bytes are requested, round down to 255
            ;(i.e. set the low byte to 255 - the high byte is otherwise ignored)
            cpse r23_wLength_hi, r15_zero
            ldi r22_wLength_lo, 0xFF

            ;TODO: do we need to send a zlp if 0 bytes are requested?
            cpi r22_wLength_lo, 0
            breq setup_get_descriptor_end

            cpi r18_wValue_lo, 0x05
            brsh setup_get_descriptor_end

            ;switch based on string index
            ldi zl, lo8(pm(string_descriptor_table))
            ldi zh, hi8(pm(string_descriptor_table))
            lsl r18_wValue_lo
            lsl r18_wValue_lo
            add zl, r18_wValue_lo
            adc zh, r15_zero
            ijmp

            string_descriptor_table:
                .macro string_descriptor_case index send_data
                    ldi zl, lo8(STRING_\index)
                    ldi zh, hi8(STRING_\index)
                    ldi r24, STRING_\index\()_END - STRING_\index
                    rjmp string_descriptor_table_end
                .endm

                ;string 0 - lang id table
                string_descriptor_case 0
                ;string 1 - manufacturer
                string_descriptor_case 1
                ;string 2 - product
                string_descriptor_case 2
                ;string 3 - serial number
                string_descriptor_case 3
                ;string 4 - configuration name
                string_descriptor_case 4

                .purgem string_descriptor_case
            string_descriptor_table_end:
            
            ;check if the requested number of bytes is less than the descriptor length
            cp r22_wLength_lo, r24
            brlo setup_get_string_descriptor_send_data
            mov r22_wLength_lo, r24
            
            setup_get_string_descriptor_send_data:
            rjmp usb_send_data_short ;tail call
            
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

    ;Sends up to 255 bytes to the currently selected usb endpoint
    ;zh:zl should point to the data to send
    ;r22 should contain the amount of data to send
    ;r10 should contain the maximum packet length for this endpoint
    ;r22, r23 and r24 will be clobbered on exit
    usb_send_data_short:
    #define r22_data_len r22
    #define r23_current_packet_len r23
    #define r24_temp_reg r24

        ;load the size of the next packet into r23
        mov r23_current_packet_len, r10_max_packet_len
        cp r23_current_packet_len, r22_data_len
        brlo usb_send_data_short_1
        ;if data_len <= current_packet_len
            mov r23_current_packet_len, r22_data_len
        usb_send_data_short_1:

        ;wait for txini to become set before queueing any data
        usb_wait_for_txini r24

        ;queue the data for the next packet
        usb_send_data_short_loop:
            lpm r24_temp_reg, z+
            sts UEDATX, r24_temp_reg
            dec r23
        brne usb_send_data_short_loop

        ;send the data
        usb_send_queued_data r24_temp_reg
        
        sub r22_data_len, r10_max_packet_len
        
        ;if z is set, we are done sending data, and need to send a zlp
        ;if c is set, we are done sending data, and don't need to send a zlp
        ;if neither of the above, we have more data to send
        
        brbs BIT_C, usb_send_data_short_end
        brbc BIT_Z, usb_send_data_short
        
        ;send a zlp
        usb_send_zlp r24
        
        usb_send_data_short_end:
    #undef r22_data_len
    #undef r23_current_packet_len
    #undef r24_temp_reg
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

#include "descriptors.h"