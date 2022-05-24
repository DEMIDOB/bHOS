SHELL_PROGRAM_SIZE = 2

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

info_cmd:
    mov byte[com_ok], 1
    puts InfoRP
    jmp shell_loop

time_cmd:
    call get_time
    puts STCurrentTimeString
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

    ; pointer to programsAmount variable is now stored in si

    mov bx, word[si]
    add bh, 0x30
    mov byte[ProgramsAmountMsgNum], bh
    puts ProgramsAmountMsgStart
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

STCurrentTimeString db "Current time is "
STCurrentTimeStringCont:
times 6 db 0

reserveBuffer:
times 32 db 0

; CMDs:
RebootCMD db 'reboot', 0
ShutdownCMD db 'shutdown', 0
TimeCMD db 'time', 0
ClearsCMD db 'clears', 0
ProglistCMD db 'proglist', 0

DrawCMD db 'draw', 0
ClockCMD db 'clock', 0
KCallCMD db 'kernel', 0

InfoCMD db 'info', 0
InfoRP db 'bHOS by DEM!DOB v0.7', 0

wc db 'Unknown command!', 0

times 512 * SHELL_PROGRAM_SIZE - ($ - shellProgramSignature) db 0