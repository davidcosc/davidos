INITIAL_CHUNK_START_ADDRESS equ 0x8600
BOUNDARY_SIZE_IN_BYTES equ 2
SECTOR_PAYLOAD_SIZE_IN_BYTES equ 512
SECTOR_CHUNK_SIZE equ BOUNDARY_SIZE_IN_BYTES + SECTOR_PAYLOAD_SIZE_IN_BYTES + BOUNDARY_SIZE_IN_BYTES
; We want to be able to allocate at least 20 separate memory sectors with their respective boundaries. Total space is 0x2850 or 10320 bytes.
INITIAL_CHUNK_SIZE_IN_BYTES equ SECTOR_CHUNK_SIZE * 20
INITIAL_PAYLOAD_SIZE_IN_BYTES equ (INITIAL_CHUNK_SIZE_IN_BYTES - BOUNDARY_SIZE_IN_BYTES) - BOUNDARY_SIZE_IN_BYTES
INITIAL_CHUNK_END_ADDRESS equ INITIAL_CHUNK_START_ADDRESS + INITIAL_CHUNK_SIZE_IN_BYTES
ALLOCATED_STATUS_BIT equ 0x0001
UNMASK_ALLOCATED_STATUS_BIT equ 0b1111111111111110

[bits 16]
init_memory_chunk:
  ; Set up the initial memory chunk for an
  ; implicit memory list.
  push es
  push di
  push ax
  ; Init segment.
  mov word di, 0x0000
  mov es, di
  ; Set first boundary (header).
  mov word di, INITIAL_CHUNK_START_ADDRESS
  mov word ax, INITIAL_PAYLOAD_SIZE_IN_BYTES
  mov word [di], ax
  add di, BOUNDARY_SIZE_IN_BYTES
  ; Set second boundary (footer).
  add di, ax
  mov word [di], ax                          
  pop ax
  pop di
  pop es
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
  ;   DX = Requested payload size in bytes.
  ;
  ; Returns:
  ;   DI = Chunk payload starting address.
  push es
  push ax
  push bx
  push dx
  ; Init segment.
  mov word di, 0x0000
  mov es, di
  ; Normalize payload size.
  call align_chunk_payload
  ; Start at bottom of the list.
  mov word di, INITIAL_CHUNK_START_ADDRESS
  .loop:
    ; We reached the end of the implicit list. We can not allocate memory past this point.
    cmp di, INITIAL_CHUNK_END_ADDRESS
    jae .not_enough_free_memory
    ; We try the next chunk, if this one is already allocated.
    mov word ax, [di]
    and ax, ALLOCATED_STATUS_BIT
    jnz .next_chunk
    ; We try the next chunk, if this one is not big enough to contain the requested payload.
    cmp word [di], dx
    jb .next_chunk
    ; We only allocate without splitting, if free chunk space equals requested payload size.
    je .only_allocate
    ; We split the chunk before allocation, if payload size plus two boundary sizes plus one word payload
    ; is less than free space of this chunk. This ensures we only split, if the two resulting chunks have
    ; a minimum payload of one byte.
    mov ax, dx
    add ax, BOUNDARY_SIZE_IN_BYTES * 3     ; Boundaries plus minimum payload of one word.
    cmp [di], ax
    jb .only_allocate
    mov ax, [di]                           ; We save the old payload size.
    mov word [di], dx                      ; We write the new payload size to header.
    or word [di], ALLOCATED_STATUS_BIT     ; We set status flag bit to allocated.
    add di, BOUNDARY_SIZE_IN_BYTES
    mov bx, di                             ; Save payload starting address for return value.
    add di, dx
    mov word [di], dx                      ; We write the new payload size to footer.
    or word [di], ALLOCATED_STATUS_BIT     ; We set status flag bit to allocated.
    sub ax, dx                             ; We calculate the second chunk payload size by subtracting the new payload size
    sub ax, BOUNDARY_SIZE_IN_BYTES * 2     ; and then subtracting the additionally requires space for the extra header and footer.
    add di, BOUNDARY_SIZE_IN_BYTES         ; New chunk header address.
    mov word [di], ax                      ; We write the second payload size to header.
    add di, BOUNDARY_SIZE_IN_BYTES
    add di, ax
    mov word [di], ax                      ; We write the second payload size to footer.
    jmp .end
    ; If payload size is equal to free space of this chunk or slightly smaller such that new boundaries would not fit,
    ; we only allocate this chunk without splitting it up.
    .only_allocate:
      mov word ax, [di]                    ; We save the current chunk size.
      or word [di], ALLOCATED_STATUS_BIT   ; Set flag bit to allocated in header boundary.
      add di, BOUNDARY_SIZE_IN_BYTES
      mov bx, di                           ; Save payload starting address for return value.
      add di, ax                           ; AX is either equal or slightly bigger than the requested payload size in DX.
      or word [di], ALLOCATED_STATUS_BIT   ; Set flag bit to allocated in footer boundary.
      jmp .end
    .next_chunk:
      ; Remove status bit, so we get the pure chunk size in bytes.
      mov word ax, [di]
      and ax, UNMASK_ALLOCATED_STATUS_BIT
      ; To get the next chunk head address, we add the current chunk size plus both boundary sizes (header and footer) to
      ; The current chunks starting address.
      add di, ax
      add di, BOUNDARY_SIZE_IN_BYTES * 2
  jmp .loop
  .not_enough_free_memory:
     mov word bx, 0x0000
  .end:
    mov di, bx
  pop dx
  pop bx
  pop ax
  pop es
  ret

