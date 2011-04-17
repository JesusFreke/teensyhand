use strict;

sub finger_map {
    return {
        down=>shift,
        north=>shift,
        east=>shift,
        south=>shift,
        west=>shift
    };
}

sub thumb_map {
    return {
        down => shift,
        down_down => shift,
        up => shift,
        inside => shift,
        lower_outside => shift,
        upper_outside => shift
    }
}

sub press_table_label {
    my($name) = shift;
    return "press_table_$name";
}

#maps a button index to it's corresponding finger+direction
my(@index_map) = (
    #selector 0x00
    ["r1", "west"],             #0x00
    ["r1", "north"],            #0x01
    ["l4", "west"],             #0x02
    ["l4", "north"],            #0x03

    #selector 0x01
    ["r1", "down"],             #0x04
    ["r1", "east"],             #0x05
    ["l4", "down"],             #0x06
    ["l4", "east"],             #0x07

    #selector 0x02
    ["r1", "south"],            #0x08
    ["r2", "south"],            #0x09
    ["l4", "south"],            #0x0a
    ["l3", "south"],            #0x0b

    #selector 0x03
    ["r2", "west"],             #0x0c
    ["r2", "north"],            #0x0d
    ["l3", "west"],             #0x0e
    ["l3", "north"],            #0x0f

    #selector 0x04
    ["r2", "down"],             #0x10
    ["r2", "east"],             #0x11
    ["l3", "down"],             #0x12
    ["l3", "east"],             #0x13

    #selector 0x05
    ["r3", "west"],             #0x14
    ["r3", "north"],            #0x15
    ["l2", "west"],             #0x16
    ["l2", "north"],            #0x17

    #selector 0x06
    ["r3", "down"],             #0x18
    ["r3", "east"],             #0x19
    ["l2", "down"],             #0x1a
    ["l2", "east"],             #0x1b

    #selector 0x07
    ["r3", "south"],            #0x1c
    ["r4", "south"],            #0x1d
    ["l2", "south"],            #0x1e
    ["l1", "south"],            #0x1f

    #selector 0x08
    ["r4", "west"],             #0x20
    ["r4", "north"],            #0x21
    ["l1", "west"],             #0x22
    ["l1", "north"],            #0x23

    #selector 0x09
    ["r4", "down"],             #0x24
    ["r4", "east"],             #0x25
    ["l1", "down"],             #0x26
    ["l1", "east"],             #0x27

    #selector 0x0a
    ["rt", "lower_outside"],    #0x28
    ["rt", "upper_outside"],    #0x29
    ["lt", "lower_outside"],    #0x2a
    ["lt", "upper_outside"],    #0x2b

    #selector 0x0b
    ["rt", "down"],             #0x2c
    ["rt", "down_down"],        #0x2d
    ["lt", "down"],             #0x2e
    ["lt", "down_down"],        #0x2f

    #selector 0x0c
    ["rt", "inside"],           #0x30
    ["rt", "up"],               #0x31
    ["lt", "inside"],           #0x32
    ["lt", "up"]                #0x33
);

#maps an action name to a sub that can generate the press and release code for that action
my(%action_map);

