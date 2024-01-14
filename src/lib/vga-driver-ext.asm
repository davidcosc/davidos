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

print_stack:
  ; Print the stack. This includes the
  ; registers pushed as part of this
  ; routine.
  ;
  ; Arguments:
  ;   CX = Row number to start printing.
  push es
  push ds
  pusha
  ; Init segement.
  xor si, si
  mov ds, si
  ; Print header.
  mov byte ah, 0x40
  mov di, cx
  imul di, TEXT_BUFFER_ROW_SIZE
  mov bx, print_stack_header_row
  call print_string
  ; Print stack.
  mov di, cx
  imul di, TEXT_BUFFER_ROW_SIZE
  add di, TEXT_BUFFER_ROW_SIZE
  mov si, sp
  .loop:
    mov bx, [si]
    call print_hex_word
    add di, 0x2
    add si, 0x2
    cmp si, bp
    jne .loop
  popa
  pop ds
  pop es
  ret

print_stack_header_row:
  db 'DI   SI   BP   SP   BX   DX   CX   AX   DS   ES', 0x00