[bits 16]
align_chunk_payload:
  ; Adjusts requested payload sizes to be
  ; even. This is done for two reasons.
  ; The x86 CPU calculates more efficiently
  ; on a word basis in real mode. Also, the
  ; last bit of the payload size will
  ; always be zero. We can use it to store
  ; the free or allocated status for the
  ; chunk efficiently.
  ;
  ; Arguments:
  ;   DX = Requested payload size in bytes.
  ;
  ; Returns:
  ;   DX = Aligned payload size in bytes.
  ; If DX is uneven, it is rounded up to the next bigger even number, or uneven number otherwise.
  add dx, 0x0001
  ; If DX is uneven, shifting right and then left by one reduces it to the next smaller even number.
  ; An even number in DX stays the same.
  shr dx, 0x1
  shl dx, 0x1
  ret
  
[bits 16]
free_chunk:
  ; Free the selected chunk. Coalesce chunk
  ; neighbors if free.
  ;
  ; Arguments:
  ;   DI = Payload starting address of
  ;        chunk to delete.
  push ds
  push es
  push si
  push di
  push ax
  push bx
  ; Init segment.
  mov word ax, 0x0000
  mov es, ax
  ; Free current chunk.
  sub di, BOUNDARY_SIZE_IN_BYTES           ; DI points to current chunk starting address.
  and word [di], UNMASK_ALLOCATED_STATUS_BIT
  mov si, di
  add si, BOUNDARY_SIZE_IN_BYTES
  add word si, [di]                        ; SI points to current chunk footer starting address.
  and word [si], UNMASK_ALLOCATED_STATUS_BIT
  ; Skip coalesce with next chunk if last chunk.
  cmp di, INITIAL_CHUNK_END_ADDRESS
  je .end
  ; Coalesce next chunk if free. 
  mov word si, [di]
  add si, di
  add si, BOUNDARY_SIZE_IN_BYTES * 2       ; SI points to next chunk starting address.
  mov word ax, [si]
  and ax, ALLOCATED_STATUS_BIT
  jnz .after_next_coalesce
    ; Coalesce.
    mov word ax, [si]
    add word ax, [di]                      ; AX contains payload sum.
    add ax, BOUNDARY_SIZE_IN_BYTES * 2     ; Coalescing two chunks removes the need one header and footer boundary. We gain payload.
    mov si, di
    add si, ax
    add si, BOUNDARY_SIZE_IN_BYTES         ; SI points to next chunk footer.
    mov word [si], ax                      ; Write coalesced payload size to footer.
    mov word [di], ax                      ; Write coalesced payload size to header.
  .after_next_coalesce:
  ; Skip coalesce with previous chunk if first chunk.
  cmp di, INITIAL_CHUNK_START_ADDRESS
  je .end
  ; Coalesce with previous chunk if free.
  mov si, di                               ; SI points to current chunk starting address.
  sub di, BOUNDARY_SIZE_IN_BYTES           ; DI points to previous chunk footer.
  mov word ax, [di]
  and ax, ALLOCATED_STATUS_BIT
  jnz .end
    ; Coalesce.
    mov word ax, [di]                      ; AX contains previous chunk payload size.
    sub di, ax
    sub di, BOUNDARY_SIZE_IN_BYTES         ; DI points to previous chunk starting address.
    add word ax, [si]                      ; AX contains payload sum.
    add ax, BOUNDARY_SIZE_IN_BYTES * 2     ; Coalescing two chunks removes the need one header and footer boundary. We gain payload.
    mov word [di], ax
    add di, ax
    add di, BOUNDARY_SIZE_IN_BYTES         ; DI points at current chunk footer.
    mov word [di], ax
  .end:
  pop bx
  pop ax
  pop di
  pop si
  pop es
  pop ds
  ret

[bits 16]
print_chunks:
  push ds
  push si
  push di
  push ax
  push bx
  push cx
  push dx
  ; Init segment.
  mov word si, 0x0000
  mov ds, si
  ; Init print.
  mov word cx, TEXT_BUFFER_ROW_SIZE * 0x2
  mov byte ah, 0x40
  ; First chunk.
  mov word si, INITIAL_CHUNK_START_ADDRESS
  .loop:
    ; Print chunk header.
    mov di, cx                             ; Init text buffer line.
    mov word dx, [si]                      ; Save payload size.
    mov bx, dx
    call print_hex_word
    add di, 0x2
    ; Print chunk payload starting address.
    add si, BOUNDARY_SIZE_IN_BYTES
    mov bx, si
    call print_hex_word
    add di, 0x2
    ; Print chunk payload end address.
    and dx, UNMASK_ALLOCATED_STATUS_BIT    ; Clear encoded status flag bit.
    add si, dx
    mov bx, si
    call print_hex_word
    add di, 0x2
    ; Print chunk footer.
    mov word bx, [si]
    call print_hex_word
    ; Continue if list end not reached.
    add cx, TEXT_BUFFER_ROW_SIZE
    add si, BOUNDARY_SIZE_IN_BYTES
    cmp si, INITIAL_CHUNK_END_ADDRESS
    jb .loop
  pop dx
  pop cx
  pop bx
  pop ax
  pop di
  pop si
  pop ds
  ret