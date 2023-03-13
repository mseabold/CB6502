$(OUTPUT)/obj/%.o: %.s
	@mkdir -p $(@D)
	@echo "[asm] $<"
	$(hide)$(ASM) $(INCLD:%=-I %) $(LOCALINCLD) $(LOCALDEF) $(CPUFLAGS) --create-full-dep $(@:%.o=%.d) -g -o $@ $<

%.ihex: %.bin
	@echo "[ihex] $@"
	$(hide)python $(TOOLS)/to_ihex.py -o $@ $<

%_exp.inc: %.map
	@echo "[exp] $@"
	$(hide)python $(TOOLS)/create_exports.py -f -o $@ $^

