print_hex_rm:                              ; this function takes a hex number as parameter that must be stored in dx before calling 
  pusha       
  mov cx, 4                                ; we ware going to work on all of the 4 nibbles contained in dx in sequence => we set our initial counter to 4 to keep track
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