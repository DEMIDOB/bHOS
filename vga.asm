macro set_cur colomn, row {
    push ax
    push bx
    push dx

    mov dh, row
    mov dl, colomn
    mov bh, 0
    mov ah, 2
    int 0x10

    pop dx
    pop bx
    pop ax
}

get_cursor_pos:
    mov bh, 0
    mov ah, 0x03  
    int 0x10

    ret

inc_cursor:
    push ax
    push bx
    push cx
    push dx

    call get_cursor_pos 
    inc dl
    mov ah, 2
    int 0x10

    pop dx
    pop cx
    pop bx
    pop ax

    ret

dec_cursor:
    push ax
    push bx
    push cx
    push dx

    call get_cursor_pos
    dec dl
    mov ah, 2
    int 0x10
    
    pop dx
    pop cx
    pop bx
    pop ax

    ret

inc_row:
    push ax
    push bx
    push cx
    push dx

    call get_cursor_pos
    inc dh
    xor dl, dl
    mov ah, 2
    int 0x10
    
    cmp dh, 24
    jb inc_row_ret

    ; scroll then
    mov al, 1
    xor cx, cx
    mov ch, 2
    mov dh, 23
    mov dl, 79
    mov ah, 0x06
    int 0x10

    call dec_row

    inc_row_ret:

    pop dx
    pop cx
    pop bx
    pop ax

    ret

dec_row:
    call get_cursor_pos
    dec dh
    xor dl, dl
    mov ah, 2
    int 0x10

    ret


macro printc char, attr {
    push ax
    push bx
    push cx

    mov al, char
    mov bl, attr
    mov bh, 0
    mov cx, 1
    mov ah, 0x09
    int 0x10  

    pop cx
    pop bx
    pop ax
}

macro fast_printc char {
    printc char, 0xF
    call inc_cursor
}

macro fast_printn num {
    push dx
    mov dl, num
    add dl, 0x30
    printc dl, 0xF
    pop dx
    call inc_cursor
}

macro printhexword hex_word {
    push ax
    mov ax, hex_word
    call printhexword_from_ax
    pop ax
}

macro le_printhexword hex_word {
    push ax
    mov ax, hex_word
    xchg ah, al
    call printhexword_from_ax
    pop ax
}

printhexword_from_ax:
    push dx
    push si

    fast_printc '0'
    fast_printc 'x'

    mov dx, ax
    and dx, 0xF000
    shr dx, 12
    mov si, hex_to_char
    add si, dx
    fast_printc [si]

    mov dx, ax
    and dx, 0x0F00
    shr dx, 8
    mov si, hex_to_char
    add si, dx
    fast_printc [si]

    mov dx, ax
    and dx, 0x00F0
    shr dx, 4
    mov si, hex_to_char
    add si, dx
    fast_printc [si]

    mov dx, ax
    and dx, 0x000F
    mov si, hex_to_char
    add si, dx
    fast_printc [si]

    pop si
    pop dx

    ret

sloop:
    printc [si], 0xF
    inc si
    call inc_cursor
    cmp byte[si], 0x0
    jne sloop
    ret

macro puts str_start_ptr {
    push si
    mov si, str_start_ptr
    call sloop
    pop si
}

; prints:
;     ; prints the string at the address which is on top of the stack

;     prints_buffer dw 0
;     prints_return_address dw 0
;     mov [prints_buffer], si ; save the value of si

;     pop si
;     mov [prints_return_address], si
    
;     pop si     ; get the pointer
;     call sloop ; sloop expects the pointer to be in si

;     mov si, [prints_buffer] ; restore the value of si

;     jmp [prints_return_address]

macro inps buffer {
    push si
    push di
    mov si, buffer
    mov di, 32
    mov bp, di
    sread:
        xor ah, ah
        int 0x16
        
        ; Check if enter:
        cmp al, 0xD
        je ereed
        
        ; Check if backspace:
        cmp al, 8
        je backspace
        
        ; Check if the buffer is full
        cmp di, 0
        je ereed
        
        mov [si], al
        printc [si], 0xF
        call inc_cursor
        inc si
        dec di
        jmp sread
    
    backspace:
        cmp bp, di
        je sread
        
        call dec_cursor
        dec si
        inc di
        printc 0x0, 0xF
        mov byte[si], 0
        jmp sread
        
    ereed:
    pop di
    pop si
}

macro clear_buffer buffer {
    push si
    push di
    
    mov si, buffer
    mov di, 16
    
    sbl:
        cmp di, 0
        je ebl
        
        mov byte[si], 0
        inc si
        dec di
        jmp sbl
        
    ebl:
    
    pop di
    pop si
}

hex_to_char db '0123456789ABCDEF'