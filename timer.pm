use strict;

sub timer1_init {
    #enable interrupt on timer compare match
    _ldi r16, MASK(OCIE1A);
    _sts TIMSK1, r16;

    #2s delay @ 16mhz
    _ldi r16, 0x7A;
    _sts OCR1AH, r16;
    _ldi r16, 0x12;
    _sts OCR1AL, r16;

    #select CTC (clear timer on compare), which compares against the OCR1A register
    #select clk/64
    #start the timer
    _ldi r16, MASK(WGM12) | TIMER_CLK_1024;
    _sts TCCR1B, r16;
}

emit_global_sub "t1_int", sub {
    if_bit_set IO(PORTD), 6, sub {
        _cbi IO(PORTD), 6;

#         SELECT_EP r16, 1;
#
#         do_while {
#             _lds r16, UEINTX;
#             _sbrs r16, RWAL;
#         } \&_rjmp;
#
#         _ldi r16, 21;
#
#         do_while {
#             _sts UEDATX, r15_zero;
#             _dec r16;
#         } \&_brne;
#
#         _lds r16, UEINTX;
#         _andi r16, ~(MASK(FIFOCON) | MASK(NAKINI) | MASK(RXOUTI) | MASK(TXINI)) & 0xFF;
#         _sts UEINTX, r16;

        _reti;
    };
    #else
    indent();
    {
        _sbi IO(PORTD), 6;

#         SELECT_EP r16, 1;
#
#         do_while {
#             _lds r16, UEINTX;
#             _sbrs r16, RWAL;
#         } \&_rjmp;
#
#         #send an 'a'
#         _ldi r16, 0x04;
#         _sts UEDATX, r16;
#
#         _ldi r16, 20;
#
#         do_while {
#             _sts UEDATX, r15_zero;
#             _dec r16;
#         } \&_brne;
#
#         _lds r16, UEINTX;
#         _andi r16, ~(MASK(FIFOCON) | MASK(NAKINI) | MASK(RXOUTI) | MASK(TXINI)) & 0xFF;
#         _sts UEINTX, r16;

        _reti;
    }
    deindent();
}