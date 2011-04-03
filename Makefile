MODULE=teensyhand

#find all the .S.pl files
PERL_SRCS=$(wildcard *.S.pl)
#find all the .S files that weren't generated from a .S.pl file
ASSEM_SRCS=$(filter-out $(PERL_SRCS:.S.pl=.S),$(wildcard *.S))

SRCS=$(PERL_SRCS) $(ASSEM_SRCS)
OBJS=$(patsubst %.S.pl,%.o,$(SRCS:.S=.o))

all: $(MODULE).hex
list: all $(MODULE).lst

main.S: AVR.pm usb.pm timer.pm

.PRECIOUS: %.S

%.S: %.S.pl
	@perl $< > $@

%.o: %.S
	@avr-gcc -nostdlib -mmcu=at90usb1286 -c $< -o $@

%.lst: %.elf
	@avr-objdump --disassemble $< > $@

$(MODULE).elf : $(MODULE).ld $(OBJS)
	@avr-gcc -nostdlib -mmcu=at90usb1286 -Wl,-T$(MODULE).ld $(OBJS) -o $@

$(MODULE).hex : $(MODULE).elf
	@avr-objcopy -j .text -O ihex $< $@

clean:
	@rm -rf *.o
	@rm -rf *.elf
	@rm -rf *.hex
	@rm -rf *.lst
	@rm -rf main.S

install: $(MODULE).hex
	@echo install: waiting for device...
	@teensy $(MODULE).hex


#avr-gcc -nostdlib -mmcu=at90usb1286 -Wl,-Tteensytest.ld,-Map=teensytest.map,--cref -o teensytest.elf *.o
#avr-gcc -nostdlib -mmcu=at90usb1286 -Wa,-adhlns=teensytest.lst,-gstabs,--listing-cont-lines=100 -c -o main.o main.S
#avr-objcopy -j .text -O ihex teensytest.elf teensytest.hex
