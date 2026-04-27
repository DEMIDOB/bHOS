macro kernelCall callString, kernelCallBufferPointer {
	push ax
	push dx

	mov dx, [kernelCallBufferPointer]
	memcpy callString, dx, KERNEL_CALL_BUFFER_SIZE - 6

	mov dx, [kernelCallBufferPointer]
	add dx, 128

	mov ax, 6
	add ax, $
	push ax

	jmp dx

	pop dx
	pop ax
}