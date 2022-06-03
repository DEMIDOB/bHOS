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

    mov  si, 0x9064
    mov  ah, 0xA
    mov  al, byte ptr [si]
    xor  bh, bh
    mov  cx, 1
    int  0x10

    mov  si, 0
    call WriteString
    call Pause
    int  0x19

welcomeMsg: .asciz "Welcome to bHOS's second stage bootloader!"
pauseMsg:   .asciz "Press any key to continue..."
