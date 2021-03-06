# use mono for exes, unless the platform supports native win32 execution
ifeq ($(or $(filter %-cygwin,$(MAKE_HOST)),\
	    $(and $(filter x86_64-pc-linux-gnu,$(MAKE_HOST)),\
		    $(wildcard /proc/sys/fs/binfmt_misc/WSLInterop))),)
MONO = mono
else
MONO =
endif

#-----------------------------------------------------------------------------
# Configuration options
# config.mk can override any of the config variables below
#-----------------------------------------------------------------------------
-include config.mk

PREFIX ?= arm-eabi-
INSTALLDIR ?= .
GUEST_KERNEL ?= kernel7.img
GUEST_DISKIMG ?= raspbian.img
VALE ?= $(MONO) tools/vale/bin/vale.exe
DAFNY ?= $(MONO) tools/dafny/Dafny.exe
#-----------------------------------------------------------------------------

AS = $(PREFIX)as
CC = $(PREFIX)gcc
LD = $(PREFIX)ld
AR = $(PREFIX)ar
OBJCOPY = $(PREFIX)objcopy

LIBGCC = $(shell $(CC) -print-libgcc-file-name)

CFLAGS_ALL = -Wall -Werror -ffreestanding -nostdinc -mcpu=cortex-a7 -std=c99 -g -O -I include -I pdclib/include
LDFLAGS_ALL = -nostdlib

TARGET = piimage/piimage.img
GUEST = guestimg/guestdisk.img

all: $(TARGET)

QEMU ?= qemu-system-arm
QEMU_ARGS = -M raspi2 -display none -serial stdio -gdb tcp:127.0.0.1:1234
QEMU_CMD = $(QEMU) $(QEMU_ARGS) -bios $(TARGET) -sd $(GUEST)

.PHONY: clean qemu qemugdb

qemu: $(TARGET) $(GUEST)
	$(QEMU_CMD)

qemugdb: $(TARGET) $(GUEST)
	$(QEMU_CMD) -S

gdb: piloader/piloader.elf monitor/monitor.elf
	$(PREFIX)gdb -ex 'target remote :1234' \
		-ex 'add-symbol-file piloader/piloader.elf 0x400' \
		-ex 'add-symbol-file monitor/monitor.elf 0x40000000'

#-----------------------------------------------------------------------------

dir := pdclib
include $(dir)/subdir.mk
dir := piloader
include $(dir)/subdir.mk
dir := piimage
include $(dir)/subdir.mk
dir := monitor
include $(dir)/subdir.mk
dir := guestimg
include $(dir)/subdir.mk
dir := verified
include $(dir)/subdir.mk

%.o: %.c
	$(CC) $(CFLAGS_ALL) $(CFLAGS_LOCAL) -c $< -o $@
	$(CC) -MM $(CFLAGS_ALL) $(CFLAGS_LOCAL) -c $< -o $*.d

%.o: %.S
	$(CC) $(CFLAGS_ALL) $(CFLAGS_LOCAL) -c $< -o $@
	$(CC) -MM $(CFLAGS_ALL) $(CFLAGS_LOCAL) -c $< -o $*.d

clean:
	$(RM) $(CLEAN)
