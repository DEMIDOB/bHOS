.code16
.intel_syntax noprefix
.text
.org 0x0

.include "vga.asm"

bHOS_ssb:
    xor  ax, ax
    mov  al, 0x13

    mov  ah, 0xA
    mov  al, 'y'
    xor  bh, bh
    mov  cx, 1
    int  0x10

    lea  si, welcomeMsg
    call WriteString
    call Pause

welcomeMsg: .asciz "Welcome to bHOS's second stage bootloader!"
pauseMsg:   .asciz "Press any key to continue..."

# .fill (1024 - (. - bHOS_ssb)), 1, 0
