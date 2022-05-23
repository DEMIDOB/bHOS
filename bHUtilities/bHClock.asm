org 0x7c00 + 0x0800

CLOCK_PROGRAM_SIZE = 1

clockProgramSignature db 0x09, 0x11
db CLOCK_PROGRAM_SIZE
db 0x00
clock_program_name db 'bHClock'
times 32 - ($ - clockProgramSignature) db 0

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
        puts STCurrentTimeString

        ; Wait for input:
        clprinp:
                xor ah, ah
                int 0x16
                cmp al, 27
                je shell
                jmp clockloop

times 512 * SHELL_PROGRAM_SIZE - ($ - shellProgramSignature) db 0