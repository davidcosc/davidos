%include "../os/kernel-drivers.asm"

[bits 16]
set_up_memory_manager:
  call init_memory_chunk

[bits 16]
load_and_set_up_task_scheduler:
  push di
  push ax
  mov word ax, 0x4
  mov word di, 0x8400
  call read_sector
  mov word ax, 0x5
  mov word di, 0x8600
  call read_sector
  pop ax
  pop di
  jmp 0x8400                                    ; Continue executing instructions in the kernel task manager sectors.

%include "../lib/first-fit-implicit-list-memory-manager.asm"

kernel_memory_manager_padding:
  times 512-(kernel_memory_manager_padding-set_up_memory_manager) db 0x00