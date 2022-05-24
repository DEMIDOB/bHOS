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

macro CheckCommandArgs src, com, cmd_len, action, buffer_len {
    push di
    push si
        
    mov di, src
    mov si, com
    mov cx, cmd_len
        
    repe cmpsb
    pop si
    pop di
    je action
}