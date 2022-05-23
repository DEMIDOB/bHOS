memcpy: ; (source, dest, size)

	add ax, si ; loop end

	memcpy_loop:
		cmp si, ax
		je memcpy_loop_end

		mov dl, byte[si]
		mov [di], dl
		inc si
		inc di

		jmp memcpy_loop

	memcpy_loop_end:
		ret
