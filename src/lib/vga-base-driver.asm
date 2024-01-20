; This module contains routines to display strings and characters on the screen. It is the base for additional vga driver modules.

TEXT_BUFFER_STARTING_ADDRESS equ 0xb8000
TEXT_BUFFER_SEGMENT_ADDRESS equ TEXT_BUFFER_STARTING_ADDRESS / 16
NUM_CHARS_ROW equ 80
NUM_CHARS_COLUMN equ 25
TOTAL_CHARS_TEXT_MODE equ NUM_CHARS_ROW * NUM_CHARS_COLUMN
TEXT_BUFFER_ROW_SIZE equ NUM_CHARS_ROW * 2

[bits 16]
print_stack:
  ; Prints the stack. Ajusts for values that
  ; are pushed onto the stack as part of the
  ; printing process. This results in the
  ; stack state previous to calling this
  ; routine being printed. The third value
  ; printed is the first stack value. Values
  ; one and two are SP and BP addresses of
  ; the printed stack.
  ;
  ; Arguments:
  ;   Color and nil char as word.
  ;   Text buffer offset word. 2 per char.
  ;
  ; Returns:
  ;   AX = Offset after the
  ;        stack was printed.
  ;
  ; Function prologue. Set up stack frame.
  push bp
  mov bp, sp
  ; Get previous stack top. [bp+0] = prev BP address. [bp+2] = print_stack ret. [bp+4/6] = args. BP + 8 prev stack top address.
  mov word si, bp                          ; We use SI since print_hex_word does not change it and we want to inc it later.
  add si, 8
  ; Print previous SP.
  push word [bp+6]                         ; Pass through offset arg.
  push word [bp+4]                         ; Pass through color and nil char arg.
  push word si                             ; Pass stack top address arg.
  call print_hex_word
  add sp, 0x6                              ; Clean up stack.
  ; Add space by skipping the next character text buffer offset.
  add ax, 0x2
  ; Get previous stack base.
  mov word bx, [bp]  
  ; Print previous BP.
  push ax                                  ; Pass offset arg.
  push word [bp+4]                         ; Pass through color and nil char arg.
  push bx                                  ; Pass stack bot address arg.
  call print_hex_word
  add sp, 0x6                              ; Clean up stack.
  ; Print stack values.
  .loop:
    ; Check stack not empty.
    cmp word [bp], si                      ; Check if current value address is equal to the stack base address.
    je .break                              ; Stack is empty.
      ; Add space by skipping the next character text buffer offset.
      add ax, 0x2
      push ax                                ; Pass offset arg.
      push word [bp+4]                       ; Pass through color and nil char arg.
      push word [si]                         ; Pass current value.
      call print_hex_word
      add sp, 0x6
      ; Set next value address.
      add si, 0x2
  jmp .loop
  .break:
  ; Function epilogue. Tear down stack frame.
  pop bp
  ret

[bits 16]
print_string:
  ; Write a zero terminated string of
  ; characters to the screen in 80x25
  ; VGA text mode.
  ;
  ; Arguments:
  ;   String pointer as word.
  ;   Color and nil char to print as word.
  ;   Text buffer offset word. 2 per char.
  ;
  ; Returns:
  ;   AX = Offset after the
  ;        string was printed.
  ;
  ; Function prologue. Set up stack frame.
  push bp
  mov bp, sp
  ; Get args.
  mov word bx, [bp+4]
  mov word ax, [bp+6]
  mov word di, [bp+8]
  ; Print all chars of string.
  mov byte al, [bx]                        ; Start with the first character.
  .loop:
    push di                                ; Pass offset arg.
    push ax                                ; Pass color and char arg.
    call print_char
    add sp, 0x4                            ; Clean up stack
    ; Prepare for next char.
    mov di, ax                             ; Next offset from return value to DI.
    mov word ax, [bp+6]                    ; Get color and nil back into AX.
    ; Select the next character.
    inc bx
    mov byte al, [bx]
    cmp al, 0x0                            ; In case it is zero, stop printing.
    jne .loop
  ; Set return value.
  mov ax, di
  ; Function epilogue. Tear down stack frame.
  pop bp
  ret

[bits 16]
print_hex_word:
  ; Write a 16 bit hex number to the screen
  ; in VGA 80x25 text mode.
  ;
  ; Arguments:
  ;   Hex word to print.
  ;   Color and nil char to print as word.
  ;   Text buffer offset word. 2 per char.
  ;
  ; Returns:
  ;   AX = Offset after the
  ;        number was printed.
  ;
  ; Function prologue. Set up stack frame.
  push bp
  mov bp, sp
  ; Get hex word and offset arg so we can manipulate them later.
  mov word bx, [bp+4]
  mov word di, [bp+8]
  ; Print nibbles.
  mov word cx, 0x4
  .next_nibble:
    ; Select nibble.
    mov word ax, [bp+6]                    ; Get color arg.
    mov dx, bx
    shr dx, 4                              ; Isolate first nibble in DH. I.e DH = ab becomes DH = 0a.
    mov al, dh                             ; Combine color and nibble.
    ; Store args on stack.
    push di                                ; Pass through offset arg.
    push ax                                ; Pass color and nibble arg.
    call print_hex_nibble
    add sp, 0x4                            ; Clean up stack.
    ; Prepare for next nibble.
    mov di, ax                             ; Set next offset from AX return value.
    shl bx, 4                              ; Prepare next nibble in high 4 bits.
  loop .next_nibble
  ; Function epilogue. Tear down stack frame.
  pop bp
  ret

