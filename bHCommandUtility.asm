macro CheckCommand src, com, len, action {
    ; see comments to the macro below
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

macro CheckCommandArgs src, com, cmd_len, action, buffer_len {
    push di         ; save register's value
    push si         ; save register's value
        
    mov di, src     ; the first  string to compare
    mov si, com     ; the second string to compare
    mov cx, cmd_len ; the number of bytes to compare
        
    repe cmpsb      ; compare cx bytes at di and si

    pop si          ; recover register's value
    pop di          ; recover register's value

    je action
}