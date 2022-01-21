MEMORY {
    RAM0: start = $0040, size = $00c0;
    RAM1: start = $1000, size = $3000;
    ACIA:  start = $8000, size = $0010, define = yes;
    VIA0:  start = $8010, size = $0010;
}

SEGMENTS {
    START: load = RAM1, type = ro;
    CODE: load = RAM1, type = ro;
    RODATA: load = RAM1, type = ro;
    BSS: load = RAM1, type = bss;
    DATA: load = RAM1, type = rw;
    ACIA_UART: load = ACIA, type = bss;
    ZEROPAGE: load = RAM0, run = RAM0, type = zp;
}

