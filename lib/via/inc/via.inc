.struct VIA_REGS
    DATAB .byte
    DATAA .byte
    DDRB .byte
    DDRA .byte
    T1CL .byte
    T1CH .byte
    T1LL .byte
    T1LH .byte
    T2CL .byte
    T2CH .byte
    SR   .byte
    ACR  .byte
    PCR  .byte
    IFR  .byte
    IER  .byte
    DATAA2 .byte
.endstruct

.global VIA0
