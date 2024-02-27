; This module contains routines to set up a first fit, implicit list memory manager.

INITIAL_CHUNK_START_ADDRESS equ 0x9000
BOUNDARY_SIZE_IN_BYTES equ 2
SECTOR_PAYLOAD_SIZE_IN_BYTES equ 512
SECTOR_CHUNK_SIZE equ BOUNDARY_SIZE_IN_BYTES + SECTOR_PAYLOAD_SIZE_IN_BYTES + BOUNDARY_SIZE_IN_BYTES
; We want to be able to allocate at least 20 separate memory sectors with their respective boundaries. Total space is 0x2850 or 10320 bytes.
INITIAL_CHUNK_SIZE_IN_BYTES equ SECTOR_CHUNK_SIZE * 40
INIT_PAYLD_SIZE_IN_BYTES equ (INITIAL_CHUNK_SIZE_IN_BYTES - BOUNDARY_SIZE_IN_BYTES) - BOUNDARY_SIZE_IN_BYTES
INITIAL_CHUNK_END_ADDRESS equ INITIAL_CHUNK_START_ADDRESS + INITIAL_CHUNK_SIZE_IN_BYTES
ALLOCATED_STATUS_BIT equ 0x0001
UNMASK_ALLOCATED_STATUS_BIT equ 0b1111111111111110

[bits 16]
malloc_initial_chunk:
  ; Set up the initial memory chunk for an
  ; implicit memory list.
  ;
  ; Arguments:
  ;   Chunk size as word.
  ;   Chunk starting address as word.
  ;
  ; Returns:
  ;   AX = Chunk starting address as word.
  ;
  ; Function prologue. Set up stack frame.
  push bp
  mov bp, sp
  ; Set first boundary (header).
  mov word di, [bp+6]                      ; Get chunk start address arg.
  mov word ax, [bp+4]                      ; Get chunk size arg.
  mov word [di], ax                        ; Set header value/payload size.
  ; Set second boundary (footer).
  add di, BOUNDARY_SIZE_IN_BYTES           ; Payload starting address.
  add di, ax                               ; Add payload size for footer starting address.
  mov word [di], ax                        ; Set footer value/payload size.
  ; Set return value.
  mov word ax, [bp+6]                          
  ; Function epilogue. Tear down stack frame.
  pop bp
  ret

