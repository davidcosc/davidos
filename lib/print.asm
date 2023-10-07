; This module contains functions that allow for printing strings, characters and hexadecimal numbers to the screen. 
; Functions are separated into 16 bit mode, 32 bit mode and generic types.
; They will not rely on any interrupts. Instead they will interact directly with the VGA hardware.
; Either by writing to the memory mapped text buffer or by setting the VGA devices registers via port mapped addresses.
; The VGA devices text buffer is mapped to address 0xb8000 and can be accessed like usual memory. 
; The text buffer shares the same address space as our main memory.
; The VGA devices port mapped I/O registers can be accessed using the special in and out instructions.
; In contrast to the text buffer, ports are mapped to a different address space. The in and out instructions work with
; this separate address space.
; For more details see "../images/memory-mapped-io.png".
;
; In order to use this module we must set VGA text mode 80x25 beforehand. Usually this mode has already been set up for us by BIOS.
; We will not include functions to set up the video mode, since it is rather complicated without BIOS.
; An example of how to set video mode without interrupt can be found at "http://bos.asmhackers.net/docs/vga_without_bios/snippet_5/vga.php".

; -----------------------------------------
; 16 bit routines -------------------------
;------------------------------------------
; Write a zero terminated string of
; characters to the screen in VGA text
; mode.
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
print_string_rm:
  call set_up_text_buffer_rm
  push ax
  call calculate_total_character_offset
  mov di, ax
  pop ax
  imul di, 0x2                             ; Numbers of characters offset times 2. Each char in text buffer is stored in 2 bytes.
  mov al, [bx]                             ; First string character value.
  .loop:
    call print_char_rm
    add bx, 0x1                            ; We raise the string address stored in bx by one to point to the next character of the string.
    mov al, [bx]       
    cmp al, 0x0                            ; We check if the value of the character is zero, the string terminating character by convention.
    jne .loop                              ; If the value is not zero, we continue printing.
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
  push bx
  stosw                                    ; Stosw is equivalent to mov [es:di], ax and then inc di by 2.
  mov bx, di
  shr bx, 0x1
  call set_cursor_rm
  pop bx
  ret

;------------------------------------------
; Set VGA text mode cursor position.
;
; Arguments:
;   BX = Cursor offset.
;
[bits 16]
set_cursor_rm:
  push ax
  push dx
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
  pop ax
	ret

;------------------------------------------
; 32 bit routines -------------------------
;------------------------------------------
; Write a zero terminated string of
; characters to the screen in VGA text
; mode.
;
; Arguments:
;   EBX = Starting address of the string.
;   DL = Selected row. One of 0 to 24.
;   DH = Selected column. One of 0 to 79.
;   AH = Color to print.
;
; Returns:
;   EDI = Text buffer offset after printing
;        the string. Numbers of characters
;        offset times 2.
[bits 32]
print_string_pm:
  push ax
  call calculate_total_character_offset
  xor edi, edi
  mov di, ax
  pop ax
  imul edi, 0x2                            ; Numbers of characters offset times 2. Each char in text buffer is stored in 2 bytes.
  add edi, 0xb8000
  mov al, [ebx]                            ; First string character value.
  .loop:
    call print_char_pm
    add ebx, 0x1                           ; We raise the string address stored in bx by one to point to the next character of the string.
    mov al, [ebx]       
    cmp al, 0x0                            ; We check if the value of the character is zero, the string terminating character by convention.
    jne .loop                              ; If the value is not zero, we continue printing.
  ret

;------------------------------------------
; Write a colored ASCII character
; to the screen in VGA 80x25 text mode.
;
; Arguments:
;   AH = Color.
;   AL = ASCII character.
;   EDI = Text buffer offset. 2 per char.
;
; Returns:
;   EDI = Initial DI incremented by two.
[bits 32]
print_char_pm:
  push ebx
  stosw                                    ; Stosw is equivalent to mov [edi], ax and then inc edi by 2.
  mov ebx, edi
  sub ebx, 0xb8000
  shr ebx, 0x1
  call set_cursor_pm
  pop ebx
  ret

;------------------------------------------
; Set VGA text mode cursor position.
;
; Arguments:
;   BX = Cursor offset.
;
[bits 32]
set_cursor_pm:
  push ax
  push dx
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
  pop ax
	ret

;------------------------------------------
; Generic routines ------------------------
;------------------------------------------
; Calculate a total character offset based
; on a 80x25 character text mode screen.
;
; Arguments:
;   DL = Selected row. One of 0 to 24.
;   DH = Selected column. One of 0 to 79.
;
; Returns:
;   AX = Total calculated character offset.
calculate_total_character_offset:
  xor ax, ax                               ; Ensure ax is empty. We want to calculate and store the cursor offset in ax.
  mov al, dl                               ; One row has 80 characters. If we want to select a row, we calculate the offset of all previous rows. We start counting from 0.
  imul ax, 0x50                            ; For the first row we have 0*80=0, hence no offset. For the second row we have 1*80=80, hence 80 offset or one line. And so on.
  add al, dh                               ; Now we add the column offset in order to select the right column within the row. The total offset is now stored in ax.
  ret
