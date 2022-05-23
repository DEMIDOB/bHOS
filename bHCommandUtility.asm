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