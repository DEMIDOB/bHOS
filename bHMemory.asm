macro memcpy source, dest, size { ; size in bytes
	push dx
	push si
	push di

	mov si, source
	mov di, dest

	memcpy_loop:
		cmp si, source + size
		je memcpy_loop_end

		mov dl, byte[si]
		mov [di], dl
		inc si

		jmp memcpy_loop

	memcpy_loop_end:

	pop di
	pop si
	pop dx
}