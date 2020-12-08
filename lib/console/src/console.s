; vim: set syntax=asm_ca65:

.include "console.inc"
.include "uart.inc"

CR = $0d
LF = $0a

.zeropage
write_buffer: .res 2

.code
console_write:
    sta write_buffer
    sty write_buffer+1

@loop:
    lda (write_buffer)
    jsr uart_write
    inc write_buffer
    beq @next
    inc write_buffer+1
@next:
    dex
    bne @loop

    rts

console_print:
    sta write_buffer
    sty write_buffer+1

    ldy #0

@loop:
    lda (write_buffer),Y
    beq @done
    jsr uart_write
    iny
    bra @loop

@done:
    rts

console_println:
    jsr console_print
    lda #CR
    jsr uart_write
    lda #LF
    jsr uart_write

    rts
