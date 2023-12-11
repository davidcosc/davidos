; This module contains routines to handle keyboard key presses. It includes an isr for getting the ascii values of keys pressed as well as
; bootstrap routines to set up the isr in the interrupt vector table such that the keyboard hardware interrupt IRQ1 can trigger it.

PS2_CONTROLLER_DATA_IO_PORT equ 0x0060
PIC_8259A_EOI_PORT equ 0x0020
PIC_8259A_EOI_COMMAND equ 0x20
ESC_SCAN_CODE equ 0x01
ENTER_SCAN_CODE equ 0x1c
UP_ARROW_SCAN_CODE equ 0x48
DOWN_ARROW_SCAN_CODE equ 0x50

[bits 16]
install_keyboard_driver:
  ; Setup an interrupt vector inside the ivt
  ; to point to the keyboard_isr. After
  ; running this routine, interrupts that
  ; refer to the configured vector will
  ; trigger the keyboard_isr.
  ;
  ; Arguments:
  ;   BX = Address of the interrupt vector
  ;        the keyboard_isr should be set to
  cli
  push ds
  push ax
  push bx
  mov word ax, 0x0000                      ; Set up the data segment to the starting address of the ivt 0x0.
  mov ds, ax
  mov word [bx], keyboard_isr              ; An entry in the ivt is 4 bytes long. The first two bytes must contain the address offset of the isr.
  mov word [bx+2], 0x0                     ; The second two bytes must contain the respective segment address. Both form the complete address to jump to.
  pop bx
  pop ax
  pop ds
  sti
  ret

[bits 16]
keyboard_isr:
  ; Interrupt service routine that handles
  ; keyboard hardware interrupts. It
  ; retrieves the scan code of a pressed key
  ; from the keyboard and maps / converts it
  ; to its ascii code based on the below 
  ; scan_code_to_ascii_map. The scan code
  ; and ascii code are stored in the
  ; pressed_key_buffer.
  ;
  ; Use the install_keyboard_driver to set
  ; this isr up in the ivt.
  cli
  push dx
  push ax
  push bx
  push ds
  xor ax, ax
  mov ds, ax
  mov dx, PS2_CONTROLLER_DATA_IO_PORT
  in byte al, dx                           ; Read current scan code from keyboard.
  cmp al, 0x1                              ; Each key can generate two scan codes. One for key press and one for key release.
  jnae .end                                ; We are only interested in pressed keys. We filter out released keys, so we do not
  cmp al, 0x80                             ; change our buffer on releasing the key. 
  jae .end
    mov word bx, scan_code_to_ascii_map
    add bx, ax                             ; Calculate the map index/offset by adding the scan code to the starting address of the map.
    shl ax, 8                              ; Move scan code from AL to AH.
    mov byte al, [bx]                      ; Store the ascii code of the key pressed into al.
    mov word [pressed_key_buffer], ax      ; Store ascii code in the pressed key buffer.
  .end:
    mov word dx, PIC_8259A_EOI_PORT
    mov byte al, PIC_8259A_EOI_COMMAND
    out byte dx, al
  pop ds
  pop bx
  pop ax
  pop dx
  sti
  iret

pressed_key_buffer:
  db 0x00

scan_code_to_ascii_map:
  ; The following bytes define a vector of
  ; ascii character codes. Each key on a
  ; keyboard is assigned a so called scan
  ; code. For a pressed key, this code can
  ; be retrieved via one of the keyboards 
  ; I/O ports and then mapped to an ascii
  ; value using this vector. The byte offset
  ; based on the scan_code_to_ascii_map
  ; label for a character is chosen based
  ; on the scan code of the keyboard key
  ; that refers to this character for a
  ; german keyboard layout. Using the scan
  ; code as index we can get the respective
  ; ascii code for that key.
  db 0x0
  db 0x0
  db '1'
  db '2'
  db '3'
  db '4'
  db '5'
  db '6'
  db '7'
  db '8'
  db '9'
  db '0'
  db 0x0
  db 0x0
  db 0x0
  db 0x0
  db 'q'
  db 'w'
  db 'e'
  db 'r'
  db 't'
  db 'z'
  db 'u'
  db 'i'
  db 'o'
  db 'p'
  times 0x4 db 0x0
  db 'a'
  db 's'
  db 'd'
  db 'f'
  db 'g'
  db 'h'
  db 'j'
  db 'k'
  db 'l'
  times 0x5 db 0x0
  db 'y'
  db 'x'
  db 'c'
  db 'v'
  db 'b'
  db 'n'
  db 'm'