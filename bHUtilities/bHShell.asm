org 0x7c00 + 0x800

SHELL_PROGRAM_SIZE = 3

shellProgramSignature db 0x09, 0x11
db SHELL_PROGRAM_SIZE
db 0x00
bHShell_kernelBufferPointer dw 0x0000
db "bHShell", 0
times 32 - ($ - shellProgramSignature) db 0


bHShell:

include 'kernelCall.asm'

shell:
        mov ax, 0x03
        int 0x10

        set_cur 71, 24
        puts OsTitle
        set_cur 0, 0
        puts HelloMsg
        printc byte[boot_disk], 0xF

shell_loop:
        mov byte[com_ok], 0
        clear_buffer KBBuffer
        call inc_row
        call inc_cursor
        printc '>', 0xF
        call inc_cursor
        call inc_cursor
        inps KBBuffer
        call inc_row
        CheckCommand KBBuffer, RebootCMD, 6, reboot
        CheckCommand KBBuffer, ShutdownCMD, 8, shutdown
        CheckCommand KBBuffer, InfoCMD, 4, info_cmd
        CheckCommand KBBuffer, TimeCMD, 4, time_cmd
        CheckCommand KBBuffer, DrawCMD, 4, draw
        CheckCommand KBBuffer, ClearsCMD, 6, clears_cmd
        CheckCommand KBBuffer, ClockCMD, 5, clock
        CheckCommand KBBuffer, KCallCMD, 6, kernel_cmd
        CheckCommand KBBuffer, ProglistCMD, 8, proglist_cmd
        cmp byte[com_ok], 0
        jne shell_loop
        puts wc
        jmp shell_loop

jmp $

divider:
    push ax
    call inc_row

    mov ax, 80

    divider_loop:
        cmp ax, 0
        je divider_loop_end

        fast_printc '-'

        dec ax
        jmp divider_loop

    divider_loop_end:
        pop ax
        ret

info_cmd:
    mov byte[com_ok], 1
    puts InfoRP
    jmp shell_loop

time_cmd:
    push ax

    kernelCall bHShell_timestrKernelCall, bHShell_kernelBufferPointer
    mov ax, [bHShell_kernelBufferPointer]
    memcpy ax, bHShell_STCurrentTimeStringCont, 5
    puts bHShell_STCurrentTimeString

    pop ax
    jmp shell_loop

clears_cmd:
    mov byte[com_ok], 1
    jmp shell

clock_cmd:
    mov byte[com_ok], 1
    jmp clock

kernel_cmd:
    kernelCall KBBuffer + 7, bHShell_kernelBufferPointer
    puts [bHShell_kernelBufferPointer]
    jmp shell_loop

proglist_cmd:
    kernelCall KBBuffer, bHShell_kernelBufferPointer
    mov si, word[bHShell_kernelBufferPointer]
    mov di, [si]

    ; pointer to programsAmount variable is now stored in di

    mov bx, word[di]
    add bx, 0x30
    mov byte[ProgramsAmountMsgNum], bl
    puts ProgramsAmountMsgStart
    call divider

    sub bx, 0x30
    mov ax, 0 ; counter (al)
    add di, 8

    proglist_cmd_loop:
        cmp bl, 0
        je proglist_cmd_loop_end

        ; loop body

        call inc_row
        fast_printn al
        fast_printc ' '
        fast_printc '|'
        fast_printc ' '
        puts di

        ; loop body end

        dec bl
        inc al
        add di, PROGRAM_REF_SIZE
        ; kernelCall PauseCMD, bHShell_kernelBufferPointer
        jmp proglist_cmd_loop

    proglist_cmd_loop_end:
        call divider
        jmp shell_loop


reboot:
    mov byte[com_ok], 1
    kernelCall KBBuffer, bHShell_kernelBufferPointer

shutdown:
    ; i know that's kinda stupid ahahha
    ret


; System info:
com_ok db 0

; Strings
HelloMsg db "bHOS is successfully loaded from disk ", 0
OsTitle db "bHOS v0.7", 0

ProgramsAmountMsgStart db "Programms installed: "
ProgramsAmountMsgNum db 0, 0

; Buffers:
KBBuffer db 0
times 31 db 0

bHShell_STCurrentTimeString db "Current time is "
bHShell_STCurrentTimeStringCont:
times 6 db 0

reserveBuffer:
times 32 db 0

; CMDs:
RebootCMD db 'reboot', 0
ShutdownCMD db 'shutdown', 0
TimeCMD db 'time', 0
ClearsCMD db 'clears', 0
ProglistCMD db 'proglist', 0
PauseCMD db 'pause', 0

DrawCMD db 'draw', 0
ClockCMD db 'clock', 0
KCallCMD db 'kernel', 0

InfoCMD db 'info', 0
InfoRP db 'bHOS by DEM!DOB v0.7', 0

wc db 'Unknown command!', 0

; Required kernel calls
bHShell_timestrKernelCall db "timestr", 0

times 512 * SHELL_PROGRAM_SIZE - ($ - shellProgramSignature) db 0