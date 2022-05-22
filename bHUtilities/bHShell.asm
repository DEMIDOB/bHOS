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

macro int_to_char2 num, buffer {
    mov [buffer], 0
    mov [buffer + 1], 0

    push dx
    push cx
    push bx
    push ax

    mov bl, num

    xor ax, ax
    xor dx, dx
    xor cx, cx

    mov al, bl
    mov cx, 0x10
    div cx
    mov [buffer], al
    mov [buffer + 1], dl
    
    add [buffer], 0x30
    add [buffer + 1], 0x30

    pop ax
    pop bx
    pop cx
    pop dx
}

;=============SOME KERNEL STUFF=============
get_time:
    push cx
    push dx

    mov ah, 0x02
    int 0x1A

    ; ch - hour
    ; cl - minute
    ; dh - second
    ; dl - tmp

    int_to_char2 ch, STHoursBuffer
    int_to_char2 cl, STMinutesBuffer
    
    pop dx
    pop cx

    ret

;=============SOME KERNEL STUFF END=============

os_start:
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