; vim: set syntax=asm_ca65:
.include "vectors.inc"
.include "uart.inc"
.include "console.inc"
.include "via.inc"
.include "spi.inc"
.include "sdcard.inc"
.include "fat.inc"
.include "macros.inc"
.include "mem.inc"
.import __ACIA_START__

.define RAMPRG_START $1000

.zeropage
load_ptr: .res 2
run_ptr: .res 2
load_size: .res 2

.bss
read_params: .res 6
read_buffer: .res 512
mem_params: .res MAX_MEM_PARAMS_SIZE
fat_params: .tag FATReadParams

.segment "IOFILL"
.word 0

.code
.import __DATA_LOAD__
.import __DATA_RUN__
.import __DATA_SIZE__
.import __BSS_SIZE__
.import __BSS_RUN__
reset_handler:
    sei
    cld
    ldx #$ff
    txs

    _SET_IM16 mem_params + CopyParams::src_ptr, __DATA_LOAD__
    _SET_IM16 mem_params + CopyParams::dst_ptr, __DATA_RUN__
    _SET_IM16 mem_params + CopyParams::size, __DATA_SIZE__

    lda #<mem_params
    ldx #>mem_params
    jsr memcpy

    _SET_IM16 mem_params + CopyParams::src_ptr, __BSS_RUN__
    _SET_IM16 mem_params + CopyParams::size, __BSS_SIZE__
    lda #0
    ldx #<mem_params
    ldy #>mem_params
    jsr memset

    lda #0
    tax
    jsr uart_init

    jsr spi_init
    jsr sdcard_init
    beq @failed
    jsr fat_init

    lda #<opening_str
    ldy #>opening_str
    jsr console_println
    lda #<open_file
    ldx #>open_file
    jsr fat_open
    jsr console_printhex
    jsr console_newline

    lda #<reading_str
    ldy #>reading_str
    jsr console_println

    lda #>RAMPRG_START
    jsr console_printhex
    lda #<RAMPRG_START
    jsr console_printhex
    jsr console_newline

    lda #<RAMPRG_START
    sta fat_params + FATReadParams::buffer
    lda #>RAMPRG_START
    sta fat_params + FATReadParams::buffer+1

    _SET_IM16 fat_params + FATReadParams::buffer_size, $0200

@read_loop:
    lda #<fat_params
    ldx #>fat_params
    jsr fat_read
    bmi @failed
    inc fat_params + FATReadParams::buffer + 1
    inc fat_params + FATReadParams::buffer + 1
    lda fat_params + FATReadParams::bytes_read
    ora fat_params + FATReadParams::bytes_read + 1
    bne @read_loop

    lda #<jumping_str
    ldy #>jumping_str
    jsr console_println
    jmp RAMPRG_START

@failed:
    lda #<failed_str
    ldy #>failed_str
    jsr console_println

forever:
    wai
    jmp forever

.rodata
open_file: .asciiz "AUTOBOOTBIN"
result_str: .asciiz "Read Result:"
opening_str: .asciiz "Opening"
reading_str: .asciiz "Reading"
jumping_str: .asciiz "Jumping"
failed_str: .asciiz "Failed to load program"
