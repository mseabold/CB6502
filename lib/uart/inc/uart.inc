; vim: set syntax=asm_ca65:

.struct ACIA_REGS
    DATA .byte
    STATUS .byte
    CMD .byte
    CTRL .byte
.endstruct

.global ACIA_isr

; Initialize the UART
;
; Parameters:
;    A: High byte of callback
;    X: Low byte of callback
.global uart_init

; Cleanup the UART
.global uart_cleanup

; Write a byte to the UART and wait for completion
;
; Parameters:
;    A: Byte to write
.global uart_write

; Read a byte from the UART
;
; Returns:
;    A: Status of the read: 1 = Read, 0 = Buffer empty
;    X: Byte read of successful
.global uart_read