[bits 16]
malloc_chunk:
  ; Using first fit, add a new chunk of
  ; memory to the implicit memory list.
  ; This fails if there is no free memory
  ; chunk available, that could fit the
  ; payload anywhere inside the list.
  ;
  ; Arguments:
  ;   Initial chunk end address.
  ;   Initial chunk starting address.
  ;   Requested payload size in bytes as
  ;   word.
  ;
  ; Returns:
  ;   AX = Chunk payload starting address.
  ;
  ; Function prologue. Set up stack frame.
  push bp
  mov bp, sp
  ; Adjusts requested payload sizes to be even. This is done for two reasons.
  ; The x86 CPU calculates more efficiently on a word basis in real mode. Also, the
  ; last bit of the payload size will always be zero. We can use it to store
  ; the free or allocated status for the chunk efficiently.
  mov word ax, [bp+8]                      ; Get payload size arg.
  ; If payload is uneven, it is rounded up to the next bigger even number, or uneven number otherwise.
  add ax, 0x0001
  ; If payload is uneven, shifting right and then left by one reduces it to the next smaller even number.
  ; An even number in AX stays the same.
  shr ax, 0x1
  shl ax, 0x1
  mov word [bp+8], ax                      ; Store aligned payload size at respective arg position on stack.
  .loop:
    ; Get current chunk starting address.
    mov word si, [bp+6]
    ; Check if we reached the end of the implicit list. We can not allocate memory past this point.
    cmp word si, [bp+4]                    ; Compare with initial chunk end address arg value.
    jae .not_enough_free_memory

    ; Check if current chunk already allocated. If it is, we continue with the next chunk.
    mov word ax, [si]
    and ax, ALLOCATED_STATUS_BIT
    jnz .next_chunk

    ; Check if requested payload size fits current chunk size. If not, we continue with the next chunk.
    mov word ax, [si]                      ; Current chunk payload size.
    cmp word ax, [bp+8]                    ; Requested payload size.
    jb .next_chunk

    ; Check if requested payload size is exactly equal to current chunk payload size. If so, we only allocate without splitting.
    je .only_allocate

    ; Check if current payload size is at least 3 words bigger than requested payload size. If not, we do not split.
    ; A split would result in a zero size payload for the second chunk.
    mov word bx, [bp+8]                    ; Requested payload size.
    add bx, BOUNDARY_SIZE_IN_BYTES * 3     ; Requested payload size plus minimal chunk size for non zero playload.
    cmp word ax, bx
    jb .only_allocate

    ; Split chunk into two. And allocate the first chunk.
    mov word bx, [bp+8]                    ; Requested payload size.
    mov word [si], bx                      ; We write the new payload size to header.
    or word [si], ALLOCATED_STATUS_BIT     ; We set status flag bit to allocated.
    add si, BOUNDARY_SIZE_IN_BYTES
    add si, bx
    mov word [si], bx                      ; We write the new payload size to footer.
    or word [si], ALLOCATED_STATUS_BIT     ; We set status flag bit to allocated.
    sub ax, bx                             ; We calculate the second chunk payload size by subtracting the new payload size
    sub ax, BOUNDARY_SIZE_IN_BYTES * 2     ; and then subtracting the additionally requires space for the extra header and footer.
    add si, BOUNDARY_SIZE_IN_BYTES         ; New chunk header address.
    mov word [si], ax                      ; We write the second payload size to header.
    add si, BOUNDARY_SIZE_IN_BYTES
    add si, ax
    mov word [si], ax                      ; We write the second payload size to footer.
    jmp .end

    ; If payload size is equal to free space of this chunk or slightly smaller such that new boundaries would not fit,
    ; we only allocate this chunk without splitting it up.
    .only_allocate:
      or word [si], ALLOCATED_STATUS_BIT   ; Set flag bit to allocated in header boundary.
      add si, BOUNDARY_SIZE_IN_BYTES
      add word si, ax                      ; Since the requested payload size could be slightly smaller, we use the current size.
      or word [si], ALLOCATED_STATUS_BIT   ; Set flag bit to allocated in footer boundary.
      jmp .end

    .next_chunk:
      ; Remove status bit, so we get the pure chunk size in bytes. If bit not set this does nothing.
      mov word ax, [si]
      and ax, UNMASK_ALLOCATED_STATUS_BIT
      ; To get the next chunk head address, we add the current chunk size plus both boundary sizes (header and footer) to
      ; The current chunks starting address.
      add word [bp+6], ax
      add word [bp+6], BOUNDARY_SIZE_IN_BYTES * 2
  jmp .loop

  .not_enough_free_memory:
     mov word [bp+6], 0x0000               ; Set zero as allocated memory starting address to indicate error.
  .end:
    ; Calculate allocated chunk payload starting address and set return.
    mov word ax, [bp+6]
    add ax, BOUNDARY_SIZE_IN_BYTES
  ; Function epilogue. Tear down stack frame.
  pop bp
  ret
  