{
    #generate actions for a-z and A-Z
    for (my($i)=ord("a"); $i<=ord("z"); $i++) {
        $action_map{chr($i)} = simple_keycode($i - ord("a") + 0x04);
        $action_map{uc(chr($i))} = modified_keycode($i - ord("a") + 0x04, LSHIFT_OFFSET);
    }
    #generate actions for 1-9
    for (my($i)=ord("1"); $i<=ord("9"); $i++) {
        $action_map{chr($i)} = simple_keycode($i - ord("1") + 0x1e);
    }
    #0 comes before 1 in ascii, but after 9 in usb's keycodes
    $action_map{"0"} = simple_keycode(0x27);

    $action_map{"!"} = modified_keycode(0x1e, LSHIFT_OFFSET);
    $action_map{"@"} = modified_keycode(0x1f, LSHIFT_OFFSET);
    $action_map{"#"} = modified_keycode(0x20, LSHIFT_OFFSET);
    $action_map{"\$"} = modified_keycode(0x21, LSHIFT_OFFSET);
    $action_map{"%"} = modified_keycode(0x22, LSHIFT_OFFSET);
    $action_map{"^"} = modified_keycode(0x23, LSHIFT_OFFSET);
    $action_map{"&"} = modified_keycode(0x24, LSHIFT_OFFSET);
    $action_map{"*"} = modified_keycode(0x25, LSHIFT_OFFSET);
    $action_map{"("} = modified_keycode(0x26, LSHIFT_OFFSET);
    $action_map{")"} = modified_keycode(0x27, LSHIFT_OFFSET);

    $action_map{"ret"} = simple_keycode(0x28);
    $action_map{"esc"} = simple_keycode(0x29);
    $action_map{"bksp"} = simple_keycode(0x2a);
    $action_map{"tab"} = simple_keycode(0x2b);
    $action_map{"sp"} = simple_keycode(0x2c);

    $action_map{"-"} = simple_keycode(0x2d);
    $action_map{"_"} = modified_keycode(0x2d, LSHIFT_OFFSET);
    $action_map{"="} = simple_keycode(0x2e);
    $action_map{"+"} = modified_keycode(0x2e, LSHIFT_OFFSET);
    $action_map{"["} = simple_keycode(0x2f);
    $action_map{"{"} = modified_keycode(0x2f, LSHIFT_OFFSET);
    $action_map{"]"} = simple_keycode(0x30);
    $action_map{"}"} = modified_keycode(0x30, LSHIFT_OFFSET);
    $action_map{"\\"} = simple_keycode(0x31);
    $action_map{"|"} = modified_keycode(0x31, LSHIFT_OFFSET);
    $action_map{";"} = simple_keycode(0x33);
    $action_map{":"} = modified_keycode(0x33, LSHIFT_OFFSET);
    $action_map{"'"} = simple_keycode(0x34);
    $action_map{"\""} = modified_keycode(0x34, LSHIFT_OFFSET);
    $action_map{"`"} = simple_keycode(0x35);
    $action_map{"~"} = modified_keycode(0x35, LSHIFT_OFFSET);
    $action_map{","} = simple_keycode(0x36);
    $action_map{"<"} = modified_keycode(0x36, LSHIFT_OFFSET);
    $action_map{"."} = simple_keycode(0x37);
    $action_map{">"} = modified_keycode(0x37, LSHIFT_OFFSET);
    $action_map{"/"} = simple_keycode(0x38);
    $action_map{"?"} = modified_keycode(0x38, LSHIFT_OFFSET);

    $action_map{"capslock"} = simple_keycode(0x39);

    #generate actions for f1-f12
    for(my($i)=1; $i<=12; $i++) {
        $action_map{"f$i"} = simple_keycode(0x3A + $i - 1);
    }

    $action_map{"printscreen"} = simple_keycode(0x46);
    $action_map{"scrolllock"} = simple_keycode(0x47);
    $action_map{"pause"} = simple_keycode(0x48);
    $action_map{"ins"} = simple_keycode(0x49);
    $action_map{"home"} = simple_keycode(0x4a);
    $action_map{"pgup"} = simple_keycode(0x4b);
    $action_map{"del"} = simple_keycode(0x4c);
    $action_map{"end"} = simple_keycode(0x4d);
    $action_map{"pgdn"} = simple_keycode(0x4e);
    $action_map{"right"} = simple_keycode(0x4f);
    $action_map{"left"} = simple_keycode(0x50);
    $action_map{"down"} = simple_keycode(0x51);
    $action_map{"up"} = simple_keycode(0x52);
    $action_map{"numlock"} = simple_keycode(0x53);
    $action_map{"menu"} = simple_keycode(0x65);

    $action_map{"lctrl"} = modifier_keycode(0xe0);
    $action_map{"lshift"} = modifier_keycode(0xe1);
    $action_map{"lalt"} = modifier_keycode(0xe2);
    $action_map{"lgui"} = modifier_keycode(0xe3);
    $action_map{"rctrl"} = modifier_keycode(0xe4);
    $action_map{"rshift"} = modifier_keycode(0xe5);
    $action_map{"ralt"} = modifier_keycode(0xe6);
    $action_map{"rgui"} = modifier_keycode(0xe7);

    $action_map{"nas"} = temporary_mode_action("nas");
    $action_map{"naslock"} = persistent_mode_action("nas");
    $action_map{"func"} = persistent_mode_action("func");
    $action_map{"norm"} = temporary_mode_action("normal_hold", "normal");

    $action_map{"ctrlx"} = modified_keycode(0x1b, LCTRL_OFFSET);
    $action_map{"ctrlc"} = modified_keycode(0x06, LCTRL_OFFSET);
    $action_map{"ctrlv"} = modified_keycode(0x19, LCTRL_OFFSET);
}

