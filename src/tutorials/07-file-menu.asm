[org 0x7c00]
[bits 16]
main:
  cli
  call setup_display
  call setup_keyboard
  ; Read file menu sector from disk.
  mov ax, 0x1
  mov di, 0x7e00                           ; We want to load the sector at the end of our bootsector.
  call read_sector
  .loop:
    xor di, di
    ; Setup file menu.
    call render_files
    sti
    xor dx, dx
    hlt
    cli
    cmp dl, '1'
    je .next_file
    cmp dl, '2'
    je .load_file
    jmp .loop
    .load_file:
      xor bx, bx
      xor ax, ax
      mov bl, [selected_file]
      dec bx
      imul bx, 0xa
      inc bx
      add bx, 0x8
      add bx, file_menu
      mov byte al, [bx]
      mov di, 0x8000                           ; We want to load the sector at the end of our file menu sector.
      call read_sector
      ; Print file sector message.
      mov ah, 0x40
      mov bx, 0x8000
      mov di, TEXT_BUFFER_ROW_SIZE * 0xa
      call print_string
      jmp .end
    .next_file:
      call select_file
    .end:
      jmp .loop

setup_display:
  ; Setup ES to point to text mode video buffer.
  mov ax, 0xb800
  mov es, ax
  ; Setup empty screen.
  call paint_screen_red
  call hide_cursor
  ret

setup_keyboard:
  ; Reinitialize pic with new irq offset.
  mov bh, 0x20                             ; Master pic interrupt offset.
  mov bl, 0x70                             ; Slave pic interrupt offset.
  call configure_pics
  ; Disable all interrupts apart from IRQ1.
  mov bh, 11111101b
  mov bl, 11111111b
  call mask_interrupts
  ; Set up keyboard isr in ivt
  mov bx, 0x84
  call install_keyboard_driver
  ret

%include "../lib/vga-driver.asm"
%include "../lib/ata-driver.asm"
%include "../lib/pic-driver.asm"
%include "../lib/keyboard-driver.asm"

padding:
  times 510-(padding-main) db 0x00
  dw 0xaa55

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; File menu sector ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FILE_LIST_STARTING_LINE equ 0x5

file_menu:
  db 0x02
  db 'File 1', 0x00, 0x00, 0x02, 0x01
  db 'File 2', 0x00, 0x00, 0x03, 0x02

selected_file:
  db 0x01

separator_line:
  times 80 db '#'
  db 0x00

render_files:
  ; Display all files inside the file menu.
  ; The selected file is highlighted.
  push cx
  push bx
  push ax
  mov byte cl, [file_menu]
  .loop:
    xor bx, bx
    mov bl, cl
    mov di, bx
    dec di
    add di, FILE_LIST_STARTING_LINE
    imul di, TEXT_BUFFER_ROW_SIZE
    mov ah, 0x40
    mov al, '#'
    call print_char
    mov al, ' '
    call print_char
    dec bl
    imul bx, 0xa
    inc bx
    add bx, file_menu
    call color_selected_file
    call print_string
    loop .loop
  pop ax
  pop bx
  pop cx
  ret

color_selected_file:
  ; Set text mode color to black over light
  ; red for the currently selected file.
  ;
  ; Arguments:
  ;   BX = Starting address of file entry.
  ;
  ; Returns:
  ;   AH = Black over light red color code.
  push bx
  xor ax, ax
  add bx, 0x9
  mov byte al, [bx]
  cmp al, [selected_file]
  jne .normal
  .selected:
    xor ax, ax
    mov ah, 0xc0
    jmp .end
  .normal:
    xor ax, ax
    mov ah, 0x40
  .end:
  pop bx
  ret

select_file:
  push ax
  push bx
  xor ax, ax
  xor bx, bx
  mov byte al, [file_menu]
  mov byte bl, [selected_file]
  cmp bl, al
  jl .next
  mov bl, 0x1
  mov byte [selected_file], bl
  jmp .end
  .next:
    inc bl
    mov byte [selected_file], bl
  .end:
  pop bx
  pop ax
  ret

file_menu_padding:
  times 512-(file_menu_padding-file_menu) db 0x00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; File one sector ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
file_one_sector:
  db 'Hello, file 1!', 0x00
file_one_padding:
    times 512-(file_one_padding-file_one_sector) db 0x00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; File two sector ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
file_two_sector:
  db 'Hello, file 2!', 0x00
file_two_padding:
    times 512-(file_two_padding-file_two_sector) db 0x00