
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

