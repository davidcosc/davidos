; this is an miniature bootable example assembly program intended to familiarize us with some nasm assembly syntax,
; important commands and concepts we are gonna use in our actual mbr
; we can assemble our program e.g. using the command nasm basics.asm -f bin -o basics.bin
; and run it using qemu-system-x86_64 basics.bin
; 
; instructions in nasm e.g. mov ax, 5 usually follow the structure of <instruction> <target> [, <source>] and translate to so called opcodes
; opcodes can be used to find our instructions in the generated hex code later e.g. via command od -t x1 -A n basics.bin
;
; info about all x86 details can be found at https://redirect.cs.umbc.edu/courses/pub/www/courses/undergraduate/CMPE310/Fall09/cpatel2/nasm/nasmdoca.html#section-A.2.1
;
; some terminology:
;   r/m => register or memory address
;   /r => effective address encoded in up to three parts: a ModR/M byte, an optional SIB byte, and an optional byte, word or doubleword displacement field
;   +r => add register number e.g. al=0 ax=0 bl=3, ib or iw => hard coded byte or word value
;   rb, rw => one of the operands to the instruction is an immediate value/hard coded address
;          => the difference between this value and the address of the end of the instruction is to be encoded as a byte, word (e.g. backwards ff-distance, forward 00+distance)
;   ib, iw => immediate/hard coded byte or word
;
; for starters we should familiarize us with the following instructions:
;   mov — move
;     copies the data item referred to by its second operand (i.e. register contents, memory contents, or a constant value)
;     into the location referred to by its first operand (i.e. a register or memory)
;     opcodes of variants we use:
;       mov r/m8,reg8       88 /r
;       mov r/m16,reg16     89 /r
;       mov reg8,r/m8       8a /r
;       mov reg16,r/m16     8b /r
;       mov reg8,imm8       b0+r ib
;       mov reg16,imm16     b8+r iw
;   jmp — jump
;     jumps to a given address, the address may be specified as an absolute segment and offset, or as a relative jump within the current segment
;     opcodes of variants we use:
;       jmp [SHORT] imm     eb rb
;   call — call
;     calls a subroutine, by means of pushing the current instruction pointer (IP) and optionally CS as well on the stack, and then jumping to a given address
;     opcodes of variants we use:
;       call imm            e8 rw
;   pusha — push all
;     pushes in succession, AX, CX, DX, BX, SP, BP, SI and DI on the stack, decrementing the stack pointer by a total of 16
;     opcode:
;       pusha               60
;   popa — pop all
;     pops a word from the stack into each of, successively, DI, SI, BP, nothing (it discards a word from the stack which was a placeholder for SP), BX, DX, CX and AX
;     opcode:
;       popa                61
;   ret — return
;     pop IP from the stack and transfer control to the new address
;     opcode:
;       ret                 c3
;   int — interrupt
;     causes a software interrupt through a specified vector number from 0 to 255
;     opcode:
;       int imm8            cd ib
[bits 16]                                  ; tell the assembler, that we want our code assembled in 16 bit mode
main:
  mov al, 0x99                             ; mov reg8,imm8 => b0 99
  mov ax, 0xffff                           ; mov reg16,imm16 => b8 ff ff
  mov bl, al                               ; mov r/m8,reg8 => 88 c3
  mov bx, ax                               ; mov r/m16,reg16 => 89 c3 
  mov bl, [dat]                            ; mov reg8,r/m8 => 8a 1e 16 00
  mov bl, dat                              ; mov reg8,imm8 => b3 16
  mov al, 'a'                              ; => b0 61
  call print_char                          ; call imm => e8 05 00
  jmp loop                                 ; jmp [SHORT] imm => eb 01

dat:
  db 0xff                                  ; => ff

loop:
  jmp loop                                 ; => eb fe

print_char:                                ; this function takes one parameter that must be stored in al before calling => the value stored in al will be printed to the screen
  pusha                                    ; 60
  mov ah, 0xe                              ; => b4 0e => 0xe in ah refers to the scrolling teletype BIOS routine if int 0x10 is called after
  int 0x10                                 ; int imm8 => cd 10 => we are in real mode with the interrupt vector already setup by the BIOS and 0x10 referring to the video interrupt
  popa                                     ; 61
  ret                                      ; c3

padding:       
  times 510-(padding-main) db 0x0          ; to make the BIOS recognize this sector as a boot block we must ensure it has a size of exactly 512 bytes
                                           ; => if the programm size is smaller than 510 bytes we have to pad the remaining bytes with zeros
       
dw 0xaa55                                  ; the last 2 bytes must be the magic number 0xaa55 representing endianness