.include "console.inc"

.segment "START"
_start:
    jmp main

.import __ACIA_START__
.code
main:

    lda #<__ACIA_START__
    sta temp
    lda #>__ACIA_START__
    sta temp + 1
    lda temp + 1
    lda temp

    lda #<hello
    ldy #>hello
    jsr console_println
@forever:
    jmp @forever
.rodata
hello: .asciiz "Hello, World!"

.bss
.global ACIA_isr
ACIA_isr: .res 2
temp: .res 2