[bits 16]
print_hex_nibble:
  ; Write a colored hex digit
  ; to the screen in VGA 80x25 text mode.
  ;
  ; Arguments:
  ;   Color and hex nibble as word.
  ;   Text buffer offset word. 2 per char.
  ;
  ; Returns:
  ;   AX = Offset incremented by two.
  ;
  ; Function prologue. Set up stack frame.
  push bp
  mov bp, sp
  ; Get color and hex nibble arg..
  mov word ax, [bp+4]
  ; Convert to ASCII.
  cmp al, 9                                ; Check of nibble is letter or digit.
  jbe .num                                 ; If it is smaller than or equal to 9 its a digit, otherwise it is a letter.
    sub al, 0xa                            ; We subtract 10 to get ASCII offset of the respective letter.
    add al, 'a'                            ; We add the base ASCII code for A to get the letters ASCII code. A + 0 = A. A + 1 = B.
    jmp .print
  .num:
    add al, '0'                            ; We add the ASCII code for 0 to each digit. '0' + 0 = '0'. '0' + 1 = '1'.
  .print:
    push word [bp+6]                       ; Pass through offset arg.
    push ax                                ; Pass color and char ASCII code arg.
    call print_char
    add sp, 0x4                            ; Clean up stack.
  ; Function epilogue. Tear down stack frame.
  pop bp
  ret

[bits 16]
print_char:
  ; Write a colored ASCII character
  ; to the screen in VGA 80x25 text mode.
  ;
  ; Arguments:
  ;   Color and ASCII character as word.
  ;   Text buffer offset word. 2 per char.
  ;
  ; Returns:
  ;   AX = Offset incremented by two.
  ;
  ; Function prologue. Set up stack frame.
  push bp
  mov bp, sp
  ; Set up text buffer starting address as ES segment start.
  mov word ax, TEXT_BUFFER_SEGMENT_ADDRESS
  mov es, ax
  ; Get arguments.
  mov word ax, [bp+4]
  mov word di, [bp+6]
  ; Print char.
  stosw                                    ; Stosw is equivalent to mov word [es:di], ax and then inc di by 2.
  ; Set return value.
  mov ax, di
  ; Function epilogue. Tear down stack frame.
  pop bp
  ret

[bits 16]
print_whole_screen:
  ; Writes the passed color and char to each
  ; character position of a VGA 80x25 text
  ; mode screen.
  ;
  ; Arguments:
  ;   Color and char as word.
  ;
  ; Returns:
  ;   AX = Text buffer offset as word.
  ;
  ; Function prologue. Set up stack frame.
  push bp
  mov bp, sp
  ; Set up text buffer starting address as ES segment start.
  mov word ax, TEXT_BUFFER_SEGMENT_ADDRESS
  mov es, ax
  ; Get color argument.
  mov word ax, [bp+4]
  ; Set color and null char value for each char representation in text buffer.
  xor di, di                               ; Clear di.
  mov word cx, TOTAL_CHARS_TEXT_MODE       ; Set counter register to total screen character size.
  rep stosw                                ; Stosw is equivalent to mov word [es:di], ax and then inc di by 2. Repeat CX times.
  xor di, di                               ; Clear di.
  ; Set first char text buffer offset as return value.
  mov ax, di
  ; Function epilogue. Tear down stack frame.
  pop bp
  ret

[bits 16]
set_new_line:
  ; Calculates a new line text buffer offset
  ; in VGA 80x25 text mode based on the
  ; passed offset.
  ;
  ; Arguments:
  ;   Text buffer offset word. 2 per char.
  ;
  ; Returns:
  ;   AX = New line offset.
  ;
  ; Function prologue. Set up stack frame.
  push bp
  mov bp, sp
  ; Get arg.
  mov word ax, [bp+4]
  ; Calculate current row number.
  mov word dx, TEXT_BUFFER_ROW_SIZE
  div dl
  xor ah, ah                               ; Discard remainder.
  imul ax, TEXT_BUFFER_ROW_SIZE
  ; Set return value.
  add ax, TEXT_BUFFER_ROW_SIZE
  ; Function epilogue. Tear down stack frame.
  pop bp
  ret