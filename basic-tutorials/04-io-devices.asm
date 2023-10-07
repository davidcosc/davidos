; Prerequisites: "basics.asm", "rm-addressing.asm", "stack.asm".
;
; In this module we want to show case how the cpu and I/O devices interact with each other.
; Since this is a deep dive into the inner workings of memory mapped I/O and port mapped I/O,
; we will not use any interrupts, since they usually abstract these details away for us.
;
; To prevent a lot of redundant code, we will use a separate module "../lib/print.asm" for our routines.
; We are going to use them later on in our actual boot sector.
; You will find all the detailed information about I/O inside "print.asm".
;
; As an example we will print a simple string to the screen.

[bits 16]
main:
  ; Set up the data segment to start where our boot sector is loaded.
  mov bx, 0x07c0
  mov ds, bx
  ; Set up stack to grow down from 0x0000:0x7c00.
  mov bp, 0x7c00                           
  mov sp, bp
  ; Display hello world.
  mov dl, 0x9                              ; Select row nine.
  mov dh, 0x0                              ; Select column one.
  mov ah, 0x02                             ; Select color green on black.
  mov bx, hello_world_string               ; Set starting address of the string to print.
  call print_string_rm
  ; Do nothing
  .loop:
    jmp .loop

%include "../lib/print.asm"

hello_world_string:
  db 'Hello, world!', 0x0
  
padding:       
  times 510-(padding-main) db 0x00     
  dw 0xaa55