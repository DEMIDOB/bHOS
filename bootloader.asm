.code16
.intel_syntax noprefix
.text
.org 0x0

LOAD_SEGMENT = 0x9000
FAT_SEGMENT  = 0x8200 # just randomly chosen (yep i stole that from a tutorial)

.global main

main:
    jmp start

bootsector:
    iOEML:         .ascii "bHOS_32 "
    iSectSize:     .word  0x200
    iClustSize:    .byte  1             # sectors per cluster
    iResSect:      .word  3             # #of reserved sectors
    iFatCnt:       .byte  2             # #of FAT copies
    iRootSize:     .word  224           # size of root directory
    iTotalSect:    .word  2880          # total # of sectors if over 32 MB
    iMedia:        .byte  0xF0          # media Descriptor
    iFatSize:      .word  18            # size of each FAT
    iTrackSect:    .word  18            # sectors per track
    iHeadCnt:      .word  2             # number of read-write heads
    iHiddenSect:   .int   0             # number of hidden sectors
    iSect32:       .int   0             # # sectors for over 32 MB
    iBootDrive:    .byte  0             # holds drive that the boot sector came from
    iReserved:     .byte  0             # reserved, empty
    iBootSign:     .byte  0x29          # extended boot sector signature
    iVolID:        .ascii "seri"        # disk serial
    acVolumeLabel: .ascii "BHVOLUME   " # volume label
    acFSType:      .ascii "FAT16   "    # file system type


.include "vga.asm"


.func Reboot
    Reboot:
        lea  si, rebootMsg
        call WriteString
        xor  ax, ax
        int  0x16

        int 0x19
.endfunc


.func ReadSector # (dw sector, dw dest) mind the es!
    ReadSector:
        pop  cx
        pop  ax             # LBA sector number
        pop  bx             # destination
        push cx

        cmp  byte ptr lba_conversion_enabled, 1
        je   convert_lba
        xor  dx, dx
        mov  cl, al
        mov  ch, 0
        inc  cl
        jmp  read

        convert_lba:
            push bx             # to not loose the destination value
            
            mov  bx, iTrackSect
            xor  dx, dx
            div  bx
            inc  dx
            mov  cl, dl

            mov  bx, iHeadCnt
            xor  dx, dx
            div  bx
            mov  ch, al
            xchg dl, dh

            pop  bx             # get the destination value back

        read:
            mov  dl, iBootDrive
            mov  ax, 0x0201

            cmp byte ptr ignore_disk_err, 1
            je  read_ignore
    
            int  0x13
            jc   bootFailure

            ret

        read_ignore:
            int 0x13
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


.global PrintStr
.func PrintStr
    PrintStr:
        pop  ax
        pop  si
        push ax
        call WriteString
        ret
.endfunc


bootFailure:
    lea  si, diskErrorMsg
    call WriteString
    call Reboot

start:
    mov  iBootDrive, dl

    cli
    mov  ax, 0
    mov  ds, ax
    mov  es, ax
    mov  ss, ax
    mov  sp, 0x7c00
    sti

    mov  ax, 0x03
    int  0x10

    mov  al, '!'
    call WriteChar
 
    mov  dl, iBootDrive
    xor  ax, ax
    int 0x13

    pusha
    mov  si, 0x7c00
    add  si, iSectSize
    mov  ax, 1
    push si
    push ax
    call ReadSector
    popa
   
    lea  si, loadingMsg
    call WriteString
    call IncRow

    mov  dl, iBootDrive
    xor  ax, ax
    int  0x13
    jc   bootFailure

    lea  si, diskOkMsg
    call WriteString
    call IncRow
    
    mov  ax, 32
    xor  dx, dx
    mul  word ptr iRootSize
    div  word ptr iSectSize
    mov  cx, ax
    mov  root_scts, cx

    xor  ax, ax
    mov  al, byte ptr iFatCnt
    mov  bx, word ptr iFatSize
    mul  bx
    add  ax, word ptr iHiddenSect
    adc  ax, word ptr iHiddenSect + 2
    add  ax, word ptr iResSect
    mov  root_strt, ax
    
    
    mov  cx, word ptr root_scts

    read_new_fat_sector:
        # read root_strt sector

        pusha
        lea  si, Tmp
        push si         # destination (hopefully, stack is not that huge ^_^)
        push ax         # source
        call ReadSector
        popa

        push ax
        push cx
        xor  ax, ax
        lea  si, Tmp
        mov  bx, si

        check_entry:
            mov  cx, 3
            mov  di, bx
            lea  si, ssb_filename
            repz cmpsb
            je   foundBootFile
            add  ax, 32
            add  bx, 32
            cmp  ax, word ptr iSectSize
            jne  check_entry

        pop    cx
        pop    ax
        inc    ax
        loopnz read_new_fat_sector

    notFoundBootFile:
        lea  si, ssbNotFound
        call WriteString
        call Reboot

    foundBootFile:
        lea  si, ssb_filename
        call WriteString

        add  bx, 0x1A
        mov  ax, word ptr [bx]
        mov  word ptr ssbf_strt, ax

        jmp  loadFat

    loadFat:
        mov  ax, 0
        mov  es, ax
        
        mov  ax, word ptr iResSect
        add  ax, word ptr iHiddenSect
        adc  ax, word ptr iHiddenSect + 2

        mov  cx, word ptr iFatSize
        mov  bx, FAT_SEGMENT

        read_fat_sector:
            pusha     # to just store the values
            push   bx # destination offset
            push   ax
            call   ReadSector
            mov  ax, 'a'
            call WriteNum
            popa

            add    bx, word ptr iSectSize
            inc    ax
            loopnz read_fat_sector

       jmp load_ssb


lba_conversion_enabled: .byte 1
ignore_disk_err:        .byte 0


.fill (510-(. - main)), 1, 0
.int 0xAA55


    load_ssb:
        xor  bx, bx
        mov  es, bx
        mov  bx, LOAD_SEGMENT
        mov  cx, ssbf_strt

    load_file_sector:
        mov  ax, cx
        add  ax, word ptr root_strt
        add  ax, word ptr root_scts
        sub  ax, 2

        pusha
        push bx
        push ax
        call ReadSector
        popa

        add  bx, word ptr iSectSize

        mov  si, cx
        mov  dx, cx
        shr  dx
        add  si, dx
        add  si, FAT_SEGMENT

        mov  dx, ds:[si]
        test cx, 1
        jnz  read_next_even_cluster
        and  dx, 0x0FFF
        jmp read_cluster_done

        read_next_even_cluster:
            shr  dx, 4
        
        read_cluster_done:
            mov  cx, dx
#            jmp  LOAD_SEGMENT # im risky aha
            mov  al, ch 
            call IncRow
            call WriteNum
            mov  al, cl 
            call WriteNum
            cmp  cx, 0xFF8
            jl   load_file_sector

        call Pause
        mov  ax, word ptr LOAD_SEGMENT
        mov  es, ax
        mov  ds, ax
        jmp  LOAD_SEGMENT


root_scts:              .word  0
root_strt:              .word  0
ssbf_strt:              .word  0
                        .byte  0

ssb_filename:           .ascii "SSB"

ssbMsg:                 .asciz " is found. "
loadingMsg:             .asciz "bHOS is loading..."
diskErrorMsg:           .asciz "Disk error. "
diskOkMsg:              .asciz "Disk is ok. "
ssbNotFound:            .asciz "SSB not found. "
rebootMsg:              .asciz "Press any key to reboot..."
pauseMsg:               .asciz "Pause..."


.fill (512-(. - load_ssb)), 1, 0

Tmp:
