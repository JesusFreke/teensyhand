use strict;

#Descriptor Types
use constant DESC_DEVICE => 1;
use constant DESC_CONFIGURATION => 2;
use constant DESC_STRING => 3;
use constant DESC_INTERFACE => 4;
use constant DESC_ENDPOINT => 5;
use constant DESC_DEVICE_QUALIFIER => 6;
use constant DESC_OTHER_SPEED_CONFIGURATION => 7;
use constant DESC_INTERFACE_POWER => 8;
use constant DESC_HID => 0x21;
use constant DESC_HID_REPORT => 0x22;
use constant DESC_PHYSICAL => 0x23;

#Endpoint direction for endpoint descriptor field bEndpointAddress
use constant ENDPOINT_DIR_OUT => 0x00;
use constant ENDPOINT_DIR_IN => 0x80;

#Endpoint transfer type for endpoint descriptor field bmAttributes
use constant ENDPOINT_TYPE_CONTROL => 0x00;
use constant ENDPOINT_TYPE_ISOCHRONOUS => 0x01;
use constant ENDPOINT_TYPE_BULK => 0x02;
use constant ENDPOINT_TYPE_INTERRUPT => 0x03;

#Usage pages
use constant HID_USAGE_PAGE_GENERIC_DESKTOP => 0x01;
use constant HID_USAGE_PAGE_KEYBOARD => 0x07;

#Generic desktop usages
use constant HID_USAGE_GENERIC_DESKTOP_KEYBOARD => 0x06;

#Data size definitions for HID items
use constant HID_ITEM_DATA_SIZE_0 => 0x00;
use constant HID_ITEM_DATA_SIZE_1 => 0x01;
use constant HID_ITEM_DATA_SIZE_2 => 0x02;
use constant HID_ITEM_DATA_SIZE_4 => 0x04;

#HID item types
use constant HID_ITEM_TYPE_MAIN => 0x00 << 2;
use constant HID_ITEM_TYPE_GLOBAL => 0x01 << 2;
use constant HID_ITEM_TYPE_LOCAL => 0x02 << 2;

#HID main item tags
use constant MAIN_ITEM_INPUT => 0x08 << 4;
use constant MAIN_ITEM_OUTPUT => 0x09 << 4;
use constant MAIN_ITEM_COLLECTION => 0x0A << 4;
use constant MAIN_ITEM_FEATURE => 0x0B << 4;
use constant MAIN_ITEM_END_COLLECTION => 0x0C << 4;

#First byte of main item data
use constant MAIN_ITEM_DATA => 0;
use constant MAIN_ITEM_CONSTANT => 0b00000001;

use constant MAIN_ITEM_ARRAY => 0;
use constant MAIN_ITEM_VARIABLE => 0b00000010;

use constant MAIN_ITEM_ABSOLUTE => 0;
use constant MAIN_ITEM_RELATIVE => 0b00000100;

use constant MAIN_ITEM_NOWRAP => 0;
use constant MAIN_ITEM_WRAP => 0b00001000;

use constant MAIN_ITEM_LINEAR => 0;
use constant MAIN_ITEM_NONLINEAR => 0b00010000;

use constant MAIN_ITEM_PREFERRED => 0;
use constant MAIN_ITEM_NONPREFERRED => 0b00100000;

use constant MAIN_ITEM_NONULL => 0;
use constant MAIN_ITEM_NULL => 0b01000000;

use constant MAIN_ITEM_NONVOLATILE => 0;
use constant MAIN_ITEM_VOLATILE => 0b10000000;

#Second byte of main item data
use constant MAIN_ITEM_BITFIELD => 0;
use constant MAIN_ITEM_BUFFEREDBYTES => 0b00000001;

#Data values for collection main item
use constant MAIN_ITEM_COLLECTION_PHYSICAL => 0x00;
use constant MAIN_ITEM_COLLECTION_APPLICATION => 0x01;
use constant MAIN_ITEM_COLLECTION_LOGICAL => 0x02;
use constant MAIN_ITEM_COLLECTION_REPORT => 0x03;
use constant MAIN_ITEM_COLLECTION_NAMEDARRAY => 0x04;
use constant MAIN_ITEM_COLLECTION_USAGESWITCH => 0x05;
use constant MAIN_ITEM_COLLECTION_USAGEMODIFIER => 0x06;

