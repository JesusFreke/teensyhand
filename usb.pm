use strict;

use constant HID_LED_NUM_LOCK => 0;
use constant HID_LED_CAPS_LOCK => 1;
use constant HID_LED_SCROLL_LOCK => 2;

use constant SETUP_HOST_TO_DEVICE => 0 << 7;
use constant SETUP_DEVICE_TO_HOST => 1 << 7;

use constant SETUP_TYPE_STANDARD => 0 << 5;
use constant SETUP_TYPE_CLASS => 1 << 5;
use constant SETUP_TYPE_VENDOR => 2 << 5;

use constant SETUP_RECIPIENT_DEVICE => 0;
use constant SETUP_RECIPIENT_INTERFACE => 1;
use constant SETUP_RECIPIENT_ENDPOINT => 2;
use constant SETUP_RECIPIENT_OTHER => 3;

sub usb_init {
    #enable usb pad regulator and select usb device mode
    _ldi r16, MASK(UIMOD) | MASK(UVREGE);
    _sts UHWCON, r16;

    #enable USB module, with clock frozen
    _ldi r16, MASK(USBE) | MASK(FRZCLK);
    _sts USBCON, r16;

    #set USB PLL prescalar value
    _ldi r16, PLL_8 | MASK(PLLE);
    _sts PLLCSR, r16;

    block {
        _lds r16, PLLCSR;
        _bst r16, PLOCK;
        _brtc block_begin;
    };

    #enable VBUS pad
    _ldi r16, MASK(USBE) | MASK(OTGPADE);
    _sts USBCON, r16;

    #attach usb
    _ldi r16, 0;
    _sts UDCON, r16;

    #enable end of reset interrupt
    _ldi r16, MASK(EORSTE) | MASK(SOFE);
    _sts UDIEN, r16;
}

sub USB_WAIT_FOR_TXINI {
    my($tempreg) = shift;

    block {
        _lds $tempreg, UEINTX;
        _sbrs $tempreg, TXINI;
        _rjmp block_begin;
    };
}

sub USB_SEND_QUEUED_DATA {
    my($tempreg) = shift;

    _lds $tempreg, UEINTX;
    _cbr $tempreg, MASK(TXINI);
    _sts UEINTX, $tempreg;
}

sub USB_SEND_ZLP {
    my($tempreg) = shift;

    USB_WAIT_FOR_TXINI $tempreg;
    _cbr $tempreg, MASK(TXINI);
    _sts UEINTX, $tempreg;
}

emit_global_sub "usb_gen", sub {
    _push r16;
    _push r17;

    _lds r16, SREG;
    _push r16;

    _lds r16, UENUM;
    _push r16;

    #check for End of Reset interrupt
    _lds r16, UDINT;
    _sbrc r16, EORSTI;
    _rjmp "eor_int";

    #check for Start of Frame interrupt
    _lds r16, UDINT;
    _sbrc r16, SOFI;
    _call "sof_int";

    #clear USB device interrupts
    _ldi r16, 0;
    _sts UDINT, r16;


    _pop r16;
    _sts UENUM, r16;

    _pop r16;
    _sts SREG, r16;

    _pop r17;
    _pop r16;
    _reti;
};

#this interrupt occurs when the usb controller has finished reseting, and is ready to be used
emit_sub "eor_int", sub {
    SELECT_EP r16, EP_0;

    #enable ep0
    _ldi r16, MASK(EPEN);
    _sts UECONX, r16;

    #configure ep0
    _ldi r16, EPTYPE_CONTROL | EPDIR_OUT;
    _sts UECFG0X, r16;

    _ldi r16, EPSIZE_8 | EPBANK_SINGLE | MASK(ALLOC);
    _sts UECFG1X, r16;

    #enable setup packet interrupt
    _ldi r16, MASK(RXSTPE);
    _sts UEIENX, r16;

    _call "reset";

    #clear USB device interrupts
    _ldi r16, 0;
    _sts UDINT, r16;

    #reset the stack pointer
    _ldi r16, 0xFF;
    _sts SPL, r16;

    _ldi r16, 0x20;
    _sts SPH, r16;

    #jump back to the main loop on return
    _ldi r16, lo8(pm("main_loop"));
    _push r16;
    _ldi r16, hi8(pm("main_loop"));
    _push r16;

    _reti;
};

