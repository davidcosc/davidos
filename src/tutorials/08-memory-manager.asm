; Prerequisites: "./01-basics.asm", "./02-rm-addressing.asm", "./03-stack.asm", "./04-display-text-vga.asm",
; "./05-capture-pressed-keys.asm", "./06-read-disk.asm".
;
; In this module we test our first fit, implicit list memory manager. We are allocating and freeing multiple chunks, to ensure flags
; flags are set correctly and coalescing works. We also ensure, that memors will not be assigned past the initially specified memory
; area. We will not use memory detection. Instead we hardcode the initial memory area.

[org 0x7c00]
[bits 16]
bootsector:
  ; Set up stack to grow down from 0x0000:0x7c00.
  mov word bp, 0x7c00                           
  mov sp, bp
  ; Load additional drivers.
  push word 0x7e00                         ; We want to load the sector at the end of our bootsector. This way label offsets work.
  push word 0x0001                         ; We want to read sector number 2. We start counting sectors at zero.
  call read_sector
  add sp, 0x4                              ; Clean up stack.
  push word 0x8000                         ; We want to load the sector at the end of the previous sector. This way label offsets work.
  push word 0x0002                         ; We want to read sector number 3. We start counting sectors at zero.
  call read_sector
  add sp, 0x4                              ; Clean up stack.
  ; Load memory manager.
  push word 0x8200                         ; We want to load the sector at the end of the previous sector. This way label offsets work.
  push word 0x0003                         ; We want to read sector number 3. We start counting sectors at zero.
  call read_sector
  add sp, 0x4                              ; Clean up stack.
  push word 0x8400                         ; We want to load the sector at the end of the previous sector. This way label offsets work.
  push word 0x0004                         ; We want to read sector number 3. We start counting sectors at zero.
  call read_sector
  add sp, 0x4                              ; Clean up stack.
  ; Setup empty screen.
  push word 0x3000                         ; Pass color and nil char arg.
  call print_whole_screen
  add sp, 0x2                              ; Clean up stack.

test_one:
  ; Malloc init chunk.
  push word INITIAL_CHUNK_START_ADDRESS    ; Pass chunk starting address arg.
  push word INIT_PAYLD_SIZE_IN_BYTES       ; Pass chunk size arg.
  call malloc_initial_chunk
  add sp, 0x4                              ; Clean up stack.
  ; Malloc payload equal to chunk size.
  push word INIT_PAYLD_SIZE_IN_BYTES       ; Pass requested payload size arg.
  push word INITIAL_CHUNK_START_ADDRESS    ; Pass initial chunk starting address arg.
  push word INITIAL_CHUNK_END_ADDRESS      ; Pass initial chunk end address arg.
  call malloc_chunk
  add sp, 0x6                              ; Clean up stack.
  ; Print allocated memory starting address.
  push word 0x0000                         ; Pass offset arg.
  push word 0x3000                         ; Pass color arg.
  push ax                                  ; Pass chunk starting address arg.
  call print_hex_word
  add sp, 0x6                              ; Clean up stack.
  ; Print chunks.
  push word TEXT_BUFFER_ROW_SIZE           ; Pass offset arg.
  push word 0x3000                         ; Pass color arg.
  push word INITIAL_CHUNK_START_ADDRESS    ; Pass chunk starting address arg.
  call print_chunks
  add sp, 0x6                              ; Clean up stack.

test_two:
  ; Reset init chunk.
  push word INITIAL_CHUNK_START_ADDRESS    ; Pass chunk starting address arg.
  push word INIT_PAYLD_SIZE_IN_BYTES       ; Pass chunk size arg.
  call malloc_initial_chunk
  add sp, 0x4                              ; Clean up stack.
  ; Malloc payload smaller than chunk size, but no split.
  push word INIT_PAYLD_SIZE_IN_BYTES - 2   ; Pass requested payload size arg.
  push word INITIAL_CHUNK_START_ADDRESS    ; Pass initial chunk starting address arg.
  push word INITIAL_CHUNK_END_ADDRESS      ; Pass initial chunk end address arg.
  call malloc_chunk
  add sp, 0x6                              ; Clean up stack.
  ; Print allocated memory starting address.
  push word TEXT_BUFFER_ROW_SIZE * 3       ; Pass offset arg.
  push word 0x3000                         ; Pass color arg.
  push ax                                  ; Pass chunk starting address arg.
  call print_hex_word
  add sp, 0x6                              ; Clean up stack.
  ; Print chunks.
  push word TEXT_BUFFER_ROW_SIZE * 4       ; Pass offset arg.
  push word 0x3000                         ; Pass color arg.
  push word INITIAL_CHUNK_START_ADDRESS    ; Pass chunk starting address arg.
  call print_chunks
  add sp, 0x6                              ; Clean up stack.
  ; Free chunk.
  push word INITIAL_CHUNK_START_ADDRESS    ; Pass start address arg.
  push word INITIAL_CHUNK_END_ADDRESS      ; Pass end address arg.
  push word 0x9002                         ; Pass payload starting address arg.
  call free_chunk
  add sp, 0x6                              ; Clean up stack.
  ; Print chunks.
  push word TEXT_BUFFER_ROW_SIZE * 6       ; Pass offset arg.
  push word 0x3000                         ; Pass color arg.
  push word INITIAL_CHUNK_START_ADDRESS    ; Pass chunk starting address arg.
  call print_chunks
  add sp, 0x6                              ; Clean up stack.

