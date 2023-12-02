; Prerequisites: "./01-basics.asm", "./02-rm-addressing.asm", "./03-stack.asm".

MAC_FIRST_VISIBLE_ROW equ 0x50 * 0x2 * 0x2
PLAYER_SIZE equ 0xa

[org 0x7c00]                               ; The org directive basically tells the location counter to not start counting from zero during assembly but in this case at 0x7c00.
                                           ; This results in our label values / offests being increased by 0x7c00.
[bits 16]
main:
  mov ax, 0xb800
  mov es, ax
  call reset_to_red_screen
  call hide_cursor
  mov di, MAC_FIRST_VISIBLE_ROW
  mov ah, 0x40
  mov al, 's'
  call print_char
  .loop:
    hlt
    jmp .loop

%include "../lib/vga-driver.asm"
  
padding:       
  times 510-(padding-main) db 0x00     
  dw 0xaa55