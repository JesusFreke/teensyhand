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