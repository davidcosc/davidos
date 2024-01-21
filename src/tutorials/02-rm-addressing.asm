; Prerequisites: "./01-basics.asm". 
; 
; How memory addresses are calculated using segment registers and offset values can best be shown using an example.
; By convention the BIOS places our boot sector code at address 0x7c00. See "./images/important_memory_addresses.png".
; To do so it also sets certain segment registers. In our case their values default to 0x0000. The base of the address space.
; For our example we want to access a data value. Hence we make use of the DS register.
; To visualize important values of registers, we use the print_hex_rm function.
; First we print the value of DS to ensure, the BIOS actually set it to 0x0000.
; We then print the offset value our "data_value" label was replaced by during assembly.
; Remember that the label value is calculated based on the location counter during assembly.
; The address where our code was loaded to by BIOS has no effect on the label value/offset.
; Next we attempt to print the value referenced by the "data_value" label. 
; This does not result in the expected value 0x1111 being printed, but some random value.
; To understand what is happening here, we can make use of segmentation address calculation formula.
; 0x0000(DS) * 16 + 0x0020 ("data_value" label offset), results in an absolute address of 0x0020.
; We know our code was loaded to 0x7c00. Which is way off of 0x0020.
; To fix this, we now set our DS register value to 0x07c0.
; Calculating 0x07c0(DS) * 16 gets us 0x7c00, the starting address our code was loaded to. Adding our label offset now will result
; in the expected address, where our value is stored.
;
; One special case to mention regarding segments is the code segment definied by the code segment register (CS) and the instruction pointer (IP).
; It is special, because we do not manually set the value of CS:IP. In fact we can not do so, because this could completely mess up what instructions the
; cpu should load next. CS:IP can only be set together by far jumping.
;
; On a side note. It is important to understand, that not all instructions in x86 work with absolute memory addresses.
; A good example would be the "short jmp" instruction, which calculates where to jump based on the relative distance to the destination in bytes.

[bits 16]
bootsector:
  mov dx, ds                               ; If set by BIOS correctly, 
  call print_hex_rm                        ; this prints 0x0000 to the screen.
  mov dx, data_value
  call print_hex_rm                        ; Should print the label value 0x0020.
  mov dx, [data_value]
  call print_hex_rm                        ; Should print some random hex value. The one stored at address
  mov dx, 0x07c0                           ; We can not set segment registers directly. We therefore set DX
  mov ds, dx                               ; and then copy the value over to DS.
  mov dx, [data_value]
  call print_hex_rm                        ; Should print the actual value referenced by "data_value", 0x1111.
  .loop:
    jmp .loop

data_value:                                ; Label value 0x0020.
  dw 0x1111

[bits 16]
print_hex_rm:
  ; Write a 16 bit hex number to the screen.
  ;
  ; Arguments:
  ;   DX = Hex number.
  ;
  pusha
  mov cx, 4                                ; We work on all 4 nibbles in sequence. We set our initial counter to 4 to keep track of the nibbles we already worked on.
  mov al, '0'                              ; Print '0x' hex number prefix.
  call print_char       
  mov al, 'x'       
  call print_char       
  next_nibble:       
    mov bl, dh                             ; We start with the most significant nibble (from left to right) e.g. for 0x9abc we start with 9 and work toward c.
    shr bl, 4                              ; The smallest unit we can copy between registers is a byte e.g 9a. We shift to the right by 4 to isolate the left most nibble e.g. 9.
    mov al, bl
    call print_hex_nibble
    shl dx, 4                              ; We shift dx to the left by 4 in order to remove the nibble we just printed.
    dec cx                                 ; We are finished working on the first nibble. We reduce our counter by one.
    jnz next_nibble                        ; As long as our counter is not zero, we still have nibbles to work on. We start working on the next nibble.
  popa
  ret

[bits 16]
print_hex_nibble:
  ; Write a nibble (or byte value with its
  ; 4 high bits set to zero) to the screen.
  ; It will be output in hexadecimal format.
  ;
  ; In ASCII Code symbols are stored in a
  ; fixed order. E.g. the hex code for 'a'
  ; incremented by one gets us the hex code
  ; for 'b' and so on. Same goes for symbols
  ; 0 to 9.
  ;
  ; Arguments:
  ;   AL = Nibble.
  ;
  pusha
  cmp al, 9                                ; If the nibble number is smaller than nine,
  jle digit                                ; we want to print a digit between 0 and 9.
  letter:                                  ; Otherwise we want to print a letter between a and f.
    sub al, 0xa                            ; In order to identify the letter to print, we subtract al by ten. A remainder of 0 would mean printing an 'a', 1 a 'b' and so on.
    add al, 'a'                            ; Adding the offset to our first letter ASCII code gives us the ASCII code for the letter we want to print.
    jmp print_nibble
  digit:
    add al, '0'                            ; Adding the offset to our first digit ASCII code gives us the ASCII code for the digit we want to print.
  print_nibble:
    call print_char
    popa
    ret

[bits 16]
print_char:
  ; Write an ASCII character to the screen.
  ;
  ; Arguments:
  ;   AL = ASCII character.
  ;
  pusha
  mov ah, 0xe
  int 0x10
  popa
  ret

bootsector_padding:
  times 510-(bootsector_padding-bootsector) db 0x0
  dw 0xaa55