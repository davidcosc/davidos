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

MAC_FIRST_VISIBLE_ROW equ TEXT_BUFFER_ROW_SIZE * 0x2

[org 0x7c00]                               ; The BIOS sets all segment register to 0x0000 per default. We later on set our data and code segment starting addresses to 0x0 as well
                                           ; in the gdt. With the org directive a label offset of e.g 0x0020 becomes 0x7c20 and can therefore be resolved in both real and protected
                                           ; mode. Without the org directive, we could have manipulated the segment registers in real mode to change segment starting addresses to
                                           ; 0c7c00. With our label offset of 0x0020 we would still end up at the correct address of 0x7c20. After the change to protected mode
                                           ; however we would end up at address 0x0020, which would crash our program.
[bits 16]
real_mode:
  ; Set up stack to grow down from 0x0000:0x7c00.
  mov bp, 0x7c00                           
  mov sp, bp
  ; Set up screen for printing.
  mov ax, 0xb800
  mov es, ax
  call paint_screen_red
  call hide_cursor
  mov di, MAC_FIRST_VISIBLE_ROW
  ; Display welcome message.
  mov ah, 0x40
  mov bx, welcome_string_rm
  call print_string
  ; Load additional sector from disk into memory.
  mov ax, 0x1                              ; We want to read sector number 2. We start counting sectors at zero.
  mov di, 0x7e00                           ; We want to load the sector at the end of our bootsector. This way label offsets work.
  call read_sector
  ; New line
  mov di, TEXT_BUFFER_ROW_SIZE * 0x3
  ; Print sector two message.
  mov ah, 0x40
  mov bx, sector_two
  call print_string
  ; Switch to protected mode.
  cli
  lgdt [gdt_descriptor]
  mov eax, cr0
  or eax, 0x1
  mov cr0, eax
  jmp 0x8:protected_mode                   ; The index of the code SD followed by the offset for the protected_mode label.
  ; Do nothing.                 
  .hang:
    hlt                                    ; We tell the cpu to idle from this point on unless any interrupts occur.
    jmp .hang                              ; If we reach here, we keep jumping so we do not execute anything past this point.

%include "../lib/vga-driver.asm"
%include "../lib/ata-driver.asm"

welcome_string_rm:
  db 'Davidos is in 16 bit mode!', 0x00    ; On a side note, for the assembler db 'abc', 0x0 and db 'a', 'b', 'c', 0x0 are equivalent.

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

padding_rm:       
  times 510-(padding_rm-real_mode) db 0x00     
  dw 0xaa55

[bits 32]
protected_mode:
    ; Point segment registers to correct segment descriptors.
    mov ax, 0x0010                         ; The index of the data SD.
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    ; Setup the stack.
    mov ebp, 0x90000
    mov esp, ebp
    ; New line
    mov edi, TEXT_BUFFER_ROW_SIZE * 0x4
    add edi, 0xb8000
    ; Display welcome message.
    mov ah, 0x40
    mov ebx, welcome_string_pm
    call print_string_pm
    ; Do nothing.
    .hang:
      hlt
      jmp .hang

%include "../lib/vga-driver-pm.asm"

welcome_string_pm:
  db 'Davidos is in 32 bit mode!', 0x00

sector_two:
  db 'Hello, sector two!', 0x00
  .padding:
    times 512-(.padding-sector_two) db 0x00