sub generate_key_maps {
    my($key_maps) = shift;
    foreach my $key_map_name (keys(%{$key_maps})) {
        my($key_map) = $key_maps->{$key_map_name};

        #iterate over each physical button, and lookup and emit the code for the
        #press and release actions for each
        my(@press_actions);
        my(@release_actions);
        for (my($i)=0; $i<0x34; $i++) {
            #get the finger+direction combination for this button index
            my($index_map_item) = $index_map[$i];

            my($finger_name) = $index_map_item->[0];
            my($finger_dir) = $index_map_item->[1];

            #get the direction map for a specific finger
            my($finger_map) = $key_map->{$finger_name};

            die "couldn't find map for finger $finger_name" unless (defined($finger_map));

            #get the name of the action associated with this particular button
            my($action_name) = $finger_map->{$finger_dir};
            if (!defined($action_name)) {
                my($labels) = &{undefined_action()}($i);
                push @press_actions, $labels->[BUTTON_PRESS];
                push @release_actions, $labels->[BUTTON_RELEASE];
                next;
            }

            #now look up the action
            my($action) = $action_map{$action_name};
            if (!defined($action)) {
                die "invalid action - $action_name";
            }

            #this will emit the code for the press and release action
            #and then we save the names in the two arrays, so we can emit a jump table afterwards
            my($actions) = &$action($i);
            push @press_actions, $actions->[BUTTON_PRESS];
            push @release_actions, $actions->[BUTTON_RELEASE];
        }

        #now emit the jump table for press actions
        emit_sub press_table_label($key_map_name), sub {
            for (my($i)=0; $i<0x34; $i++) {
                my($action_label) = $press_actions[$i];
                if (defined($action_label)) {
                    emit ".word pm($action_label)\n";
                } else {
                    emit ".word pm(no_action)\n";
                }
            }
        };
    }
}

emit_sub "no_action", sub {
    _ret;
};

#adds a keycode to the hid report and sends it
#r16 should contain the keycode to send
emit_sub "send_keycode_press", sub {
    #find the first 0 in current_report, and store the new keycode there
    _ldi zl, lo8("current_report");
    _ldi zh, hi8("current_report");

    _mov r24, zl;
    _adiw r24, 0x20;

    #TODO: we need to handle duplicate keys. e.g. if two buttons are pressed
    #and one is a shifted variant of the other

    block {
        _ld r17, "z+";
        _cp r17, r15_zero;

        block {
            _breq block_end;

            #have we reached the end?
            _cp r24, zl;
            _breq block_end parent;

            _rjmp block_begin parent;
        };

        _st "-z", r16;

        _rjmp "send_hid_report";
    };
    #couldn't find an available slot in the hid report - just return
    #TODO: should report ErrorRollOver in all fields
    _ret;
};

