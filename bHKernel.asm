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

        push dx
        push si

        ; it's 3am im tired sorry for not using kinda loop...

        mov dx, word[reservedSector]
        mov si, [installedProgramsAmount]
        imul si, PROGRAM_REF_SIZE
        add si, installedProgramsList
        mov [si], dx

        mov dx, word[reservedSector + 2]
        add si, 2
        mov [si], dx

        mov dx, word[reservedSector + 4]
        add si, 2
        mov [si], dx

        mov dx, word[reservedSector + 6]
        add si, 2
        mov [si], dx

        mov dx, word[reservedSector + 8]
        add si, 2
        mov [si], dx

        mov dx, word[reservedSector + 10]
        add si, 2
        mov [si], dx

        mov dx, word[reservedSector + 12]
        add si, 2
        mov [si], dx

        mov dx, word[reservedSector + 14]
        add si, 2
        mov [si], dx

        pop si
        pop dx

        inc [installedProgramsAmount]
        mov dh, byte[scanOffset]
        add dh, byte[reservedSector + 2]
        mov byte[scanOffset], dh

        printc [scanOffset], 0xB

        jmp scan_installed_apps

    start_requested_app:
        cmp [installedProgramsAmount], 0
        je no_apps

        add [installedProgramsAmount], 0x30
        printc byte[installedProgramsAmount], 0xB
        call inc_row
        puts installedProgramsList
        jmp $
    
        ; mov word[current_program], word[requested_program]
        jmp word[current_program]

    no_apps:
        printc ':', 0xA
        call inc_cursor
        printc '(', 0xA
        jmp $


requested_program dw bHShell
current_program dw bHShell

; data

reservedSector:
times 512 db 0

scanOffset db 0
installedProgramsAmount dw 0
installedProgramsList:


kernel_end:
times 2048-($-$$) db 0
