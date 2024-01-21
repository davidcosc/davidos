; Prerequisites: "./01-basics.asm", "./02-rm-addressing.asm", "./03-stack.asm", "./vga-base-driver.asm".
;
; We will showcase port mapped I/O by using some VGA controller I/O ports to position the cursor on the screen.
; The print_hex_word_cursor, print_string_cursor and print_char_cursor routines use the position_cursor routine to always
; place the cursor at the end of the printed number, string or char.
;
; To show that all routines work correctly, we can change the routine calls of the two routines we do not want to test to
; their non cursor variants.

[org 0x7c00]
[bits 16]
bootsector:
  ; Paint a ligh blue clear screen.
  push 0x3000                              ; Pass color and nil char argument.
  call print_whole_screen
  add sp, 0x02                             ; It is the callers job to clean up the stack to the state before argument passing.
  ; The first two rows zero and one are not visible in qemu on mac due to window header bar. We skip them.
  add ax, TEXT_BUFFER_ROW_SIZE * 0x2
  ; Print hex.
  push ax                                  ; Pass text buffer offset arg, the bottom most argument documented in print_hex_word.
  push 0x3000                              ; Pass color and nil char argument.
  push 0x1234                              ; Pass hex number to print argument, the top most argument documented in print_hex_word.
  call print_hex_word_cursor
  add sp, 0x6                              ; Clean up stack.
  ; Add space by skipping the next character text buffer offset.
  add ax, 0x2
  ; Print string.
  push ax                                  ; Pass offset arg.
  push 0x3000                              ; Pass color and nil char arg.
  push hello_world_string                  ; Pass string starting address arg.
  call print_string_cursor
  add sp, 0x6                              ; Clean up stack.
  ; Add space by skipping the next character text buffer offset.
  add ax, 0x2
  ; Print char.
  push ax                                  ; Pass offset arg.
  push 0x3000 + 'a'                        ; Pass color and a char arg.
  call print_char_cursor
  add sp, 0x4                              ; Clean up stack.
  ; New line.
  push ax                                  ; Pass offset arg.
  call set_new_line_cursor
  add sp, 0x2                              ; Clean up stack.
  .loop:
    hlt
    jmp .loop

%include "../lib/vga-base-driver.asm"
%include "../lib/vga-cursor-driver.asm"

hello_world_string:
  db 'Hello, world!', 0x00

bootsector_padding:
  times 510-(bootsector_padding-bootsector) db 0x00
  dw 0xaa55