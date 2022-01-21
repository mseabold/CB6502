.struct FATReadParams
    buffer .addr
    buffer_size .word
    bytes_read .word
.endstruct

.global fat_init
.global fat_ls
.global fat_open
.global fat_read
