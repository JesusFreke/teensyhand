#!/usr/bin/perl
use strict;

BEGIN {
    do "AVR.pm";
    die $@ if ($@);
}

BEGIN {
    emit ".section .bss\n";

    #make the button event queue be 256 byte aligned, so we can easily use mod 256 arithmetic
    #we should already be aligned since this should be the beginning of the .bss section, so
    #this is mostly informational
    emit ".align 8\n";

    #a queue to hold the button press and release events generated by logic associated with timer3
    #The lower 6 bits of each item hold the button index, while the MSB indicates if it was a
    #press (1) or release (0) event
    #We shouldn't near this much space, but it makes the math much cheaper
    #since we get mod 256 arithmetic "for free"
    memory_variable "button_event_queue", 0x100;

    #The head and tail of the button queue
    memory_variable "button_event_head", 1;
    memory_variable "button_event_tail", 1;

    #done in begin section, so that declared constants can be accessed further down
    memory_variable "current_configuration";
    memory_variable "hid_idle_period";

    #contains the button states for each selector value
    #the button states are stored in the low nibble of each byte.
    #The high nibbles are not used
    memory_variable "button_states", 13;

    #contains the current state of the hid report
    memory_variable "current_report", 21;

    #An array with an entry for each modifier key, which contains a count of the number
    #of keys currently pressed that "virtually" press that modifier key (like the # key,
    #which is actually the 3 key with a virtual shift). If both the # and $ keys were
    #pressed the count for the lshift modifier would be 2
    memory_variable "modifier_virtual_count", 8;

    #A bitmask that specifies which modifier keys are currently being physically pressed
    #This does not take into account any modifier keys that are only being "virtually"
    #pressed (see comments for modifier_virtual_count)
    memory_variable "modifier_physical_status", 1;

    #The address of the press table for the current keyboard mode
    memory_variable "current_press_table", 2;

    #The address of the press table for the "persistent" mode - that is, the mode that we go back
    #to after a temporary mode switch (i.e. the nas button)
    memory_variable "persistent_mode_press_table", 2;

    #The LED state associated with the persistent mode
    memory_variable "persistent_mode_leds", 1;

    #This contains a 2-byte entry for each button, which is the address of a routine to
    #execute when the button is released. The entry for a button is updated when the button
    #is pressed, to reflect the correct routine to use when it is released
    #In this way, we can correctly handle button releases when the mode changes while a
    #button is pressed
    memory_variable "release_table", 104;



    emit ".text\n";
}

use constant BUTTON_RELEASE => 0;
use constant BUTTON_PRESS => 1;

use constant LCTRL_OFFSET => 0;
use constant LSHIFT_OFFSET => 1;
use constant LALT_OFFSET => 2;
use constant LGUI_OFFSET => 3;
use constant RCTRL_OFFSET => 4;
use constant RSHIFT_OFFSET => 5;
use constant RALT_OFFSET => 6;
use constant RGUI_OFFSET => 7;

use constant RH_LED_MASK => 0b00001111;
use constant LH_LED_MASK => 0b11110000;
use constant LED_NAS => 0;
use constant LED_NORMAL => 1;
use constant LED_FUNC => 2;
use constant LED_10K => 3;
use constant LED_CAPS_LOCK => 4;
use constant LED_MOUSE => 5;
use constant LED_NUM_LOCK => 6;
use constant LED_SCROLL_LOCK => 7;

do "descriptors.pm";
die $@ if ($@);

do "usb.pm";
die $@ if ($@);

do "timer.pm";
die $@ if ($@);

do "actions.pm";
die $@ if ($@);

sub dequeue_input_event;
sub process_input_event;

