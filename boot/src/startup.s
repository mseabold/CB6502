; vim: set syntax=asm_ca65:
.include "vectors.inc"
.include "uart.inc"
.include "console.inc"
.include "via.inc"
.include "spi.inc"
.include "sdcard.inc"
.import __ACIA_START__

.zeropage
load_ptr: .res 2
run_ptr: .res 2
load_size: .res 2

.bss
read_params: .res 6
read_buffer: .res 512

.code
.import __DATA_LOAD__
.import __DATA_RUN__
.import __DATA_SIZE__
reset_handler:
    sei
    cld
    ldx #$ff
    txs
    lda #<__DATA_LOAD__
    sta load_ptr
    lda #>__DATA_LOAD__
    sta load_ptr+1
    lda #<__DATA_RUN__
    sta run_ptr
    lda #>__DATA_RUN__
    sta run_ptr+1
    lda #<__DATA_SIZE__
    sta load_size
    lda #>__DATA_SIZE__
    sta load_size+1

    ldx #0
    ldy #0

@copy_loop:
    cpy load_size
    bne @copy_byte
    cpx load_size+1
    beq @copy_done

@copy_byte:
    lda (load_ptr),Y
    sta (run_ptr),Y

    iny
    bne @copy_loop

    inx
    inc load_ptr+1
    inc run_ptr+1
    jmp @copy_loop

@copy_done:


    lda #0
    tax
    jsr uart_init
    jsr spi_init
    jsr sdcard_init

    lda #0
    sta read_params
    sta read_params+1
    sta read_params+2
    sta read_params+3

    lda #<read_buffer
    sta read_params+4
    lda #>read_buffer
    sta read_params+5

    lda #<read_params
    ldx #>read_params

    jsr sdcard_read_block
    ldx #0

@print_loop:
    lda read_buffer,X
    phx
    jsr console_printhex
    jsr console_newline
    plx
    inx
    bne @print_loop

    ldx #0
@print_loop2:
    lda read_buffer+256,X
    phx
    jsr console_printhex
    jsr console_newline
    plx
    inx
    bne @print_loop2

forever:
    wai
    jmp forever