#sends a simple, non-modified key release
#r16 should contain the keycode to release
emit_sub "send_keycode_release", sub {
    #find the keycode in current_report, and zero it out
    _ldi zl, lo8("current_report");
    _ldi zh, hi8("current_report");

    _mov r24, zl;
    _adiw r24, 0x20;

    block {
        _ld r17, "z+";
        _cp r16, r17;

        block {
            _breq block_end;

            #have we reached the end?
            _cp r24, zl;
            _breq block_end parent;

            _rjmp block_begin parent;
        };

        _st "-z", r15_zero;
        _rjmp "send_hid_report";
    };
    #huh? couldn't find the keycode in the hid report. just return
    _ret;
};

#send a modifier key press
#r16 should contain a mask that specifies which modifier should be sent
#the mask should use the same bit ordering as the modifier byte in the
#hid report
emit_sub "send_modifier_press", sub {
    #first, check if the modifier key is already pressed
    block {
        #grab the modifier byte from the hid report and check if the modifier is already pressed
        _lds r17, "current_report + 20";
        _mov r18, r17;
        _and r17, r16;
        _brne block_end;

        #set the modifier bit and store it
        _or r18, r16;
        _sts "current_report + 20", r18;

        _rjmp "send_hid_report";
    };
    _ret;
};

#send a modifier key release
#r16 should contain a mask that specifies which modifier should be sent
#the mask should use the same bit ordering as the modifier byte in the
#hid report
emit_sub "send_modifier_release", sub {
    block {
        #check if the modifier is actually pressed
        _lds r17, "current_report + 20";
        _mov r18, r17;
        _and r17, r16;
        _breq block_end;

        #clear the modifier bit
        _com r16;
        _and r18, r16;
        _sts "current_report + 20", r18;

        _rjmp "send_hid_report";
    };
    _ret;
};

#sends current_report as an hid report
emit_sub "send_hid_report", sub {
    #now, we need to send the hid report
    SELECT_EP r17, EP_1;

    block {
        _lds r17, UEINTX;
        _sbrs r17, RWAL;
        _rjmp block_begin;
    };

    _ldi zl, lo8("current_report");
    _ldi zh, hi8("current_report");

    _ldi r17, 21;

    block {
        _ld r18, "z+";
        _sts UEDATX, r18;
        _dec r17;
        _brne block_begin;
    };

    _lds r17, UEINTX;
    _cbr r17, MASK(FIFOCON);
    _sts UEINTX, r17;
    _ret;
};

#stores the address for the release routine
sub store_release_pointer {
    my($button_index) = shift;
    my($release_label) = shift;

    _ldi r16, lo8(pm($release_label));
    _sts "release_table + " . ($button_index * 2), r16;
    _ldi r16, hi8(pm($release_label));
    _sts "release_table + " . (($button_index * 2) + 1), r16;
}


sub simple_keycode {
    my($keycode) = shift;
    my($emitted) = 0;
    my($labels);

    return sub {
        if (!$emitted) {
            my($press_label) = unique_label("simple_press_action");
            my($release_label) = unique_label("simple_release_action");

            emit_sub $press_label, sub {
                _ldi r16, $keycode;
                _ldi r17, lo8(pm($release_label));
                _ldi r18, hi8(pm($release_label));
                _jmp "handle_simple_press";
            };

            emit_sub $release_label, sub {
                _ldi r16, $keycode;
                _jmp "send_keycode_release";
            };

            $labels = [$release_label, $press_label];
            $emitted = 1;
        }
        return $labels;
    }
}

