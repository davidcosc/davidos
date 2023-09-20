; prerequisites: basics.asm, rm-addressing.asm, stack.asm
[bits 16]
SEGMENT_REGISTER_INIT equ 0x7c0
CODE_SD_GDT_OFFSET equ sd_code - gdt
DATA_SD_GDT_OFFSET equ sd_data - gdt

main:
  mov bx, SEGMENT_REGISTER_INIT
  mov ds, bx                               ; data segment
  mov ss, bx                               ; stack segment
  mov es, bx                               ; extra segment overlap competely and all start at 0x7c00
  mov bp, 0x0000                           ; setting up the stack base at 0x7c00
  mov sp, bp                               ; start with an empty stack => start at base
  mov bx, welcome_string     
  call print_string
  mov dx, gdt_descriptor
  call print_hex_rm
  mov dx, CODE_SD_GDT_OFFSET
  call print_hex_rm
  mov dx, DATA_SD_GDT_OFFSET
  call print_hex_rm

; the global descriptor table (gdt) is a data structure used to define memory segments in x86 32 bit protected mode(pm)
; an entry in the table is called segment descriptor(sd) and has a size of 8 bytes
; the segment registers are used to point to these table entries => in pm segment registers store the index of a sd
; a sd consists of a 32 bit base address that defines where the segment begins in memory,
; a 20 bit segment limit which defines the size of the segment and various flags e.g. defining priviledge level or read/write permissions
; for some historic reason the base address and limit bits are split into fragments,
; for the full sd structure see ./images/segment_descriptor.png
; the first sd of the gdt must be an invalid null descriptor with all 8 bytes set to zero
; this is done to catch errors when attempting to access an address through a misconfigured segment register 
; => if an addressing attempt is made with the null descriptor the cpu raises an error/interrupt
; e.g we had ds set to 0x0000 in rm and forgot to point it to an sd before switching to pm
gdt:
  sd_null:                                 
    times 8 db 0x0                         
  sd_code:                                 
    times 2 db 0xff                        ; limit (bits 0-15 of first 4 bytes) for the exact meaning of sd fields and flags see ./images/segment_descriptor_fields.png
    times 2 db 0x0                         ; base (bits 16-31 of first 4 bytes)
    db 0x0                                 ; base (bits 0-7 of second 4 bytes)
    db 10011010b                           ; P=1, DPL=00, S=1, Type=(Code=1, Conforming=0, Readable=1, Accessed=0) for the exact meaning of type flags see ./images/segment_types.png
    db 11001111b                           ; G=1, DB=1, unnamed/unused=0, A=0, limit (bits 16-19 of second 4 bytes)
    db 0x0                                 ; base (bits 24-31 of second 4 bytes)
  sd_data:                                 
    times 2 db 0xff                        ; limit (bits 0-15 of first 4 bytes)
    times 2 db 0x0                         ; base (bits 16-31 of first 4 bytes)
    db 0x0                                 ; base (bits 0-7 of second 4 bytes)
    db 10010010b                           ; P=1, DPL=00, S=1, Type=(Code=0, Expand down=0, Write=1, Accessed=0)
    db 11001111b                           ; G=1, DB=1, unnamed/unused=0, A=0, limit (bits 16-19 of second 4 bytes)
    db 0x0                                 ; base (bits 24-31 of second 4 bytes)

gdt_descriptor:                            ; the cpu needs to know not only about the start address of the gdt, but also its size => we pass it this info using this structure
    dw gdt_descriptor - gdt - 1            ; the size of the gdt, for some reason always less one than the actual size
    dd gdt                                 ; this is defined as double word, thus 32 bits for usage in protected mode

loop:
  jmp loop
       
print_string:                              ; this function takes one parameter that must be stored in bx before calling => bx should point to the starting address of a string
  pusha
  mov al, [bx]
  print_next_char:       
    call print_char       
    add bx, 0x1                            ; raise the string address stored in bx by one byte => point to the next char of the string
    mov al, [bx]       
    cmp al, 0x0                            ; check if the value of the char is zero, the string terminating character by convention
    jne print_next_char                    ; if the value is not zero, continue printing
  popa
  ret       

%include "debug_helpers/rm-helpers.asm"

print_char:                                ; this function takes one parameter that must be stored in al before calling => the value stored in al will be printed to the screen
  pusha
  mov ah, 0xe
  int 0x10
  popa
  ret
       
welcome_string:
  db 'Davidos is in 16 bit mode!', 0xA, 0xD, 0x0  ; on a side note, for the assembler db 'abc', 0x0 and db 'a', 'b', 'c', 0x0 are equivalent
       
padding:       
  times 510-(padding-main) db 0x0
       
dw 0xaa55