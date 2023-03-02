.include "ihex.inc"
.include "uart.inc"

.zeropage
loadaddr: .res 2
checksum: .res 1

.bss
numbytes: .res 1
rectype: .res 1
tmp: .res 1

.code
to_hex:
    sec
    sbc #'0'
    cmp #10
    bcc @done
    sec
    sbc #7
@done:
    rts

read_hex:
    jsr uart_read
    jsr to_hex
    asl
    asl
    asl
    asl
    sta tmp
    jsr uart_read
    jsr to_hex
    and #$0f
    ora tmp
    rts

load_ihex:
@start:
    jsr uart_read
    cmp #':'
    bne @start

    ;load the number of bytes
    jsr read_hex
    sta checksum
    sta numbytes

    jsr read_hex
    sta loadaddr
    clc
    adc checksum
    sta checksum

    jsr read_hex
    sta loadaddr+1
    clc
    adc checksum
    sta checksum

    jsr read_hex
    sta rectype
    clc
    adc checksum
    sta checksum

    lda rectype
    cmp #2
    bpl @error

    ldy #0
@loop:
    cpy numbytes
    beq @check
    jsr read_hex
    sta (loadaddr),Y
    clc
    adc checksum
    sta checksum
    iny
    bra @loop

@check:
    jsr read_hex
    clc
    adc checksum
    bne @error

    lda rectype
    beq @start

    lda #0
    jsr uart_write
    lda #0
    rts

@error:
    lda #$ff
    jsr uart_write
    lda #$ff
    rts


