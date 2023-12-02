; This module contains functions to display strings and characters on the screen in protected mode.

NUM_CHARS_ROW equ 0x50
ROW_26 equ NUM_CHARS_ROW * 0x19
TEXT_BUFFER_ROW_SIZE equ NUM_CHARS_ROW * 0x2

[bits 32]
print_string_pm:
  ; Write a zero terminated string of
  ; characters to the screen in VGA text
  ; mode. Start writing at text buffer
  ; position DI based on 80x25 text mode.
  ;
  ; Arguments:
  ;   EBX = Starting address of the string.
  ;   EDI = Text buffer starting address +
  ;         text buffer offset. 2 per char.
  ;   AH = Color to print.
  ;
  ; Returns:
  ;   EDI = Text buffer offset after the
  ;        string was printed. Numbers of 
  ;        characters offset times 2.
  mov byte al, [ebx]                        ; Start with the first character.
  .loop:
    call print_char_pm
    inc ebx                                 ; Select the next character.
    mov al, [ebx]
    cmp al, 0x0                            ; In case it is zero, stop printing.
    jne .loop
  ret


[bits 32]
print_char_pm:
  ; Write a colored ASCII character
  ; to the screen in VGA 80x25 text mode.
  ;
  ; Arguments:
  ;   AH = Color.
  ;   AL = ASCII character.
  ;   EDI = Text buffer starting address +
  ;         text buffer offset. 2 per char.
  ;
  ; Returns:
  ;   EDI = Initial DI incremented by two.
  stosw
  ret