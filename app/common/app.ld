MEMORY {
    RAM0: start = $0040, size = $00c0;
    RAM1: start = $1000, size = $3000;
}

SEGMENTS {
    START: load = RAM1, type = ro;
    CODE: load = RAM1, type = ro;
    RODATA: load = RAM1, type = ro;
    BSS: load = RAM1, type = bss;
    DATA: load = RAM1, type = rw;
    ZEROPAGE: load = RAM0, run = RAM0, type = zp;
}

