; Prerequisites: "./01-basics.asm", "./02-rm-addressing.asm", "./03-stack.asm", "./04-display-text-and-numbers-vga.asm", "./05-cursor-vga.asm".
;
; The bootsector is already loaded into memory for us by the BIOS. In this module we read an additional sector to memory.

[org 0x7c00]
[bits 16]
bootsector:
  ; Setup screen.
  push 0x3000                              ; Pass color and nil char arg.
  call print_whole_screen
  add sp, 0x2                              ; Clean up stack.
  ; Read disk.
  push 0x7e00                              ; We want to load the sector at the end of our bootsector. This way label offsets work.
  push 0x0001                              ; We want to read sector number 2. We start counting sectors at zero.
  call read_sector
  add sp, 0x4                              ; Clean up stack.
  ; Print return value.
  push TEXT_BUFFER_ROW_SIZE * 0x0002       ; Pass offset arg.
  push 0x3000                              ; Pass color and nil char arg.
  push ax                                  ; Pass return value arg.
  call print_hex_word
  add sp, 0x6                              ; Clean up stack.
  ; Add space.
  add ax, 0x2
  ; Print sector two message.
  push ax                                  ; Pass offset arg.
  push 0x3000                              ; Pass color and nil char arg.
  push sector_two                          ; Pass sector two message starting address arg.
  call print_string_cursor
  add sp, 0x6                              ; Clean up stack.
  .loop:
    hlt
    jmp .loop

%include "../lib/ata-driver.asm"
%include "../lib/vga-base-driver.asm"

bootsector_padding:
  times 510-(bootsector_padding-bootsector) db 0x00     
  dw 0xaa55

sector_two:
  db 'Hello, sector two!', 0x00

%include "../lib/vga-cursor-driver.asm"

sector_two_padding:
    times 512-(sector_two_padding-sector_two) db 0x00