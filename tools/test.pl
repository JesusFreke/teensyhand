#!/usr/bin/perl
use strict;

use Device::USB;

my $usb = Device::USB->new();
my $dev = $usb->find_device( 0xFEED, 0xFACE );

$dev->open();
$dev->detach_kernel_driver_np(0);


#hid set idle
#$dev->control_msg( 0b00100001, 0x0a, 0x1300, 0, undef, 0, 1000);


my($buffer) = "";

#setup get configuration
my($ret) = $dev->control_msg( 0b10000000, 0x08, 0, 0, $buffer, 1, 1000);

#hid get report
#my($ret) = $dev->control_msg( 0b10100001, 0x01, 0, 0, $buffer, 34, 1000);

#hid get idle
#my($ret) = $dev->control_msg( 0b10100001, 0x02, 0, 0, $buffer, 1, 1000);

print "ret: $ret\n";
print "data length: " . length($buffer) . "\n";
print "data: " . join(", ", (unpack("C*", $buffer))) . "\n";