emit_global_sub "main", sub {
    SET_CLOCK_SPEED r16, CLOCK_DIV_1;

    CONFIGURE_GPIO(port=>GPIO_PORT_A, pin=>PIN_0, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);
    CONFIGURE_GPIO(port=>GPIO_PORT_A, pin=>PIN_1, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);
    CONFIGURE_GPIO(port=>GPIO_PORT_A, pin=>PIN_2, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);
    CONFIGURE_GPIO(port=>GPIO_PORT_A, pin=>PIN_3, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);
    CONFIGURE_GPIO(port=>GPIO_PORT_A, pin=>PIN_4, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);
    CONFIGURE_GPIO(port=>GPIO_PORT_A, pin=>PIN_5, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);
    CONFIGURE_GPIO(port=>GPIO_PORT_A, pin=>PIN_6, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);
    CONFIGURE_GPIO(port=>GPIO_PORT_A, pin=>PIN_7, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);

    CONFIGURE_GPIO(port=>GPIO_PORT_B, pin=>PIN_0, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);
    CONFIGURE_GPIO(port=>GPIO_PORT_B, pin=>PIN_1, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);
    CONFIGURE_GPIO(port=>GPIO_PORT_B, pin=>PIN_2, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);
    CONFIGURE_GPIO(port=>GPIO_PORT_B, pin=>PIN_3, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);
    CONFIGURE_GPIO(port=>GPIO_PORT_B, pin=>PIN_4, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);
    CONFIGURE_GPIO(port=>GPIO_PORT_B, pin=>PIN_5, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);
    CONFIGURE_GPIO(port=>GPIO_PORT_B, pin=>PIN_6, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);
    CONFIGURE_GPIO(port=>GPIO_PORT_B, pin=>PIN_7, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);

    CONFIGURE_GPIO(port=>GPIO_PORT_C, pin=>PIN_0, dir=>GPIO_DIR_OUT);
    CONFIGURE_GPIO(port=>GPIO_PORT_C, pin=>PIN_1, dir=>GPIO_DIR_OUT);
    CONFIGURE_GPIO(port=>GPIO_PORT_C, pin=>PIN_2, dir=>GPIO_DIR_OUT);
    CONFIGURE_GPIO(port=>GPIO_PORT_C, pin=>PIN_3, dir=>GPIO_DIR_OUT);
    CONFIGURE_GPIO(port=>GPIO_PORT_C, pin=>PIN_4, dir=>GPIO_DIR_OUT);
    CONFIGURE_GPIO(port=>GPIO_PORT_C, pin=>PIN_5, dir=>GPIO_DIR_OUT);
    CONFIGURE_GPIO(port=>GPIO_PORT_C, pin=>PIN_6, dir=>GPIO_DIR_OUT);
    CONFIGURE_GPIO(port=>GPIO_PORT_C, pin=>PIN_7, dir=>GPIO_DIR_OUT);

    CONFIGURE_GPIO(port=>GPIO_PORT_D, pin=>PIN_0, dir=>GPIO_DIR_OUT);
    CONFIGURE_GPIO(port=>GPIO_PORT_D, pin=>PIN_1, dir=>GPIO_DIR_OUT);
    CONFIGURE_GPIO(port=>GPIO_PORT_D, pin=>PIN_2, dir=>GPIO_DIR_OUT);
    CONFIGURE_GPIO(port=>GPIO_PORT_D, pin=>PIN_3, dir=>GPIO_DIR_OUT);
    CONFIGURE_GPIO(port=>GPIO_PORT_D, pin=>PIN_4, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);
    CONFIGURE_GPIO(port=>GPIO_PORT_D, pin=>PIN_5, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);
    CONFIGURE_GPIO(port=>GPIO_PORT_D, pin=>PIN_6, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);
    CONFIGURE_GPIO(port=>GPIO_PORT_D, pin=>PIN_7, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);

    CONFIGURE_GPIO(port=>GPIO_PORT_E, pin=>PIN_0, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);
    CONFIGURE_GPIO(port=>GPIO_PORT_E, pin=>PIN_1, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);
    CONFIGURE_GPIO(port=>GPIO_PORT_E, pin=>PIN_2, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);
    CONFIGURE_GPIO(port=>GPIO_PORT_E, pin=>PIN_3, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);
    CONFIGURE_GPIO(port=>GPIO_PORT_E, pin=>PIN_4, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);
    CONFIGURE_GPIO(port=>GPIO_PORT_E, pin=>PIN_5, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);
    CONFIGURE_GPIO(port=>GPIO_PORT_E, pin=>PIN_6, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);
    CONFIGURE_GPIO(port=>GPIO_PORT_E, pin=>PIN_7, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);

    CONFIGURE_GPIO(port=>GPIO_PORT_F, pin=>PIN_0, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);
    CONFIGURE_GPIO(port=>GPIO_PORT_F, pin=>PIN_1, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);
    CONFIGURE_GPIO(port=>GPIO_PORT_F, pin=>PIN_2, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);
    CONFIGURE_GPIO(port=>GPIO_PORT_F, pin=>PIN_3, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);
    CONFIGURE_GPIO(port=>GPIO_PORT_F, pin=>PIN_4, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);
    CONFIGURE_GPIO(port=>GPIO_PORT_F, pin=>PIN_5, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);
    CONFIGURE_GPIO(port=>GPIO_PORT_F, pin=>PIN_6, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);
    CONFIGURE_GPIO(port=>GPIO_PORT_F, pin=>PIN_7, dir=>GPIO_DIR_IN, pullup=>GPIO_PULLUP_ENABLED);


    #initialize register with commonly used "zero" value
    _clr r15_zero;

    _ldi zl, 0x00;
    _ldi zh, 0x01;

    #reset all memory to 0s
    block {
        _st "z+", r15_zero;

        _cpi zl, 0x00;
        _brne block_begin;

        _cpi zh, 0x21;
        _brne block_begin;
    };

    usb_init();

    #timer1_init();

    timer3_init();
    enable_timer3(r16);

    #enable interrupts
    _sei;

    #initialize the press tables
    _ldi r16, lo8(press_table_label("normal"));
    _sts "current_press_table", r16;
    _sts "persistent_mode_press_table", r16;

    _ldi r16, hi8(press_table_label("normal"));
    _sts "current_press_table + 1", r16;
    _sts "persistent_mode_press_table + 1", r16;

    #initialize LEDs
    _ldi r16, INVERSE_MASK(LED_NORMAL);
    _out IO(PORTC), r16;
    _sts "persistent_mode_leds", r16;

    block {
        #wait for an input event and dequeue it
        dequeue_input_event;
        #process the dequeued event
        process_input_event;

        #and do it all over again
        _rjmp block_begin;
    };
};

