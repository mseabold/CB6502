OUTPUT ?= out
ROOTDIR ?= ../..
TOOLS ?= $(ROOTDIR)/tools
SCRIPTDIR := $(ROOTDIR)/build
BOOTBUILD ?= $(ROOTDIR)/out/boot
LIBOUT ?= $(ROOTDIR)/out/lib

ASM := ca65
LD := ld65
AR := ar65
CPUFLAGS := --cpu 65c02

ifeq (${V},1)
hide :=
else
hide := @
endif

APP_OBJ := $(OUTPUT)/obj/update.o

INCLD := \
	$(BOOTBUILD) \
	$(ROOTDIR)/lib/uart/inc \
	$(ROOTDIR)/lib/console/inc

LIBS := \
	$(LIBOUT)/console.lib \
	$(LIBOUT)/uart.lib

APP_BIN := $(OUTPUT)/update.bin

ARTIFACTS := \
	$(APP_BIN) \
	$(APP_BIN:%.bin=%.ihex)

.PHONY:
all: $(ARTIFACTS)

include $(SCRIPTDIR)/common.mk
-include $(APP_OBJ:%.o=%.d)

$(APP_OBJ): LOCALDEF := --bin-include-dir $(BOOTBUILD)

.PHONY:
clean:
	rm -rf $(OUTPUT)

$(APP_BIN): $(APP_OBJ) update.ld $(BOOTBUILD)/boot_update.bin
	@mkdir -p $(@D)
	@echo "[link] $@"
	$(hide)$(LD) -o $@ -C update.ld $(APP_OBJ) $(LIBS) --dbgfile $(OUTPUT)/update.dbg
