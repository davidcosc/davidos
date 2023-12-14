; This module contains routines to display strings and characters on the screen. It also allows us to hide the cursor.

NUM_CHARS_ROW equ 80
NUM_CHARS_COLUMN equ 25
TOTAL_CHARS_TEXT_MODE equ NUM_CHARS_ROW * NUM_CHARS_COLUMN
ROW_26 equ NUM_CHARS_ROW * 25
TEXT_BUFFER_ROW_SIZE equ NUM_CHARS_ROW * 2
CRT_CONTROLLER_INDEX_PORT equ 0x03d4
CRT_CONTROLLER_DATA_PORT equ 0x03d5
CRT_CONTROLLER_TEXT_CURSOR_LOCATION_LOW_INDEX equ 0x0f
CRT_CONTROLLER_TEXT_CURSOR_LOCATION_HIGH_INDEX equ 0x0e

[bits 16]
hide_cursor:
  ; Hides the cursor by placing it just
  ; outside of the displayed character
  ; range.
  push ax
  push dx
  push bx
  ; Store the new cursor positiong.
  mov word bx, ROW_26
  ; Set the cursor location low index.
  mov word dx, CRT_CONTROLLER_INDEX_PORT
  mov byte al, CRT_CONTROLLER_TEXT_CURSOR_LOCATION_LOW_INDEX
  out byte dx, al
  ; Set the cursor location low value.
  mov word dx, CRT_CONTROLLER_DATA_PORT
  mov al, bl                               ; Lower part of the new cursor location. The cursor location is split in two VGA registers.
  out byte dx, al
  ; Set the cursor location high index.
  mov word dx, CRT_CONTROLLER_INDEX_PORT
  mov byte al, CRT_CONTROLLER_TEXT_CURSOR_LOCATION_HIGH_INDEX
  out byte dx, al
  ; Set the cursor location high value.
  mov word dx, CRT_CONTROLLER_DATA_PORT
  mov al, bh                               ; High part of the new cursor location.
  out byte dx, al
  pop bx
  pop dx
  pop ax
  ret

[bits 16]
paint_screen_red:
  ; Paints the entire screen red.
  ; Resets DI to 0x0. 
  ; Only works in 80x25 text mode.
  ;
  ; Returns:
  ;   DI = Zero.
  push ax
  push es
  push cx
  mov word ax, 0xb800
  mov es, ax                               ; Set up text buffer starting address as ES segment start.
  mov word ax, 0x4000                      ; Set red background under black font. Set null character. Only the red background remains.
  xor di, di                               ; Clear di.
  mov word cx, TOTAL_CHARS_TEXT_MODE       ; Set counter register to total screen character size. Using this with rep will repeat the following instruction cx times.
  rep stosw                                ; Stosw is equivalent to mov [es:di], ax and then inc di by 2.
  xor di, di                               ; Clear di.
  pop cx
  pop es
  pop ax
  ret

[bits 16]
print_string:
  ; Write a zero terminated string of
  ; characters to the screen in VGA text
  ; mode. Start writing at text buffer
  ; position DI based on 80x25 text mode.
  ;
  ; Arguments:
  ;   BX = Starting address of the string.
  ;   DI = Text buffer offset. 2 per char.
  ;   AH = Color to print.
  ;
  ; Returns:
  ;   DI = Text buffer offset after the
  ;        string was printed. Numbers of 
  ;        characters offset times 2.
  push ax
  push bx
  push es
  push dx
  mov word dx, 0xb800
  mov es, dx
  mov byte al, [bx]                        ; Start with the first character.
  .loop:
    call print_char
    inc bx                                 ; Select the next character.
    mov byte al, [bx]
    cmp al, 0x0                            ; In case it is zero, stop printing.
    jne .loop
  pop dx
  pop es
  pop bx
  pop ax
  ret

[bits 16]
print_hex_word:
  ; Write a 16 bit hex number to the screen
  ; in VGA text mode. Start writing at text
  ; buffer position DI based on 80x25 text
  ; mode.
  ;
  ; Arguments:
  ;   BX = Hex word to print.
  ;   DI = Text buffer offset. 2 per char.
  ;   AH = Color to print.
  ;
  ; Returns:
  ;   DI = Text buffer offset after the
  ;        number was printed. Numbers of
  ;        characters offset times 2.
  push es
  push ax
  push bx
  push dx
  mov word dx, 0xb800
  mov es, dx
  mov dh, bh
  shr dh, 4
  mov al, dh
  call print_hex_nibble
  mov dh, bh
  shl dh, 4
  shr dh, 4
  mov al, dh
  call print_hex_nibble
  mov dh, bl
  shr dh, 4
  mov al, dh
  call print_hex_nibble
  mov dh, bl
  shl dh, 4
  shr dh, 4
  mov al, dh
  call print_hex_nibble
  pop dx
  pop bx
  pop ax
  pop es
  ret

print_hex_nibble:
  ; Write a colored hex digit
  ; to the screen in VGA 80x25 text mode.
  ; Requires ES set to the text buffer
  ; starting address.
  ;
  ; Arguments:
  ;   AH = Color.
  ;   AL = Hex digit.
  ;   DI = Text buffer offset. 2 per char.
  ;
  ; Returns:
  ;   DI = Initial DI incremented by two.
  push ax
  cmp al, 9
  jbe .num
  sub al, 0xa
  add al, 'a'
  jmp .print
  .num:
    add al, '0'
  .print:
    call print_char
  pop ax
  ret

[bits 16]
print_char:
  ; Write a colored ASCII character
  ; to the screen in VGA 80x25 text mode.
  ; Requires ES set to the text buffer
  ; starting address.
  ;
  ; Arguments:
  ;   AH = Color.
  ;   AL = ASCII character.
  ;   DI = Text buffer offset. 2 per char.
  ;
  ; Returns:
  ;   DI = Initial DI incremented by two.
  push ax
  stosw
  pop ax
  ret
