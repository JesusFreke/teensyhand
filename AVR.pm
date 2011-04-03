use strict;

use constant NO_ARG => 0;
use constant ONE_ARG => 1;
use constant TWO_ARG => 2;

BEGIN {
    package emit;
    our($indent) = 0;
    our($blankline) = 0;

    package main;
    sub emit {
        print ' ' x $emit::indent;
        print @_;
        $emit::blankline = 0;
    }

    our(@insns) = (
        "adc",
        "add",
        "and",
        "andi",
        "asr",
        "bclr",
        "bld",
        "brbc",
        "brbs",
        "brcc",
        "brcs",
        "break",
        "breq",
        "brge",
        "brhc",
        "brhs",
        "brid",
        "brie",
        "brne",
        "brtc",
        "bst",
        "cbi",
        "clr",
        "dec",
        "ldi",
        "lds",
        "ret",
        "reti",
        "rjmp",
        "sbi",
        "sbis",
        "sbrs",
        "sei",
        "sts"
    );

    for my $name (@insns) {
        no strict 'refs'; # allow symbol table manipulation

        my($symname) = "_" . $name;

        *$symname = sub {
            emit "$name";
            if (scalar(@_) > 0) {
                print " ", join(", ", @_);
            }
            print "\n";
        };
    }

    #define r0-r31
    for (my($i)=0; $i<32; $i++) {
        no strict 'refs';
        my($regname) = "r" . $i;

        *$regname = sub () { $regname; };
    }
}

sub indent {
    $emit::indent+=4;
}

sub deindent {
    $emit::indent = $emit::indent<4?0:$emit::indent-4;
}

sub emit_blank_line {
    if ($emit::blankline == 0) {
        print "\n";
        $emit::blankline = 1;
    }
}

sub memory_variable {
    no strict 'refs';
    my($name) = shift || die "no variable name specified";
    emit ".lcomm $name, 1\n";

    *$name = sub () { $name };
}

sub emit_sub {
    my($name) = shift || die "no sub name specified";
    my($block) = shift || die "no block specified";
    my($global) = shift;

    emit_blank_line;
    emit ".global $name\n" if $global;
    emit "$name:\n";
    indent();
    &$block();
    deindent();
    emit_blank_line;
}

sub emit_global_sub {
    emit_sub @_, 1;
}

my($do_while_counter) = 0;
sub do_while(&&) {
    my($block) = shift || die "no code block";
    my($branch_insn) = shift || die "no branch instruction";

    my($label) = "do_while_$do_while_counter";
    $do_while_counter++;

    emit_blank_line;
    emit "$label:\n";
    indent();
    &$block();
    deindent();
    &$branch_insn(@_, $label);
    emit_blank_line;
}

my($if_io_bit_set_counter) = 0;
sub if_io_bit_set {
    my($address) = shift || die "no port specified";
    my($pin) = shift || die "no port specified";
    my($block) = shift || die "no code block";

    die "invalid address specified - $address" if ($address < 0 || $address > 0x1f);

    my($label) = "if_io_bit_set_$if_io_bit_set_counter";
    $if_io_bit_set_counter++;

    emit_blank_line;
    _sbis $address, $pin;
    _rjmp $label;

    indent();
    &$block();
    deindent();
    emit_blank_line;
    emit("$label:\n");
}

use constant CLOCK_DIV_1 =>     0b0000;
use constant CLKPR => 0x61;

use constant PIND => 0x29;
use constant DDRD => 0x2A;
use constant PORTD => 0x2B;

use constant PLLCSR => 0x49;
use constant PLOCK => 0;
use constant PLLE => 1;
use constant PLL_4 => 0b011 << 2;
use constant PLL_8 => 0b101 << 2;

use constant TIMSK1 => 0x6f;
use constant ICIE1 => 5;
use constant OCIE1C => 3;
use constant OCIE1B => 2;
use constant OCIE1A => 1;
use constant TOIE1 => 0;

use constant TCCR1B => 0x81;
use constant ICNC1 => 7;
use constant ICES1 => 6;
use constant WGM13 => 4;
use constant WGM12 => 3;
use constant TIMER_CLK_OFF => 0b000;
use constant TIMER_CLK_1 => 0b001;
use constant TIMER_CLK_8 => 0b010;
use constant TIMER_CLK_64 => 0b011;
use constant TIMER_CLK_256 => 0b100;
use constant TIMER_CLK_1024 => 0b101;
use constant TIMER_CLK_EXT_RISE => 0b110;
use constant TIMER_CLK_EXT_FALL => 0b111;

