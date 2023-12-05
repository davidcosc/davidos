; Prerequisites: "./01-basics.asm", "./02-rm-addressing.asm", "./03-stack.asm".
;
; In this module we want to showcase how the cpu and I/O devices interact with each other.
; We will do so by going over two device drivers in detail.
; First we will write a driver for printing characters and strings to the screen. We will use memory mapped I/O to showcase the function of the video buffer.
; We will use port mapped I/O in order to reposition the cursor at the end of the printed text.
; We will conclude by printing the hello world string to the screen.
;
; In a second example, we will showcase hardware interrupts as a means of triggering I/O actions from the devices side, instead of our currently running main program
; as we did in the previous print driver example. We will initialize the 8259 programmable interrupt controller. This will set up harware interrupts such that an interrupt
; triggers a jump to a specific interrupt vector inside the interrupt vector table. From there an interrupt service routine will be called.
;
; We will set up such an interrupt service routine specifically to handle keys being pressed on a keyboard device (IRQ1). It will retrieve the pressed keys value
; using port mapped I/O and return in inside the DX register. In the main program we will continuously print the pressed keys respective ascii character to the screen.
;
; Since we might use the created drivers later on in our actual minimal os implementation, we will use separate modules "../lib/print-driver-rm.asm", "../lib/pic-driver-rm.asm" and
; "../lib/keyboard-driver-rm.asm" for our routines.

MAC_FIRST_VISIBLE_ROW equ TEXT_BUFFER_ROW_SIZE * 0x2

[org 0x7c00]
[bits 16]
main:
  ; Set up stack to grow down from 0x0000:0x7c00.
  mov bp, 0x7c00                           
  mov sp, bp
  ; Setup empty screen.
  mov ax, 0xb800
  mov es, ax
  call paint_screen_red
  call hide_cursor
  ; Display hello world.
  mov di, MAC_FIRST_VISIBLE_ROW
  mov dl, 0x9                              ; Select row nine.
  mov dh, 0x0                              ; Select column one.
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
  xor dx, dx
  .loop:
    mov al, dl
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