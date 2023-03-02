MEMORY {
    RAM0: start = $0000, size = $0100;
    RAM1: start = $0200, size = $7e00;
    IO: start = $8000, size = $0080, fill = yes, fillval = 0;
    ACIA:  start = $8000, size = $0010, define = yes;
    VIA0:  start = $8010, size = $0010, define = yes;
    ROM: start = $8080, size = $7f7a, fill = yes, fillval = 0, define = yes;
    VECTORS: start = $fffa, size = 6, define = yes;
}

SEGMENTS {
    IOFILL: load = IO, type = ro;
    CODE: load = ROM, type = ro;
    RODATA: load = ROM, type = ro;
    DATA: load = ROM, run = RAM1, type = rw, define = yes;
    BSS: load = RAM1, type = bss, define = yes;
    UNINIT: load = RAM1, type = bss;
    VECTORS:  load = VECTORS, type = ro;
    ACIA_UART: load = ACIA, type = bss;
    VIA0: load = VIA0, type = bss;
    ZEROPAGE: load = RAM0, run = RAM0, type = zp;
}