#Global item tags
use constant GLOBAL_ITEM_USAGE_PAGE => 0x00 << 4;
use constant GLOBAL_ITEM_LOGICAL_MINIMUM => 0x01 << 4;
use constant GLOBAL_ITEM_LOGICAL_MAXIMUM => 0x02 << 4;
use constant GLOBAL_ITEM_PHYSICAL_MINIMUM => 0x03 << 4;
use constant GLOBAL_ITEM_PHYSICAL_MAXIMUM => 0x04 << 4;
use constant GLOBAL_ITEM_UNIT_EXPONENT => 0x05 << 4;
use constant GLOBAL_ITEM_UNIT => 0x06 << 4;
use constant GLOBAL_ITEM_REPORT_SIZE => 0x07 << 4;
use constant GLOBAL_ITEM_REPORT_ID => 0x08 << 4;
use constant GLOBAL_ITEM_REPORT_COUNT => 0x09 << 4;
use constant GLOBAL_ITEM_PUSH => 0x0A << 4;
use constant GLOBAL_ITEM_POP => 0x0B << 4;

#Local item tags
use constant LOCAL_ITEM_USAGE => 0x00 << 4;
use constant LOCAL_ITEM_USAGE_MINIMUM => 0x01 << 4;
use constant LOCAL_ITEM_USAGE_MAXIMUM => 0x02 << 4;
use constant LOCAL_ITEM_DESIGNATOR_INDEX => 0x03 << 4;
use constant LOCAL_ITEM_DESIGNATOR_MINIMUM => 0x04 << 4;
use constant LOCAL_ITEM_DESIGNATOR_MAXIMUM => 0x05 << 4;
use constant LOCAL_ITEM_STRING_INDEX => 0x07 << 4;
use constant LOCAL_ITEM_STRING_MINIMUM => 0x08 << 4;
use constant LOCAL_ITEM_STRING_MAXIMUM => 0x09 << 4;
use constant LOCAL_ITEM_DELIMITER => 0x0A << 4;

use constant SIZE => 0;
use constant EMIT => 1;
my($mode) = SIZE;

sub _value_decl {
	my($directive) = shift;
	my($size) = shift;
	my($value) = shift;

	sub {
		return $size if ($mode == SIZE);

		if (ref($value) eq "CODE") {
			$value = &$value();
		}
		emit "$directive $value\n";
	};
}

sub byte($) {
	return _value_decl ".byte", 1, @_;
}

sub word($) {
	return _value_decl ".word", 2, @_;
}

my(%descriptors);

sub get_descriptor {
    return $descriptors{$_[0]};
}

sub descriptor {
	my($descriptor_name) = shift;
	my(@descriptor_def) = @_;

	sub {
		if ($mode == SIZE) {
			my($size) = 0;
			foreach my $descriptor (@descriptor_def) {
				$size += &$descriptor();
			}

			$descriptors{$descriptor_name} = {
				size => $size,
				name => $descriptor_name
			};

			return $size;
		} else {
			emit "$descriptor_name:\n";
			indent_block {
				foreach my $descriptor (@descriptor_def) {
					&$descriptor();
				}
			};
		}
	};
}

sub string_descriptors {
    my($langid) = shift;
    my(@strings) = @_;

    sub {
        if ($mode == SIZE) {
            my($size) = 0;
            $size += 4 + 2; #for the string 0 descriptor, and for the string table entry
            foreach my $string (@strings) {
                $size += length($string) * 2 + 2; #descriptor length
                $size += 2; #string table entry
            }

            $descriptors{"STRING_DESCRIPTOR_TABLE"} = {
                name => "STRING_DESCRIPTOR_TABLE",
                size => $size,
                count => scalar(@strings) + 1
            };

            #Just return the size, we don't currently need to add an entry in %descriptors.
            return $size;
        } else {
            #The string descriptor table will contain the 2-byte address for each string
            emit "STRING_DESCRIPTOR_TABLE:\n";
            indent_block {
                for (my($i)=0; $i<=scalar(@strings); $i++) {
                    emit ".word STRING_DESCRIPTOR_$i\n";
                }
            };

            #now write out the descriptors themselves
            emit "STRING_DESCRIPTOR_0:\n";
            indent_block {
                emit ".byte 4\n";
                emit ".byte " . DESC_STRING . "\n";
                emit ".word $langid\n";
            };
            my($i) = 1;
            foreach my $string (@strings) {
                emit "STRING_DESCRIPTOR_$i:\n";
                indent_block {
                    emit ".byte " . (length($string) * 2 + 2) . "\n";
                    emit ".byte " . DESC_STRING . "\n";
                    my(@chars) = unpack("C*", $string);
                    emit ".word " . join(", ", map { "'" . chr($_) . "'" } @chars) . "\n";
                };
                $i++;
            }
        }
    }
}

