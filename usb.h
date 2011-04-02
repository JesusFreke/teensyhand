/*Standard Request Codes*/
#define REQ_GET_STATUS          0
#define REQ_CLEAR_FEATURE       1
#define REQ_SET_FEATURE         3
#define REQ_SET_ADDRESS         5
#define REQ_GET_DESCRIPTOR      6
#define REQ_SET_DESCRIPTOR      7
#define REQ_GET_CONFIGURATION   8
#define REQ_SET_CONFIGURATION   9
#define REQ_GET_INTERFACE       10
#define REQ_SET_INTERFACE       11
#define REQ_SYNCH_FRAME         12

/*Descriptor Types*/
#define DESC_DEVICE                     1
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

/*Feature values for CLEAR_FEATURE and SET_FEATURE requests*/
#define FEATURE_ENDPOINT_HALT           0
#define FEATURE_DEVICE_REMOTE_WAKEUP    1
#define FEATURE_TEST_MODE               2

/*bmRequestType values*/
#define REQTYPE_DEVICE      0<<0
#define REQTYPE_INTERFACE   1<<0
#define REQTYPE_ENDPOINT    2<<0
#define REQTYPE_OTHER       3<<0

#define REQTYPE_STANDARD    0<<5
#define REQTYPE_CLASS       1<<5
#define REQTYPE_VENDOR      2<<5
#define REQTYPE_RESERVED    3<<5

#define REQTYPE_HOST_TO_DEVICE 0 << 7
#define REQTYPE_DEVICE_TO_HOST 1 << 7

/*Address states for SET_ADDRESS request*/
#define STATE_DEFAULT
#define STATE_ADDRESS
#define STATE_CONFIGURED

/*Endpoint direction for endpoint descriptor field bEndpointAddress*/
#define ENDPOINT_DIR_OUT 0x00
#define ENDPOINT_DIR_IN  0x80

/*Endpoint transfer type for endpoint descriptor field bmAttributes*/
#define ENDPOINT_TYPE_CONTROL       0x00
#define ENDPOINT_TYPE_ISOCHRONOUS   0x01
#define ENDPOINT_TYPE_BULK          0x02
#define ENDPOINT_TYPE_INTERRUPT     0x03

/*Endpoint synchronization type for endpoint descriptor field bmAttributes
Only for use with isochronous endpoints*/
#define ENDPOINT_SYNCH_NONE         0x00 << 2
#define ENDPOINT_SYNCH_ASYNC        0x01 << 2
#define ENDPOINT_SYNCH_ADAPTIVE     0x02 << 2
#define ENDPOINT_SYNCH_SYNCHRONOUS  0x03 << 2

/*Endpoint usage type for endpoint descriptor field bmAttributes
Only for use with isochronous endpoints*/
#define ENDPOINT_USAGE_DATA                 0x00 << 4
#define ENDPOINT_USAGE_FEEDBACK             0x01 << 4
#define ENDPOINT_USAGE_IMPLICIT_FEEDBACK    0x02 << 4
#define ENDPOINT_USAGE_RESERVED             0x03 << 4

/*Usage pages*/
#define HID_USAGE_PAGE_GENERIC_DESKTOP      0x01
#define HID_USAGE_PAGE_KEYBOARD             0x07

/*Generic desktop usages*/
#define HID_USAGE_GENERIC_DESKTOP_KEYBOARD  0x06

/*Data size definitions for HID items*/
#define HID_ITEM_DATA_SIZE_0       0x00
#define HID_ITEM_DATA_SIZE_1       0x01
#define HID_ITEM_DATA_SIZE_2       0x02
#define HID_ITEM_DATA_SIZE_4       0x04

/*HID item types*/
#define HID_ITEM_TYPE_MAIN          0x00 << 2
#define HID_ITEM_TYPE_GLOBAL        0x01 << 2
#define HID_ITEM_TYPE_LOCAL         0x02 << 2

/*HID main item tags*/
#define MAIN_ITEM_INPUT             0x08 << 4
#define MAIN_ITEM_OUTPUT            0x09 << 4
#define MAIN_ITEM_COLLECTION        0x0A << 4
#define MAIN_ITEM_FEATURE           0x0B << 4
#define MAIN_ITEM_END_COLLECTION    0x0C << 4

