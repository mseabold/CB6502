; vim: set syntax=asm_ca65:
.include "spi.inc"
.include "sdcard.inc"
.include "macros.inc"

.define R1_READY $00
.define R1_IDLE  $01
.define R1_ILLEGAL_CMD $04

.define CMD0 $40
.define CMD8 $48
.define CMD55 $77
.define CMD17 $51
.define ACMD41 $69

.zeropage
spi_param: .res 2
spi_buf: .res 2


.bss
r7_buf: .res 4
spi_crc: .res 1
buf_len: .res 2

.rodata
zero_param: .dword 0
CMD8_param: .byte $00, $00, $01, $aa
ACMD41_param: .byte $40, $00, $00, $00

.code
send_cmd:
    phx
    pha

    stz spi_crc
    cmp #$40
    bne @check8
    ldx #$95
    stx spi_crc
    jmp @wait_init
@check8:
    cmp #$48
    bne @wait_init
    ldx #$87
    stx spi_crc

@wait_init:
    ldx #$ff
@init_loop:
    lda #$ff
    jsr spi_transfer_byte
    cmp #$ff
    beq @send_cmd_byte
    dex
    bne @init_loop

@send_cmd_byte:
    pla
    jsr spi_transfer_byte
    ldy #0
    ldx #4
@send_param:
    lda (spi_param),Y
    jsr spi_transfer_byte
    iny
    dex
    bne @send_param

    lda spi_crc
    jsr spi_transfer_byte

    ldy #$ff
@wait_rsp:
    lda #$ff
    jsr spi_transfer_byte
    bit #$80
    bne @wait_rsp

    plx
    rts

read_r7:
    ldx #0
@read_loop:
    lda #$ff
    phx
    jsr spi_transfer_byte
    plx
    sta r7_buf,X
    inx
    txa
    cmp #4
    bne @read_loop
    rts

sdcard_init:
    ldx #10

@pump_loop:
    lda #$ff
    jsr spi_transfer_byte
    dex
    bne @pump_loop

    lda #SPI_SLAVE_0
    jsr spi_select_slave

    lda #<zero_param
    sta spi_param
    lda #>zero_param
    sta spi_param+1

    ldx #5
@cmd0_loop:
    lda #CMD0
    jsr send_cmd
    cmp #1
    beq @cmd8 ;TODO limit retries
    dex
    bne @cmd0_loop

    lda #SPI_SLAVE_0
    jsr spi_deselect_slave
    lda #0
    rts

@cmd8:
    lda #<CMD8_param
    sta spi_param
    lda #>CMD8_param
    sta spi_param+1
    lda #CMD8

    jsr send_cmd
    jsr read_r7

    ldx #10
@acmd41_loop:
    lda #<zero_param
    sta spi_param
    lda #>zero_param
    sta spi_param+1
    lda #CMD55

    jsr send_cmd

    lda #<ACMD41_param
    sta spi_param
    lda #>ACMD41_param
    sta spi_param+1
    lda #ACMD41

    jsr send_cmd
    cmp #0
    bne @acmd41_loop

    lda #SPI_SLAVE_0
    jsr spi_deselect_slave
    lda #1
    rts

; Params
; 4 byte address/block
; 2 byte output buffer pointer
; 2 byte size
sdcard_read_block_partial:
    sta spi_param
    stx spi_param+1
    ldy #6
    lda (spi_param),Y
    sta buf_len
    iny
    lda (spi_param),Y
    sta buf_len+1

do_read:
    ldy #4
    lda (spi_param),Y
    sta spi_buf
    iny
    lda (spi_param),Y
    sta spi_buf+1

    lda #SPI_SLAVE_0
    jsr spi_select_slave
    lda #CMD17
    jsr send_cmd

    cmp #0
    beq @wait_block
    lda #$ff
    rts

@wait_block:
    lda #$ff
    jsr spi_transfer_byte
    cmp #$ff
    beq @wait_block

    cmp #$fe
    beq @data_read
    lda #SPI_SLAVE_0
    jsr spi_deselect_slave
    lda #0
    rts

@data_read:
    ldx #0
    ldy #0
@loop:
    lda #$ff
    jsr spi_transfer_byte
    sta (spi_buf),Y
    iny
    bne @check_len
    inc spi_buf+1
    inx
@check_len:
    cpy buf_len
    bne @loop
    cpx buf_len+1
    bne @loop

    cpx #2
    beq @crc

@loop2:
    lda #$ff
    jsr spi_transfer_byte
    iny
    bne @loop2
    inc spi_buf+1
    inx
    cpx #2
    bne @loop2

@crc:
    ; CRC
    lda #$ff
    jsr spi_transfer_byte
    lda #$ff
    jsr spi_transfer_byte

    lda #SPI_SLAVE_0
    jsr spi_deselect_slave

    lda #0
    rts

sdcard_read_block:
    sta spi_param
    stx spi_param+1
    _SET_IM16 buf_len,$0200
    jmp do_read
