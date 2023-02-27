.include "console.inc"
.include "sdcard.inc"
.include "fat.inc"
.include "macros.inc"
.include "mem.inc"

.define PART_ENTRIES_OFFSET 446
.define PART_ENTRY_SIZE 16
.define PART_LBA_OFFSET $8
.define BPB_OFFSET $0b

.struct FileContext
    cluster .dword
    sector .dword
    offset .byte
.endstruct

FLAG_CACHE_VALID = $01
FLAG_EOF         = $02

.bss
flags: .res 1
read_params: .res 8
cached_sector: .res 4
read_buffer: .res 512
lba: .res 4
cluster_size: .res 1
reserved_sects: .res 1
current_dir: .res 4
fat_sector: .res 4
cluster_shift: .res 1
data_start: .res 4
filename_8_3: .res 13
filesize: .res 4
temp: .res 4
dircount: .res 1

file_cxt: .tag FileContext
dir_cxt: .tag FileContext

.struct BPB
    bytes_per_sector .word
    cluster_size .byte
    reserved .word
    num_fats .byte
    root_entries .word
    total_sects .word
    media_desc .byte
    sectors_per_fat .word
    phys_per_track .word
    num_heads .word
    hidden .dword
    total_sects_32 .dword
    sectors_per_fat_32 .dword
    drive_desc .word
    version .word
    current_dir .dword
    fsinfo_sect .word
    copy_sect .word
.endstruct

.struct dirent
    filename .res 8
    extension .res 3
    attributes .byte
    unused .res 8
    cluster_high .word
    times .dword
    cluster_low .word
    file_size .dword
.endstruct


.zeropage
read_ptr: .res 2
param_ptr: .res 2
temp_ptr: .res 2

.code
fat_cache_block:
    lda flags
    bit #FLAG_CACHE_VALID
    beq @read_block
    lda read_params
    cmp cached_sector+3
    bne @read_block
    lda read_params+1
    cmp cached_sector+2
    bne @read_block
    lda read_params+2
    cmp cached_sector+1
    bne @read_block
    lda read_params+3
    cmp cached_sector
    bne @read_block
    lda #0
    rts
@read_block:
    lda #<read_params
    ldx #>read_params
    jsr sdcard_read_block
    bpl @flag
    rts
@flag:
    lda flags
    ora #FLAG_CACHE_VALID
    sta flags
    lda read_params
    sta cached_sector+3
    lda read_params+1
    sta cached_sector+2
    lda read_params+2
    sta cached_sector+1
    lda read_params+3
    sta cached_sector
    lda #0
    rts

fat_init:
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

    jsr fat_cache_block
    bpl @continue
    rts

@continue:
    lda #<(read_buffer + PART_ENTRIES_OFFSET)
    sta read_ptr
    lda #>(read_buffer + PART_ENTRIES_OFFSET)
    sta read_ptr+1

    ldy #PART_LBA_OFFSET
    ldx #0
    lda (read_ptr),Y
    sta lba,X
    iny
    inx
    lda (read_ptr),Y
    sta lba,X
    iny
    inx
    lda (read_ptr),Y
    sta lba,X
    iny
    inx
    lda (read_ptr),Y
    sta lba,X

    ;Assume partition 0
    lda lba
    sta read_params+3
    lda lba+1
    sta read_params+2
    lda lba+2
    sta read_params+1
    lda lba+3
    sta read_params

    lda #<read_buffer
    sta read_params+4
    lda #>read_buffer
    sta read_params+5

    lda #<read_params
    ldx #>read_params
    jsr fat_cache_block

    lda read_buffer + BPB_OFFSET + BPB::cluster_size
    sta cluster_size
    ldx #0
@shift_count:
    lsr
    beq @shift_count_done
    inx
    bra @shift_count
@shift_count_done:
    stx cluster_shift

    _MOV32 fat_sector,lba

    clc
    lda fat_sector
    adc read_buffer + BPB_OFFSET + BPB::reserved
    sta fat_sector
    bcc @l1
    inc fat_sector+1
    bne @l1
    inc fat_sector+2
    bne @l1
    inc fat_sector+3

@l1:
    _MOV32 data_start, fat_sector

    ldx read_buffer + BPB_OFFSET + BPB::num_fats ;TODO This could technically be 2 bytes
