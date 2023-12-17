; Prerequisites: "./01-basics.asm", "./02-rm-addressing.asm", "./03-stack.asm", "./04-display-text-vga.asm", "./06-read-disk.asm".
;
; In this module we read additional sectors to memory dynamically. We will ask the memory manager, where to place the sectors in memory.
; We will not hard code the destination addresses. We will use lower memory only. The lower memory map is standardized.
; Memory space 0x07e00 to 0x7ffff is conventional memory that can be used freely. We will only use this memory space for dynamic allocation
; through our memory manager. The manager will use the buddy system to allocate memory. We will never use more than 20 sectors of memory in our project.

%include "../os/kernel-drivers.asm"

[bits 16]
main:
  ; Setup empty screen.
  call paint_screen_red
  call hide_cursor
  ; Load memory manager sector.
  mov word ax, 0x0004
  mov word di, 0x8400
  call read_sector
  ; Setup printing.
  mov ah, 0x40
  mov di, 0xb800
  mov es, di
  ; Test init memory list.
  call init_memory_chunk
  call print_chunks
  call continue_loop 
  ; Test add new chunk that splits current chunk and payload gets aligned from 7 to 8.
  call paint_screen_red
  mov word dx, 0x7
  call malloc_chunk
  mov bx, di
  mov di, 0x9 * TEXT_BUFFER_ROW_SIZE
  call print_hex_word
  call print_chunks
  call continue_loop
  ; Test add new chunk that exactly matches free memory.
  call paint_screen_red
  mov word dx, 0x2840
  call malloc_chunk
  mov bx, di
  mov di, 0x9 * TEXT_BUFFER_ROW_SIZE
  call print_hex_word
  call print_chunks
  call continue_loop
  ; Test add new chunk that is only slightly smaller than free memory.
  call paint_screen_red
  call init_memory_chunk
  call print_chunks
  call continue_loop
  mov word dx, 0x284a
  call malloc_chunk
  mov bx, di
  mov di, 0x9 * TEXT_BUFFER_ROW_SIZE
  call print_hex_word
  call print_chunks
  call continue_loop
  ; Test add new chunk but not enough free memory.
  call paint_screen_red
  call init_memory_chunk
  call print_chunks
  call continue_loop
  call paint_screen_red
  mov word dx, 0x2850
  call malloc_chunk
  mov bx, di
  mov di, 0x9 * TEXT_BUFFER_ROW_SIZE
  call print_hex_word
  call print_chunks
  call continue_loop
  ; Test free no coalesce.
  call paint_screen_red
  mov word dx, 0x0200
  call malloc_chunk
  call malloc_chunk
  call malloc_chunk
  call print_chunks
  call continue_loop
  mov di, 0x8602
  call free_chunk
  call print_chunks
  call continue_loop
  ; Test free coalesce next.
  call paint_screen_red
  mov di, 0x8a0a
  call free_chunk
  call print_chunks
  .loop:
    hlt
    jmp .loop

continue_loop:
  push es
  push di
  push ax
  push bx
  push dx
  ; Init segment.
  mov di, 0xb800
  mov es, di
  .pause_loop:
    mov word bx, continue_message
    mov di, TEXT_BUFFER_ROW_SIZE * 0x10
    mov ah, 0x40
    call print_string
    hlt
    mov word dx, [pressed_key_buffer]
    mov word [pressed_key_buffer], 0x0000  ; Clear pressed key buffer.
    cmp dh, ENTER_SCAN_CODE
    jne .pause_loop
  pop dx
  pop bx
  pop ax
  pop di
  pop es
  ret

continue_message:
  db 'Press any key to continue.', 0x00 

padding:
  times 512-(padding-main) db 0x00     

memory_manager_sector:
  
%include "../lib/first-fit-implicit-list-memory-manager.asm"

memory_manager_sector_padding:
    times 512-(memory_manager_sector_padding-memory_manager_sector) db 0x00

test_sector_one:
  db 'Hello, test sector one!', 0x00
  .padding:
    times 512-(.padding-test_sector_one) db 0x00

test_sectors_two:
  times 1024 db 0x00
  .test_sectors_two_message:
    db 'Hello, test sectors two!', 0x00
  .padding:
    times 512-(.padding-.test_sectors_two_message) db 0x00