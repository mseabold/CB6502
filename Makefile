OUTPUT ?= out
TOOLS ?= tools
ASM := ca65
LD := ld65
AR := ar65
CPUFLAGS := --cpu 65c02
UPDATE_TOOL ?= $(TOOLS)/pack_update.py

ifeq (${V},1)
hide :=
else
hide := @
endif

BOOTVER :=

ifdef BOOTVER_MAJOR
BOOTVER += -D VERSION_MAJOR=$(BOOTVER_MAJOR)
endif

ifdef BOOTVER_MINOR
BOOTVER += -D VERSION_MINOR=$(BOOTVER_MINOR)
endif

ifdef BOOTVER_STEP
BOOTVER += -D VERSION_STEP=$(BOOTVER_STEP)
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

BOOT_BIN := $(BOOTOUT)/boot.bin

BOOT_UPDATE := $(BOOTOUT)/boot_update.bin

BOOT_ARTIFACTS := \
	$(BOOT_BIN) \
	$(BOOT_BIN:%.bin=%.ihex) \
	$(BOOT_BIN:%.bin=%_exp.inc) \
	$(BOOT_UPDATE)

.PHONY:
all: boot apps

include build/common.mk

define deflib =
$(1)_OBJS := $$($(1)_SRC:%.s=$(OUTPUT)/obj/%.o)
$(OUTPUT)/lib/$(1).lib: $$($(1)_OBJS)
ALL_OBJS += $$($(1)_OBJS)
endef

ALL_OBJS := $(BOOT_OBJS)

$(foreach lib,$(LIBNAMES),$(eval $(call deflib,$(lib))))

-include $(ALL_OBJS:%.o=%.d)

.PHONY:
clean:
	rm -rf $(OUTPUT)

.PHONY:
boot: $(BOOT_ARTIFACTS)

.PHONY:
apps: boot
	@$(MAKE) -C app

$(BOOT_OBJS): LOCALDEF := $(BOOTVER)
$(BOOT_BIN) $(BOOTOUT)/boot.map: $(BOOT_OBJS) boot/src/boot.ld $(BOOT_LIBS)
	@mkdir -p $(@D)
	@echo "[link] $@"
	$(hide)$(LD) -o $@ -C boot/src/boot.ld -L $(BOOTOUT)/lib -vm -m$(BOOTOUT)/boot.map  $(BOOT_OBJS) $(BOOT_LIBS) -Ln ${BOOTOUT}/boot.lbl --dbgfile ${BOOTOUT}/boot.dbg

$(LIBRARIES):
	@mkdir -p $(@D)
	@echo "[ar] $@ $^"
	$(hide)$(AR) r $@ $^

$(BOOT_UPDATE): $(UPDATE_TOOL) $(BOOT_BIN) $(BOOTOUT)/boot.map
	@echo "[pack_update] $@"
	$(hide)python $(UPDATE_TOOL) -vp -o $@ $(BOOT_BIN) $(BOOTOUT)/boot.map
