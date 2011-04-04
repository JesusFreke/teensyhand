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
        "brlo",
        "brne",
        "brsh",
        "brtc",
        "bst",
        "call",
        "cbi",
        "cbr",
        "clr",
        "cp",
        "cpi",
        "cpse",
        "dec",
        "ijmp",
        "ldi",
        "lds",
        "lpm",
        "mov",
        "ret",
        "reti",
        "rjmp",
        "sbi",
        "sbic",
        "sbis",
        "sbiw",
        "sbrc",
        "sbrs",
        "sei",
        "sts",
        "sub"
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

    use constant zl => "r30";
    use constant zh => "r31";
    use constant r15_zero => "r15";
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

my($jump_table_counter) = 0;
sub jump_table {
    my(%args) = @_;
    my($value) = $args{value};
    my($initial_index) = $args{initial_index};
    my($table) = $args{table} || die "no jump table specified";
    my($invalid_value_label) = $args{invalid_value_label};

    my($table_size) = scalar(@$table);

    die "Invalid table index/size" if ($initial_index + $table_size > 256);

    emit_blank_line;

    my($emit_end_label) = 0;
    my($invalid_label);
    if ($invalid_value_label) {
        $invalid_label = $invalid_value_label;
    } else {
        $invalid_label = "jump_table_end_$jump_table_counter";
        $emit_end_label = 1;
    }

    my($table_label) = "jump_table_$jump_table_counter";
    $jump_table_counter++;

    #check the bounds of the value if applicable
    if ($initial_index < 0) {
        _cpi $value, $initial_index;
        _brlo $invalid_label;
    }
    if ($initial_index + $table_size < 256) {
        _cpi $value, $table_size + $initial_index;
        _brsh $invalid_label;
    }

    _ldi zl, lo8(pm($table_label));
    _ldi zh, hi8(pm($table_label));

    _add zl, $value;
    _adc zh, r15_zero;
    _sbiw zl, $initial_index if ($initial_index);

    _ijmp;

    emit_blank_line;
    emit "$table_label:\n";
    indent;
    foreach my $item (@$table) {
        _rjmp $item;
    };
    emit "$invalid_label:\n" if ($emit_end_label);
    deindent;
    emit_blank_line;
}

my($forward_branch_counter) = 0;
sub forward_branch {
    my($branch_insn) = shift || die "no branch instruction given";
    my($block) = shift || die "no code block given";

    my($label) = "forward_branch_$forward_branch_counter";
    $forward_branch_counter++;

    &$branch_insn(@_, $label);
    indent;
    &$block();
    deindent;
    emit_blank_line;
    emit "$label:\n"
}

my($bit_set) = 1;
my($bit_cleared) = 2;

my($if_bit_counter) = 0;
sub _if_bit {
    my($set) = shift;
    my($address) = shift;
    my($bit) = shift;
    my($block) = shift;

    my($insn);

    if ($address =~ /^r[0-9]+$/) {
        $insn = $set?\&_sbrs:\&_sbrc;
    } else {
        die "invalid address specified - $address" if ($address < 0 || $address > 0x1f);
        $insn = $set?\&_sbis:\&_sbic;
    }

    my($label) = "if_bit_$if_bit_counter";
    $if_bit_counter++;

    emit_blank_line;
    &$insn($address, $bit);
    _rjmp $label;

    indent();
    &$block();
    deindent();
    emit_blank_line;
    emit("$label:\n");
}

sub if_bit_set {
    _if_bit($bit_set, @_);
}

sub if_bit_cleared {
    _if_bit($bit_cleared, @_);
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

use constant SREG => 0x5f;
use constant BIT_C => 0;
use constant BIT_Z => 1;
use constant BIT_N => 2;
use constant BIT_V => 3;
use constant BIT_S => 4;
use constant BIT_H => 5;
use constant BIT_T => 6;
use constant BIT_I => 7;

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

use constant UDINT => 0xe1;
use constant UPRSMI => 6;
use constant EORSMI => 5;
use constant WAKEUPI => 4;
use constant EORSTI => 3;
use constant SOFI => 2;
use constant SUSPI => 0;

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

use constant UECONX => 0xeb;
use constant STALLRQ => 5;
use constant STALLRQC => 4;
use constant RSTDT => 3;
use constant EPEN => 0;

use constant UECFG1X => 0xed;
use constant EPSIZE_8 => 0b000 << 4;
use constant EPSIZE_16 => 0b001 << 4;
use constant EPSIZE_32 => 0b010 << 4;
use constant EPSIZE_64 => 0b011 << 4;
use constant EPSIZE_128 => 0b100 << 4;
use constant EPSIZE_256 => 0b101 << 4;
use constant EPBANK_SINGLE => 0b00 << 2;
use constant EPBANK_DOUBLE => 0b01 << 2;
use constant ALLOC => 1;

use constant UECFG0X => 0xec;
use constant EPTYPE_CONTROL => 0b00 << 6;
use constant EPTYPE_ISO => 0b01 << 6;
use constant EPTYPE_BULK => 0b10 << 6;
use constant EPTYPE_INT => 0b11 << 6;
use constant EPDIR_IN => 1;
use constant EPDIR_OUT => 0;

use constant UEIENX => 0xf0;
use constant FLERRE => 7;
use constant NAKINE => 6;
use constant NAKOUTE => 4;
use constant RXSTPE => 3;
use constant RXOUTE => 2;
use constant STALLEDE => 1;
use constant TXINE => 0;

use constant UEDATX => 0xf1;

use constant UEINT => 0xf4;
use constant EPINT6 => 6;
use constant EPINT5 => 5;
use constant EPINT4 => 4;
use constant EPINT3 => 3;
use constant EPINT2 => 2;
use constant EPINT1 => 1;
use constant EPINT0 => 0;

sub IO {
    my($addr) = shift;
    die "invalid io adress - $addr" if ($addr < 0x20 || $addr > 0x5f);
    return $addr - 0x20;
}

sub pm {
    return "pm($_[0])";
}

sub hi8 {
    return "hi8($_[0])";
}

sub lo8 {
    return "lo8($_[0])";
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

use constant EP_0 => 1;
use constant EP_1 => 2;
use constant EP_2 => 3;
use constant EP_3 => 4;
use constant EP_4 => 5;
use constant EP_5 => 6;

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
