NAME := esp-monitor
OBJS := main.o monitor.o

OPEN_SDK ?= /home/br1/dev/esp8266/esp-open-sdk
SERIAL_PORT ?= /dev/ttyUSB2
SERIAL_SPEED ?= 921600

PATH := $(OPEN_SDK)/xtensa-lx106-elf/bin:$(PATH)

CC = xtensa-lx106-elf-gcc
# project specific
CFLAGS += -std=gnu99 -Wall -Wextra -Wno-implicit-function-declaration
CFLAGS += -I. -I./libuwifi -I./libuwifi/core/ -I./libuwifi/util -I./libuwifi/esp8266
# defaults
CFLAGS += -I$(OPEN_SDK)/sdk/include -I$(OPEN_SDK)/sdk/driver_lib/include/
CFLAGS += -Os -mlongcalls -fno-inline-functions -mtext-section-literals
CFLAGS += -falign-functions=4 -DICACHE_FLASH
LDLIBS = -nostdlib -Wl,--start-group -lmain -lnet80211 -lwpa -llwip -lpp -lphy -Wl,--end-group -ldriver -luwifi -lgcc
#LDFLAGS = -Teagle.app.v6.ld
LDFLAGS = -Tlinker-script.ld
# enables removal of unused functions by LD
CFLAGS += -ffunction-sections -fdata-sections
LDFLAGS += -Wl,--gc-sections
LDFLAGS += -L ./libuwifi

export CFLAGS
export LDFLAGS
export CC

$(NAME)-0x00000.bin: $(NAME)
	esptool.py elf2image $^

$(NAME): $(OBJS) ./libuwifi/libuwifi.a
	$(CC) $(LDFLAGS) $^ -o $@ $(LDLIBS)

flash: $(NAME)-0x00000.bin
	esptool.py --port $(SERIAL_PORT) --baud $(SERIAL_SPEED) write_flash 0 $(NAME)-0x00000.bin 0x40000 $(NAME)-0x40000.bin

clean:
	rm -f $(OBJS) $(NAME) $(NAME)-0x00000.bin $(NAME)-0x40000.bin
	$(MAKE) -C libuwifi clean

./libuwifi/libuwifi.a:
	$(MAKE) -C libuwifi PLATFORM=esp8266 DEBUG=0
