#!/usr/bin/perl
use strict;

use Device::USB;

my $usb = Device::USB->new();
my $dev = $usb->find_device( 0xFEED, 0xFACE );

if (!defined($dev)) {
    if ($ARGV[0] ne "-silent") {
        die "couldn't find device";
    }
    exit 0;
}

$dev->open();
$dev->detach_kernel_driver_np(0);

my($ret) = $dev->control_msg(0b11000000, 0x02, 0, 0, undef, 0, 1000);