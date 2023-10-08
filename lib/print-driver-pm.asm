; This module contains functions that allow for printing strings, characters and hexadecimal numbers to the screen. 
; This module contains 32 bit protected mode functions. For their 16 bit counterparts see "./print-driver-rm.asm".

;------------------------------------------
; Write a zero terminated string of
; characters to the screen in VGA text
; mode. Start writing at the specified
; column and row based on 80x25 text mode.
;
; Arguments:
;   EBX = Starting address of the string.
;   DL = Selected row. One of 0 to 24.
;   DH = Selected column. One of 0 to 79.
;   AH = Color to print.
;
; Returns:
;   DI = Text buffer offset after printing
;        the string. Numbers of characters
;        offset times 2.
[bits 32]
print_string_row_column_pm:
  push ebx
  push dx
  push ax
  call calculate_text_buffer_offset_pm
  call print_string_pm
  pop ax
  pop dx
  pop ebx
  ret

;------------------------------------------
; Calculate the text buffer address plus
; offset based on selected row and column
; for 80x25 VGA text mode.
;
; Arguments:
;   DL = Selected row. One of 0 to 24.
;   DH = Selected column. One of 0 to 79.
;
; Returns:
;   EDI = Text buffer address plus offset.
[bits 32]
calculate_text_buffer_offset_pm:
  push dx
  push eax
  push ebx
  xor eax, eax
  xor ebx, ebx
  xor edi, edi
  mov al, dl                               ; One row has 80 characters. If we want to select a row, we calculate the offset of all previous rows. We start counting from 0.
  imul eax, 0x50                           ; For the first row we have 0*80=0, hence no offset. For the second row we have 1*80=80, hence 80 offset or one line. And so on.
  mov bl, dh
  add eax, ebx                             ; Now we add the column offset in order to select the right column within the row. The total offset is now stored in ax.
  imul eax, 0x2                            ; In the text buffer 2 bytes are used to encode each character.
  add eax, 0xb8000                         ; Add text buffer starting address.
  mov edi, eax
  pop ebx
  pop eax
  pop dx
  ret

;------------------------------------------
; Write a zero terminated string of
; characters to the screen in VGA text
; mode. Start writing at the current
; cursor position.
;
; Arguments:
;   EBX = Starting address of the string.
;   AH = Color to print.
;
; Returns:
;   EDI = Text buffer address plus offset
;         of next line after printing. 
[bits 32]
println_pm:
  push ebx
  push ax
  call get_cursor_text_buffer_offset_pm
  call print_string_pm
  call move_cursor_next_row_pm
  pop ax
  pop ebx
  ret

;------------------------------------------
; Get VGA text buffer cursor position.
;
; Returns:
;   EDI = Cursor text buffer offset.
[bits 32]
get_cursor_text_buffer_offset_pm:
   call get_cursor_pm
   imul edi, 0x2                           ; Numbers of characters offset times 2. Each char in text buffer is stored in 2 bytes.
   add edi, 0xb8000                        ; Add text buffer address to offset to get text buffer address the cursor relates to.
   ret

;------------------------------------------
; Get VGA text mode cursor position.
;
; Returns:
;   EDI = Cursor offset.
[bits 32]
get_cursor_pm:
  push eax
  push edx
  xor edi, edi                             ; Clear EDI.
  mov dx, 0x03D4                           ; Mapped address of the VGA I/O port we can use to manipulate the cursor. This is done in combination with the indices below. 
  mov al, 0x0F                             ; Index for cursor location low register.
  out dx, al                               ; Reading from the VGA register is done in two steps. We first store the index of the register we want to access at the base port address.
  inc dl                                   ; The selected registers value will be available at the address following the base address. The VGA hw handles this for us.
  in ax, dx                                ; The cursor location is stored in two registers, high and low. We first read the lower part of the location/offset word.
  xor ah, ah                               ; Clear ff padding in ah. VGA register values are 8 bit. Only al is relevant to us.
  mov di, ax                               ; Store the first part of the offset in DI.
  dec dl                                   ; Return to base address so we can set the next register we want to target. This will be the cursor location high register.
  mov al, 0x0E                             ; Index for cursor location high register.
  out dx, al
  inc dl
  in ax, dx                                ; Retrieve the high part of the location/offset word.
  shl ax, 0x8                              ; In order to construct the entire offset, we have to add the high and low parts together. To do this, we have to mov the high part to ah.
  add di, ax                               ; Calculate the combined offset.
  pop edx
  pop eax
  ret

;------------------------------------------
; Write a zero terminated string of
; characters to the screen in VGA text
; mode.
;
; Arguments:
;   EBX = Starting address of the string.
;   EDI = Text buffer address plus offset.
;   AH = Color to print.
;
; Returns:
;   EDI = Text buffer address plus offset
;         after printing to the string.
[bits 32]
print_string_pm:
  push ebx
  mov al, [ebx]                            ; First string character value.
  .loop:
    call print_char_pm
    add ebx, 0x1                           ; We raise the string address stored in bx by one to point to the next character of the string.
    mov al, [ebx]       
    cmp al, 0x0                            ; We check if the value of the character is zero, the string terminating character by convention.
    jne .loop                              ; If the value is not zero, we continue printing.
  call set_cursor_pm
  pop ebx
  ret

;------------------------------------------
; Write a colored ASCII character
; to the screen in VGA 80x25 text mode.
;
; Arguments:
;   AH = Color.
;   AL = ASCII character.
;   EDI = Text buffer address plus offset.
;
; Returns:
;   EDI = Initial DI incremented by two.
[bits 32]
print_char_pm:
  stosw                                    ; Stosw is equivalent to mov [edi], ax and then inc edi by 2.
  ret

;------------------------------------------
; Get the next row offset based on cursor.
;
; Arguments:
;   EDI = Text buffer offset cursor position.
;
; Returns:
;   EDX = Next row text buffer offset.
[bits 32]
move_cursor_next_row_pm:
  push eax
  push ebx
  mov eax, edi
  sub eax, 0xb8000
  shr eax, 0x1
  mov bl, 0x50
  div bl
  xor ebx, ebx
  mov bl, al
  add bx, 0x1
  imul bx, 0x50
  imul bx, 0x2
  add ebx, 0xb8000
  mov edi, ebx
  call set_cursor_pm
  pop ebx
  pop eax
  ret

;------------------------------------------
; Set VGA text mode cursor position.
;
; Arguments:
;   EDI = Text buffer address plus offset.
[bits 32]
set_cursor_pm:
  push eax
  push ebx
  push edx
  mov ebx, edi
  sub ebx, 0xb8000                         ; Subtract text buffer starting address to get the actual offset.
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
  pop edx
  pop ebx
  pop eax
  ret