#Waits for an input event and dequeues it into r16
sub dequeue_input_event {
    block {
        _cli;

        _ldi zh, hi8("button_event_queue");
        _lds zl, "button_event_head";
        _lds r16, "button_event_tail";

        block {
            _cp zl, r16;
            _breq block_end;

            _ld r16, "z+";
            _sts "button_event_head", zl;
            _sei;
            _rjmp block_end parent;
        };

        _sei;
        _rjmp block_begin;
    };
}

sub process_input_event {
    block {
        #we've got the input event in r16

        #extract the button index and store it in r17
        _mov r17, r16;
        _cbr r17, 0x80;
        #we really only need index*2 for address offsets/lookups (which are 2 bytes each)
        _lsl r17;

        block {
            block {
                #is it a press or release?
                _sbrc r16, 7;
                _rjmp block_end;

                #it's a release event. Load the handler address from the release table
                _ldi zl, lo8("release_table");
                _ldi zh, hi8("release_table");
                _add zl, r17;
                _adc zh, r15_zero;
                _ld r18, "z+";
                _ld r19, "z";
                _movw zl, r18;

                _rjmp block_end parent;
            };

            #it's a press event. Load the address for the current press table
            _lds zl, "current_press_table";
            _lds zh, "current_press_table+1";

            #calculate and store the location in the release table, based on button index
            _ldi yl, lo8("release_table");
            _ldi yh, hi8("release_table");
            _add yl, r17;
            _adc yh, r15_zero;

            #lookup the handler address from the table
            _add zl, r17;
            _adc zh, r15_zero;
            _lpm r16, "z+";
            _lpm r17, "z";
            _movw zl, r16;
        };

        _icall;
    };
}

