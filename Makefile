OUTPUT ?= out
ASM := ca65
LD := ld65
AR := ar65
CPUFLAGS := --cpu 65c02

BOOT_SRCS := \
	boot/src/vectors.s \
	boot/src/startup.s \
	lib/uart/src/uart.s

UART_SRC := \
	lib/uart/src/uart.s

INCLD := \
	boot/inc \
	lib/uart/inc

BOOT_OBJS := $(BOOT_SRCS:%.s=out/obj/%.o)
UART_OBJS := $(UART_SRC:%.s=out/obj/%.o)

BOOT_LIBS := \
	$(OUTPUT)/lib/uart.lib

.PHONY:
all: $(OUTPUT)/bin/boot.bin

.PHONY:
clean:
	rm -rf $(OUTPUT)

$(OUTPUT)/bin/boot.bin: $(BOOT_OBJS) boot/src/boot.ld $(BOOT_LIBS)
	@mkdir -p $(@D)
	$(LD) -o $@ -C boot/src/boot.ld -L$(OUTPUT)/lib $(BOOT_OBJS) $(BOOT_LIBS)

$(OUTPUT)/obj/%.o: %.s
	@mkdir -p $(@D)
	$(ASM) $(INCLD:%=-I %) $(CPUFLAGS) -o $@ $<

$(OUTPUT)/lib/uart.lib: $(UART_OBJS)
	@mkdir -p $(@D)
	$(AR) r $@ $^
