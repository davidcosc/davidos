[org 0x7c00]                        ; tell the assembler where this code will be loaded, by convention this is address 0x7c00, see ./important_memory_addresses.png
main:
  mov bp, 0x7c00                    ; initialize stack base pointer to address 0x7c00 => we can use expand our stack downward from address 0x7c00 to 0x500, see ./important_memory_addresses
  mov sp, bp                        ; start with stack pointer at bp as well                 
  mov bx, start_boot_string
  call print_string                 ; basically call is a jmp that additionally pushes the return address to the stack (address following the one of the current instruction pointer)
  mov bl, 0xa
  call print_hex_nibble
  mov bl, 0x9
  call print_hex_nibble

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

print_hex_nibble:                   ; this funciton takes one nibble (4 bit value or byte value with its 4 high bits set to zero) as parameter that must be stored in bl before calling
  pusha
  cmp bl, 9
  jle digit
  letter:
    sub bl, 0xa                     ; in ASCII Code the starting at e.g. the hex code for 'a' incremented by one gets us the hex code for 'b' which incremented by one again 
    add bl, 'a'                     ; gets us the hex code for 'c' and so on, same goes for digits '0' to '9' => in order to print hex numbers greater 0x9 we reduce the number by 0xa
    mov al, bl                      ; => this gives us the offsets for a to f respectively 0 to 5 which we can use to get the hex code / value for the letters 'a' to 'f' by increasing
    call print_char                 ; the hex code for the letter 'a' by the offset => e.g to print 0xb we get the hex code of 'a' incremented by one (0xb minus ten)
    popa
    ret
  digit:
    add bl, '0'                     ; using the same principle we can use an offset as well to calculate hex codes for symbols '0' to '9'
    mov al, bl
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
  db 'Booting...', 0                ; quotes are syntactic sugar => db 'Booting...', 0 and db 'B', 'ooting', '...', 0x0 are equivalent

padding:
  times 510-(padding-main) db 0     ; to make the BIOS recognize this sector as a boot block we must ensure it has a size of exactly 512 bytes
                                    ; => if the programm size (address of main up to address of padding) is smaller than 510 bytes we have to pad the remaining bytes with zeroes

dw 0xaa55                           ; the last 2 bytes must be the magic number 0xaa55 representing endianness