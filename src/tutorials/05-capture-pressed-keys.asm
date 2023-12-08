; Prerequisites: "./01-basics.asm", "./02-rm-addressing.asm", "./03-stack.asm", "./04-display-text-vga.asm".
;
; In this module we will reconfigure the 8259A PIC. We will disable all IRQs apart from IRQ1. We will set up a
; keyboard ISR for IRQ1 at INT 33. Pressed keys will be printed to the screen.

MAC_FIRST_VISIBLE_ROW equ TEXT_BUFFER_ROW_SIZE * 0x2

[org 0x7c00]
[bits 16]
main:
  ; Set up stack to grow down from 0x0000:0x7c00.
  mov bp, 0x7c00                           
  mov sp, bp
  ; Setup empty screen.
  call paint_screen_red
  call hide_cursor
  ; Display hello world.
  mov di, MAC_FIRST_VISIBLE_ROW
  mov ah, 0x42                             ; Select color green on red.
  mov bx, press_key_string                 ; Set starting address of the string to print.
  call print_string
  ; New line
  mov di, TEXT_BUFFER_ROW_SIZE * 0x3
  ; Reinitialize pic with new irq offset.
  mov bh, 0x10                             ; Master pic interrupt offset.
  mov bl, 0x70                             ; Slave pic interrupt offset.
  call configure_pics
  mov bh, 11111101b                        ; We want OCW1 to disable all interrupts apart from IRQ1 on master in order to be able to still use the keyboard.
  mov bl, 11111111b                        ; We want to mask/disable all interrupts on slave.
  call mask_interrupts
  ; Set up keyboard isr in ivt
  mov bx, 0x44
  call install_keyboard_driver
  ; Repeatedly print most recently pressed key
  mov ax, 0xb800                           ; Print char requires ES to point to text buffer starting address.
  mov es, ax
  .loop:
    mov word ax, [pressed_key_buffer]
    mov ah, 0x42
    call print_char
    dec di
    dec di
    jmp .loop

%include "../lib/vga-driver.asm"
%include "../lib/pic-driver.asm"
%include "../lib/keyboard-driver.asm"

press_key_string:
  db 'Press any key from [a to z] or [1 to 9]:', 0x0
  
padding:       
  times 510-(padding-main) db 0x00     
  dw 0xaa55