; vim: set syntax=asm_ca65:
.include "uart.inc"

; TODO Move ACIA general stuff out to a separate module, in case more than 1 ACIA is ever used for
;      different purposes (not sure why)
.segment "ACIA_UART"
ACIA_UART: .tag ACIA_REGS

.bss
uart_callback: .res 2

uart_tx_buffer: .res 64
uart_tx_read_idx: .res 1
uart_tx_write_idx: .res 1


CMD_DTR_RDY             = $01
CMD_DTR_NRDY            = $00
CMD_RX_INTR_EN          = $02
CMD_RX_INTR_DIS         = $00
CMD_RTSH_TX_ISR_DIS     = $00
CMD_RTSL_TX_ISR_EN      = $04
CMD_RTSL_TX_ISR_DIS     = $08
CMD_RTSL_TX_ISR_DIS_BRK = $0C
CMD_RX_ECHO_EN          = $10
CMD_RX_ECHO_DIS         = $00
CMD_PAR_EN              = $20
CMD_PAR_DIS             = $00
CMD_PAR_MODE_ODD        = $00
CMD_PAR_MODE_EVEN       = $40
CMD_PAR_MODE_DIS        = $C0

CTRL_BAUD_DIV_16x       = $00
CTRL_RX_CLK_EXT         = $00
CTRL_RX_CLK_BAUD        = $10
CTRL_WORD_LEN_8_BIT     = $00
CTRL_WORD_LEN_7_BIT     = $20
CTRL_WORD_LEN_6_BIT     = $40
CTRL_WORD_LEN_5_BIT     = $60
CTRL_STOP_BITS_1        = $00
CTRL_STOP_BITS_2_1_5    = $80

.code
.global ACIA_isr
uart_isr:
    pha

    lda uart_tx_read_idx
    inc a
    and #63
    cmp uart_tx_write_idx
    ;TODO Flowing off would be useful, but asserting RTSB seems to prevent TX?
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

    lda #0
    sta uart_tx_read_idx
    sta uart_tx_write_idx

    lda #(CMD_DTR_RDY | CMD_RX_INTR_EN | CMD_RTSL_TX_ISR_DIS)
    sta ACIA_UART+ACIA_REGS::CMD
    lda #(CTRL_STOP_BITS_1 | CTRL_WORD_LEN_8_BIT | CTRL_STOP_BITS_1 | CTRL_BAUD_DIV_16x)
    sta ACIA_UART+ACIA_REGS::CTRL

    rts

.global uart_cleanup
uart_cleanup:
    pha
    lda #0
    sta ACIA_UART+ACIA_REGS::STATUS
    pla
    rts

.global uart_write
uart_write:
    sta ACIA_UART+ACIA_REGS::DATA
    ; TODO Time this out better
    phx
    ldx #20
@loop:
    dex
    beq @done
    jmp @loop
@done:
    plx
    rts

.global uart_read
uart_read:
    ldy uart_tx_read_idx
    cpy uart_tx_write_idx
    bne @read
    lda #0
    rts

@read:
    ldx uart_tx_buffer,Y
    inc uart_tx_read_idx
    iny
    tya
    and #63
    sta uart_tx_read_idx
    lda #1
    rts