test_three:
  ; Reset init chunk.
  push word INITIAL_CHUNK_START_ADDRESS    ; Pass chunk starting address arg.
  push word INIT_PAYLD_SIZE_IN_BYTES       ; Pass chunk size arg.
  call malloc_initial_chunk
  add sp, 0x4                              ; Clean up stack.
  ; Malloc payload smaller than chunk size with split.
  push word INIT_PAYLD_SIZE_IN_BYTES - 6   ; Pass requested payload size arg.
  push word INITIAL_CHUNK_START_ADDRESS    ; Pass initial chunk starting address arg.
  push word INITIAL_CHUNK_END_ADDRESS      ; Pass initial chunk end address arg.
  call malloc_chunk
  add sp, 0x6                              ; Clean up stack.
  ; Print allocated memory starting address.
  push word TEXT_BUFFER_ROW_SIZE * 8       ; Pass offset arg.
  push word 0x3000                         ; Pass color arg.
  push ax                                  ; Pass chunk starting address arg.
  call print_hex_word
  add sp, 0x6                              ; Clean up stack.
  ; Print chunks.
  push word TEXT_BUFFER_ROW_SIZE * 9       ; Pass offset arg.
  push word 0x3000                         ; Pass color arg.
  push word INITIAL_CHUNK_START_ADDRESS    ; Pass chunk starting address arg.
  call print_chunks
  add sp, 0x6                              ; Clean up stack.
  ; Free chunk and merge with next chunk.
  push word INITIAL_CHUNK_START_ADDRESS    ; Pass start address arg.
  push word INITIAL_CHUNK_END_ADDRESS      ; Pass end address arg.
  push word 0x9002                         ; Pass payload starting address arg.
  call free_chunk
  add sp, 0x6                              ; Clean up stack.
  ; Print chunks.
  push word TEXT_BUFFER_ROW_SIZE * 12      ; Pass offset arg.
  push word 0x3000                         ; Pass color arg.
  push word INITIAL_CHUNK_START_ADDRESS    ; Pass chunk starting address arg.
  call print_chunks
  add sp, 0x6                              ; Clean up stack.
  
test_four:
  ; Reset init chunk.
  push word INITIAL_CHUNK_START_ADDRESS    ; Pass chunk starting address arg.
  push word INIT_PAYLD_SIZE_IN_BYTES       ; Pass chunk size arg.
  call malloc_initial_chunk
  add sp, 0x4                              ; Clean up stack.
  ; Malloc payload smaller than chunk size with split.
  push word 0x200                          ; Pass requested payload size arg.
  push word INITIAL_CHUNK_START_ADDRESS    ; Pass initial chunk starting address arg.
  push word INITIAL_CHUNK_END_ADDRESS      ; Pass initial chunk end address arg.
  call malloc_chunk
  add sp, 0x6                              ; Clean up stack.
  ; Malloc payload smaller than chunk size with split and align.
  push word 0x1ff                          ; Pass requested payload size arg.
  push word INITIAL_CHUNK_START_ADDRESS    ; Pass initial chunk starting address arg.
  push word INITIAL_CHUNK_END_ADDRESS      ; Pass initial chunk end address arg.
  call malloc_chunk
  add sp, 0x6                              ; Clean up stack.
  ; Free chunk.
  push word INITIAL_CHUNK_START_ADDRESS    ; Pass start address arg.
  push word INITIAL_CHUNK_END_ADDRESS      ; Pass end address arg.
  push word 0x9002                         ; Pass payload starting address arg.
  call free_chunk
  add sp, 0x6                              ; Clean up stack.
  ; Malloc payload smaller than chunk size with split.
  push word 0x100                          ; Pass requested payload size arg.
  push word INITIAL_CHUNK_START_ADDRESS    ; Pass initial chunk starting address arg.
  push word INITIAL_CHUNK_END_ADDRESS      ; Pass initial chunk end address arg.
  call malloc_chunk
  add sp, 0x6                              ; Clean up stack.
  ; Print allocated memory starting address.
  push word TEXT_BUFFER_ROW_SIZE * 14      ; Pass offset arg.
  push word 0x3000                         ; Pass color arg.
  push ax                                  ; Pass chunk starting address arg.
  call print_hex_word
  add sp, 0x6                              ; Clean up stack.
  ; Print chunks.
  push word TEXT_BUFFER_ROW_SIZE * 15      ; Pass offset arg.
  push word 0x3000                         ; Pass color arg.
  push word INITIAL_CHUNK_START_ADDRESS    ; Pass chunk starting address arg.
  call print_chunks
  add sp, 0x6                              ; Clean up stack.
  ; Free chunk and merge previous and next chunk.
  push word INITIAL_CHUNK_START_ADDRESS    ; Pass start address arg.
  push word INITIAL_CHUNK_END_ADDRESS      ; Pass end address arg.
  push word 0x9206                         ; Pass payload starting address arg.
  call free_chunk
  add sp, 0x6                              ; Clean up stack.
  ; Print chunks.
  push word TEXT_BUFFER_ROW_SIZE * 20      ; Pass offset arg.
  push word 0x3000                         ; Pass color arg.
  push word INITIAL_CHUNK_START_ADDRESS    ; Pass chunk starting address arg.
  call print_chunks
  add sp, 0x6                              ; Clean up stack.
  .tmp:
  jmp .tmp

%include "../lib/ata-driver.asm"

bootsector_padding:
  times 510-(bootsector_padding-bootsector) db 0x00
  dw 0xaa55     

additional_drivers:

%include "../lib/vga-base-driver.asm"
%include "../lib/vga-cursor-driver.asm"
%include "../lib/pic-driver.asm"
%include "../lib/keyboard-driver.asm"

additional_drivers_padding:
  times 1024-(additional_drivers_padding-additional_drivers) db 0x00

memory_management:
  
%include "../lib/memory-management.asm"

memory_management_padding:
    times 1024-(memory_management_padding-memory_management) db 0x00