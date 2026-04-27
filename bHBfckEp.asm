macro bfck_run code_ptr, tape_ptr {
    push si
    push di

    mov si, code_ptr
    mov di, tape_ptr
    
    call bfck_ep

    pop di
    pop si
}

bfck_ep:
    push ax ; al is to store the current instruction
    push bx
    push cx
    push dx
    ; assuming di stores tape (memory) pointer
    ; assuming si stores the brainfuck instruction pointer

    bfck_main_loop:
        mov al, [si]          ; load the current instruction
        ; fast_printc al
        ; call inc_row

        cmp al, 0
        je bfck_main_loop_exit

        cmp al, '>'
        je bfck_inc_dp

        cmp al, '<'
        je bfck_dec_dp

        cmp al, '+'
        je bfck_inc_tape_at_dp

        cmp al, '-'
        je bfck_dec_tape_at_dp

        cmp al, '.'
        je bfck_out_tape_at_dp

        cmp al, ','
        je bfck_in_tape_at_dp

        cmp al, '['
        je bfck_continue_main_loop

        cmp al, ']'
        je bfck_continue_user_loop

        jmp bfck_syntax_error ; if no match

    bfck_inc_dp:
        inc di
        jmp bfck_continue_main_loop

    bfck_dec_dp:
        ; TODO: do not allow di < tape!!!
        dec di
        jmp bfck_continue_main_loop

    bfck_inc_tape_at_dp:
        inc byte[di]
        jmp bfck_continue_main_loop

    bfck_dec_tape_at_dp:
        dec byte[di]
        jmp bfck_continue_main_loop
        
    bfck_out_tape_at_dp:
        mov dl, byte[di]
        cmp dl, 10                   ; check if is is a new line character
        je bfck_out_new_line
        cmp dl, 13                   ; check if is is a new line character
        je bfck_out_new_line

        fast_printc dl
        jmp bfck_continue_main_loop

    bfck_out_new_line:
        call inc_row
        jmp bfck_continue_main_loop

    bfck_in_tape_at_dp:
        push ax

        xor ax, ax
        int 0x16                     ; read a keystroke to al
        mov [di], al

        pop ax
        jmp bfck_continue_main_loop

    bfck_continue_user_loop:
        ; read the current tape value
        mov dl, byte[di]
        cmp dl, 0
        je bfck_continue_main_loop ; continue normally if 0

        ; otherwise find the opening '['...
        bfck_find_opening_sqbr_loop:
            ; TODO: do not allow si < code start!!!
            dec si
            mov al, byte[si]
            cmp al, '['
            jne bfck_find_opening_sqbr_loop

        ; ... and continue from there
        jmp bfck_continue_main_loop

    bfck_continue_main_loop:
        cmp al, 0
        inc si
        jne bfck_main_loop ; if not the end of string, continue

    bfck_syntax_error:
        mov cx, si
        call inc_row
        puts bHSyntaxErrorMessage
        fast_printn cl
        call inc_row
        fast_printc [si]
        call inc_row

        jmp bfck_main_loop_exit

    bfck_main_loop_exit:

    pop dx
    pop cx
    pop bx
    pop ax
    
    ret