.include "uart.inc"
.include "console.inc"

.define FLAG_SDP_ENABLED $01

.import __ROM_START__

.zeropage
inptr: .res 2
outptr: .res 2
numtags: .res 2
pagesize: .res 1
flags: .res 2

.bss
.global ACIA_isr
ACIA_isr: .res 2

.segment "START"
_start:
    jmp main

.code
main:
    lda #0
    tax
    jsr uart_init

    lda #<start_str
    ldy #>start_str
    jsr console_println

    lda update
    sta numtags
    lda update+1
    sta numtags+1

    lda update+2
    sta flags
    lda update+3
    sta flags+1

    lda #<(update+4)
    sta inptr
    lda #>(update+5)
    sta inptr+1

@mainloop:
    ; Load the page address
    lda numtags

    ldy #1
    lda (inptr)
    sta outptr
    lda (inptr),Y
    sta outptr+1

    ; Offset outptr
    iny
    lda (inptr),Y
    clc
    adc outptr
    sta outptr
    bcc @ldsize
    inc outptr+1

@ldsize:
    lda outptr+1
    lda outptr

    ldy #3
    lda (inptr),Y
    sta pagesize

    ; Increment inptr past the header
    clc
    lda #4
    adc inptr
    sta inptr
    bcc @writepage
    inc inptr+1

@writepage:
    jsr writepage
    jsr pollcycle

    sec
    lda numtags
    sbc #1
    sta numtags
    lda numtags+1
    sbc #0
    sta numtags+1

    ora numtags
    beq @done

    clc
    lda pagesize
    adc inptr
    sta inptr
    lda inptr+1
    adc #0
    sta inptr+1

    bra @mainloop

@done:
    lda #<done_str
    ldy #>done_str
    jsr console_println
@infloop:
    bra @infloop

writepage:
    lda #FLAG_SDP_ENABLED
    bit flags
    beq @nosdp

    ; Enable temporary SDP writes
    lda #$AA
    sta __ROM_START__ + $5555
    lda #$55
    sta __ROM_START__ + $2AAA
    lda #$A0
    sta __ROM_START__ + $5555

    ; Writes should now be enabled until the end of tWC
@nosdp:
    ldy #0
@pageloop:
    lda (inptr),Y
    sta (outptr),Y
    iny
    cpy pagesize
    bne @pageloop
    rts

pollcycle:
    dey
@pollloop:
    cmp (outptr),Y
    bne @pollloop
    rts


.rodata
start_str: .asciiz "Updating ROM image..."
done_str: .asciiz "Update Complete. Reset CPU now."
update: .incbin "boot_update.bin"
