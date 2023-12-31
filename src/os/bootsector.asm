[org 0x7c00]
[bits 16]
set_up_segments_and_registers:
	mov word ax, 0x0000
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov fs, ax
	mov gs, ax
	mov bx, ax
	mov cx, ax
	mov dx, ax
	mov si, ax
	mov di, ax

[bits 16]
set_up_stack:
	mov word bp, 0x7c00                           ; Grow down from starting address of our bootsector.
	mov sp, bp

[bits 16]
load_and_set_up_additional_kernel_drivers:
	push ax
	push di
	mov word ax, 0x1
	mov word di, 0x7e00
	call read_sector
	mov word ax, 0x2
	mov word di, 0x8000
	call read_sector
	pop di
	pop ax
	jmp 0x7e00                                    ; Continue executing instructions in the additional kernel driver sectors.

%include "../lib/ata-driver.asm"

bootsector_padding:
	times 510-(bootsector_padding-set_up_segments_and_registers) db 0x0
	dw 0xaa55