#this occurs when we receiver a usb start of frame packet, which occurs reliably every 1ms
#we use this to time the hid idle period
emit_sub "sof_int", sub {
    block {
        _lds r16, "hid_idle_ms_remaining";
        _lds r17, "hid_idle_ms_remaining + 1";

        _cp r16, r15_zero;
        _cpc r17, r15_zero;
        _breq block_end;

        _subi r16, 0x01;
        _sbci r17, 0x00;

        _sts "hid_idle_ms_remaining", r16;
        _sts "hid_idle_ms_remaining + 1", r17;
    };
    _ret;
};

{
    my($r10_max_packet_length) = "r10";

    emit_global_sub "usb_enp", sub {
        _push r10;
        _push r16;
        _push r17;
        _push r18;
        _push r19;
        _push r20;
        _push r21;
        _push r22;
        _push r23;
        _push r24;
        _push r25;
        _push zl;
        _push zh;

        _lds r16, SREG;
        _push r16;

        _lds r16, UENUM;
        _push r16;

        #check for endpoints with interrupts
        _lds r16, UEINT;

        #check EP0
        block {
            _sbrs r16, EPINT0;
            _rjmp block_end;

            SELECT_EP r16, EP_0;

            #setup max_packet_length shared register
            _ldi r16, 0x08;
            _mov $r10_max_packet_length, r16;

            _rjmp "handle_setup_packet";
        };
        _rjmp "usb_stall";

        emit_sub "usb_enp_end", sub {
            _pop r16;
            _sts UENUM, r16;

            _pop r16;
            _sts SREG, r16;

            _pop zh;
            _pop zl;
            _pop r25;
            _pop r24;
            _pop r23;
            _pop r22;
            _pop r21;
            _pop r20;
            _pop r19;
            _pop r18;
            _pop r17;
            _pop r16;
            _pop r10;
            _reti;
        };

        emit_sub "handle_setup_packet", sub {
            #check if we got an interrupt for a setup packet
            _lds r24, UEINTX;
            _sbrs r24, RXSTPI;
                _rjmp "usb_stall";

            #setup some local register aliases, for clarity
            my($r16_bmRequestType) = "r16";
            my($r17_bRequest) = "r17";
            my($r18_wValue_lo) = "r18";
            my($r19_wValue_hi) = "r19";
            my($r20_wIndex_lo) = "r20";
            my($r21_wIndex_hi) = "r21";
            my($r22_wLength_lo) = "r22";
            my($r23_wLength_hi) = "r23";

            #read in the setup packet
            _lds $r16_bmRequestType, UEDATX;
            _lds $r17_bRequest, UEDATX;
            _lds $r18_wValue_lo, UEDATX;
            _lds $r19_wValue_hi, UEDATX;
            _lds $r20_wIndex_lo, UEDATX;
            _lds $r21_wIndex_hi, UEDATX;
            _lds $r22_wLength_lo, UEDATX;
            _lds $r23_wLength_hi, UEDATX;

            #clear the setup interrupt bit
            _cbr r24, MASK(RXSTPI) | MASK(RXOUTI) | MASK(TXINI);
            _sts UEINTX, r24;

            #is it a class request?
            _sbrc $r16_bmRequestType, 5;
            _rjmp "handle_hid_packet";

            #is it a vendor request?
            _sbrc $r16_bmRequestType, 6;
            _rjmp "handle_vendor_packet";

            jump_table(value=>$r17_bRequest, initial_index=>0, invalid_value_label=>"setup_unknown", table=>[
                "setup_get_status",         #0x00
                "setup_clear_feature",      #0x01
                "setup_unknown",            #0x02
                "setup_set_feature",        #0x03
                "setup_unknown",            #0x04
                "setup_set_address",        #0x05
                "setup_get_descriptor",     #0x06
                "setup_set_descriptor",     #0x07
                "setup_get_configuration",  #0x08
                "setup_set_configuration",  #0x09
                "setup_get_interface",      #0x0a
                "setup_set_interface",      #0x0b
                "setup_synch_frame"         #0x0c
            ]);


            emit_sub "setup_unknown", sub {
                _rjmp "usb_stall";
            };

            emit_sub "handle_hid_packet", sub {
                jump_table(value=>$r17_bRequest, initial_index=>0, invalid_value_label=>"setup_unknown", table=>[
                    "setup_unknown",        #0x00
                    "hid_get_report",       #0x01
                    "hid_get_idle",         #0x02
                    "hid_get_protocol",     #0x03
                    "setup_unknown",        #0x04
                    "setup_unknown",        #0x05
                    "setup_unknown",        #0x06
                    "setup_unknown",        #0x07
                    "setup_unknown",        #0x08
                    "hid_set_report",       #0x09
                    "hid_set_idle",         #0x0a
                    "hid_set_protocol"      #0x0b
                ]);
            };

            emit_sub "handle_vendor_packet", sub {
                block {
                    _cpi $r17_bRequest, 0x01;
                    _brne block_end;
                    _rjmp "vendor_get_memory";
                };
                block {
                    _cpi $r17_bRequest, 0x02;
                    _brne block_end;
                    _rjmp "vendor_start_bootloader";
                };

                _rjmp "usb_stall";
            };

            emit_sub "setup_get_status", sub {
                block {
                    block {
                        _cpi $r16_bmRequestType, SETUP_DEVICE_TO_HOST | SETUP_TYPE_STANDARD | SETUP_RECIPIENT_DEVICE;
                        _brne block_end;

                        _sts UEDATX, r15_zero;
                        _sts UEDATX, r15_zero;

                        USB_SEND_QUEUED_DATA r16;
                        _rjmp "usb_enp_end";
                    };
                    block {
                        _cpi $r16_bmRequestType, SETUP_DEVICE_TO_HOST | SETUP_TYPE_STANDARD | SETUP_RECIPIENT_INTERFACE;
                        _brne block_end;

                        _cp $r20_wIndex_lo, r15_zero;
                        _cpc $r21_wIndex_hi, r15_zero;
                        _brne block_end parent;

                        _lds r16, "current_configuration";
                        _cpi r16, 0;
                        _breq block_end parent;

                        _sts UEDATX, r15_zero;
                        _sts UEDATX, r15_zero;

                        USB_SEND_QUEUED_DATA r16;
                        _rjmp "usb_enp_end";
                    };
                    block {
                        _cpi $r16_bmRequestType, SETUP_DEVICE_TO_HOST | SETUP_TYPE_STANDARD | SETUP_RECIPIENT_ENDPOINT;
                        _brne block_end;

                        block {
                            #is it endpoint 1?
                            _cpi $r20_wIndex_lo, 1;
                            _cpc $r21_wIndex_hi, r15_zero;
                            _brne block_end;

                            _lds r16, "current_configuration";
                            _cpi r16, 0;
                            _breq block_end parent;

                            SELECT_EP r16, EP_1;
                            _lds r16, UECONX;
                            _bst r16, STALLRQ;

                            _clr r17;
                            _bld r17, 0;

                            SELECT_EP r16, EP_0;

                            _sts UEDATX, r17;
                            _sts UEDATX, r15_zero;

                            USB_SEND_QUEUED_DATA r16;
                            _rjmp "usb_enp_end";
                        };
                        block {
                            #is it endpoint 0?
                            _cp $r20_wIndex_lo, r15_zero;
                            _cpc $r21_wIndex_hi, r15_zero;
                            _brne block_end;

                            _sts UEDATX, r15_zero;
                            _sts UEDATX, r15_zero;

                            USB_SEND_QUEUED_DATA r16;
                            _rjmp "usb_enp_end";
                        };
                    };
                };
                _rjmp "usb_stall";
            };

            emit_sub "setup_clear_feature", sub {
                _rjmp "usb_stall";
            };

            emit_sub "setup_set_feature", sub {
                _rjmp "usb_stall";
            };

            emit_sub "setup_set_address", sub {
                block {
                    _cpi $r16_bmRequestType, 0b00000000;
                    _brne block_end;

                    _cpi $r19_wValue_hi, 0;
                    _brne block_end;

                    _cpi $r18_wValue_lo, 0x80;
                    _brsh block_end;

                    #store the new address, but don't enable it yet
                    _sts UDADDR, $r18_wValue_lo;

                    USB_SEND_ZLP r24;

                    USB_WAIT_FOR_TXINI r24;

                    #enable the new address
                    _sbr $r18_wValue_lo, MASK(ADDEN);
                    _sts UDADDR, $r18_wValue_lo;

                    _rjmp "usb_enp_end";
                };
                _sbi IO(PORTD), 6;
                _rjmp "usb_stall";
            };

            emit_sub "setup_get_descriptor", sub {
                #if more than 255 bytes are requested, round down to 255
                #(i.e. set the low byte to 255 - the high byte is otherwise ignored)
                _cpse $r23_wLength_hi, r15_zero;
                _ldi $r22_wLength_lo, 0xff;

                #check for normal descriptor request
                block {
                    _cpi $r16_bmRequestType, 0b10000000;
                    _brne block_end;

                    jump_table(value=>$r19_wValue_hi, initial_index=>0, invalid_value_label=>"setup_get_descriptor_end", table=>[
                        "setup_get_descriptor_end",                         #0x00
                        "setup_get_device_descriptor",                      #0x01
                        "setup_get_configuration_descriptor",               #0x02
                        "setup_get_string_descriptor",                      #0x03
                    ]);
                };

                #check for HID class descriptor request
                block {
                    _cpi $r16_bmRequestType, 0b10000001;
                    _brne block_end;

                    _cpi $r19_wValue_hi, DESC_HID_REPORT;
                    _breq "setup_get_hid_report_descriptor";
                };

                #otherwise, unsupported
                emit "setup_get_descriptor_end:\n";
                    _rjmp "usb_stall";

                emit_sub "setup_get_device_descriptor", sub {
                    my($descriptor) = get_descriptor("DEVICE_DESCRIPTOR");
                    _ldi zl, lo8($descriptor->{name});
                    _ldi zh, hi8($descriptor->{name});

                    #check if the requested number of bytes is less than the descriptor length
                    block {
                        _cpi $r22_wLength_lo, $descriptor->{size};
                        _brlo block_end;
                        _ldi $r22_wLength_lo, $descriptor->{size};
                    };

                    _rjmp "usb_send_program_data_short";
                };

                emit_sub "setup_get_configuration_descriptor", sub {
                    my($descriptor) = get_descriptor("CONFIGURATION_DESCRIPTORS");
                    _ldi zl, lo8($descriptor->{name});
                    _ldi zh, hi8($descriptor->{name});

                    #check if the requested number of bytes is less than the descriptor length
                    block {
                        _cpi $r22_wLength_lo, $descriptor->{size};
                        _brlo block_end;
                        _ldi $r22_wLength_lo, $descriptor->{size};
                    };

                    _rjmp "usb_send_program_data_short";
                };

                emit_sub "setup_get_string_descriptor", sub {
                     block {
                        my($descriptor) = get_descriptor("STRING_DESCRIPTOR_TABLE");
                         _cpi $r18_wValue_lo, $descriptor->{count};
                         _brsh block_end;

                        _ldi zl, lo8($descriptor->{name});
                        _ldi zh, hi8($descriptor->{name});
                        _lsl $r18_wValue_lo;
                        _add zl, $r18_wValue_lo;
                        _add zh, r15_zero;

                        #load the address of the string descriptor
                        _lpm r24, "z+";
                        _lpm r25, "z";
                        _mov zl, r24;
                        _mov zh, r25;

                        #load the descriptor length
                        _lpm r23, "z";

                        #check if the requested number of bytes is less than the descriptor length
                        block {
                            _cp $r22_wLength_lo, r23;
                            _brlo block_end;
                            _mov $r22_wLength_lo, r23;
                        };

                        _rjmp "usb_send_program_data_short";
                    };
                    _rjmp "usb_stall";
                };

                emit_sub "setup_get_hid_report_descriptor", sub {
                    my($descriptor) = get_descriptor("REPORT_DESCRIPTOR");
                    _ldi zl, lo8($descriptor->{name});
                    _ldi zh, hi8($descriptor->{name});

                    #check if the requested number of bytes is less than the descriptor length
                    block {
                        _cpi $r22_wLength_lo, $descriptor->{size};
                        _brlo block_end;
                        _ldi $r22_wLength_lo, $descriptor->{size};
                    };

                    _rjmp "usb_send_program_data_short";
                }
            };

            emit_sub "setup_set_descriptor", sub {
                _rjmp "usb_stall";
            };

            emit_sub "setup_get_configuration", sub {
                block {
                    USB_WAIT_FOR_TXINI r24;

                    _cpi $r22_wLength_lo, 0;
                    _breq block_end;

                    _lds r16, "current_configuration";
                    _sts UEDATX, r16;
                };

                USB_SEND_QUEUED_DATA r16;
                _rjmp "usb_enp_end";
            };

            emit_sub "setup_set_configuration", sub {
                _sts "current_configuration", $r18_wValue_lo;

                SELECT_EP r16, EP_1;

                #enable ep1
                _ldi r16, MASK(EPEN);
                _sts UECONX, r16;

                #configure ep1
                _ldi r16, EPTYPE_INT | EPDIR_IN;
                _sts UECFG0X, r16;

                _ldi r16, EPSIZE_32 | EPBANK_SINGLE | MASK(ALLOC);
                _sts UECFG1X, r16;

                #initialize LEDs
                _ldi r16, INVERSE_MASK(LED_NORMAL);
                _out IO(PORTC), r16;
                _sts "persistent_mode_leds", r16;

                #re-select ep0
                SELECT_EP r16, EP_0;

                _rjmp "usb_send_zlp";
            };

            emit_sub "setup_get_interface", sub {
                _rjmp "usb_stall";
            };

            emit_sub "setup_set_interface", sub {
                _rjmp "usb_stall";
            };

            emit_sub "setup_synch_frame", sub {
                _rjmp "usb_stall";
            };

            emit_sub "hid_get_report", sub {
                #if more than 255 bytes are requested, round down to 255
                #(i.e. set the low byte to 255 - the high byte is otherwise ignored)
                _cpse $r23_wLength_hi, r15_zero;
                _ldi $r22_wLength_lo, 0xff;

                #check if the requested number of bytes is less than the report length
                block {
                    _cpi $r22_wLength_lo, 0x15;
                    _brlo block_end;
                    _ldi $r22_wLength_lo, 0x15;
                };

                #TODO: we don't currently protect current_report when writing
                _ldi zl, lo8("current_report");
                _ldi zh, hi8("current_report");

                _rjmp "usb_send_memory_data_short";
            };

            emit_sub "hid_get_idle", sub {
                block {
                    USB_WAIT_FOR_TXINI r24;

                    _cpi $r22_wLength_lo, 0;
                    _breq block_end;

                    _lds r16, "hid_idle_period";
                    _lds r17, "hid_idle_period + 1";

                    _lsr r17;
                    _ror r16;

                    _lsr r17;
                    _ror r16;

                    _sts UEDATX, r16;
                };

                USB_SEND_QUEUED_DATA r16;
                _rjmp "usb_enp_end";
            };

            emit_sub "hid_get_protocol", sub {
                block {
                    USB_WAIT_FOR_TXINI r24;

                    _cpi $r22_wLength_lo, 0;
                    _breq block_end;

                    _lds r16, "current_protocol";
                    _sts UEDATX, r16;
                };

                USB_SEND_QUEUED_DATA r16;
                _rjmp "usb_enp_end";
            };

            emit_sub "hid_set_report", sub {
                block {
                    _lds r16, UEINTX;
                    _sbrs r16, RXOUTI;
                    _rjmp block_begin;
                };

                _in r16, IO(PORTC);
                _ori r16, LH_LED_MASK;

                _lds r17, UEDATX;
                #invert the values, to match the "0 is on" logic of the LEDs
                _com r17;

                #translate the hid led bits to the corresponding bits in PORTC
                _bst r17, HID_LED_NUM_LOCK;
                _bld r16, LED_NUM_LOCK;

                _bst r17, HID_LED_CAPS_LOCK;
                _bld r16, LED_CAPS_LOCK;

                _bst r17, HID_LED_SCROLL_LOCK;
                _bld r16, LED_SCROLL_LOCK;

                _out IO(PORTC), r16;

                #acknowledge receipt of data
                _cbr r16, MASK(RXOUTI);
                _sts UEINTX, r16;

                #send zlp
                _cbr r16, MASK(TXINI);
                _sts UEINTX, r16;

                _rjmp "usb_enp_end";
            };

            emit_sub "hid_set_idle", sub {
                #the high byte of wValue contains the new idle period, in 4ms increments
                _mov r23, $r19_wValue_hi;
                _clr r24;

                _lsl r23;
                _rol r24;

                _lsl r23;
                _rol r24;

                _sts "hid_idle_period", r23;
                _sts "hid_idle_ms_remaining", r23;

                _sts "hid_idle_period + 1", r24;
                _sts "hid_idle_ms_remaining + 1", r24;

                _rjmp "usb_send_zlp";
            };

            emit_sub "hid_set_protocol", sub {
                #the low byte of wValue contains the protocol. 0=boot, 1=report
                block {
                    _cpi $r18_wValue_lo, 0;
                    _brne block_end;

                    #it's the boot protocol
                    _sts "current_protocol", $r18_wValue_lo;

                    _ldi r16, 0x02;
                    _sts "key_array_offset", r16;

                    _ldi r16, 0x06;
                    _sts "key_array_length", r16;

                    _rjmp "usb_send_zlp";
                };
                block {
                    _cpi $r18_wValue_lo, 1;
                    _brne block_end;

                    #it's the report protocol
                    _sts "current_protocol", $r18_wValue_lo;

                    _ldi r16, 0x01;
                    _sts "key_array_offset", r16;

                    _ldi r16, 0x14;
                    _sts "key_array_length", r16;

                    _rjmp "usb_send_zlp";
                };
                _rjmp "usb_stall";
            };

            emit_sub "vendor_get_memory", sub {
                my($r23_current_packet_len) = "r23";
                my($r24_temp_reg) = "r24";
                my($r22_data_len) = "r22";

                block {
                    _cpi $r16_bmRequestType, 0b11000000;
                    _brne block_end;

                    #if more than 255 bytes are requested, round down to 255
                    #(i.e. set the low byte to 255 - the high byte is otherwise ignored)
                    _cpse $r23_wLength_hi, r15_zero;
                    _ldi $r22_wLength_lo, 0xff;

                    _mov zl, $r18_wValue_lo;
                    _mov zh, $r19_wValue_hi;

                    _rjmp "usb_send_memory_data_short";
                };
                _rjmp "usb_enp_end";
            };

            emit_sub "vendor_start_bootloader", sub {
                _cli;

                #disable usb
                _ldi r16, MASK(DETACH);
                _sts UDCON, r16;

                _ldi r16, MASK(FRZCLK);
                _sts USBCON, r16;

                #wait for 5ms after usb reset
                _ldi r24, 0x13;
                _ldi r25, 0x13;
                block {
                    _sbiw r24, 1;
                    _brne block_begin;
                };

                #disable timer 1
                _sts TCCR1B, r15_zero;
                _sts TIMSK1, r15_zero;

                #disable timer 3
                _sts TCCR3B, r15_zero;
                _sts TIMSK3, r15_zero;

                #clear out port configurations
                _sts DDRA, r15_zero;
                _sts DDRB, r15_zero;
                _sts DDRC, r15_zero;
                _sts DDRD, r15_zero;
                _sts DDRE, r15_zero;
                _sts DDRF, r15_zero;

                _sts PORTA, r15_zero;
                _sts PORTB, r15_zero;
                _sts PORTC, r15_zero;
                _sts PORTD, r15_zero;
                _sts PORTE, r15_zero;
                _sts PORTF, r15_zero;

                #jump to the bootloader
                _jmp 0xF800;
            };
        };
    };

    emit_sub "usb_stall", sub {
        _lds r16, UECONX;
        _sbr r16, MASK(STALLRQ);
        _sts UECONX, r16;
        _rjmp "usb_enp_end";
    };

    emit_sub "usb_send_zlp", sub {
        USB_SEND_ZLP r24;
        _rjmp "usb_enp_end";
    };

    #Sends up to 255 bytes of program memory to the currently selected usb endpoint
    #zh:zl should point to the data to send
    #r22 should contain the amount of data to send
    #r10 should contain the maximum packet length for this endpoint
    #r22, r23 and r24 will be clobbered on exit
    emit_sub "usb_send_program_data_short", sub {
        my($r22_data_len) = "r22";
        my($r23_current_packet_len) = "r23";
        my($r24_temp_reg) = "r24";

        block {
            #load the size of the next packet into r23
            _mov $r23_current_packet_len, $r10_max_packet_length;

            #if data_len <= current_packet_len
            block {
                _cp $r23_current_packet_len, $r22_data_len;
                _brlo block_end;

                _mov $r23_current_packet_len, $r22_data_len;
            };

            #txini must be set before we queue any data
            USB_WAIT_FOR_TXINI r24;

            #queue the data for the next packet
            block {
                _lpm $r24_temp_reg, "z+";
                _sts UEDATX, $r24_temp_reg;
                _dec r23;
                _brne block_begin;
            };

            #send the data
            USB_SEND_QUEUED_DATA $r24_temp_reg;

            _sub $r22_data_len, $r10_max_packet_length;

            #if z is set, we are done sending data, and need to send a zlp
            #if c is set, we are done sending data, and don't need to send a zlp
            #if neither of the above, we have more data to send

            _brbs BIT_C, block_end;
            _brbc BIT_Z, block_begin;
            USB_SEND_ZLP r24;
        };

        _rjmp "usb_enp_end";
    };

    #Sends up to 255 bytes of data memory to the currently selected usb endpoint
    #zh:zl should point to the data to send
    #r22 should contain the amount of data to send
    #r10 should contain the maximum packet length for this endpoint
    #r22, r23 and r24 will be clobbered on exit
    emit_sub "usb_send_memory_data_short", sub {
        my($r22_data_len) = "r22";
        my($r23_current_packet_len) = "r23";
        my($r24_temp_reg) = "r24";

        block {
            #load the size of the next packet into r23
            _mov $r23_current_packet_len, $r10_max_packet_length;

            #if data_len <= current_packet_len
            block {
                _cp $r23_current_packet_len, $r22_data_len;
                _brlo block_end;

                _mov $r23_current_packet_len, $r22_data_len;
            };

            #txini must be set before we queue any data
            USB_WAIT_FOR_TXINI r24;

            #queue the data for the next packet
            block {
                _ld $r24_temp_reg, "z+";
                _sts UEDATX, $r24_temp_reg;
                _dec r23;
                _brne block_begin;
            };

            #send the data
            USB_SEND_QUEUED_DATA $r24_temp_reg;

            _sub $r22_data_len, $r10_max_packet_length;

            #if z is set, we are done sending data, and need to send a zlp
            #if c is set, we are done sending data, and don't need to send a zlp
            #if neither of the above, we have more data to send

            _brbs BIT_C, block_end;
            _brbc BIT_Z, block_begin;
            USB_SEND_ZLP r24;
        };

        _rjmp "usb_enp_end";
    };
}