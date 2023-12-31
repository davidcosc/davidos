; Prerequisites: "./01-basics.asm", "./02-rm-addressing.asm", "./03-stack.asm".
;
; The VGA display is a great place to learn about memory and port mapped I/O.
; In the following example, we will use I/O ports to get rid of the cursor by placing it outside of the visible character grid.
; We will then write a "Hello, world!" message to the screen using the memory mapped text buffer, starting at address 0xb8000.
;
; We are going to use the showcased functions later on in our actual minimal os implementation. We separate the functions we want
; reuse in driver files inside the "lib" directory from now on.

MAC_FIRST_VISIBLE_ROW equ TEXT_BUFFER_ROW_SIZE * 2

[org 0x7c00]                               ; The org directive basically tells the location counter to not start counting from zero during assembly but in this case at 0x7c00.
                                           ; This results in our label values / offests being increased by 0x7c00.
[bits 16]
main:
  ; Setup empty screen.
  call paint_screen_red
  call hide_cursor
  ; Write "Hello, world!" to the screen.
  mov word di, MAC_FIRST_VISIBLE_ROW       ; On mac the window bar covers the first two rows of the qemu window. 
  mov byte ah, 0x40                        ; Red background (4) under black font (0).
  mov word bx, hello_msg                   ; Starting adderss of hello message.
  call print_string
  .loop:
    hlt
    jmp .loop

%include "../lib/vga-driver.asm"

hello_msg:
  db 'Hello, world!', 0x0
  
padding:       
  times 510-(padding-main) db 0x00     
  dw 0xaa55