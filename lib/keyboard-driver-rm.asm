; This module contains routines to handle keyboard key presses. It includes an isr for getting the ascii values of keys pressed as well as
; bootstrap routines to set up the isr in the interrupt vector table such that the keyboard hardware interrupt IRQ1 can trigger it.

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
  mov ax, 0x0                               ; Set up the data segment to the starting address of the ivt 0x0.
  mov ds, ax
  mov [bx], word keyboard_isr               ; An entry in the ivt is 4 bytes long. The first two bytes must contain the address offset of the isr.
  mov [bx+2], word 0x0                            ; The second two bytes must contain the respective segment address. Both form the complete address to jump to.
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
  ; scan_code_to_ascii_map. Since this is an
  ; isr, it has to be setup in the ivt using
  ; the install_keyboard_driver routine.
  ; 
  ; Returns:
  ;   DX = Scan code in DH and respective
  ;        ascii code in DL.
  cli
  push ax
  push bx
  xor ax, ax
  in al, 0x60                              ; Read current scan code from keyboard.
  cmp al, 0x2
  jl .end
  cmp al, 0x32
  jg .end
    mov bx, scan_code_to_ascii_map
    add bx, ax                             ; Calculate the map index/offset by adding the scan code to the starting address of the map.
    mov dl, [bx]                           ; Store the ascii code of the key pressed into dl.
    mov dh, al                             ; Store the respective scan code in dh.
  .end:
    mov al, 0x61                           ; Send end of interrupt
    out 20h, al                            ; to keyboard.
  pop bx
  pop ax
  sti
  iret

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