bootloader_start:

; clear registers
cli
mov ax, 0
mov es, ax
mov ds, ax
mov ss, ax
mov sp, 0x7c00
sti

mov byte[boot_disk], dl

; set video mode
mov ax, 0x03
int 0x10

; load system from the disk
mov cx, 0x0002 ; cylinder 0, sector 2
xor dh, dh     ; head 0
mov al, 0x03   ; load 3 sectors
mov bx, 0x7E00 ; write to RAM from here
mov ah, 0x02   ; read sectors into memory
int 0x13       ; boom!

printc 'Y', 0xF

printc byte[0x7E00], 0xF

jmp kernel_start

boot_disk db 0x80
addr dw 0x7E00

times 510-($-$$) db 0
db 0x55, 0xAA