@fat_loop:
    _ADD32 data_start, read_buffer + BPB_OFFSET + BPB::sectors_per_fat_32, data_start
    dex
    bne @fat_loop

    _MOV32 current_dir, read_buffer + BPB_OFFSET + BPB::current_dir

    rts

fat_ls:
    _MOV32 dir_cxt + FileContext::cluster,current_dir

    lda #<dir_cxt
    ldx #>dir_cxt
    jsr calc_sector

    stx dir_cxt + FileContext::offset

@read_sector:
    lda dir_cxt + FileContext::sector
    sta read_params + 3
    lda dir_cxt + FileContext::sector + 1
    sta read_params + 2
    lda dir_cxt + FileContext::sector + 2
    sta read_params + 1
    lda dir_cxt + FileContext::sector + 3
    sta read_params

    lda #<read_buffer
    sta read_params + 4
    lda #>read_buffer
    sta read_params + 5

    lda #<read_params
    ldx #>read_params

    jsr fat_cache_block

    lda #<read_buffer
    sta read_ptr
    lda #>read_buffer
    sta read_ptr+1

    ; 16 entries per sector
    lda #16
    sta dircount
@dir_loop:
    lda (read_ptr)
    bne @blah
    jmp @done
@blah:
    cmp #$e5
    beq @next_entry
    ldy #dirent::attributes
    lda (read_ptr),Y
    cmp #$0f
    beq @next_entry
    ldy #0
    ldx #8
@copy_name:
    lda (read_ptr),Y
    cmp #$20
    beq @extension
    sta filename_8_3,Y
    iny
    dex
    bne @copy_name
@extension:
    tya
    tax
    ldy #dirent::attributes
    lda (read_ptr),Y
    bit #$10
    bne @null_char
    lda #'.'
    sta filename_8_3,X
    inx
    ldy #dirent::extension
    lda (read_ptr),Y
    sta filename_8_3,X
    iny
    inx
    lda (read_ptr),Y
    sta filename_8_3,X
    iny
    inx
    lda (read_ptr),Y
    sta filename_8_3,X
    inx

@null_char:
    stz filename_8_3,X

    lda #<filename_8_3
    ldy #>filename_8_3
    jsr console_println

@next_entry:
    dec dircount
    bne @advance
    inc dir_cxt + FileContext::sector
    bcc @next_sector
    inc dir_cxt + FileContext::sector + 1
    bcc @next_sector
    inc dir_cxt + FileContext::sector + 2
    bcc @next_sector
    inc dir_cxt + FileContext::sector + 3

@next_sector:
    inc dir_cxt + FileContext::offset
    lda dir_cxt + FileContext::offset
    cmp cluster_size
    beq @next_cluster
    jmp @read_sector
@next_cluster:
    lda #<dir_cxt
    ldx #>dir_cxt
    jsr fat_get

    lda #<dir_cxt
    ldx #>dir_cxt
    jsr calc_sector

    stz dir_cxt + FileContext::offset

    jmp @read_sector

@advance:
    lda read_ptr
    clc
    adc #32
    sta read_ptr
    bcc @back2loop
    inc read_ptr+1
    ;bra @dir_loop
@back2loop:
    jmp @dir_loop

@done:
    rts

fat_open:
    sta param_ptr
    stx param_ptr+1

    _MOV32 dir_cxt + FileContext::cluster, current_dir

    lda #<dir_cxt
    ldx #>dir_cxt
    jsr calc_sector

@read_sector:
    lda dir_cxt + FileContext::sector + 3
    sta read_params
    lda dir_cxt + FileContext::sector + 2
    sta read_params + 1
    lda dir_cxt + FileContext::sector + 1
    sta read_params + 2
    lda dir_cxt + FileContext::sector
    sta read_params + 3

    lda #<read_buffer
    sta read_params + 4
    lda #>read_buffer
    sta read_params + 5
    lda #<read_params
    ldx #>read_params

    jsr fat_cache_block

    lda #<read_buffer
    sta read_ptr
    lda #>read_buffer
    sta read_ptr+1

    ; 16 entries per 512 byte sector
    lda #16
    sta dircount