#handle the press of a simple (non-modified) key
#r16        the keycode to send
#r17:r18    the address for the release routine
#y          the location in the release table to store the release pointer
emit_sub "handle_simple_press", sub {
    block {
        #update the release table
        _st "y+", r17;
        _st "y", r18;

        #we need to check if a purely virtual modifier key is being pressed
        #if so, we need to release the virtual modifier before sending the keycode

        #grab the modifier byte from the hid report
        _lds r17, "current_report + 20";

        #and also grab the physical status
        _lds r18, "modifier_physical_status";

        #check if there are any bits that are 1 in the hid report, but 0 in the physical status
        _com r18;
        _and r18, r17;

        #if not, we don't need to clear any virtual keys, and can proceed to send the actual key press
        _breq block_end;

        #otherwise, we need to clear the virtual modifiers and send a report
        _com r18;
        _and r17, r18;
        _sts "current_report + 20", r17;
        _call "send_hid_report";
    };
    _rjmp "send_keycode_press";
};

sub modified_keycode {
    my($keycode) = shift;
    my($modifier_offset) = shift;
    my($emitted) = 0;
    my($labels);

    return sub {
        if (!$emitted) {
            my($press_label) = unique_label("modified_press_action");
            my($release_label) = unique_label("modified_release_action");

            emit_sub $press_label, sub {
                _ldi r16, $keycode;
                _ldi r17, lo8(pm($release_label));
                _ldi r18, hi8(pm($release_label));
                _ldi r19, $modifier_offset;
                _ldi r20, MASK($modifier_offset);
                _jmp "handle_modified_press";
            };

            emit_sub $release_label, sub {
                _ldi r16, $keycode;
                _ldi r17, $modifier_offset;
                _ldi r18, MASK($modifier_offset);
                _jmp "handle_modified_release";
            };

            $labels =  [$release_label, $press_label];
            $emitted = 1;
        }

        return $labels;
    }
}

#handle the press of a modified key
#r16        the keycode to send
#r17:r18    the address for the release routine
#r19        the offset of the modifier to use
#r20        the mask of the modifier to use
#y          the location in the release table to store the release pointer
emit_sub "handle_modified_press", sub {
    #save off the keycode to send
    _mov r10, r16;

    block {
        #update the release table
        _st "y+", r17;
        _st "y", r18;

        #increment the virtual press counter for this modifier
        _ldi zl, lo8("modifier_virtual_count");
        _ldi zh, hi8("modifier_virtual_count");
        _add zl, r19;
        _adc zh, r15_zero;
        _ld r21, "z";
        _inc r21;
        _st "z", r21;

        _mov r16, r20;
        _call "send_modifier_press";

        #we need to check if any other purely virtual modifier keys are being pressed
        #if so, we need to release them before sending the keycode

        #grab the modifier byte from the hid report
        _lds r17, "current_report + 20";

        #and also grab the physical status
        _lds r18, "modifier_physical_status";
        #and set the bit for the modifier we just sent
        _or r18, r16;

        #check if there are any bits that are 1 in the hid report, but 0 in the physical status
        _com r18;
        _and r18, r17;

        #if not, we don't need to clear any virtual keys, and can proceed to send the actual key press
        _breq block_end;

        #otherwise, we need to clear the virtual modifiers and send a report
        _com r18;
        _and r17, r18;
        _sts "current_report + 20", r17;
        _call "send_hid_report";
    };

    _mov r16, r10;
    _rjmp "send_keycode_press";
};

#handle the release of a modified key
#r16        the keycode to send
#r17        the offset of the modifier to use
#r18        the mask of the modifier to use
emit_sub "handle_modified_release", sub {
    #save off r17 and r18
    _mov r10, r17;
    _mov r11, r18;

    _call "send_keycode_release";

    #decrement the virtual press counter for the modifier
    _ldi zl, lo8("modifier_virtual_count");
    _ldi zh, hi8("modifier_virtual_count");
    _add zl, r10;
    _adc zh, r15_zero;
    _ld r16, "z";
    _dec r16;
    _st "z", r16;

    block {
        #we need to release the modifier key when (both):
        #1. The modifier virtual count is 0 (after decrementing for this release)
        #2. The physical status for the modifier is 0
        #3. The modifier in the hid report is shown as being pressed (checked in send_modifier_release)

        #check if the modifier virtual count is 0 (after decrement)
        _cpi r16, 0;
        _brne block_end;

        #check the physical flag
        _lds r17, "modifier_physical_status";
        _and r17, r11;
        _brne block_end;

        _mov r16, r11;
        _jmp "send_modifier_release";
    };
    _ret;
};

