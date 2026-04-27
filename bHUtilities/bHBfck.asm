org 0x7c00 + 512 * (KERNEL_SIZE_SECT + 1)

BFCK_PROGRAM_SIZE = 6

bfckProgramSignature db 0x09, 0x11
db BFCK_PROGRAM_SIZE
db 0
bHBfck_kernelBufferPointer dw 0x0000
bfck_program_name db 'bHBfck v0.1', 0
times 32 - ($ - bfckProgramSignature) db 0

jmp bHBfck_start

include 'kernelCall.asm'
; include 'bHBfckEp.asm'

bHBfck_start:
    push si
    push ax

    mov si, [bHBfck_kernelBufferPointer]
    add si, 6
    mov al, byte[si]
    cmp al, 0
    
    pop ax
    pop si

    je bHBfck_showtime

    jmp bHBfck_fromKernelBufferPointer

bHBfck_showtime:
    bfck_run test_program, bHBfck_tape
    jmp bHBfck_exit

bHBfck_fromKernelBufferPointer:
    push si

    mov si, [bHBfck_kernelBufferPointer]
    add si, 6
    
    bfck_run si, bHBfck_tape
    
    pop si

    jmp bHBfck_exit

bHBfck_exit:
    call inc_row

    ; pause and return to the kernel
    kernelCall bHBfck_pauseKernelCall, bHBfck_kernelBufferPointer
    kernelCall bHBfck_exitKernelCall, bHBfck_kernelBufferPointer

; test_program db ">+++++++++[<++++++++>-]<.>+++++[<++++++>-]<-.+++++++..+++.>++++++++[<---------->-]<+.>+++++++[<++++++++>-]<-.>++++++[<++++>-]<.+++.------.--------.>+++++++++++[<------>-]<-.>++++[<------>-]<+.[-]>[><-]><+++++++++[<+++++++++++>-]<-.++++++++++.>++++[<+++>-]<+.>++++++[<---->-]<.>++++++++[<----------->-]<+.[-]", 0
test_program db ">>+++++++++[<++++++++>-]<.>+++++[<++++++>-]<-.+++++++..+++.>++++++++[<---------->-]<+.>+++++++[<++++++++>-]<-.>++++++[<++++>-]<.+++.------.--------.>+++++++++++[<------>-]<-.-.>+++++++[<++++++++>-]<-.>+++[<+++++>-]<-.+++++++.---------.>++++[<+++>-]<.--.--------.>+++++++[<---------->-]<+.>++++++++++++[<+++++++>-]<.-----.>++++++++[<---------->-]<+.>+++++++++++[<++++++>-]<.>++++[<++++>-]<.>++++[<---->-]<-.++++++++.+++++.--------.>+++++[<+++>-]<.>++++++[<--->-]<.++++++++.>+++++++++[<-------->-]<--.>++++[<------>-]<+.[-]>+++++++[<++++++++++>-]<-.>++++++[<+++++++>-]<-.++++++.>+++++[<--->-]<.>++++[<+++>-]<+.>+++++++++[<--------->-]<-.>+++++++[<++++++++++++>-]<-.----.--.--------.>+++++[<+++>-]<.>++++[<--->-]<.+.+++++.-------.>+++++++++[<----->-]<.[-]<,>++++++++++.[-]>+++++++++[<++++++++++>-]<-.>+++++++[<+++>-]<+.++++++.>++++++++++++[<------->-]<-.>+++++++[<++++++++++>-]<-.+++++++++.++++++.>+++++[<--->-]<.>++++[<+++>-]<+.>++++[<--->-]<-.-.>+++++++[<------>-]<.[-]<.", 0
bHSyntaxErrorMessage db "Syntax error at ", 0

bHBfck_tape:
    times 1024 db 0

bHBfck_pauseKernelCall db "pause", 0
bHBfck_exitKernelCall db "run 0", 0

times 512 * BFCK_PROGRAM_SIZE - ($ - bfckProgramSignature) db 0