[bits 16]
free_chunk:
  ; Free the selected chunk. Merge chunk
  ; neighbors if free.
  ;
  ; Arguments:
  ;   Payload starting address of chunk to
  ;   delete as word.
  ;   Initial chunk end address.
  ;   Initial chunk starting address.
  ;
  ; Function prologue. Set up stack frame.
  push bp
  mov bp, sp
  ; Set up current chunk starting/header address local variable.
  mov word si, [bp+4]                      ; Get current chunk payload starting address arg.
  sub si, BOUNDARY_SIZE_IN_BYTES           ; Calculate current chunk starting address.
  push si
  ; Set up current chunk footer address local variable.
  mov word si, [bp-2]                      ; Get current chunk starting address.
  mov word ax, [si]                        ; Get current chunk header value.
  and ax, UNMASK_ALLOCATED_STATUS_BIT      ; Remove allocated flag if exists.
  add si, ax                               ; Add curent chunk payload siz to starting address.
  add si, BOUNDARY_SIZE_IN_BYTES           ; Calculate current chunk footer address.
  push si
  ; Set up previous chunk starting/header address local variable.
  mov word si, [bp-2]                      ; Get current chunk starting address.
  cmp word si, [bp+8]                      ; Check if current chunk starting address is memory start address.
  jbe .set_start_of_memory
    sub si, BOUNDARY_SIZE_IN_BYTES         ; Get previous chunk footer starting address.
    mov word ax, [si]                      ; Get previous chunk footer value.
    and ax, UNMASK_ALLOCATED_STATUS_BIT    ; Remove allocated flag if exists.
    sub si, ax                             ; Calculate previous chunk payload starting address.
    sub si, BOUNDARY_SIZE_IN_BYTES         ; Calculate previous chunk starting address.
    jmp .set_prev_chunk_header_var
  .set_start_of_memory:
    mov word si, 0x0000                    ; We choose zero as start of memory value.
  .set_prev_chunk_header_var:
  push si
  ; Set up next chunk footer address local variable.
  mov word si, [bp-4]                      ; Get current chunk footer address.
  add si, BOUNDARY_SIZE_IN_BYTES           ; Get next chunk starting/header address.
  cmp word si, [bp+6]
  jae .set_end_of_memory
    mov word ax, [si]                      ; Get next chunk header value.
    and ax, UNMASK_ALLOCATED_STATUS_BIT    ; Remove allocated flag if exists.
    add si, ax                             ; Add next chunk payload size to starting address.
    add si, BOUNDARY_SIZE_IN_BYTES         ; Calculate next chunk footer address.
    jmp .set_next_chunk_footer_var
  .set_end_of_memory:
    mov word si, 0x0000                    ; We choose zero as end of memory value.
  .set_next_chunk_footer_var:
  push si

  ; Check if end of memory.  
  mov word si, [bp-6]                      ; Get previous chunk header address.
  cmp si, 0x0000
  je .merge_and_free_next
  ; Check if previous chunk unallocated.
  mov word ax, [si]                        ; Get previous chunk header value.
  and ax, ALLOCATED_STATUS_BIT
  jnz .merge_and_free_next
    ; Free and merge current and previous chunk.
    mov word ax, [si]                      ; Get previous chunk payload size/header value.
    mov word si, [bp-2]                    ; Get current chunk header address.
    add word ax, [si]                      ; Add current chunk payload size/header value.
    add ax, BOUNDARY_SIZE_IN_BYTES * 2     ; Merging two chunks into one frees two boundaries for additional payload space.
    mov word si, [bp-6]                    ; Get previous chunk header address.
    mov word [si], ax                      ; Set new payload size/header value.
    mov word si, [bp-4]                    ; Get current chunk footer address.
    mov word [si], ax                      ; Set new payload size/footer value.
    ; Update current chunk header local variable.
    mov word ax, [bp-6]                    ; Get previous header address.
    mov word [bp-2], ax                    ; Set current chunk to previous header address.

  .merge_and_free_next:
  ; Check if end of memory.  
  mov word si, [bp-8]                      ; Get next chunk footer address.
  cmp si, 0x0000
  je .free_current
  ; Check if next chunk unallocated
  mov word ax, [si]                        ; Get next chunk footer value/payload size.
  and ax, ALLOCATED_STATUS_BIT
  jnz .free_current
    ; Free and merge current and next chunk.
    mov word ax, [si]                      ; Get next chunk footer value/payload size.
    mov word si, [bp-2]                    ; Get current chunk header address.
    add word ax, [si]                      ; Add current chunk header value/payload size.
    add ax, BOUNDARY_SIZE_IN_BYTES * 2     ; Merging two chunks into one frees two boundaries for additional payload space.
    mov word [si], ax                      ; Set new header value/payload size.
    mov word si, [bp-8]                    ; Get next chunk footer address.
    mov word [si], ax                      ; Set new footer value/payload size.
    ; Update current chunk footer local variable.
    mov word ax, [bp-8]                    ; Get next chunk footer address.
    mov word [bp-4], ax                    ; Set current chunk to next chunk footer address.

  .free_current:
  mov word si, [bp-2]                      ; Get current chunk header address.
  and word [si], UNMASK_ALLOCATED_STATUS_BIT
  mov word si, [bp-4]                      ; Get current chunk footer address.
  and word [si], UNMASK_ALLOCATED_STATUS_BIT   
  
  ; Clean up local variables from stack.
  add sp, 0x8
  ; Function epilogue. Tear down stack frame.
  pop bp
  ret