@dir_loop:
    lda (read_ptr)
    beq @not_found ; Zero first byte means end of directory listing
    cmp #$e5 ; E5 means deleted
    beq @next_entry
    ldy #dirent::attributes
    lda (read_ptr),Y
    cmp #$0f ; $0f means VFAT long filename, which we don't currently support
    beq @next_entry
    bit #$10 ; Can't open a subdirectory
    bne @next_entry
    ldy #0
    ldx #11
@check_name:
    ;TODO Case sensitivity?
    lda (read_ptr),Y
    cmp (param_ptr),Y
    bne @next_entry
    iny
    dex
    bne @check_name
    bra @open

@next_entry:
    dec dircount
    bne @advance
    inc dir_cxt + FileContext::sector
    bne @next_sector
    inc dir_cxt + FileContext::sector + 1
    bne @next_sector
    inc dir_cxt + FileContext::sector + 2
    bne @next_sector
    inc dir_cxt + FileContext::sector + 3

@next_sector:
    inc dir_cxt + FileContext::offset
    lda dir_cxt + FileContext::offset
    cmp cluster_size
    beq @next_cluster
    jmp @read_sector
@next_cluster:
    lda #<dir_cxt
    ldx #>dir_cxt
    jsr fat_get

    lda #<dir_cxt
    ldx #>dir_cxt
    jsr calc_sector

    stz dir_cxt + FileContext::offset

    jmp @read_sector

@advance:
    lda read_ptr
    clc
    adc #32
    sta read_ptr
    bcc @back2loop
    inc read_ptr+1
    ;bra @dir_loop
@back2loop:
    jmp @dir_loop

@not_found:
    lda #$ff
    rts

@open:
    ; Filename match, so note the start cluster
    ldy #dirent::cluster_low
    lda (read_ptr),Y
    sta file_cxt + FileContext::cluster
    iny
    lda (read_ptr),Y
    sta file_cxt + FileContext::cluster + 1

    ldy #dirent::cluster_high
    lda (read_ptr),Y
    sta file_cxt + FileContext::cluster + 2
    iny
    lda (read_ptr),Y
    sta file_cxt + FileContext::cluster + 3

    ldy #dirent::file_size
    lda (read_ptr),Y
    sta filesize
    iny
    lda (read_ptr),Y
    sta filesize+1
    iny
    lda (read_ptr),Y
    sta filesize+2
    iny
    lda (read_ptr),Y
    sta filesize+3

    lda #<file_cxt
    ldx #>file_cxt
    jsr calc_sector

    stz file_cxt + FileContext::offset

    lda flags
    and #(FLAG_EOF ^ $ff)
    sta flags

@done:
    lda #0
    rts

fat_read:
    sta param_ptr
    stx param_ptr+1

    lda flags
    bit #FLAG_EOF
    beq @read_params

    ldy #FATReadParams::bytes_read
    lda #0
    sta (param_ptr),Y
    iny
    sta (param_ptr),Y
    rts

@read_params:
    ldy #0
    lda (param_ptr),Y
    sta read_params+4
    iny
    lda (param_ptr),Y
    sta read_params+5
    iny
    lda (param_ptr),Y
    sta read_params+6
    iny
    lda (param_ptr),Y
    sta read_params+7

    lda #<read_buffer
    sta read_ptr
    lda #>read_buffer
    sta read_ptr+1

    lda file_cxt + FileContext::sector
    sta read_params+3
    lda file_cxt + FileContext::sector+1
    sta read_params+2
    lda file_cxt + FileContext::sector+2
    sta read_params+1
    lda file_cxt + FileContext::sector+3
    sta read_params

    lda filesize+2
    ora filesize+3
    bne @read

    lda filesize+1
    cmp read_params+7
    bpl @read
    bne @use_filesize
    lda filesize
    cmp read_params+6
    bpl @read

@use_filesize:
    lda filesize
    sta read_params+6
    lda filesize+1
    sta read_params+7

@read:
    ldy #FATReadParams::bytes_read
    lda read_params+6
    sta (param_ptr),Y
    iny
    lda read_params+7
    sta (param_ptr),Y

    lda #<read_params
    ldx #>read_params
    jsr sdcard_read_block

    inc file_cxt + FileContext::sector
    bne @subsize
    inc file_cxt + FileContext::sector+1
    bne @subsize
    inc file_cxt + FileContext::sector+2
    bne @subsize
    inc file_cxt + FileContext::sector+3

