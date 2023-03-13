OUTPUT ?= out
ROOTDIR ?= ../..
TOOLS ?= $(ROOTDIR)/tools
SCRIPTDIR := $(ROOTDIR)/build
BOOTBUILD := $(ROOTDIR)/out/boot
LINKERFILE ?= $(ROOTDIR)/app/common/app.ld

ASM := ca65
LD := ld65
AR := ar65
CPUFLAGS := --cpu 65c02

ifeq (${V},1)
hide :=
else
hide := @
endif

APP_OBJ := $(OUTPUT)/obj/loopback.o

INCLD := \
	$(BOOTBUILD) \
	$(ROOTDIR)/lib/uart/inc

APP_BIN := $(OUTPUT)/loopback.bin

ARTIFACTS := \
	$(APP_BIN) \
	$(APP_BIN:%.bin=%.ihex)

.PHONY:
all: $(ARTIFACTS)

include $(SCRIPTDIR)/common.mk
-include $(APP_OBJ:%.o=%.d)

.PHONY:
clean:
	rm -rf $(OUTPUT)

$(APP_BIN): $(APP_OBJ) $(LINKERFILE)
	@mkdir -p $(@D)
	@echo "[link] $@"
	$(hide)$(LD) -o $@ -C $(LINKERFILE) $(APP_OBJ) --dbgfile $(OUTPUT)/looback.dbg
