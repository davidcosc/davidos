; This module contains routines for configuring the 8259 programmable interrupt controller.

MASTER_PIC_COMANND_IO_PORT equ 0x0020
MASTER_PIC_DATA_IO_PORT equ 0x0021
SLAVE_PIC_COMANND_IO_PORT equ 0x00A0
SLAVE_PIC_DATA_IO_PORT equ 0x00A1
ICW1_CASC_EDGE_WITH_ICW4 equ 00010001b
ICW4_X86_MODE equ 00000001b
MASTER_DEFAULT_INT_OFFSET equ 0x20
SLAVE_DEFAULT_INT_OFFSET equ 0x70
IVT_ENTRY_BYTE_SIZE equ 4
MASTER_DEFAULT_IRQ0_IVT_ADDRESS equ MASTER_DEFAULT_INT_OFFSET * IVT_ENTRY_BYTE_SIZE
MASTER_DEFAULT_IRQ1_IVT_ADDRESS equ MASTER_DEFAULT_IRQ0_IVT_ADDRESS + IVT_ENTRY_BYTE_SIZE
ENABLE_IRQ1_ONLY equ 0b11111101
DISABLE_ALL_IRQS equ 0b11111111
ENABLE_IRQ0_AND_IRQ1_ONLY equ 0b11111100

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
  ;   ICW2 for master pic as word.
  ;   ICW2 for slave pic as word.
  ;
  ; We want hardware interrupts disabled while manipulating the hardware responsible for handling them.
  cli
  ; Function prologue. Set up stack frame.
  push bp
  mov bp, sp
  ; ICW1
  mov byte al, ICW1_CASC_EDGE_WITH_ICW4    ; We want 2 cascading, edge triggered PICs. In x86 ICW4 is required and the call address interval ignored.
  mov dx, MASTER_PIC_COMANND_IO_PORT
  out dx, al
  mov dx, SLAVE_PIC_COMANND_IO_PORT
  out dx, al
  ; ICW2
  mov word ax, [bp+4]                      ; Get master ICW2 arg.
  mov dx, MASTER_PIC_DATA_IO_PORT
  out dx, al
  mov word ax, [bp+6]                      ; Get slave ICW2 arg.
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
  mov byte al, ICW4_X86_MODE               ; We want ICW4 to set x86 mode environment.
  mov dx, MASTER_PIC_DATA_IO_PORT
  out dx, al
  mov dx, SLAVE_PIC_DATA_IO_PORT
  out dx, al
  ; Function epilogue. Tear down stack frame.
  pop bp
  ; Restart hardware interrupts.
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
  ;   OCW1 for the master pic as word.
  ;   OCW1 for the slave pic as word.
  ;
  ; We want hardware interrupts disabled while manipulating the hardware responsible for handling them.
  cli
  ; Function prologue. Set up stack frame.
  push bp
  mov bp, sp
  ; Mask interrupts.
  mov word ax, [bp+4]
  mov dx, MASTER_PIC_DATA_IO_PORT
  out dx, al
  mov word ax, [bp+6]
  mov dx, SLAVE_PIC_DATA_IO_PORT
  out dx, al
  ; Function epilogue. Tear down stack frame.
  pop bp
  ; Restart hardware interrupts.
  sti
  ret