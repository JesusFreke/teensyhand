DEVICE_DESCRIPTOR:
/*bLength*/             .byte 0x12
/*bDescriptorType*/     .byte DESC_DEVICE
/*bcdUSB*/              .word 0x0200
/*bDeviceClass*/        .byte 0x00
/*bDeviceSubClass*/     .byte 0x00
/*bDeviceProtocol*/     .byte 0x00
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
/*wTotalLength*/        .word CONFIGURATION_END - CONFIGURATION
/*bNumInterfaces*/      .byte 0x01
/*bConfigurationValue*/ .byte 0x01
/*iConfiguration*/      .byte 0x04
/*bmAttributes*/        .byte 0x80
/*bMaxPower*/           .byte 0xFA ;TODO: need to measure current draw
CONFIGURATION_DESCRIPTOR_END:

INTERFACE_DESCRIPTOR:
/*bLength*/             .byte 0x09
/*bDescriptorType*/     .byte DESC_INTERFACE
/*bInterfaceNumber*/    .byte 0x00
/*bAlternateSetting*/   .byte 0x00
/*bNumEndpoints*/       .byte 0x01
/*bInterfaceClass*/     .byte 0x03 ;HID class
/*bInterfaceSubClass*/  .byte 0x00 ;no subclass (yet)
/*bInterfaceProtocol*/  .byte 0x00 ;no protocol (yet)
/*iInterface*/          .byte 0x05
INTERFACE_DESCRIPTOR_END:

HID_DESCRIPTOR:
/*bLength*/             .byte 0x09
/*bDescriptorType*/     .byte DESC_HID
/*bcdHID*/              .word 0x0111
/*bCountryCode*/        .byte 0x21 ;US
/*bNumDescriptors*/     .byte 0x01
/*bDescriptorType*/     .byte DESC_HID_REPORT
/*wDescriptorLength*/   .word REPORT_DESCRIPTOR_END - REPORT_DESCRIPTOR
HID_DESCRIPTOR_END:

ENDPOINT_DESCRIPTOR:
/*bLength*/             .byte 0x07
/*bDescriptorType*/     .byte DESC_ENDPOINT
/*bEndpointAddress*/    .byte 0x01 | ENDPOINT_DIR_IN
/*bmAttributes*/        .byte ENDPOINT_TYPE_INTERRUPT
/*wMaxPacketSize*/      .word 0x20
/*bInterval*/           .byte 1 ;1ms polling period
ENDPOINT_DESCRIPTOR_END:
CONFIGURATION_END:


REPORT_DESCRIPTOR:
;Usage page - Generic Desktop
.byte HID_ITEM_DATA_SIZE_1 | HID_ITEM_TYPE_GLOBAL | GLOBAL_ITEM_USAGE_PAGE, \
      HID_USAGE_PAGE_GENERIC_DESKTOP

;Usage - Keyboard
.byte HID_ITEM_DATA_SIZE_1 | HID_ITEM_TYPE_LOCAL | LOCAL_ITEM_USAGE, \
      HID_USAGE_GENERIC_DESKTOP_KEYBOARD

