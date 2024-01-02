; Prerequisites: "./01-basics.asm", "./02-rm-addressing.asm", "./03-stack.asm", "./04-display-text-vga.asm".
;
; In this module we will reconfigure the 8259A PIC. We will disable all IRQs apart from IRQ1. We will set up a
; keyboard ISR for IRQ1 at INT 33. Pressed keys will be printed to the screen.

MAC_FIRST_VISIBLE_ROW equ TEXT_BUFFER_ROW_SIZE * 2

[org 0x7c00]
[bits 16]
main:
  ; Set up stack to grow down from 0x0000:0x7c00.
  mov word bp, 0x7c00                           
  mov sp, bp
  ; Setup empty screen.
  call paint_screen_red
  call hide_cursor
  ; Display hello world.
  mov word di, MAC_FIRST_VISIBLE_ROW
  mov byte ah, 0x42                        ; Select color green on red.
  mov word bx, press_key_string            ; Set starting address of the string to print.
  call print_string
  ; New line
  mov word di, TEXT_BUFFER_ROW_SIZE * 3
  ; Reinitialize pic with new irq offset.
  mov byte bh, MASTER_DEFAULT_INT_OFFSET
  mov byte bl, SLAVE_DEFAULT_INT_OFFSET
  call configure_pics
  mov byte bh, 11111101b                   ; We want OCW1 to disable all interrupts apart from IRQ1 on master in order to be able to still use the keyboard.
  mov byte bl, 11111111b                   ; We want to mask/disable all interrupts on slave.
  call mask_interrupts
  ; Set up keyboard isr in ivt
  call install_keyboard_isr
  ; Repeatedly print most recently pressed key
  mov word ax, 0xb800                           ; Print char requires ES to point to text buffer starting address.
  mov es, ax
  .loop:
    mov word ax, [pressed_key_buffer]
    mov byte ah, 0x42
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