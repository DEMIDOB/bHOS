org 0x7c00 + 0x0800

DRAW_PROGRAM_SIZE = 1

drawProgramSignature db 0x09, 0x11
db DRAW_PROGRAM_SIZE
drawProgramName db "bHDraw"
times 32 - ($ - drawProgramSignature) db 0

draw:
    mov ax, 0x003
    int 0x10
    
    mov al, 0x13
    mov ah, 0
    int 0x10
        
    set_cur 29, 24
    puts drawProgramName
    
    mov cx, 160
    mov dx, 100
    
    mov bl, 0001b
    
    output:
        cmp cx, 0
        je exit
        cmp dx, 0
        je exit
        jne drawpix
        
        jmp output

    drawpix:
        mov ah, 0x0C
        mov al, bl
        int 0x10
        jmp input
        
    input:      
        mov ah, 0x00
        int 0x16
        cmp al, 27
        je exit
        cmp al, 99
        je draw       
        cmp al, 119
        je moveUp
        cmp al, 97
        je moveLeft
        cmp al, 100
        je moveRight
        cmp al, 115
        je moveDown
        cmp al, 114
        je red
        cmp al, 103
        je green
        cmp al, 98
        je blue
                cmp al, 0x6E
                je null
                cmp al, 8
                je draw
        jne output  
        
    moveUp:
        dec dx
        jmp output 
        
    moveDown:
        inc dx
        jmp output  
        
    moveLeft:
        dec cx
        jmp output
        
    moveRight:
        inc cx
        jmp output  
        
    red:
        mov bl, 0100b
        jmp output
        
    green:
        mov bl, 0010b
        jmp output
        
    blue:
        mov bl, 0001b
        jmp output
        
        null:
                mov bl, 0000b
                jmp output
        
    exit:
        jmp shell

drawProgramEnd:
times 512 * DRAW_PROGRAM_SIZE - (drawProgramEnd - drawProgramSignature) db 0