.struct CopyParams
    size .word
    src_ptr .word
    dst_ptr .word
.endstruct

.struct SetParans
    size .word
    ptr .word
.endstruct

; Constant which indicates the largest size required to store a parameters structure. This allows
; modules to share a single memory block for all possible contexts if desired.
.define MAX_MEM_PARAMS_SIZE 6

; NOTE! This calls are *NOT* currently interrupt safe. This is a mainly a reminded to my future self, as the system
;       is currently not really doing anything with interrupts.

; Params:
;   A - Low pyte of CopyParams
;   X - High byte of CopyParams
; Return:
;   None
; Preserves:
;   None
.global memcpy


; Set memory to a value
; Params:
;   A - Value to set
;   X - Low byte of CopyParams (dst_ptr is ignored)
;   Y - High byte of CopyParams
; Return:
;   None
; Preserves:
;   None
.global memset
