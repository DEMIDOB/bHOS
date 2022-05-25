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

    set_cur 80 + OsTitle - OsTitleEnd, 24
    puts OsTitle
    set_cur 0, 0
    puts HelloMsg
    call divider

    jmp shell_loop

display_time:
    push bx
    push si

    kernelCall bHShell_timestrKernelCall, bHShell_kernelBufferPointer
    mov ax, [bHShell_kernelBufferPointer]
    
    mov si, ax
    add si, 4
    mov bl, byte[si]
    mov bh, byte[bHShell_STCurrentTimeStringCont + 4]
    cmp bl, bh
    je display_time_ret

    memcpy ax, bHShell_STCurrentTimeStringCont, 5
    call get_cursor_pos
    mov word[cursorPos], dx
    set_cur 75, 0
    puts bHShell_STCurrentTimeStringCont

    mov dx, word[cursorPos]
    mov bh, 0
    mov ah, 2
    int 0x10

display_time_ret:
    pop si
    pop bx
    ret

shell_loop:
    mov byte[com_ok], 0
    clear_buffer KBBuffer
    call inc_row
    call inc_cursor
    printc '>', 0xF
    call inc_cursor
    call inc_cursor

    mov si, KBBuffer
    mov di, 0x20 ; KBBuffer length
    mov bp, di

    shell_wait_for_input_loop:
        call display_time

        cmp di, 0
        je shell_wait_for_input_loop_end

        mov ax, 0x0100
        int 0x16

        jz shell_wait_for_input_loop

        xor ax, ax
        int 0x16

        ; ENTER
        cmp al, 0xD
        je shell_wait_for_input_loop_end

        ; BACKSPACE
        cmp al, 8
        je backspace

        ; just regular symbol, then...
        fast_printc al
        mov byte[si], al
        inc si
        dec di
        jmp shell_wait_for_input_loop

        backspace:
            cmp bp, di
            je shell_wait_for_input_loop
        
            call dec_cursor
            dec si
            inc di
            printc 0x0, 0xF
            mov byte[si], 0
            jmp shell_wait_for_input_loop

    shell_wait_for_input_loop_end:

    call inc_row
    
    ; ==========  parse command ==========
    CheckCommand KBBuffer, RebootCMD, 6, reboot
    CheckCommand KBBuffer, ShutdownCMD, 8, shutdown
    CheckCommand KBBuffer, InfoCMD, 4, info_cmd
    CheckCommand KBBuffer, TimeCMD, 4, time_cmd
    CheckCommand KBBuffer, DrawCMD, 4, draw
    CheckCommand KBBuffer, ClearsCMD, 6, clears_cmd
    CheckCommand KBBuffer, ClockCMD, 5, clock
    CheckCommand KBBuffer, KCallCMD, 6, kernel_cmd
    CheckCommand KBBuffer, ProglistCMD, 8, proglist_cmd
    ; ========  parse command_end ======== 

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
    puts OsTitle
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

    call inc_row
    mov bx, word[di]
    add bx, 0x30
    mov byte[ProgramsAmountMsgNum], bl
    puts ProgramsAmountMsgStart
    call inc_row

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
        call inc_row
        jmp shell_loop


reboot:
    mov byte[com_ok], 1
    kernelCall KBBuffer, bHShell_kernelBufferPointer

shutdown:
    fast_printc ')'
    MOV     AX,5301
    XOR     BX,BX
    INT     15

    ;Try to set APM version (to 1.2)
    MOV     AX,530E
    XOR     BX,BX
    MOV     CX,0102
    INT     15

    ;Turn off the system
    MOV     AX,5307
    MOV     BX,0001
    MOV     CX,0003
    INT     15

    ;Exit (for good measure and in case of failure)
    RET
    ret


; System info:
com_ok db 0

; Strings
HelloMsg db "Hello, it's bHOS", 0
OsTitle db "bHOS v0.8-dev"
OsTitleEnd db 0

ProgramsAmountMsgStart db "Programs installed: "
ProgramsAmountMsgNum db 0, 0

; Buffers:
KBBuffer db 0
times 31 db 0

bHShell_STCurrentTimeString db "Current time is "
bHShell_STCurrentTimeStringCont:
times 6 db 0

reserveBuffer:
times 32 db 0

cursorPos:
cursorRow db 0
cursorCol db 0

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
