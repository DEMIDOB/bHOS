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

        mov cx, [installedProgramsAmount]
        imul cx, PROGRAM_REF_SIZE
        add cx, installedProgramsList

        memcpy reservedSector, cx, 32

        add cx, 3
        mov di, cx
        mov [di], al

        pop bx
        pop cx

        inc [installedProgramsAmount]
        mov dh, byte[scanOffset]
        add dh, byte[reservedSector + 2]
        mov byte[scanOffset], dh

        jmp scan_installed_apps

    start_requested_app:
        cmp [installedProgramsAmount], 0
        je no_apps

        cmp [requested_program], [installedProgramsAmount]
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
        printc ':', 0xA
        call inc_cursor
        printc '(', 0xA
        jmp $


    kernelCallBuffer:
        times 128 db 0

    kernelCall:
        CheckCommand kernelCallBuffer, runKCallCmd, 3, kernelCall_run

    kernelCallReturn:
        pop bx
        jmp bx

    kernelCall_run:
        mov si, kernelCallBuffer
        add si, 4
        mov di, requested_program
        add di, 1
        mov ax, 1
        call  _memcpy
        jmp start_requested_app


requested_program dw 0
current_program dw 0

tmpBuffer db 0
times 127 db 0

; kernel calls' cmds

runKCallCmd db "run"

; data

reservedSector:
times 512 db 0

scanOffset db 0
installedProgramsAmount dw 0
installedProgramsList:

kernel_end:
times 2048-($-$$) db 0
