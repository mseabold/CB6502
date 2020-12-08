MEMORY {
    RAM0: start = $0000, size = $0100;
    RAM1: start = $0200, size = $3e00;
    ACIA:  start = $5000, size = $0010, define = yes;
    VIA:  start = $6000, size = $0010;
    ROM: start = $8000, size = $8000;
}

SEGMENTS {
    CODE: load = ROM, type = ro;
    RODATA: load = ROM, type = ro;
    DATA: load = ROM, run = RAM1, type = rw, define = yes;
    BSS: load = RAM1, type = bss;
    VECTORS:  load = ROM, type = ro, start = $fffa;
    ACIA_UART: load = ACIA, type = bss;
    ZEROPAGE: load = RAM0, run = RAM0, type = zp;
}
