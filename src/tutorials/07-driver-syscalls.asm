[org 0x7c00]
[bits 16]
main:
  call install_syscall_isr
  ; Test clear screen interrupt.
  mov word ax, 0x2
  int 0x80
  ; Test print hex word interrupt.
  mov word dx, 0x4000
  mov word di, TEXT_BUFFER_ROW_SIZE * 0x2
  mov word bx, 0x1234
  mov word ax, 0x3
  int 0x80
  ; Test print string interrupt.
  mov word dx, 0x4000
  mov word di, TEXT_BUFFER_ROW_SIZE * 0x3
  mov word bx, test_string
  mov word ax, 0x4
  int 0x80
  ; Test print char interrupt.
  mov byte dh, 0x40
  mov byte dl, 'a'
  mov word di, 0xb800
  mov es, di
  mov word di, TEXT_BUFFER_ROW_SIZE * 0x4
  mov word ax, 0x5
  int 0x80
  .loop:
    hlt
    jmp .loop

%include "../lib/vga-driver.asm"
%include "../lib/syscall.asm"

test_string:
  db 'Test string!', 0x00

padding:       
  times 510-(padding-main) db 0x00     
  dw 0xaa55

sector_two:
  db 'Sector two1', 0x00
  .padding:
    times 512-(.padding-sector_two) db 0x00