/*First byte of main item data*/
#define MAIN_ITEM_DATA              0
#define MAIN_ITEM_CONSTANT          0b00000001

#define MAIN_ITEM_ARRAY             0
#define MAIN_ITEM_VARIABLE          0b00000010

#define MAIN_ITEM_ABSOLUTE          0
#define MAIN_ITEM_RELATIVE          0b00000100

#define MAIN_ITEM_NOWRAP            0
#define MAIN_ITEM_WRAP              0b00001000

#define MAIN_ITEM_LINEAR            0
#define MAIN_ITEM_NONLINEAR         0b00010000

#define MAIN_ITEM_PREFERRED         0
#define MAIN_ITEM_NONPREFERRED      0b00100000

#define MAIN_ITEM_NONULL            0
#define MAIN_ITEM_NULL              0b01000000

#define MAIN_ITEM_NONVOLATILE       0
#define MAIN_ITEM_VOLATILE          0b10000000

/*Second byte of main item data*/
#define MAIN_ITEM_BITFIELD          0
#define MAIN_ITEM_BUFFEREDBYTES     0b00000001

/*Data values for collection main item*/
#define MAIN_ITEM_COLLECTION_PHYSICAL       0x00
#define MAIN_ITEM_COLLECTION_APPLICATION    0x01
#define MAIN_ITEM_COLLECTION_LOGICAL        0x02
#define MAIN_ITEM_COLLECTION_REPORT         0x03
#define MAIN_ITEM_COLLECTION_NAMEDARRAY     0x04
#define MAIN_ITEM_COLLECTION_USAGESWITCH    0x05
#define MAIN_ITEM_COLLECTION_USAGEMODIFIER  0x06

/*Global item tags*/
#define GLOBAL_ITEM_USAGE_PAGE          0x00 << 4
#define GLOBAL_ITEM_LOGICAL_MINIMUM     0x01 << 4
#define GLOBAL_ITEM_LOGICAL_MAXIMUM     0x02 << 4
#define GLOBAL_ITEM_PHYSICAL_MINIMUM    0x03 << 4
#define GLOBAL_ITEM_PHYSICAL_MAXIMUM    0x04 << 4
#define GLOBAL_ITEM_UNIT_EXPONENT       0x05 << 4
#define GLOBAL_ITEM_UNIT                0x06 << 4
#define GLOBAL_ITEM_REPORT_SIZE         0x07 << 4
#define GLOBAL_ITEM_REPORT_ID           0x08 << 4
#define GLOBAL_ITEM_REPORT_COUNT        0x09 << 4
#define GLOBAL_ITEM_PUSH                0x0A << 4
#define GLOBAL_ITEM_POP                 0x0B << 4

/*Local item tags*/
#define LOCAL_ITEM_USAGE                0x00 << 4
#define LOCAL_ITEM_USAGE_MINIMUM        0x01 << 4
#define LOCAL_ITEM_USAGE_MAXIMUM        0x02 << 4
#define LOCAL_ITEM_DESIGNATOR_INDEX     0x03 << 4
#define LOCAL_ITEM_DESIGNATOR_MINIMUM   0x04 << 4
#define LOCAL_ITEM_DESIGNATOR_MAXIMUM   0x05 << 4
#define LOCAL_ITEM_STRING_INDEX         0x07 << 4
#define LOCAL_ITEM_STRING_MINIMUM       0x08 << 4
#define LOCAL_ITEM_STRING_MAXIMUM       0x09 << 4
#define LOCAL_ITEM_DELIMITER            0x0A << 4


.macro USB_WAIT_FOR_TXINI tempreg
    usb_wait_for_txini_\@:
    lds \tempreg, UEINTX
    sbrs \tempreg, TXINI
    rjmp usb_wait_for_txini_\@
.endm

.macro USB_SEND_QUEUED_DATA tempreg
    lds \tempreg, UEINTX
    cbr \tempreg, MASK(TXINI)
    sts UEINTX, \tempreg
.endm

.macro USB_SEND_ZLP tempreg
    USB_WAIT_FOR_TXINI \tempreg
    cbr \tempreg, MASK(TXINI)
    sts UEINTX, \tempreg
.endm
