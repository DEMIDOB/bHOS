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
        je bfck_start_user_loop

        cmp al, ']'
        je bfck_continue_user_loop

        cmp al, ' '
        je bfck_continue_main_loop

        ; We used to treat everything except for allowed characters
        ; and newline characters as syntax errors, but will ignore them for now...

        jmp bfck_continue_main_loop ; ...and simply continue executing

        ; cmp al, 10
        ; je bfck_continue_main_loop

        ; cmp al, 13
        ; je bfck_continue_main_loop

        ; jmp bfck_syntax_error ; if no match

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

    bfck_start_user_loop:
        push bx                     ; this wil store bfck_nestingDepth
        mov bl, [bfck_nestingDepth] ; will be used for handling closing brackets
        
        ; if we are here, the value in si points to a '['
        ; so we automatically increment nestingDepth
        inc [bfck_nestingDepth]

        ; read the current tape value
        mov dl, byte[di]
        cmp dl, 0
        jne bfck_start_user_loop_break ; if not zero, execute the loop

        ; otherwise find the closing ']'...
        bfck_find_closing_sqbr_loop:
            ; TODO: do not allow si < code start!!!
            inc si
            mov al, byte[si]

            cmp al, ']'
            je .found_closing

            cmp al, '['
            je .found_opening

            jmp bfck_find_closing_sqbr_loop

            .found_closing:                     ; if a ']' is found, we ...
                dec [bfck_nestingDepth]         ; ... decrement the nestingDepth and ...
                cmp bl, [bfck_nestingDepth]     ; ... check if the nestingDepth has the value we started with
                jne bfck_find_closing_sqbr_loop ; continue the iteration if not
                jmp bfck_start_user_loop_break  ; or exit the loop otherwise
                
            .found_opening: ; if a '[' is found, we ...
                inc [bfck_nestingDepth]
                jmp bfck_find_closing_sqbr_loop

        bfck_start_user_loop_break:
            ; ... and continue from there
            pop bx
            jmp bfck_continue_main_loop

    bfck_continue_user_loop:
        push bx                     ; this wil store bfck_nestingDepth
        
                                    ; if we are here, the value in si points to a '[',
        dec [bfck_nestingDepth]     ; so we increment nestingDepth

        mov bl, [bfck_nestingDepth] ; will be used for handling closing brackets
                                    ; IMPORTANT: here, before moving backwards, we FIRST decrement THEN store the value
                                    ; (compared to before moving forward at bfck_start_user_loop)

        ; read the current tape value
        mov dl, byte[di]
        cmp dl, 0
        je bfck_continue_user_loop_break ; reenter the loop iff != 0

        ; otherwise find the opening '['...
        inc [bfck_nestingDepth]
        bfck_find_opening_sqbr_loop:
            ; TODO: do not allow si < code start!!!
            dec si
            mov al, byte[si]

            cmp al, ']'
            je .found_closing

            cmp al, '['
            je .found_opening

            jmp bfck_find_opening_sqbr_loop

            .found_closing:                     ; if a ']' is found, we ...
                inc [bfck_nestingDepth]
                jmp bfck_find_opening_sqbr_loop
                
            .found_opening: ; if a '[' is found, we ...
                dec [bfck_nestingDepth]           ; ... decrement the nestingDepth and ...
                cmp bl, [bfck_nestingDepth]       ; ... check if the nestingDepth has the value we started with
                jne bfck_find_opening_sqbr_loop   ; continue the iteration if not
                inc [bfck_nestingDepth]
                jmp bfck_continue_user_loop_break ; or exit the loop otherwise

        bfck_continue_user_loop_break:
            ; ... and continue from there
            pop bx
            jmp bfck_continue_main_loop

    bfck_continue_main_loop:
        inc si
        jmp bfck_main_loop ; if not the end of string, continue

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

; we need to control nested brackets like [[.]]
; so here, we store the nesting depth
bfck_nestingDepth db 0