; This module contains additional vga routines for printing registers.

[bits 16]
print_registers:
  ; Print all important register values to
  ; the screen in VGA text mode.
  ;
  ; Arguments:
  ;   CX = Row number to print to.
  pusha
  push bx
  push ax
  push es
  push di
  ; Print header.
  mov byte ah, 0x40
  mov di, cx
  imul di, TEXT_BUFFER_ROW_SIZE
  mov word bx, print_registers_header_row
  call print_string
  ; Print DI.
  mov di, cx
  imul di, TEXT_BUFFER_ROW_SIZE
  add di, TEXT_BUFFER_ROW_SIZE
  pop bx
  call print_hex_word
  add di, 0x2
  ; Print ES.
  pop bx
  call print_hex_word
  add di, 0x2
  ; Print SI.
  mov bx, si
  call print_hex_word
  add di, 0x2
  ; Print DS.
  mov bx, ds
  call print_hex_word
  add di, 0x2
  ; Print AX.
  pop bx
  call print_hex_word
  add di, 0x2
  ; Print BX.
  pop bx
  call print_hex_word
  add di, 0x2
  ; Print CX.
  mov bx, cx
  call print_hex_word
  add di, 0x2
  ; Print DX.
  mov bx, dx
  call print_hex_word
  add di, 0x2
  ; Print BP.
  mov bx, bp
  call print_hex_word
  add di, 0x2
  ; Print SP.
  mov bx, sp
  call print_hex_word
  popa
  ret 

print_registers_header_row:
  db 'DI   ES   SI   DS   AX   BX   CX   DX   BP   SP', 0x00