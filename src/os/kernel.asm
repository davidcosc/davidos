extern_read_sector equ 0x7d00

[org 0x7e00]
[bits 16]
kernel:
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
  ; Setup empty screen.
  push 0x3000                              ; Pass color and nil char arg.
  call print_whole_screen
  add sp, 0x2                              ; Clean up stack.
  ; tmp
  push 0x8200
  push 0x0003
  call extern_read_sector
  add sp, 0x4
  push TEXT_BUFFER_ROW_SIZE * 0x2
  push 0x3000
  push word msg_sec
  call print_string_cursor
  add sp, 0x6
  hlt
  .loop:
    push TEXT_BUFFER_ROW_SIZE * 0x3        ; Pass offset arg.
    mov word ax, [pressed_key_buffer]      ; Get pressed key.
    mov byte ah, 0x30                      ; Combine color and pressed key char.
    push ax                                ; Pass color and pressed key char arg.
    call print_char_cursor
    add sp, 0x4                            ; Clean up stack.
    sub ax, 0x2                            ; Reset offset so we keep printing in the same place.
    jmp .loop

%include "../lib/vga-base-driver.asm"  
%include "../lib/vga-cursor-driver.asm"
%include "../lib/pic-driver.asm"
%include "../lib/keyboard-driver.asm"

kernel_padding:
  times 1024-(kernel_padding-kernel) db 0x00

msg_sec:
  db 'Hello msg sec', 0x00

msg_sec_padding:
  times 512-(msg_sec_padding-msg_sec) db 0x00