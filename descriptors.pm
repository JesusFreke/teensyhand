use strict;

#Descriptor Types
use constant DESC_DEVICE => 1;
#define DESC_CONFIGURATION              2
#define DESC_STRING                     3
#define DESC_INTERFACE                  4
#define DESC_ENDPOINT                   5
#define DESC_DEVICE_QUALIFIER           6
#define DESC_OTHER_SPEED_CONFIGURATION  7
#define DESC_INTERFACE_POWER            8
#define DESC_HID                        0x21
#define DESC_HID_REPORT                 0x22
#define DESC_PHYSICAL                   0x23

sub _byte {
    emit ".byte $_[0]\n";
}

sub _word {
    emit ".word $_[0]\n";
}

sub emit_descriptor {
    emit_sub @_;
}

emit_descriptor "DEVICE_DESCRIPTOR", sub {
    _byte 0x12;          #bLength
    _byte DESC_DEVICE;   #bDescriptorType
    _word 0x0200;        #bcdUSB
    _byte 0x00;          #bDeviceClass
    _byte 0x00;          #bDeviceSubClass
    _byte 0x00;          #bDeviceProtocol
    _byte 0x40;          #bMaxPacketSize
    _word 0xFEED;        #idVendor
    _word 0xFACE;        #idVendor
    _word 0xF00D;        #bcdDevice
    _byte 0x01;          #iManufacturer
    _byte 0x02;          #iProduct
    _byte 0x03;          #iSerialNumber
    _byte 0x01;          #bNumConfigurations
};
