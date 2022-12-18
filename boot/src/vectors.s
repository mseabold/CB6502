; vim: set syntax=asm_ca65:
;
.include "vectors.inc"
.import __ACIA_START__

.data
ACIA_isr: .word default_vector

.code
default_vector:
    rti

irq_isr:
    pha
    lda #$80
    bit __ACIA_START__+1
    beq @isr1
    pla
    jmp (ACIA_isr)

@isr1:
    pla
    rti

.segment "VECTORS"
.word default_vector
.word reset_handler
.word irq_isr