sub modifier_keycode {
    my($keycode) = shift;
    my($modifier_offset) = $keycode - 0xe0;
    my($emitted) = 0;
    my($labels);

    return sub {
        if (!$emitted) {
            my($press_label) = unique_label("modifier_press_action");
            my($release_label) = unique_label("modifier_release_action");

            emit_sub $press_label, sub {
                _ldi r16, MASK($modifier_offset);
                _ldi r17, lo8(pm($release_label));
                _ldi r18, hi8(pm($release_label));
                _jmp "handle_modifier_press";
            };

            emit_sub $release_label, sub {
                _ldi r16, $modifier_offset;
                _ldi r17, MASK($modifier_offset);
                _jmp "handle_modifier_release";
            };

            $labels = [$release_label, $press_label];
            $emitted = 1;
        }

        return $labels;
    }
}

#handle the press of a modifier key
#r16        the mask of the modifier to send
#r17:r18    the address for the release routine
#y          the location in the release table to store the release pointer
emit_sub "handle_modifier_press", sub {
    #update the release table
    _st "y+", r17;
    _st "y", r18;

    #set the bit in the modifier_physical_status byte
    _lds r17, "modifier_physical_status";
    _or r17, r16;
    _sts "modifier_physical_status", r17;

    _jmp "send_modifier_press";
};

#handle the release of a modifier key
#r16        the offset of the modifier to release
#r17        the mask of the modifier to release
emit_sub "handle_modifier_release", sub {
    block {
        #clear the bit in the modifier_physical_status byte
        _lds r18, "modifier_physical_status";
        _mov r19, r17;
        _com r19;
        _and r18, r19;
        _sts "modifier_physical_status", r18;

        #don't release the modifier if it's virtual count is still > 0
        _ldi zl, lo8("modifier_virtual_count");
        _ldi zh, hi8("modifier_virtual_count");
        _add zl, r16;
        _adc zh, r15_zero;
        _ld r18, "z";
        _cpi r18, 0;
        _brne block_end;

        _mov r16, r17;
        _jmp "send_modifier_release";
    };

    _ret;
};

sub temporary_mode_action {
    #this is the temporary mode that will be in effect only while this key is pressed
    my($mode) = shift;

    #we can optionally change the persistent mode - that is, the mode that will become
    #active once the key for the temporary mode is released
    #This is used to implement, for example, the extra mode used when holding down the
    #normal mode key, for left-hand ctrl+c,v,z shortcuts
    my($persistent_mode) = shift;

    my($emitted) = 0;
    my($labels);

    return sub {
        if (!$emitted) {
            my($press_label) = unique_label("temporary_mode_press_action");
            my($release_label) = unique_label("temporary_mode_release_action");

            emit_sub $press_label, sub {
                _ldi r16, lo8(press_table_label($mode));
                _ldi r17, hi8(press_table_label($mode));

                _ldi r18, lo8(pm($release_label));
                _ldi r19, hi8(pm($release_label));

                if ($persistent_mode) {
                    _ldi r20, lo8(press_table_label($persistent_mode));
                    _ldi r21, hi8(press_table_label($persistent_mode));

                    _rjmp "handle_temporary_persistent_mode_press";
                } else {
                    _rjmp "handle_temporary_mode_press";
                }
            };

            emit_sub $release_label, sub {
                _ldi r16, lo8(press_table_label($mode));
                _ldi r17, hi8(press_table_label($mode));

                _rjmp "handle_temporary_mode_release";
            };

            $labels = [$release_label, $press_label];
            $emitted = 1;
        }

        return $labels;
    };
}

