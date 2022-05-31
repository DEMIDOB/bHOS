.code16
.intel_syntax noprefix
.text
.org 0x0

jmp  bHOS_ssb

.include "vga.asm"

bHOS_ssb:
    xor  ax, ax
    mov  al, 0x03
    int  0x10

    mov  ah, 0xA
    mov  al, 'y'
    xor  bh, bh
    mov  cx, 1
    int  0x10

    lea  si, welcomeMsg
    call WriteString
    call Pause

.fill (1024 - (. - bHOS_ssb)), 1, 0

welcomeMsg: .asciz "Welcome to bHOS's second stage bootloader!"
pauseMsg:   .asciz "Press any key to continue..."
