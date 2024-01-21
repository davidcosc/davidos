; This is an miniature bootable example assembly program intended to familiarize us with some nasm assembly syntax, important commands
; and concepts we are going to use in our actual os later on.
;
; Info about all x86 nasm details can be found inside the Intel sdm inside the "docs" directory.
;
; Some terminology:
;   r/m => A register or memory address.
;   /r => Effective address encoded in up to three parts. A ModR/M byte, an optional SIB byte, and an optional byte, word or doubleword displacement field.
;   +r => Add register number e.g. al=0 ax=0 bl=3.
;   rb, rw => One of the operands to the instruction is an immediate value/hard coded address. The difference between this value and the address of the end of the
;             instruction is to be encoded as a byte, word (e.g. backwards ff-distance, forward 00+distance).
;   ib, iw => An immediate/hard coded byte or word.
;
; In particular we should familiarize us with the following instructions:
;   mov — move
;     Copies the data item referred to by its second operand (i.e. register contents, memory contents, or a constant value)
;     into the location referred to by its first operand (i.e. a register or memory).
;     Opcodes of variants we use:
;       mov r/m8,reg8       88 /r
;       mov r/m16,reg16     89 /r
;       mov reg8,r/m8       8a /rrw
;       mov reg16,r/m16     8b /r
;       mov reg8,imm8       b0+r ib
;       mov reg16,imm16     b8+r iw
;   jmp — jump
;     Jumps to a given address. The address may be specified as an absolute segment and offset or as a relative jump within the current segment.
;     Opcodes of variants we use:
;       jmp [SHORT] imm     eb rb
;   call — call
;     Calls a subroutine by means of pushing the current instruction pointer (IP) and optionally CS as well onto the stack and then jumping to a given address.
;     The stack is just another area in memory. We will cover the stack in detail later on. We will provide a separate tutorial inside "./03-stack.asm".
;     Opcodes of variants we use:
;       call imm            e8 rw
;   pusha — push all
;     Pushes in succession, AX, CX, DX, BX, SP, BP, SI and DI on the stack, decrementing the stack pointer by a total of 16.
;     Opcode:
;       pusha               60
;   popa — pop all
;     Pops a word from the stack into each of, successively, DI, SI, BP, nothing (it discards a word from the stack which was a placeholder for SP), BX, DX, CX and AX.
;     Opcode:
;       popa                61
;   ret — return
;     Pop IP from the stack and transfer control to the new address.
;     Opcode:
;       ret                 c3
;   int — interrupt
;     Causes a software interrupt through a specified vector number from 0 to 255. Interrupts are a mechanism that allow the CPU temporarily to halt what it is doing and
;     run some other, higher-priority instructions before returning to the original task. An interrupt could be raised either by a software instruction (e.g. int 0x10) or by some
;     hardware device that requires high-priority action (e.g. to read some incoming data from a network device). We will cover interrupts in detail later on. However, this explanation
;     should suffice for the example below.
;     
;     Opcode:
;       int imm8            cd ib

[bits 16]                                  ; We tell the assembler, that we want our code assembled in 16 bit mode.
bootsector:                                ; A label like "main" represents or points to the address/offset of the next instruction directly below it. Labels must be unique.
  mov al, 0x99                             ; mov reg8,imm8 => b0 99
  mov ax, 0xffff                           ; mov reg16,imm16 => b8 ff ff
  mov bl, al                               ; mov r/m8,reg8 => 88 c3
  mov bx, ax                               ; mov r/m16,reg16 => 89 c3 
  mov bl, [.dat]                           ; mov reg8,r/m8 => 8a 1e 16 00 ; This is like dereferencing. We want to access the value stored at the address of .dat.
  mov bl, .dat                             ; mov reg8,imm8 => b3 16
  mov al, 'a'                              ; => b0 61 ; Quotes tell the assembler to use respective ASCII code.
  call print_char                          ; call imm => e8 05 00
  jmp .loop                                ; jmp [SHORT] imm => eb 01
  .dat:                                    ; A label prefixed with a dot acts as a sublabel. Sublabels only must be unique within the context of their parent label.
    db 0xff                                ; => ff
  .loop:
    jmp .loop                              ; => eb fe

[bits 16]
print_char:
  ; Write an ASCII character to the screen.
  ;
  ; Arguments:
  ;   AL = ASCII character.
  ;
  pusha                                    ; 60
  mov ah, 0xe                              ; => b4 0e ; 0xe in AH refers to the scrolling teletype BIOS routine in context of interrupt 0x10.
  int 0x10                                 ; int imm8 => cd 10 ; We are in real mode with the interrupt vector already setup by the BIOS. 0x10 refers to the video interrupt.
  popa                                     ; 61
  ret                                      ; c3

padding:       
  times 510-(padding-bootsector) db 0x0    ; To make the BIOS recognize this sector as a boot block we must ensure it has a size of exactly 512 bytes.
                                           ; If the programm size is smaller than 510 bytes we have to pad the remaining bytes with zeros.     
  dw 0xaa55                                ; The last 2 bytes must be the magic number 0xaa55 representing endianness.