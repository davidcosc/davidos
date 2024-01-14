; This module contains routines to set up multitasking.

TASK_CONTROL_BLOCK_SIZE_BYTES equ 0xc
TASK_STACK_SIZE_BYTES equ 0x200
TASK_RESERVED_MEMORY_SIZE_BYTES equ TASK_CONTROL_BLOCK_SIZE_BYTES + TASK_STACK_SIZE_BYTES
SWITCH_TASK_INTERRUPT_NUMBER equ 0x81
SWITCH_TASK_INTERRUPT_VECTOR_ADDRESS equ SWITCH_TASK_INTERRUPT_NUMBER * 0x4

[bits 16]
create_root_kernel_task:
  ; Transforms the current program into 
  ; a task. A task control block is created
  ; with the current stack. 
  ;
  ; Arguments:
  ;   AX = Task ID word.
  cli                                      ; We do not want to be interrupted by a task switch during task creation.
  pusha
  push es
  ; Init segments.
  xor di, di
  mov es, di
  mov ds, di
  ; Allocate memory for task control block.                                 
  mov dx, TASK_CONTROL_BLOCK_SIZE_BYTES
  call malloc_chunk
  mov bx, di                               ; Save task control block starting address for later.
  ; Set up task control block.
  mov word [di], ax                        ; Set task ID.
  mov word [di+2], bp                      ; Set base pointer for task.
  mov word [di+4], bp                      ; Set stack pointer for task. We want the root task to start with an empty stack.
  mov si, sp
  add si, 0x12
  mov word ax, [si]                        ; Retrieve the create_root_kernel_task return address. Task exec starts after creation.
  mov word [di+6], ax                      ; Set return address as task exec address.
  mov word [di+8], bx                      ; Set current task starting address as previous task.
  mov word [di+10], bx                     ; Set current task starting address as next task.
  ; Set first, last and current task to this one, since it is the only task.
  mov word [first_task], bx
  mov word [last_task], bx
  mov word [current_task], bx
  pop es
  popa
  sti
  ret

[bits 16]
exec_task:
  ; Creates a new task. This creates a new
  ; task control block as well as a new
  ; stack. Execution is then transferred to
  ; the new task. For the new task registers
  ; are initializes as zero.
  ;
  ; Arguments:
  ;   AX = Task ID word.
  ;   SI = Execution address.
  cli                                      ; We do not want to be interrupted by a task switch during task creation.
  ; Save current task register state to stack.
  ; We do not use pusha since we want to manipulates BP and SP later on when task switching.
  ; We do not want to continue executing this function on future task switch.
  ; We set this functions return address as iret IP on the stack.
  ; We have to move it down by 4 on the stack to make room for CS and FLAGS values of the iret.
  sub sp, 0x4                              ; Make room to set up IP, CS, FLAGS later on. IP is already on stack but at wrong place.
  push ax
  push bx
  push cx
  push dx
  push di
  push si
  push ds
  push es
  ; Init segments.
  mov word di, 0x0000
  mov es, di
  mov ds, di
  ; Set up iret IP, CS, FLAGS
  push cx                                 ; Save CX value since we gonna change it to set FLAGS and move ret to IP on stack.
  mov di, sp
  mov word cx, [di+22]                    ; Get ret address into CX.
  mov word [di+18], cx                    ; Set IP to ret address in iret struct on stack.
  mov word [di+20], cs                    ; Set CS in iret struct on stack.
  pushf
  pop cx                                  ; Get FLAGS into CX.
  or cx, 0x0200                           ; Set interrupt flag to enabled.
  mov word [di+22], cx                    ; Set FLAGS in iret struct on stack.
  pop cx                                  ; Reset CX back to its original value.
  ; Save current task stack state.
  mov word di, [current_task]
  mov word [di+4], sp
  ; Allocate memory for new task control block.                                 
  mov dx, TASK_RESERVED_MEMORY_SIZE_BYTES
  call malloc_chunk
  mov bx, di                               ; Save new task control block starting address for later.
  mov cx, si                               ; Save new task exec address for later.
  ; Calculate new task stack base address.
  add di, TASK_RESERVED_MEMORY_SIZE_BYTES  ; End of task allocated memory.
  mov dx, di                               ; Save new task stack base address for later.
  mov di, bx                               ; Start of new task control block.
  ; Set up new task control block.
  mov word [di], ax                        ; Set new task ID.
  mov word [di+2], dx                      ; Set base pointer for new task.
  mov word [di+4], dx                      ; Set stack pointer for new task.
  mov word [di+6], cx                      ; Set starting memory address of new task exec.
  mov word si, [last_task]
  mov word [di+8], si                      ; Set last task as previous task for new task.
  mov word si, [first_task]
  mov word [di+10], si                     ; Set first task as next task for new task.
  ; Adjust last and first task next and previous tasks.
  mov word [si+8], bx
  mov word si, [last_task]
  mov word [si+10], bx
  ; Set last and current task to this one, since we added it at the end of the task list.
  mov word [last_task], bx
  mov word [current_task], bx
  ; Switch to new task and stack.
  mov bp, dx
  mov sp, dx
  push cx
  ; Initialize registers to zero.
  xor ax, ax
  xor bx, bx
  xor cx, cx
  xor dx, dx
  xor di, di
  xor si, si
  mov es, di
  mov ds, di
  sti
  ret