[bits 16]
print_chunks:
  ; Prints the memory chunk list.
  ;
  ; Arguments:
  ;   Initial chunk starting address as
  ;   word.
  ;   Color and nil char as word.
  ;   Text buffer offset as word. Must be
  ;   the beginning of a row.
  ;
  ; Function prologue. Set up stack frame.
  push bp
  mov bp, sp
  ; Set up local text buffer offset variable on stack.
  mov word ax, [bp+8]                      ; Get initial text buffer offset arg.
  push ax
  ; Set up local chunk starting address variable.
  mov word ax, [bp+4]
  push ax

  ; Print header row.
  push word [bp-2]                         ; Pass offset arg.
  push word [bp+6]                         ; Pass through color and nil char arg.
  push word chunks_header_row              ; Pass string address arg.
  call print_string
  add sp, 0x6                              ; Clean up args.

  .loop:
    ; Increase text buffer offset local var to next row.
    add word [bp-2], TEXT_BUFFER_ROW_SIZE
    ; Print chunk header boundary.
    mov word si, [bp-4]                    ; Get chunk starting address.
    push word [bp-2]                       ; Pass offset arg.
    push word [bp+6]                       ; Pass through color and nil char arg.
    push word [si]                         ; Pass chunk header value arg.
    call print_hex_word
    add sp, 0x6                            ; Clean up args.
    ; Increase text buffer offset for space.
    add ax, 0x2
    ; Calculate chunk payload starting address.
    add word [bp-4], BOUNDARY_SIZE_IN_BYTES
    ; Print chunk payload starting address.
    push word ax                           ; Pass offset arg.
    push word [bp+6]                       ; Pass through color and nil char arg.
    push word [bp-4]                       ; Pass chunk payload starting address arg.
    call print_hex_word
    add sp, 0x6                            ; Clean up args.
    ; Increase text buffer offset for space.
    add ax, 0x2
    ; Calculate chunk payload end address.
    mov word bx, [si]
    and bx, UNMASK_ALLOCATED_STATUS_BIT    ; Clear encoded status flag bit.
    add word [bp-4], bx
    ; Print chunk payload end address.
    push word ax                           ; Pass offset arg.
    push word [bp+6]                       ; Pass through color and nil char arg.
    push word [bp-4]                       ; Pass chunk payload end address arg.
    call print_hex_word
    add sp, 0x6                            ; Clean up args.
    ; Increase text buffer offset for space.
    add ax, 0x2
    ; Print chunk footer boundary.
    mov word si, [bp-4]                    ; Get chunk footer address.
    push word ax                           ; Pass offset arg.
    push word [bp+6]                       ; Pass through color and nil char arg.
    push word [si]                         ; Pass chunk footer value arg.
    call print_hex_word
    add sp, 0x6                            ; Clean up args.
    ; Calculate next chunk start address.
    add word [bp-4], BOUNDARY_SIZE_IN_BYTES
    ; Continue unless initial chunk end address reached.
  cmp word [bp-4], INITIAL_CHUNK_END_ADDRESS
  jb .loop

  ; Set cursor to new line.
  push ax                                  ; Pass offset arg.
  call set_new_line_cursor
  add sp, 0x2                              ; Clean up args.
  ; Clean up local variables from stack.
  add sp, 0x4
  ; Function epilogue. Tear down stack frame.
  pop bp
  ret

  chunks_header_row:
    db 'Head Pls& Ple& Foot', 0x00