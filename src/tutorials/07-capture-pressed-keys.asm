; Prerequisites: "./01-basics.asm", "./02-rm-addressing.asm", "./03-stack.asm", "./04-display-text-and-numbers-vga.asm",
; "./05-cursor-vga.asm", "./06-read-disk.asm".
;
; In this module we will reconfigure the 8259A PIC. We will disable all IRQs apart from IRQ1. We will set up a
; keyboard ISR for IRQ1 at INT 33. Pressed keys will be printed to the screen.

[org 0x7c00]
[bits 16]
bootsector:
  ; Set up stack to grow down from 0x0000:0x7c00.
  mov word bp, 0x7c00                           
  mov sp, bp
  ; Load additional drivers.
  push 0x7e00                              ; We want to load the sector at the end of our bootsector. This way label offsets work.
  push 0x0001                              ; We want to read sector number 2. We start counting sectors at zero.
  call read_sector
  add sp, 0x4                              ; Clean up stack.
  push 0x8000                              ; We want to load the sector at the end of the previous sector. This way label offsets work.
  push 0x0002                              ; We want to read sector number 3. We start counting sectors at zero.
  call read_sector
  add sp, 0x4                              ; Clean up stack.
  ; Setup empty screen.
  push 0x3000                              ; Pass color and nil char arg.
  call print_whole_screen
  add sp, 0x2                              ; Clean up stack.
  ; Display hello world.
  push TEXT_BUFFER_ROW_SIZE * 0x0002       ; Pass offset arg.
  push 0x3000                              ; Pass color and nil char arg.
  push press_key_string                    ; Pass press key string address arg.
  call print_string_cursor
  add sp, 0x6                              ; Clean up stack
  ; New line
  push ax                                  ; Pass offset arg.
  call set_new_line_cursor
  add sp, 0x2                              ; Clean up stack.
  ; Save offset for later printing.
  push ax
  ; Reinitialize pic with new irq offset.
  push SLAVE_DEFAULT_INT_OFFSET            ; Pass slave offset arg.
  push MASTER_DEFAULT_INT_OFFSET           ; Pass master offset arg.
  call configure_pics
  add sp, 0x4                              ; Clean up stack.
  ; Enable IRQ1 only.
  push DISABLE_ALL_IRQS                    ; Pass slave mask arg.
  push ENABLE_IRQ1_ONLY                    ; Pass master mask arg. 
  call mask_interrupts
  add sp, 0x4                              ; Clean up stack.
  ; Set up keyboard isr in ivt
  call install_keyboard_isr
  ; Repeatedly print most recently pressed key
  hlt                                      ; Halt CPU until we press the first key.
  pop ax
  .loop:
    push ax                                ; Pass offset arg.
    mov word ax, [pressed_key_buffer]      ; Get pressed key.
    mov byte ah, 0x30                      ; Combine color and pressed key char.
    push ax                                ; Pass color and pressed key char arg.
    call print_char_cursor
    add sp, 0x4                            ; Clean up stack.
    sub ax, 0x2                            ; Reset offset so we keep printing in the same place.
    jmp .loop

press_key_string:
  db 'Press any key from [a to z] or [1 to 9]:', 0x0
  
%include "../lib/ata-driver.asm"

bootsector_padding:       
  times 510-(bootsector_padding-bootsector) db 0x00     
  dw 0xaa55

additional_drivers:

%include "../lib/vga-base-driver.asm"
%include "../lib/vga-cursor-driver.asm"
%include "../lib/pic-driver.asm"
%include "../lib/keyboard-driver.asm"

additional_drivers_padding:
  times 1024-(additional_drivers_padding-additional_drivers) db 0x00