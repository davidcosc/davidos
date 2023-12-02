ROW_26 equ 0x50 * 0x19
CRT_CONTROLLER_INDEX_PORT equ 0x3d4
CRT_CONTROLLER_DATA_PORT equ 0x3d5
CRT_CONTROLLER_TEXT_CURSOR_LOCATION_LOW_INDEX equ 0xf
CRT_CONTROLLER_TEXT_CURSOR_LOCATION_HIGH_INDEX equ 0xe

[bits 16]
hide_cursor:
  ; Hides the cursor by placing it just
  ; outside of the displayed character
  ; range.
  push ax
  push dx
  push bx
  ; Store the new cursor positiong.
  mov bx, ROW_26
  ; Set the cursor location low index.
  mov dx, CRT_CONTROLLER_INDEX_PORT
  mov al, CRT_CONTROLLER_TEXT_CURSOR_LOCATION_LOW_INDEX
  out dx, al
  ; Set the cursor location low value.
  mov dx, CRT_CONTROLLER_DATA_PORT
  mov al, bl                               ; Lower part of the new cursor location. The cursor location is split in two VGA registers.
  out dx, al
  ; Set the cursor location high index.
  mov dx, CRT_CONTROLLER_INDEX_PORT
  mov al, CRT_CONTROLLER_TEXT_CURSOR_LOCATION_HIGH_INDEX
  out dx, al
  ; Set the cursor location high value.
  mov dx, CRT_CONTROLLER_DATA_PORT
  mov al, bh                               ; High part of the new cursor location.
  out dx, al
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
  pusha
  mov ax, 0x4000                           ; Set red background under black font. Set null character. Only the red background remains.
  xor di, di                               ; Clear di.
  mov cx, 80*25                            ; Set counter register to total screen character size. Using this with rep will repeat the following instruction cx times.
  rep stosw                                ; Stosw is equivalent to mov [es:di], ax and then inc di by 2.
  xor di, di                               ; Clear di.
  popa
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
  ;   DI = Text buffer offset.
  ;   AH = Color to print.
  ;
  ; Returns:
  ;   DI = Text buffer offset after printing
  ;        the string. Numbers of characters
  ;        offset times 2.
  mov byte al, [bx]                        ; Start with the first character.
  .loop:
    call print_char
    inc bx                                 ; Select the next character.
    mov al, [bx]
    cmp al, 0x0                            ; In case it is zero, stop printing.
    jne .loop
  ret


[bits 16]
print_char:
  ; Write a colored ASCII character
  ; to the screen in VGA 80x25 text mode.
  ; Requires ES set to text video buffer.
  ;
  ; Arguments:
  ;   AH = Color.
  ;   AL = ASCII character.
  ;   DI = Text buffer offset. 2 per char.
  ;
  ; Returns:
  ;   DI = Initial DI incremented by two.
  stosw
  ret