sub process_descriptor {
	my($descriptor_def) = shift;

	$mode = 0;
	my($total_size) = &$descriptor_def();

	$mode = 1;
	&$descriptor_def();
}

process_descriptor
descriptor("DESCRIPTORS",
	descriptor("DEVICE_DESCRIPTOR",
		byte sub { $descriptors{DEVICE_DESCRIPTOR}->{size}; }, #bLength
		byte DESC_DEVICE,   #bDescriptorType
		word 0x0200,        #bcdUSB
		byte 0x00,          #bDeviceClass
		byte 0x00,          #bDeviceSubClass
		byte 0x00,          #bDeviceProtocol
		byte 0x40,          #bMaxPacketSize
		word 0xFEED,        #idVendor
		word 0xFACE,        #idVendor
		word 0xF00D,        #bcdDevice
		byte 0x01,          #iManufacturer
		byte 0x02,          #iProduct
		byte 0x03,          #iSerialNumber
		byte 0x01           #bNumConfigurations
	),
	descriptor("CONFIGURATION_DESCRIPTORS",
		descriptor("CONFIGURATION_DESCRIPTOR",
			byte sub { $descriptors{CONFIGURATION_DESCRIPTOR}->{size}; }, #bLength
			byte DESC_CONFIGURATION, 	#bDescriptorType
			word sub { $descriptors{CONFIGURATION_DESCRIPTORS}->{size}; }, #wTotalLength
			byte 0x01, 					#bNumInterfaces
			byte 0x01,					#bConfigurationValue
			byte 0x04,					#iConfiguration
			byte 0x80,					#bmAttributes
			byte 0xFA					#bMaxPower - TODO: need to measure current draw
		),
		descriptor("INTERFACE_DESCRIPTOR",
			byte sub { $descriptors{CONFIGURATION_DESCRIPTOR}->{size}; }, #bLength
			byte DESC_INTERFACE,	#bDescriptorType
			byte 0x00,				#bInterfaceNumber
			byte 0x00,				#bAlternateSetting
			byte 0x01,				#bNumEndpoints
			byte 0x03, 				#bInterfaceClass - HID class
			byte 0x00, 				#bInterfaceSubClass - no subclass (yet)
			byte 0x00,				#bInterfaceProtocol - no protocol (yet)
			byte 0x05				#iInterface
		),
		descriptor("HID_DESCRIPTOR",
			byte sub { $descriptors{HID_DESCRIPTOR}->{size}; }, #bLength
			byte DESC_HID,			#bDescriptorType
			word 0x0111,			#bcdHID
			byte 0x21,				#bCountryCode - US
			byte 0x01,				#bNumDescriptors
			byte DESC_HID_REPORT,	#bDescriptorType
			word sub { $descriptors{REPORT_DESCRIPTOR}->{size}; } #wDescriptorLength
		),
		descriptor("EP0_DESCRIPTOR",
			byte sub { $descriptors{EP0_DESCRIPTOR}->{size}; }, #bLength
			byte DESC_ENDPOINT,				#bDescriptorType
			byte (ENDPOINT_DIR_IN | 0x01),	#bEndpointAddress
			byte ENDPOINT_TYPE_INTERRUPT,	#bmAttributes
			word 0x20,						#wMaxPacketSize
			byte 1							#bInterval - 1ms polling period
		)
	),
    descriptor("REPORT_DESCRIPTOR",
        #Usage page - Generic Desktop
        byte(HID_ITEM_DATA_SIZE_1 | HID_ITEM_TYPE_GLOBAL | GLOBAL_ITEM_USAGE_PAGE),
        byte(HID_USAGE_PAGE_GENERIC_DESKTOP),

        #Usage - Keyboard
        byte(HID_ITEM_DATA_SIZE_1 | HID_ITEM_TYPE_LOCAL | LOCAL_ITEM_USAGE),
        byte(HID_USAGE_GENERIC_DESKTOP_KEYBOARD),

        #Application collection item
        byte(HID_ITEM_DATA_SIZE_1 | HID_ITEM_TYPE_MAIN | MAIN_ITEM_COLLECTION),
        byte(MAIN_ITEM_COLLECTION_APPLICATION),

            #-----------Button Array----------
            #Report size
            byte(HID_ITEM_DATA_SIZE_1 | HID_ITEM_TYPE_GLOBAL | GLOBAL_ITEM_REPORT_SIZE),
            byte(0x08),

            #Report count - support up to 20 simultaneous buttons at once
            byte(HID_ITEM_DATA_SIZE_1 | HID_ITEM_TYPE_GLOBAL | GLOBAL_ITEM_REPORT_COUNT),
            byte(0x14),

            #Logical minimum
            byte(HID_ITEM_DATA_SIZE_1 | HID_ITEM_TYPE_GLOBAL | GLOBAL_ITEM_LOGICAL_MINIMUM),
            byte(0x00),

            #Logical maximum
            byte(HID_ITEM_DATA_SIZE_1 | HID_ITEM_TYPE_GLOBAL | GLOBAL_ITEM_LOGICAL_MAXIMUM),
            byte(0xDD),

            #Usage page - Keyboard
            byte(HID_ITEM_DATA_SIZE_1 | HID_ITEM_TYPE_GLOBAL | GLOBAL_ITEM_USAGE_PAGE),
            byte(HID_USAGE_PAGE_KEYBOARD),

            #Usage minimum
            byte(HID_ITEM_DATA_SIZE_1 | HID_ITEM_TYPE_LOCAL | LOCAL_ITEM_USAGE_MINIMUM),
            byte(0x00),

            #Usage maximum
            byte(HID_ITEM_DATA_SIZE_1 | HID_ITEM_TYPE_LOCAL | LOCAL_ITEM_USAGE_MAXIMUM),
            byte(0xDD),

            #Input item (array)
            byte(HID_ITEM_DATA_SIZE_0 | HID_ITEM_TYPE_MAIN | MAIN_ITEM_INPUT),

            #------------Modifier List---------
            #Report size
            byte(HID_ITEM_DATA_SIZE_1 | HID_ITEM_TYPE_GLOBAL | GLOBAL_ITEM_REPORT_SIZE),
            byte(0x01),

            #Report count - support up to 20 simultaneous buttons at once
            byte(HID_ITEM_DATA_SIZE_1 | HID_ITEM_TYPE_GLOBAL | GLOBAL_ITEM_REPORT_COUNT),
            byte(0x08),

            #Logical maximum
            byte(HID_ITEM_DATA_SIZE_1 | HID_ITEM_TYPE_GLOBAL | GLOBAL_ITEM_LOGICAL_MAXIMUM),
            byte(0x01),

            #Usage minimum
            byte(HID_ITEM_DATA_SIZE_1 | HID_ITEM_TYPE_LOCAL | LOCAL_ITEM_USAGE_MINIMUM),
            byte(0xE0),

            #Usage maximum
            byte(HID_ITEM_DATA_SIZE_1 | HID_ITEM_TYPE_LOCAL | LOCAL_ITEM_USAGE_MAXIMUM),
            byte(0xE7),

            #Input item (variable)
            byte(HID_ITEM_DATA_SIZE_1 | HID_ITEM_TYPE_MAIN | MAIN_ITEM_INPUT),
            byte(MAIN_ITEM_VARIABLE),

        #End application collection
        byte(HID_ITEM_DATA_SIZE_0 | HID_ITEM_TYPE_MAIN | MAIN_ITEM_END_COLLECTION)
    ),
    string_descriptors(
        #Supported lang id
        0x0409,
        #Manufacturer
        "JesusFreke",
        #Product
        "DataHand",
        #Serial Number
        "3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679821480865132823066470938",
        #Configuration Name
        "The Configuration of DOOOOOOOOM",
        #Interface Name
        "Keyboard Interface"
    )
);