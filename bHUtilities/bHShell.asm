org 0x7c00 + 0x0800

SHELL_PROGRAM_SIZE = 2

shellProgramSignature db 0x09, 0x11
db SHELL_PROGRAM_SIZE
db 0x00
db "bHShell", 0
times 32 - ($ - shellProgramSignature) db 0


bHShell:
macro CheckCommand src, com, len, action {
    push di
    push si
        
    mov di, src
    mov si, com
    mov cx, len
        
    repe cmpsb
    pop si
    pop di
    je action
}

shell:
        mov ax, 0x03
        int 0x10

        set_cur 71, 24
        printc 'p', 0xE
        jmp $
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

reboot:
    mov byte[com_ok], 1
    int 0x19

shutdown:
    ; i know that's kinda stupid ahahha
    jmp $


; System info:
com_ok db 0

; Strings
HelloMsg db "bHOS is successfully loaded from disk ", 0
OsTitle db "bHOS v0.7", 0

; Buffers:
KBBuffer db 0
times 16 db 0
STCurrentTimeString db "Current time is "
STHoursBuffer db 0, 0
db ":"
STMinutesBuffer db 0, 0
db 0

; CMDs:
RebootCMD db 'reboot', 0
ShutdownCMD db 'shutdown', 0
TimeCMD db 'time', 0
ClearsCMD db 'clears', 0

DrawCMD db 'draw', 0
ClockCMD db 'clock', 0

InfoCMD db 'info', 0
InfoRP db 'bHOS by DEM!DOB v0.7', 0

wc db 'Unknown command!', 0

times 512 * SHELL_PROGRAM_SIZE - ($ - shellProgramSignature) db 0