use constant OCR1AL => 0x88;
use constant OCR1AH => 0x89;

use constant UHWCON => 0xd7;
use constant UIMOD => 7;
use constant UIDE => 6;
use constant UVCONE => 4;
use constant UVREGE => 0;

use constant USBCON => 0xd8;
use constant USBE => 7;
use constant HOST => 6;
use constant FRZCLK => 5;
use constant OTGPADE => 4;
use constant IDTE => 1;
use constant VBUSTE => 0;

use constant UDCON => 0xe0;
use constant LSM => 2;
use constant RMWKUP => 1;
use constant DETACH => 0;

use constant UDIEN => 0xe2;
use constant UPRSME => 6;
use constant EORSME => 5;
use constant WAKEUPE => 4;
use constant EORSTE => 3;
use constant SOFE => 2;
use constant SUSPE => 0;

use constant UEINTX => 0xe8;
use constant FIFOCON => 7;
use constant NAKINI => 6;
use constant RWAL => 5;
use constant NAKOUTI => 4;
use constant RXSTPI => 3;
use constant RXOUTI => 2;
use constant STALLEDI => 1;
use constant TXINI => 0;

use constant UENUM => 0xe9;

use constant UEDATX => 0xf1;

sub IO {
    my($addr) = shift;
    die "invalid io adress - $addr" if ($addr < 0x20 || $addr > 0x5f);
    return $addr - 0x20;
}

sub MAKE_8BIT {
    return $_[0] & 0xFF;
}

sub MASK {
    return 1 << $_[0];
}

sub SET_CLOCK_SPEED {
    my($tempreg, $div) = @_;

    _ldi $tempreg, 0x80;
    _sts CLKPR, $tempreg;

    _ldi $tempreg, $div;
    _sts CLKPR, $tempreg;
}

use constant GPIO_DIR_IN => 1;
use constant GPIO_DIR_OUT => 2;

use constant GPIO_PULLUP_DISABLED => 1;
use constant GPIO_PULLUP_ENABLED => 2;

use constant GPIO_PORT_A => 1;
use constant GPIO_PORT_B => 2;
use constant GPIO_PORT_C => 3;
use constant GPIO_PORT_D => 4;
use constant GPIO_PORT_E => 5;
use constant GPIO_PORT_F => 6;

use constant PIN_0 => 1;
use constant PIN_1 => 2;
use constant PIN_2 => 3;
use constant PIN_3 => 4;
use constant PIN_4 => 5;
use constant PIN_5 => 6;
use constant PIN_6 => 7;
use constant PIN_7 => 8;

sub CONFIGURE_GPIO {
    my(%args) = @_;
    my($dir) = $args{dir};
    my($pullup) = $args{pullup};
    my($port) = $args{port} || die "no port specified";
    my($pin) = $args{pin} || die "no pin specified";

    my($printed_blank) = 0;

    if ($dir) {
        emit_blank_line;
        $printed_blank = 1;

        #set/clear the appropriate bit in the DDRX register
        if ($dir == GPIO_DIR_IN) {
            _cbi 0x03 * ($port - 1) + 1, $pin - 1;
        } elsif ($dir == GPIO_DIR_OUT) {
            _sbi 0x03 * ($port - 1) + 1, $pin - 1;
        } else {
            die "unknown gpio direction";
        }
    }

    if ($pullup) {
        emit_blank_line unless ($printed_blank);

        #set/clear the appropriate bit in the PORTX register
        if ($pullup == GPIO_PULLUP_DISABLED) {
            _cbi 0x03 * ($port - 1) + 2, $pin - 1;
        } elsif ($pullup == GPIO_PULLUP_ENABLED) {
            _sbi 0x03 * ($port - 1) + 2, $pin - 1;
        }
    }

    emit_blank_line if ($printed_blank);
}

sub SELECT_EP {
    my($tempreg) = shift || die "no temporary register given";
    my($endpoint) = shift || die "no endpoint given";

    _ldi $tempreg, $endpoint-1;
    _sts UENUM, $tempreg;
}

1;
