; vim: set syntax=asm_ca65:
.include "version.inc"
.include "vectors.inc"
.include "uart.inc"
.include "console.inc"
.include "via.inc"
.include "spi.inc"
.include "sdcard.inc"
.include "fat.inc"
.include "macros.inc"
.include "mem.inc"
.include "ihex.inc"
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

    lda #<version
    ldy #>version
    jsr console_println

    jsr sdcard_detect
    bne @sddetect
    lda #<sd_detect_fail_str
    ldy #>sd_detect_fail_str
    jsr console_println
    jmp wait_ihex
@sddetect:
    lda #<sd_detect_str
    ldy #>sd_detect_str
    jsr console_println

    jsr spi_init
    jsr sdcard_init
    bne @open_fat
    lda #<sdfailed_str
    ldy #>sdfailed_str
    jsr console_println
    jmp wait_ihex


@open_fat:
    jsr fat_init
    bpl @open_fat2
    lda #<fatfailed_str
    ldy #>fatfailed_str
    jsr console_println
    jmp wait_ihex

@open_fat2:
    lda #<open_file
    ldx #>open_file
    jsr fat_open
    bmi wait_ihex

    lda #<autoboot_found_str
    ldy #>autoboot_found_str
    jsr console_println

    lda #<RAMPRG_START
    sta fat_params + FATReadParams::buffer
    lda #>RAMPRG_START
    sta fat_params + FATReadParams::buffer+1

    _SET_IM16 fat_params + FATReadParams::buffer_size, $0200

@read_loop:
    lda #<fat_params
    ldx #>fat_params
    jsr fat_read
    bmi @readfailed
    inc fat_params + FATReadParams::buffer + 1
    inc fat_params + FATReadParams::buffer + 1
    lda fat_params + FATReadParams::bytes_read
    ora fat_params + FATReadParams::bytes_read + 1
    bne @read_loop

    lda #<jumping_str
    ldy #>jumping_str
    jsr console_println
    jmp RAMPRG_START

@readfailed:
    lda #<read_failed_str
    ldy #>read_failed_str
    jsr console_println

wait_ihex:
    lda #<wait_ihex_str
    ldy #>wait_ihex_str
    jsr console_println

    jsr load_ihex
    bmi @ihexfail
    jmp RAMPRG_START

@ihexfail:
    lda #<ihex_fail_str
    ldy #>ihex_fail_str
    jsr console_println
    bra wait_ihex

.rodata
version: .asciiz "CB6502 bootrom v",VERSION_STRING
open_file: .asciiz "AUTOBOOTBIN"
sdfailed_str: .asciiz "Failed to init SD"
fatfailed_str: .asciiz "Failed to init FAT"
sd_detect_str: .asciiz "SD Card Detected. Checking for autoboot"
sd_detect_fail_str: .asciiz "No SD Card Detected"
autoboot_found_str: .asciiz "Autoboot binary found. Loading to RAM."
jumping_str: .asciiz "Jumping to autoboot program"
wait_ihex_str: .asciiz "No autoboot binary. Waiting for ihex over serial."
read_failed_str: .asciiz "Failed to read autoboot file."
ihex_fail_str: .asciiz "failed to parse ihex file"