@subsize:
    sec
    lda filesize
    sbc read_params+6
    sta filesize
    lda filesize + 1
    sbc read_params+7
    sta filesize + 1
    lda filesize + 2
    sbc #0
    sta filesize + 2
    lda filesize + 3
    sbc #0
    sta filesize + 3

    lda filesize
    ora filesize+1
    ora filesize+2
    ora filesize+3
    bne @ret
    lda flags
    ora #FLAG_EOF
    sta flags

@ret:
    inc file_cxt + FileContext::offset
    lda cluster_size
    cmp file_cxt + FileContext::offset
    bne @ret2
    lda #<file_cxt
    ldx #>file_cxt
    jsr fat_get
@ret2:
    lda #0
    rts

fat_get:
    sta temp_ptr
    stx temp_ptr+1

    ldy #FileContext::cluster
    lda (temp_ptr),Y
    sta read_params
    iny
    lda (temp_ptr),Y
    sta read_params+1
    iny
    lda (temp_ptr),Y
    sta read_params+2
    iny
    lda (temp_ptr),Y
    sta read_params+3

    ldx #7
@div128:
    lsr read_params+3
    ror read_params+2
    ror read_params+1
    ror read_params
    dex
    bne @div128

    _ADD32 read_params, fat_sector, read_params

    lda read_params
    ldx read_params+3
    stx read_params
    sta read_params+3
    lda read_params+1
    ldx read_params+2
    stx read_params+1
    sta read_params+2

    lda #<read_buffer
    sta read_params+4
    sta read_ptr
    lda #>read_buffer
    sta read_params+5
    sta read_ptr+1

    lda #<read_params
    ldx #>read_params
    jsr fat_cache_block

    ldy #FileContext::cluster
    lda (temp_ptr),Y
    and #$7f
    sta read_ptr
    stz read_ptr+1

    asl read_ptr
    rol read_ptr+1
    asl read_ptr
    rol read_ptr+1

    clc
    lda read_ptr
    adc #<read_buffer
    sta read_ptr
    lda read_ptr+1
    adc #>read_buffer
    sta read_ptr+1

    ldy #0
    lda (read_ptr),Y
    sta temp
    iny
    lda (read_ptr),Y
    sta temp+1
    iny
    lda (read_ptr),Y
    sta temp+2
    iny
    lda (read_ptr),Y
    sta temp+3

    ldy #FileContext::cluster
    lda temp
    sta (temp_ptr),Y
    iny
    lda temp+1
    sta (temp_ptr),Y
    iny
    lda temp+2
    sta (temp_ptr),Y
    iny
    lda temp+3
    sta (temp_ptr),Y

    lda #$ff
    cmp temp+3
    bne @sector
    cmp temp+2
    bne @sector
    cmp temp+1
    bne @sector
    lda #$f8
    cmp temp
    bpl @ret

    lda flags
    ora #FLAG_EOF
    sta flags

@sector:
    lda #<file_cxt
    ldx #>file_cxt
    jsr calc_sector

@ret:
    rts

calc_sector:
    phy
    sta temp_ptr
    stx temp_ptr+1

    ldy #FileContext::cluster

    lda (temp_ptr),Y
    sta temp
    iny
    lda (temp_ptr),Y
    sta temp+1
    iny
    lda (temp_ptr),y
    sta temp+2
    iny
    lda (temp_ptr),Y
    sta temp+3

    sec
    lda temp
    sbc #2
    sta temp
    bcs @shift_cluster
    dec temp+1
    bcs @shift_cluster
    dec temp+2
    bcs @shift_cluster
    dec temp+3

@shift_cluster:
    ldx cluster_shift
    beq @add_start
@shift_loop:
    asl temp
    rol temp+1
    rol temp+2
    rol temp+3
    dex
    bne @shift_loop

@add_start:
    _ADD32 temp,data_start,temp

    ldy #FileContext::sector
    lda temp
    sta (temp_ptr),Y
    iny
    lda temp+1
    sta (temp_ptr),Y
    iny
    lda temp+2
    sta (temp_ptr),Y
    iny
    lda temp+3
    sta (temp_ptr),Y

    ply
    rts
