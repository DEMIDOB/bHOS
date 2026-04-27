org 0x7c00
use16

jmp bootloader_start

bootsector:
    iOEML         db "bHOS_32 "
    iSectSize     dw  0x200
    iClustSize    db  4             ; sectors per cluster (4 for ~32MB FAT16)
    iResSect      dw  0x30          ; #of reserved sectors
    iFatCnt       db  2             ; #of FAT copies
    iRootSize     dw  512           ; size of root directory (512 entries)
    iTotalSect    dw  0             ; total # of sectors (0 for >32MB, use iSect32)
    iMedia        db  0xF8          ; media Descriptor (0xF8 for hard disk/USB)
    iFatSize      dw  64            ; size of each FAT (64 sectors for ~32MB)
    iTrackSect    dw  63            ; sectors per track (63 for USB)
    iHeadCnt      dw  255           ; number of read-write heads (255 for USB)
    iHiddenSect   dd  0             ; number of hidden sectors
    iSect32       dd  65536         ; # sectors for over 32 MB (65536 = 32MB)
    iBootDrive    db  0             ; holds drive that the boot sector came from
    iReserved     db  0             ; reserved, empty
    iBootSign     db  0x29          ; extended boot sector signature
    iVolID        db  "seri"        ; disk serial
    acVolumeLabel db  "bHVolume   " ; volume label
    acFSType      db  "FAT16   "    ; file system type

; AD ED C4 E4 FA C4 E4 C6

include 'vga.asm'
include 'bootloader.asm'

; primary_fat:
; times 0x2000 db 0

; backup_fat:
; times 0x2000 db 0

os_start:
include 'bHKernel.asm'

program_start:

include 'bHUtilities/bHShell.asm'
include 'bHUtilities/bHDraw.asm'
include 'bHUtilities/bHClock.asm'

times (0x6000)-($-$$) db 0

primary_fat:
times 0x8000 db 0

backup_fat:
times 0x8000 db 0
