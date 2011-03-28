DEVICE_DESCRIPTOR:
/*bLength*/             .byte 0x12
/*bDescriptorType*/     .byte DESC_DEVICE
/*bcdUSB*/              .word 0x0200
/*bDeviceClass*/        .byte 0xFF
/*bDeviceSubClass*/     .byte 0xFF
/*bDeviceProtocol*/     .byte 0xFF
/*bMaxPacketSize*/      .byte 0x40
/*idVendor*/            .word 0xFEED
/*idProduct*/           .word 0xFACE
/*bcdDevice*/           .word 0xF00D
/*iManufacturer*/       .byte 0x01
/*iProduct*/            .byte 0x02
/*iSerialNumber*/       .byte 0x03
/*bNumConfigurations*/  .byte 0x01

CONFIGURATION:
CONFIGURATION_DESCRIPTOR:
/*bLength*/             .byte 0x09
/*bDescriptorType*/     .byte DESC_CONFIGURATION
/*wTotalLength*/        .word END_CONFIGURATION - CONFIGURATION
/*bNumInterfaces*/      .byte 0x00
/*bConfigurationValue*/ .byte 0x01
/*iConfiguration*/      .byte 0x04
/*bmAttributes*/        .byte 0x80
/*bMaxPower*/           .byte 0xFA ;TODO: need to measure current draw
END_CONFIGURATION_DESCRIPTOR:
END_CONFIGURATION:

;Supported Languages
STRING_0:
.byte 0x04
.byte DESC_STRING
.word 0x0409
STRING_0_END:

;Manufacturer
STRING_1:
.byte 0x16
.byte DESC_STRING
.byte 'J',0,'e',0,'s',0,'u',0,'s',0,'F',0,'r',0,'e',0,'k',0,'e',0
STRING_1_END:

;Product
STRING_2:
.byte 0x12
.byte DESC_STRING
.byte 'D',0,'a',0,'t',0,'a',0,'H',0,'a',0,'n',0,'d',0
STRING_2_END:

;Serial Number
STRING_3:
.byte 0x40
.byte DESC_STRING
.byte '3',0,'.',0,'1',0,'4',0,'1',0,'5',0,'9',0,'2',0,'6',0,'5',0,'3',0,'5',0
.byte '8',0,'9',0,'7',0,'9',0,'3',0,'2',0,'3',0,'8',0,'4',0,'6',0,'2',0,'6',0
.byte '4',0,'3',0,'3',0,'8',0,'3',0,'2',0,'7',0
STRING_3_END:

;Configuration Name
STRING_4:
.byte 0x40
.byte DESC_STRING
.byte 'T',0,'h',0,'e',0,' ',0,'C',0,'o',0,'n',0,'f',0,'i',0,'g',0,'u',0,'r',0
.byte 'a',0,'t',0,'i',0,'o',0,'n',0,' ',0,'o',0,'f',0,' ',0,'D',0,'O',0,'O',0
.byte 'O',0,'O',0,'O',0,'O',0,'O',0,'O',0,'M',0
STRING_4_END:

;we have to be aligned, for any code that follows
.align 2
