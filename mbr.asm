[bits 16]
BOOT_SECTOR_START_ADDRESS equ 0x7c0        ; by convention the bios loads the mbr to address 0x7c00, for the initial memory setup see ./important_memory_addresses.png
                                           ; in real mode physical addresses are calculated based on the segment address * 16 + offset
                                           ; e.g. if the assembled programm bb c0 07 8e db 8e d3 8e c3 bd 00, was stored at 0x7c00 with the ds segment address set to 0x07c0
                                           ; we would get the bd 00 instruction at address ds:0x0009
                                           ; or 0x7c00(0x07c0 * 16) with an added offset of 9 since bd is the 10th byte(we start counting from zero)
main:    
  mov bx, BOOT_SECTOR_START_ADDRESS        ; we can not set segment registers directly, so we store the in another register and then copy it                 
  mov ds, bx                               ; we also do not set the code register since it is only ment to change automatically in combination with the 
  mov ss, bx                               ; instruction pointer when using a far jump
  mov es, bx                               ; with all segment registers set to 0x7c0 and code loaded to 0x7c00 printing the hex address/offset of our main label should return 0x0000
  mov bp, 0x0000                           ; our stack segment starts at 0x7c00 so we set the stack and base pointer to address 0x0000 to ensure at the beginning
  mov sp, bp                               ; since the stack grows downward we wont overlap with our mbr, but the stack must not grow past 0x500, see ./important_memory_addresses                
  mov bx, welcome_string     
  call print_string
  mov dx, global_descriptor_table
  call print_hex_rm
  mov dx, sd_null
  call print_hex_rm

global_descriptor_table:                   ; the gdt is a data structure used to define memory segments in x86 32 bit protected mode(pm)
                                           ; an entry in the table is called segment descriptor(sd) and has a size of 8 bytes
                                           ; the segment registers are used to point to these table entries => in pm segment registers store the index of a sd
                                           ; a sd consists of a 32 bit base address that defines where the segment begins in memory,
                                           ; a 20 bit segment limit which defines the size of the segment and various flags e.g. defining priviledge level or read/write permissions
                                           ; for some historic reason the base address and limit bits are split into fragments, for the full sd structure see ./segment_descriptor.png
                                           ; the first sd of the gdt must be an invalid null descriptor with all 8 bytes set to zero
                                           ; this is done to catch errors when attempting to access an address through a misconfigured segment register 
                                           ; => if an addressing attempt is made with the null descriptor the cpu raises an error/interrupt
                                           ; e.g we had ds set to 0x0000 in rm and forgot to point it to an sd before switching to pm
  sd_null:                                 
    times 8 db 0x0                         
  sd_code:                                 
    times 2 db 0xff                        ; limit (bits 0-15 of first 4 bytes), for the exact meaning of sd fields and flags see ./segment_descriptor_fields.png
    times 2 db 0x0                         ; base (bits 16-31 of first 4 bytes)
    db 0x0                                 ; base (bits 0-7 of second 4 bytes)
    db 10011010b                           ; 1st flags , type flags
    db 11001111b                           ; 2nd flags , limit (bits 16-19 of second 4 bytes)
    db 0x0                                 ; base (bits 24-31 of second 4 bytes)
    
loop:
  jmp loop
       
print_string:                              ; this function takes one parameter that must be stored in bx before calling => bx should point to the starting address of a string
  pusha
  mov al, [ds:bx]                          ; move the value stored at the address stored in bx to al (basically dereferencing)
  print_next_char:       
    call print_char       
    add bx, 0x1                            ; raise the string address stored in bx by one byte => point to the next char of the string
    mov al, [ds:bx]       
    cmp al, 0x0                            ; check if the value of the char is zero, the string terminating character by convention
    jne print_next_char                    ; if the value is not zero, continue printing
  popa
  ret
       
print_hex_rm:                              ; this function takes a hex number as parameter that must be stored in dx before calling 
  pusha       
  mov cx, 4                                ; we gonna work on all of the 4 nibbles contained in dx in sequence => we set our initial counter to 4 to keep track
  mov al, '0'                              ; print '0x' prefix before printing the char converted hex number
  call print_char       
  mov al, 'x'       
  call print_char       
  next_nibble:       
    mov bl, dh                             ; we will print all 4 nibbles starting with the most significant one (from left to right) e.g. for 0x9abc we start with 9 and work toward c
    shr bl, 4                              ; since the smallest unit we can copy between registers is a byte e.g 9a, we shift to the right by 4 to isolate the left most nibble e.g. 9
    mov al, bl                             ; we copy the nibble to al for printing e.g. this results in al containing 0x09
    call print_hex_nibble       
    shl dx, 4                              ; we now shift dx to the left by 4 in order to remove the nibble we just printed e.g this results in bx containing 0xabc0
    dec cx                                 ; we are finished working on the first nibble, so we reduce our counter by one
    jnz next_nibble                        ; as long as our counter is not zero, we still have nibbles to work on, so we start working on the next nibble
  popa       
  ret       
       
print_hex_nibble:                          ; this funciton takes one nibble (or byte value with its 4 high bits set to zero) as parameter that must be stored in al before calling
  pusha       
  cmp al, 9       
  jle digit       
  letter:       
    sub al, 0xa                            ; in ASCII Code the starting at e.g. the hex code for 'a' incremented by one gets us the hex code for 'b' which incremented by one again 
    add al, 'a'                            ; gets us the hex code for 'c' and so on, same goes for digits '0' to '9' => in order to print hex numbers greater 0x9 we reduce the
    jmp print_nibble                       ; number by 0xa => this gives us the offsets for a to f respectively 0 to 5 which we can use to get the hex code/value for the
  digit:                                   ; letters 'a' to 'f' by increasing the hex code for the letter 'a' by the offset => e.g to print 0xb we get the hex code of 'a'
    add al, '0'                            ; incremented by one (0xb minus ten), also using the same principle we can calculate hex codes for symbols '0' to '9'
  print_nibble:       
    call print_char       
    popa       
    ret       
       
print_char:                                ; this function takes one parameter that must be stored in al before calling => the value stored in al will be printed to the screen
  pusha
  mov ah, 0xe
  int 0x10
  popa
  ret
       
welcome_string:
  db 'Welcome to Davidos!', 0xA, 0xD, 0x0  ; write bytes to memory, quotes are syntactic sugar => db 'abc', 0x0 and db 'a', 'b', 'c', 0x0 are equivalent
       
padding:       
  times 510-(padding-main) db 0x0
       
dw 0xaa55