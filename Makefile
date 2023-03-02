OUTPUT ?= out
ASM := ca65
LD := ld65
AR := ar65
CPUFLAGS := --cpu 65c02

ifeq (${V},1)
hide :=
else
hide := @
endif

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

IHEX_SRC := \
	lib/ihex/src/ihex.s

BOOTOUT := \
	$(OUTPUT)/boot

INCLD := \
	boot/inc \
	lib/uart/inc \
	lib/console/inc \
	lib/via/inc \
	lib/spi/inc \
	lib/sdcard/inc \
	lib/fat/inc \
	lib/runtime/inc \
	lib/ihex/inc

BOOT_OBJS := $(BOOT_SRCS:%.s=$(OUTPUT)/obj/%.o)
UART_OBJS := $(UART_SRC:%.s=$(OUTPUT)/obj/%.o)
CONSOLE_OBJS := $(CONSOLE_SRC:%.s=$(OUTPUT)/obj/%.o)
VIA_OBJS := $(VIA_SRC:%.s=$(OUTPUT)/obj/%.o)
SPI_OBJS := $(SPI_SRC:%.s=$(OUTPUT)/obj/%.o)
SDCARD_OBJS := $(SDCARD_SRC:%.s=$(OUTPUT)/obj/%.o)
FAT_OBJS := $(FAT_SRC:%.s=$(OUTPUT)/obj/%.o)
RUNTIME_OBJS := $(RUNTIME_SRC:%.s=$(OUTPUT)/obj/%.o)
IHEX_OBJS :=  $(IHEX_SRC:%.s=$(OUTPUT)/obj/%.o)

BOOT_LIBS := \
	$(OUTPUT)/lib/fat.lib \
	$(OUTPUT)/lib/sdcard.lib \
	$(OUTPUT)/lib/console.lib \
	$(OUTPUT)/lib/uart.lib \
	$(OUTPUT)/lib/spi.lib \
	$(OUTPUT)/lib/via.lib \
	$(OUTPUT)/lib/runtime.lib \
	$(OUTPUT)/lib/ihex.lib \

BOOT_BIN := \
	$(BOOTOUT)/bin/boot.bin \

.PHONY:
all: $(BOOT_BIN)

ALL_OBJS := $(BOOT_OBJS) $(UART_OBJS) $(CONSOLE_OBJS) $(VIA_OBJS) $(SPI_OBJS) $(SDCARD_OBJS) $(FAT_OBJS) $(RUNTIME_OBJS)

-include $(ALL_OBJS:%.o=%.d)

.PHONY:
clean:
	rm -rf $(OUTPUT)

$(BOOT_BIN) $(BOOTOUT)/bin/boot.map: $(BOOT_OBJS) boot/src/boot.ld $(BOOT_LIBS)
	@mkdir -p $(@D)
	@echo "[link] $@"
	$(hide)$(LD) -o $@ -C boot/src/boot.ld -L $(BOOTOUT)/lib -vm -m$(BOOTOUT)/bin/boot.map  $(BOOT_OBJS) $(BOOT_LIBS) -Ln ${BOOTOUT}/boot.lbl --dbgfile ${BOOTOUT}/boot.dbg

$(OUTPUT)/obj/%.o: %.s
	@mkdir -p $(@D)
	@echo "[asm] $<"
	$(hide)$(ASM) $(INCLD:%=-I %) $(LOCALINCLD) $(LOCALDEF) $(CPUFLAGS) --create-full-dep $(@:%.o=%.d) -g -o $@ $<

$(OUTPUT)/lib/uart.lib: $(UART_OBJS)
	@mkdir -p $(@D)
	@echo "[ar] $@"
	$(hide)$(AR) r $@ $^

$(OUTPUT)/lib/console.lib: $(CONSOLE_OBJS)
	@mkdir -p $(@D)
	@echo "[ar] $@"
	$(hide)$(AR) r $@ $^

$(OUTPUT)/lib/via.lib: $(VIA_OBJS)
	@mkdir -p $(@D)
	@echo "[ar] $@"
	$(hide)$(AR) r $@ $^

$(OUTPUT)/lib/spi.lib: $(SPI_OBJS)
	@mkdir -p $(@D)
	@echo "[ar] $@"
	$(hide)$(AR) r $@ $^

$(OUTPUT)/lib/sdcard.lib: $(SDCARD_OBJS)
	@mkdir -p $(@D)
	@echo "[ar] $@"
	$(hide)$(AR) r $@ $^

$(OUTPUT)/lib/fat.lib: $(FAT_OBJS)
	@mkdir -p $(@D)
	@echo "[ar] $@"
	$(hide)$(AR) r $@ $^

$(OUTPUT)/lib/runtime.lib: $(RUNTIME_OBJS)
	@mkdir -p $(@D)
	@echo "[ar] $@"
	$(hide)$(AR) r $@ $^

$(OUTPUT)/lib/ihex.lib: $(IHEX_OBJS)
	@mkdir -p $(@D)
	@echo "[ar $@"
	$(hide)$(AR) r $@ $^
