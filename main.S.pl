#!/usr/bin/perl
use strict;

BEGIN {
    do "AVR.pm";
    die $@ if ($@);
}

BEGIN {
    #done in begin section, so that declared constants can be accessed further down
    memory_variable "current_configuration";
    memory_variable "hid_idle_period";
    emit ".text\n";
}

do "usb.pm";
die $@ if ($@);

do "timer.pm";
die $@ if ($@);

emit_global_sub "main", sub {
    SET_CLOCK_SPEED r16, CLOCK_DIV_1;

    CONFIGURE_GPIO(port=>GPIO_PORT_D, pin=>PIN_6, dir=>GPIO_DIR_OUT);

    #initialize register with commonly used "zero" value
    _clr r15_zero;

    #usb_init();

    timer1_init();

    #enable interrupts
    _sei;

    do_while {} \&_rjmp;
}