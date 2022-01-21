.macro _ADD32 a1,a2,s
    clc
    lda a1
    adc a2
    sta s
    lda a1+1
    adc a2+1
    sta s+1
    lda a1+2
    adc a2+2
    sta s+2
    lda a1+3
    adc a2+3
    sta s+3
.endmacro

.macro _SUB32 a1,s2,d
    sec
    lda a1
    sbc a2
    sta d
    lda a1+1
    sbc a2+1
    sta d+1
    lda a1+2
    sbc a2+2
    sta d+2
    lda a1+3
    sbc a2+3
    sta d+3
.endmacro

.macro _MOV16 d,s
    lda s
    sta d
    lda s+1
    sta d+1
.endmacro

.macro _MOV32 d,s
    lda s
    sta d
    lda s+1
    sta d+1
    lda s+2
    sta d+2
    lda s+3
    sta d+3
.endmacro

.macro _SET_IM16 d,imm
    lda #<imm
    sta d
    lda #>imm
    sta d+1
.endmacro
