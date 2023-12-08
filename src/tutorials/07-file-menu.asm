[org 0x7c00]
[bits 16]
main:
  call setup_display
  call setup_keyboard
  ; Read file menu sector one from disk.
  mov ax, 0x1
  mov di, 0x7e00                           ; We want to load the sector at the end of our bootsector.
  call read_sector
  ; Read file menu sector two from disk.
  mov ax, 0x2
  mov di, 0x8000                           ; We want to load the sector at the end of file menu one sector.
  call read_sector
  .loop:
    xor di, di
    ; Setup file menu.
    call render_file_menu_header
    call render_files
    call render_file_menu_footer
    hlt
    mov word dx, [pressed_key_buffer]
    mov word [pressed_key_buffer], 0x0000  ; Clear pressed key buffer.
    cmp dh, DOWN_ARROW_SCAN_CODE
    je .next_file
    cmp dh, UP_ARROW_SCAN_CODE
    je .previous_file
    cmp dh, ENTER_SCAN_CODE
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
      mov di, 0x8200                       ; We want to load the sector at the end of our file menu sector two.
      call read_sector
      ; Print file sector message.
      mov ah, 0x40
      mov bx, 0x8200
      mov di, TEXT_BUFFER_ROW_SIZE * 0xc
      call print_string
      jmp .end
    .next_file:
      call select_next_file
      jmp .end
    .previous_file:
      call select_previous_file
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
;;;;; File menu sectors ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FILE_MENU_WELCOME_STARTING_LINE equ 0x2 * TEXT_BUFFER_ROW_SIZE
FILE_MENU_ENTRY_STARTING_LINE equ 0x7 * TEXT_BUFFER_ROW_SIZE
FILE_MENU_ETNRY_PADDING_RIGHT_OFFSET equ TEXT_BUFFER_ROW_SIZE - 0x6

render_file_menu_header:
  push di
  push ax
  push bx
  mov word di, FILE_MENU_WELCOME_STARTING_LINE
  mov ah, 0x40
  mov bx, file_menu_header
  call print_string
  pop bx
  pop ax
  pop di
  ret

render_files:
  ; Display all files inside the file menu.
  ; The selected file is highlighted.
  ;
  ; Returns:
  ;   DI = Next line text buffer offset.
  push cx
  push bx
  push ax
  mov byte cl, [file_menu]
  .loop:
    xor bx, bx
    mov bl, cl
    mov di, bx
    dec di
    imul di, TEXT_BUFFER_ROW_SIZE
    add di, FILE_MENU_ENTRY_STARTING_LINE
    call render_file_entry_padding_right
    call render_file_entry_padding_left
    dec bl
    imul bx, 0xa
    inc bx
    add bx, file_menu
    call color_selected_file
    call print_string
    loop .loop
  xor ax, ax
  mov byte al, [file_menu]
  mov di, ax
  imul di, TEXT_BUFFER_ROW_SIZE
  add di, FILE_MENU_ENTRY_STARTING_LINE
  pop ax
  pop bx
  pop cx
  ret

render_file_entry_padding_left:
  push bx
  push ax
  mov ah, 0x40
  mov bx, file_entry_hash_padding_left
  call print_string
  pop ax
  pop bx
  ret

render_file_entry_padding_right:
  push bx
  push ax
  add di, FILE_MENU_ETNRY_PADDING_RIGHT_OFFSET
  mov ah, 0x40
  mov bx, file_entry_hash_padding_right
  call print_string
  sub di, 0x6
  sub di, FILE_MENU_ETNRY_PADDING_RIGHT_OFFSET
  pop ax
  pop bx
  ret

render_file_menu_footer:
  mov ah, 0x40
  mov bx, file_menu_footer
  call print_string
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

select_next_file:
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

select_previous_file:
  push ax
  push bx
  xor ax, ax
  xor bx, bx
  mov byte al, [file_menu]
  mov byte bl, [selected_file]
  cmp bl, 0x01
  jne .next
  mov byte [selected_file], al
  jmp .end
  .next:
    dec bl
    mov byte [selected_file], bl
  .end:
  pop bx
  pop ax
  ret

file_menu_header:
  times 160 db '#'
  db '## Use the UP and DOWN arrow keys to navigate files.                          ##'
  db '## Press ENTER to select a file.                                              ##'
  times 80 db '#'
  db 0x00

file_entry_hash_padding_left:
  db '## ', 0x00

file_entry_hash_padding_right:
  db ' ##', 0x00

file_menu_footer:
  times 160 db '#'
  db 0x00

file_menu:
  db 0x02
  db 'File 1', 0x00, 0x00, 0x03, 0x01
  db 'File 2', 0x00, 0x00, 0x04, 0x02

selected_file:
  db 0x01

file_menu_sector_padding:
  times 1024-(file_menu_sector_padding-render_file_menu_header) db 0x00

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