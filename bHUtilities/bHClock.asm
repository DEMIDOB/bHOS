org 0x7c00 + 0x800

CLOCK_PROGRAM_SIZE = 1

clockProgramSignature db 0x09, 0x11
db CLOCK_PROGRAM_SIZE
db 0x00
bHClock_kernelBufferPointer dw 0x0000
clock_program_name db 'bHClock v0.1', 0
times 32 - ($ - clockProgramSignature) db 0

clock:
    include 'kernelCall.asm'

    mov al, 0x13
    mov ah, 0
    int 0x10

    set_cur 28, 24
    puts clock_program_name

clockloop:
    set_cur 10, 10

    push ax
    kernelCall bHClock_timestrKernelCall, bHClock_kernelBufferPointer
    mov ax, [bHClock_kernelBufferPointer]
    memcpy ax, bHClock_STCurrentTimeStringCont, 5
    puts bHClock_STCurrentTimeString
    pop ax

    ; Wait for input:
    clprinp:
        xor ax, ax
        mov ah, 1
        int 0x16
        cmp al, 27
        je bHClock_exit
        jmp clockloop

    bHClock_exit:
        xor ax, ax
        int 0x16
        printc al, 0xB
        kernelCall bHClock_exitKernelCall, bHClock_kernelBufferPointer

bHClock_timestrKernelCall db "timestr"
bHClock_STCurrentTimeString db "Current time is "
bHClock_STCurrentTimeStringCont:
times 6 db 0

bHClock_exitKernelCall db "run 0"

times 512 * SHELL_PROGRAM_SIZE - ($ - shellProgramSignature) db 0
































































