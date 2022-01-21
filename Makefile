OUTPUT ?= out
ASM := ca65
LD := ld65
AR := ar65
CPUFLAGS := --cpu 65c02

BOOT_SRCS := \
	boot/src/vectors.s \
	boot/src/startup.s \

UART_SRC := \
	lib/uart/src/uart.s

VIA_SRC := \
	lib/via/src/via.s

CONSOLE_SRC := \
	lib/console/src/console.s

SPI_SRC := \
	lib/spi/src/spi.s

SDCARD_SRC := \
	lib/sdcard/src/sdcard.s

FAT_SRC := \
	lib/fat/src/fat.s

RUNTIME_SRC := \
	lib/runtime/src/mem.s

APP_SRC := \
	app/test/src/app.s

INCLD := \
	boot/inc \
	lib/uart/inc \
	lib/console/inc \
	lib/via/inc \
	lib/spi/inc \
	lib/sdcard/inc \
	lib/fat/inc \
	lib/runtime/inc

BOOT_OBJS := $(BOOT_SRCS:%.s=out/obj/%.o)
UART_OBJS := $(UART_SRC:%.s=out/obj/%.o)
CONSOLE_OBJS := $(CONSOLE_SRC:%.s=out/obj/%.o)
VIA_OBJS := $(VIA_SRC:%.s=out/obj/%.o)
SPI_OBJS := $(SPI_SRC:%.s=out/obj/%.o)
SDCARD_OBJS := $(SDCARD_SRC:%.s=out/obj/%.o)
FAT_OBJS := $(FAT_SRC:%.s=out/obj/%.o)
RUNTIME_OBJS := $(RUNTIME_SRC:%.s=out/obj/%.o)
APP_OBJS := $(APP_SRC:%.s=out/obj/%.o)

BOOT_LIBS := \
	$(OUTPUT)/lib/fat.lib \
	$(OUTPUT)/lib/sdcard.lib \
	$(OUTPUT)/lib/console.lib \
	$(OUTPUT)/lib/uart.lib \
	$(OUTPUT)/lib/spi.lib \
	$(OUTPUT)/lib/via.lib \
	$(OUTPUT)/lib/runtime.lib \

APP_LIBS := \
	$(OUTPUT)/lib/console.lib \
	$(OUTPUT)/lib/uart.lib \

.PHONY:
all: $(OUTPUT)/bin/boot.bin $(OUTPUT)/app/app.bin

ALL_OBJS := $(BOOT_OBJS) $(UART_OBJS) $(CONSOLE_OBJS) $(VIA_OBJS) $(SPI_OBJS) $(SDCARD_OBJS) $(FAT_OBJS) $(RUNTIME_OBJS)

-include $(ALL_OBJS:%.o=%.d)

.PHONY:
clean:
	rm -rf $(OUTPUT)

$(OUTPUT)/bin/boot.bin $(OUTPUT)/bin/boot.map: $(BOOT_OBJS) boot/src/boot.ld $(BOOT_LIBS)
	@mkdir -p $(@D)
	$(LD) -o $@ -C boot/src/boot.ld -L$(OUTPUT)/lib -vm -m$(OUTPUT)/bin/boot.map  $(BOOT_OBJS) $(BOOT_LIBS) -Ln wat.wut

$(OUTPUT)/app/app.bin $(OUTPUT)/app/app.map: $(APP_OBJS) app/test/src/app.ld $(APP_LIBS)
	@mkdir -p $(@D)
	$(LD) -o $@ -C app/test/src/app.ld -L$(OUTPUT)/lib -vm -m$(OUTPUT)/app/app.map  $(APP_OBJS) $(APP_LIBS)

$(OUTPUT)/obj/%.o: %.s
	@mkdir -p $(@D)
	$(ASM) $(INCLD:%=-I %) $(CPUFLAGS) --create-full-dep $(@:%.o=%.d) -o $@ $<

$(OUTPUT)/lib/uart.lib: $(UART_OBJS)
	@mkdir -p $(@D)
	$(AR) r $@ $^

$(OUTPUT)/lib/console.lib: $(CONSOLE_OBJS)
	@mkdir -p $(@D)
	$(AR) r $@ $^

$(OUTPUT)/lib/via.lib: $(VIA_OBJS)
	@mkdir -p $(@D)
	$(AR) r $@ $^

$(OUTPUT)/lib/spi.lib: $(SPI_OBJS)
	@mkdir -p $(@D)
	$(AR) r $@ $^

$(OUTPUT)/lib/sdcard.lib: $(SDCARD_OBJS)
	@mkdir -p $(@D)
	$(AR) r $@ $^

$(OUTPUT)/lib/fat.lib: $(FAT_OBJS)
	@mkdir -p $(@D)
	$(AR) r $@ $^

$(OUTPUT)/lib/runtime.lib: $(RUNTIME_OBJS)
	@mkdir -p $(@D)
	$(AR) r $@ $^
