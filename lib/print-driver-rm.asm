; This module contains functions that allow for printing strings, characters and hexadecimal numbers to the screen. 
; This module contains 16 bit real mode functions. For their 32 bit counterparts see "./print-driver-pm.asm".
;
; The contained functions will not rely on any interrupts. Instead they will interact directly with the VGA hardware.
; Either by writing to the memory mapped text buffer or by setting the VGA devices registers via port mapped addresses.
;
; The VGA devices text buffer is mapped to address 0xb8000 and can be accessed like usual memory. 
; The text buffer shares the same address space as our main memory.
;
; The VGA devices port mapped I/O registers can be accessed using the special in and out instructions.
; In contrast to the text buffer, ports are mapped to a different address space. The in and out instructions work with
; this separate address space.
; For more details see "../images/memory-mapped-io.png".
;
; In order to use this module we must set VGA text mode 80x25 beforehand. Usually this mode has already been set up for us by BIOS.
; We will not include functions to set up the video mode, since it is rather complicated without BIOS.
; An example of how to set video mode without interrupt can be found at "http://bos.asmhackers.net/docs/vga_without_bios/snippet_5/vga.php".

;------------------------------------------
; Write a zero terminated string of
; characters to the screen in VGA text
; mode. Start writing at the specified
; column and row based on 80x25 text mode.
;
; Arguments:
;   BX = Starting address of the string.
;   DL = Selected row. One of 0 to 24.
;   DH = Selected column. One of 0 to 79.
;   AH = Color to print.
;
; Returns:
;   DI = Text buffer offset after printing
;        the string. Numbers of characters
;        offset times 2.
[bits 16]
print_string_row_column_rm:
  push bx
  push dx
  push ax
  call calculate_text_buffer_offset_rm
  call print_string_rm
  pop ax
  pop dx
  pop bx
  ret

;------------------------------------------
; Calculate the text buffer offset
; based on selected row and column
; for 80x25 VGA text mode.
;
; Arguments:
;   DL = Selected row. One of 0 to 24.
;   DH = Selected column. One of 0 to 79.
;
; Returns:
;   DI = Text buffer offset.
[bits 16]
calculate_text_buffer_offset_rm:
  push dx
  push ax
  push bx
  xor bx, bx                               ; Empty bx.
  xor ax, ax                               ; Empty ax. We want to calculate the cursor offset in ax.
  mov al, dl                               ; One row has 80 characters. If we want to select a row, we calculate the offset of all previous rows. We start counting from 0.
  imul ax, 0x50                            ; For the first row we have 0*80=0, hence no offset. For the second row we have 1*80=80, hence 80 offset or one line. And so on.
  mov bl, dh
  add ax, bx                               ; Now we add the column offset in order to select the right column within the row. The total offset is now stored in ax.
  imul ax, 0x2                             ; Each character in the text buffer is stored in 2 bytes.
  mov di, ax
  pop bx
  pop ax
  pop dx
  ret

;------------------------------------------
; Write a zero terminated string of
; characters to the screen in VGA text
; mode. Start writing at the current
; cursor position.
;
; Arguments:
;   BX = Starting address of the string.
;   AH = Color to print.
;
; Returns:
;   DI = Text buffer offset after printing
;        the string. Numbers of characters
;        offset times 2.
[bits 16]
println_rm:
  push bx
  push ax
  call get_cursor_text_buffer_offset_rm
  call print_string_rm
  call move_cursor_next_row_rm
  pop ax
  pop bx
  ret

;------------------------------------------
; Get VGA text buffer cursor position.
;
; Returns:
;   DI = Cursor text buffer offset.
[bits 16]
get_cursor_text_buffer_offset_rm:
   call get_cursor_rm
   imul di, 0x2                           ; Each character in the text buffer is stored in 2 bytes.
   ret

;------------------------------------------
; Get VGA text mode cursor position.
;
; Returns:
;   DI = Cursor offset.
;
[bits 16]
get_cursor_rm:
  push ax
  push dx
  xor di, di                               ; Clear DI.
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
  pop dx
  pop ax
	ret

;------------------------------------------
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
[bits 16]
print_string_rm:
  push bx
  push ax
  call set_up_text_buffer_rm
  mov al, [bx]                             ; First string character value.
  .loop:
    call print_char_rm
    add bx, 0x1                            ; We raise the string address stored in bx by one to point to the next character of the string.
    mov al, [bx]       
    cmp al, 0x0                            ; We check if the value of the character is zero, the string terminating character by convention.
    jne .loop                              ; If the value is not zero, we continue printing.
  call set_cursor_rm
  pop ax
  pop bx
  ret       

;------------------------------------------
; Set up extra segment to start at 0xb8000.
; This is the starting address the VGA
; devices text buffer is mapped to.
;
; Returns:
;   ES = Offset for text buffer start addr.
[bits 16]
set_up_text_buffer_rm:
  push ax
  mov ax, 0xb800
  mov es, ax
  pop ax
  ret

;------------------------------------------
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
[bits 16]
print_char_rm:
  stosw                                    ; Stosw is equivalent to mov [es:di], ax and then inc di by 2.
  ret

;------------------------------------------
; Get the next row offset based on cursor.
;
; Arguments:
;   DI = Text buffer cursor position.
;
; Returns:
;   DI = Next row text buffer offset.
;
[bits 16]
move_cursor_next_row_rm:
  push ax
  push bx
  mov ax, di
  shr ax, 0x1
  mov bl, 0x50
  div bl
  xor bx, bx
  mov bl, al
  add bx, 0x1
  imul bx, 0x50
  imul bx, 0x2
  mov di, bx
  call set_cursor_rm
  pop bx
  pop ax
	ret

;------------------------------------------
; Set VGA text mode cursor position.
;
; Arguments:
;   DI = Text buffer offset.
;
[bits 16]
set_cursor_rm:
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
