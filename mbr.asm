[org 0x7c00]                        ; tell the assembler where this code will be loaded, by convention this is address 0x7c00, see ./important_memory_addresses.png
main:
  mov bp, 0x7c00                    ; initialize stack base pointer to address 0x7c00 => we can use expand our stack downward from address 0x7c00 to 0x500, see ./important_memory_addresses
  mov sp, bp                        ; start with stack pointer at bp as well                 
  mov bx, start_boot_string
  call print_string                 ; basically call is a jmp that additionally pushes the return address to the stack (address following the one of the current instruction pointer)

loop:                               ; jumping to a label is done using a relative jump which means we do not need to know the specific address in memory referenced by the loop label
  jmp loop                          ; offset calculation always begins at the byte immediatley after jmp instruction
                                    ; The first byte of a SHORT Jump is always EB and the second is a relative offset from 00h to 7Fh for Forward jumps
                                    ; and from 80h to FFh for Reverse (or Backward) jumps https://thestarman.pcministry.com/asm/2bytejumps.htm

print_string:                       ; this function takes one parameter that must be stored in bx before calling => bx should point to the starting address of a string to be printed
  pusha                             ; push all current register values to the stack => save the state of all registers before running this function
  print_next_char:
    mov al, [bx]                    ; move the value stored at the address stored in bx to al (basically dereferencing)
    cmp al, 0x0                     ; check if the value is zero, the string terminating character by convention
    je end_print                    ; if the value is zero, stop printing
    call print_char                 ; print the value otherwise
    add bx, 0x1                     ; raise the string address stored in bx by one byte => point to the next char of the string
    jmp print_next_char             ; repeat
  end_print:
    popa                            ; restore all registers to their state prior to running this function
    ret                             ; pop the return address off the stack and jmp to it / set instruction pointer to it

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