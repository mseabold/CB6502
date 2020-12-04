; vim: set syntax=asm_ca65:
.include "uart.inc"

.segment "ACIA_UART"
ACIA_UART: .tag ACIA_REGS

.bss
uart_callback: .res 2

uart_tx_buffer: .res 64
uart_tx_read_idx: .res 1
uart_tx_write_idx: .res 1


.code
.global ACIA_isr
uart_isr:
    pha

    lda uart_tx_read_idx
    inc a
    and #63
    cmp uart_tx_write_idx
    beq @done ; Buffer is full (we should have flowed off after the last byte)

    inc 
    inc a
    and #63
    ;

    lda uart_callback
    ora uart_callback+1
    bne @done
    pla
    jmp (uart_cleanup) ; The callback will rti

@done:
    pla
    rti

.global uart_init
uart_init:
    sta uart_callback
    stx uart_callback+1

    lda #<uart_isr
    sta ACIA_isr
    lda #>uart_isr
    sta ACIA_isr+1

    lda 0
    sta uart_tx_read_idx
    sta uart_tx_write_idx

    lda #$09
    sta ACIA_UART+ACIA_REGS::CMD
    lda #$10
    sta ACIA_UART+ACIA_REGS::CTRL

    rts

.global uart_cleanup
uart_cleanup:
    pha
    lda 0
    sta ACIA_UART+ACIA_REGS::STATUS
    pla
    rts

.global uart_write
uart_write:
    sta ACIA_UART+ACIA_REGS::DATA
    ; TODO Time this out better
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rts

.global uart_read
uart_read:
    ldy uart_tx_read_idx
    cpy uart_tx_write_idx
    bne @read
    lda 0
    rts

@read:
    ldx uart_tx_buffer,Y
    inc uart_tx_read_idx
    iny
    tya
    and #63
    sta uart_tx_read_idx
    lda 1
    rts
