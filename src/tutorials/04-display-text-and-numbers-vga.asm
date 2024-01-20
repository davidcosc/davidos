; Prerequisites: "./01-basics.asm", "./02-rm-addressing.asm", "./03-stack.asm".
;
; The VGA display is a great place to learn about memory and port mapped I/O.
; We will start with memory mapped I/O by printing a hex number and a string to the screen using the memory mapped VGA text buffer.
;
; We are going to use the showcased functions later on in our actual minimal os implementation. We separate the functions we want
; reuse in driver files inside the "lib" directory.
;
; We are also going to use a calling convention to write our routines from now on. It is based on cdecl.
; We use the caller to push routine arguments to the stack. We start with the bottom most argument according to the routines
; documentation header and finish with the top most. We use the caller to clean up arguments from the stack after calling a routine.
; The return value of a routine will be placed inside the AX register by the callee.
; We use the callee to set up a stack frame once it is called. We use a function prologue to set up an empty stack at the beginning
; of the routine. Before exiting the routine we use the callee to restore the old stack of the caller.

[org 0x7c00]                               ; The org directive tells the location counter to not start counting from zero.
                                           ; During assembly this results in our label values / offests being increased by 0x7c00.
                                           ; This is necessary, since the BIOS sets the data segment register DS to zero.
[bits 16]
main:
  ; Set up stack to grow down from 0x0000:0x7c00.
  mov word bp, 0x0000
  mov ss, bp
  mov word bp, 0x7c00
  mov sp, bp
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
  call print_hex_word
  add sp, 0x6                              ; Clean up stack.
  ; Add space by skipping the next character text buffer offset.
  add ax, 0x2
  ; Print string.
  push ax                                  ; Pass offset arg.
  push 0x3000                              ; Pass color and nil char arg.
  push hello_world_string                  ; Pass string starting address arg.
  call print_string
  add sp, 0x6                              ; Clean up stack.
  ; Add space by skipping the next character text buffer offset.
  add ax, 0x2
  ; Print char.
  push ax                                  ; Pass offste arg.
  push 0x3000 + 'a'                        ; Pass color and a char arg.
  call print_char
  add sp, 0x4                              ; Clean up stack.
  ; New line.
  push ax                                  ; Pass offset arg.
  call set_new_line
  add sp, 0x2                              ; Clean up stack.
  ; Fill stack with some random values.
  push 0x1234
  push 0x2345
  push 0x3456
  ; Print stack.
  push ax                                  ; Pass offset arg.
  push 0x3000                              ; Pass color and nil char arg.
  call print_stack
  add sp, 0x4                              ; Clean up stack.
  ; Clean up random values from stack.
  add sp, 0x6
  .loop:
    hlt
    jmp .loop

%include "../lib/vga-base-driver.asm"

hello_world_string:
  db 'Hello, world!', 0x00

padding:
  times 510-(padding-main) db 0x00         ; Ensure our code is and fits a bootsector. We can not load additional sectors yet.
  dw 0xaa55