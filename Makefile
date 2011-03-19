MODULE=teensytest

SRCS=$(wildcard *.S)
OBJS=$(SRCS:.S=.o)

all: $(MODULE).hex


%.o: %.S
	@avr-gcc -nostdlib -mmcu=at90usb1286 -c $< -o $@

$(MODULE).elf : $(MODULE).ld $(OBJS)
	@avr-gcc -nostdlib -mmcu=at90usb1286 -Wl,-T$(MODULE).ld $(OBJS) -o $@

$(MODULE).hex : $(MODULE).elf
	@avr-objcopy -j .text -O ihex $< $@

clean:
	@rm -rf *.o
	@rm -rf *.elf
	@rm -rf *.hex

install: $(MODULE).hex
	@echo install: waiting for device...
	@teensy $(MODULE).hex


#avr-gcc -nostdlib -mmcu=at90usb1286 -Wl,-Tteensytest.ld,-Map=teensytest.map,--cref -o teensytest.elf *.o
#avr-gcc -nostdlib -mmcu=at90usb1286 -Wa,-adhlns=teensytest.lst,-gstabs,--listing-cont-lines=100 -c -o main.o main.S
#avr-objcopy -j .text -O ihex teensytest.elf teensytest.hex