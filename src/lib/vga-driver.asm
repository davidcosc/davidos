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
reset_to_red_screen:
  ; Paints the entire screen red.
  ; Resets DI to 0x0. 
  ; Only works in 80x25 text mode.
  ;
  ; Returns:
  ;   DI = Zero.
  pusha
  mov ax, 0x4000                           ; Light green background.
  xor di, di                               ; Clear di.
  mov cx, 80*25                            ; Set counter register to total screen character size. Using this with rep will repeat the following instruction cx times.
  rep stosw                                ; Stosw is equivalent to mov [es:di], ax and then inc di by 2. We write zero to all 80*25 words in video memory for a black screen.
  xor di, di                               ; Clear di.
  popa
  ret

[bits 16]
print_char:
  ; Write a colored ASCII character
  ; to the screen in VGA 80x25 text mode.
  ; Requires set_up_text_buffer_rm.
  ;
  ; Arguments:
  ;   AH = Color.
  ;   AL = ASCII character.
  ;   DI = Text buffer offset. 2 per char.
  ;
  ; Returns:
  ;   DI = Initial DI incremented by two.
  stosw                                    ; Stosw is equivalent to mov [es:di], ax and then inc di by 2.
  ret
