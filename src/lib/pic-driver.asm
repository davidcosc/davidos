; This module contains routines for configuring the 8259 programmable interrupt controller.

MASTER_PIC_COMANND_IO_PORT equ 0x0020
MASTER_PIC_DATA_IO_PORT equ 0x0021
SLAVE_PIC_COMANND_IO_PORT equ 0x00A0
SLAVE_PIC_DATA_IO_PORT equ 0x00A1
MASTER_DEFAULT_INT_OFFSET equ 0x20
SLAVE_DEFAULT_INT_OFFSET equ 0x70
IVT_ENTRY_BYTE_SIZE equ 4
MASTER_DEFAULT_IRQ0_IVT_ADDRESS equ MASTER_DEFAULT_INT_OFFSET * IVT_ENTRY_BYTE_SIZE
MASTER_DEFAULT_IRQ1_IVT_ADDRESS equ MASTER_DEFAULT_IRQ0_IVT_ADDRESS + IVT_ENTRY_BYTE_SIZE
ENABLE_IRQ1_ONLY equ 0b11111101
DISABLE_ALL_IRQS equ 0b11111111

[bits 16]
configure_pics:
  ; Fully configures the pic. This can only
  ; be done by reinitializing it. To do so
  ; we first need to send a special control
  ; word called ICW1 to the command port.
  ; This starts the configuration process
  ; which requires 2 or 3 additional control
  ; words called ICW2, ICW3 and ICW4 to be
  ; send to the data port.
  ;
  ; ICW2 specifies the interrupt offset for
  ; all interrupts handled by the respective
  ; pic. Offsets must be divisible by 8.
  ; Each pic has 8 interrupt lines. I.e. an
  ; offset of 0x10 on the master pic results
  ; in IRQ0 being mapped to INT 0x10, IRQ1
  ; being mapped to INT 0x11 and so on. In
  ; real mode each interrupt vector has a
  ; size of 4 bytes. To get the starting
  ; address in memory where the vector
  ; begins for a specific interrupt,
  ; multiply the interrupt number by 4.
  ; I.e. for INT 0x11 this results in
  ; address 0x44.
  ;
  ; Arguments:
  ;   BH = ICW2 for master pic.
  ;   BL = ICW2 for slave pic.
  cli
  push dx
  push ax
  push bx
  ; ICW1
  mov byte al, 00010001b                   ; We want 2 cascading, edge triggered PICs. In x86 ICW4 is required and the call address interval ignored.
  mov dx, MASTER_PIC_COMANND_IO_PORT
  out dx, al
  mov dx, SLAVE_PIC_COMANND_IO_PORT
  out dx, al
  ; ICW2
  mov al, bh
  mov dx, MASTER_PIC_DATA_IO_PORT
  out dx, al
  mov al, bl
  mov dx, SLAVE_PIC_DATA_IO_PORT
  out dx, al
  ; ICW3
  mov byte al, 00000100b                   ; We expect the slave pic to be connected to the master on IRQ2 pin.
  mov dx, MASTER_PIC_DATA_IO_PORT
  out dx, al
  mov byte al, 0x02                        ; We expect the slave pic to have a cascade identity of 2. It triggers IRQ2 on master.
  mov dx, SLAVE_PIC_DATA_IO_PORT
  out dx, al
  ; ICW4
  mov byte al, 00000001b                   ; We want ICW4 to set x86 mode environment.
  mov dx, MASTER_PIC_DATA_IO_PORT
  out dx, al
  mov dx, SLAVE_PIC_DATA_IO_PORT
  out dx, al
  pop bx
  pop ax
  pop dx
  sti
  ret

[bits 16]
mask_interrupts:
  ; Enables or disables specific interrupt
  ; lines on the master and slave pic by
  ; providing operational control world OCW1
  ; to the data port of the respective pic.
  ; OCW1 is an 8 bit binary value. The least
  ; significant bit refers to the lowest
  ; interrupt line. To disable the
  ; respective interrupt line set the bit 
  ; value to 1. I.e. to disable all
  ; interrupts on the master pic apart from
  ; IRQ1, provide a OCW1 of 11111101b.
  ;
  ; Arguments:
  ;   BH = OCW1 for the master pic.
  ;   BL = OCW1 for the slave pic.
  cli
  push ax
  push dx
  mov al, bh
  mov dx, MASTER_PIC_DATA_IO_PORT
  out dx, al
  mov al, bl
  mov dx, SLAVE_PIC_DATA_IO_PORT
  out dx, al
  pop dx
  pop ax
  sti
  ret