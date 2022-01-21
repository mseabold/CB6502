.include "mem.inc"

.zeropage
src: .res 2
dst: .res 2

.segment "UNINIT"
len: .res 2

.code
memcpy:
    ; Use dst is temporary storage to index the parameters
    sta dst
    stx dst+1

    ldy #0

    lda (dst),Y
    sta len
    iny
    lda (dst),Y
    sta len+1
    iny
    lda (dst),Y
    sta src
    iny
    lda (dst),Y
    sta src+1
    iny

    ; Load dst into registers first, then replace the temporary pointers
    lda (dst),Y
    tax
    iny
    lda (dst),Y

    stx dst
    sta dst+1

    ldy #0
    ldx len+1
    beq @remaining
@chunk:
    lda (src),Y
    sta (dst),Y
    iny
    bne @chunk
    ldy #0
    inc src+1
    inc dst+1
    dex
    bne @chunk
@remaining:
    cpy len
    beq @done
    lda (src),Y
    sta (dst),Y
    iny
    bra @remaining
@done:
    rts


memset:
    ; memset doesn't need dst, so we can use it as temporary storage
    stx dst
    sty dst+1
    pha

    ldy #0

    lda (dst),Y
    sta len
    iny
    lda (dst),Y
    sta len+1
    iny
    lda (dst),Y
    sta src
    iny
    lda (dst),Y
    sta src+1
    iny

    pla

    ldy #0
    ldx len+1
    beq @remaining
@chunk:
    sta (src),Y
    iny
    bne @chunk
    ldy #0
    inc src+1
    dex
    bne @chunk
@remaining:
    cpy len
    beq @done
    sta (src),Y
    iny
    bra @remaining
@done:
    rts


