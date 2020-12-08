; vim: set syntax=asm_ca65:
.include "vectors.inc"
.include "uart.inc"
.include "console.inc"
.import __ACIA_START__

.zeropage
load_ptr: .res 2
run_ptr: .res 2
load_size: .res 2

.code
.import __DATA_LOAD__
.import __DATA_RUN__
.import __DATA_SIZE__
reset_handler:
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

    ldx #$10
@delay:
    dex
    bne @delay


    lda #<msg
    ldy #>msg

    jsr console_println


forever:
    wai
    jmp forever

.rodata
msg: .asciiz "Hello, world!"
