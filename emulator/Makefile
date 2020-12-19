OBJS := \
	cpu.o \
	main.o \
	acia.o

all: simCB6502

simCB6502: $(OBJS)
	$(LINK.o) $(LDLIBS) -o $@ $^


