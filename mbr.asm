; Prerequisites: "basics.asm", "rm-addressing.asm", "stack.asm".
;
; The following code sets up a 512 byte boot sector. First off we start in 16 bit real mode and print a welcome message to the screen.
; We then define a global descriptor table and switch the cpu to 32 bit protected mode. Once we arrive in protected mode,
; we print another message to the screen.
;
; The global descriptor table (GDT) is a data structure used to define memory segments for x86 32 bit protected mode (PM).
; An entry in the table is called segment descriptor (SD) and has a size of 8 bytes.
; Segment registers are used to point to these table entries. In protected mode segment registers store the index of a SD within the GDT.
; A sd consists of a 32 bit base address that defines where the segment begins in memory,
; a 20 bit segment limit which defines the size of the segment and various flags e.g. defining priviledge level or read/write permissions.
;
; For backwards compatibility to old cpus, the base address and limit bits are split into fragments.
; For the full SD structure, see "./images/segment_descriptor.png".
;
; The first SD of the gdt must be an invalid null descriptor with all 8 bytes set to zero.
; This is done to catch errors when attempting to access an address through a misconfigured segment register. 
; If an addressing attempt is made with the null descriptor the cpu raises an error/interrupt.
;
; For simplicity we only define two more SDs, a code and a data segment descriptor. We also use the so called flat model.
; All segments will start at address 0x0 and overalp completely.
;
; In case you need to debug print some addresses or other hex numbers in real mode, pls add %include "debug_helpers/rm-helpers.asm".

[org 0x7c00]
[bits 16]
real_mode:
  mov bp, 0x7c00  
  mov sp, bp
  call configure_video_mode
  mov bx, welcome_string_rm     
  call print_string_rm
  cli
  lgdt [gdt_descriptor]
  mov eax, cr0
  or eax, 0x1
  mov cr0, eax
  jmp 0x8:protected_mode                   ; The index of the code SD followed by the offset for the protected_mode label.                 
  .hang:
    hlt                                    ; We tell the cpu to idle from this point on unless any interrupts occur.
    jmp .hang                              ; If we reach here, we keep jumping so we do not execute anything past this point.

;------------------------------------------
; Configures basic colour text video mode.
;
[bits 16]
configure_video_mode:
  pusha
  mov ah, 0x0                              ; Set video mode.
  mov al, 0x3                              ; Type of video mode. 0x3 is a 80x25 char colour mode.
  int 0x10
  popa
  ret

;------------------------------------------
; Write a zero terminated string of
; characters to the screen.
;
; Arguments:
;   BX = Starting address of the string.
;
[bits 16]
print_string_rm:
  pusha
  mov al, [bx]
  .loop:
    call print_char_rm
    add bx, 0x1                            ; We raise the string address stored in bx by one to point to the next character of the string.
    mov al, [bx]       
    cmp al, 0x0                            ; We check if the value of the character is zero, the string terminating character by convention.
    jne .loop                              ; If the value is not zero, we continue printing.
  popa
  ret       

;------------------------------------------
; Write an ASCII character to the screen.
;
; Arguments:
;   AL = ASCII character.
;
[bits 16]
print_char_rm:
  pusha
  mov ah, 0xe
  int 0x10                                 ; Thankfully we can still make use of preset BIOS interrupts in real mode.
  popa
  ret

[bits 32]
protected_mode:
    mov ax, 0x10                           ; The index of the data SD.
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ebp, 0x90000
    mov esp, ebp
    mov ebx, 160
    mov al, 'A'
    call print_char_pm
    .hang:
      hlt
      jmp .hang 

;------------------------------------------
; Write an ASCII character to the screen.
;
; Arguments:
;   AL = ASCII character.
;   EBX = Offset defining position to print to.
;
[bits 32]
print_char_pm:
  pusha
  mov ah, 0x02                             ; Color light green on black.
  mov [ebx+0xb8000], ax                    ; Address where video memory starts offset by position to place char at.
  popa
  ret

welcome_string_rm:
  db 'Davidos is in 16 bit mode!', 0x0     ; On a side note, for the assembler db 'abc', 0x0 and db 'a', 'b', 'c', 0x0 are equivalent.

welcome_string_pm:
  db 'Davidos is in 32 bit mode!', 0x0

gdt:                                       ; Our one and only global descriptor table.
  .sd_null:
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
  .sd_code:
    db 0xff, 0xff                          ; Limit (bits 0-15 of first 4 bytes). For the exact meaning of SD fields and flags see "./images/segment_descriptor_fields.png".
    db 0x00, 0x00                          ; Base (bits 16-31 of first 4 bytes).
    db 0x0                                 ; Base (bits 0-7 of second 4 bytes).
    db 0b10011010                          ; P=1, DPL=00, S=1, Type=(Code=1, Conforming=0, Readable=1, Accessed=0). For details see "./images/segment_types.png".
    db 0b11001111                          ; G=1, DB=1, unnamed/unused=0, A=0, limit (bits 16-19 of second 4 bytes)
    db 0x0                                 ; Base (bits 24-31 of second 4 bytes).
  .sd_data:                                 
    db 0xff, 0xff                          ; Limit (bits 0-15 of first 4 bytes).
    db 0x00, 0x00                          ; Base (bits 16-31 of first 4 bytes).
    db 0x0                                 ; Base (bits 0-7 of second 4 bytes).
    db 0b10010010                          ; P=1, DPL=00, S=1, Type=(Code=0, Expand down=0, Write=1, Accessed=0).
    db 0b11001111                          ; G=1, DB=1, unnamed/unused=0, A=0, limit (bits 16-19 of second 4 bytes).
    db 0x0                                 ; Base (bits 24-31 of second 4 bytes).

gdt_descriptor:                            ; The cpu not only needs to know about the start address of the gdt, but also its size. We pass this info using this structure.
    dw gdt_descriptor - gdt - 1            ; The size of the gdt. For some reason always less one than the actual size.
    dd gdt                                 ; This is defined as a double word. Thus 32 bits for usage in protected mode.

padding:       
  times 510-(padding-real_mode) db 0x00     
  dw 0xaa55