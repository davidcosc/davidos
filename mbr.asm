[org 0x7c00]                        ; tell the assembler where this code will be loaded, by convention this is address 0x7c00, see ./important_memory_addresses.png
main:
  mov bp, 0x7c00                    ; initialize stack base pointer to address 0x7c00 => we can use expand our stack downward from address 0x7c00 to 0x500, see ./important_memory_addresses
  mov sp, bp                        ; start with stack pointer at bp as well                 
  mov bx, start_boot_string
  call print_string                 ; basically call is a jmp that additionally pushes the return address to the stack (address following the one of the current instruction pointer)
  mov dx, 0x9abc
  call print_hex_double_byte

loop:                               ; jumping to a label is done using a relative jump which means we do not need to know the specific address in memory referenced by the loop label
  jmp loop                          ; offset calculation always begins at the byte immediatley after jmp instruction
                                    ; The first byte of a SHORT Jump is always EB and the second is a relative offset from 00h to 7Fh for Forward jumps
                                    ; and from 80h to FFh for Reverse (or Backward) jumps https://thestarman.pcministry.com/asm/2bytejumps.htm 

print_string:                       ; this function takes one parameter that must be stored in bx before calling => bx should point to the starting address of a string to be printed
  pusha                             ; push all current register values to the stack => save the state of all registers before running this function
  mov al, [bx]                      ; move the value stored at the address stored in bx to al (basically dereferencing)
  print_next_char:
    call print_char
    add bx, 0x1                     ; raise the string address stored in bx by one byte => point to the next char of the string
    mov al, [bx]
    cmp al, 0x0                     ; check if the value of the char is zero, the string terminating character by convention
    jne print_next_char             ; if the value is not zero, continue printing
  popa                              ; restore all registers to their state prior to running this function
  ret                               ; pop the return address off the stack and jmp to it / set instruction pointer to it

print_hex_double_byte:              ; this function takes a hex number as parameter that must be stored in dx before calling 
  pusha
  mov cx, 4                         ; we gonna work on all of the 4 nibbles contained in dx in sequence => we set our initial counter to 4 to keep track on how many nibbles we already worked on
  mov al, '0'                       ; print '0x' prefix before printing the char converted hex number
  call print_char
  mov al, 'x'
  call print_char
  next_nibble:
    mov bl, dh                      ; we will print all 4 nibbles starting with the most significant one (from left to right) e.g. for 0x9abc we start with 9 and work toward c
    shr bl, 4                       ; since the smallest unit we can copy between registers is a byte e.g 9a, we shift to the right by 4 to isolate the left most nibble e.g. 9
    mov al, bl                      ; we copy the nibble to al for printing e.g. this results in al containing 0x09
    call print_hex_nibble
    shl dx, 4                       ; we now shift dx to the left by 4 in order to remove the nibble we just printed e.g this results in bx containing 0xabc0, making a the left most nibble
    dec cx                          ; we are finished working on the first nibble, so we reduce our counter by one
    jnz next_nibble                 ; as long as our counter is not zero, we still have nibbles to work on, so we start working on the next nibble
  popa
  ret

print_hex_nibble:                   ; this funciton takes one nibble (4 bit value or byte value with its 4 high bits set to zero) as parameter that must be stored in al before calling
  pusha
  cmp al, 9
  jle digit
  letter:
    sub al, 0xa                     ; in ASCII Code the starting at e.g. the hex code for 'a' incremented by one gets us the hex code for 'b' which incremented by one again 
    add al, 'a'                     ; gets us the hex code for 'c' and so on, same goes for digits '0' to '9' => in order to print hex numbers greater 0x9 we reduce the number by 0xa
    jmp print_nibble                ; => this gives us the offsets for a to f respectively 0 to 5 which we can use to get the hex code / value for the letters 'a' to 'f' by increasing
  digit:                            ; the hex code for the letter 'a' by the offset => e.g to print 0xb we get the hex code of 'a' incremented by one (0xb minus ten)
    add al, '0'                     ; using the same principle we can use an offset as well to calculate hex codes for symbols '0' to '9'
  print_nibble:
    call print_char
    popa
    ret

print_char:                         ; this function takes one parameter that must be stored in al before calling => the value stored in al will be printed to the screen
  pusha
  mov ah, 0xe                       ; if register ah is set to 0xe
  int 0x10                          ; the BIOS video interrupt int 0x10 triggers a scrolling teletype BIOS routine
  popa
  ret

start_boot_string:
  db 'Booting...', 0xA, 0xD, 0x0               ; quotes are syntactic sugar => db 'Booting...', 0 and db 'B', 'ooting', '...', 0x0 are equivalent

padding:
  times 510-(padding-main) db 0     ; to make the BIOS recognize this sector as a boot block we must ensure it has a size of exactly 512 bytes
                                    ; => if the programm size (address of main up to address of padding) is smaller than 510 bytes we have to pad the remaining bytes with zeroes

dw 0xaa55                           ; the last 2 bytes must be the magic number 0xaa55 representing endianness