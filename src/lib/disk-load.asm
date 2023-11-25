; This module contains functions for loading disk sectors into memory.
; It depends on the "./print.asm" module in order to print error messages to the screen.

[bits 16]
chs_load_sectors:
  ; Read data sectors from boot drive and
  ; load them to 0x0000(ES):(BX).
  ;
  ; Arguments:
  ;   DL = Boot drive number.
  ;   DH = Number of sectors to read.
  ;   ES:BX = Address to load sectors to in memory.
  ;
  ; Returns:
  ;   AL = Number of actual sectors loaded.
  ;
  push cx
  push dx
  mov ah, 0x02                             ; BIOS read sectors from drive.
  mov al, dh                               ; Set number of sectors to be read.
  mov ch, 0x00                             ; Select cylinder zero.
  mov dh, 0x00                             ; Select head zero.
  mov cl, 0x2                              ; Start reading from sector two, since the boot sector was already loaded by BIOS. Weirdly we start counting from one this time.
  int 0x13                                 ; BIOS sector-based hard disk and floppy disk read and write services using cylinder-head-sector addressing (CHS).
  jc .error                                ; If a general fault occurred during read, the carry flag is set.
  pop dx
  cmp dh, al                               ; Compare the number of sectors actually read with the number of sectors we wanted to read.
  jne .error
  pop cx
  ret
  .error:
    mov bx, disk_error_string
    mov dl, 0x18
    mov dh, 0x0
    mov ah, 0x04
    call print_string_rm
    .hang:
      hlt
      jmp .hang

disk_error_string:
  db 'Error reading from disk!', 0x0

disk_load_string:
  db 'Successfully loaded '
  .replace:
    db 0x00
  db ' additional sectors from disk!', 0x00