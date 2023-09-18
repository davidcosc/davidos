; prerequisites: basics.asm, rm-addressing.asm
; one of the problems of low level programming is, that the cpu has a limited numbr of registers and therefore limited space for temporarily storing variables, values etc.
; the stack is a simple solution to this problem, it is a memory area defined by a starting address pointed to by a so called base pointer (bp) and another stack pointer (sp)
; that points to the top of the stack
; the stack was explicitly designed this way with the following assumptions in mind:
;   - we only use it to store things temporarily
;   - we do not really care where temporary values are stored (we do not want to need to know the exact address things are stored)
;   - we want to easily store and retrieve things from the stack
; some intersting features of the stack are:
;   - there are push and pop instructions to easily add and retrieve values from the top of the stack
;   - the stack grows downward => a pushed value gets stored below the address of bp and sp is decremented by the values size
;   - we can not push and pop single bytes to the stack, but e.g. in 16 bit mode only 16 bit chunks at a time
; for our boot sector the stack has already been defined by the BIOS, but we can define it manually as well as seen below
[bits 16]
SEGMENT_REGISTER_INIT equ 0x7c0            ; equ just defines a constant value that is going to be replaced by the assembler where used, like a c #define

main:
  mov bx, SEGMENT_REGISTER_INIT            ; => bb c0 07 ; we can not set segment registers directly, so we store the desired value in another register and then copy it              
  mov ss, bx                               ; => 8e d3 ; setting the stack segment register (SS) to 0x7c0 results in our stack segment starting at address 0x7c00
  mov bp, 0x0000                           ; => bd 00 00 ; we point our base pointer (BP) to the beginning of the code segment => stack grows downward, we wont override our own code
  mov sp, bp                               ; => 89 ec ; start with empty stack at 0x7c00; the stack must not grow past 0x500, see ./images/important_memory_addresses.png
  push 'a'                                 ; => 6a 61 ; add the ACII code for 'a' = 61 to the top of the stack
  mov ax, [bp-0x2]                         ; => 8b 46 fe ; move the value at the bp-2 bytes offset address into ax
  call print_char                          ; => e8 02 00 ; if our stack really grows downward we should see a printed to the screen when running the program
  
loop:
  jmp loop

print_char:
  pusha
  mov ah, 0xe
  int 0x10
  popa
  ret

padding:
  times 510-(padding-main) db 0x0

dw 0xaa55