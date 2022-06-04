.func WriteString
    WriteString:
        pusha
    WriteString_loop:
        lodsb
        or  al, al
        jz  WriteString_end

        mov ah, 0xE
        xor bh, bh
        mov bl, 0xF
        int 0x10

        jmp WriteString_loop

    WriteString_end:
        popa
        retw
.endfunc 


.func WriteChar
    WriteChar:
        push ax
        push bx
        
        mov  ah, 0xE
        xor  bh, bh
        mov  bl, 0xF
        int 0x10

        pop  bx
        pop  ax
        
        retw
.endfunc


.func IncRow
    IncRow:
        pusha
        
        mov bh, 0
        mov ah, 0x03
        int 0x10

        inc dh
        xor dl, dl
        mov ah, 0x02
        int 0x10

        popa

        retw
.endfunc


.func Pause
    Pause:
        pusha
        call  IncRow
        lea   si, pauseMsg
        call  WriteString
        xor   ax, ax
        int   0x16
        popa
        ret
.endfunc



.func WriteNum
    WriteNum:
        cmp al, 0xA
        jb  WriteNumOut
        
        add al, 7

    WriteNumOut:
        add al, 0x30
        mov ah, 0xE
        int 0x10
        ret
.endfunc


