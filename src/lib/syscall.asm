; This module contains routines for setting up a syscall ISR at interrupt vector 0x80.

SYSCALL_INTERRUPT_VECTOR_NUMBER equ 0x80
SYSCALL_INTERRUPT_VECTOR_ADDRESS equ SYSCALL_INTERRUPT_VECTOR_NUMBER * 0x4

install_syscall_isr:
  ; Setup an interrupt vector inside the ivt
  ; to point to the syscall_isr. After
  ; running this routine, interrupts that
  ; refer to the configured vector will
  ; trigger the syscall_isr.
  cli
  push es
  push di
  push ax
  ; Init segments.
  mov word di, 0x0000
  mov es, di
  ; Set up vector.
  mov word di, SYSCALL_INTERRUPT_VECTOR_ADDRESS
  mov word ax, syscall_isr
  stosw
  mov word ax, 0x0000
  stosw
  pop ax
  pop di
  pop es
  sti
  ret

syscall_isr:
  ; Execute the kernel service routine for
  ; the passed syscall number. Arguments
  ; of the called routines that would
  ; usually go into AX have to be provided
  ; via DX instead.
  ;
  ; Arguments:
  ;   AX = Syscall number.
  pusha
  cmp ax, 0x2
  je .clear_screen
  cmp ax, 0x3
  je .print_hex_word
  cmp ax, 0x4
  je .print_string
  cmp ax, 0x5
  je .print_char
  jmp .end
  .clear_screen:
    call hide_cursor
    call paint_screen_red
    jmp .end
  .print_hex_word:
    mov ax, dx
    call print_hex_word
    jmp .end
  .print_string:
    mov ax, dx
    call print_string
    jmp .end
  .print_char:
    mov ax, dx
    call print_char
    jmp .end
  .end:
  popa
  iret