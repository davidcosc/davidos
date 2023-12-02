; Prerequisites: "./01-basics.asm", "./02-rm-addressing.asm", "./03-stack.asm".

MAC_FIRST_VISIBLE_ROW equ 0x50 * 0x2 * 0x2

[org 0x7c00]                               ; The org directive basically tells the location counter to not start counting from zero during assembly but in this case at 0x7c00.
                                           ; This results in our label values / offests being increased by 0x7c00.
[bits 16]
main:
  call hide_cursor
  ; Setup ES to point to text mode video buffer.
  mov ax, 0xb800
  mov es, ax                               ; We select ES instead of DS, because it is used by stosw instruction.
  ; Setup empty screen.
  call paint_screen_red
  call hide_cursor
  ; Write "Hello, world!" to the screen.
  mov di, MAC_FIRST_VISIBLE_ROW            ; On mac the window bar covers the first two rows of the qemu window. 
  mov ah, 0x40                             ; Red background (4) under black font (0).
  mov bx, hello_msg                        ; Starting adderss of hello message.
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