[bits 16]
install_switch_task_isr:
  ; Setup an interrupt vector inside the ivt
  ; to point to the keyboard_isr. After
  ; running this routine, interrupts that
  ; refer to the configured vector will
  ; trigger the keyboard_isr. The vector
  ; must match IRQ 1 as specified by the
  ; PIC.
  cli
  push es
  push di
  push ax
  ; Init segments.
  mov word di, 0x0000
  mov es, di
  ; Set up vector.
  mov word di, SWITCH_TASK_INTERRUPT_VECTOR_ADDRESS
  mov word ax, switch_task_isr
  stosw
  mov word ax, 0x0000
  stosw
  pop ax
  pop di
  pop es
  sti
  ret

[bits 16]
switch_task_isr:
  ; Save current task register state. FLAGS, CS and IP are already saved by INT instruction.
  push ax
  push bx
  push cx
  push dx
  push di
  push si
  push ds
  push es
  ; Init segments. We do this in case the current ds and es values are not zero.
  mov word di, 0x0000
  mov es, di
  mov ds, di
  ; Save current task stack state.
  mov word si, [current_task]
  mov word [si+2], bp
  mov word [si+4], sp
  ; Restore next task stack state.
  mov word di, [si+10]
  mov word bp, [di+2]
  mov word sp, [di+4]
  ; Set next task as new current.
  mov word [current_task], di
  ; Restore next task register state.
  pop es
  pop ds
  pop si
  pop di
  pop dx
  pop cx
  pop bx
  pop ax
  iret

first_task:
  dw 0x0000

last_task:
  dw 0x0000

current_task:
  dw 0x0000

print_tasks:
  ; Print all tasks inside the task list.
  ; Start printing the header row at row CX.
  ;
  ; Arguments:
  ;   CX = Row number to start printing at.
  push ds
  push si
  push es
  push di
  push ax
  push bx
  push cx
  push dx
  ; Init segments.
  mov word si, 0xb800
  mov es, si
  mov word si, 0x0000
  mov ds, si
  ; Print header row.
  imul cx, TEXT_BUFFER_ROW_SIZE
  mov byte ah, 0x40
  mov word bx, task_list_header_row
  mov di, cx
  call print_string
  ; Select first task.
  mov word si, [first_task]
  ; Print tasks.
  .loop:
    ; Print current task ID.
    add cx, TEXT_BUFFER_ROW_SIZE
    mov di, cx
    mov word bx, [si]
    call print_hex_word
    add di, 0x2
    ; Print current task stack BP.
    mov word bx, [si+2]
    call print_hex_word
    add di, 0x2
    ; Print current task stack SP.
    mov word bx, [si+4]
    call print_hex_word
    add di, 0x2
    ; Print current task memory &.
    mov word bx, [si+6]
    call print_hex_word
    add di, 0x2
    ; Print current task prev tsk.
    mov word bx, [si+8]
    call print_hex_word
    add di, 0x2
    ; Print current task next tsk.
    mov word bx, [si+10]
    call print_hex_word
    ; Continue with next task or end.
    mov word dx, [si+10]
    cmp [first_task], dx
    mov si, dx
    jne .loop
  pop dx
  pop cx
  pop bx
  pop ax
  pop di
  pop es
  pop si
  pop ds
  ret

task_list_header_row:
  db 'ID   BP   SP   Exe& Prv& Nxt&', 0x00