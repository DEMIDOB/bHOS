org 0x7c00 + 0x800

CLOCK_PROGRAM_SIZE = 1

clockProgramSignature db 0x09, 0x11
db CLOCK_PROGRAM_SIZE
db 0x00
bHClock_kernelBufferPointer dw 0x0000
clock_program_name db 'bHClock', 0
times 32 - ($ - clockProgramSignature) db 0

clock:
    mov ax, 0x003
    int 0x10

clockloop:
    mov al, 0x13
    mov ah, 0
    int 0x10

    set_cur 28, 24
    puts clock_program_name

    set_cur 10, 10
    call get_time
    puts STCurrentTimeString - 0x800

    ; Wait for input:
    clprinp:
        xor ah, ah
        int 0x16
        cmp al, 27
        je bHClock_exit
        jmp clockloop

    bHClock_exit:
        memcpy bHClock_exitKernelCall, [bHClock_kernelBufferPointer], 5
        mov cx, word[bHClock_kernelBufferPointer]
        add cx, 128
        jmp cx

bHClock_exitKernelCall db "run 0"

times 512 * SHELL_PROGRAM_SIZE - ($ - shellProgramSignature) db 0
































































