.include "boot_exp.inc"
.include "uart.inc"

.segment "START"
_start:
    jmp main

.code
main:
    jsr uart_read
    cmp #$0d
    beq @return
    cmp #$08
    beq @bksp
    jsr uart_write
    bra main
@return:
    jsr uart_write
    lda #$0a
    jsr uart_write
    bra main
@bksp:
    jsr uart_write
    lda #$20
    jsr uart_write
    lda #$08
    jsr uart_write
    bra main
