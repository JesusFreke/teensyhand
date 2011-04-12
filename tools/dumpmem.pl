#!/usr/bin/perl
use strict;

use Device::USB;

if (scalar(@ARGV) < 2) {
    print "usage: dumpmem.pl <begin address> <count>\n";
    print "dumps <count> bytes starting at <begin address>\n";
    die;
}

my($begin_address) = eval($ARGV[0]);
my($count) = eval($ARGV[1]);

#if ($count > 256) {
#    die "Only 256 bytes can be dumped at once.";
#}

my $usb = Device::USB->new();
my $dev = $usb->find_device( 0xFEED, 0xFACE );

$dev->open();
$dev->detach_kernel_driver_np(0);

my($buffer) = " " x $count;

my($ret) = $dev->control_msg(0b11000000, 0x01, $begin_address, 0, $buffer, $count, 1000);

print "ret: $ret\n";
print "data length: " . length($buffer) . "\n";
print "data: " . join(", ", (unpack("(H2)*", $buffer))) . "\n";