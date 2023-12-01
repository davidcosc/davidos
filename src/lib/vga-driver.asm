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
  call set_cursor_rm
  ret

[bits 16]
set_cursor_rm:
  ; Set VGA text mode cursor position.
  ;
  ; Arguments:
  ;   DI = Text buffer offset.
  ;
  push ax
  push bx
  push dx
  mov bx, di
  shr bx, 0x1                              ; We divide by 2 to get the character offset based on 80x25, since the VGA ports do not use 2 bytes per character like the buffer.
  mov dx, 0x03D4                           ; Mapped address of the VGA I/O port we can use to manipulate the cursor. This is done in combination with the indices below. 
  mov al, 0x0F                             ; Index for cursor location low register.
  out dx, al                               ; Writing to the VGA register is done in two steps. We first store the index of the register we want to access at the base port address.
  inc dl                                   ; We place the value we want to set the selected register to, to the address following the base address. Storing the value is handled by hw.
  mov al, bl                               ; The cursor location is stored in two registers, high and low. We first write the lower part of the location/offset word.
  out dx, al
  dec dl                                   ; Return to base address so we can set the next register we want to target. This will be the cursor location high register.
  mov al, 0x0E                             ; Index for cursor location high register.
  out dx, al
  inc dl
  mov al, bh                               ; Store the high part of the location/offset word.
  out dx, al
  pop dx
  pop bx
  pop ax
  ret
