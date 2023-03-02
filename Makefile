OUTPUT ?= out
TOOLS ?= tools
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

uart_SRC := \
	lib/uart/src/uart.s

via_SRC := \
	lib/via/src/via.s

console_SRC := \
	lib/console/src/console.s

spi_SRC := \
	lib/spi/src/spi.s

sdcard_SRC := \
	lib/sdcard/src/sdcard.s

fat_SRC := \
	lib/fat/src/fat.s

runtime_SRC := \
	lib/runtime/src/mem.s

ihex_SRC := \
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

LIBNAMES := \
	uart \
	console \
	via \
	spi \
	sdcard \
	fat \
	runtime \
	ihex

LIBRARIES := $(LIBNAMES:%=$(OUTPUT)/lib/%.lib)

BOOT_OBJS := $(BOOT_SRCS:%.s=$(OUTPUT)/obj/%.o)

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
	$(BOOTOUT)/boot.bin \

BOOT_ARTIFACTS := \
	$(BOOT_BIN) \
	$(BOOT_BIN:%.bin=%.ihex) \
	$(BOOT_BIN:%.bin=%_exp.inc)

.PHONY:
all: $(BOOT_ARTIFACTS)

ALL_OBJS := $(BOOT_OBJS)

define deflib =
$(1)_OBJS := $$($(1)_SRC:%.s=$(OUTPUT)/obj/%.o)
$(OUTPUT)/lib/$(1).lib: $$($(1)_OBJS)
ALL_OBJS += $$($(1)_OBJS)
endef

$(foreach lib,$(LIBNAMES),$(eval $(call deflib,$(lib))))

-include $(ALL_OBJS:%.o=%.d)

.PHONY:
clean:
	rm -rf $(OUTPUT)

$(BOOT_BIN) $(BOOTOUT)/boot.map: $(BOOT_OBJS) boot/src/boot.ld $(BOOT_LIBS)
	@mkdir -p $(@D)
	@echo "[link] $@"
	$(hide)$(LD) -o $@ -C boot/src/boot.ld -L $(BOOTOUT)/lib -vm -m$(BOOTOUT)/boot.map  $(BOOT_OBJS) $(BOOT_LIBS) -Ln ${BOOTOUT}/boot.lbl --dbgfile ${BOOTOUT}/boot.dbg

$(OUTPUT)/obj/%.o: %.s
	@mkdir -p $(@D)
	@echo "[asm] $<"
	$(hide)$(ASM) $(INCLD:%=-I %) $(LOCALINCLD) $(LOCALDEF) $(CPUFLAGS) --create-full-dep $(@:%.o=%.d) -g -o $@ $<

$(LIBRARIES):
	@mkdir -p $(@D)
	@echo "[ar] $@ $^"
	$(hide)$(AR) r $@ $^

%.ihex: %.bin
	@echo "[ihex] $@"
	$(hide)python $(TOOLS)/to_ihex.py -o $@ $<

%_exp.inc: %.map
	@echo "[exp] $@"
	$(hide)python $(TOOLS)/create_exports.py -f -o $@ $^
