.include "via.inc"
.include "spi.inc"

SPI_VIA = VIA0

;SPI Bit-Banging using VIA peripheral port
; bit 0 = CLK
; bit 1 = MOSI
; bit 2 = MISO
; bits 4-7 = SSs
SPI_CLK = $01
SPI_MOSI = $02
SPI_MISO = $04
SPI_SS0  = $10

.zeropage
spi_buffer: .res 1
tmp_dbg: .res 1

.code
spi_init:
    ; Configure CLK, MOSI, and SSs as output, MISO as input
    lda #$f3
    sta SPI_VIA+VIA_REGS::DDRB

    ; No slaves selected at boot and MODE0 is used exclusively for now, so CLK is idle low
    lda #$f0
    sta SPI_VIA+VIA_REGS::DATAB

    rts

spi_transfer_byte:
    sta spi_buffer
    phx

    ldx #8

    ; for now hardcode SS0
    ;sta SPI_VIA+VIA_REGS::DATAB
    lda SPI_VIA+VIA_REGS::DATAB


@loop:
    asl spi_buffer
    bcc @write
    ora #SPI_MOSI
@write:
    sta SPI_VIA+VIA_REGS::DATAB
    inc SPI_VIA+VIA_REGS::DATAB
    tay
    lda #SPI_MISO
    bit SPI_VIA+VIA_REGS::DATAB
    beq @next
    inc spi_buffer
@next:
    dec SPI_VIA+VIA_REGS::DATAB
    tya
    and #(SPI_MOSI ^ $ff)
    dex
    bne @loop

    and #$f0
    sta SPI_VIA+VIA_REGS::DATAB
    lda spi_buffer
    plx
    rts

spi_select_slave:
    eor #$ff
    sta tmp_dbg
    and SPI_VIA+VIA_REGS::DATAB
    sta SPI_VIA+VIA_REGS::DATAB
    rts

spi_deselect_slave:
    ora SPI_VIA+VIA_REGS::DATAB
    sta SPI_VIA+VIA_REGS::DATAB
    rts


