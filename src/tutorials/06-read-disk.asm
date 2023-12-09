; Prerequisites: "./01-basics.asm", "./02-rm-addressing.asm", "./03-stack.asm", "./04-display-text-vga.asm".
;
; The bootsector is already loaded into memory for us by the BIOS. In this module we read an additional sector to memory.

[org 0x7c00]
[bits 16]
main:
  ; Setup empty screen.
  call paint_screen_red
  call hide_cursor
  ; Read disk.
  mov word ax, 0x0001                      ; We want to read sector number 2. We start counting sectors at zero.
  mov word di, 0x7e00                      ; We want to load the sector at the end of our bootsector. This way label offsets work.
  call read_sector
  ; Print sector two message.
  mov byte ah, 0x40
  mov word bx, sector_two
  mov word di, TEXT_BUFFER_ROW_SIZE * 0x0002
  call print_string
  .loop:
    hlt
    jmp .loop

%include "../lib/ata-driver.asm"
%include "../lib/vga-driver.asm"

padding:
  times 510-(padding-main) db 0x00     
  dw 0xaa55

sector_two:
  db 'Hello, sector two!', 0x00
  .padding:
    times 512-(.padding-sector_two) db 0x00