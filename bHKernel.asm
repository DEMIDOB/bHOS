include 'bHMemory.asm'
include 'bHCommandUtility.asm'

PROGRAM_REF_SIZE = 32

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

; ============== kernel functions ==============

k_get_installed_programs_amount:
    printc '!', 0xF
    jmp $

; ============ kernel functions end ============


kernel_start:
    printc 'j', 0xA

    scan_installed_apps:
    
        mov ch, 0x00 ; cylinder 0
        mov cl, 0x05 ; sector 5 (initially)
        add cl, [scanOffset]
        xor dh, dh     ; head 0
        mov al, 0x01   ; load sectors
        mov bx, reservedSector ; write to RAM from here
        mov ah, 0x02   ; read sectors into memory
        int 0x13       ; boom!

        ; === check for bHProgram signature ===
        cmp byte[reservedSector], 0x09
        jne start_requested_app

        cmp byte[reservedSector + 1], 0x11
        jne start_requested_app        
        ; === check for bHProgram signature ===

        mov al, cl

        push bx
        push cx

        mov cx, word[installedProgramsAmount]
        imul cx, PROGRAM_REF_SIZE
        add cx, installedProgramsList

        memcpy reservedSector, cx, 32

        add cx, 3
        mov di, cx
        mov [di], al

        mov cx, word[installedProgramsAmount]
        inc cx
        mov word[installedProgramsAmount], cx

        pop bx
        pop cx

        mov dh, byte[scanOffset]
        add dh, byte[reservedSector + 2]
        mov byte[scanOffset], dh

        jmp scan_installed_apps

    start_requested_app:
        cmp word[installedProgramsAmount], 0
        je no_apps

        mov di, word[requested_program]
        cmp di, word[installedProgramsAmount]
        jae no_apps

        call unload_current_program

        puts installedProgramsList
        call inc_row

        xor di, di

        ; get requested program size (in sectors)
        mov di, word[requested_program]
        imul di, PROGRAM_REF_SIZE
        add di, 2
        add di, installedProgramsList
        mov al, byte[di]

        ; calculate its position on disk
        inc di
        mov cl, byte[di]

        mov ch, 0x00 ; cylinder 0
        xor dh, dh     ; head 0
        mov bx, program_start ; write to RAM from here
        mov ah, 0x02   ; read sectors into memory
        int 0x13       ; boom!

        memcpy requested_program, current_program, 2
        mov ax, kernelCallBuffer
        mov [program_start + 4], ax

        call clear_kernelCallBuffer
    
        ; mov word[current_program], word[requested_program]
        jmp program_start + 32

        cmp byte[kernelCallBuffer], 0
        je no_apps

        jmp kernelCall

    unload_current_program:
        ; get programs's size
        mov ax, 0
        mov bx, ax
        mov al, byte[program_start]
        imul ax, 512

        ; call memset (si: start, ax: lenght, bl: byte to write)
        push bx
        push ax
        push program_start
        call memset

        ret

    no_apps:
        printc ':', 0xB
        call inc_cursor
        printc '(', 0xB
        call inc_row
        call kernelCall_pause
        call kernelCall_reboot

    clear_kernelCallBuffer:
        push 0
        push 128
        push kernelCallBuffer
        call memset
        ret

    kernelCallBuffer:
        times 128 db 0

    kernelCall:
        CheckCommand kernelCallBuffer, runKCallCmd, 3, kernelCall_run
        CheckCommand kernelCallBuffer, pauseKCallCmd, 5, kernelCall_pause
        CheckCommand kernelCallBuffer, rebootKCallCmd, 6, kernelCall_reboot
        CheckCommand kernelCallBuffer, timestrKCallCmd, 7, kernelCall_timestr
        CheckCommand kernelCallBuffer, proglistKCallCmd, 8, kernelCall_proglist

    kernelCallReturn:
        pop bx
        jmp bx

    kernelCall_run:
        puts kernelCallBuffer
        call inc_row
        mov si, kernelCallBuffer
        add si, 4
        mov di, requested_program
        mov ax, 1
        call  _memcpy
        sub word[requested_program], 0x30
        jmp start_requested_app

    kernelCall_pause:
        puts pauseKCallCmd
        xor ah, ah
        int 0x16
        call clear_kernelCallBuffer
        ret

    kernelCall_timestr:
        call get_time
        call clear_kernelCallBuffer
        memcpy STHoursBuffer, kernelCallBuffer, 6
        ret

    kernelCall_proglist:
        call clear_kernelCallBuffer
        push ax
        mov ax, installedProgramsAmount
        mov word[kernelCallBuffer], ax
        pop ax
        ret

    kernelCall_reboot:
        int 0x19


requested_program dw 0
current_program dw 0

tmpBuffer db 0
times 127 db 0

; kernel calls' cmds

runKCallCmd db "run", 0
pauseKCallCmd db "pause", 0
timestrKCallCmd db "timestr", 0
proglistKCallCmd db "proglist", 0
rebootKCallCmd db "reboot", 0

; data

STHoursBuffer db 0, 0
db ":"
STMinutesBuffer db 0, 0
db 0

reservedSector:
times 512 db 0

scanOffset db 0
installedProgramsAmount dw 0
installedProgramsList:

kernel_end:
times 2048-($-$$) db 0
