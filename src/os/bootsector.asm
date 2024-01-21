[org 0x7c00]
[bits 16]
bootsector:
  ; Set up all segment registers to zero.
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
  ; Set up stack.
  mov word bp, 0x7c00                      ; Grow down from starting address of our bootsector.
  mov sp, bp
  ; Load kernel.
  push 0x7e00                              ; Push target address arg.
  push 0x0002                              ; Push number of sectors arg.
  push 0x0001                              ; Push first sector number arg.
  call load_kernel
  add sp, 0x6                              ; Clean up stack.
  jmp 0x7e00                               ; Jump to kernel code. We will not return here.

load_kernel:
  ; Loads the kernel sectors into memory.
  ;
  ; Arguments:
  ;   First kernel sector LBA as word.
  ;   Number of sectors as word.
  ;   Target memory address as word.
  ;
  ; Function prologue. Set up stack frame.
  push bp
  mov bp, sp
  ; Load sectors.
  .loop:
    push word [bp+8]                       ; Pass through target memory address arg.
    push word [bp+4]                       ; Pass through first sector number arg.
    call read_sector
    add sp, 0x4                            ; Clean up stack.
    ; Prepare next sector.
    add word [bp+4], 0x0001                ; We want to load the next sector.
    sub word [bp+6], 0x0001                ; We successfully loaded a sector. We reduce the numbers of sectors to load by 1.                   
    add word [bp+8], 0x0200                ; We add 512 to the target address. We want to load the next directly after the previous sector.
    cmp word [bp+6], 0x0000                ; Get number of sectors arg and check if unread sectors remain.
  jne .loop
  ; Function epilogue. Tear down stack frame.
  pop bp
  ret

read_sector_padding:                       ; We pad to ensure the read_sector routine starts at address 0x7d00 to call it from kernel.
   times 0x0100-(read_sector_padding-bootsector) db 0x00

%include "../lib/ata-driver.asm"

bootsector_padding:
  times 510-(bootsector_padding-bootsector) db 0x00
  dw 0xaa55