#key map for normal mode
my(%normal_key_map) = (
    #                 d    n    e    s    w
    r1 => finger_map("h", "g", "'", "m", "d"),
    r2 => finger_map("t", "w", "`", "c", "f"),
    r3 => finger_map("n", "v", undef, "r", "b"),
    r4 => finger_map("s", "z", "\\", "l", ")"),
    #                d      dd         u       in    lo      uo
    rt => thumb_map("nas", "naslock", "func", "sp", "lalt", "bksp"),

    #                 d    n    e    s    w
    l1 => finger_map("u", "q", "i", "p", "\""),
    l2 => finger_map("e", ".", "y", "j", "`"),
    l3 => finger_map("o", ",", "x", "k", "esc"),
    l4 => finger_map("a", "/", "(", ";", "del"),
    #                d         dd          u       in     lo       uo
    lt => thumb_map("lshift", "capslock", "norm", "ret", "lctrl", "tab")
);

#key map for when the normal mode key is held down
#It's similar to normal mode, except that we add some shortcuts for
#ctrl+c, ctrl+v, ctrl+x, etc.
my(%normal_hold_key_map) = (
    #                 d    n    e    s    w
    r1 => finger_map("h", "g", "'", "m", "d"),
    r2 => finger_map("t", "w", "`", "c", "f"),
    r3 => finger_map("n", "v", undef, "r", "b"),
    r4 => finger_map("s", "z", "\\", "l", ")"),
    #                d      dd         u       in    lo      uo
    rt => thumb_map("nas", "naslock", "func", "sp", "lalt", "bksp"),

    #                 d    n    e    s    w
    l1 => finger_map("u", "q", "i", "ctrlv", "\""),
    l2 => finger_map("e", ".", "y", "ctrlc", "`"),
    l3 => finger_map("o", ",", "x", "ctrlx", "esc"),
    l4 => finger_map("a", "/", "(", ";", "del"),
    #                d         dd          u       in     lo       uo
    lt => thumb_map("lshift", "capslock", "norm", "ret", "lctrl", "tab")
);

my(%nas_key_map) = (
    #                 d    n    e    s    w
    r1 => finger_map("7", "&", undef, "+", "6"),
    r2 => finger_map("8", "*", undef, undef, "^"),
    r3 => finger_map("9", "[", "menu", undef, undef),
    r4 => finger_map("0", "]", undef, undef, "}"),
    #                d      dd         u       in    lo      uo
    rt => thumb_map("nas", "naslock", "func", "sp", "lalt", "bksp"),

    #                 d    n    e    s    w
    l1 => finger_map("4", "\$", "5", "-", undef),
    l2 => finger_map("3", "#", undef, "%", undef),
    l3 => finger_map("2", "@", undef, undef, "esc"),
    l4 => finger_map("1", "!", "{", "=", "del"),
    #                d         dd          u       in     lo       uo
    lt => thumb_map("lshift", "capslock", "norm", "ret", "lctrl", "tab")
);

my(%func_key_map) = (
    #                 d    n    e    s    w
    r1 => finger_map("home", "up", "right", "down", "left"),
    r2 => finger_map(undef, "f8", undef, "f7", "end"),
    r3 => finger_map("printscreen", "f10", "lgui", "f9", "ins"),
    r4 => finger_map("pause", "pgup", "f12", "pgdn", "f11"),
    #                d      dd         u       in    lo      uo
    rt => thumb_map("nas", "naslock", "func", "sp", "lalt", "bksp"),

    #                 d    n    e    s    w
    l1 => finger_map("home", "up", "right", "down", "left"),
    l2 => finger_map(undef, "f6", undef, "f5", undef),
    l3 => finger_map(undef, "f4", "numlock", "f3", "esc"),
    l4 => finger_map(undef, "f2", "scrolllock", "f1", "del"),
    #                d         dd          u       in     lo       uo
    lt => thumb_map("lshift", "capslock", "norm", "ret", "lctrl", "tab")
);

my(%key_maps) = (
    "normal" => \%normal_key_map,
    "normal_hold" => \%normal_hold_key_map,
    "nas" => \%nas_key_map,
    "func" => \%func_key_map
);

generate_key_maps(\%key_maps);
