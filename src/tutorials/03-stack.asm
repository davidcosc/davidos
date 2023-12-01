; Prerequisites: "./01-basics.asm", "./02-rm-addressing.asm".
;
; For our initial boot sector the stack has already been defined by the BIOS. We can define it manually as well as seen below.

[bits 16]
SEGMENT_REGISTER_INIT equ 0x7c0            ; Equ just defines a constant value that is going to be replaced by the assembler where used. It kind of functions like a c #define.

main:
  mov bx, SEGMENT_REGISTER_INIT            ; => bb c0 07 ; We can not set segment registers directly. We store the desired value in another register and then copy it.              
  mov ss, bx                               ; => 8e d3 ; Setting the stack segment register (SS) to 0x7c0 results in our stack segment starting at address 0x7c00.
  mov bp, 0x0000                           ; => bd 00 00 ; We point our base pointer (BP) to the beginning of the code segment. The stack grows downward. We wont override our code.
  mov sp, bp                               ; => 89 ec ; We start with an empty stack at 0x7c00. The stack must not grow past 0x500. See "./images/important_memory_addresses.png".
  push 'a'                                 ; => 6a 61 ; We add the ACII code for 'a' = 61 to the top of the stack.
  mov ax, [bp-0x2]                         ; => 8b 46 fe ; We move the value at the bp-2 bytes offset address into ax.
  call print_char                          ; => e8 02 00 ; If our stack really grows downward we should see "a" printed to the screen when running the program.
  .loop:
    jmp .loop

[bits 16]
print_char:
  ; Write an ASCII character to the console.
  ;
  ; Arguments:
  ;   AL = ASCII character.
  ;
  pusha
  mov ah, 0xe
  int 0x10
  popa
  ret

padding:
  times 510-(padding-main) db 0x0
  dw 0xaa55