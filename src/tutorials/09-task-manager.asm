; We want to implement some form of multitasking in real mode. We are going to use a linked list to keep track of all tasks.
; We define a task via a data structure called task control block. It contains the following fields:
;   base pointer BP as 16 bit value
;   stack pointer SP as 16 bit value
;   starting address of memory allocated to the task as 16 bit value.
;   next task control block starting address
;
; Each task will have its own stack defined by BP and SP. This makes it easyer to not get confused when switching between tasks.
; We limit the tasks stack size to 512 byte.
;
; We pass additional memory required by a task as a parameter when creating a task. For simplicity, programs run inside a task
; must not request additional memory. We will allocate memory to a task using the memory manager from tutorial 7.
;
; Task switching will be done manually by pressing TAB. For simplicity reasons, we are not going to do this automatically using
; the programmable interval timer interrupt IRQ0. The switch task ISR will be the same. It will just be triggered via software
; interrupt.
;
; We mark the first task created in a way, that prevents us from exiting it. This ensures the number of running tasks can never be
; zero.

%include "../os/kernel-memory-manager.asm"

[bits 16]
main:
  ; Setup empty screen.
  call paint_screen_red
  call hide_cursor
  ; Install switch task.
  call install_switch_task_isr
  ; Init task list.
  mov ax, 0x0000
  call create_root_kernel_task
  ; Create second task.
  mov ax, 0x0001
  mov si, second
  call exec_task
  ; Reset arg values.
  xor ax, ax
  xor si, si
  .loop:
    ; Print stack.
    pushf
    mov word cx, 0x9
    call print_stack
    popf
    mov word dx, [pressed_key_buffer]
    mov word [pressed_key_buffer], 0x0000  ; Clear pressed key buffer.
    cmp dh, TAB_SCAN_CODE
    jne .end
      int 0x81
    .end:
      inc ax
      jmp .loop

[bits 16]
second:
  mov word cx, 0x2
  call print_tasks
  .loop:
    ; Print stack.
    pushf
    mov word cx, 0x6
    call print_stack
    popf
    mov word dx, [pressed_key_buffer]
    mov word [pressed_key_buffer], 0x0000  ; Clear pressed key buffer.
    cmp dh, TAB_SCAN_CODE
    jne .end
      int 0x81
    .end:
      inc ax
      jmp .loop
  
%include "../lib/multitasking.asm"

padding:       
  times 1024-(padding-main) db 0x00