#handle the press of a temporary mode key that also updates the persistent mode
#r16:r17    the address of the temporary mode's press table
#r18:r19    the address for the release routine
#r20:r21    the address of the persistent mode's press table
#y          the location in the release table to store the release pointer
emit_sub "handle_temporary_persistent_mode_press", sub {
    #update the persistent mode press table pointer
    _sts "persistent_mode_press_table", r20;
    _sts "persistent_mode_press_table + 1", r21;

    #intentional fall-through!
};

#handle the press of a temporary mode key
#r16:r17    the address of the temporary mode's press table
#r18:r19    the address for the release routine
#y          the location in the release table to store the release pointer
emit_sub "handle_temporary_mode_press", sub {
    #update the release table
    _st "y+", r18;
    _st "y", r19;

    #update the current press table pointer
    _sts "current_press_table", r16;
    _sts "current_press_table+1", r17;

    _ret;
};

#handle the release of a temporary mode key
#r16:r17    the address of the temporary mode's press table
emit_sub "handle_temporary_mode_release", sub {
    block {
        #make sure that we're still in the same temporary mode. If the mode is different
        #than what we expect, don't change modes. For example, if the user presses and holds
        #the nas button, and then presses and hold a different temporary mode button, and
        #then releases the nas button, we don't want to switch back to the persistent mode
        #while the other temporary mode button is being held
        _lds r18, "current_press_table";
        _cp r18, r16;
        _brne block_end;

        _lds r18, "current_press_table + 1";
        _cp r18, r17;
        _brne block_end;

        #restore the press table pointer from persistent_mode_press_table
        _lds r16, "persistent_mode_press_table";
        _sts "current_press_table", r16;
        _lds r16, "persistent_mode_press_table + 1";
        _sts "current_press_table + 1", r16;
    };
    _ret;
};

sub persistent_mode_action {
    #this is the persistent mode to switch to
    my($mode) = shift;

    my($emitted) = 0;
    my($labels);

    return sub {
        if (!$emitted) {
            my($press_label) = unique_label("persistent_mode_press_action");
            my($release_label) = unique_label("persistent_mode_release_action");

            emit_sub $press_label, sub {
                _ldi r16, lo8(press_table_label($mode));
                _ldi r17, hi8(press_table_label($mode));

                _ldi r18, lo8(pm($release_label));
                _ldi r19, hi8(pm($release_label));

                _rjmp "handle_persistent_mode_press";
            };

            emit_sub $release_label, sub {
                _ret;
            };

            $labels = [$release_label, $press_label];
            $emitted = 1;
        }

        return $labels;
    }
}

#handle the press of a persistent mode key
#r16:r17    the address of the new mode's press table
#r18:r19    the address for the release routine
#y          the location in the release table to store the release pointer
emit_sub "handle_persistent_mode_press", sub {
    #update the release table
    _st "y+", r18;
    _st "y", r19;

    #update the current press table pointer
    _sts "current_press_table", r16;
    _sts "current_press_table + 1", r17;

    #update the persistent mode press table pointer
    _sts "persistent_mode_press_table", r16;
    _sts "persistent_mode_press_table + 1", r17;

    _ret;
};

sub undefined_action {
    my($emitted) = 0;
    my($labels);

    return sub {
        if (!$emitted) {
            my($press_label) = unique_label("undefined_press_action");
            my($release_label) = unique_label("undefined_release_action");

            emit_sub $press_label, sub {
                _ldi r16, lo8(pm($release_label));
                _ldi r17, hi8(pm($release_label));
                _rjmp "handle_undefined_press";
            };

            emit_sub $release_label, sub {
                _ret;
            };

            $labels = [$release_label, $press_label];
            $emitted = 1;
        }
        return $labels;
    }
}

#handle the press of a persistent mode key
#r16:r17    the address for the release routine
#y          the location in the release table to store the release pointer
emit_sub "handle_undefined_press", sub {
    #update the release table
    _st "y+", r16;
    _st "y", r17;
    _ret;
};
