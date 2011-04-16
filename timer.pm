use strict;

#timer 3 is used to wait 100uS after the mux selector is changed,
#before reading the button states - to give the voltage level time to
#settle
sub timer3_init {
    #enable interrpt on timer compare match
    _ldi r16, MASK(OCIE3A);
    _sts TIMSK3, r16;

    #100uS @ 16mhz (1:1 prescalar)
    _ldi r16, 0x06;
    _sts OCR3AH, r16;
    _ldi r16, 0x40;
    _sts OCR3AL, r16;
}

sub enable_timer3 {
    my($tempreg) = shift;

    #select CTC (clear timer on compare), which compares against the OCR3A register
    #select clk/1
    #start the timer
    _ldi $tempreg, MASK(WGM32) | TIMER_CLK_1;
    _sts TCCR3B, $tempreg;
}

sub disable_timer3 {
    _sts TCCR3B, r15_zero;
    _sts TCNT3H, r15_zero;
    _sts TCNT3L, r15_zero;
}

emit_global_sub "t3_int", sub {
    _push r16;
    _push r17;
    _push r18;
    _push r19;
    _push r20;
    _push zl;
    _push zh;

    disable_timer3;

    my($r16_button_states) = "r16";
    my($r17_descriptor) = "r17";

    #read the current selector and button states
    _in $r16_button_states, IO(PIND);
    _mov $r17_descriptor, $r16_button_states;
    _swap $r16_button_states;
    _cbr $r16_button_states, 0xf0;
    _cbr $r17_descriptor, 0xf0;

    #update selector
    {
        _mov r18, $r17_descriptor;

        block {
            #calculate the next selector value
            _dec r18;
            _brbc BIT_N, block_end;

            #set it back to the max value if we've gone past 0
            _ldi r18, 0x0c;
        };

        #combine the selector back into r18 and write it to the port
        _in r19, IO(PORTD);
        _cbr r19, 0x0f;
        _or r18, r19;
        _out IO(PORTD), r18;
    }

    #restart the timer
    enable_timer3 r19;

    #check for button presses/releases
    block {
        _ldi zl, lo8(button_states);
        _ldi zh, hi8(button_states);
        _add zl, $r17_descriptor;
        _adc zh, r15_zero;

        _ld r18, "z";

        _eor r18, $r16_button_states;
        block {
            _brne block_end;
            _rjmp block_end parent;
        };

        #we have at least 1 event, iterate through the 4 bits and add any events
        #to the queue
        _st "z", $r16_button_states;

        for (my $i=0; $i<4; $i++) {
            #We could factor out some of this logic, but there is a fairly low chance
            #of more than 1 button changing state, so it is actually better to "inline"
            #the logic into each block, and keep the fast path as fast as possible
            block {
                _sbrs r18, $i;
                _rjmp block_end;

                #we found an event - process it

                #calculate the button index
                _mov r19, $r17_descriptor;
                _lsl r19;
                _lsl r19;
                if ($i) {
                    _ldi r20, $i;
                    _add r19, r20;
                }

                #store whether it was a button press (1) or release (0) in the MSB of r19
                _bst $r16_button_states, $i;
                _bld r19, 7;

                _ldi zh, hi8(button_event_queue);

                #grab the tail and head, and make sure there's room in the queue
                _lds zl, button_event_tail;
                _lds r20, button_event_head;
                _dec r20;

                block {
                    #if there is no more room in the queue, bail out
                    _cp zl, r20;
                    _brne block_end;
                    _rjmp block_end parent;
                };

                _st "z+", r19;
                _sts button_event_tail, zl;
            };
        }
    };

    _pop zh;
    _pop zl;
    _pop r20;
    _pop r19;
    _pop r18;
    _pop r17;
    _pop r16;
    _reti;
};

#timer 1 is currently used for debugging
sub timer1_init {
    #enable interrupt on timer compare match
    _ldi r16, MASK(OCIE1A);
    _sts TIMSK1, r16;

    #2s delay @ 16mhz (1:1024 prescalar)
    _ldi r16, 0x7A;
    _sts OCR1AH, r16;
    _ldi r16, 0x12;
    _sts OCR1AL, r16;

    #select CTC (clear timer on compare), which compares against the OCR1A register
    #select clk/1024
    #start the timer
    _ldi r16, MASK(WGM12) | TIMER_CLK_1024;
    _sts TCCR1B, r16;
}

emit_global_sub "t1_int", sub {
    _push r16;

    block {
        #if led is on
        block {
            _sbis IO(PORTD), 6;
            _rjmp block_end;

            _cbi IO(PORTD), 6;

            SELECT_EP r16, EP_1;

            block {
                _lds r16, UEINTX;
                _sbrs r16, RWAL;
                _rjmp block_begin;
            };

            _ldi r16, 21;

            block {
                _sts UEDATX, r15_zero;
                _dec r16;
                _brne block_begin;
            };

            _lds r16, UEINTX;
            _andi r16, ~(MASK(FIFOCON) | MASK(NAKINI) | MASK(RXOUTI) | MASK(TXINI)) & 0xFF;
            _sts UEINTX, r16;

            _rjmp block_end parent;
        };
        #else
        indent_block {
            _sbi IO(PORTD), 6;

            SELECT_EP r16, EP_1;

            block {
                _lds r16, UEINTX;
                _sbrs r16, RWAL;
                _rjmp block_begin;
            };

            #send an 'a'
            _ldi r16, 0x04;
            _sts UEDATX, r16;

            _ldi r16, 20;

            block {
                _sts UEDATX, r15_zero;
                _dec r16;
                _brne block_begin;
            };

            _lds r16, UEINTX;
            _andi r16, ~(MASK(FIFOCON) | MASK(NAKINI) | MASK(RXOUTI) | MASK(TXINI)) & 0xFF;
            _sts UEINTX, r16;
        };
    };

    _pop r16;
    _reti;
}