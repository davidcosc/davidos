%include "../os/bootsector.asm"

[bits 16]
set_up_interrupts:
  push bx
  mov byte bh, MASTER_DEFAULT_INT_OFFSET
  mov byte bl, SLAVE_DEFAULT_INT_OFFSET
  call configure_pics
  mov byte bh, ENABLE_IRQ1_ONLY
  mov byte bl, DISABLE_ALL_IRQS
  call mask_interrupts
  call install_keyboard_isr
  pop bx

[bits 16]
load_and_set_up_memory_management:
  push di
  push ax
  mov word ax, 0x3
  mov word di, 0x8200
  call read_sector
  pop ax
  pop di
  jmp 0x8200                               ; Continue executing instructions in the kernel memory manager sectors.

%include "../lib/vga-driver.asm"
%include "../lib/vga-driver-ext.asm"
%include "../lib/pic-driver.asm"
%include "../lib/keyboard-driver.asm"

additional_kernel_drivers_padding:
  times 1024-(additional_kernel_drivers_padding-set_up_interrupts) db 0x00