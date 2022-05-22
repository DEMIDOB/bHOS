org 0x7c00
use16

cli
mov ax, 0
mov es, ax
mov ds, ax
mov ss, ax
mov sp, 0x7c00
sti

mov byte[boot_disk], dl

mov ax, 0x03
int 0x10

macro putc char, attr {
    mov al, char
    mov bl, attr
    mov bh, 0
    mov cx, 1
    mov ah, 0x09
    int 0x10  
}


mov cx, 0x0002 ; cylinder 0, sector 2
xor dh, dh     ; head 0
mov al, 0x03   ; load 3 sectors
mov bx, 0x200 ; write to RAM from here
mov ah, 0x02   ; read sectors into memory
int 0x13       ; boom!

putc byte[0x7E00], 0xF

jmp shell

boot_disk db 0x80
addr dw 0x7E00

;=============VGA===============
macro set_cur colomn, row {
        mov dh, row
        mov dl, colomn
        mov bh, 0
        mov ah, 2
        int 0x10
}

get_cursor_pos:
    mov bh, 0
    mov ah, 0x03  
    int 0x10
    ret

inc_cursor:
    call get_cursor_pos 
    inc dl
    mov ah, 2
    int 0x10
    ret

dec_cursor:
        call get_cursor_pos
        dec dl
        mov ah, 2
        int 0x10
        ret

inc_row:
        call get_cursor_pos
        inc dh
        xor dl, dl
        mov ah, 2
        int 0x10
        ret

macro putc char, attr {
    mov al, char
    mov bl, attr
    mov bh, 0
    mov cx, 1
    mov ah, 0x09
    int 0x10  
}

sloop:
        putc [si], 0xF
        inc si
        call inc_cursor
        cmp byte[si], 0x0
        jne sloop
        ret

macro puts str_start_ptr {
      mov si, str_start_ptr
      call sloop
}

macro inps buffer {
        push si
        push di
        mov si, buffer
        mov di, 16
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
                putc [si], 0xF
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
                putc 0x0, 0xF
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
;=============VGA END===============

;=============SOME KERNEL STUFF=============
get_time:
        mov ah, 0x02
        int 0x1A
        ret

;=============SOME KERNEL STUFF END=============
times 510-($-$$) db 0
db 0x55, 0xAA

;=============BL END!===============

shell:
                mov ax, 0x03
                int 0x10
        
                set_cur 71, 24
        puts OsTitle
        set_cur 0, 0
        puts HelloMsg
        putc byte[boot_disk], 0xF

rstart:
        mov byte[com_ok], 0
        clear_buffer KBBuffer
        call inc_row
        call inc_cursor
        putc '>', 0xF
        call inc_cursor
        call inc_cursor
        inps KBBuffer
        call inc_row
        CheckCommand KBBuffer, RebootCMD, 6, reboot
        CheckCommand KBBuffer, InfoCMD, 4, info_cmd
        CheckCommand KBBuffer, TimeCMD, 4, time_cmd
        CheckCommand KBBuffer, DrawCMD, 4, draw
        CheckCommand KBBuffer, ClearsCMD, 6, clears_cmd
        CheckCommand KBBuffer, ClockCMD, 5, clock
        cmp byte[com_ok], 0
        jne rstart
        puts wc
        jmp rstart

jmp $

info_cmd:
        mov byte[com_ok], 1
        puts InfoRP
        jmp rstart

time_cmd:
        call get_time
        putc ch, 0xE
        call inc_cursor
        putc cl, 0xE
        jmp rstart

clears_cmd:
        mov byte[com_ok], 1
        jmp shell

clock_cmd:
        mov byte[com_ok], 1
        jmp clock

reboot:
        mov byte[com_ok], 1
        int 0x19

; System info:
com_ok db 0

; Data segment:
HelloMsg db "bHOS is successfully loaded from disk ", 0
OsTitle db "bHOS v0.6", 0

; Buffers:
KBBuffer db 0
times 16 db 0

; CMDs:
RebootCMD db 'reboot', 0
TimeCMD db 'time', 0
ClearsCMD db 'clears', 0

DrawCMD db 'draw', 0
ClockCMD db 'clock', 0

InfoCMD db 'info', 0
InfoRP db 'bHOS by DEM!DOB v0.5', 0

wc db 'Unknown command!', 0




;========DRAW=========

drawProgramName db "bHDraw v0.2", 0

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



;=============CLOCK=============

clock_program_name db 'bHClock v0.1'

clock:

        mov ax, 0x003
        int 0x10

clockloop:
        mov al, 0x13
        mov ah, 0
        int 0x10

        set_cur 28, 24
        puts clock_program_name

        set_cur 10, 10
        call get_time
        putc ch, 0xE
        call inc_cursor
        putc cl, 0xE

        ; Wait for input:
        clprinp:
                xor ah, ah
                int 0x16
                cmp al, 27
                je shell
                jmp clockloop
