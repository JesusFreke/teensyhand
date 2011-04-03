use strict;

sub usb_init {
    #initialize hid idle period to 500ms (125*4ms)
    _ldi r16, 125;
    _sts hid_idle_period, r16;

    #enable usb pad regulator and select usb device mode
    _ldi r16, MASK(UIMOD) | MASK(UVREGE);
    _sts UHWCON, r16;

    #enable USB module, with clock frozen
    _ldi r16, MASK(USBE) | MASK(FRZCLK);
    _sts USBCON, r16;

    #set USB PLL prescalar value
    _ldi r16, PLL_8 | MASK(PLLE);
    _sts PLLCSR, r16;

    do_while {
        _lds r16, PLLCSR;
        _bst r16, PLOCK;
    } \&_brtc;

    #enable VBUS pad
    _ldi r16, MASK(USBE) | MASK(OTGPADE);
    _sts USBCON, r16;

    #attach usb
    _ldi r16, 0;
    _sts UDCON, r16;

    #enable end of reset interrupt
    _ldi r16, MASK(EORSTE);
    _sts UDIEN, r16;
}

emit_global_sub "usb_gen", sub {
    #check for End of Reset interrupt
    _lds r16, UDINT;
    _sbrc r16, EORSTI;
    _call "eor_int";

    #clear USB device interrupts
    _ldi r16, 0;
    _sts UDINT, r16;

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

    _ldi r16, EPSIZE_64 | EPBANK_SINGLE | MASK(ALLOC);
    _sts UECFG1X, r16;

    #enable setup packet interrupt
    _ldi r16, MASK(RXSTPE);
    _sts UEIENX, r16;

    _ret;
};

emit_global_sub "usb_enp", sub {
    _reti;
};