;Application collection item
.byte HID_ITEM_DATA_SIZE_1 | HID_ITEM_TYPE_MAIN | MAIN_ITEM_COLLECTION, \
    MAIN_ITEM_COLLECTION_APPLICATION

    ;-----------Button Array----------

    ;Report size
    .byte HID_ITEM_DATA_SIZE_1 | HID_ITEM_TYPE_GLOBAL | GLOBAL_ITEM_REPORT_SIZE, \
          0x08

    ;Report count - support up to 20 simultaneous buttons at once
    .byte HID_ITEM_DATA_SIZE_1 | HID_ITEM_TYPE_GLOBAL | GLOBAL_ITEM_REPORT_COUNT, \
          0x14

    ;Logical minimum
    .byte HID_ITEM_DATA_SIZE_1 | HID_ITEM_TYPE_GLOBAL | GLOBAL_ITEM_LOGICAL_MINIMUM, \
          0x00
    ;Logical maximum
    .byte HID_ITEM_DATA_SIZE_1 | HID_ITEM_TYPE_GLOBAL | GLOBAL_ITEM_LOGICAL_MAXIMUM, \
          0xDD

    ;Usage page - Keyboard
    .byte HID_ITEM_DATA_SIZE_1 | HID_ITEM_TYPE_GLOBAL | GLOBAL_ITEM_USAGE_PAGE, \
          HID_USAGE_PAGE_KEYBOARD

    ;Usage minimum
    .byte HID_ITEM_DATA_SIZE_1 | HID_ITEM_TYPE_LOCAL | LOCAL_ITEM_USAGE_MINIMUM, \
          0x00
    ;Usage maximum
    .byte HID_ITEM_DATA_SIZE_1 | HID_ITEM_TYPE_LOCAL | LOCAL_ITEM_USAGE_MAXIMUM, \
          0xDD

    ;Input item (array)
    .byte HID_ITEM_DATA_SIZE_0 | HID_ITEM_TYPE_MAIN | MAIN_ITEM_INPUT

    ;------------Modifier List---------

    ;Report size
    .byte HID_ITEM_DATA_SIZE_1 | HID_ITEM_TYPE_GLOBAL | GLOBAL_ITEM_REPORT_SIZE, \
          0x01

    ;Report count - support up to 20 simultaneous buttons at once
    .byte HID_ITEM_DATA_SIZE_1 | HID_ITEM_TYPE_GLOBAL | GLOBAL_ITEM_REPORT_COUNT, \
          0x08

    ;Logical maximum
    .byte HID_ITEM_DATA_SIZE_1 | HID_ITEM_TYPE_GLOBAL | GLOBAL_ITEM_LOGICAL_MAXIMUM, \
          0x01

    ;Usage minimum
    .byte HID_ITEM_DATA_SIZE_1 | HID_ITEM_TYPE_LOCAL | LOCAL_ITEM_USAGE_MINIMUM, \
          0xE0
    ;Usage maximum
    .byte HID_ITEM_DATA_SIZE_1 | HID_ITEM_TYPE_LOCAL | LOCAL_ITEM_USAGE_MAXIMUM, \
          0xE7

    ;Input item (variable)
    .byte HID_ITEM_DATA_SIZE_1 | HID_ITEM_TYPE_MAIN | MAIN_ITEM_INPUT, \
          MAIN_ITEM_VARIABLE

;End application collection
.byte HID_ITEM_DATA_SIZE_0 | HID_ITEM_TYPE_MAIN | MAIN_ITEM_END_COLLECTION


REPORT_DESCRIPTOR_END:

.macro string_descriptor index, string
    ;calculate the length of the string
    .set length, 0
    .irpc ch, \string
        .set length, length+1
    .endr

    ;output the string descriptor, as 16-bit UNICODE
    STRING_\index:
    .byte (length*2)+2
    .byte DESC_STRING

    .irpc n,\string
        ;ughughugh. using the symbol name n is an ugly ugly hack to
        ;avoid a bogus "warning, unknown escape" warning. \n actually
        ;expands into the current character from the given string, it
        ;is NOT a newline character
        .asciz "\n"
    .endr
    STRING_\index\()_END:

    ;make a note of the length of the string, for use elsewhere
    .set STRING_\index\()_LEN, (length*2)+2
.endm

;Supported Languages
STRING_0:
.byte 0x04
.byte DESC_STRING
.word 0x0409 ;English (US)
STRING_0_END:

;Manufacturer
string_descriptor 1, "JesusFreke"
;Product
string_descriptor 2, "DataHand"
;Serial Number
string_descriptor 3, "3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679821480865132823066470938"
;Configuration Name
string_descriptor 4, "The Configuration of DOOOOOOOOM"
;Interface Name
string_descriptor 5, "Keyboard Interface"

;we have to be aligned, for any code that follows
.align 2
