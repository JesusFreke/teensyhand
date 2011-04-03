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

global_sub "usb_gen", sub {
    _reti;
};

global_sub "usb_enp", sub {
    _reti;
};