; prerequisites: basics.asm
; learning about addressing and segmentation in 16 bit real mode is best done using an example
;   lets take a look at the "mov ax, loop" code below
;   "mov ax, loop" in our example is assembled to b0 02
;   "02" however is not the actual address the loop label points to but rather an offset => the loop label points to the third byte (offset 2 we start counting from 0) of our code 
;   but how does the cpu know the actual base address / starting address of our code from which the relative offset is being calculated?
;   the answer is segment registers, see ./x86_registers.png
;   in 16 bit mode these registers are used to calculate the effective address of e.g. the "loop" label as follows
;   "value stored in the segment register e.g. DS" * 16 + "offset e.g. 2 for the loop label"
;   by convention the BIOS places our boot sector code at address 0x7c00, see ./important_memory_addresses.png
;   this means using the formula above, we can calculate the effective address our loop label points to as follows
;   0x7c0 (the value stored in DS, note the one missing zero) * 16 which gives us the starting address of our code 0x7c00 plus 2 => 0x7c02
;   this means the BIOS must have set a segment register used for calculating the label address to the value of 0x7c0 for us, since this results in the "jmp loop"
;   instruction being at offset 2
; there are different types of segments used for different purposes, see ./x86_registers
;   one special case to note is the code segment definied by the code segment register (CS) and the instruction pointer (IP)
;   it is special, because we do not manually set the value of CS:IP, in fact we should/can not do so, because this could completely mess up what instructions the
;   cpu should load next => CS:IP should only be set by far jumping 
; segments can overlap e.g. if DS is set to 0x7c0 and we far jump to 0x7c0:0x0000, both the data segment and the code segment start at address 0x7c00
; => they refer to the same area of memory but are just used for differnt things e.g CS:IP for tracking the current instruction address and DS:offset for
; identifying data e.g. pointed to by a label like declared strings etc.
; to see how we can use the stack segment register (SS) in combination with the stack pointer (SP) and base pointer (BP) registers to set up our own stack see stack.asm
[bits 16]
main:
  mov al, loop                        ; => b0 02
  
loop:
  jmp loop                            ; => eb fe

padding:
  times 510-(padding-main) db 0x0

dw 0xaa55