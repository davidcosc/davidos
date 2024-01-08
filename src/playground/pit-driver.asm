; Requires "pic-driver.asm" to be set up beforehand.
; This module contains routines for configuring the 8254 programmable interval timer as well as the respective ISR.

install_pit_isr:
  ; Setup an interrupt vector inside the ivt
  ; to point to the pit_isr. After
  ; running this routine, interrupts that
  ; refer to the configured vector will
  ; trigger the pit_isr. The vector must
  ; match IRQ 0 as specified by the PIC.
  cli
  push es
  push di
  push ax
  ; Init segments.
  mov word di, 0x0000
  mov es, di
  ; Set up vector.
  mov word di, MASTER_DEFAULT_IRQ0_IVT_ADDRESS
  mov word ax, pit_isr
  stosw
  mov word ax, 0x0000
  stosw
  pop ax
  pop di
  pop es
  sti
  ret

pit_isr:
  cli
  pusha
  mov ah, 0x40
  mov word bx, [pit_counter]
  add word bx, 0x0001
  mov word [pit_counter], bx
  mov di, 0xb800
  mov es, di
  mov di, TEXT_BUFFER_ROW_SIZE * 5
  call print_hex_word
  mov word dx, PIC_8259A_EOI_PORT
  mov byte al, PIC_8259A_EOI_COMMAND
  out dx, al
  popa
  sti
  ret

pit_counter:
  dw 0x0000