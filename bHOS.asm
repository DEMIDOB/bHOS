org 0x7c00
use16

jmp bootloader_start

include 'vga.asm'
include 'bootloader.asm'

include 'bHUtilities/bHShell.asm'

; System info:
com_ok db 0

; Strings
HelloMsg db "bHOS is successfully loaded from disk ", 0
OsTitle db "bHOS v0.7", 0

; Buffers:
KBBuffer db 0
times 16 db 0
STCurrentTimeString db "Current time is "
STHoursBuffer db 0, 0
db ":"
STMinutesBuffer db 0, 0
db 0

; CMDs:
RebootCMD db 'reboot', 0
ShutdownCMD db 'shutdown', 0
TimeCMD db 'time', 0
ClearsCMD db 'clears', 0

DrawCMD db 'draw', 0
ClockCMD db 'clock', 0

InfoCMD db 'info', 0
InfoRP db 'bHOS by DEM!DOB v0.7', 0

wc db 'Unknown command!', 0


include 'bHUtilities/bHDraw.asm'
include 'bHUtilities/bHClock.asm'